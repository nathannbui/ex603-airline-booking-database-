-- EX 603 Assignment 4 | Airline Booking | PostgreSQL 14+ | ex603_data
-- Use instructor airline.sql from Unit 3, not schema/schema.sql.
-- Metric: fare_paid. Failure: recorded Passenger no show; all statuses in denominator.

-- Requirement 4.2A: For each producer, how many bookings and recorded no-shows?
-- One event-table scan; no WHERE removes bookings from the denominator.
SELECT flight_id, COUNT(*) AS bookings,
       SUM(CASE WHEN cancellation_reason = 'Passenger no show' THEN 1 ELSE 0 END)
           AS no_shows,
       ROUND(100.0 * SUM(CASE WHEN cancellation_reason = 'Passenger no show'
                             THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS no_show_pct
FROM bookings
GROUP BY flight_id
ORDER BY no_shows DESC, no_show_pct DESC, flight_id;

-- Requirement 4.2B: What are regional subtotals and the platform grand total?
-- One grouping dimension produces only regional subtotals and one grand total.
-- GROUPING distinguishes a real NULL country from the aggregate total.
SELECT CASE WHEN GROUPING(booking_country) = 1 THEN 'PLATFORM GRAND TOTAL'
            ELSE COALESCE(booking_country, 'Unknown region') END AS region,
       CASE WHEN GROUPING(booking_country) = 1 THEN 'Grand total'
            ELSE 'Regional subtotal' END AS row_type,
       COUNT(*) AS bookings, SUM(fare_paid) AS total_fare,
       SUM(CASE WHEN cancellation_reason = 'Passenger no show' THEN 1 ELSE 0 END)
           AS no_shows,
       ROUND(100.0 * SUM(CASE WHEN cancellation_reason = 'Passenger no show'
                             THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS no_show_pct
FROM bookings
GROUP BY ROLLUP (booking_country)
ORDER BY GROUPING(booking_country), booking_country;

-- Requirement 4.2C: What is the baseline among producers with at least 15 bookings?
-- Step 1 summarizes each producer; step 2 filters and aggregates those summaries.
WITH producer_metrics AS (
    SELECT flight_id, COUNT(*) AS bookings,
           SUM(CASE WHEN cancellation_reason = 'Passenger no show' THEN 1 ELSE 0 END)
               AS no_shows
    FROM bookings
    GROUP BY flight_id
)
SELECT COUNT(*) AS producers, SUM(bookings) AS bookings, SUM(no_shows) AS no_shows,
       ROUND(100.0 * SUM(no_shows) / NULLIF(SUM(bookings), 0), 2) AS weighted_pct,
       ROUND(AVG(100.0 * no_shows / NULLIF(bookings, 0)), 2) AS mean_producer_pct
FROM producer_metrics
WHERE bookings >= 15;

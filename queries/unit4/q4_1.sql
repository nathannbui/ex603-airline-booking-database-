-- EX 603 Assignment 4 | Airline Booking | PostgreSQL 14+ | ex603_data
-- Use instructor airline.sql from Unit 3, not schema/schema.sql.
-- Metric: fare_paid. Failure: recorded Passenger no show; all statuses in denominator.

-- Requirement 4.1.1: What are the platform's fare statistics and actor count?
SELECT COUNT(*) AS bookings, COUNT(fare_paid) AS fares,
       SUM(fare_paid) AS total_fare, ROUND(AVG(fare_paid), 2) AS avg_fare,
       MIN(fare_paid) AS min_fare, MAX(fare_paid) AS max_fare,
       COUNT(DISTINCT passenger_id) AS passengers,
       SUM(CASE WHEN fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fares
FROM bookings;

-- Requirement 4.1.2: Which producers have the most bookings and what average fare?
SELECT flight_id, COUNT(*) AS bookings, ROUND(AVG(fare_paid), 2) AS avg_fare
FROM bookings
GROUP BY flight_id
ORDER BY bookings DESC, flight_id;

-- Requirement 4.1.3: Which producers meet the 15-booking screening threshold?
-- 15 is a practical screen near the mean of 13.33, not statistical certainty.
SELECT flight_id, COUNT(*) AS bookings, ROUND(AVG(fare_paid), 2) AS avg_fare,
       SUM(CASE WHEN cancellation_reason = 'Passenger no show' THEN 1 ELSE 0 END)
           AS no_shows,
       ROUND(100.0 * SUM(CASE WHEN cancellation_reason = 'Passenger no show'
                             THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS no_show_pct
FROM bookings
GROUP BY flight_id
HAVING COUNT(*) >= 15
ORDER BY no_show_pct DESC, bookings DESC, flight_id;

-- Requirement 4.1.4: How do booking volume and fare vary by region and status?
-- Region means booking_country (booking market), not flight origin or passenger home.
SELECT booking_country AS region, booking_status, COUNT(*) AS bookings,
       ROUND(AVG(fare_paid), 2) AS avg_fare, SUM(fare_paid) AS total_fare,
       SUM(CASE WHEN cancellation_reason = 'Passenger no show' THEN 1 ELSE 0 END)
           AS no_shows
FROM bookings
GROUP BY booking_country, booking_status
ORDER BY region, booking_status;

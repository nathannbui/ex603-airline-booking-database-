-- =================================================================
-- EX 603 Assignment 3 - Task 3.1: Establish what the data contains
-- Theme: Airline Booking
-- Target: PostgreSQL 14+, database ex603_data
-- Load the instructor-provided airline.sql, not the Unit 2 schema.
-- =================================================================
-- Findings from the supplied data:
-- 3.1.0: 30 passengers, 15 flights, 28 flight_services, 5 airports,
--        25 flight_routes, and 200 bookings. There are six physical tables
--        representing the five roles described in the assignment.
-- 3.1a: Eight flights qualify: VN201, VN202, VN204, VN205, VN214,
--       VN208, VN210, VN211. Only eight satisfy the filter, so LIMIT 10
--       returns eight. Capacity ties are ordered by flight ID.
-- 3.1b: cancelled, confirmed, disputed. Disputed is a third outcome,
--       so the data is not simply success versus failure.
-- 3.1c: Ten fares fall between 40 and 50 inclusive. Booking IDs in order:
--       200, 60, 116, 18, 190, 47, 67, 94, 100, 105.
-- 3.1d: 44 bookings match the list: 34 cancelled and 10 disputed.
-- 3.1e: Six flight numbers match: VN210 through VN215.
-- 3.1f: 166 missing reasons: 156 confirmed and 10 disputed bookings.
--       COALESCE changes only the displayed label, not the stored value.
--       A missing reason does not by itself prove a successful booking.
-- 3.1g: The first ten bookings include a no-show (4), another cancellation
--       (8), and a dispute (5). Missing check-in times remain NULL, not zero.
-- 3.1h: All 200 bookings are dated in 2023: 156 confirmed, 34 cancelled,
--       and 10 disputed. All statuses belong in the overall denominator.

-- 3.1.0 Setup: did all supplied tables and the booking population load?
-- Requirement: confirm the dataset. Six physical tables implement five roles.
SELECT 'passengers' AS table_name, COUNT(*) AS row_count FROM passengers
UNION ALL SELECT 'flights', COUNT(*) FROM flights
UNION ALL SELECT 'flight_services', COUNT(*) FROM flight_services
UNION ALL SELECT 'airports', COUNT(*) FROM airports
UNION ALL SELECT 'flight_routes', COUNT(*) FROM flight_routes
UNION ALL SELECT 'bookings', COUNT(*) FROM bookings
ORDER BY table_name;

-- 3.1a Which active flights have at least 180 seats?
-- Requirement 1: SELECT, WHERE, ORDER BY, LIMIT; exact appendix filter.
SELECT flight_id, flight_number, seat_capacity
FROM flights
WHERE is_active = TRUE AND seat_capacity >= 180
ORDER BY seat_capacity DESC, flight_id
LIMIT 10;

-- 3.1b Which booking statuses actually occur?
-- Requirement 2: DISTINCT. These are observed values, not a schema enum.
SELECT DISTINCT booking_status
FROM bookings
ORDER BY booking_status;

-- 3.1c Which bookings have fares from 40 through 50, inclusive?
-- Requirement 3: numeric range filter. Currency is not specified by the data.
SELECT booking_id, flight_id, fare_paid
FROM bookings
WHERE fare_paid BETWEEN 40.00 AND 50.00
ORDER BY fare_paid DESC, booking_id;

-- 3.1d Which bookings are disputed or cancelled?
-- Requirement 3: explicit IN list; return all matches, without a sample limit.
SELECT booking_id, passenger_id, booking_status
FROM bookings
WHERE booking_status IN ('disputed', 'cancelled')
ORDER BY booking_status, booking_id;

-- 3.1e Which flight numbers start with VN21?
-- Requirement 4: LIKE text pattern on the producer's display name.
SELECT flight_id, flight_number, seat_capacity
FROM flights
WHERE flight_number LIKE 'VN21%'
ORDER BY flight_number, flight_id;

-- 3.1f Which bookings have no recorded cancellation reason?
-- Requirement 4: IS NULL and COALESCE; return every matching record.
SELECT booking_id, booking_status,
       COALESCE(cancellation_reason, 'No reason provided') AS reason_label
FROM bookings
WHERE cancellation_reason IS NULL
ORDER BY booking_id;

-- 3.1g How long did check-in take, and what does each outcome mean?
-- Requirement 5: computed column and CASE categories; first 10 IDs are a sample.
SELECT booking_id,
       ROUND(EXTRACT(EPOCH FROM (checked_in_at - booked_at)) / 60.0, 1)
           AS minutes_to_check_in,
       CASE WHEN cancellation_reason = 'Passenger no show' THEN 'Passenger no-show'
            WHEN booking_status = 'cancelled' THEN 'Other cancellation'
            WHEN booking_status = 'disputed' THEN 'Disputed booking'
            WHEN booking_status = 'confirmed' THEN 'Confirmed booking'
            ELSE 'Other status' END AS outcome
FROM bookings
ORDER BY booking_id
LIMIT 10;

-- 3.1h How large is each status group, and when were bookings made?
-- Requirement: record the population supporting the dashboard investigation.
SELECT booking_status, COUNT(*) AS bookings,
       MIN(booked_at)::date AS first_booking, MAX(booked_at)::date AS last_booking
FROM bookings
GROUP BY booking_status
ORDER BY booking_status;

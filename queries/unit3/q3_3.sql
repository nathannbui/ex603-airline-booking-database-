-- =================================================================
-- EX 603 Assignment 3 - Task 3.3: Hand the team a corrected query
-- Theme: Airline Booking
-- Target: PostgreSQL 14+, database ex603_data
-- =================================================================
-- All three forms return the same 20 passenger IDs and their names:
-- 2, 3, 5, 8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 22, 23, 24, 25, 26, 28, 30.
-- The bidirectional EXCEPT ALL comparison returns zero differences.
-- The NULL counterexample returns 0 for NOT IN and 20 for both other forms.
-- Two-step question: identify passengers in recorded no-show bookings;
-- then return passengers NOT in that group. Include passengers with no bookings.
-- "No recorded no-show" does not mean every booking succeeded.

-- 3.3a Which passengers have no booking marked Passenger no show?
-- Requirement 1: NOT IN subquery. Safe here: bookings.passenger_id is NOT NULL.
SELECT p.passenger_id, p.passenger_name
FROM passengers AS p
WHERE p.passenger_id NOT IN (
    SELECT b.passenger_id FROM bookings AS b
    WHERE b.cancellation_reason = 'Passenger no show'
)
ORDER BY p.passenger_id;

-- 3.3b Which passengers have no recorded no-show, using a named group?
-- Requirement 2: WITH CTE and LEFT JOIN to find passengers without a match.
WITH no_show_passengers AS (
    SELECT DISTINCT passenger_id FROM bookings
    WHERE cancellation_reason = 'Passenger no show'
)
SELECT p.passenger_id, p.passenger_name
FROM passengers AS p
LEFT JOIN no_show_passengers AS n ON n.passenger_id = p.passenger_id
WHERE n.passenger_id IS NULL
ORDER BY p.passenger_id;

-- 3.3c Which passengers lack any matching no-show booking?
-- Requirement 3: correlated NOT EXISTS, a different subquery form.
SELECT p.passenger_id, p.passenger_name
FROM passengers AS p
WHERE NOT EXISTS (
    SELECT 1 FROM bookings AS b
    WHERE b.passenger_id = p.passenger_id
      AND b.cancellation_reason = 'Passenger no show'
)
ORDER BY p.passenger_id;

-- 3.3d Do the actual rows, including multiplicities, match in every direction?
-- Requirement 4: four EXCEPT ALL comparisons; zero rows proves A=B and A=C.
WITH
a AS (
    SELECT p.passenger_id, p.passenger_name FROM passengers AS p
    WHERE p.passenger_id NOT IN (
        SELECT passenger_id FROM bookings WHERE cancellation_reason = 'Passenger no show')
),
no_shows AS (
    SELECT DISTINCT passenger_id FROM bookings
    WHERE cancellation_reason = 'Passenger no show'
),
b AS (
    SELECT p.passenger_id, p.passenger_name FROM passengers AS p
    LEFT JOIN no_shows AS n ON n.passenger_id = p.passenger_id
    WHERE n.passenger_id IS NULL
),
c AS (
    SELECT p.passenger_id, p.passenger_name FROM passengers AS p
    WHERE NOT EXISTS (
        SELECT 1 FROM bookings AS e WHERE e.passenger_id = p.passenger_id
          AND e.cancellation_reason = 'Passenger no show')
)
SELECT 'A minus B' AS difference, d.* FROM (TABLE a EXCEPT ALL TABLE b) AS d
UNION ALL SELECT 'B minus A', d.* FROM (TABLE b EXCEPT ALL TABLE a) AS d
UNION ALL SELECT 'A minus C', d.* FROM (TABLE a EXCEPT ALL TABLE c) AS d
UNION ALL SELECT 'C minus A', d.* FROM (TABLE c EXCEPT ALL TABLE a) AS d
ORDER BY difference, passenger_id;

-- 3.3e What input would break equivalence? A NULL passenger ID in no-show input.
-- Requirement 5: executable counterexample; DOES NOT change the supplied tables.
-- If a future import/query admitted NULL IDs (the current schema forbids them),
-- NOT IN would return no passengers. The other forms still return 20.
-- Repeated no-show IDs do not break these forms; an empty group returns all 30.
WITH no_shows AS (
    SELECT passenger_id FROM bookings WHERE cancellation_reason = 'Passenger no show'
    UNION ALL SELECT NULL::integer
)
SELECT 'NOT IN' AS form, COUNT(*) AS passengers_returned
FROM passengers WHERE passenger_id NOT IN (SELECT passenger_id FROM no_shows)
UNION ALL
SELECT 'CTE / LEFT JOIN', COUNT(*) FROM passengers AS p
LEFT JOIN (SELECT DISTINCT passenger_id FROM no_shows) AS n
    ON n.passenger_id = p.passenger_id
WHERE n.passenger_id IS NULL
UNION ALL
SELECT 'NOT EXISTS', COUNT(*) FROM passengers AS p
WHERE NOT EXISTS (SELECT 1 FROM no_shows AS n WHERE n.passenger_id = p.passenger_id)
ORDER BY form;

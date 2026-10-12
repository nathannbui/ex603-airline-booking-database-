-- =================================================================
-- EX 603 Assignment 3 - Task 3.2: Find the bug
-- Theme: Airline Booking
-- Target: PostgreSQL 14+, database ex603_data
-- =================================================================
-- Existing NULL cancellation reasons are used; no data was inserted.
-- The broken alias example is caught so this entire file runs unchanged
-- with ON_ERROR_STOP=1. The standalone failing statement and its error
-- are shown together in screenshots/Unit3 - 3.2b1-error.png.
-- Verbatim standalone PostgreSQL error:
-- ERROR:  column "minutes_to_check_in" does not exist
-- LINE 5: WHERE minutes_to_check_in > 50
--               ^
-- The relevant logical order is FROM, WHERE, SELECT, ORDER BY.
-- WHERE cannot see the SELECT alias in the same query. An outer query
-- can see the column produced by a CTE.
-- Both repairs return the same 14 booking IDs:
-- 7, 29, 50, 51, 90, 101, 110, 126, 133, 145, 157, 180, 187, 196.
-- The supplied data gives 12/200 = 6.00% recorded no-shows; using only
-- recorded reasons gives 12/34 = 35.29%. This does not reproduce the
-- scenario's approximate 50%; the original dashboard SQL was not supplied.

-- 3.2a1 BROKEN: how many bookings are not recorded as passenger no-shows?
-- Requirement A2: inequality on a nullable column; wrongly excludes NULLs.
SELECT COUNT(*) AS broken_non_no_show_count
FROM bookings
WHERE cancellation_reason <> 'Passenger no show';

-- 3.2a2 How many rows silently vanished because their reason is missing?
-- Requirement A3: count the NULL rows omitted by the broken predicate.
SELECT COUNT(*) AS silently_omitted_null_rows
FROM bookings
WHERE cancellation_reason IS NULL;

-- 3.2a3 Do the apparent opposite filters cover the table? Show all counts.
-- Requirement A3: compare both predicates, the omitted rows, and table total.
-- 22 + 12 = 34, not 200: 166 NULL rows are absent from BOTH comparisons.
-- Also, a1 + a2 = 22 + 166 = 188, not 200: 12 no-shows are intentionally out.
SELECT COUNT(*) AS table_total,
       COUNT(*) FILTER (WHERE cancellation_reason <> 'Passenger no show') AS other_reason,
       COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show') AS no_show,
       COUNT(cancellation_reason) AS both_comparisons,
       COUNT(*) FILTER (WHERE cancellation_reason IS NULL) AS omitted_null
FROM bookings;

-- 3.2a4 REPAIR: include bookings with no reason in the non-no-show group.
-- Requirement A4: explicit IS NULL restores all 188 intended rows.
-- This means "no recorded no-show", not proof that every booking succeeded.
SELECT COUNT(*) AS repaired_non_no_show_count
FROM bookings
WHERE cancellation_reason <> 'Passenger no show' OR cancellation_reason IS NULL;

-- 3.2a5 Does the repaired partition cover every booking, and what is the rate?
-- Requirement A4 / memo: 188 + 12 = 200; denominator includes every booking.
SELECT COUNT(*) AS total_bookings,
       COUNT(*) FILTER (WHERE cancellation_reason <> 'Passenger no show'
                        OR cancellation_reason IS NULL) AS not_recorded_no_show,
       COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show') AS no_shows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show')
             / NULLIF(COUNT(*), 0), 2) AS corrected_no_show_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show')
             / NULLIF(COUNT(cancellation_reason), 0), 2) AS reason_only_pct
FROM bookings;

-- 3.2b1 BROKEN: which bookings took more than 50 minutes to check in?
-- Requirement B1: SELECT alias referenced too early in WHERE.
-- Standalone statement executed to capture the actual PostgreSQL error:
-- SELECT booking_id,
--        ROUND(EXTRACT(EPOCH FROM (checked_in_at - booked_at)) / 60.0, 1)
--            AS minutes_to_check_in
-- FROM bookings
-- WHERE minutes_to_check_in > 50
-- ORDER BY booking_id;
-- Verbatim server message: ERROR:  column "minutes_to_check_in" does not exist
-- Expected SQLSTATE: 42703. Catch only that error; any other failure propagates.
DO $audit$
BEGIN
    EXECUTE $broken$
        SELECT booking_id,
               ROUND(EXTRACT(EPOCH FROM (checked_in_at - booked_at)) / 60.0, 1)
                   AS minutes_to_check_in
        FROM bookings
        WHERE minutes_to_check_in > 50
        ORDER BY booking_id
    $broken$;
    RAISE EXCEPTION 'Expected undefined_column error did not occur';
EXCEPTION WHEN undefined_column THEN
    RAISE NOTICE 'Expected error reproduced [%]: %', SQLSTATE, SQLERRM;
END;
$audit$;

-- 3.2b2 REPAIR 1: which bookings took more than 50 minutes to check in?
-- Requirement B2: repeat the computed expression in WHERE.
SELECT booking_id,
       ROUND(EXTRACT(EPOCH FROM (checked_in_at - booked_at)) / 60.0, 1)
           AS minutes_to_check_in
FROM bookings
WHERE ROUND(EXTRACT(EPOCH FROM (checked_in_at - booked_at)) / 60.0, 1) > 50
ORDER BY booking_id;

-- 3.2b3 REPAIR 2: ask the same question using the computed column of a CTE.
-- Requirement B2: WITH makes the alias available to the outer WHERE.
WITH check_in_times AS (
    SELECT booking_id,
           ROUND(EXTRACT(EPOCH FROM (checked_in_at - booked_at)) / 60.0, 1)
               AS minutes_to_check_in
    FROM bookings
)
SELECT booking_id, minutes_to_check_in
FROM check_in_times
WHERE minutes_to_check_in > 50
ORDER BY booking_id;

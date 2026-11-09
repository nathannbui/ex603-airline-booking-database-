-- 5.2A.1: Which flights and bookings appear when every producer is retained?
SELECT f.flight_id, f.flight_number, b.booking_id
FROM flights f LEFT JOIN bookings b ON b.flight_id=f.flight_id
ORDER BY f.flight_id,b.booking_id;

-- 5.2A.2: Which flights and bookings have matches on both sides?
SELECT f.flight_id, f.flight_number, b.booking_id
FROM flights f INNER JOIN bookings b ON b.flight_id=f.flight_id
ORDER BY f.flight_id,b.booking_id;

-- 5.2A.3: How many unique producers does the inner join exclude?
SELECT COUNT(DISTINCT f.flight_id) AS all_producers,
 COUNT(DISTINCT f.flight_id) FILTER (WHERE b.booking_id IS NOT NULL) AS matched_producers,
 COUNT(DISTINCT f.flight_id) FILTER (WHERE b.booking_id IS NULL) AS excluded_producers
FROM flights f LEFT JOIN bookings b ON b.flight_id=f.flight_id;

-- 5.2B.1: Does reversing the sides and using RIGHT JOIN retain all flights?
SELECT f.flight_id,f.flight_number,b.booking_id
FROM bookings b RIGHT JOIN flights f ON f.flight_id=b.flight_id
ORDER BY f.flight_id,b.booking_id;

-- 5.2B.2: Are the LEFT and RIGHT results identical, including duplicates?
WITH l AS (SELECT f.flight_id,b.booking_id FROM flights f LEFT JOIN bookings b USING(flight_id)),
r AS (SELECT f.flight_id,b.booking_id FROM bookings b RIGHT JOIN flights f USING(flight_id))
SELECT 'left_minus_right' AS difference,COUNT(*) FROM (TABLE l EXCEPT ALL TABLE r) d
UNION ALL SELECT 'right_minus_left',COUNT(*) FROM (TABLE r EXCEPT ALL TABLE l) d;

-- 5.2B.3: Are there unmatched records on either side?
SELECT f.flight_id,f.flight_number,b.booking_id,b.flight_id AS booking_flight_id
FROM flights f FULL OUTER JOIN bookings b ON b.flight_id=f.flight_id
ORDER BY f.flight_id NULLS LAST,b.booking_id;

-- 5.2C.1: Which producers have no events, using NOT EXISTS?
SELECT f.flight_id,f.flight_number FROM flights f
WHERE NOT EXISTS (SELECT 1 FROM bookings b WHERE b.flight_id=f.flight_id)
ORDER BY f.flight_id;

-- 5.2C.2: Which producers have no events, using set subtraction?
SELECT flight_id FROM flights EXCEPT SELECT flight_id FROM bookings ORDER BY flight_id;

-- 5.2C.3: Do both unmatched-producer approaches return the same identifiers?
WITH n AS (SELECT f.flight_id FROM flights f WHERE NOT EXISTS
 (SELECT 1 FROM bookings b WHERE b.flight_id=f.flight_id)),
e AS (SELECT flight_id FROM flights EXCEPT SELECT flight_id FROM bookings)
SELECT 'not_exists_minus_except' AS difference,COUNT(*) FROM (TABLE n EXCEPT TABLE e) d
UNION ALL SELECT 'except_minus_not_exists',COUNT(*) FROM (TABLE e EXCEPT TABLE n) d;

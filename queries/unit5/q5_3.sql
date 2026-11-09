-- 5.3A.1: What candidate airport pairs can be generated from two small tables?
-- Both source relations contain five rows; includes same-airport pairs intentionally.
WITH origins AS (SELECT airport_id,iata_code FROM airports),
 destinations AS (SELECT airport_id,iata_code FROM airports)
SELECT o.iata_code AS origin,d.iata_code AS destination
FROM origins o CROSS JOIN destinations d ORDER BY o.airport_id,d.airport_id;

-- 5.3A.2: Does the actual Cartesian count equal the product of source counts?
WITH origins AS (SELECT airport_id FROM airports),
 destinations AS (SELECT airport_id FROM airports)
SELECT (SELECT COUNT(*) FROM origins) AS origin_count,
 (SELECT COUNT(*) FROM destinations) AS destination_count,
 (SELECT COUNT(*) FROM origins)*(SELECT COUNT(*) FROM destinations) AS expected_pairs,
 (SELECT COUNT(*) FROM origins CROSS JOIN destinations) AS actual_pairs;

-- 5.3B: How does PostgreSQL execute the exact three-table event report from 5.1.1?
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.booking_id, p.passenger_id, p.passenger_name,
       f.flight_id, f.flight_number, b.booked_at
FROM bookings b
INNER JOIN passengers p ON p.passenger_id = b.passenger_id
INNER JOIN flights f ON f.flight_id = b.flight_id
ORDER BY b.booking_id;

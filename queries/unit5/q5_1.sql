-- 5.1.1: Who booked each flight, and when?
SELECT b.booking_id, p.passenger_id, p.passenger_name,
       f.flight_id, f.flight_number, b.booked_at
FROM bookings b
INNER JOIN passengers p ON p.passenger_id = b.passenger_id
INNER JOIN flights f ON f.flight_id = b.flight_id
ORDER BY b.booking_id;

-- 5.1.2: Which flights have the SGN catalog tag, including investigation targets?
-- Airports are the catalog; SGN is the selected airline theme tag.
SELECT f.flight_id, f.flight_number, a.iata_code, a.airport_name,
       f.flight_id IN (2, 3) AS unit4_investigation_target
FROM flights f
JOIN flight_routes r ON r.flight_id = f.flight_id
JOIN airports a ON a.airport_id = r.airport_id
WHERE a.iata_code = 'SGN'
ORDER BY f.flight_id;

-- 5.1.3: How do targets 2 and 3 compare to other flights from the same country?
WITH activity AS (
 SELECT flight_id, COUNT(*) AS bookings,
        COUNT(*) FILTER (WHERE cancellation_reason = 'Passenger no show') AS no_shows
 FROM bookings GROUP BY flight_id
)
SELECT f.flight_id AS target_id, f.flight_number AS target_number,
       peer.flight_id AS peer_id, peer.flight_number AS peer_number,
       f.origin_country, f.is_active AS target_active, peer.is_active AS peer_active,
       f.seat_capacity AS target_capacity, peer.seat_capacity AS peer_capacity,
       COALESCE(a.bookings,0) AS target_bookings, COALESCE(b.bookings,0) AS peer_bookings,
       ROUND(100.0*a.no_shows/NULLIF(a.bookings,0),2) AS target_no_show_pct,
       ROUND(100.0*b.no_shows/NULLIF(b.bookings,0),2) AS peer_no_show_pct
FROM flights f
JOIN flights peer ON peer.origin_country = f.origin_country AND peer.flight_id <> f.flight_id
LEFT JOIN activity a ON a.flight_id=f.flight_id
LEFT JOIN activity b ON b.flight_id=peer.flight_id
WHERE f.flight_id IN (2,3)
ORDER BY f.flight_id, peer.flight_id;

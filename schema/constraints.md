# Integrity Constraints — Airline Booking Platform

## Primary keys
- `passengers(passenger_id)`
- `flights(flight_id)`
- `bookings(booking_id)`
- `airports(airport_code)`
- `flight_routes(flight_id, airport_code)` = composite

Enforced with `PRIMARY KEY`. Guarantees no duplicate passenger, flight, booking, or airport row, and that a given flight cannot list the same airport twice in its route.

## Unique constraints
- `passengers.email UNIQUE` — one account per email address.
- `passengers.passport_number UNIQUE` — one passenger record per real traveler this prevents accidental duplicate registration.

## Foreign keys and `ON DELETE` behavior

### `bookings.passenger_id => passengers.passenger_id`
**`ON DELETE RESTRICT`.**
A booking is a financial and legal record (proof of purchase, refund, audit trail). If a passenger row could be deleted while bookings referencing it exist, that history would either vanish (if cascaded) or be orphaned (if left unconstrained) so both are unacceptable for anything resembling a real airline. If a passenger genuinely needs to be removed, that is an explicit, anonymization step, not a blind cascading delete.

### `bookings.flight_id => flights.flight_id`
**`ON DELETE RESTRICT`.**
Same reasoning as above: once a flight has bookings, its revenue and passenger history must survive. Flights are retired from active service by setting `is_active = FALSE` once any booking exists against them.

### `flight_routes.flight_id => flights.flight_id`
**`ON DELETE CASCADE`.**
Route legs have no independent meaning without their flight a row in `flight_routes` only exists to describe one flight's itinerary. If a flight is truly purged, ex: it was created in error and never received a booking, so the `RESTRICT` above never applies, its route rows should be removed automatically rather than left as orphans requiring a separate manual cleanup.

### `flight_routes.airport_code => airports.airport_code`
**`ON DELETE RESTRICT`.**
Airports are reference/master data. Deleting one while `flight_routes` rows still reference it would silently corrupt every itinerary that flies through it. Any airport retirement, permanent closure has to be handled by first re-routing or removing the affected flights, not by a cascading delete that would rewrite history.

## Check 
- `flights`: `CHECK (arrival_time > departure_time)` = a flight cannot arrive before or at the moment it departs.
- `bookings.booking_status`: `CHECK (booking_status IN ('confirmed','cancelled','checked_in'))`
- `passengers.loyalty_tier`: `CHECK (loyalty_tier IN ('standard','silver','gold','platinum'))`
- `flight_routes.leg_role`: `CHECK (leg_role IN ('origin','stop','destination'))`

## Not-null 
This will be applied to every attribute listed as `NOT NULL` in `schema-definition.md`, in short, everything except `passengers.phone`, `flights.aircraft_type`, and `bookings.seat_number`, which are legitimately unknown at some point in the row's life.

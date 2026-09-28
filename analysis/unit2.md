# Unit 2

## Creation order and PostgreSQL types

The script creates `passengers`, `flights`, and `airports` first because they do not reference other tables. It then creates `bookings`, which references passengers and flights, followed by `flight_routes`, which references flights and airports. 

The three surrogate keys use `INTEGER GENERATED ALWAYS AS IDENTITY`. Airport codes use `CHAR(3)`, and the junction table uses the composite primary key `(flight_id, airport_code)`. This pair saves the same airport from appearing twice for one flight without adding an unrelated ID. Foreign key columns have the same types as the keys they reference.

Fares use `NUMERIC(10,2)` to store decimal amounts exactly. Flight and booking times use `TIMESTAMP`, dates of birth use `DATE`, and flight availability uses `BOOLEAN`. Flight duration is not stored separately. The route role uses `VARCHAR(11)` because `destination` contains eleven characters.

## Foreign key constraints

| Foreign key | ON DELETE choice | Reason |
|---|---|---|
| `fk_bookings_passenger`: `bookings.passenger_id` references `passengers.passenger_id` | `CASCADE` | In the implemented schema, deleting a passenger also removes that passenger's bookings so no bookings remain without their owner. |
| `fk_bookings_flight`: `bookings.flight_id` references `flights.flight_id` | `RESTRICT` | A flight with bookings cannot be deleted because those bookings still need their flight record. |
| `fk_flight_routes_flight`: `flight_routes.flight_id` references `flights.flight_id` | `CASCADE` | Route entries describe a particular flight and are removed automatically when that flight is deleted. |
| `fk_flight_routes_airport`: `flight_routes.airport_code` references `airports.airport_code` | `RESTRICT` | An airport cannot be deleted while a flight route still depends on it. |

### Deleting a passenger

Under the current `CASCADE` rule, deleting a passenger removes every booking belonging to that passenger. This treats passenger deletion as a removal of the passenger and their booking records. It affects booking history and revenue reports because those bookings no longer exist. `RESTRICT` would instead block the deletion until the bookings were handled explicitly; `SET NULL` would conflict with the required passenger reference.

This behavior differs from the Unit 1 retention policy, which specified `RESTRICT` to preserve booking history. The implemented cascade is therefore a material change, not an equivalent way to enforce the original policy. If preserving booking history remains the goal, this foreign key should return to `RESTRICT`, with account closure handled through a separate process.

### Deleting a flight with bookings

If an administrator tries to delete a flight that passengers have booked, `RESTRICT` prevents the deletion. The booking records keep their connection to the flight, including its schedule and flight number. A flight can instead be marked inactive using `is_active`; this flag does not itself cancel bookings. With `CASCADE`, deleting a flight would erase its bookings and remove them from passenger histories and revenue reports.

### Deleting a flight's route entries

A flight created by mistake can be deleted if no bookings reference it. When that happens, `CASCADE` removes its `flight_routes` rows because those rows have no meaning without the flight. With `RESTRICT`, the administrator would have to delete the route entries separately before deleting the flight. This cascade does not override the booking restriction: a flight with bookings still cannot be deleted.

### Deleting an airport

If an airport closes or is entered incorrectly, `RESTRICT` prevents its deletion while routes still reference it. The affected itineraries must be reviewed and their route entries changed or removed explicitly. With `CASCADE`, deleting an airport could silently remove an origin, stop, or destination from multiple flights. The restriction makes that route change an explicit action.

## CHECK constraints

| Constraint | Invalid state prevented | How it could arise |
|---|---|---|
| `chk_passengers_loyalty_tier` | A tier outside `standard`, `silver`, `gold`, and `platinum`. | A form or import could supply an unsupported tier or a typo such as `golds`. |
| `chk_flights_times` | An arrival time equal to or earlier than the departure time. | A schedule entry could swap the two timestamps or omit the next day's date on an overnight flight. |
| `chk_flights_base_fare` | A negative advertised fare. | A pricing import could include a sign error or apply a discount incorrectly. |
| `chk_bookings_status` | A status outside `confirmed`, `cancelled`, and `completed`. | Application code could send an unsupported status or an inconsistent spelling. |
| `chk_bookings_fare_paid` | A negative amount paid for a booking. | A payment import could mistake a refund adjustment for the booking's fare; this schema does not model refunds as negative fares. |
| `chk_flight_routes_leg_role` | A route role outside `origin`, `stop`, and `destination`. | A route entry could contain a typo or an unsupported label such as `arrival`. |

The fare checks allow zero, so a complimentary booking or zero base fare is valid. Every column used by these checks is also `NOT NULL`, which prevents missing values from bypassing the intended rules. The timestamp comparison assumes that both timestamps use a consistent time basis; the schema does not store airport time zones.

These checks validate individual rows. They do not ensure that each route has exactly one origin and one destination, that stop numbers are positive and unique within a flight, or that a passenger has no overlapping bookings. Those rules need additional constraints or application validation.

## Differences from the Unit 1 design

The five tables and their relationships remain the same, but the current implementation differs...

- `bookings.passenger_id` uses `ON DELETE CASCADE`, while Unit 1 specified `RESTRICT`. The retention consequence is explained above.
- `bookings.booking_id` uses `INTEGER`, while the Unit 1 definition and diagram specify `BIGINT`. The implementation has a smaller identifier range.
- `bookings.booking_status` allows `completed` instead of `checked_in` and has no default. Every new booking must supply an allowed status explicitly.
- `flight_routes.leg_role` uses `VARCHAR(11)` instead of `VARCHAR(10)` so the documented value `destination` fits.
- The SQL explicitly checks that both `base_fare` and `fare_paid` are nonnegative.

The missing `flight_routes` creation block was also added to the SQL. That repair implements a relationship already present in the Unit 1 design. The ERD image and both diagram source files now reflect the implemented booking ID type and route-role length. The PNG also labels the current foreign key deletion rules. The earlier schema definition and constraints documents still need to be reconciled with the implementation before submission.

## Execution verification

```bash
psql -v ON_ERROR_STOP=1 airline_booking -f schema/schema.sql
psql -v ON_ERROR_STOP=1 airline_booking -f schema/schema.sql
psql airline_booking -c '\dt'
```

Both executions succeeded and each produced five `CREATE TABLE` results. The final table list contained `airports`, `bookings`, `flight_routes`, `flights`, and `passengers`. Screenshots are in the screenshots folder. 
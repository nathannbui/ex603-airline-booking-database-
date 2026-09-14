# Schema — Airline Booking Platform

Five relations, one per role. Domains are given as PostgreSQL types. `PK` = primary key; `FK` = foreign key; `UQ` = a uniqueness constraint that is not the primary key.

## 1. `passengers` (actor)

| Attribute | Domain | Notes |
|---|---|---|
| `passenger_id` | `INTEGER` | **PK**. Surrogate key |
| `full_name` | `VARCHAR(120) NOT NULL` | Display name |
| `email` | `VARCHAR(255) NOT NULL` | **UQ**. Login/contact identifier |
| `phone` | `VARCHAR(20)` | Nullable — not every passenger provides one |
| `date_of_birth` | `DATE NOT NULL` | Needed for age-restricted fares/rules |
| `passport_number` | `VARCHAR(20) NOT NULL` | **UQ**. See reflection in `analysis/unit1.md` for why this is not the PK |
| `loyalty_tier` | `VARCHAR(20) NOT NULL DEFAULT 'standard'` | `CHECK` restricts to `'standard','silver','gold','platinum'`. |

**Primary key:** `passenger_id`

## 2. `flights` (producer)

| Attribute | Domain | Notes |
|---|---|---|
| `flight_id` | `INTEGER` (`GENERATED ALWAYS AS IDENTITY`) | **PK**. Surrogate key. |
| `flight_number` | `VARCHAR(10) NOT NULL` | Display name such as `AA1234`. Not unique alone, the same number is reused across dates |
| `airline_code` | `CHAR(2) NOT NULL` | IATA carrier code |
| `departure_time` | `TIMESTAMP NOT NULL` | |
| `arrival_time` | `TIMESTAMP NOT NULL` | `CHECK (arrival_time > departure_time)`. |
| `aircraft_type` | `VARCHAR(50)` | Nullable this can be unassigned far out from departure. |
| `base_fare` | `DECIMAL(10,2) NOT NULL` | The numeric attribute used for filtering such as "flights under $300". |
| `is_active` | `BOOLEAN NOT NULL DEFAULT TRUE` | Activity flag. Flights are retired by flipping this, never hard-deleted once booked on constraints.md. |

**Primary key:** `flight_id`

## 3. `bookings` (event / fact table)

| Attribute | Domain | Notes |
|---|---|---|
| `booking_id` | `BIGINT` (`GENERATED ALWAYS AS IDENTITY`) | **PK**. `BIGINT` because this table is high-volume. |
| `passenger_id` | `INTEGER NOT NULL` | **FK**  = `passengers.passenger_id`. |
| `flight_id` | `INTEGER NOT NULL` | **FK** = `flights.flight_id`. |
| `booking_timestamp` | `TIMESTAMP NOT NULL DEFAULT now()` | When the booking was made. |
| `seat_number` | `VARCHAR(5)` | Null until check-in/seat assignment. |
| `booking_status` | `VARCHAR(20) NOT NULL DEFAULT 'confirmed'` | `CHECK` restricts to `'confirmed','cancelled','checked_in'`. |
| `fare_paid` | `DECIMAL(10,2) NOT NULL` | The metric to aggregate so the actual amount charged, which can differ from `flights.base_fare` due to discounts/dynamic pricing. |

**Primary key:** `booking_id`

## 4. `airports` (catalog)

| Attribute | Domain | Notes |
|---|---|---|
| `airport_code` | `CHAR(3)` | **PK**. Natural key the IATA code, already a stable. |
| `airport_name` | `VARCHAR(150) NOT NULL` | |
| `city` | `VARCHAR(100) NOT NULL` | |
| `country` | `VARCHAR(100) NOT NULL` | |

**Primary key:** `airport_code`.

## 5. `flight_routes` (junction)

| Attribute | Domain | Notes |
|---|---|---|
| `flight_id` | `INTEGER NOT NULL` | **PK, FK** = `flights.flight_id`. |
| `airport_code` | `CHAR(3) NOT NULL` | **PK, FK** = `airports.airport_code`. |
| `stop_sequence` | `SMALLINT NOT NULL` | Order of this airport within the flight's itinerary. |
| `leg_role` | `VARCHAR(10) NOT NULL` | `CHECK` restricts to `'origin','stop','destination'`. |

**Primary key:** composite, `(flight_id, airport_code)`. This directly expresses the many-to-many relationship: one flight touches several airports, and one airport is touched by many flights.

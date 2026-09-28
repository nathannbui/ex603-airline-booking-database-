-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Airline Booking Database
-- Author: Nathan Bui
-- Target: PostgreSQL 14+
-- =================================================================

-- Reset.
-- Drop tables in reverse creation order so dependencies do not block
-- the script from being run again.

DROP TABLE IF EXISTS flight_routes CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS airports CASCADE;
DROP TABLE IF EXISTS flights CASCADE;
DROP TABLE IF EXISTS passengers CASCADE;

-- ----------------------------------------------------------------
-- 1. passengers
-- Created first because it does not reference any other table.
-- ----------------------------------------------------------------
CREATE TABLE passengers (
    passenger_id INTEGER GENERATED ALWAYS AS IDENTITY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE NOT NULL,
    passport_number VARCHAR(20) NOT NULL,
    loyalty_tier VARCHAR(20) NOT NULL DEFAULT 'standard',

    CONSTRAINT pk_passengers PRIMARY KEY (passenger_id),
    CONSTRAINT uq_passengers_email UNIQUE (email),
    CONSTRAINT uq_passengers_passport UNIQUE (passport_number),
    CONSTRAINT chk_passengers_loyalty_tier
        CHECK (loyalty_tier IN ('standard', 'silver', 'gold', 'platinum'))
);

-- ----------------------------------------------------------------
-- 2. flights
--  second because it does not reference any other table....
-- ----------------------------------------------------------------

CREATE TABLE flights (
    flight_id INTEGER GENERATED ALWAYS AS IDENTITY,
    flight_number VARCHAR(10) NOT NULL,
    airline VARCHAR(100) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    flight_status VARCHAR(20) NOT NULL,

    CONSTRAINT pk_flights PRIMARY KEY (flight_id),
    CONSTRAINT uq_flights_flight_number UNIQUE (flight_number),
    CONSTRAINT chk_flights_times
        CHECK (arrival_time > departure_time)
);

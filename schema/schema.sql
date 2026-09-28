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


USE eventhub_midterm;

-- Drop in child-to-parent order so the script can be re-run safely
DROP TABLE IF EXISTS booking_speakers;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS speakers;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS organizers;
DROP TABLE IF EXISTS venues;

-- venues: venue_code -> venue_name, venue_city, venue_capacity
CREATE TABLE venues (
    venue_code     VARCHAR(20)  NOT NULL,
    venue_name     VARCHAR(100) NOT NULL,
    venue_city     VARCHAR(50)  NOT NULL,
    venue_capacity INT          NOT NULL,
    CONSTRAINT pk_venues PRIMARY KEY (venue_code),
    CONSTRAINT chk_venues_capacity CHECK (venue_capacity > 0)
);

-- organizers: organizer_id -> organizer_name, organizer_email
CREATE TABLE organizers (
    organizer_id    INT          NOT NULL,
    organizer_name  VARCHAR(100) NOT NULL,
    organizer_email VARCHAR(100) NOT NULL,
    CONSTRAINT pk_organizers PRIMARY KEY (organizer_id),
    CONSTRAINT uq_organizers_email UNIQUE (organizer_email)
);

-- events: event_id (= booking_id in the flat table) ->
--         event_title, booking_date, organizer_id, venue_code
CREATE TABLE events (
    event_id     INT          NOT NULL,
    event_title  VARCHAR(150) NOT NULL,
    booking_date DATE         NOT NULL,
    organizer_id INT          NOT NULL,
    venue_code   VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_events PRIMARY KEY (event_id),
    CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id)
        REFERENCES organizers (organizer_id),
    CONSTRAINT fk_events_venue FOREIGN KEY (venue_code)
        REFERENCES venues (venue_code)
);

-- bookings: one row per (event, session) ticket booking.
-- (event_id, session_code) is the original composite key of the flat
-- table; it is kept as a UNIQUE candidate key and a surrogate booking_no
-- is the PK so the speaker junction table needs only a 2-column key.
CREATE TABLE bookings (
    booking_no      INT           NOT NULL AUTO_INCREMENT,
    event_id        INT           NOT NULL,
    session_code    VARCHAR(20)   NOT NULL,
    ticket_category VARCHAR(50)   NOT NULL,
    ticket_price    DECIMAL(8,2)  NOT NULL,
    tickets_booked  INT           NOT NULL,
    booking_status  VARCHAR(20)   NOT NULL DEFAULT 'CONFIRMED',
    CONSTRAINT pk_bookings PRIMARY KEY (booking_no),
    CONSTRAINT uq_bookings_event_session UNIQUE (event_id, session_code),
    CONSTRAINT fk_bookings_event FOREIGN KEY (event_id)
        REFERENCES events (event_id),
    CONSTRAINT chk_bookings_price CHECK (ticket_price >= 0.00),
    CONSTRAINT chk_bookings_tickets CHECK (tickets_booked > 0)
);

-- speakers: speaker_id -> speaker_name
CREATE TABLE speakers (
    speaker_id   INT          NOT NULL AUTO_INCREMENT,
    speaker_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_speakers PRIMARY KEY (speaker_id),
    CONSTRAINT uq_speakers_name UNIQUE (speaker_name)
);

-- booking_speakers: junction table for the many-to-many relationship
-- between bookings (sessions) and speakers. Composite PK + two FKs.
CREATE TABLE booking_speakers (
    booking_no INT NOT NULL,
    speaker_id INT NOT NULL,
    CONSTRAINT pk_booking_speakers PRIMARY KEY (booking_no, speaker_id),
    CONSTRAINT fk_bs_booking FOREIGN KEY (booking_no)
        REFERENCES bookings (booking_no),
    CONSTRAINT fk_bs_speaker FOREIGN KEY (speaker_id)
        REFERENCES speakers (speaker_id)
);

-- Verification
SHOW TABLES;

DESCRIBE venues;
DESCRIBE organizers;
DESCRIBE events;
DESCRIBE bookings;
DESCRIBE speakers;
DESCRIBE booking_speakers;

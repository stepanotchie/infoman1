
USE eventhub_midterm;

-- PART A: MIGRATION from event_booking_flat into the 3NF tables
-- Parents are loaded before children so foreign keys are always valid.

-- A1. venues: one row per distinct venue_code
INSERT INTO venues (venue_code, venue_name, venue_city, venue_capacity)
SELECT DISTINCT venue_code, venue_name, venue_city, venue_capacity
FROM event_booking_flat
ORDER BY venue_code;

-- A2. organizers: one row per distinct organizer_id
INSERT INTO organizers (organizer_id, organizer_name, organizer_email)
SELECT DISTINCT organizer_id, organizer_name, organizer_email
FROM event_booking_flat
ORDER BY organizer_id;

-- A3. events: one row per flat booking_id (title/date/organizer/venue
--     depend only on booking_id, so the 7 flat rows collapse to 6 events)
INSERT INTO events (event_id, event_title, booking_date, organizer_id, venue_code)
SELECT DISTINCT booking_id, event_title, booking_date, organizer_id, venue_code
FROM event_booking_flat
ORDER BY booking_id;

-- A4. bookings: one row per flat row (booking_id, session_code)
INSERT INTO bookings (event_id, session_code, ticket_category, ticket_price, tickets_booked)
SELECT booking_id, session_code, ticket_category, ticket_price, tickets_booked
FROM event_booking_flat
ORDER BY booking_id, session_code;

-- A5. speakers: split the comma-separated speaker_list into atomic names.
--     The derived table n (1,2,3) generates one row per list position;
--     SUBSTRING_INDEX twice extracts the n-th item, TRIM removes the space
--     after the comma. The ON condition stops n at the real item count
--     (commas + 1).
INSERT INTO speakers (speaker_name)
SELECT DISTINCT
       TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(f.speaker_list, ',', n.n), ',', -1)) AS speaker_name
FROM event_booking_flat AS f
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) AS n
  ON n.n <= 1 + LENGTH(f.speaker_list) - LENGTH(REPLACE(f.speaker_list, ',', ''))
WHERE f.speaker_list IS NOT NULL
ORDER BY speaker_name;

-- A6. booking_speakers: same split, then look up the surrogate keys
INSERT INTO booking_speakers (booking_no, speaker_id)
SELECT DISTINCT b.booking_no, s.speaker_id
FROM event_booking_flat AS f
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) AS n
  ON n.n <= 1 + LENGTH(f.speaker_list) - LENGTH(REPLACE(f.speaker_list, ',', ''))
JOIN bookings AS b
  ON b.event_id = f.booking_id AND b.session_code = f.session_code
JOIN speakers AS s
  ON s.speaker_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(f.speaker_list, ',', n.n), ',', -1))
WHERE f.speaker_list IS NOT NULL;

-- A7. Migration check: row counts and speaker links
SELECT 'venues' AS table_name, COUNT(*) AS row_count FROM venues
UNION ALL SELECT 'organizers',       COUNT(*) FROM organizers
UNION ALL SELECT 'events',           COUNT(*) FROM events
UNION ALL SELECT 'bookings',         COUNT(*) FROM bookings
UNION ALL SELECT 'speakers',         COUNT(*) FROM speakers
UNION ALL SELECT 'booking_speakers', COUNT(*) FROM booking_speakers;

SELECT b.booking_no, b.event_id, b.session_code, s.speaker_name
FROM booking_speakers AS bs
JOIN bookings AS b ON b.booking_no = bs.booking_no
JOIN speakers AS s ON s.speaker_id = bs.speaker_id
ORDER BY b.booking_no, s.speaker_name;

-- PART B: Add the new venue V-CAMPUS
INSERT INTO venues (venue_code, venue_name, venue_city, venue_capacity)
VALUES ('V-CAMPUS', 'University Amphitheater', 'Quezon City', 500);

SELECT * FROM venues ORDER BY venue_code;

-- PART C: SAFE CHANGE LOOP -- 10% increase on tickets priced above 400.00

-- Step 1: Preview the rows the UPDATE will touch (and the new price)
SELECT booking_no, event_id, session_code, ticket_category,
       ticket_price AS old_price,
       ROUND(ticket_price * 1.10, 2) AS new_price
FROM bookings
WHERE ticket_price > 400.00
ORDER BY booking_no;

-- Step 2: Confirm the target row count (expect 4)
SELECT COUNT(*) AS rows_to_update
FROM bookings
WHERE ticket_price > 400.00;

-- Step 3: Execute the targeted UPDATE (same WHERE as the preview)
UPDATE bookings
SET ticket_price = ROUND(ticket_price * 1.10, 2)
WHERE ticket_price > 400.00;

-- Step 4: Verify the modification (rows affected should be 4)
SELECT booking_no, event_id, session_code, ticket_category, ticket_price AS new_price
FROM bookings
ORDER BY booking_no;

-- PART D: SAFE CHANGE LOOP -- DELETE of temporary venue V-TEMP
INSERT INTO venues (venue_code, venue_name, venue_city, venue_capacity)
VALUES ('V-TEMP', 'Temporary Pop-up Hall', 'Makati', 50);

-- Step 1: Preview the row to be deleted (by primary key)
SELECT * FROM venues WHERE venue_code = 'V-TEMP';

-- Step 2: Confirm the target count (expect 1) and that nothing references it
SELECT COUNT(*) AS rows_to_delete FROM venues WHERE venue_code = 'V-TEMP';
SELECT COUNT(*) AS events_using_venue FROM events WHERE venue_code = 'V-TEMP';

-- Step 3: Execute the DELETE using the primary key
DELETE FROM venues WHERE venue_code = 'V-TEMP';

-- Step 4: Verify it is gone (expect 0) and the real venues are untouched
SELECT COUNT(*) AS remaining_v_temp FROM venues WHERE venue_code = 'V-TEMP';
SELECT venue_code, venue_name, venue_city, venue_capacity FROM venues ORDER BY venue_code;

-- PART E: CONSTRAINT PROTECTION -- negative ticket price
-- EXPECTED TO FAIL: chk_bookings_price (ticket_price >= 0.00)
INSERT INTO bookings (event_id, session_code, ticket_category, ticket_price, tickets_booked)
VALUES (101, 'SESS-X9', 'Standard', -100.00, 1);

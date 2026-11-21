

USE eventhub_midterm;

-- 1. Lossless 4-table INNER JOIN: bookings -> events -> venues -> organizers
-- Every join predicate is PK = FK. Expect 7 rows (same as the flat table).
-- total_price = tickets_booked * ticket_price (prices reflect the Task 3
-- 10% increase on tickets originally above 400.00).
SELECT e.event_title      AS event_title,
       o.organizer_name   AS organizer_name,
       v.venue_name       AS venue_name,
       b.ticket_category  AS ticket_category,
       b.tickets_booked   AS tickets_booked,
       b.tickets_booked * b.ticket_price AS total_price
FROM bookings   AS b
INNER JOIN events     AS e ON e.event_id     = b.event_id
INNER JOIN venues     AS v ON v.venue_code   = e.venue_code
INNER JOIN organizers AS o ON o.organizer_id = e.organizer_id
ORDER BY e.event_id, b.session_code;

-- Losslessness check: compare against the original flat table on every
-- column the Task 3 price update did not change. Expect mismatches = 0.
SELECT COUNT(*) AS flat_rows,
       SUM(
         e.event_title      = f.event_title
         AND o.organizer_name  = f.organizer_name
         AND o.organizer_email = f.organizer_email
         AND v.venue_name      = f.venue_name
         AND v.venue_city      = f.venue_city
         AND v.venue_capacity  = f.venue_capacity
         AND e.booking_date    = f.booking_date
         AND b.ticket_category = f.ticket_category
         AND b.tickets_booked  = f.tickets_booked
       ) AS matching_rows
FROM event_booking_flat AS f
INNER JOIN bookings   AS b ON b.event_id = f.booking_id AND b.session_code = f.session_code
INNER JOIN events     AS e ON e.event_id     = b.event_id
INNER JOIN venues     AS v ON v.venue_code   = e.venue_code
INNER JOIN organizers AS o ON o.organizer_id = e.organizer_id;

-- 2. Outer-join missing-record diagnostic (preserve-then-filter)
-- Step 1 (preserve): LEFT JOIN keeps every venue, even with no match.
-- Step 2 (filter):   WHERE b.booking_no IS NULL keeps only unmatched ones.
-- The events+bookings pair is joined as one nested unit so a venue that
-- has an event but zero bookings is also detected correctly.
-- Expect: V-CAMPUS only.
SELECT v.venue_code, v.venue_name, v.venue_city
FROM venues AS v
LEFT JOIN (events AS e
           INNER JOIN bookings AS b ON b.event_id = e.event_id)
       ON e.venue_code = v.venue_code
WHERE b.booking_no IS NULL;

-- 3. The "Silent Inner Join" trap

-- Version A (FLAWED): the filter on the right-hand table is in WHERE.
-- Unbooked venues carry NULL in ticket_category, NULL = 'VIP' is not TRUE,
-- so those rows are discarded and the LEFT JOIN behaves like an INNER JOIN.
SELECT v.venue_code, v.venue_name, b.session_code, b.ticket_category, b.tickets_booked
FROM venues AS v
LEFT JOIN (events AS e
           INNER JOIN bookings AS b ON b.event_id = e.event_id)
       ON e.venue_code = v.venue_code
WHERE b.ticket_category = 'VIP'
ORDER BY v.venue_code;

-- Version B (CORRECT): the filter is part of the ON clause, so it limits
-- which bookings match but never removes a venue. Venues without a VIP
-- booking are kept with NULLs in the booking columns.
SELECT v.venue_code, v.venue_name, b.session_code, b.ticket_category, b.tickets_booked
FROM venues AS v
LEFT JOIN (events AS e
           INNER JOIN bookings AS b ON b.event_id = e.event_id)
       ON e.venue_code = v.venue_code
      AND b.ticket_category = 'VIP'
ORDER BY v.venue_code;

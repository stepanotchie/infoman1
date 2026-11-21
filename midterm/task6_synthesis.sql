
USE eventhub_midterm;

-- 1. Schema evolution: add venue_status with a default and a CHECK.
-- Existing rows receive the DEFAULT 'ACTIVE', so NOT NULL succeeds.
ALTER TABLE venues
    ADD COLUMN venue_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    ADD CONSTRAINT chk_venues_status
        CHECK (venue_status IN ('ACTIVE', 'RENOVATION', 'INACTIVE'));

DESCRIBE venues;
SELECT venue_code, venue_name, venue_status FROM venues ORDER BY venue_code;

-- 2. Safe update of V-PARK (primary key in WHERE)
-- Preview
SELECT venue_code, venue_name, venue_status FROM venues WHERE venue_code = 'V-PARK';
-- Execute
UPDATE venues SET venue_status = 'RENOVATION' WHERE venue_code = 'V-PARK';
-- Verify
SELECT venue_code, venue_name, venue_status FROM venues ORDER BY venue_code;

-- 3. Integrated analytical report (Weeks 7, 8, 9)
--    joins (venues, events, bookings) + WHERE (Week 7) + GROUP BY and
--    aggregates + HAVING (Week 8) + ORDER BY (Week 7)
SELECT v.venue_name,
       v.venue_city,
       COUNT(b.booking_no)                  AS total_bookings,
       SUM(b.tickets_booked)                AS total_attendees,
       ROUND(AVG(b.ticket_price), 2)        AS avg_ticket_price,
       SUM(b.tickets_booked * b.ticket_price) AS total_revenue
FROM venues AS v
INNER JOIN events   AS e ON e.venue_code = v.venue_code
INNER JOIN bookings AS b ON b.event_id   = e.event_id
WHERE v.venue_status = 'ACTIVE'
GROUP BY v.venue_name, v.venue_city
HAVING AVG(b.ticket_price) > 300.00
ORDER BY total_revenue DESC;

-- 4. Constraint test -- EXPECTED TO FAIL: chk_venues_status
UPDATE venues SET venue_status = 'CLOSED' WHERE venue_code = 'V-CAMPUS';

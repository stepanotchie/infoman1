
USE eventhub_midterm;

-- Query 1: Compound filtering with explicit precedence (Week 7)
-- Date range AND (VIP OR price > 500). Without the parentheses, AND binds
-- tighter than OR, so "VIP OR price > 500" would escape the date filter.
SELECT e.event_id, e.event_title, e.booking_date,
       b.session_code, b.ticket_category, b.ticket_price, b.tickets_booked
FROM bookings AS b
INNER JOIN events AS e ON e.event_id = b.event_id
WHERE e.booking_date BETWEEN '2025-04-10' AND '2025-04-20'
  AND (b.ticket_category = 'VIP' OR b.ticket_price > 500.00)
ORDER BY e.booking_date, b.session_code;

-- Query 2: Scalar string and date functions (Week 7)
-- contact_card via CONCAT; days elapsed via DATEDIFF(later, earlier)
SELECT e.event_id,
       e.event_title,
       CONCAT(o.organizer_name, ' <', o.organizer_email, '>') AS contact_card,
       e.booking_date,
       DATEDIFF('2025-05-01', e.booking_date) AS days_elapsed
FROM events AS e
INNER JOIN organizers AS o ON o.organizer_id = e.organizer_id
ORDER BY e.booking_date, e.event_id;

-- Query 3: Pattern matching with wildcards (Week 8)
-- '%City' = ends with City; 'M%' = starts with M
SELECT venue_code, venue_name, venue_city, venue_capacity
FROM venues
WHERE venue_city LIKE '%City'
   OR venue_city LIKE 'M%'
ORDER BY venue_city, venue_code;

-- Query 4: GROUP BY with HAVING (Week 8)
-- HAVING filters the per-category totals; WHERE cannot see SUM() because
-- it runs before grouping.
SELECT ticket_category,
       SUM(tickets_booked)                 AS total_tickets,
       SUM(tickets_booked * ticket_price)  AS gross_revenue
FROM bookings
GROUP BY ticket_category
HAVING SUM(tickets_booked) >= 5
ORDER BY gross_revenue DESC;

-- =====================================================================
-- OUTPUT (captured from MySQL 8.0, in query order Q1 -> Q4)
-- Q4 note: VIP (3 tickets) is removed by HAVING SUM(tickets_booked) >= 5
-- =====================================================================
-- +----------+-------------------------+--------------+--------------+-----------------+--------------+----------------+
-- | event_id | event_title             | booking_date | session_code | ticket_category | ticket_price | tickets_booked |
-- +----------+-------------------------+--------------+--------------+-----------------+--------------+----------------+
-- |      101 | Modern Web & DB Summit  | 2025-04-10   | SESS-A1      | Standard        |       550.00 |              4 |
-- |      101 | Modern Web & DB Summit  | 2025-04-10   | SESS-A2      | VIP             |      1320.00 |              2 |
-- |      105 | Health Informatics 2025 | 2025-04-20   | SESS-D1      | VIP             |      1650.00 |              1 |
-- +----------+-------------------------+--------------+--------------+-----------------+--------------+----------------+
-- +----------+-----------------------------+-------------------------------------------------+--------------+--------------+
-- | event_id | event_title                 | contact_card                                    | booking_date | days_elapsed |
-- +----------+-----------------------------+-------------------------------------------------+--------------+--------------+
-- |      101 | Modern Web & DB Summit      | Tech Forward PH <info@techforward.ph>           | 2025-04-10   |           21 |
-- |      102 | Urban Ecology Seminar       | Green Earth Initiative <contact@greenearth.org> | 2025-04-12   |           19 |
-- |      103 | AI & Cloud Infrastructure   | Innovate Campus Lab <lead@innovatecampus.edu>   | 2025-04-15   |           16 |
-- |      104 | Community Climate Action    | Green Earth Initiative <contact@greenearth.org> | 2025-04-18   |           13 |
-- |      105 | Health Informatics 2025     | Digital Health Alliance <care@digitalhealth.ph> | 2025-04-20   |           11 |
-- |      106 | Telemedicine Implementation | Digital Health Alliance <care@digitalhealth.ph> | 2025-04-22   |            9 |
-- +----------+-----------------------------+-------------------------------------------------+--------------+--------------+
-- +------------+-------------------------+-------------+----------------+
-- | venue_code | venue_name              | venue_city  | venue_capacity |
-- +------------+-------------------------+-------------+----------------+
-- | V-BAY      | Bayview Convention Hall | Manila      |            150 |
-- | V-CAMPUS   | University Amphitheater | Quezon City |            500 |
-- | V-METRO    | Metro Tech Auditorium   | Quezon City |            300 |
-- +------------+-------------------------+-------------+----------------+
-- +-----------------+---------------+---------------+
-- | ticket_category | total_tickets | gross_revenue |
-- +-----------------+---------------+---------------+
-- | Standard        |            18 |       8960.00 |
-- | Student         |            10 |       2500.00 |
-- +-----------------+---------------+---------------+

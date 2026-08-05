USE travel_booking_fraud;

-- Detect devices used by multiple customers
CREATE OR REPLACE VIEW vw_shared_devices AS
SELECT
    device_id,
    COUNT(DISTINCT customer_id) AS customers_using_device,
    COUNT(*) AS total_bookings
FROM bookings
GROUP BY device_id
HAVING COUNT(DISTINCT customer_id) >= 2;

-- Detect cards used by multiple customers
CREATE OR REPLACE VIEW vw_shared_cards AS
SELECT
    p.card_id,
    COUNT(DISTINCT b.customer_id) AS customers_using_card,
    COUNT(DISTINCT b.booking_id) AS total_bookings
FROM payments p
JOIN bookings b
    ON p.booking_id = b.booking_id
GROUP BY p.card_id
HAVING COUNT(DISTINCT b.customer_id) >= 2;

-- Combine booking, customer, payment and fraud signals
CREATE OR REPLACE VIEW vw_booking_fraud_analysis AS
SELECT
    b.booking_id,
    b.customer_id,
    c.full_name,
    c.country_code AS customer_country,
    c.account_created_date,
    b.booking_date,
    b.departure_date,
    b.departure_airport,
    b.arrival_airport,
    b.booking_amount,
    b.passenger_count,
    b.booking_status,
    b.device_id,
    b.ip_country_code,
    p.payment_id,
    p.payment_method,
    p.card_id,
    p.card_country_code,
    p.payment_status,
    p.failed_attempts,

    DATEDIFF(b.departure_date, DATE(b.booking_date)) AS days_before_departure,
    DATEDIFF(DATE(b.booking_date), c.account_created_date) AS account_age_days,

    CASE
        WHEN b.booking_amount >= 1500 THEN 1
        ELSE 0
    END AS high_value_flag,

    CASE
        WHEN DATEDIFF(b.departure_date, DATE(b.booking_date)) <= 2
             AND b.booking_amount >= 800
        THEN 1
        ELSE 0
    END AS last_minute_flag,

    CASE
        WHEN c.country_code <> b.ip_country_code
             OR c.country_code <> p.card_country_code
        THEN 1
        ELSE 0
    END AS country_mismatch_flag,

    CASE
        WHEN p.failed_attempts >= 3 THEN 1
        ELSE 0
    END AS failed_payment_flag,

    CASE
        WHEN DATEDIFF(DATE(b.booking_date), c.account_created_date) <= 7
             AND b.booking_amount >= 1000
        THEN 1
        ELSE 0
    END AS new_account_high_value_flag,

    CASE
        WHEN sd.device_id IS NOT NULL THEN 1
        ELSE 0
    END AS shared_device_flag,

    CASE
        WHEN sc.card_id IS NOT NULL THEN 1
        ELSE 0
    END AS shared_card_flag,

    COALESCE(f.fraud_confirmed, FALSE) AS fraud_confirmed,
    f.investigation_status

FROM bookings b
JOIN customers c
    ON b.customer_id = c.customer_id
JOIN payments p
    ON b.booking_id = p.booking_id
LEFT JOIN fraud_labels f
    ON b.booking_id = f.booking_id
LEFT JOIN vw_shared_devices sd
    ON b.device_id = sd.device_id
LEFT JOIN vw_shared_cards sc
    ON p.card_id = sc.card_id;

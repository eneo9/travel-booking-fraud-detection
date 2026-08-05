USE travel_booking_fraud;

CREATE OR REPLACE VIEW vw_powerbi_fraud_bookings AS
SELECT
    booking_id,
    customer_id,
    full_name,
    customer_country,
    booking_date,
    DATE(booking_date) AS booking_day,
    YEAR(booking_date) AS booking_year,
    MONTH(booking_date) AS booking_month_number,
    DATE_FORMAT(booking_date, '%Y-%m') AS booking_month,
    departure_date,
    departure_airport,
    arrival_airport,
    CONCAT(departure_airport, ' - ', arrival_airport) AS route,
    booking_amount,
    booking_status,
    payment_method,
    payment_status,
    failed_attempts,
    device_id,
    card_id,
    ip_country_code,
    card_country_code,
    days_before_departure,
    account_age_days,
    high_value_flag,
    last_minute_flag,
    country_mismatch_flag,
    failed_payment_flag,
    new_account_high_value_flag,
    shared_device_flag,
    shared_card_flag,
    fraud_risk_score,
    risk_level,
    recommended_action,
    fraud_confirmed,
    investigation_status
FROM vw_fraud_dashboard;

CREATE OR REPLACE VIEW vw_powerbi_monthly_fraud AS
SELECT
    DATE_FORMAT(booking_date, '%Y-%m') AS booking_month,
    COUNT(*) AS total_bookings,
    ROUND(SUM(booking_amount), 2) AS total_booking_value,
    SUM(fraud_confirmed) AS confirmed_fraud,
    ROUND(100.0 * SUM(fraud_confirmed) / COUNT(*), 2) AS fraud_rate_percent,
    ROUND(
        SUM(
            CASE
                WHEN fraud_confirmed = 1 THEN booking_amount
                ELSE 0
            END
        ),
        2
    ) AS fraudulent_booking_value
FROM vw_fraud_dashboard
GROUP BY DATE_FORMAT(booking_date, '%Y-%m');

CREATE OR REPLACE VIEW vw_powerbi_risk_summary AS
SELECT
    risk_level,
    COUNT(*) AS total_bookings,
    ROUND(SUM(booking_amount), 2) AS total_booking_value,
    ROUND(AVG(fraud_risk_score), 2) AS average_risk_score,
    SUM(fraud_confirmed) AS confirmed_fraud,
    SUM(
        CASE
            WHEN fraud_confirmed = 0
                 AND risk_level IN ('High', 'Critical')
            THEN 1
            ELSE 0
        END
    ) AS false_positives
FROM vw_fraud_dashboard
GROUP BY risk_level;

CREATE OR REPLACE VIEW vw_powerbi_payment_summary AS
SELECT
    payment_method,
    COUNT(*) AS total_bookings,
    ROUND(SUM(booking_amount), 2) AS total_booking_value,
    SUM(fraud_confirmed) AS confirmed_fraud,
    ROUND(100.0 * SUM(fraud_confirmed) / COUNT(*), 2) AS fraud_rate_percent,
    ROUND(AVG(fraud_risk_score), 2) AS average_risk_score
FROM vw_fraud_dashboard
GROUP BY payment_method;

CREATE OR REPLACE VIEW vw_powerbi_country_summary AS
SELECT
    customer_country,
    COUNT(*) AS total_bookings,
    ROUND(SUM(booking_amount), 2) AS total_booking_value,
    SUM(fraud_confirmed) AS confirmed_fraud,
    ROUND(100.0 * SUM(fraud_confirmed) / COUNT(*), 2) AS fraud_rate_percent,
    ROUND(AVG(fraud_risk_score), 2) AS average_risk_score
FROM vw_fraud_dashboard
GROUP BY customer_country;

CREATE OR REPLACE VIEW vw_powerbi_signal_summary AS
SELECT 'High value booking' AS fraud_signal, SUM(high_value_flag) AS flagged_bookings
FROM vw_fraud_dashboard

UNION ALL

SELECT 'Last-minute booking', SUM(last_minute_flag)
FROM vw_fraud_dashboard

UNION ALL

SELECT 'Country mismatch', SUM(country_mismatch_flag)
FROM vw_fraud_dashboard

UNION ALL

SELECT 'Repeated failed payments', SUM(failed_payment_flag)
FROM vw_fraud_dashboard

UNION ALL

SELECT 'New account and high value', SUM(new_account_high_value_flag)
FROM vw_fraud_dashboard

UNION ALL

SELECT 'Shared device', SUM(shared_device_flag)
FROM vw_fraud_dashboard

UNION ALL

SELECT 'Shared card', SUM(shared_card_flag)
FROM vw_fraud_dashboard;

CREATE OR REPLACE VIEW vw_powerbi_chargeback_summary AS
SELECT
    cb.chargeback_reason,
    COUNT(*) AS total_chargebacks,
    ROUND(SUM(cb.chargeback_amount), 2) AS total_chargeback_value,
    ROUND(AVG(cb.chargeback_amount), 2) AS average_chargeback_value
FROM chargebacks cb
GROUP BY cb.chargeback_reason;

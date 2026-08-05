USE travel_booking_fraud;

-- Calculate fraud risk points for each booking
CREATE OR REPLACE VIEW vw_booking_risk_scores AS
SELECT
    booking_id,
    customer_id,
    full_name,
    customer_country,
    booking_date,
    departure_date,
    departure_airport,
    arrival_airport,
    booking_amount,
    booking_status,
    device_id,
    ip_country_code,
    payment_method,
    card_id,
    card_country_code,
    payment_status,
    failed_attempts,
    days_before_departure,
    account_age_days,

    high_value_flag,
    last_minute_flag,
    country_mismatch_flag,
    failed_payment_flag,
    new_account_high_value_flag,
    shared_device_flag,
    shared_card_flag,

    high_value_flag * 20 AS high_value_points,
    last_minute_flag * 15 AS last_minute_points,
    country_mismatch_flag * 15 AS country_mismatch_points,
    failed_payment_flag * 15 AS failed_payment_points,
    new_account_high_value_flag * 10 AS new_account_points,
    shared_device_flag * 20 AS shared_device_points,
    shared_card_flag * 25 AS shared_card_points,

    (
        high_value_flag * 20
        + last_minute_flag * 15
        + country_mismatch_flag * 15
        + failed_payment_flag * 15
        + new_account_high_value_flag * 10
        + shared_device_flag * 20
        + shared_card_flag * 25
    ) AS fraud_risk_score,

    fraud_confirmed,
    investigation_status

FROM vw_booking_fraud_analysis;

-- Assign risk level and recommended action
CREATE OR REPLACE VIEW vw_fraud_dashboard AS
SELECT
    rs.*,

    CASE
        WHEN fraud_risk_score >= 90 THEN 'Critical'
        WHEN fraud_risk_score >= 60 THEN 'High'
        WHEN fraud_risk_score >= 30 THEN 'Medium'
        ELSE 'Low'
    END AS risk_level,

    CASE
        WHEN fraud_risk_score >= 90 THEN 'Block and investigate'
        WHEN fraud_risk_score >= 60 THEN 'Manual review'
        WHEN fraud_risk_score >= 30 THEN 'Additional verification'
        ELSE 'Allow'
    END AS recommended_action

FROM vw_booking_risk_scores rs;

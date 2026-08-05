USE travel_booking_fraud;

-- Overall project performance
SELECT
    COUNT(*) AS total_bookings,
    SUM(fraud_confirmed) AS confirmed_fraud,
    SUM(
        CASE
            WHEN fraud_confirmed = 1
                 AND risk_level IN ('High', 'Critical')
            THEN 1
            ELSE 0
        END
    ) AS detected_fraud,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN fraud_confirmed = 1
                     AND risk_level IN ('High', 'Critical')
                THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(fraud_confirmed), 0),
        2
    ) AS detection_rate_percent,
    SUM(
        CASE
            WHEN fraud_confirmed = 0
                 AND risk_level IN ('High', 'Critical')
            THEN 1
            ELSE 0
        END
    ) AS false_positives,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN fraud_confirmed = 0
                     AND risk_level IN ('High', 'Critical')
                THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(CASE WHEN fraud_confirmed = 0 THEN 1 ELSE 0 END), 0),
        2
    ) AS false_positive_rate_percent
FROM vw_fraud_dashboard;

-- Highest-risk bookings for investigation
SELECT
    booking_id,
    full_name,
    customer_country,
    departure_airport,
    arrival_airport,
    booking_amount,
    payment_method,
    failed_attempts,
    fraud_risk_score,
    risk_level,
    recommended_action,
    fraud_confirmed
FROM vw_fraud_dashboard
WHERE risk_level IN ('High', 'Critical')
ORDER BY fraud_risk_score DESC, booking_amount DESC;

-- Monthly fraud trend
SELECT *
FROM vw_powerbi_monthly_fraud
ORDER BY booking_month;

-- Risk-level summary
SELECT *
FROM vw_powerbi_risk_summary
ORDER BY
    CASE risk_level
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        ELSE 4
    END;

-- Fraud performance by payment method
SELECT *
FROM vw_powerbi_payment_summary
ORDER BY fraud_rate_percent DESC;

-- Fraud performance by customer country
SELECT *
FROM vw_powerbi_country_summary
ORDER BY fraud_rate_percent DESC;

-- Most common fraud signals
SELECT *
FROM vw_powerbi_signal_summary
ORDER BY flagged_bookings DESC;

-- Chargeback summary
SELECT *
FROM vw_powerbi_chargeback_summary
ORDER BY total_chargeback_value DESC;

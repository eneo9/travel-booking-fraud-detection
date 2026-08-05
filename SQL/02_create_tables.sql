USE travel_booking_fraud;

CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(150),
    account_created_date DATE,
    country_code CHAR(2)
);

CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT PRIMARY KEY,
    customer_id INT,
    booking_date DATETIME,
    departure_date DATE,
    departure_airport CHAR(3),
    arrival_airport CHAR(3),
    booking_amount DECIMAL(10,2),
    currency_code CHAR(3),
    passenger_count INT,
    booking_status VARCHAR(30),
    device_id VARCHAR(50),
    ip_address VARCHAR(45),
    ip_country_code CHAR(2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id INT PRIMARY KEY,
    booking_id INT,
    payment_date DATETIME,
    payment_amount DECIMAL(10,2),
    payment_method VARCHAR(30),
    card_id VARCHAR(50),
    card_country_code CHAR(2),
    payment_status VARCHAR(30),
    failed_attempts INT,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE IF NOT EXISTS passengers (
    passenger_id INT PRIMARY KEY,
    booking_id INT,
    passenger_name VARCHAR(100),
    passenger_country_code CHAR(2),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE IF NOT EXISTS chargebacks (
    chargeback_id INT PRIMARY KEY,
    payment_id INT,
    chargeback_date DATE,
    chargeback_amount DECIMAL(10,2),
    chargeback_reason VARCHAR(100),
    FOREIGN KEY (payment_id) REFERENCES payments(payment_id)
);

CREATE TABLE IF NOT EXISTS fraud_labels (
    booking_id INT PRIMARY KEY,
    fraud_confirmed BOOLEAN DEFAULT FALSE,
    investigation_status VARCHAR(30),
    investigation_date DATE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

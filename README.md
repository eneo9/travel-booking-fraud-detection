# Travel Booking Fraud Detection

## Dashboard Screenshots

### Fraud Overview

![Chargebacks and Fraud Patterns](Screenshots/chargebacks_fraud_patterns.png)


### Fraud Investigation

![Fraud Investigation](Screenshots/fraud_investigation.png)


### Chargebacks and Fraud Patterns

![Fraud Overview](Screenshots/fraud_overview.png)



I created this project to explore how suspicious travel bookings could be identified using SQL rules, risk scoring and Power BI.

The project uses synthetic data that I generated with Python. It includes customers, bookings, payments, passengers, chargebacks and confirmed fraud cases.

The main goal was to build a simple fraud detection process from start to finish:

- generate the data
- store it in MySQL
- create fraud detection rules
- calculate a risk score for every booking
- measure how well the rules worked
- present the results in Power BI

## What the project checks

I created several fraud rules based on common suspicious patterns:

- high-value bookings
- last-minute bookings
- mismatches between customer, card and IP country
- repeated failed payment attempts
- new accounts making expensive bookings
- devices used by multiple customers
- cards used by multiple customers

Each rule adds points to the booking's fraud risk score.

The final score places each booking into one of four levels:

| Risk Score | Risk Level | Action |
|---|---|---|
| 90 or above | Critical | Block and investigate |
| 60–89 | High | Manual review |
| 30–59 | Medium | Additional verification |
| Below 30 | Low | Allow |

## Main results

The project contains:

- 8,000 bookings
- 480 confirmed fraud cases
- 410 confirmed fraud cases detected as High or Critical risk
- 85.42% fraud detection rate
- 2.39% false-positive rate
- £8.34M total booking value
- £982.76K fraudulent booking value
- 449 chargebacks
- £788.14K total chargeback value

## How to Run

**1. Set up the database**

Run the SQL scripts in order using MySQL Workbench (or the MySQL CLI):

- SQL/01_create_database.sql
- SQL/02_create_tables.sql
- SQL/03_fraud_detection_views.sql
- SQL/04_risk_scoring.sql
- SQL/05_powerbi_views.sql
- SQL/06_analysis_queries.sql

**2. Generate the synthetic data**

No external packages needed — the script only uses Python's standard library.

python generate_travel_fraud_data_v2.py


This creates six CSV files (`customers.csv`, `bookings.csv`, `payments.csv`, `passengers.csv`, `chargebacks.csv`, `fraud_labels.csv`), which can then be loaded into the corresponding MySQL tables.

**3. Open the dashboard**

Open `Dashboard/travel_fraud_dashboard.pbix` in Power BI Desktop and point the data source to your local MySQL instance (`travel_booking_fraud` database).

## Tools I used

- Python
- MySQL
- MySQL Workbench
- SQL
- Power BI
- CSV files

## Project structure

```text
travel-booking-fraud-detection/
├── Dashboard/
│   └── travel_fraud_dashboard.pbix
├── Data/
│   ├── chargeback_summary.csv
│   ├── country_summary.csv
│   ├── fraud_bookings_dashboard.csv
│   ├── monthly_fraud.csv
│   ├── payment_summary.csv
│   ├── risk_summary.csv
│   └── signal_summary.csv
├── Screenshots/
│   ├── fraud_overview.png
│   ├── fraud_investigation.png
│   └── chargebacks_fraud_patterns.png
├── SQL/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_fraud_detection_views.sql
│   ├── 04_risk_scoring.sql
│   ├── 05_powerbi_views.sql
│   └── 06_analysis_queries.sql
├── generate_travel_fraud_data_v2.py
├── .gitignore
└── README.md

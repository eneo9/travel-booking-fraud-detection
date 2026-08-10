#!/usr/bin/env python3
"""
Generate synthetic travel-booking fraud data.

Creates:
- customers.csv
- bookings.csv
- payments.csv
- passengers.csv
- chargebacks.csv
- fraud_labels.csv

Uses only Python's standard library.
"""

import argparse
import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

FIRST_NAMES = [
    "James", "Maria", "Daniel", "Sofia", "Alex", "Emma", "Liam", "Olivia",
    "Noah", "Ava", "Lucas", "Mia", "Ethan", "Isabella", "Leo", "Amelia"
]

LAST_NAMES = [
    "Smith", "Rossi", "Brown", "Garcia", "Miller", "Wilson", "Taylor",
    "Anderson", "Thomas", "Moore", "Martin", "Lee", "Clark", "Lewis"
]

COUNTRIES = ["GB", "IT", "ES", "FR", "DE", "US", "GR", "AL", "NL", "RO", "NG", "AE"]

AIRPORTS = {
    "GB": ["LHR", "LGW", "MAN"],
    "IT": ["FCO", "MXP", "VCE"],
    "ES": ["MAD", "BCN", "AGP"],
    "FR": ["CDG", "ORY", "NCE"],
    "DE": ["FRA", "MUC", "BER"],
    "US": ["JFK", "LAX", "ORD"],
    "GR": ["ATH", "SKG", "HER"],
    "AL": ["TIA"],
    "NL": ["AMS"],
    "RO": ["OTP"],
    "NG": ["LOS"],
    "AE": ["DXB", "AUH"],
}

PAYMENT_METHODS = ["Visa", "Mastercard", "Amex", "PayPal"]
BOOKING_STATUSES = ["Confirmed", "Completed", "Cancelled", "Pending Review"]
CHARGEBACK_REASONS = [
    "Cardholder did not recognise transaction",
    "Service not received",
    "Card reported stolen",
    "Duplicate transaction",
    "Fraudulent transaction",
]


def random_date(start, end):
    return start + timedelta(days=random.randint(0, (end - start).days))


def random_datetime(start, end):
    seconds = int((end - start).total_seconds())
    return start + timedelta(seconds=random.randint(0, seconds))


def write_csv(path, fieldnames, rows):
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def generate_data(customer_count, booking_count, output_dir, seed):
    random.seed(seed)
    output_dir.mkdir(parents=True, exist_ok=True)

    booking_start = datetime(2025, 1, 1)
    booking_end = datetime(2026, 7, 20, 23, 59, 59)

    customers = []
    for customer_id in range(1, customer_count + 1):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        created = random_date(date(2023, 1, 1), date(2026, 7, 15))
        dob = random_date(date(1955, 1, 1), date(2005, 12, 31))
        country = random.choice(COUNTRIES)

        customers.append({
            "customer_id": customer_id,
            "full_name": f"{first} {last}",
            "email": f"{first.lower()}.{last.lower()}{customer_id}@example.com",
            "account_created_date": created.isoformat(),
            "country_code": country,
            "date_of_birth": dob.isoformat(),
            "account_status": random.choices(
                ["Active", "Suspended", "Closed"], weights=[94, 4, 2], k=1
            )[0],
        })

    fraud_count = max(1, round(booking_count * 0.06))
    fraud_ids = set(random.sample(range(1, booking_count + 1), fraud_count))

    suspicious_devices = [f"DEV-FRAUD-{i:03d}" for i in range(1, max(4, booking_count // 250) + 1)]
    suspicious_cards = [f"CARD-FRAUD-{i:03d}" for i in range(1, max(4, booking_count // 300) + 1)]

    bookings = []
    payments = []
    passengers = []
    chargebacks = []
    fraud_labels = []

    passenger_id = 1
    chargeback_id = 1

    for booking_id in range(1, booking_count + 1):
        customer = random.choice(customers)
        customer_id = customer["customer_id"]
        customer_country = customer["country_code"]
        account_created = date.fromisoformat(customer["account_created_date"])
        is_fraud = booking_id in fraud_ids

        earliest_booking = max(
            datetime.combine(account_created, datetime.min.time()),
            booking_start
        )

        booking_dt = random_datetime(earliest_booking, booking_end)

        if is_fraud:
            # Fraud is deliberately imperfect: not every fraudulent booking has every signal.
            departure_date = (
                booking_dt.date() + timedelta(days=random.randint(0, 2))
                if random.random() < 0.78
                else booking_dt.date() + timedelta(days=random.randint(3, 60))
            )
            amount = (
                round(random.uniform(1500, 3200), 2)
                if random.random() < 0.82
                else round(random.uniform(250, 1499), 2)
            )
            failed_attempts = (
                random.randint(3, 8)
                if random.random() < 0.70
                else random.randint(0, 2)
            )
            ip_country = (
                random.choice([c for c in COUNTRIES if c != customer_country])
                if random.random() < 0.72
                else customer_country
            )
            card_country = (
                random.choice([c for c in COUNTRIES if c != customer_country])
                if random.random() < 0.72
                else customer_country
            )
            device_id = (
                random.choice(suspicious_devices)
                if random.random() < 0.72
                else f"DEV-{customer_id:06d}"
            )
            card_id = (
                random.choice(suspicious_cards)
                if random.random() < 0.68
                else f"CARD-{customer_id:06d}-{random.randint(1, 2)}"
            )
            booking_status = random.choice(["Confirmed", "Pending Review"])
            payment_status = "Successful"
        else:
            # Genuine bookings can still look suspicious, creating realistic false positives.
            departure_date = (
                booking_dt.date() + timedelta(days=random.randint(0, 2))
                if random.random() < 0.10
                else booking_dt.date() + timedelta(days=random.randint(3, 180))
            )
            amount = (
                round(random.uniform(1500, 2600), 2)
                if random.random() < 0.15
                else round(random.uniform(70, 1499), 2)
            )
            failed_attempts = (
                random.randint(3, 5)
                if random.random() < 0.12
                else random.choices([0, 1, 2], weights=[84, 11, 5], k=1)[0]
            )
            ip_country = (
                random.choice([c for c in COUNTRIES if c != customer_country])
                if random.random() < 0.25
                else customer_country
            )
            card_country = (
                random.choice([c for c in COUNTRIES if c != customer_country])
                if random.random() < 0.20
                else customer_country
            )
            # Some genuine users share family/work devices and cards.
            device_id = (
                f"DEV-SHARED-{random.randint(1, 120):03d}"
                if random.random() < 0.15
                else f"DEV-{customer_id:06d}"
            )
            card_id = (
                f"CARD-SHARED-{random.randint(1, 100):03d}"
                if random.random() < 0.12
                else f"CARD-{customer_id:06d}-{random.randint(1, 2)}"
            )
            booking_status = random.choices(
                BOOKING_STATUSES, weights=[58, 30, 8, 4], k=1
            )[0]
            payment_status = random.choices(
                ["Successful", "Failed", "Refunded"], weights=[91, 6, 3], k=1
            )[0]

        departure_country = random.choice(COUNTRIES)
        arrival_country = random.choice([c for c in COUNTRIES if c != departure_country])
        passenger_count = random.randint(1, 4)

        bookings.append({
            "booking_id": booking_id,
            "customer_id": customer_id,
            "booking_date": booking_dt.strftime("%Y-%m-%d %H:%M:%S"),
            "departure_date": departure_date.isoformat(),
            "departure_airport": random.choice(AIRPORTS[departure_country]),
            "arrival_airport": random.choice(AIRPORTS[arrival_country]),
            "booking_amount": f"{amount:.2f}",
            "currency_code": "GBP",
            "passenger_count": passenger_count,
            "booking_status": booking_status,
            "device_id": device_id,
            "ip_address": ".".join([
                str(random.randint(1, 223)),
                str(random.randint(0, 255)),
                str(random.randint(0, 255)),
                str(random.randint(1, 254))
            ]),
            "ip_country_code": ip_country,
        })

        payments.append({
            "payment_id": booking_id,
            "booking_id": booking_id,
            "payment_date": (booking_dt + timedelta(minutes=random.randint(1, 10))).strftime("%Y-%m-%d %H:%M:%S"),
            "payment_amount": f"{amount:.2f}",
            "payment_method": random.choice(PAYMENT_METHODS),
            "card_id": card_id,
            "card_country_code": card_country,
            "payment_status": payment_status,
            "failed_attempts": failed_attempts,
        })

        for _ in range(passenger_count):
            first = random.choice(FIRST_NAMES)
            last = random.choice(LAST_NAMES)
            passengers.append({
                "passenger_id": passenger_id,
                "booking_id": booking_id,
                "passenger_name": f"{first} {last}",
                "passenger_country_code": random.choices(
                    [customer_country, random.choice(COUNTRIES)],
                    weights=[80, 20],
                    k=1,
                )[0],
            })
            passenger_id += 1

        fraud_labels.append({
            "booking_id": booking_id,
            "fraud_confirmed": 1 if is_fraud else 0,
            "investigation_status": "Confirmed Fraud" if is_fraud else "Cleared",
            "investigation_date": (booking_dt.date() + timedelta(days=random.randint(2, 30))).isoformat(),
        })

        chargeback_probability = 0.65 if is_fraud else 0.015
        if payment_status == "Successful" and random.random() < chargeback_probability:
            chargebacks.append({
                "chargeback_id": chargeback_id,
                "payment_id": booking_id,
                "chargeback_date": (booking_dt.date() + timedelta(days=random.randint(3, 45))).isoformat(),
                "chargeback_amount": f"{amount:.2f}",
                "chargeback_reason": random.choice(CHARGEBACK_REASONS),
            })
            chargeback_id += 1

    write_csv(
        output_dir / "customers.csv",
        ["customer_id", "full_name", "email", "account_created_date", "country_code",
         "date_of_birth", "account_status"],
        customers
    )

    write_csv(
        output_dir / "bookings.csv",
        ["booking_id", "customer_id", "booking_date", "departure_date",
         "departure_airport", "arrival_airport", "booking_amount", "currency_code",
         "passenger_count", "booking_status", "device_id", "ip_address",
         "ip_country_code"],
        bookings
    )

    write_csv(
        output_dir / "payments.csv",
        ["payment_id", "booking_id", "payment_date", "payment_amount",
         "payment_method", "card_id", "card_country_code", "payment_status",
         "failed_attempts"],
        payments
    )

    write_csv(
        output_dir / "passengers.csv",
        ["passenger_id", "booking_id", "passenger_name", "passenger_country_code"],
        passengers
    )

    write_csv(
        output_dir / "chargebacks.csv",
        ["chargeback_id", "payment_id", "chargeback_date", "chargeback_amount",
         "chargeback_reason"],
        chargebacks
    )

    write_csv(
        output_dir / "fraud_labels.csv",
        ["booking_id", "fraud_confirmed", "investigation_status", "investigation_date"],
        fraud_labels
    )

    print(f"Created files in: {output_dir.resolve()}")
    print(f"Customers: {len(customers)}")
    print(f"Bookings: {len(bookings)}")
    print(f"Payments: {len(payments)}")
    print(f"Passengers: {len(passengers)}")
    print(f"Chargebacks: {len(chargebacks)}")
    print(f"Confirmed fraud bookings: {sum(int(row['fraud_confirmed']) for row in fraud_labels)}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true")
    parser.add_argument("--output", default="travel_fraud_data")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    if args.test:
        customer_count = 20
        booking_count = 50
    else:
        customer_count = 2000
        booking_count = 8000

    generate_data(
        customer_count=customer_count,
        booking_count=booking_count,
        output_dir=Path(args.output),
        seed=args.seed
    )


if __name__ == "__main__":
    main()

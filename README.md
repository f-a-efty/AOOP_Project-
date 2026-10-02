# GREENIFY: Smart Plastic Collection & Reward System

**Greenify** is a smart plastic recycling and reward platform designed for Bangladesh. It connects citizens, smart collection booth hardware, recycling companies, and administrators. Citizens deposit plastic, earn reward tokens (`100 Tokens = 1 kg`), and cash out directly to their **bKash** account (`4 Tokens = ৳1.00 BDT`, minimum withdrawal `৳100.00 BDT`).

---

## Stack

- **Mobile**: Flutter, Riverpod, GoRouter, Dio.
- **API**: PHP 8.1+ with PDO.
- **Database**: MySQL 8+ or MariaDB 10.4+.
- **Design**: Brand styling from `Logo/Greenify-01.svg`.

---

## Directory Layout

```
greenify/
├── backend/public/       # PHP REST API
├── database/             # MySQL schema, seed data, setup script
├── mobile/               # Flutter application
├── docs/                 # API and project documentation
├── sql/                  # DBMS lab scripts
└── Logo/                 # Brand assets
```

---

## Quick Start Guide

### 1. Start MySQL

Start MySQL or MariaDB. With XAMPP, start MySQL from the XAMPP Control Panel.

For a fresh database, run this from **Command Prompt** at the project root:

```cmd
C:\xampp\mysql\bin\mysql.exe -u root < database\setup.sql
```

The setup script creates `greenify_db`, then loads its schema and sample records. It does not drop an existing database.
New booths start unassigned; an administrator assigns them to an approved recycler from Operations. Seed data assigns only the two sample booths with pickup requests.

For an existing database, apply the QR-token and audit-table upgrade from PowerShell:

```powershell
Get-Content .\database\upgrade.sql | & 'C:\xampp\mysql\bin\mysql.exe' -u root greenify_db
```

### 2. Start the PHP API

From the project root, run this in a terminal and leave it open:

```cmd
C:\xampp\php\php.exe -S 127.0.0.1:8000 backend\public\index.php
```

The API is available at `http://127.0.0.1:8000/api/v1`. Check `http://127.0.0.1:8000/api/v1/health` for database connectivity. By default the API uses MySQL at `127.0.0.1:3306`, database `greenify_db`, user `root`, and an empty password. Set `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, or `DB_PASS` before starting PHP to override these values.

### 3. Run Flutter

In another terminal:

```cmd
cd mobile
flutter run -d chrome
```

The seeded admin development login is phone `+8801746995650`, password `GreenifyAdmin2026`. Change this password before deployment. New citizen accounts can be registered with the development OTP `123456`. For an Android emulator, use `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`.

---

## Authoritative Token & Cashback Economics

- **Token Rate**: 100 Tokens / 1 kg (1 Token / 10 grams). Grams under 10g discarded.
- **Cashback Rate**: 4 Tokens = ৳1.00 BDT paid to bKash (Effective ৳25.00/kg).
- **Minimum Withdrawal**: ৳100.00 BDT (400 Tokens).
- **Withdrawal Step**: Tokens must be a multiple of 4.
- **OTP Test Mode**: Fixed code `123456`; do not use this mode in production.
- **Payouts**: bKash withdrawals are recorded as simulated transactions; no live bKash gateway is configured.
# GREENIFY: Smart Plastic Collection & Reward System

**Greenify** is a smart plastic recycling and reward platform designed for Bangladesh. It connects citizens, smart collection booth hardware, recycling companies, and administrators. Citizens deposit plastic, earn reward tokens (`100 Tokens = 1 kg`), and cash out directly to their **bKash** account (`4 Tokens = ৳1.00 BDT`, minimum withdrawal `৳100.00 BDT`).

---

## Technical Architecture

- **Backend**: Spring Boot 3.2.4 (Java 17/21), Spring Security 6, JWT Auth, Spring Data JPA, Flyway Migrations.
- **Database**: MySQL 8.0 (InnoDB) strictly normalized to 3NF.
- **Mobile Application**: Flutter (Material 3), Riverpod, GoRouter, Dio.
- **Design Tokens**: Brand styling derived from `Logo/Greenify-01.svg` (`#2E6027` primary, `#6BBF3A` accent, soft `#F2F5F1` background).

---

## Directory Layout

```
greenify/
├── backend/              # Spring Boot REST API
├── mobile/               # Flutter mobile application
├── docs/                 # Documentation (PLAN.md, API.md, SQL_FEATURES.md, BKASH.md, ASSUMPTIONS.md)
├── sql/                  # Standalone SQL lab scripts for DBMS Lab grading
├── design/admin-prototype/# React admin prototype source reference
├── Logo/                 # Original SVG & PNG logo brand assets
├── docker-compose.yml    # Docker setup for MySQL & Backend
└── README.md
```

---

## Quick Start Guide

### 1. Launching Database & Backend with Docker
```bash
docker compose up -d
```
Access points:
- REST API Base: `http://localhost:8080/api/v1`
- OpenAPI Swagger UI: `http://localhost:8080/api/v1/swagger-ui.html`
- Smart Booth Scale Simulator: `http://localhost:8080/api/v1/sim`

### 2. Running Flutter App
```bash
cd mobile
flutter run
```

---

## Authoritative Token & Cashback Economics

- **Token Rate**: 100 Tokens / 1 kg (1 Token / 10 grams). Grams under 10g discarded.
- **Cashback Rate**: 4 Tokens = ৳1.00 BDT paid to bKash (Effective ৳25.00/kg).
- **Minimum Withdrawal**: ৳100.00 BDT (400 Tokens).
- **Withdrawal Step**: Tokens must be a multiple of 4.
- **OTP Test Mode**: Fixed code `123456` enabled for dev profile.
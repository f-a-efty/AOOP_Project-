# GREENIFY: REST API ENDPOINT SPECIFICATION (`/api/v1`)

All API endpoints return standard JSON responses and error envelopes. OpenAPI Swagger UI documentation is live at `/api/v1/swagger-ui.html`.

---

## 1. Authentication (`/api/v1/auth`)

### `POST /auth/otp/send`
- **Request Body**: `{ "phoneNumber": "+8801711111111", "purpose": "REGISTER" }`
- **Response**: `{ "success": true, "message": "OTP verification code dispatched.", "testCode": "123456" }`

### `POST /auth/otp/verify`
- **Request Body**: `{ "phoneNumber": "+8801711111111", "code": "123456", "purpose": "REGISTER" }`
- **Response**: `{ "verified": true, "resetToken": "uuid-token" }`

### `POST /auth/register/user`
- **Request Body**: `{ "fullName": "Rakibul Islam", "phoneNumber": "+8801711111111", "password": "Password123!", "confirmPassword": "Password123!", "otpCode": "123456" }`
- **Response**: `AuthResponse` with JWT `accessToken` & `refreshToken`.

### `POST /auth/login`
- **Request Body**: `{ "username": "+8801711111111", "password": "Password123!" }`
- **Response**: `AuthResponse` with user details & JWT.

---

## 2. User App Endpoints (`/api/v1/me`)

### `GET /me/dashboard`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: User stats (plastic submitted, tokens, wallet balance ৳, loyalty level, CO2 offset).

### `POST /me/withdraw`
- **Headers**: `Authorization: Bearer <token>`, `Idempotency-Key: <unique-uuid>`
- **Request Body**: `{ "tokens": 400, "bkashNumber": "+8801711111111" }`
- **Response**: `WalletTransaction` with bKash transaction ID.

---

## 3. Booth Hardware Endpoints (`/api/v1/booths`)

### `POST /booths/{id}/qr`
- **Response**: `{ "qrToken": "uuid-token", "ttlSeconds": 60 }`

### `POST /booths/{id}/deposit-sessions/{sessionId}/weight`
- **Request Body**: `{ "weightKg": 1.500, "plasticType": "PET/Mix" }`
- **Response**: `PlasticDeposit` record with tokens earned.

---

## 4. Recycling Company Endpoints (`/api/v1/company`)
- `GET /company/dashboard`
- `GET /company/booths`
- `GET /company/pickup-requests`
- `POST /company/pickup-requests/{id}/accept`
- `POST /company/pickup-requests/{id}/assign-vehicle`
- `POST /company/pickup-requests/{id}/complete`
- `GET /company/collections`

---

## 5. Admin Portal Endpoints (`/api/v1/admin`)
- `GET /admin/dashboard/metrics`
- `GET /admin/users`
- `POST /admin/companies/{id}/approve`
- `POST /admin/config/economics`
- `GET /admin/audit-logs`

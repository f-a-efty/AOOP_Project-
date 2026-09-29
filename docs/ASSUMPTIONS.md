# GREENIFY: SYSTEM ASSUMPTIONS & DESIGN DECISIONS

This document records sensible defaults, design decisions, and deferred features adopted during the full-stack development of Greenify.

---

## 1. Token Economics & Calculations
- **[CONFIRM] Gram Discard Rule**: `base_tokens = floor(weight_kg * 100)`. Grams under 10g are discarded (e.g., 0.009 kg yields 0 tokens).
- **[CONFIRM] CO2 Conversion Factor**: `co2_kg_per_plastic_kg = 1.5`. Every 1.0 kg of plastic recycled prevents an estimated 1.5 kg of CO2 emissions.
- **Loyalty Tier Bounds**: Lower bounds are inclusive (Eco Buddy 0.0-50.0 kg, Green Friend 50.0-150.0 kg, Nature Hero 150.0-300.0 kg, Nature Guardian 300.0+ kg).

---

## 2. Dynamic QR Sessions & Hardware Telemetry
- **QR Code Expiration**: `qr_ttl_seconds = 60` seconds. QR tokens are single-use and hashed server-side.
- **Booth Hardware Scope**: Simulated hardware endpoints provided via `/sim` web controller. Real ESP32/Ultrasonic scale hardware connects via REST API.

---

## 3. Pickup Requests & Vehicle Queue
- **Auto-Trigger Threshold**: When a booth reaches 80% capacity (`Almost Full`) or 100% capacity (`Full`), the server auto-generates a single `Pending` pickup request.
- **Priority Queue**: `Full` booths are prioritized above `Almost Full` booths, with tie-breaking by creation timestamp (FIFO).

---

## 4. UI & Visual Branding
- **Color Palette Tokens**: Extracted from logo (`#2E6027` Forest Green primary, `#6BBF3A` Leaf Green accent, `#F2F5F1` Soft Surface).
- **Single Flutter App with Role Shells**: Roles (`USER`, `COMPANY`, `ADMIN`) redirect to respective navigation shells after login.

---

## 5. Deferred Stretch Features
- Referral bonus rewards
- Token direct peer-to-peer donation flow
- Real SMS gateway live SIM dispatch (Mock test mode active by default with code `123456`)

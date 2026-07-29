# Partner Forgot Password & Reset Password Integration Guide

This guide details how to integrate the **Forgot Password** and **Reset Password** flow for Partner accounts in frontend applications (Flutter mobile app, Web, or cURL/Postman testing) using the Indopo Partner Backend APIs (powered by Supabase Auth & Resend Email Delivery).

---

## 1. Flow Overview

There are **two ways** to complete the password reset flow:

### Option A: Direct Token / OTP API Reset (`POST /api/partner-auth/reset-password`)
Best for direct API calls (cURL/Postman) or custom UI where the partner inputs the token/link code or 8-digit OTP received via email.

```mermaid
sequenceDiagram
    participant PartnerApp as Mobile/Web/Postman
    participant BE as Express Backend API
    participant SB as Supabase Auth
    participant Email as Partner Inbox

    PartnerApp->>BE: POST /api/partner-auth/forgot-password { email }
    BE->>SB: generateLink({ type: 'recovery', email })
    BE-->>Email: Sends email with reset link & 8-digit OTP (via Resend/SMTP)
    PartnerApp->>BE: POST /api/partner-auth/reset-password { email, token/otp, newPassword }
    BE->>SB: verifyOtp({ token_hash: token } or { email, token: otp, type: 'recovery' })
    BE->>SB: PUT /auth/v1/user { password }
    BE-->>PartnerApp: 200 OK (Password reset successfully)
```

---

### Option B: Mobile Deep Link Flow (`POST /api/partner-auth/change-password`)
Best for mobile apps with deep linking (`indopo://partner-reset-password`).

```mermaid
sequenceDiagram
    participant PartnerApp as Partner Mobile App
    participant BE as Express Backend API
    participant SB as Supabase Auth
    participant Email as Partner Inbox

    PartnerApp->>BE: POST /api/partner-auth/forgot-password { email, redirectTo }
    BE->>SB: generateLink({ type: 'recovery', email, redirectTo })
    BE-->>Email: Sends password reset link (via Resend/SMTP)
    Partner->>Email: Clicks reset link
    Email->>SB: Opens Supabase verify endpoint
    SB-->>PartnerApp: Redirects to indopo://partner-reset-password#access_token=eyJhbGci...
    PartnerApp->>BE: POST /api/partner-auth/change-password { newPassword } (Header: Bearer <access_token>)
    BE-->>PartnerApp: 200 OK (Password changed successfully)
```

---

## 2. API Reference

### A. Request Reset Link / OTP

- **URL**: `/api/partner-auth/forgot-password`
- **Method**: `POST`
- **Auth Required**: No (Public)
- **Headers**: `Content-Type: application/json`

#### Request Body
```json
{
  "email": "doctor@example.com",
  "redirectTo": "indopo://partner-reset-password"
}
```

| Field | Type | Required | Description |
|:--|:--|:--|:--|
| `email` | `string` | Yes | Registered partner email address |
| `redirectTo` | `string` | Optional | Custom deep link URL (e.g. `indopo://partner-reset-password`) for mobile flow |

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Password reset email sent successfully."
}
```

---

### B. Reset Password using Email Token or OTP (`POST /api/partner-auth/reset-password`)

Use either the `token` parameter from the email link (`token=...` or `token_hash=...`) OR the 8-digit numeric `otp` code received in the email.

- **URL**: `/api/partner-auth/reset-password`
- **Method**: `POST`
- **Auth Required**: No (Public)
- **Headers**: `Content-Type: application/json`

#### Option 1: Request Body using `token`
```json
{
  "email": "doctor@example.com",
  "token": "28218e33b9a2191271d7125ba7fca1a7bbffb50d5913496408d18dde",
  "newPassword": "Partner@123"
}
```

#### Option 2: Request Body using 8-Digit `otp`
```json
{
  "email": "doctor@example.com",
  "otp": "12345678",
  "newPassword": "Partner@123"
}
```

| Field | Type | Required | Description |
|:--|:--|:--|:--|
| `email` | `string` | Yes | Registered partner email address |
| `token` | `string` | Optional* | Verification token / `token_hash` extracted from email link (`token=...` / `token_hash=...`) |
| `otp` | `string` | Optional* | 8-digit numeric verification code received in email (must be exactly 8 digits) |
| `newPassword` | `string` | Yes | New password (minimum 6 characters) |

> **Note**: Either `token` OR `otp` MUST be provided in the request body.

#### cURL Examples

**Using Token:**
```bash
curl --location 'https://indopo-beta.onrender.com/api/partner-auth/reset-password' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "email": "doctor@example.com",
    "token": "28218e33b9a2191271d7125ba7fca1a7bbffb50d5913496408d18dde",
    "newPassword": "Partner@123"
  }'
```

**Using 8-digit OTP:**
```bash
curl --location 'https://indopo-beta.onrender.com/api/partner-auth/reset-password' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "email": "doctor@example.com",
    "otp": "12345678",
    "newPassword": "Partner@123"
  }'
```

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Password reset successfully."
}
```

---

### C. Change Password using JWT Access Token (`POST /api/partner-auth/change-password`)

Used when the user opens the deep link and receives a full JWT `access_token` (starting with `eyJhbGci...`).

- **URL**: `/api/partner-auth/change-password`
- **Method**: `POST`
- **Auth Required**: Yes (`Authorization: Bearer <ACCESS_TOKEN>`)
- **Headers**: `Content-Type: application/json`

#### Request Body
```json
{
  "newPassword": "Partner@123"
}
```

#### cURL Example
```bash
curl --location 'https://indopo-beta.onrender.com/api/partner-auth/change-password' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1Ni...' \
  --data-raw '{
    "newPassword": "Partner@123"
  }'
```

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Password changed successfully"
}
```

---

## 3. Understanding Token Types & Troubleshooting

When you request a password reset, you receive an email link formatted like:
`https://<supabase-ref>.supabase.co/auth/v1/verify?token=beb65de2a53f04c1...&type=recovery&redirect_to=indopo://partner-reset-password`

There are two ways to process this link:

### 1. Direct Token API Reset (`POST /api/partner-auth/reset-password`)
- Extract the `token` parameter directly from the email link (`beb65de2a53f04c1...`).
- This `token` is an **email verification OTP / hash token**, **NOT** a JWT session token.
- Send `POST /api/partner-auth/reset-password` with `{ "email", "token": "beb65de2a53f04c1...", "newPassword" }`.

### 2. Deep Link Redirect Flow (`POST /api/partner-auth/change-password`)
- Open the full URL in a browser. Supabase will verify the token and redirect to:
  `indopo://partner-reset-password#access_token=eyJhbGci...&type=recovery`
- The mobile app intercepts this deep link, extracts the JWT `access_token` (which has 3 dot-separated base64 sections `eyJhbGci...`), and passes it in the `Authorization: Bearer <ACCESS_TOKEN>` header to `POST /api/partner-auth/change-password` with `{ "newPassword" }`.

> **Warning**: Passing a raw email token (`beb65de2...`) in the `Authorization: Bearer ...` header to `/change-password` will cause Supabase to return an `invalid JWT` error.

### Quick Reference:
- **Email `token` hash or 8-digit `otp` code** -> Use `POST /api/partner-auth/reset-password` (Body: `{ email, token/otp, newPassword }`).
- **JWT `access_token` from deep link fragment** -> Use `POST /api/partner-auth/change-password` (Header: `Authorization: Bearer <access_token>`, Body: `{ newPassword }`).


# Partner Authentication API — Frontend Integration Guide

This document is the **complete reference for frontend developers** integrating partner authentication into the partner-facing application. It covers login, token handling, password management, account deactivation, and availability toggling.

> **Base URL:** `http://localhost:5000/api/partner-auth`  
> **Content-Type:** `application/json`  
> **Auth Stack:** Supabase Auth (JWT Bearer tokens)

---

## Table of Contents

1. [Authentication Overview](#1-authentication-overview)
2. [Login](#2-login)
3. [Change Password](#3-change-password)
4. [Deactivate Account](#4-deactivate-account)
5. [Update Availability](#5-update-availability)
6. [Token Storage & Axios Setup](#6-token-storage--axios-setup)
7. [Common Error Responses](#7-common-error-responses)
8. [Typical Integration Flow](#8-typical-integration-flow)

---

## 1. Authentication Overview

The partner login endpoint authenticates via **Supabase Auth** (email + password). On success, the backend returns two tokens:

| Token | Purpose | Where to store |
|:--|:--|:--|
| `accessToken` | Sent as `Authorization: Bearer <token>` on every protected request | Memory / `sessionStorage` |
| `refreshToken` | Used to obtain a new access token when it expires | `localStorage` (or secure storage on mobile) |

All endpoints **except `/login`** require a valid access token in the `Authorization` header.

---

## 2. Login

Authenticates a partner with their email and password. Returns the partner profile along with Supabase session tokens.

- **Method:** `POST`
- **Path:** `/api/partner-auth/login`
- **Auth Required:** No (public)

### Request Body

```json
{
  "email": "doctor@example.com",
  "password": "your-password"
}
```

| Field | Type | Required | Validation |
|:--|:--|:--|:--|
| `email` | `string` | Yes | Must be a valid email address |
| `password` | `string` | Yes | Must not be empty |

### Example Request

```bash
curl -X POST "http://localhost:5000/api/partner-auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@example.com",
    "password": "your-password"
  }'
```

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Partner login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
    "session": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "token_type": "bearer",
      "expires_in": 3600,
      "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
      "user": { "id": "supabase-user-uuid", "email": "doctor@example.com" }
    },
    "user": {
      "id": "supabase-user-uuid",
      "email": "doctor@example.com"
    },
    "partner": {
      "id": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
      "name": "Dr. Sarah Jenkins",
      "email": "doctor@example.com",
      "orgName": "City General Hospital",
      "orgAddress": "123 Health Ave, Medical District",
      "phone": "+919876543210",
      "isActive": true,
      "isAvailable": true,
      "partnerType": "DOCTOR",
      "doctorProfile": {
        "specialization": "Cardiology",
        "experience": 10,
        "qualification": "MBBS, MD"
      },
      "services": [
        {
          "id": "b2085822-86d4-4076-acbb-464ceeeeffa0",
          "name": "General Consultation",
          "category": "Consultation",
          "price": "500.00"
        }
      ]
    }
  }
}
```

> **Important:** Save `data.accessToken` and `data.refreshToken` immediately after login. Use the access token for all subsequent API requests. Refer to the [Refresh Token Integration Guide](./refresh_token_integration.md) to handle token expiry automatically.

### Login Error — `400 Bad Request`

Returned when the email is not registered as a partner:

```json
{
  "success": false,
  "statusCode": 400,
  "message": "No partner account found with this email"
}
```

Returned when the password is wrong (from Supabase):

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Invalid login credentials"
}
```

---

## 3. Change Password

Updates the authenticated partner's password via Supabase Auth. The current access token is used directly to perform the update — **no old password is required**.

- **Method:** `POST`
- **Path:** `/api/partner-auth/change-password`
- **Auth Required:** Yes

### Request Body

```json
{
  "newPassword": "new-secure-password"
}
```

| Field | Type | Required | Validation |
|:--|:--|:--|:--|
| `newPassword` | `string` | Yes | Minimum 6 characters |

### Example Request

```bash
curl -X POST "http://localhost:5000/api/partner-auth/change-password" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "newPassword": "newSecure@123"
  }'
```

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Password changed successfully",
  "data": {
    "id": "supabase-user-uuid",
    "email": "doctor@example.com",
    "updated_at": "2026-07-18T08:00:00.000Z"
  }
}
```

> **Note:** After a successful password change, the current session remains valid. It is **recommended** to log the user out and redirect to the login screen so they can sign in with their new credentials.

---

## 4. Deactivate Account

Soft-deactivates the authenticated partner's account by setting `isActive = false`. This is a **permanent action** — the partner will no longer be able to operate on the platform once deactivated. Deactivation can only be reversed by an administrator.

- **Method:** `DELETE`
- **Path:** `/api/partner-auth/deactivate`
- **Auth Required:** Yes

### Example Request

```bash
curl -X DELETE "http://localhost:5000/api/partner-auth/deactivate" \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Account deactivated successfully",
  "data": null
}
```

### Error — Account Already Deactivated — `400 Bad Request`

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Account is already deactivated"
}
```

> **Frontend guidance:** Show a confirmation dialog before calling this endpoint (e.g., *"Are you sure? This action cannot be undone."*). On success, clear all stored tokens and redirect to the login screen.

---

## 5. Update Availability

Toggles the partner's real-time availability status (`isAvailable`). This controls whether the partner appears as available to patients on the platform.

- **Method:** `PATCH`
- **Path:** `/api/partner-auth/availability`
- **Auth Required:** Yes

### Request Body

```json
{
  "isAvailable": true
}
```

| Field | Type | Required | Description |
|:--|:--|:--|:--|
| `isAvailable` | `boolean` | Yes | `true` to mark as available, `false` to mark as unavailable |

### Example Requests

```bash
# Set partner as available
curl -X PATCH "http://localhost:5000/api/partner-auth/availability" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "isAvailable": true }'

# Set partner as unavailable
curl -X PATCH "http://localhost:5000/api/partner-auth/availability" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "isAvailable": false }'
```

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Availability set to true",
  "data": {
    "id": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
    "name": "Dr. Sarah Jenkins",
    "email": "doctor@example.com",
    "isAvailable": true,
    "isActive": true,
    "updatedAt": "2026-07-18T08:15:00.000Z"
  }
}
```

### Error — Invalid Value — `400 Bad Request`

```json
{
  "success": false,
  "statusCode": 400,
  "message": "isAvailable must be a boolean"
}
```

> **Frontend guidance:** Expose this as a toggle switch on the partner dashboard (e.g., "Available for Appointments"). Optimistically update the UI and revert on error.

---

## 6. Token Storage & Axios Setup

### Recommended Storage Strategy

```
accessToken  → in-memory (React state / Zustand store)
refreshToken → localStorage or httpOnly cookie (more secure)
```

### Axios Instance with Auth Interceptor

Set up a shared Axios instance that automatically attaches the access token and handles `401` responses by refreshing the token:

```typescript
// lib/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:5000/api',
  headers: { 'Content-Type': 'application/json' },
});

// ── Request interceptor: attach access token ──────────────────────────────────
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken'); // or from store
  if (token) {
    config.headers['Authorization'] = `Bearer ${token}`;
  }
  return config;
});

// ── Response interceptor: refresh on 401 ─────────────────────────────────────
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      const refreshToken = localStorage.getItem('refreshToken');

      if (refreshToken) {
        try {
          const { data } = await axios.post(
            'http://localhost:5000/api/auth/refresh-token',
            { refreshToken }
          );
          const { accessToken, refreshToken: newRefreshToken } = data.data;
          localStorage.setItem('accessToken', accessToken);
          localStorage.setItem('refreshToken', newRefreshToken);
          originalRequest.headers['Authorization'] = `Bearer ${accessToken}`;
          return api(originalRequest);
        } catch {
          // Refresh failed — force logout
          localStorage.removeItem('accessToken');
          localStorage.removeItem('refreshToken');
          window.location.href = '/login';
        }
      }
    }

    return Promise.reject(error);
  }
);

export default api;
```

> See [refresh_token_integration.md](./refresh_token_integration.md) for the full token refresh API reference.

---

## 7. Common Error Responses

### 400 Bad Request — Validation

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email address"
    }
  ]
}
```

### 401 Unauthorized — Missing / Expired Token

```json
{
  "success": false,
  "statusCode": 401,
  "message": "Unauthorized"
}
```

### 401 Unauthorized — Email not in token

```json
{
  "success": false,
  "statusCode": 401,
  "message": "User email not found in token"
}
```

### 404 Not Found — Partner profile missing

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Partner account not found"
}
```

---

## 8. Typical Integration Flow

```
1. LOGIN
   POST /api/partner-auth/login { email, password }
   → Save accessToken + refreshToken
   → Store partner profile in global state (name, partnerType, isAvailable, etc.)

2. PROTECTED REQUESTS
   Attach: Authorization: Bearer <accessToken>
   On 401 → call refresh-token endpoint → retry original request
   On refresh failure → clear tokens → redirect to /login

3. AVAILABILITY TOGGLE (dashboard)
   PATCH /api/partner-auth/availability { isAvailable: true | false }
   → Update toggle in UI immediately

4. CHANGE PASSWORD (settings page)
   POST /api/partner-auth/change-password { newPassword }
   → On success → log out → redirect to /login

5. DEACTIVATE ACCOUNT (settings page — destructive)
   Show confirmation dialog
   DELETE /api/partner-auth/deactivate
   → On success → clear tokens → redirect to /login
```

---

## Related Documentation

- [Refresh Token Integration](./refresh_token_integration.md) — How to handle access token expiry and silent re-authentication
- [Partner Appointments API](./partner-appointments-api.md) — Managing appointment requests after login

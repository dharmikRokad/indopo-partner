# Partner Request (Become a Partner) — Frontend Integration Guide

This document is the **complete reference for frontend developers** integrating the "Become a Partner" feature. It covers the public request submission form (partner panel) and the admin screens for viewing and managing incoming requests.

> **Base URL:** `http://localhost:5000/api`  
> **Content-Type:** `application/json`

---

## Table of Contents

1. [Overview & Flow](#1-overview--flow)
2. [Partner Panel — Submit a Request](#2-partner-panel--submit-a-request)
3. [Admin Panel — List Partner Requests](#3-admin-panel--list-partner-requests)
4. [Admin Panel — Get Single Request](#4-admin-panel--get-single-request)
5. [Admin Panel — Update Request Status](#5-admin-panel--update-request-status)
6. [Status Values Reference](#6-status-values-reference)
7. [Common Error Responses](#7-common-error-responses)
8. [End-to-End Integration Flow](#8-end-to-end-integration-flow)

---

## 1. Overview & Flow

```
[Partner Panel Auth Screen]
        │
        ▼  clicks "Become a Partner"
[Become a Partner Form]
        │
        ▼  POST /api/partner-auth/become-partner
[partner_requests table]  ← ONLY this table is written to
        │
        ▼  Admin opens partner requests list
[Admin Panel — Requests List]
        │
        ├─ Admin marks REJECTED  → PATCH .../status  { status: "REJECTED" }
        │
        └─ Admin decides to convert:
               1. Copies details from request
               2. Fills existing "Add Partner" form  (POST /api/admin/partners)
               3. Marks request CONVERTED → PATCH .../status { status: "CONVERTED" }
```

> **Important:** Submitting a "Become a Partner" request does **not** create a partner account. The `partner_requests` table is entirely separate from the `partners` table.

---

## 2. Partner Panel — Submit a Request

Shown on the partner panel's auth screens (login / register area). **No authentication required.**

- **Method:** `POST`
- **Path:** `/api/partner-auth/become-partner`
- **Auth Required:** ❌ Public

### Request Body

```json
{
  "name": "Dr. Priya Sharma",
  "email": "priya.sharma@clinic.in",
  "phone": "9876543210",
  "orgName": "Sharma Clinic",
  "orgAddress": "123 MG Road, Pune, Maharashtra",
  "partnerType": "DOCTOR"
}
```

| Field | Type | Required | Validation |
|:--|:--|:--:|:--|
| `name` | `string` | ✅ | Must not be empty |
| `email` | `string` | ✅ | Must be a valid email address |
| `phone` | `string` | ✅ | Must not be empty |
| `orgName` | `string` | ✅ | Must not be empty |
| `orgAddress` | `string` | ✅ | Must not be empty |
| `partnerType` | `string` | ✅ | One of: `DOCTOR`, `PHARMACY`, `LABORATORY`, `IMAGING_CENTER` |

### Success Response — `201 Created`

```json
{
  "success": true,
  "statusCode": 201,
  "message": "Your request to become a partner has been submitted successfully. We will get back to you shortly.",
  "data": {
    "id": "a1b2c3d4-...",
    "name": "Dr. Priya Sharma",
    "email": "priya.sharma@clinic.in",
    "phone": "9876543210",
    "orgName": "Sharma Clinic",
    "orgAddress": "123 MG Road, Pune, Maharashtra",
    "partnerType": "DOCTOR",
    "status": "PENDING",
    "createdAt": "2026-07-31T15:30:00.000Z",
    "updatedAt": "2026-07-31T15:30:00.000Z"
  }
}
```

### Error — Duplicate Active Request `409 Conflict`

Triggered when a `PENDING` or `CONVERTED` request already exists for this email.

```json
{
  "success": false,
  "statusCode": 409,
  "message": "A partner request with this email is already pending review."
}
```

> **Note on email reuse:** If a previous request was `REJECTED`, the same email can be submitted again. Only `PENDING` and `CONVERTED` requests block resubmission.

### Example — React / Axios

```typescript
import axios from 'axios';

interface BecomePartnerPayload {
  name: string;
  email: string;
  phone: string;
  orgName: string;
  orgAddress: string;
  partnerType: 'DOCTOR' | 'PHARMACY' | 'LABORATORY' | 'IMAGING_CENTER';
}

export async function submitBecomePartnerRequest(payload: BecomePartnerPayload) {
  const response = await axios.post('/api/partner-auth/become-partner', payload);
  return response.data;
}
```

### Example — cURL

```bash
curl -X POST "http://localhost:5000/api/partner-auth/become-partner" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. Priya Sharma",
    "email": "priya.sharma@clinic.in",
    "phone": "9876543210",
    "orgName": "Sharma Clinic",
    "orgAddress": "123 MG Road, Pune, Maharashtra",
    "partnerType": "DOCTOR"
  }'
```

---

## 3. Admin Panel — List Partner Requests

Returns a paginated, filterable list of all "Become a Partner" requests.

- **Method:** `GET`
- **Path:** `/api/admin/partner-requests`
- **Auth Required:** ✅ Admin JWT (`Authorization: Bearer <token>`)

### Query Parameters

| Parameter | Type | Default | Description |
|:--|:--|:--|:--|
| `page` | `number` | `1` | Page number (min: 1) |
| `limit` | `number` | `10` | Results per page (max: 100) |
| `status` | `string` | — | Filter by status: `PENDING`, `CONVERTED`, `REJECTED` |
| `search` | `string` | — | Text search across `name`, `email`, `orgName` |
| `sort` | `string` | `createdAt:desc` | Sort field and direction, e.g. `name:asc`, `createdAt:desc` |

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Partner requests retrieved successfully",
  "data": {
    "data": [
      {
        "id": "a1b2c3d4-...",
        "name": "Dr. Priya Sharma",
        "email": "priya.sharma@clinic.in",
        "phone": "9876543210",
        "orgName": "Sharma Clinic",
        "orgAddress": "123 MG Road, Pune, Maharashtra",
        "partnerType": "DOCTOR",
        "status": "PENDING",
        "createdAt": "2026-07-31T15:30:00.000Z",
        "updatedAt": "2026-07-31T15:30:00.000Z"
      }
    ],
    "pagination": {
      "total": 42,
      "page": 1,
      "limit": 10,
      "totalPages": 5
    }
  }
}
```

### Example — Axios (Admin)

```typescript
// Get all pending requests, page 1
const { data } = await adminAxios.get('/api/admin/partner-requests', {
  params: { status: 'PENDING', page: 1, limit: 10 },
});

// Search by name or email
const { data } = await adminAxios.get('/api/admin/partner-requests', {
  params: { search: 'priya', sort: 'createdAt:desc' },
});
```

### Example — cURL

```bash
curl -X GET "http://localhost:5000/api/admin/partner-requests?status=PENDING&page=1&limit=10" \
  -H "Authorization: Bearer <admin_token>"
```

---

## 4. Admin Panel — Get Single Request

Fetches full details of one partner request by its ID.

- **Method:** `GET`
- **Path:** `/api/admin/partner-requests/:id`
- **Auth Required:** ✅ Admin JWT

### Path Parameters

| Parameter | Type | Description |
|:--|:--|:--|
| `id` | `string (UUID)` | The partner request ID |

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Partner request retrieved successfully",
  "data": {
    "id": "a1b2c3d4-...",
    "name": "Dr. Priya Sharma",
    "email": "priya.sharma@clinic.in",
    "phone": "9876543210",
    "orgName": "Sharma Clinic",
    "orgAddress": "123 MG Road, Pune, Maharashtra",
    "partnerType": "DOCTOR",
    "status": "PENDING",
    "createdAt": "2026-07-31T15:30:00.000Z",
    "updatedAt": "2026-07-31T15:30:00.000Z"
  }
}
```

### Error — Not Found `404`

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Partner request not found"
}
```

### Example — cURL

```bash
curl -X GET "http://localhost:5000/api/admin/partner-requests/a1b2c3d4-..." \
  -H "Authorization: Bearer <admin_token>"
```

---

## 5. Admin Panel — Update Request Status

Updates the status of a partner request. Used to reject a request or mark it as converted after the partner account has been created.

- **Method:** `PATCH`
- **Path:** `/api/admin/partner-requests/:id/status`
- **Auth Required:** ✅ Admin JWT

### Path Parameters

| Parameter | Type | Description |
|:--|:--|:--|
| `id` | `string (UUID)` | The partner request ID |

### Request Body

```json
{
  "status": "REJECTED"
}
```

| Field | Type | Required | Allowed Values |
|:--|:--|:--:|:--|
| `status` | `string` | ✅ | `PENDING`, `CONVERTED`, `REJECTED` |

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Partner request status updated successfully",
  "data": {
    "id": "a1b2c3d4-...",
    "name": "Dr. Priya Sharma",
    "email": "priya.sharma@clinic.in",
    "phone": "9876543210",
    "orgName": "Sharma Clinic",
    "orgAddress": "123 MG Road, Pune, Maharashtra",
    "partnerType": "DOCTOR",
    "status": "REJECTED",
    "createdAt": "2026-07-31T15:30:00.000Z",
    "updatedAt": "2026-07-31T15:35:00.000Z"
  }
}
```

### Example — Axios (Admin)

```typescript
// Reject a request
await adminAxios.patch(`/api/admin/partner-requests/${requestId}/status`, {
  status: 'REJECTED',
});

// Mark as converted (after creating the partner via POST /api/admin/partners)
await adminAxios.patch(`/api/admin/partner-requests/${requestId}/status`, {
  status: 'CONVERTED',
});
```

### Example — cURL

```bash
curl -X PATCH "http://localhost:5000/api/admin/partner-requests/a1b2c3d4-.../status" \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{ "status": "REJECTED" }'
```

---

## 6. Status Values Reference

| Status | Meaning | Can resubmit same email? |
|:--|:--|:--|
| `PENDING` | Request submitted, waiting for admin review | ❌ Blocked |
| `CONVERTED` | Admin created a partner account from this request | ❌ Blocked |
| `REJECTED` | Admin rejected the request | ✅ Allowed |

---

## 7. Common Error Responses

All endpoints use a consistent error shape:

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Descriptive error message here"
}
```

| Status Code | When it occurs |
|:--|:--|
| `400` | Validation error (missing/invalid field) |
| `401` | Missing or invalid admin/auth token |
| `404` | Partner request not found |
| `409` | Duplicate active request for the same email |
| `500` | Unexpected server error |

---

## 8. End-to-End Integration Flow

### Partner Panel Side

1. Show a **"Become a Partner"** button/link on the auth screens (login, register).
2. On click, navigate to a new screen/modal with the form fields: `name`, `email`, `phone`, `orgName`, `orgAddress`, `partnerType`.
3. On submit, call `POST /api/partner-auth/become-partner`.
   - **201** → Show success message: *"Your request has been submitted. We'll be in touch."*
   - **409** → Show: *"A request with this email is already pending/converted."*
   - **400** → Display field-level validation errors.

### Admin Panel Side

1. Add a **"Partner Requests"** section/page in the admin panel.
2. On load, call `GET /api/admin/partner-requests?status=PENDING` to show pending requests.
3. Admin can **search** by name/email, and **filter** by status tab (Pending / Converted / Rejected).
4. On clicking a request row, call `GET /api/admin/partner-requests/:id` to show details.
5. On the detail screen, provide two action buttons:
   - **Reject** → `PATCH .../status` with `{ "status": "REJECTED" }`.
   - **Convert to Partner** → Pre-fill and open the existing *Add Partner* form (`POST /api/admin/partners`) with the request's details. After successful partner creation, call `PATCH .../status` with `{ "status": "CONVERTED" }`.

### Suggested partnerType UI Options

```typescript
const partnerTypeOptions = [
  { label: 'Doctor',         value: 'DOCTOR' },
  { label: 'Pharmacy',       value: 'PHARMACY' },
  { label: 'Laboratory',     value: 'LABORATORY' },
  { label: 'Imaging Center', value: 'IMAGING_CENTER' },
];
```

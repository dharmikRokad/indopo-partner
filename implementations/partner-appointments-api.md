# Partner Appointments API — Integration Guide

This document covers all appointment-related endpoints that the **partner frontend** should consume. Partners manage their incoming booking requests, confirm appointments with a date & time, and update statuses (complete, cancel, no-show).

> **Base URL:** `http://localhost:5000/api/appointments`  
> **Authentication:** All endpoints require a valid Supabase JWT passed as a Bearer token.  
> **Content-Type:** `application/json`

---

## Authentication

Include the partner's JWT in every request:

```http
Authorization: Bearer <PARTNER_JWT_TOKEN>
```

The server resolves the partner record from the token's email claim. If no matching partner is found, a `404` is returned.

---

## Appointment Statuses

| Status | Description |
|:--|:--|
| `PENDING` | Patient submitted a booking request; awaiting partner confirmation |
| `CONFIRMED` | Partner has set a date, time, and token number |
| `COMPLETED` | Appointment has been completed |
| `CANCELLED` | Appointment was cancelled by either party |
| `NO_SHOW` | Patient did not show up |

---

## Endpoints

### 1. List Partner Appointments

Fetch all appointment requests assigned to the authenticated partner. Supports filtering by status, date, and pagination.

- **Method:** `GET`
- **Path:** `/api/appointments/partner/list`

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|:--|:--|:--|:--|:--|
| `status` | `string` | No | — | Filter by status. Allowed: `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`, `NO_SHOW` |
| `date` | `string (YYYY-MM-DD)` | No | — | Filter appointments on a specific calendar day (UTC) |
| `page` | `number` | No | `1` | Page number for pagination |
| `limit` | `number` | No | `20` | Records per page. Maximum: `100` |

#### Sorting Behaviour

- When **`date` is provided** → results are sorted chronologically: `appointmentDate ASC`, `appointmentTime ASC`
- When **no `date`** → results are sorted newest-first: `createdAt DESC`

#### Example Requests

```bash
# All pending requests (newest first)
curl -X GET "http://localhost:5000/api/appointments/partner/list?status=PENDING" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>"

# All appointments on a specific date (chronological)
curl -X GET "http://localhost:5000/api/appointments/partner/list?date=2026-07-20" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>"

# Confirmed appointments on a specific date
curl -X GET "http://localhost:5000/api/appointments/partner/list?date=2026-07-20&status=CONFIRMED" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>"

# Paginated request
curl -X GET "http://localhost:5000/api/appointments/partner/list?page=2&limit=10" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": {
    "appointments": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "patientId": "fa75b8a0-8412-42a3-9b49-896af939befa",
        "partnerId": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
        "serviceId": "b2085822-86d4-4076-acbb-464ceeeeffa0",
        "patientName": "Rahul Sharma",
        "patientPhone": "+919876543210",
        "location": "Clinic Visit",
        "notes": "Chest pain since 2 days",
        "appointmentDate": null,
        "appointmentTime": null,
        "tokenNumber": null,
        "status": "PENDING",
        "createdAt": "2026-07-18T07:00:00.000Z",
        "updatedAt": "2026-07-18T07:00:00.000Z",
        "service": {
          "id": "b2085822-86d4-4076-acbb-464ceeeeffa0",
          "name": "General Consultation",
          "price": "500.00"
        }
      }
    ],
    "total": 1,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

> **Note:** `appointmentDate`, `appointmentTime`, and `tokenNumber` are `null` for `PENDING` appointments until the partner confirms them.

---

### 2. Confirm Appointment (Set Date & Time)

Phase 2 of the booking flow. The partner sets the appointment date, time, and a sequential token number is automatically assigned for that day.

- **Method:** `POST`
- **Path:** `/api/appointments/partner/:id/confirm`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `id` | `string (UUID)` | Yes | The appointment ID to confirm |

#### Request Body

```json
{
  "appointmentDate": "2026-07-20",
  "appointmentTime": "10:30"
}
```

| Field | Type | Required | Validation | Description |
|:--|:--|:--|:--|:--|
| `appointmentDate` | `string` | Yes | Format: `YYYY-MM-DD` | The date of the appointment |
| `appointmentTime` | `string` | Yes | Format: `HH:MM` (24-hr) | The time slot for the appointment |

#### Token Number Assignment

The `tokenNumber` is automatically computed as a **1-based sequential counter** of already-confirmed appointments for this partner on the same date. There is no need to send it from the frontend.

#### Example Request

```bash
curl -X POST "http://localhost:5000/api/appointments/partner/a1b2c3d4-e5f6-7890-abcd-ef1234567890/confirm" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "appointmentDate": "2026-07-20",
    "appointmentTime": "10:30"
  }'
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Appointment confirmed successfully",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "patientId": "fa75b8a0-8412-42a3-9b49-896af939befa",
    "partnerId": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
    "serviceId": "b2085822-86d4-4076-acbb-464ceeeeffa0",
    "patientName": "Rahul Sharma",
    "patientPhone": "+919876543210",
    "location": "Clinic Visit",
    "notes": "Chest pain since 2 days",
    "appointmentDate": "2026-07-20T00:00:00.000Z",
    "appointmentTime": "10:30",
    "tokenNumber": 1,
    "status": "CONFIRMED",
    "createdAt": "2026-07-18T07:00:00.000Z",
    "updatedAt": "2026-07-20T05:00:00.000Z",
    "partner": {
      "id": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
      "name": "Dr. Sarah Jenkins",
      "orgName": "City General Hospital",
      "phone": "+91 98765 43210"
    },
    "service": {
      "id": "b2085822-86d4-4076-acbb-464ceeeeffa0",
      "name": "General Consultation",
      "price": "500.00"
    }
  }
}
```

#### Business Rules

- Only `PENDING` appointments can be confirmed. Attempting to confirm a `CONFIRMED` / `CANCELLED` / `COMPLETED` / `NO_SHOW` appointment returns a `400`.
- The appointment **must belong to the authenticated partner**. Attempting to confirm another partner's appointment returns a `400`.

---

### 3. Update Appointment Status

Update the status of any appointment assigned to the partner (e.g., mark as completed, cancelled, or no-show).

- **Method:** `PATCH`
- **Path:** `/api/appointments/:id/status`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `id` | `string (UUID)` | Yes | The appointment ID to update |

#### Request Body

```json
{
  "status": "COMPLETED"
}
```

| Field | Type | Required | Allowed Values | Description |
|:--|:--|:--|:--|:--|
| `status` | `string` | Yes | `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`, `NO_SHOW` | The new appointment status |

#### Example Requests

```bash
# Mark as completed
curl -X PATCH "http://localhost:5000/api/appointments/a1b2c3d4-e5f6-7890-abcd-ef1234567890/status" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "status": "COMPLETED" }'

# Mark as cancelled
curl -X PATCH "http://localhost:5000/api/appointments/a1b2c3d4-e5f6-7890-abcd-ef1234567890/status" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "status": "CANCELLED" }'

# Mark as no-show
curl -X PATCH "http://localhost:5000/api/appointments/a1b2c3d4-e5f6-7890-abcd-ef1234567890/status" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "status": "NO_SHOW" }'
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Appointment status updated",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "patientId": "fa75b8a0-8412-42a3-9b49-896af939befa",
    "partnerId": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
    "serviceId": "b2085822-86d4-4076-acbb-464ceeeeffa0",
    "patientName": "Rahul Sharma",
    "patientPhone": "+919876543210",
    "appointmentDate": "2026-07-20T00:00:00.000Z",
    "appointmentTime": "10:30",
    "tokenNumber": 1,
    "status": "COMPLETED",
    "createdAt": "2026-07-18T07:00:00.000Z",
    "updatedAt": "2026-07-20T11:00:00.000Z"
  }
}
```

---

## Common Error Responses

### 400 Bad Request

Returned when request parameters fail validation.

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "appointmentDate",
      "message": "Date must be in YYYY-MM-DD format"
    }
  ]
}
```

Also returned when business logic fails (e.g., confirming a non-PENDING appointment):

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Cannot confirm an appointment with status CONFIRMED"
}
```

### 401 Unauthorized

Returned when the JWT is missing, expired, or malformed.

```json
{
  "success": false,
  "statusCode": 401,
  "message": "Unauthorized"
}
```

### 404 Not Found

Returned when the authenticated user has no partner profile, or the requested appointment does not exist / does not belong to this partner.

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Partner profile not found"
}
```

---

## Typical Partner Frontend Flow

```
1. On dashboard load:
   GET /api/appointments/partner/list?status=PENDING
   → Display incoming booking requests

2. Partner picks a pending request and assigns a date/time:
   POST /api/appointments/partner/:id/confirm
   { "appointmentDate": "YYYY-MM-DD", "appointmentTime": "HH:MM" }
   → Status changes to CONFIRMED; tokenNumber is auto-assigned

3. On appointment day, filter today's schedule:
   GET /api/appointments/partner/list?date=YYYY-MM-DD&status=CONFIRMED
   → Show today's confirmed appointments sorted chronologically

4. After patient visit, mark outcome:
   PATCH /api/appointments/:id/status
   { "status": "COMPLETED" | "NO_SHOW" | "CANCELLED" }
   → Status is updated; appointment closes
```

---

## Related Documentation

- [Admin Appointments API](./admin-appointments-api.md) — Admin-level view of all appointments across partners

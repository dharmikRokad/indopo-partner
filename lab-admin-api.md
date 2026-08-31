# Lab Packages API — Admin Integration Guide

This document covers all lab-package-related endpoints that the **admin panel** should consume. Admins manage the global catalog of lab test packages that all LABORATORY partners can fulfill.

> **Base URL:** `http://localhost:5000/api/admin`  
> **Authentication:** All endpoints require a valid Admin JWT passed as a Bearer token.  
> **Content-Type:** `application/json`

---

## Authentication

Include the admin JWT in every request:

```http
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

Obtain the token from `POST /api/admin/login`.

---

## Data Model — LabPackage

```json
{
  "id": "uuid",
  "name": "Full Body Checkup",
  "category": "Preventive",
  "description": "A comprehensive panel covering key health markers.",
  "price": "999.00",
  "icon": "https://cdn.example.com/icons/full-body.png",
  "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting", "Thyroid TSH"],
  "isAvailable": true,
  "createdAt": "2026-08-01T10:00:00.000Z",
  "updatedAt": "2026-08-01T10:00:00.000Z"
}
```

| Field | Type | Notes |
|:--|:--|:--|
| `id` | `string (UUID)` | Auto-generated |
| `name` | `string` | Required. Package display name |
| `category` | `string \| null` | Optional grouping label (e.g. "Cardiac", "Diabetes") |
| `description` | `string \| null` | Optional free-text description |
| `price` | `string (decimal) \| null` | Stored as `Decimal(10,2)`. Serialized as a string |
| `icon` | `string (URL) \| null` | Direct URL to the package icon image |
| `tests` | `string[]` | Individual test names bundled in this package |
| `isAvailable` | `boolean` | `false` hides it from the patient-facing catalog |

---

## Endpoints

### 1. List Lab Packages

Fetch all packages (including unavailable ones — unlike the patient catalog).

- **Method:** `GET`
- **Path:** `/api/admin/lab-packages`

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|:--|:--|:--|:--|:--|
| `search` | `string` | No | — | Case-insensitive name search. Max 100 chars |
| `category` | `string` | No | — | Exact category match (case-insensitive) |
| `page` | `number` | No | `1` | Page number |
| `limit` | `number` | No | `20` | Records per page. Max: `100` |

#### Example Requests

```bash
# All packages (newest first)
curl -X GET "http://localhost:5000/api/admin/lab-packages" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"

# Search by name
curl -X GET "http://localhost:5000/api/admin/lab-packages?search=blood&page=1&limit=10" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"

# Filter by category
curl -X GET "http://localhost:5000/api/admin/lab-packages?category=Preventive" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": {
    "packages": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "name": "Full Body Checkup",
        "category": "Preventive",
        "description": "A comprehensive panel covering key health markers.",
        "price": "999.00",
        "icon": "https://cdn.example.com/icons/full-body.png",
        "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"],
        "isAvailable": true,
        "createdAt": "2026-08-01T10:00:00.000Z",
        "updatedAt": "2026-08-01T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 42,
      "page": 1,
      "limit": 20,
      "totalPages": 3,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

> **Note:** Admin list includes packages with `isAvailable: false`. The patient catalog (`GET /api/labs/catalog`) only returns packages where `isAvailable: true`.

---

### 2. Create Lab Package

Create a new global lab test package.

- **Method:** `POST`
- **Path:** `/api/admin/lab-packages`

#### Request Body

```json
{
  "name": "Full Body Checkup",
  "category": "Preventive",
  "description": "A comprehensive panel covering key health markers.",
  "price": 999.00,
  "icon": "https://cdn.example.com/icons/full-body.png",
  "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"],
  "isAvailable": true
}
```

| Field | Type | Required | Validation | Description |
|:--|:--|:--|:--|:--|
| `name` | `string` | **Yes** | Min 1 char | Package display name |
| `category` | `string` | No | Min 1 char if provided | Grouping label |
| `description` | `string` | No | — | Free-text description |
| `price` | `number` | No | Must be positive | Price in local currency |
| `icon` | `string` | No | Must be a valid URL | Icon image URL |
| `tests` | `string[]` | No | Each item min 1 char. Default: `[]` | Individual test names |
| `isAvailable` | `boolean` | No | Default: `true` | Controls patient catalog visibility |

#### Example Request

```bash
curl -X POST "http://localhost:5000/api/admin/lab-packages" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Full Body Checkup",
    "category": "Preventive",
    "price": 999,
    "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"],
    "isAvailable": true
  }'
```

#### Success Response — `201 Created`

```json
{
  "success": true,
  "statusCode": 201,
  "message": "Lab package created successfully",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "name": "Full Body Checkup",
    "category": "Preventive",
    "description": null,
    "price": "999.00",
    "icon": null,
    "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"],
    "isAvailable": true,
    "createdAt": "2026-08-29T07:30:00.000Z",
    "updatedAt": "2026-08-29T07:30:00.000Z"
  }
}
```

#### Validation Error — `400 Bad Request`

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    { "field": "name", "message": "Name is required" },
    { "field": "price", "message": "Price must be positive" },
    { "field": "icon", "message": "Icon must be a valid URL" }
  ]
}
```

---

### 3. Update Lab Package

Partially update any field of an existing package. Only include fields you want to change.

- **Method:** `PUT`
- **Path:** `/api/admin/lab-packages/:id`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `id` | `string (UUID)` | Yes | The package ID to update |

#### Request Body

All fields are optional. Only provided fields are updated.

```json
{
  "price": 1199.00,
  "isAvailable": false
}
```

#### Example Requests

```bash
# Update price only
curl -X PUT "http://localhost:5000/api/admin/lab-packages/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "price": 1199 }'

# Hide from patient catalog
curl -X PUT "http://localhost:5000/api/admin/lab-packages/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "isAvailable": false }'

# Add more tests to existing package
curl -X PUT "http://localhost:5000/api/admin/lab-packages/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting", "Thyroid TSH"] }'
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lab package updated successfully",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "name": "Full Body Checkup",
    "category": "Preventive",
    "description": null,
    "price": "1199.00",
    "icon": null,
    "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"],
    "isAvailable": false,
    "createdAt": "2026-08-01T10:00:00.000Z",
    "updatedAt": "2026-08-29T08:00:00.000Z"
  }
}
```

#### Not Found — `404`

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Lab package not found"
}
```

> **Quick availability toggle:** Use this endpoint with only `{ "isAvailable": true/false }` to toggle a package on or off without changing any other data.

---

### 4. Delete Lab Package

Permanently delete a lab package.

- **Method:** `DELETE`
- **Path:** `/api/admin/lab-packages/:id`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `id` | `string (UUID)` | Yes | The package ID to delete |

#### Example Request

```bash
curl -X DELETE "http://localhost:5000/api/admin/lab-packages/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lab package deleted successfully",
  "data": null
}
```

#### Not Found — `404`

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Lab package not found"
}
```

> **Important:** This is a **hard delete**. Existing lab orders that included this package retain a snapshot of `packageName` and `price` in the `lab_order_items` table, so order history is preserved. However, the package will no longer appear in any catalog or list.

---

## Part 2 — Lab Tests

Lab Tests are **individual diagnostic tests** managed as a separate master list. When composing a package, the admin picks test names from this list and stores them in the package's `tests[]` string array.

> The `LabPackage.tests` field stores test **names** (strings), not IDs — so deleting a test does not affect existing packages or order history.

---

### Data Model — LabTest

```json
{
  "id": "uuid",
  "name": "Complete Blood Count",
  "category": "Haematology",
  "description": "Measures the cellular components of blood.",
  "unit": "cells/μL",
  "isActive": true,
  "createdAt": "2026-08-01T10:00:00.000Z",
  "updatedAt": "2026-08-01T10:00:00.000Z"
}
```

| Field | Type | Notes |
|:--|:--|:--|
| `id` | `string (UUID)` | Auto-generated |
| `name` | `string` | **Unique** across all tests |
| `category` | `string \| null` | Grouping label (e.g. "Haematology", "Biochemistry") |
| `description` | `string \| null` | What the test measures |
| `unit` | `string \| null` | Result unit, e.g. `"mg/dL"`, `"cells/μL"`, `"%"` |
| `isActive` | `boolean` | `false` hides the test from selection dropdowns |

---

### 5. Get Lab Test Categories

Returns distinct test categories for filter dropdowns.

- **Method:** `GET`
- **Path:** `/api/admin/lab-tests/categories`

#### Example Request

```bash
curl -X GET "http://localhost:5000/api/admin/lab-tests/categories" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": ["Biochemistry", "Haematology", "Hormones", "Lipids", "Thyroid"]
}
```

---

### 6. List Lab Tests

Lists all tests. Default `limit` is `100` so the full list loads in a single request for package-creation dropdowns.

- **Method:** `GET`
- **Path:** `/api/admin/lab-tests`

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|:--|:--|:--|:--|:--|
| `search` | `string` | No | — | Case-insensitive name search. Max 100 chars |
| `category` | `string` | No | — | Exact category match (case-insensitive) |
| `page` | `number` | No | `1` | Page number |
| `limit` | `number` | No | `100` | Records per page. Max: `100` |

#### Example Requests

```bash
# Fetch all tests (one request, default limit=100)
curl -X GET "http://localhost:5000/api/admin/lab-tests" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"

# Search by name
curl -X GET "http://localhost:5000/api/admin/lab-tests?search=glucose" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"

# Filter by category
curl -X GET "http://localhost:5000/api/admin/lab-tests?category=Haematology" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": {
    "tests": [
      {
        "id": "b1c2d3e4-f5a6-7890-bcde-fa1234567890",
        "name": "Complete Blood Count",
        "category": "Haematology",
        "description": "Measures the cellular components of blood.",
        "unit": "cells/μL",
        "isActive": true,
        "createdAt": "2026-08-01T10:00:00.000Z",
        "updatedAt": "2026-08-01T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 48,
      "page": 1,
      "limit": 100,
      "totalPages": 1,
      "hasNextPage": false,
      "hasPrevPage": false
    }
  }
}
```

---

### 7. Create Lab Test

- **Method:** `POST`
- **Path:** `/api/admin/lab-tests`

#### Request Body

```json
{
  "name": "Complete Blood Count",
  "category": "Haematology",
  "description": "Measures the cellular components of blood.",
  "unit": "cells/μL",
  "isActive": true
}
```

| Field | Type | Required | Validation | Description |
|:--|:--|:--|:--|:--|
| `name` | `string` | **Yes** | Min 1 char. **Must be unique** | Test display name |
| `category` | `string` | No | Min 1 char if provided | Grouping label |
| `description` | `string` | No | — | What the test measures |
| `unit` | `string` | No | — | Result unit (e.g. `"mg/dL"`) |
| `isActive` | `boolean` | No | Default: `true` | Controls visibility in selection dropdowns |

#### Example Request

```bash
curl -X POST "http://localhost:5000/api/admin/lab-tests" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Complete Blood Count",
    "category": "Haematology",
    "unit": "cells/μL",
    "isActive": true
  }'
```

#### Success Response — `201 Created`

```json
{
  "success": true,
  "statusCode": 201,
  "message": "Lab test created successfully",
  "data": {
    "id": "b1c2d3e4-f5a6-7890-bcde-fa1234567890",
    "name": "Complete Blood Count",
    "category": "Haematology",
    "description": null,
    "unit": "cells/μL",
    "isActive": true,
    "createdAt": "2026-08-29T08:00:00.000Z",
    "updatedAt": "2026-08-29T08:00:00.000Z"
  }
}
```

#### Duplicate Name — `409 Conflict`

```json
{
  "success": false,
  "statusCode": 409,
  "message": "A test named \"Complete Blood Count\" already exists"
}
```

---

### 8. Update Lab Test

Partially update any field. Only provided fields are changed.

- **Method:** `PUT`
- **Path:** `/api/admin/lab-tests/:id`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `id` | `string (UUID)` | Yes | The test ID to update |

#### Example Requests

```bash
# Update unit
curl -X PUT "http://localhost:5000/api/admin/lab-tests/b1c2d3e4-f5a6-7890-bcde-fa1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "unit": "×10⁹/L" }'

# Disable test (hide from package dropdowns)
curl -X PUT "http://localhost:5000/api/admin/lab-tests/b1c2d3e4-f5a6-7890-bcde-fa1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "isActive": false }'
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lab test updated successfully",
  "data": {
    "id": "b1c2d3e4-f5a6-7890-bcde-fa1234567890",
    "name": "Complete Blood Count",
    "category": "Haematology",
    "description": null,
    "unit": "×10⁹/L",
    "isActive": true,
    "createdAt": "2026-08-01T10:00:00.000Z",
    "updatedAt": "2026-08-29T09:00:00.000Z"
  }
}
```

#### Not Found — `404`

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Lab test not found"
}
```

---

### 9. Delete Lab Test

- **Method:** `DELETE`
- **Path:** `/api/admin/lab-tests/:id`

#### Example Request

```bash
curl -X DELETE "http://localhost:5000/api/admin/lab-tests/b1c2d3e4-f5a6-7890-bcde-fa1234567890" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Lab test deleted successfully",
  "data": null
}
```

> **Safe to delete:** Deleting a `LabTest` does not affect any existing `LabPackage` or order history because packages store test names as plain strings, not foreign keys.

---

## Common Error Responses

### 401 Unauthorized

```json
{
  "success": false,
  "statusCode": 401,
  "message": "Unauthorized"
}
```

### 400 Validation Error

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    { "field": "name", "message": "Name is required" }
  ]
}
```

### 409 Conflict (Duplicate Test Name)

```json
{
  "success": false,
  "statusCode": 409,
  "message": "A test named \"CBC\" already exists"
}
```

---

## Typical Admin Frontend Flow

```
── Lab Tests Management ──────────────────────────────────────────────

1. On "Lab Tests" page load:
   GET /api/admin/lab-tests/categories → populate filter chips
   GET /api/admin/lab-tests            → render test list (limit=100, all in one call)

2. Admin creates a new test:
   POST /api/admin/lab-tests
   { name, category, unit, description, isActive }
   → Append to list; handle 409 if name already exists

3. Admin edits a test:
   PUT /api/admin/lab-tests/:id
   { only changed fields }
   → Update row in list

4. Admin disables a test (soft hide from package dropdowns):
   PUT /api/admin/lab-tests/:id
   { "isActive": false }

5. Admin deletes a test:
   DELETE /api/admin/lab-tests/:id
   → Remove from list (no impact on existing packages)

── Lab Package Creation (using test list) ────────────────────────────

6. Admin opens "Create Package" form:
   GET /api/admin/lab-tests?limit=100  → populate multi-select test picker

7. Admin picks tests from the dropdown:
   Collect selected test names into a string[] → send in package body

8. Admin submits:
   POST /api/admin/lab-packages
   { name, category, price, tests: ["CBC", "Lipid Profile", ...] }

── Lab Package Management ────────────────────────────────────────────

9. List / search / filter packages:
   GET /api/admin/lab-packages?search=blood&category=Cardiac

10. Toggle availability, edit, delete:
    PUT /api/admin/lab-packages/:id  |  DELETE /api/admin/lab-packages/:id
```

---

## Related Documentation

- [Lab Patient API](./lab-patient-api.md) — Patient-facing catalog, cart, and order endpoints
- [Lab Partner API](./lab-partner-api.md) — Lab partner order dispatch and accept endpoints

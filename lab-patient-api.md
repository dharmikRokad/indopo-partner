# Lab API — Patient Integration Guide

This document covers all lab-related endpoints that the **patient frontend** should consume. The patient browses a global catalog of test packages, manages a cart, checks out, and then waits for an FCM notification when a nearby lab accepts the order.

> **Base URL:** `http://localhost:5000`  
> **Authentication:** Catalog endpoints are public. Cart and order endpoints require a Patient JWT.  
> **Content-Type:** `application/json`

---

## Authentication

Include the patient JWT in all protected requests:

```http
Authorization: Bearer <PATIENT_JWT_TOKEN>
```

Obtain the token from `POST /api/auth/login`.

---

## Order Status Reference

| `status` | Badge | Meaning |
|:--|:--|:--|
| `PENDING` | 🟡 Orange | Order placed — searching for a nearby lab |
| `ACCEPTED` | 🟢 Green | A lab has accepted and will collect samples |
| `EXPIRED` | 🔴 Red | No lab was available — order expired |
| `CANCELLED` | ⚫ Grey | Order was cancelled |

---

## Part 1 — Catalog (Public, No Auth Required)

### 1. Get Lab Package Categories

Returns a distinct list of all available categories for building filter chips/dropdowns.

- **Method:** `GET`
- **Path:** `/api/labs/categories`

#### Example Request

```bash
curl -X GET "http://localhost:5000/api/labs/categories"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": ["Cardiac", "Diabetes", "Liver", "Preventive", "Thyroid"]
}
```

> **Tip:** Fetch this once on catalog screen load to populate filter chips. Sorted alphabetically.

---

### 2. Browse Lab Catalog

Returns all available lab packages. Patient browses and selects tests without choosing any specific lab — the system picks the best available lab at checkout.

- **Method:** `GET`
- **Path:** `/api/labs/catalog`

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|:--|:--|:--|:--|:--|
| `search` | `string` | No | — | Case-insensitive name search. Max 100 chars |
| `category` | `string` | No | — | Exact category match (case-insensitive) |
| `page` | `number` | No | `1` | Page number |
| `limit` | `number` | No | `20` | Records per page. Max: `100` |

#### Example Requests

```bash
# All packages (alphabetical)
curl -X GET "http://localhost:5000/api/labs/catalog"

# Search by name
curl -X GET "http://localhost:5000/api/labs/catalog?search=thyroid"

# Filter by category with pagination
curl -X GET "http://localhost:5000/api/labs/catalog?category=Preventive&page=1&limit=10"
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
        "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting", "Thyroid TSH"],
        "isAvailable": true,
        "createdAt": "2026-08-01T10:00:00.000Z",
        "updatedAt": "2026-08-01T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 24,
      "page": 1,
      "limit": 20,
      "totalPages": 2,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

> **Note:** Only packages with `isAvailable: true` appear here.

---

## Part 2 — Cart (Requires Patient Auth)

One cart per patient. Cart is auto-created on first add and auto-deleted after a successful checkout or when all items are removed.

### 3. Get My Cart

- **Method:** `GET`
- **Path:** `/api/lab/cart`

#### Example Request

```bash
curl -X GET "http://localhost:5000/api/lab/cart" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": {
    "id": "cart-uuid",
    "patientId": "patient-uuid",
    "createdAt": "2026-08-29T07:00:00.000Z",
    "updatedAt": "2026-08-29T07:15:00.000Z",
    "items": [
      {
        "id": "item-uuid",
        "cartId": "cart-uuid",
        "labPackageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "quantity": 1,
        "createdAt": "2026-08-29T07:00:00.000Z",
        "labPackage": {
          "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
          "name": "Full Body Checkup",
          "category": "Preventive",
          "description": "A comprehensive panel...",
          "price": "999.00",
          "icon": "https://cdn.example.com/icons/full-body.png",
          "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"],
          "isAvailable": true
        }
      }
    ]
  }
}
```

> **Empty cart:** If the patient has no active cart, the server returns `{ "items": [] }` (not a 404).

**Total price** (compute on frontend):
```js
const total = cart.items.reduce(
  (sum, item) => sum + parseFloat(item.labPackage.price ?? 0) * item.quantity, 0
);
```

---

### 4. Add Item to Cart

- **Method:** `POST`
- **Path:** `/api/lab/cart/add`

#### Request Body

```json
{
  "labPackageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "quantity": 1
}
```

| Field | Type | Required | Validation | Description |
|:--|:--|:--|:--|:--|
| `labPackageId` | `string (UUID)` | **Yes** | Valid UUID | The package to add |
| `quantity` | `number` | No | Integer 1–10. Default: `1` | Quantity |

> **Upsert behaviour:** If the same package is already in the cart, its quantity is **replaced** (not added) with the new value.

#### Example Request

```bash
curl -X POST "http://localhost:5000/api/lab/cart/add" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "labPackageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "quantity": 1 }'
```

#### Success Response — `201 Created`

```json
{
  "success": true,
  "statusCode": 201,
  "message": "Package added to cart",
  "data": {
    "id": "item-uuid",
    "cartId": "cart-uuid",
    "labPackageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "quantity": 1,
    "createdAt": "2026-08-29T07:00:00.000Z",
    "labPackage": { "id": "...", "name": "Full Body Checkup", "price": "999.00" }
  }
}
```

#### Error Responses

| Scenario | HTTP | Message |
|:--|:--|:--|
| Invalid UUID format | `400` | `"labPackageId must be a valid UUID"` |
| Package does not exist | `404` | `"Lab package not found"` |
| Package is unavailable | `400` | `"This lab package is currently unavailable"` |

---

### 5. Remove Item from Cart

- **Method:** `DELETE`
- **Path:** `/api/lab/cart/items/:labPackageId`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `labPackageId` | `string (UUID)` | Yes | The package to remove |

#### Example Request

```bash
curl -X DELETE "http://localhost:5000/api/lab/cart/items/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Package removed from cart",
  "data": null
}
```

> If removing the last item, the cart row is also deleted. Next `GET /cart` will return `{ "items": [] }`.

#### Not Found — `404`

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Package not found in cart"
}
```

---

### 6. Clear Entire Cart

Removes all items and deletes the cart in one call.

- **Method:** `DELETE`
- **Path:** `/api/lab/cart`

#### Example Request

```bash
curl -X DELETE "http://localhost:5000/api/lab/cart" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Cart cleared",
  "data": null
}
```

---

## Part 3 — Checkout (Requires Patient Auth)

### 7. Checkout

Converts the cart into a `LabOrder` and starts the dispatch chain. Returns immediately with a `202` — the actual lab assignment happens asynchronously.

- **Method:** `POST`
- **Path:** `/api/lab/cart/checkout`

#### Request Body

```json
{
  "patientLat": 18.5204,
  "patientLong": 73.8567
}
```

| Field | Type | Required | Validation | Description |
|:--|:--|:--|:--|:--|
| `patientLat` | `number` | No | -90 to 90 | Patient's current latitude |
| `patientLong` | `number` | No | -180 to 180 | Patient's current longitude |

> **Important — Always send GPS coordinates.** The system uses PostGIS to find lab partners within 10 km of the patient, ranked by subscription tier then distance. Without coordinates, all labs nationwide are eligible (no radius filter), which may result in a lab far away being dispatched.

#### Example Request

```bash
curl -X POST "http://localhost:5000/api/lab/cart/checkout" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{ "patientLat": 18.5204, "patientLong": 73.8567 }'
```

#### Success Response — `202 Accepted`

```json
{
  "success": true,
  "statusCode": 202,
  "message": "Order placed! We are contacting a nearby lab. You will be notified once a lab accepts.",
  "data": {
    "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "status": "PENDING",
    "itemCount": 3
  }
}
```

**After receiving `202`:**
- Clear the cart state locally (server already deleted it)
- Save `orderId` for navigation
- Navigate to an "Order Placed" confirmation screen
- Tell the patient: *"We are searching for a nearby lab. You will receive a notification once a lab accepts."*

#### Error Responses

| Scenario | HTTP | Message |
|:--|:--|:--|
| Cart is empty | `400` | `"Your cart is empty"` |
| No labs available in range | `503` | `"No nearby lab partners are available right now. Please try again later."` |

---

## Part 4 — FCM Notifications (Patient Side)

The system sends two types of FCM push notifications to the patient after checkout.

### Order Accepted

```json
{
  "title": "✅ Lab Order Accepted!",
  "body": "City Diagnostics has accepted your order: Full Body Checkup x1",
  "data": {
    "type": "LAB_ORDER_ACCEPTED",
    "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "labName": "City Diagnostics"
  }
}
```

**On tap:** Navigate to `/lab/orders/:orderId` (order detail screen).

### Order Expired (All Labs Timed Out)

```json
{
  "title": "Lab Order Expired",
  "body": "Sorry, no nearby lab was available to accept your order. Please try again.",
  "data": {
    "type": "LAB_ORDER_EXPIRED",
    "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  }
}
```

**On tap:** Navigate to the order detail screen, show an error state with a "Try Again" CTA that sends the user back to the catalog.

---

## Part 5 — Order History (Requires Patient Auth)

### 8. List My Lab Orders

- **Method:** `GET`
- **Path:** `/api/lab/orders`

#### Example Request

```bash
curl -X GET "http://localhost:5000/api/lab/orders" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "patientId": "patient-uuid",
      "patientName": "Rahul Sharma",
      "patientPhone": "+919876543210",
      "patientLat": 18.5204,
      "patientLong": 73.8567,
      "status": "ACCEPTED",
      "acceptedById": "lab-partner-uuid",
      "createdAt": "2026-08-29T07:30:00.000Z",
      "updatedAt": "2026-08-29T07:33:00.000Z",
      "items": [
        {
          "id": "item-uuid",
          "packageName": "Full Body Checkup",
          "price": "999.00",
          "quantity": 1,
          "labPackage": {
            "id": "pkg-uuid",
            "category": "Preventive",
            "tests": ["CBC", "Lipid Profile"]
          }
        }
      ]
    }
  ]
}
```

Orders are sorted **newest first** (`createdAt DESC`).

---

### 9. Get Single Lab Order

- **Method:** `GET`
- **Path:** `/api/lab/orders/:orderId`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `orderId` | `string (UUID)` | Yes | The order ID |

#### Example Request

```bash
curl -X GET "http://localhost:5000/api/lab/orders/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer <PATIENT_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "status": "ACCEPTED",
    "acceptedById": "lab-partner-uuid",
    "patientName": "Rahul Sharma",
    "patientPhone": "+919876543210",
    "createdAt": "2026-08-29T07:30:00.000Z",
    "items": [
      {
        "packageName": "Full Body Checkup",
        "price": "999.00",
        "quantity": 1,
        "labPackage": {
          "id": "pkg-uuid",
          "name": "Full Body Checkup",
          "category": "Preventive",
          "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"]
        }
      }
    ],
    "dispatches": [
      {
        "queueIndex": 0,
        "status": "ACCEPTED",
        "notifiedAt": "2026-08-29T07:30:05.000Z",
        "respondedAt": "2026-08-29T07:32:00.000Z",
        "partner": {
          "id": "lab-partner-uuid",
          "name": "Dr. Lab Admin",
          "orgName": "City Diagnostics"
        }
      },
      {
        "queueIndex": 1,
        "status": "SKIPPED",
        "notifiedAt": null,
        "respondedAt": null,
        "partner": {
          "id": "other-lab-uuid",
          "name": "Lab Admin 2",
          "orgName": "Metro Labs"
        }
      }
    ]
  }
}
```

> **Show lab name:** When `status === "ACCEPTED"`, display `dispatches.find(d => d.status === "ACCEPTED").partner.orgName` as the accepting lab's name.

#### Not Found — `404`

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Order not found"
}
```

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

### 400 Validation / Business Rule Error

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Your cart is empty"
}
```

### 503 Service Unavailable

```json
{
  "success": false,
  "statusCode": 503,
  "message": "No nearby lab partners are available right now. Please try again later."
}
```

---

## Typical Patient Frontend Flow

```
1. On Lab screen load:
   GET /api/labs/categories → populate filter chips
   GET /api/labs/catalog    → render package grid/list

2. Patient filters / searches:
   GET /api/labs/catalog?search=thyroid&category=Thyroid
   → Re-render filtered results

3. Patient taps "Add to Cart" on a package:
   POST /api/lab/cart/add
   { "labPackageId": "...", "quantity": 1 }
   → Update cart badge count

4. Patient opens cart:
   GET /api/lab/cart
   → Show items, quantities, and total price

5. Patient removes an item:
   DELETE /api/lab/cart/items/:labPackageId
   → Refresh cart

6. Patient taps "Checkout":
   → Request GPS permission
   POST /api/lab/cart/checkout
   { "patientLat": ..., "patientLong": ... }
   → 202: Navigate to "Order Placed" screen
   → 503: Show "No labs available" error with retry option

7. Patient waits for FCM:
   type: "LAB_ORDER_ACCEPTED" → show success toast, navigate to order detail
   type: "LAB_ORDER_EXPIRED"  → show error, offer retry / back to catalog

8. Patient views order history:
   GET /api/lab/orders
   → List all orders with status badges

9. Patient taps an order:
   GET /api/lab/orders/:orderId
   → Show items, accepting lab name (if ACCEPTED), dispatch timeline
```

---

## Related Documentation

- [Lab Admin API](./lab-admin-api.md) — Admin management of global lab packages
- [Lab Partner API](./lab-partner-api.md) — Lab partner order dispatch and accept endpoints
- [Push Notifications](./push-notifications.md) — FCM setup and notification handling

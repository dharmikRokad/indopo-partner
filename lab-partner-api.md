# Lab Orders API — Partner Integration Guide

This document covers all lab-order endpoints that the **lab partner frontend** should consume. When a patient checks out, the system dispatches the order to nearby LABORATORY partners one at a time via FCM push notification. The first partner to accept within 5 minutes wins the order.

> **Base URL:** `http://localhost:5000/api/partner-auth`  
> **Authentication:** All endpoints require a valid Partner JWT passed as a Bearer token.  
> **Content-Type:** `application/json`

---

## Authentication

Include the partner JWT in every request:

```http
Authorization: Bearer <PARTNER_JWT_TOKEN>
```

Obtain the token from `POST /api/partner-auth/login`. Only partners with `partnerType: "LABORATORY"` will receive lab order dispatches.

---

## Dispatch Status Reference

Each dispatch slot tracks the partner's state in the waterfall queue.

| `dispatchStatus` | Badge Color | Meaning |
|:--|:--|:--|
| `PENDING` | Grey | Slot queued — not yet your turn |
| `NOTIFIED` | Amber/Orange | FCM sent — 5-minute acceptance window is open |
| `ACCEPTED` | Green | You accepted this order |
| `TIMED_OUT` | Red | 5-minute window expired without response |
| `SKIPPED` | Grey | Another lab accepted this order first |

---

## Order Status Reference

| `order.status` | Meaning |
|:--|:--|
| `PENDING` | No lab has accepted yet |
| `ACCEPTED` | A lab has accepted this order |
| `EXPIRED` | All labs in the queue timed out |
| `CANCELLED` | Order was cancelled |

---

## Endpoints

### 1. List Lab Orders (Dispatched to This Partner)

Fetch all dispatch slots where this partner was notified. Includes full order and patient details.

- **Method:** `GET`
- **Path:** `/api/partner-auth/lab-orders`

#### Example Request

```bash
curl -X GET "http://localhost:5000/api/partner-auth/lab-orders" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>"
```

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "OK",
  "data": [
    {
      "dispatchId": "d1e2f3a4-b5c6-7890-dcba-fedcba987654",
      "dispatchStatus": "NOTIFIED",
      "notifiedAt": "2026-08-29T07:30:00.000Z",
      "respondedAt": null,
      "order": {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "patientName": "Rahul Sharma",
        "patientPhone": "+919876543210",
        "patientLat": 18.5204,
        "patientLong": 73.8567,
        "status": "PENDING",
        "createdAt": "2026-08-29T07:29:58.000Z",
        "updatedAt": "2026-08-29T07:29:58.000Z",
        "items": [
          {
            "id": "item-uuid",
            "packageName": "Full Body Checkup",
            "price": "999.00",
            "quantity": 1,
            "labPackage": {
              "id": "pkg-uuid",
              "category": "Preventive",
              "tests": ["CBC", "Lipid Profile", "Blood Sugar Fasting"]
            }
          }
        ],
        "patient": {
          "id": "patient-uuid",
          "firstName": "Rahul",
          "lastName": "Sharma",
          "phone": "+919876543210"
        }
      }
    }
  ]
}
```

**Response is sorted newest-first** by `createdAt`.

**Computed values to derive on the frontend:**

| Value | How to compute |
|:--|:--|
| Total order value | `sum(item.price * item.quantity)` |
| Test summary string | `items.map(i => i.packageName + ' x' + i.quantity).join(', ')` |
| Minutes remaining | `5 - Math.floor((Date.now() - new Date(notifiedAt)) / 60000)` |

---

### 2. Accept a Lab Order

Accept a dispatched order. Must be called within 5 minutes of receiving the FCM notification.

- **Method:** `POST`
- **Path:** `/api/partner-auth/lab-orders/:orderId/accept`

#### Path Parameters

| Parameter | Type | Required | Description |
|:--|:--|:--|:--|
| `orderId` | `string (UUID)` | Yes | The `order.id` from the dispatch list response (NOT `dispatchId`) |

#### Example Request

```bash
curl -X POST "http://localhost:5000/api/partner-auth/lab-orders/a1b2c3d4-e5f6-7890-abcd-ef1234567890/accept" \
  -H "Authorization: Bearer <PARTNER_JWT_TOKEN>"
```

No request body required.

#### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Order accepted. The patient has been notified.",
  "data": null
}
```

After a successful accept:
- The patient receives an FCM push: `"✅ Lab Order Accepted! <Your Org Name> has accepted your order."`
- The `order.status` changes to `ACCEPTED`
- All other partners in the queue get their slots marked `SKIPPED`
- Your `dispatchStatus` changes to `ACCEPTED`

#### Failure Responses — `400 Bad Request`

| Scenario | Error message |
|:--|:--|
| Not in the dispatch queue | `"You are not in the dispatch queue for this order"` |
| Order already accepted by another lab | `"This order has already been accepted"` |
| Your 5-minute window expired | `"Your acceptance window has expired for this order"` |
| Another lab accepted first | `"This order was already accepted by another lab"` |
| Not yet notified (future queue slot) | `"You have not received a notification for this order yet"` |

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Your acceptance window has expired for this order"
}
```

---

## FCM Push Notification (Incoming Order)

When it is your turn in the dispatch queue, the system sends an FCM push to the partner device.

### Notification Payload

```json
{
  "title": "🔬 New Lab Order Request",
  "body": "Patient: Rahul Sharma | Tests: Full Body Checkup x1, CBC Panel x2",
  "data": {
    "type": "LAB_ORDER_REQUEST",
    "orderId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "patientName": "Rahul Sharma",
    "patientPhone": "+919876543210",
    "items": "[{\"packageName\":\"Full Body Checkup\",\"quantity\":1,\"price\":\"999.00\"}]"
  }
}
```

> **Note:** `items` in the FCM payload is a **JSON-stringified array**. Parse it with `JSON.parse(data.items)` before use.

### Recommended App Behaviour on Receiving FCM

1. Show a local push notification (system tray) with the title and body.
2. On notification tap → navigate to the lab orders screen, highlight the specific order (use `data.orderId`).
3. Refresh the `GET /api/partner-auth/lab-orders` list to fetch the latest dispatch status.
4. Start a 5-minute countdown timer in the UI for that order card.

---

## Dispatch Waterfall — How It Works

```
Patient checks out
       ↓
System ranks nearby labs: tier (sponsored → featured → premium → free)
                          then distance (nearest first)
       ↓
FCM sent to Lab #1 (dispatchStatus = NOTIFIED)
5-minute timer starts
       ├── Lab #1 accepts within 5 min
       │     → order.status = ACCEPTED
       │     → All other slots = SKIPPED
       │     → Patient notified ✅
       └── Lab #1 does NOT accept within 5 min
             → Lab #1 slot = TIMED_OUT
             → FCM sent to Lab #2
             → 5-minute timer restarts
             └── If all labs time out
                   → order.status = EXPIRED
                   → Patient notified ❌
```

---

## Real-time Refresh Strategy

There is no WebSocket; use these triggers to keep the list fresh:

| Trigger | Action |
|:--|:--|
| Receive FCM with `type: "LAB_ORDER_REQUEST"` | Call `GET /api/partner-auth/lab-orders` |
| App returns to foreground | Call `GET /api/partner-auth/lab-orders` |
| Partner taps "Accept" (success or failure) | Call `GET /api/partner-auth/lab-orders` |
| Periodic background poll (fallback) | Every 30–60 seconds while app is open |

---

## 5-Minute Countdown Timer

For each order with `dispatchStatus === "NOTIFIED"` and `order.status === "PENDING"`, compute:

```js
const notifiedAt = new Date(dispatch.notifiedAt);
const expiresAt  = new Date(notifiedAt.getTime() + 5 * 60 * 1000); // +5 minutes
const remaining  = Math.max(0, expiresAt - Date.now()); // milliseconds
const minutes    = Math.floor(remaining / 60000);
const seconds    = Math.floor((remaining % 60000) / 1000);
```

Hide the "Accept Order" button and show a "Expired" state when `remaining <= 0`.

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

### 400 Bad Request

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Your acceptance window has expired for this order"
}
```

---

## Typical Partner Frontend Flow

```
1. App starts / comes to foreground:
   GET /api/partner-auth/lab-orders
   → Display all dispatched orders with status badges

2. FCM push received (type: "LAB_ORDER_REQUEST"):
   → Show local push notification
   → On tap: navigate to orders list, highlight orderId from data
   → Refresh GET /api/partner-auth/lab-orders

3. Partner sees NOTIFIED order with 5-min countdown:
   → Show "Accept Order" button + countdown timer

4. Partner taps "Accept Order" → confirmation dialog:
   POST /api/partner-auth/lab-orders/:orderId/accept
   → Success: toast "Order accepted!", refresh list (card shows ACCEPTED)
   → Failure: show error message from server

5. If partner misses the 5-min window:
   → dispatchStatus becomes TIMED_OUT (update via next list refresh)
   → Order moves to next partner in queue automatically
```

---

## Related Documentation

- [Lab Admin API](./lab-admin-api.md) — Admin management of global lab packages
- [Lab Patient API](./lab-patient-api.md) — Patient catalog, cart, and checkout endpoints

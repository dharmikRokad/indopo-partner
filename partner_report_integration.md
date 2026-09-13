# Lab Report — Partner App Integration

## What You Need to Build

After a lab accepts an order and completes the checkup, the partner needs a **"Mark Report Sent"** button that tells the system the WhatsApp report has been shared. The patient then gets a push notification to confirm receipt.

---

## Order Status Reference

Your UI should reflect these statuses:

| Status | Label to show partner |
|---|---|
| `PENDING` | Waiting... |
| `ACCEPTED` | Active — show "Mark Report Sent" button |
| `REPORT_SENT` | Report Sent — waiting for patient confirmation |
| `COMPLETED` | Completed ✅ |
| `EXPIRED` | Expired |
| `CANCELLED` | Cancelled |

---

## API — Mark Report Sent

```
POST /api/partner-auth/lab-orders/:orderId/report-sent
Authorization: Bearer <partner_token>
```

- **No request body required**
- **No query params required**

### Success `200`

```json
{
  "success": true,
  "message": "Report marked as sent. The patient has been notified to confirm receipt.",
  "data": null
}
```

### Error `400`

```json
{
  "success": false,
  "message": "Cannot mark report sent — order is currently report sent"
}
```

### All possible error messages

| Message | Cause |
|---|---|
| `Order not found` | Invalid orderId |
| `You did not accept this order` | Authenticated partner ≠ lab that accepted the order |
| `Cannot mark report sent — order is currently <status>` | Order is not in `ACCEPTED` state |

---

## Recommended UI Flow

```
Order Detail Screen
│
├── status == "ACCEPTED"
│     └── Show button: [ Send Report Confirmation ]
│           → On tap: call POST .../report-sent
│           → Show loading spinner
│           → On success: update local status to "REPORT_SENT"
│                         show message: "Patient notified to confirm receipt"
│           → On error: show snackbar with error message
│
├── status == "REPORT_SENT"
│     └── Show badge: "Waiting for patient confirmation..."
│           (no action button needed)
│
└── status == "COMPLETED"
      └── Show badge: "Completed ✅"
            (triggered by patient confirming — you get FCM push)
```

---

## FCM Notification You Will Receive

When the patient confirms they received the report, your app gets this push:

```
title: "Report Confirmed!"
body:  "The patient has confirmed receiving their lab report."

data: {
  "type":    "LAB_ORDER_COMPLETED",
  "orderId": "<uuid>"
}
```

### Flutter FCM Handler

```dart
// In your FCM message handler:
if (message.data['type'] == 'LAB_ORDER_COMPLETED') {
  final orderId = message.data['orderId'];
  // Refresh the order detail / order list
  // Show a success toast or badge update
}
```

---

## Notes

- The "Mark Report Sent" button must only be visible when `order.status == "ACCEPTED"`
- After tapping, disable the button immediately to prevent double-taps
- You do **not** need to poll for status — wait for the `LAB_ORDER_COMPLETED` FCM push to update the UI

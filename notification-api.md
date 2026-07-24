# Notification API Documentation

This document provides technical documentation for the Notification API, designed for frontend developers building Web or Flutter/Mobile applications.

---

## 1. Overview & Authentication

All notification endpoints require user authentication via Supabase Bearer JWT tokens.

* **Base URL**: `/api/notifications`
* **Authentication**: `Authorization: Bearer <SUPABASE_JWT_TOKEN>`
* **Content-Type**: `application/json`

> **User Scoping Note:** The API automatically detects whether the logged-in user is a **Patient** or a **Partner** based on their authenticated token and scopes notifications accordingly. 

---

## 2. Notification Data Models & Enums

### `NotificationType` Enum
Notifications belong to one of the following types:
- `APPOINTMENT_REMINDER` - Reminder for an upcoming appointment.
- `APPOINTMENT_CONFIRMED` - Notification when an appointment is confirmed.
- `APPOINTMENT_CANCELLED` - Notification when an appointment is cancelled.
- `REVIEW_REQUEST` - Request for patient to leave a partner review.
- `PRESCRIPTION_INQUIRY` - Patient inquiry sent to nearby pharmacies.
- `GENERAL` - General platform or system notification.

### `Notification` Object
```typescript
interface NotificationItem {
  id: string; // UUID
  patientId: string; // UUID
  partnerId: string | null; // UUID (optional partner reference)
  type: NotificationType;
  message: string;
  metadata: Record<string, any> | null; // Payload data (e.g., appointmentId, inquiryId)
  isRead: boolean;
  createdAt: string; // ISO 8601 Timestamp

  // Relations (Included if associated)
  partner?: {
    id: string;
    name: string;
    orgName: string;
    partnerType: string; // 'DOCTOR' | 'PHARMACY' | 'LABORATORY' | 'IMAGING_CENTER'
    orgAddress: string;
  } | null;

  patient?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  } | null;
}
```

---

## 3. Endpoints

---

### Endpoint 1: List Notifications with Pagination & Filters

Retrieves a paginated list of notifications for the authenticated user, supporting filtering, text search, date range filtering, and custom sorting.

* **HTTP Method**: `GET`
* **Route**: `/api/notifications`

#### Query Parameters

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `page` | `number` | No | `1` | Page number (min: 1) |
| `limit` | `number` | No | `20` | Items per page (min: 1, max: 100) |
| `isRead` | `boolean` | No | - | Filter by read status: `true` (read only), `false` (unread only) |
| `type` | `string` | No | - | Filter by notification type enum (e.g. `PRESCRIPTION_INQUIRY`, `APPOINTMENT_CONFIRMED`) |
| `search` | `string` | No | - | Case-insensitive text search in notification message |
| `patientId` | `string` | No | - | Filter by specific patient ID (UUID) |
| `partnerId` | `string` | No | - | Filter by specific partner ID (UUID) |
| `startDate` | `string` | No | - | Start date filter (`YYYY-MM-DD` or ISO string) |
| `endDate` | `string` | No | - | End date filter (`YYYY-MM-DD` or ISO string) |
| `sortBy` | `string` | No | `createdAt` | Field to sort by: `createdAt` \| `isRead` |
| `sortOrder` | `string` | No | `desc` | Sort order direction: `asc` \| `desc` |

#### Request Examples

##### Example 1: Fetch first page of unread notifications
```http
GET /api/notifications?page=1&limit=10&isRead=false HTTP/1.1
Host: api.indopo.com
Authorization: Bearer <TOKEN>
```

##### Example 2: Filter prescription inquiry notifications with search
```http
GET /api/notifications?type=PRESCRIPTION_INQUIRY&search=prescription&sortBy=createdAt&sortOrder=desc HTTP/1.1
Host: api.indopo.com
Authorization: Bearer <TOKEN>
```

##### Example 3: Filter by date range
```http
GET /api/notifications?startDate=2026-07-01&endDate=2026-07-31 HTTP/1.1
Host: api.indopo.com
Authorization: Bearer <TOKEN>
```

#### Success Response (`200 OK`)

```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "c138d6bf-4e20-4e3b-b2b7-a364cf233bc2",
        "patientId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
        "partnerId": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
        "type": "PRESCRIPTION_INQUIRY",
        "message": "New prescription inquiry from John Doe. Tap to view inquiry.",
        "metadata": {
          "prescriptionInquiryId": "8f3192a0-4567-4890-a123-bcdef4567890",
          "patientName": "John Doe",
          "chatId": "e5d6c7b8-a910-1112-1314-151617181920"
        },
        "isRead": false,
        "createdAt": "2026-07-23T21:14:41.000Z",
        "partner": {
          "id": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
          "name": "City Care Pharmacy",
          "orgName": "City Care Pharmacy Ltd",
          "partnerType": "PHARMACY",
          "orgAddress": "123 Healthcare Blvd, Suite 100"
        },
        "patient": {
          "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
          "firstName": "John",
          "lastName": "Doe",
          "email": "john.doe@example.com"
        }
      }
    ],
    "pagination": {
      "total": 1,
      "page": 1,
      "limit": 20,
      "totalPages": 1,
      "hasNextPage": false,
      "hasPrevPage": false
    },
    "unreadCount": 1
  }
}
```

---

### Endpoint 2: Mark Notification as Read

Marks a specific notification record as read (`isRead: true`).

* **HTTP Method**: `PATCH`
* **Route**: `/api/notifications/:id/read`

#### Path Parameters

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Yes | Notification UUID |

#### Request Example
```http
PATCH /api/notifications/c138d6bf-4e20-4e3b-b2b7-a364cf233bc2/read HTTP/1.1
Host: api.indopo.com
Authorization: Bearer <TOKEN>
```

#### Success Response (`200 OK`)

```json
{
  "success": true,
  "data": {
    "id": "c138d6bf-4e20-4e3b-b2b7-a364cf233bc2",
    "patientId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "partnerId": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
    "type": "PRESCRIPTION_INQUIRY",
    "message": "New prescription inquiry from John Doe. Tap to view inquiry.",
    "metadata": {
      "prescriptionInquiryId": "8f3192a0-4567-4890-a123-bcdef4567890"
    },
    "isRead": true,
    "createdAt": "2026-07-23T21:14:41.000Z"
  },
  "message": "Notification marked as read"
}
```

---

## 4. Error Responses

### `401 Unauthorized`
Occurs when the `Authorization` header is missing, invalid, or expired.
```json
{
  "success": false,
  "message": "Invalid or expired token"
}
```

### `400 Bad Request`
Occurs when query or path parameters fail validation (e.g. invalid UUID or unknown enum value).
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "type": ["Invalid enum value. Expected 'APPOINTMENT_REMINDER' | 'APPOINTMENT_CONFIRMED' | ..."]
  }
}
```

### `404 Not Found`
Occurs when trying to mark a non-existent notification as read or accessing a notification not belonging to the user.
```json
{
  "success": false,
  "message": "Notification not found"
}
```

---

## 5. Frontend Integration Code Examples

### TypeScript / Axios Example (Web)

```typescript
import axios from 'axios';

export interface GetNotificationsParams {
  page?: number;
  limit?: number;
  isRead?: boolean;
  type?: string;
  search?: string;
  startDate?: string;
  endDate?: string;
  sortBy?: 'createdAt' | 'isRead';
  sortOrder?: 'asc' | 'desc';
}

export async function fetchNotifications(token: string, params: GetNotificationsParams = {}) {
  const response = await axios.get('/api/notifications', {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    params,
  });
  return response.data.data;
}

export async function markNotificationAsRead(token: string, notificationId: string) {
  const response = await axios.patch(
    `/api/notifications/${notificationId}/read`,
    {},
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );
  return response.data.data;
}
```

---

### Flutter / Dart Integration Example (Mobile App)

#### Data Models (`notification_model.dart`)

```dart
class NotificationResponse {
  final List<NotificationItem> notifications;
  final Pagination pagination;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.pagination,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

class NotificationItem {
  final String id;
  final String patientId;
  final String? partnerId;
  final String type;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.patientId,
    this.partnerId,
    required this.type,
    required this.message,
    this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      patientId: json['patientId'],
      partnerId: json['partnerId'],
      type: json['type'],
      message: json['message'],
      metadata: json['metadata'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

#### API Service (`notification_service.dart`)

```dart
import 'dart:convert';
import 'http_client.dart'; // Your base HTTP client wrapper

class NotificationApiService {
  final HttpClient client;

  NotificationApiService(this.client);

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (isRead != null) queryParams['isRead'] = isRead.toString();
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

    final uri = Uri.parse('/api/notifications').replace(queryParameters: queryParams);
    final response = await client.get(uri);

    final jsonBody = jsonDecode(response.body);
    if (jsonBody['success'] == true) {
      return NotificationResponse.fromJson(jsonBody['data']);
    } else {
      throw Exception(jsonBody['message'] ?? 'Failed to fetch notifications');
    }
  }

  Future<NotificationItem> markAsRead(String notificationId) async {
    final response = await client.patch(Uri.parse('/api/notifications/$notificationId/read'));
    final jsonBody = jsonDecode(response.body);

    if (jsonBody['success'] == true) {
      return NotificationItem.fromJson(jsonBody['data']);
    } else {
      throw Exception(jsonBody['message'] ?? 'Failed to mark notification as read');
    }
  }
}
```

---

## 6. Recommended Frontend UX Guidelines

1. **Badge Counter**: Use the top-level `unreadCount` field in the response to display the unread notification badge on the bell icon without needing a separate count query.
2. **Infinite Scroll / Pagination**: Check `pagination.hasNextPage`. When user scrolls to bottom of list, increment `page` parameter and append returned items to state array.
3. **Optimistic UI Updates**: When tapping a notification item, immediately update its `isRead` property to `true` and decrement local `unreadCount` by 1 before awaiting the `PATCH /api/notifications/:id/read` API call.
4. **Push Notification Handling**: Upon receiving a push notification (FCM / APNs), re-fetch page 1 (`page=1&limit=20`) to get the latest feed.

# Partner Profile API — Frontend Integration Guide

This document is the **complete reference for frontend developers** integrating the two partner-panel profile endpoints. These endpoints let an authenticated partner **view** and **edit** their own profile data — including doctor-specific fields — without needing to pass a partner ID in the URL (the ID is derived from the JWT automatically).

> **Base URL:** `http://localhost:5000/api/partner-auth`  
> **Content-Type:** `application/json`  
> **Auth Stack:** Supabase Auth (JWT Bearer tokens)  
> **Auth Required:** Yes — both endpoints require `Authorization: Bearer <accessToken>`

---

## Table of Contents

1. [Get Own Profile](#1-get-own-profile)
2. [Edit Own Profile](#2-edit-own-profile)
3. [Profile Object Shape](#3-profile-object-shape)
4. [TypeScript Types](#4-typescript-types)
5. [Axios Integration Examples](#5-axios-integration-examples)
6. [Common Error Responses](#6-common-error-responses)
7. [Integration Workflow](#7-integration-workflow)

---

## 1. Get Own Profile

Fetches the full profile of the currently authenticated partner, including their doctor profile (if applicable) and available services.

- **Method:** `GET`
- **Path:** `/api/partner-auth/profile`
- **Auth Required:** Yes

### Example Request

```bash
curl -X GET "http://localhost:5000/api/partner-auth/profile" \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

### Success Response — `200 OK`

```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "id": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
    "name": "Dr. Sarah Jenkins",
    "email": "doctor@example.com",
    "phone": "+919876543210",
    "orgName": "City General Hospital",
    "orgAddress": "123 Health Ave, Medical District",
    "partnerType": "DOCTOR",
    "isActive": true,
    "isAvailable": true,
    "isVerified": true,
    "rating": "4.5",
    "openTime": "09:00",
    "closeTime": "18:00",
    "workingDays": ["MON", "TUE", "WED", "THU", "FRI"],
    "lat": "18.5204",
    "long": "73.8567",
    "subscriptionTier": "free",
    "createdAt": "2026-01-15T10:30:00.000Z",
    "updatedAt": "2026-07-18T08:00:00.000Z",
    "doctorProfile": {
      "id": "a7e12345-1234-4abc-9012-def012345678",
      "partnerId": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
      "qualification": "MBBS, MD (Cardiology)",
      "experienceYrs": 10,
      "consultationFee": "500.00",
      "licenseNumber": "MH-DOC-12345",
      "specialityId": "b9f11111-aaaa-4bbb-8ccc-ddd000000001",
      "speciality": {
        "id": "b9f11111-aaaa-4bbb-8ccc-ddd000000001",
        "name": "Cardiology",
        "icon": "heart",
        "description": "Heart and cardiovascular care"
      },
      "createdAt": "2026-01-15T10:31:00.000Z"
    },
    "services": [
      {
        "id": "b2085822-86d4-4076-acbb-464ceeeeffa0",
        "name": "General Consultation",
        "category": "Consultation",
        "description": "Standard 30-minute consultation",
        "price": "500.00",
        "isAvailable": true,
        "createdAt": "2026-01-20T09:00:00.000Z"
      }
    ]
  }
}
```

> **Note:** `doctorProfile` is `null` for non-DOCTOR partner types (PHARMACY, LABORATORY, IMAGING_CENTER). Always null-check before accessing.

### Error — `404 Not Found`

Returned when the authenticated user's ID does not match any partner record in the database:

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Partner profile not found"
}
```

---

## 2. Edit Own Profile

Partially updates the authenticated partner's profile. Only the fields you send will be updated — all other fields remain unchanged (PATCH semantics).

- **Method:** `PATCH`
- **Path:** `/api/partner-auth/profile`
- **Auth Required:** Yes

### Request Body

All fields are **optional**. Send only the fields you wish to update.

```json
{
  "name": "Dr. Sarah Jenkins",
  "phone": "+919876543210",
  "orgName": "City General Hospital",
  "orgAddress": "123 Health Ave, Medical District",
  "openTime": "09:00",
  "closeTime": "18:00",
  "workingDays": ["MON", "TUE", "WED", "THU", "FRI"],
  "lat": 18.5204,
  "long": 73.8567,
  "doctorProfile": {
    "qualification": "MBBS, MD (Cardiology)",
    "experienceYrs": 10,
    "consultationFee": 500,
    "specialityId": "b9f11111-aaaa-4bbb-8ccc-ddd000000001"
  }
}
```

### Field Reference

#### Partner Fields

| Field | Type | Validation | Description |
|:--|:--|:--|:--|
| `name` | `string` | Min 1 char | Display name of the partner |
| `phone` | `string` | Min 1 char | Contact phone number |
| `orgName` | `string` | Min 1 char | Organisation / clinic / pharmacy name |
| `orgAddress` | `string` | Min 1 char | Organisation address |
| `openTime` | `string \| null` | — | Opening time, e.g. `"09:00"` (HH:mm) |
| `closeTime` | `string \| null` | — | Closing time, e.g. `"18:00"` (HH:mm) |
| `workingDays` | `string[]` | — | Array of day abbreviations e.g. `["MON","TUE"]` |
| `lat` | `number \| null` | -90 to 90 | Latitude of the partner location |
| `long` | `number \| null` | -180 to 180 | Longitude of the partner location |

#### `doctorProfile` Sub-object (DOCTOR partners only)

| Field | Type | Validation | Description |
|:--|:--|:--|:--|
| `qualification` | `string` | — | Academic qualifications e.g. `"MBBS, MD"` |
| `experienceYrs` | `number` | Integer ≥ 0 | Years of practice experience |
| `consultationFee` | `number` | Positive number | Consultation fee in local currency |
| `specialityId` | `string` | Valid UUID | ID from the `/api/specialities` endpoint |

> **Important:** The `doctorProfile` sub-object is silently ignored for non-DOCTOR partners.

### Minimal Example — Update Phone Only

```bash
curl -X PATCH "http://localhost:5000/api/partner-auth/profile" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+919988776655"
  }'
```

### Full Example — Update All Fields

```bash
curl -X PATCH "http://localhost:5000/api/partner-auth/profile" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. Sarah Jenkins",
    "phone": "+919876543210",
    "orgName": "City General Hospital",
    "orgAddress": "456 Wellness Road, Medical District",
    "openTime": "08:30",
    "closeTime": "17:30",
    "workingDays": ["MON", "TUE", "WED", "THU", "FRI", "SAT"],
    "lat": 18.5204,
    "long": 73.8567,
    "doctorProfile": {
      "experienceYrs": 11,
      "consultationFee": 600
    }
  }'
```

### Success Response — `200 OK`

Returns the full updated profile (same shape as the GET response):

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Profile updated successfully",
  "data": {
    "id": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
    "name": "Dr. Sarah Jenkins",
    "email": "doctor@example.com",
    "phone": "+919876543210",
    "orgName": "City General Hospital",
    "orgAddress": "456 Wellness Road, Medical District",
    "partnerType": "DOCTOR",
    "isActive": true,
    "isAvailable": true,
    "isVerified": true,
    "rating": "4.5",
    "openTime": "08:30",
    "closeTime": "17:30",
    "workingDays": ["MON", "TUE", "WED", "THU", "FRI", "SAT"],
    "lat": "18.5204",
    "long": "73.8567",
    "subscriptionTier": "free",
    "createdAt": "2026-01-15T10:30:00.000Z",
    "updatedAt": "2026-07-18T09:05:00.000Z",
    "doctorProfile": {
      "id": "a7e12345-1234-4abc-9012-def012345678",
      "partnerId": "603f93a1-6ab9-4a76-9a90-f46ef88641d6",
      "qualification": "MBBS, MD (Cardiology)",
      "experienceYrs": 11,
      "consultationFee": "600.00",
      "licenseNumber": "MH-DOC-12345",
      "specialityId": "b9f11111-aaaa-4bbb-8ccc-ddd000000001",
      "speciality": {
        "id": "b9f11111-aaaa-4bbb-8ccc-ddd000000001",
        "name": "Cardiology",
        "icon": "heart",
        "description": "Heart and cardiovascular care"
      },
      "createdAt": "2026-01-15T10:31:00.000Z"
    },
    "services": [
      {
        "id": "b2085822-86d4-4076-acbb-464ceeeeffa0",
        "name": "General Consultation",
        "category": "Consultation",
        "description": "Standard 30-minute consultation",
        "price": "500.00",
        "isAvailable": true,
        "createdAt": "2026-01-20T09:00:00.000Z"
      }
    ]
  }
}
```

### Validation Error — `400 Bad Request`

Returned when a field fails Zod validation:

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": {
    "lat": ["Number must be greater than or equal to -90"],
    "doctorProfile.specialityId": ["Invalid speciality ID"]
  }
}
```

---

## 3. Profile Object Shape

Both endpoints return identical profile objects. Here is the complete shape for reference:

```
Partner
├── id              string (UUID)
├── name            string
├── email           string
├── phone           string
├── orgName         string
├── orgAddress      string
├── partnerType     "DOCTOR" | "PHARMACY" | "LABORATORY" | "IMAGING_CENTER"
├── isActive        boolean
├── isAvailable     boolean
├── isVerified      boolean
├── rating          string  (decimal, e.g. "4.5")
├── openTime        string | null   (HH:mm)
├── closeTime       string | null   (HH:mm)
├── workingDays     string[]
├── lat             string | null   (decimal)
├── long            string | null   (decimal)
├── subscriptionTier string
├── createdAt       ISO 8601 string
├── updatedAt       ISO 8601 string
│
├── doctorProfile   DoctorProfile | null   (only for DOCTOR partners)
│   ├── id                string (UUID)
│   ├── partnerId         string (UUID)
│   ├── qualification     string | null
│   ├── experienceYrs     number
│   ├── consultationFee   string | null  (decimal)
│   ├── licenseNumber     string
│   ├── specialityId      string | null (UUID)
│   ├── createdAt         ISO 8601 string
│   └── speciality        Speciality | null
│       ├── id            string (UUID)
│       ├── name          string
│       ├── icon          string | null
│       └── description   string | null
│
└── services        Service[]   (only available/active services)
    ├── id          string (UUID)
    ├── name        string
    ├── category    string
    ├── description string | null
    ├── price       string | null  (decimal)
    ├── isAvailable boolean
    └── createdAt   ISO 8601 string
```

---

## 4. TypeScript Types

Copy these types into your frontend project for full type safety:

```typescript
// types/partner.ts

export type PartnerType = 'DOCTOR' | 'PHARMACY' | 'LABORATORY' | 'IMAGING_CENTER';

export interface Speciality {
  id: string;
  name: string;
  icon: string | null;
  description: string | null;
}

export interface DoctorProfile {
  id: string;
  partnerId: string;
  qualification: string | null;
  experienceYrs: number;
  consultationFee: string | null;
  licenseNumber: string;
  specialityId: string | null;
  speciality: Speciality | null;
  createdAt: string;
}

export interface PartnerService {
  id: string;
  name: string;
  category: string;
  description: string | null;
  price: string | null;
  isAvailable: boolean;
  createdAt: string;
}

export interface PartnerProfile {
  id: string;
  name: string;
  email: string;
  phone: string;
  orgName: string;
  orgAddress: string;
  partnerType: PartnerType;
  isActive: boolean;
  isAvailable: boolean;
  isVerified: boolean;
  rating: string;
  openTime: string | null;
  closeTime: string | null;
  workingDays: string[];
  lat: string | null;
  long: string | null;
  subscriptionTier: string;
  createdAt: string;
  updatedAt: string;
  doctorProfile: DoctorProfile | null;
  services: PartnerService[];
}

// ── Request type for PATCH /api/partner-auth/profile ──────────────────────────

export interface UpdateDoctorProfileInput {
  qualification?: string;
  experienceYrs?: number;
  consultationFee?: number;
  specialityId?: string;
}

export interface UpdateProfileInput {
  name?: string;
  phone?: string;
  orgName?: string;
  orgAddress?: string;
  openTime?: string | null;
  closeTime?: string | null;
  workingDays?: string[];
  lat?: number | null;
  long?: number | null;
  doctorProfile?: UpdateDoctorProfileInput;
}

// ── API response wrappers ──────────────────────────────────────────────────────

export interface ApiSuccessResponse<T> {
  success: true;
  data: T;
  message?: string;
}

export interface ApiErrorResponse {
  success: false;
  message: string;
  errors?: Record<string, string[]>;
}
```

---

## 5. Axios Integration Examples

These examples assume you have the shared Axios instance from [partner-auth-api.md](./partner-auth-api.md#6-token-storage--axios-setup) configured.

### Get Profile

```typescript
// api/partner-profile.ts
import api from '@/lib/api';
import type { PartnerProfile, ApiSuccessResponse } from '@/types/partner';

export async function getMyProfile(): Promise<PartnerProfile> {
  const res = await api.get<ApiSuccessResponse<PartnerProfile>>('/partner-auth/profile');
  return res.data.data;
}
```

### Edit Profile

```typescript
// api/partner-profile.ts (continued)
import type { UpdateProfileInput } from '@/types/partner';

export async function updateMyProfile(input: UpdateProfileInput): Promise<PartnerProfile> {
  const res = await api.patch<ApiSuccessResponse<PartnerProfile>>(
    '/partner-auth/profile',
    input
  );
  return res.data.data;
}
```

### React Hook Example

```typescript
// hooks/usePartnerProfile.ts
import { useState, useEffect } from 'react';
import { getMyProfile, updateMyProfile } from '@/api/partner-profile';
import type { PartnerProfile, UpdateProfileInput } from '@/types/partner';

export function usePartnerProfile() {
  const [profile, setProfile] = useState<PartnerProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getMyProfile()
      .then(setProfile)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  const updateProfile = async (input: UpdateProfileInput) => {
    setLoading(true);
    setError(null);
    try {
      const updated = await updateMyProfile(input);
      setProfile(updated);
      return updated;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to update profile';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { profile, loading, error, updateProfile };
}
```

### Usage in a Profile Edit Form

```tsx
// components/ProfileEditForm.tsx
import { usePartnerProfile } from '@/hooks/usePartnerProfile';
import type { UpdateProfileInput } from '@/types/partner';

export function ProfileEditForm() {
  const { profile, loading, error, updateProfile } = usePartnerProfile();

  const handleSubmit = async (formData: UpdateProfileInput) => {
    try {
      await updateProfile(formData);
      alert('Profile updated successfully!');
    } catch {
      // Error is already stored in `error` state
    }
  };

  if (loading) return <p>Loading...</p>;
  if (!profile) return <p>Profile not found.</p>;

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      // Collect form values and call handleSubmit(formValues)
    }}>
      {error && <p style={{ color: 'red' }}>{error}</p>}

      <label>Name
        <input name="name" defaultValue={profile.name} />
      </label>

      <label>Phone
        <input name="phone" defaultValue={profile.phone} />
      </label>

      <label>Organisation Name
        <input name="orgName" defaultValue={profile.orgName} />
      </label>

      <label>Organisation Address
        <input name="orgAddress" defaultValue={profile.orgAddress} />
      </label>

      <label>Open Time
        <input type="time" name="openTime" defaultValue={profile.openTime ?? ''} />
      </label>

      <label>Close Time
        <input type="time" name="closeTime" defaultValue={profile.closeTime ?? ''} />
      </label>

      {/* Show doctor fields only for DOCTOR partner type */}
      {profile.partnerType === 'DOCTOR' && profile.doctorProfile && (
        <>
          <label>Qualification
            <input name="qualification" defaultValue={profile.doctorProfile.qualification ?? ''} />
          </label>

          <label>Experience (years)
            <input type="number" name="experienceYrs"
              defaultValue={profile.doctorProfile.experienceYrs} />
          </label>

          <label>Consultation Fee
            <input type="number" name="consultationFee"
              defaultValue={profile.doctorProfile.consultationFee ?? ''} />
          </label>
        </>
      )}

      <button type="submit" disabled={loading}>
        {loading ? 'Saving...' : 'Save Changes'}
      </button>
    </form>
  );
}
```

---

## 6. Common Error Responses

### `401 Unauthorized` — Missing / Expired Token

```json
{
  "success": false,
  "statusCode": 401,
  "message": "Missing or malformed Authorization header"
}
```

### `401 Unauthorized` — Partner ID not in token

```json
{
  "success": false,
  "statusCode": 401,
  "message": "Partner ID not found in token"
}
```

### `404 Not Found` — Profile missing

```json
{
  "success": false,
  "statusCode": 404,
  "message": "Partner profile not found"
}
```

### `400 Bad Request` — Validation error (PATCH only)

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": {
    "lat": ["Number must be greater than or equal to -90"],
    "doctorProfile.specialityId": ["Invalid speciality ID"]
  }
}
```

---

## 7. Integration Workflow

### Recommended Flow for a Profile Settings Page

```
1. PAGE LOAD
   GET /api/partner-auth/profile
   → Populate all form fields with returned data
   → Store original values for dirty-state detection

2. USER EDITS FORM
   → Collect only changed fields (avoid sending unchanged values)
   → Conditionally build the doctorProfile sub-object
     (only if partnerType === "DOCTOR" and doctor fields were changed)

3. SAVE BUTTON
   PATCH /api/partner-auth/profile { ...changedFields }
   → On success: update local state / global store with returned profile
   → On 400: display field-level validation errors next to inputs
   → On 401: clear tokens → redirect to /login (handled by Axios interceptor)

4. AFTER SAVE
   → Show success toast/notification
   → Optionally refresh the global partner profile state
```

### Tips for the Frontend

- **Only send changed fields.** Computing a diff before the PATCH request reduces unnecessary DB writes and makes error messages more precise.
- **Speciality lookup.** Populate the `specialityId` dropdown by calling `GET /api/specialities` (no auth required).
- **`doctorProfile` guard.** Always check `partnerType === 'DOCTOR'` before rendering or sending doctor-specific fields. Non-doctor partners will have `doctorProfile: null` in the GET response.
- **Decimal fields.** `rating`, `lat`, `long`, `consultationFee` and `price` come back from the API as **strings** (Prisma `Decimal` serialisation). Parse with `parseFloat()` before using in calculations.
- **`updatedAt` freshness.** Use the returned `updatedAt` timestamp to show a "Last updated" indicator on the profile page.

---

## Related Documentation

- [Partner Auth API](./partner-auth-api.md) — Login, change password, availability toggle, account deactivation
- [Partner Appointments API](./partner-appointments-api.md) — Managing appointment requests from the partner panel
- [Refresh Token Integration](./refresh_token_integration.md) — Handling access token expiry and silent re-authentication

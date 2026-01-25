# EMS API Specification

> Version: 1.0.0
> Base URL: `/api`

## Authentication

All endpoints (except `/api/auth/login`) require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

Tokens expire after 7 days.

---

## Endpoints

### 1. Authentication

#### POST /api/auth/login
Login with mobile number and password.

| Field | Value |
|-------|-------|
| **Auth Required** | No |
| **Rate Limit** | 10 requests/minute |

**Request Body:**
```json
{
  "mobile_number": "+1234567890",
  "password": "string (min 6 chars)",
  "device_name": "Android Device (optional - for login history)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "jwt_token_string",
    "user": {
      "id": "uuid",
      "mobile_number": "+1234567890",
      "full_name": "John Doe",
      "role": "ADMIN|LEAD|EMPLOYEE",
      "team_id": "uuid|null"
    }
  }
}
```

**Note:** Login history (device_name, IP address, user_agent) is captured for security auditing.

**Error Cases:**
- 400: Missing mobile_number or password
- 401: Invalid credentials or account deactivated

---

#### POST /api/auth/signup
Employee self-registration. Creates user with EMPLOYEE role, no team assigned.

| Field | Value |
|-------|-------|
| **Auth Required** | No |
| **Rate Limit** | 5 requests/minute |

**Request Body:**
```json
{
  "full_name": "John Doe",
  "mobile_number": "+1234567890",
  "password": "string (min 6 chars)"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "mobile_number": "+1234567890",
      "full_name": "John Doe",
      "role": "EMPLOYEE",
      "team_id": null,
      "created_at": "timestamp"
    }
  }
}
```

**Error Cases:**
- 400: Missing required fields, password too short
- 409: Mobile number already registered

---

#### POST /api/auth/register
Register a new user (Admin only).

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 20 requests/minute |

**Request Body:**
```json
{
  "mobile_number": "+1234567890",
  "password": "string (min 6 chars)",
  "full_name": "string",
  "role": "ADMIN|LEAD|EMPLOYEE",
  "team_id": "uuid (optional)"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "mobile_number": "+1234567890",
      "full_name": "John Doe",
      "role": "EMPLOYEE",
      "team_id": "uuid|null",
      "created_at": "timestamp"
    }
  }
}
```

**Error Cases:**
- 400: Missing required fields, invalid role, weak password
- 401: Not authenticated
- 403: Not authorized (non-admin)
- 409: Mobile number already registered

---

#### GET /api/auth/me
Get current user's profile.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 60 requests/minute |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "mobile_number": "+1234567890",
      "full_name": "John Doe",
      "role": "EMPLOYEE",
      "team_id": "uuid|null",
      "team_name": "Engineering|null",
      "created_at": "timestamp"
    }
  }
}
```

---

### 2. Users

#### GET /api/users
List users with pagination.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN, LEAD) |
| **Rate Limit** | 30 requests/minute |

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 50, max: 100)
- `team_id` (optional, Admin only)
- `role` (optional, filter by role)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "users": [...],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 100,
      "totalPages": 2
    }
  }
}
```

**Note:** Leads can only see their own team members.

---

#### GET /api/users/:id
Get single user details.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN, LEAD) |
| **Rate Limit** | 60 requests/minute |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "mobile_number": "+1234567890",
      "full_name": "John Doe",
      "role": "EMPLOYEE",
      "team_id": "uuid",
      "team_name": "Engineering",
      "team_lead_name": "Jane Smith",
      "is_active": true,
      "created_at": "timestamp"
    }
  }
}
```

**Error Cases:**
- 404: User not found

---

#### PATCH /api/users/:id/assign-team
Assign user to a team.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 20 requests/minute |

**Request Body:**
```json
{
  "team_id": "uuid|null",
  "is_lead": true|false
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Team assignment updated",
  "data": {
    "user": {...}
  }
}
```

---

#### DELETE /api/users/:id
Soft delete a user.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 10 requests/minute |

**Success Response (200):**
```json
{
  "success": true,
  "message": "User deactivated successfully"
}
```

**Error Cases:**
- 400: Cannot delete yourself
- 404: User not found

---

### 3. Teams

#### GET /api/teams
List all teams.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 60 requests/minute |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "teams": [
      {
        "id": "uuid",
        "name": "Engineering",
        "lead_id": "uuid",
        "lead_name": "Jane Smith",
        "lead_mobile": "+1234567890",
        "member_count": 5,
        "is_active": true,
        "created_at": "timestamp"
      }
    ]
  }
}
```

---

#### POST /api/teams
Create a new team.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 20 requests/minute |

**Request Body:**
```json
{
  "name": "string",
  "lead_id": "uuid (optional)"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Team created successfully",
  "data": {
    "team": {...}
  }
}
```

**Error Cases:**
- 400: Missing name
- 404: Lead user not found
- 409: Team name already exists

---

#### GET /api/teams/:id
Get team with members.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 60 requests/minute |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "team": {...},
    "members": [...]
  }
}
```

---

#### PATCH /api/teams/:id
Update team.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 20 requests/minute |

**Request Body:**
```json
{
  "name": "string (optional)",
  "lead_id": "uuid|null (optional)"
}
```

---

#### DELETE /api/teams/:id
Soft delete a team.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 10 requests/minute |

**Error Cases:**
- 400: Cannot delete team with active members

---

### 4. Locations

#### GET /api/locations
List all office locations.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 60 requests/minute |

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "locations": [
      {
        "id": "uuid",
        "name": "HQ - New York",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "radius_meters": 50,
        "is_active": true,
        "created_at": "timestamp"
      }
    ]
  }
}
```

---

#### POST /api/locations
Create office location.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 20 requests/minute |

**Request Body:**
```json
{
  "name": "string",
  "latitude": -90 to 90,
  "longitude": -180 to 180,
  "radius_meters": 1-1000 (default: 50)
}
```

---

#### PATCH /api/locations/:id
Update location.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 20 requests/minute |

---

#### DELETE /api/locations/:id
Soft delete location.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN) |
| **Rate Limit** | 10 requests/minute |

---

### 5. Attendance

#### POST /api/attendance/check-in
Record check-in with GPS validation.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 5 requests/minute |

**Request Body:**
```json
{
  "latitude": -90 to 90,
  "longitude": -180 to 180
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Checked in at HQ - New York",
  "data": {
    "attendance": {
      "id": "uuid",
      "date": "2026-01-25",
      "check_in_time": "timestamp",
      "status": "PRESENT|LATE"
    },
    "location": "HQ - New York"
  }
}
```

**Error Cases:**
- 400: Invalid coordinates, already checked in, not within geofence, no locations configured

---

#### POST /api/attendance/check-out
Record check-out.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 5 requests/minute |

**Request Body:**
```json
{
  "latitude": -90 to 90,
  "longitude": -180 to 180
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Checked out successfully",
  "data": {
    "attendance": {...},
    "hoursWorked": "8.50"
  }
}
```

**Error Cases:**
- 400: Not checked in today, already checked out

---

#### GET /api/attendance/self
Get own attendance history.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (Any role) |
| **Rate Limit** | 30 requests/minute |

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 30, max: 100)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "attendance": [...],
    "pagination": {...}
  }
}
```

---

#### GET /api/attendance/team/:teamId
Get team attendance.

| Field | Value |
|-------|-------|
| **Auth Required** | Yes (ADMIN, LEAD) |
| **Rate Limit** | 30 requests/minute |

**Query Parameters:**
- `date` (optional, filter by date)
- `page` (default: 1)
- `limit` (default: 50, max: 100)

**Note:** Leads can only view their own team.

---

### 6. Health Check

#### GET /health
System health check.

| Field | Value |
|-------|-------|
| **Auth Required** | No |
| **Rate Limit** | None |

**Success Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-25T10:00:00Z",
  "uptime": 3600,
  "database": "connected"
}
```

---

## Standard Error Response

All errors follow this format:
```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (not logged in) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (duplicate) |
| 500 | Internal Server Error |
| 503 | Service Unavailable |

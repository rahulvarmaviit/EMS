# Geo-Attendance System: Technical Blueprint (Production Grade)

> **Role:** Principal Software Architect
> **Product:** Startup Attendance & Team Management System (Geo-fenced)
> **Scale:** Small Enterprise (~50 Users)
> **Constraint:** $0 Operational Cost (Free Tier Architecture)

---

## 1. Executive Summary
This document serves as the master technical plan for a mobile-first attendance system designed for small startups. The system ensures verified physical presence via geolocation, simplifies hierarchy management (CEO -> Lead -> Employee), and runs on a fully zero-cost infrastructure using robust free-tier services.

## 2. User Flows & Core Features

### 2.1 Roles
1.  **Admin (CEO):** Superuser. Manages organization structure (Teams, Leads). View global reports.
2.  **Team Lead:** Mid-level management. will have all employe features and Views attendance for their specific team members.
3.  **Employee:** End-user. Marks attendance with checkin and checkout. Views own history and Team Lead info and project details.

### 2.2 Critical User Flows

#### A. Login & Dynamic Routing (All Users)
1.  User enters **Mobile Number** & **Password**.
2.  Backend returns `token` and `role` (`ADMIN`, `LEAD`, `EMPLOYEE`).
3.  **App directs user to specific Home Interface:**
    *   **Admin:** Goes to *Admin Dashboard* (Organization Overview, Manage Teams).
    *   **Team Lead:** Goes to *Lead Dashboard* (Team List + 'My Attendance').
    *   **Employee:** Goes to *Employee Home* (Big 'Check In' Button + History).

#### B. Onboarding & Setup (Admin)
1.  Admin logs in with **Mobile Number** & Password (Pre-seeded).
2.  Admin defines **Office Locations** (Lat/Long + Radius).
3.  Admin creates **Teams** (e.g., "Engineering", "Marketing").
4.  Admin invites/creates users and assigns roles:
    *   *Assign User A as Lead of Team X.*
    *   *Assign User B as Member of Team X.*

#### B. Daily Attendance (Employee/Lead)
1.  User opens app. App requests **Location Permissions**.
2.  App checks if User is within `<Radius>` meters of any defined **Office Location**.
    *   *Success:* "Check In" button becomes active.
    *   *Failure:* "You are not at the office" message.
3.  User taps "Check In".
    *   App captures: `Timestamp`, `Live Coords`, `Device ID`.
    *   App sends to Backend.
4.  Backend validates Geo-fence server-side (prevent spoofing).
5.  User taps "Check Out" at end of day.

#### C. Monitoring (Team Lead)
1.  Lead navigates to "My Team".
2.  List view shows all members of their team.
3.  Status indicators: 🟢 Present, 🔴 Absent, 🟡 Late .
4.  Lead clicks a member to see monthly history.

---

## 3. System Architecture

### 3.1 High-Level Diagram
```mermaid
graph TD
    UserDevice[Flutter Mobile App]
    AdminDevice[Flutter Mobile App (Admin View)]
    
    API[Node.js REST API Layer]
    Auth[Auth Middleware (JWT)]
    GeoEngine[Geo-calculation Service]
    
    DB[(PostgreSQL Database)]
    MapService[Google Maps API / OpenStreetMap]

    UserDevice -->|HTTPS/JSON| API
    AdminDevice -->|HTTPS/JSON| API
    
    API --> Auth
    API --> GeoEngine
    API --> DB
    GeoEngine --> MapService
```

### 3.2 Technical Stack (Free-Tier Optimization)

| Component | Technology | Reasoning for "Free Production" |
| :--- | :--- | :--- |
| **Frontend** | **Flutter** (Dart) | Single codebase for Android/iOS. Native performance for maps. requested by client. |
| **Backend** | **Node.js** + **Express** + **TypeScript** | Lightweight, fast cold-starts on free hosting. TypeScript ensures maintainability. |
| **Database** | **PostgreSQL** (via **Supabase**) | Supabase provides a generous free tier (500MB storage), built-in backups, and is production-grade SQL. |
| **Hosting** | **Render.com** (Web Service) | Native Node.js support. Free tier allows 24/7 usage (with spin-down). |
| **Maps** | **Google Maps SDK** | $200 free monthly credit is sufficient for 50 users (approx 2000-3000 map loads/month). |
| **Auth** | **JWT (Custom)** or **Supabase Auth** | Custom JWT keeps control in Node. backend. Supabase Auth is easier but tightly coupled. We will use **Custom JWT** on Node for architectural independence. |

---

## 4. Database Schema (PostgreSQL)

We will use a relational model to strictly enforce hierarchy and referential integrity.

### 4.1 Users Table
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | UUID | PK |
| `mobile_number` | VARCHAR | Unique, Indexed (Login ID) |
| `password_hash` | VARCHAR | Bcrypt hash |
| `full_name` | VARCHAR | |
| `role` | ENUM | `'ADMIN'`, `'LEAD'`, `'EMPLOYEE'` |
| `team_id` | UUID | FK -> Teams.id (Nullable for Admins) |
| `created_at` | TIMESTAMP | |

### 4.2 Teams Table
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | UUID | PK |
| `name` | VARCHAR | e.g. "Backend Devs" |
| `lead_id` | UUID | FK -> Users.id (One Lead per team) |

### 4.3 Locations Table (Office Geofences)
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | UUID | PK |
| `name` | VARCHAR | e.g. "HQ - New York" |
| `latitude` | DECIMAL | |
| `longitude` | DECIMAL | |
| `radius_meters` | INT | Acceptance radius (e.g., 50m) |

### 4.4 Attendance Table
| Column | Type | Notes |
| :--- | :--- | :--- |
| `id` | UUID | PK |
| `user_id` | UUID | FK -> Users.id |
| `date` | DATE | Format YYYY-MM-DD (Indexed for queries) |
| `check_in_time` | TIMESTAMP | |
| `check_out_time` | TIMESTAMP | Nullable |
| `check_in_lat` | DECIMAL | Audit trail |
| `check_in_long` | DECIMAL | Audit trail |
| `status` | ENUM | `'PRESENT'`, `'LATE'`, `'HALF_DAY'` |

---

## 5. API Contracts (RESTful)

All endpoints require `Authorization: Bearer <token>` (except Auth).

### Auth
- `POST /api/auth/login` -> `{ mobile_number, password }` -> Returns `{ token, user }`
- `POST /api/auth/register` (Admin only) -> Create new employee.

### User & Team Management
- `GET /api/users` (Admin/Lead) -> List users.
- `GET /api/teams` -> List teams with Lead info.
- `PATCH /api/users/:id/assign-team` (Admin) -> `{ teamId, isLead }`

### Attendance
- `POST /api/attendance/check-in`
    - Body: `{ latitude, longitude }`
    - Logic: Server calculates distance between User and *All Active Locations*. If `distance < radius`, record Check-in. Else 400 Bad Request.
- `POST /api/attendance/check-out`
- `GET /api/attendance/self` -> Get my history.
- `GET /api/attendance/team/:teamId` (Lead/Admin) -> Get team history.

---

## 6. Security & Scalability

### 6.1 Security Model
1.  **Transport Security:** HTTPS (Enforced by Render/Supabase).
2.  **Authentication:** Stateless JWT with 7-day expiration (mobile-friendly).
3.  **Role-Based Access Control (RBAC):** Middleware to check permissions.
    *   `@Roles('ADMIN')` for structural changes.
    *   `@Roles('LEAD')` for viewing other's data.
4.  **Geo-spoofing Prevention:**
    *   **Server-Side Validation:** Never trust the client saying "I am at office". Client sends Lat/Long, Server computes distance.
    *   **Time Check:** Ensure server time is used for timestamps, not device time.

### 6.2 Scalability Strategy
*   **Database:** PostgreSQL can handle millions of rows. 50 users generating 2 rows/day is ~36k rows/year. Index on `user_id` and `date` ensures queries remain <10ms.
*   **Backend:** Node.js is event-driven and handles concurrent I/O well.
*   **Cost Control:** If users grow > 50, move media (profile pics) to Cloudinary (Free tier) or AWS S3.

---

## 7. Folder Structure (Monorepo Recommended)

We will use a clean separation of concerns.

```text
/root
  /mobile (Flutter)
    /lib
      /core
        /api           # HTTP client & Interceptors
        /auth          # Auth State Management
        /location      # Geo-services
      /models          # Data classes (User, Attendance)
      /features
        /login         # Login UI & Logic
        /dashboard     # Dashboard based on Role
        /attendance    # Check-in/out button & Logic
        /admin         # Admin management panels
  
  /backend (Node.js)
    /src
      /config        # Env vars, DB connection
      /controllers   # Request handlers
      /middlewares   # Auth, Validation, Role checks
      /models        # Sequelize/Prisma schemas
      /routes        # Express routes
      /services      # Business logic (Geo-calc, Attendance rules)
      /utils         # Helpers
```

---

## 8. Development Roadmap (Step-by-Step)

### Phase 1: Foundation (Days 1-2)
1.  Setup **Node.js + Express** project.
2.  Setup **Supabase PostgreSQL** database.
3.  Implement **User Registration/Login** API with JWT.
3.  Implement **User Registration/Login** API with JWT.
4.  Implement **Flutter App Architecture** with **Role-Based Routing Logic** (Switch screens based on JWT role).
5.  Create basic layouts for Admin, Lead, and Employee screens.

### Phase 2: Core Logic (Days 3-5)
1.  Define **Office Locations** in DB (manually via SQL or Postman).
2.  Implement **Geo-calculation Service** in Node.js (Haversine formula).
3.  Create `/check-in` endpoint with validation.
4.  Integrate **Geolocator** package in Flutter to fetch coords.
5.  Connect "Check In" button to Backend.

### Phase 3: Hierarchy & Dashboards (Days 6-8)
1.  Create Data Models for **Teams**.
2.  Build **Admin Dashboard** in App: List users, create teams.
3.  Build **Lead Dashboard**: View team attendance list.
4.  Build **Profile Page**: "My Team Lead is: [Name]".

### Phase 4: Polish & Deploy (Days 9-10)
1.  **Error Handling**: "Weak GPS signal", "No Internet", "Server Awake".
2.  **Deployment**:
    *   Backend -> Render.com (Connect GitHub repo).
    *   Database -> Supabase (Production mode).
3.  **APK Build**: `flutter build apk --release`.
4.  **Distribute**: Upload APK to Google Drive / GitHub Releases for employees.

---

## 9. Next Setup Steps for Authorization
To begin, the Admin must be seeded into the database manually or via a secret API key during the first deployment, as the app has no public "Sign Up" flow (private corporate app).

### Seed Command Example
```sql
INSERT INTO users (mobile_number, password_hash, role, full_name) 
VALUES ('+19876543210', '$2b$10$...', 'ADMIN', 'CEO Name');
```

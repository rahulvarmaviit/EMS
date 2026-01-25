# EMS - Geo-Attendance System

## Overview
A mobile-first attendance system for small startups (~50 users) that verifies employee physical presence via GPS geofencing and manages organizational hierarchy (CEO → Team Lead → Employee).

## Current State
- **Phase 1: Backend Foundation** - Complete
- **Phase 2: Flutter Mobile App** - Complete
- Backend API server running on port 5000
- PostgreSQL database with migrations
- JWT authentication implemented
- All REST APIs implemented
- Flutter mobile app ready for build

## Tech Stack
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL (Replit built-in)
- **Auth**: Custom JWT (7-day expiration)
- **Frontend**: Flutter (Dart)

## Project Structure
```
/backend                  # Node.js API server
  /src
    /config              # Database & environment config
    /controllers         # Request handlers
    /middlewares         # Auth, logging, validation
    /migrations          # SQL migration files
    /routes              # Express route definitions
    /services            # Business logic (geo-calculation)
    /utils               # Logger utility
    /scripts             # Admin seeding script
  package.json
  tsconfig.json

/mobile                  # Flutter app (pending)

/API_SPEC.md            # Complete API documentation
/PLAN_*.md              # Original technical blueprint
```

## How to Run

### Start Backend Server
```bash
cd backend && npm run dev
```

### Seed Admin User
```bash
cd backend && npx tsx src/scripts/seedAdmin.ts
```

### Default Admin Credentials
- Mobile: `+1234567890`
- Password: `admin123`

## API Endpoints
See `API_SPEC.md` for full documentation.

### Key Endpoints
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Register user (Admin only)
- `POST /api/attendance/check-in` - GPS-verified check-in
- `POST /api/attendance/check-out` - Check-out
- `GET /api/attendance/self` - View own history
- `GET /health` - Health check

## Database Tables
1. **users** - All system users
2. **teams** - Organizational units
3. **locations** - Office geofences
4. **attendance** - Daily attendance records

## User Preferences
- Follow PLAN.md exactly
- Production-quality code with comments
- Handle edge cases
- Add logging
- Step-by-step approval process

## Building the Mobile App

The Flutter mobile app is in the `/mobile` directory. To build:

1. Install Flutter on your computer: https://flutter.dev
2. Navigate to the mobile folder
3. Run `flutter pub get` to install dependencies
4. Update API URL in `lib/core/api/api_client.dart`
5. Run `flutter build apk --release` for Android APK

See `mobile/README.md` for detailed instructions.

## Recent Changes
- 2026-01-25: Phase 2 Flutter mobile app complete
- 2026-01-25: Phase 1 backend complete - all APIs implemented

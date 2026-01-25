# EMS Mobile App

Flutter mobile app for the Geo-Attendance System.

## Features

- **Login Screen**: Mobile number + password authentication
- **Employee Home**: Big check-in/check-out buttons with GPS verification
- **Lead Dashboard**: View team attendance with status indicators
- **Admin Dashboard**: Manage users, teams, and locations

## Prerequisites

- Flutter SDK 3.0+ installed on your computer
- Android Studio / Xcode for building
- Device or emulator

## Setup Instructions

### 1. Install Flutter
Download and install Flutter from: https://flutter.dev/docs/get-started/install

### 2. Clone and Setup
```bash
# Navigate to mobile directory
cd mobile

# Get dependencies
flutter pub get
```

### 3. Update API URL
Open `lib/core/api/api_client.dart` and update `baseUrl` to your backend URL:
```dart
static const String baseUrl = 'https://your-backend-url.com';
```

### 4. Run the App
```bash
# For development
flutter run

# For Android APK
flutter build apk --release

# For iOS
flutter build ios --release
```

## Project Structure

```
lib/
  core/
    api/           - HTTP client for backend API
    auth/          - Authentication state management
  models/          - Data classes (User, Attendance, Team)
  features/
    login/         - Login screen
    attendance/    - Check-in/out and history
    dashboard/     - Admin dashboard
    lead/          - Team lead dashboard
```

## Test Credentials

- **Admin**: +1234567890 / admin123
- **Employee**: +1987654321 / test123

## Permissions Required

- **Location**: For GPS-based check-in/check-out
- **Internet**: For API communication

## Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## iOS Permissions

Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location to verify office check-in</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location to verify office check-in</string>
```

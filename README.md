# Elimu Pepe

Flutter Android app for secure learner access to ebooks and learner dashboard resources.

## Current Status

The app is no longer in the default Flutter starter state.

Implemented:
- Student login with token-based authentication
- Session validation and auth-gated splash routing
- Learner categories with API-driven content lists
- In-app WebView SSO flow using `GET /api/student/webview-token`
- Cloud ebook listing/download from PHP backend
- Local offline ebook storage and reading

## Tech Stack

- Flutter 3 / Dart 3
- Dio for API communication
- Flutter Secure Storage for token storage
- Sqflite for local metadata storage
- Pdfx for PDF viewing
- WebView Flutter for in-app content launch

## API Integration

Main learner API base:
- `https://elimupepe.loholearning.co.ke/api`

Authentication:
- `POST /v1/auth/login`
- `GET /v1/auth/me`
- `GET /v1/auth/logout`

Learner endpoints used by categories:
- `GET /student/courses`
- `GET /student/books`
- `GET /student/elibrary`
- `GET /student/labs`
- `GET /student/quizzes`
- `GET /student/games`
- `GET /student/leaderboard`
- `GET /student/questions`

WebView SSO:
- `GET /student/webview-token`
- Returns `webview_login_url` that is loaded inside app WebView

Ebook cloud API base:
- `https://api-ebooks.loholearning.co.ke`

## Project Structure

- `lib/screens/` UI screens (login, home, categories, reader, webview)
- `lib/services/` auth, learner API, cloud sync, storage, database services
- `lib/models/` data models and menu model

## Run Locally

1. Install dependencies:

```bash
flutter pub get
```

2. Run on device/emulator:

```bash
flutter run
```

## Build APK

Release build:

```bash
flutter build apk --release
```

Output:
- `build/app/outputs/flutter-apk/app-release.apk`

## Access Model

Only users created in backend can access content.

Required:
- valid login credentials
- learner/student role assignment on backend
- successful token issuance from login API

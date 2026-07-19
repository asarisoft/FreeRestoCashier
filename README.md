# Resto Flow Free

> Free POS cashier app for restaurants and cafes. Track sales, manage products, print receipts via Bluetooth thermal printer.

## Features

- **POS Cashier** — realtime shopping cart, per-item & total discount, multiple payment methods
- **Products** — CRUD with categories, price, cost (HPP), ready status, and photos
- **Expenses** — track daily operational costs
- **Reports** — revenue, expenses, gross & net profit summaries by day/month
- **Receipt Printing** — Bluetooth thermal printer 58mm / 80mm (ESC/POS)
- **Multi-device** — Google sign-in, data stored in Cloud Firestore

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Auth | Firebase Auth + Google Sign-In |
| Database | Cloud Firestore |
| Storage | Firebase Storage (product photos) |
| Printer | ESC/POS via Bluetooth SPP |
| Font | Inter (Google Fonts) |

## Firebase Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Enable **Authentication → Sign-in method → Google**
3. Create a **Cloud Firestore** database (production mode)
4. Add an Android app → download `google-services.json` → place it in `android/app/`
5. Add **SHA-1 fingerprint** to your Firebase Android app:
   ```
   A7:80:DD:F6:F4:35:E6:77:98:E1:59:E2:CB:C8:28:B2:0D:25:BC:B5
   ```
6. Deploy Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{uid}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```

## Getting Started

```bash
# clone
git clone https://github.com/asarisoft/FreeRestoCashier.git
cd FreeRestoCashier

# install dependencies
flutter pub get

# generate app icon (optional)
dart run flutter_launcher_icons

# run
flutter run
```

> **Note**: Make sure `google-services.json` exists in `android/app/` before running the app.

## Build APK

```bash
flutter build apk --release
```

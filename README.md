# Resto Flow Free

> Aplikasi POS kasir gratis untuk restoran dan kafe. Catat penjualan, kelola produk, cetak struk via Bluetooth thermal printer.

## Fitur

- **Kasir (POS)** — keranjang belanja realtime, diskon per item & total, multi metode pembayaran
- **Produk** — CRUD produk dengan kategori, harga, HPP, status ready, dan foto
- **Pengeluaran** — catat biaya operasional harian
- **Laporan** — ringkasan omzet, pengeluaran, laba kotor & bersih per hari/bulan
- **Cetak Struk** — Bluetooth thermal printer 58mm / 80mm (ESC/POS)
- **Multi-perangkat** — login dengan Google, data tersimpan di Cloud Firestore

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Auth | Firebase Auth + Google Sign-In |
| Database | Cloud Firestore |
| Storage | Firebase Storage (foto produk) |
| Printer | ESC/POS via Bluetooth SPP |
| Font | Inter (Google Fonts) |

## Persiapan Firebase

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Aktifkan **Authentication → Sign-in method → Google**
3. Buat **Cloud Firestore** (mode production)
4. Tambah aplikasi Android → download `google-services.json` → taruh di `android/app/`
5. Tambah **SHA-1 fingerprint** ke Firebase Android app:
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

## Cara Jalankan

```bash
# clone
git clone https://github.com/asarisoft/FreeRestoCashier.git
cd FreeRestoCashier

# install dependencies
flutter pub get

# generate app icon (optional)
dart run flutter_launcher_icons

# jalankan
flutter run
```

> **Catatan**: Pastikan `google-services.json` sudah ada di `android/app/` sebelum menjalankan app.

## Build APK

```bash
flutter build apk --release
```

# Kasir Resto — Specification & Build Plan

> Aplikasi kasir resto sederhana: catat produk + HPP, status ready, transaksi penjualan, pengeluaran, laporan omzet, dan print struk via Bluetooth thermal printer. User download dari Play Store → Google login → langsung pakai (data scoped per akun di shared Firebase).

## 1. Tujuan & Scope

### 1.1 Goals
- Catat jenis produk & HPP-nya
- Tandai produk ready / tidak ready
- Catat penjualan (POS mini dengan keranjang)
- Catat pengeluaran operasional
- Laporan penghasilan (omzet), pengeluaran, laba kotor & bersih
- Print struk via Bluetooth thermal printer (58mm / 80mm, bisa dipilih)
- Setting nama resto + info struk (alamat, no telp, footer)

### 1.2 Non-Goals (tidak dikerjakan di MVP)
- Manajemen meja / table
- Promo & diskon kompleks (cuma ada diskon manual per item/total)
- Pelanggan/member
- Stok bahan baku & resep (HPP manual sudah cukup)
- Multi-user/cashier shift
- Back-office dashboard di web
- Sinkron ke Excel/Sheets otomatis

### 1.3 Success Criteria
- User baru bisa: login → isi nama resto → tambahkan produk → jualan → print struk → lihat laporan omzet, semua < 5 menit.
- Struk Bluetooth ter-print pada printer thermal umum di pasaran.
- Data per resto terpisah & aman (lihat §6 Firestore rules).

---

## 2. Persona & Flow Utama

### 2.1 User
- Pemilik resto/warung Indonesia
- Punya thermal printer Bluetooth 58mm/80mm
- Teknologi dasar (HP Android)

### 2.2 Happy Path
1. Buka app → Google Login
2. Onboarding 1x: isi nama resto (untuk header struk), pilih ukuran kertas printer
3. Dashboard → tambah produk (nama, harga jual, HPP, ready toggle)
4. Buka Kasir → tambah produk ke keranjang → "Bayar" → pilih metode → simpan → print struk
5. Buka Laporan → lihat omzet hari ini / bulan → lihat pengeluaran → laba
6. Tambah pengeluaran kapan saja (misal: beli gas, bayar listrik)
7. Settings: ubah nama resto, info struk, pairing printer, ukuran kertas, logout

---

## 3. Tech Stack

| Layer | Choice | Alasan |
|---|---|---|
| UI | Flutter (Material 3) | cross-platform, sudah ada project |
| Auth | Firebase Auth + google_sign_in | login cepat, data otomatis scoped by uid |
| DB | Cloud Firestore | real-time, free tier cukup |
| Storage | (opsional) Firebase Storage untuk foto produk di tahap 2 | MVP nggak pakai foto |
| Print | `esc_pos_utils` + `flutter_blue_plus` atau `bluetooth_print` | thermal printer ESC/POS standar via BLE/SPP |
| State | `flutter_riverpod` (atau `provider` sederhana) | minimal, ringan |
| Routing | `go_router` | deklaratif, simple |
| Laporan | Firestore query + agregasi lokal | MVP cukup, tahap 2 bisa Cloud Function |

### Alternatif pertimbangan
- `bluetooth_print` package sudah include ESC/POS wrapper & BLE discovery — lebih cepat dipakai daripada raw `flutter_blue_plus`. **Dipilih: `bluetooth_print`** (BLE thermal printer).

---

## 4. Arsitektur Aplikasi

```
lib/
├── main.dart
├── core/
│   ├── theme/            # warna, typography
│   ├── router.dart       # go_router
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── auth_service.dart
│   │   └── printer_service.dart
│   └── utils/
│       ├── money.dart   # format Rp
│       └── date.dart
├── features/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── auth_controller.dart
│   ├── onboarding/
│   │   └── onboarding_page.dart
│   ├── home/
│   │   └── home_shell.dart   # bottom nav
│   ├── products/
│   │   ├── product_list_page.dart
│   │   ├── product_form_page.dart
│   │   └── product_repository.dart
│   ├── pos/
│   │   ├── pos_page.dart
│   │   ├── cart_controller.dart
│   │   ├── checkout_page.dart
│   │   └── transaction_repository.dart
│   ├── expenses/
│   │   ├── expense_list_page.dart
│   │   ├── expense_form_page.dart
│   │   └── expense_repository.dart
│   ├── reports/
│   │   ├── report_page.dart
│   │   └── report_repository.dart
│   └── settings/
│       ├── settings_page.dart
│       └── printer_pairing_page.dart
└── models/
    ├── product.dart
    ├── transaction.dart
    ├── transaction_item.dart
    ├── expense.dart
    └── resto_profile.dart
```

State management pakai **Riverpod** (provider `@riverpod` annotation dengan riverpod_generator) supaya scalable & testable.

---

## 5. Data Model (Firestore)

Root path per resto = `users/{uid}/...` untuk isolate data per pemilik.

### 5.1 `users/{uid}/profile/resto`
```json
{
  "name": "Warung Mami",
  "address": "Jl. Mawar No. 1",
  "phone": "0812xxxx",
  "footerNote": "Terima kasih",
  "paperWidth": 58,           // 58 | 80
  "currency": "IDR",
  "createdAt": "timestamp"
}
```

### 5.2 `users/{uid}/products/{productId}`
```json
{
  "name": "Nasi Goreng",
  "category": "Makanan",      // opsional, tipe string bebas
  "price": 18000,
  "hpp": 9000,
  "ready": true,              // false jika habis
  "archived": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 5.3 `users/{uid}/transactions/{txnId}`
```json
{
  "number": 12,                          // running no per resto
  "items": [
    {"productId":"p1","name":"Nasi Goreng","price":18000,"hpp":9000,"qty":2,"subtotal":36000}
  ],
  "subtotal": 36000,
  "discount": 0,
  "total": 36000,
  "paid": 36000,
  "change": 0,
  "paymentMethod": "cash",               // cash | qris | card
  "profit": 18000,                       // sum(subtotal - hpp*qty)
  "printedAt": null | "timestamp",
  "createdAt": "timestamp"
}
```
→ Index: `createdAt` (sort), `number` unique increment.

### 5.4 `users/{uid}/expenses/{expenseId}`
```json
{
  "category": "Operasional",     // bebas: Belanja Bahan, Gas, Listrik, Gaji
  "note": "Beli gas 3kg",
  "amount": 21000,
  "date": "timestamp",
  "createdAt": "timestamp"
}
```

### 5.5 `users/{uid}/counters/transactions`
```json
{ "value": 12 }  // running number untuk struk
```
Increment aman pakai `FieldValue.increment(1)` + transaction.

---

## 6. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }

    match /users/{uid}/{document=**} {
      allow read, write: if isSignedIn() && request.auth.uid == uid;
    }
  }
}
```
Semua data per-uid hanya bisa diakses oleh pemilik. Struktur flat sederhana dan aman.

---

## 6.5 Design System

Prinsip: **flat, clean, profesional. Simple animation, minim shadow.**

### Tema
- **Light theme only** — tidak ada dark mode di MVP. Simplifikasi QA & ukuran bundle.
- Background: `#FAFAFA` (off-white) supaya nggak silau vs pure white.
- Surface/Card: `#FFFFFF` dengan border tipis `#EFEFEF`, **tanpa shadow** kecuali FAB & bottom bar (shadow halus).
- Primary: `#1F6FEB` (biru modem, jelas terbaca di struk & tombol).
- OnPrimary: putih.
- Success/Ready: `#16A34A`; Warning/NotReady: `#DC2626`.
- Text primary `#0F172A`, secondary `#64748B`.

### Typography
- Font: **Inter** (Google Fonts) — bersih, modern, profesional, nyaman dibaca.
-重量: Regular 400 (body), Medium 500 (subtitle/button), SemiBold 600 (title), Bold 700 (number & total).
- Scale (Material 3 adaptif):
  - `displayMedium` 28/36 — angka total struk
  - `titleLarge` 20/28 — title halaman
  - `titleMedium` 16/24 — card title
  - `bodyLarge` 16/24 — list item
  - `bodyMedium` 14/20 — secondary
  - `labelLarge` 14/20 — button
- Number/uang: `FontFeature.tabularFigures()` supaya align rapi.

### Shape & Spacing
- Card radius: 12. Button radius: 10.
- Spacing scale: 4/8/12/16/24/32.
- Padding default: 16dp.
- Divider rambut: `color: #EFEFEF, height: 1`.

### Shadow
- **Default: tanpa shadow.** Card pakai border 1px `#EFEFEF`.
- Hanya `FloatingActionButton`, `BottomAppBar`, dan dialog yang boleh shadow halus (`elevation: 1-2`).

### Animation
- **Simple & purpose-driven**, bukan dekorasi.
- Transisi antar halaman: default `MaterialPageRoute` 300ms.
- Tap feedback: `InkWell` splash bawaan.
- ListTile/Switch: bawaan.
- Cart badge count: `AnimatedSwitcher` fade (200ms) saat angka berubah.
- Bottom sheet slide: bawaan.
- Total di cart: `AnimatedDefaultTextStyle` 200ms saat subtotal update.
- Hindari `Hero` & animasi kompleks di MVP.

### Komponen reusable (`core/widgets/`)
- `AppCard` — container datar dengan border + radius 12.
- `PrimaryButton`, `SecondaryButton` — flat, border 1.5dp saat secondary.
- `AmountText` — format rupiah + tabular figures.
- `ReadyChip` — chip kecil hijau "Ready" / merah "Habis".
- `EmptyState` — ilustrasi teks simple (`Icons.*` + judul + subtitle).

### Ikon
- Material Symbols (sudah bundled Flutter).
- Konsisten: login `Icons.login`, kasir `Icons.pointOfSale`, produk `Icons.inventory_2`, laporan `Icons.bar_chart`, pengeluaran `Icons.receipt_long`, setting `Icons.settings`, printer `Icons.print`.

## 7. UI/UX Spec

### 7.0 Target Device & Responsive Strategy

**Target: Mobile + Tablet, responsive.** Tidak lock orientation — ikuti device.

Prinsip:
- **Mobile-first**: semua page dibuat untuk portrait ~360-428dp dulu, pastikan jalan & rapi.
- **Tablet-wide (>=600dp)**: page dengan banyak info otomatis switch ke layout multi-kolom / lebih lega via `LayoutBuilder`.
- Komponen padding/grid menggunakan `MediaQuery` & breakpoint konstan di `core/breakpoints.dart`.

| Breakpoint | Width | Pola layout |
|---|---|---|
| `compact` | < 600dp (HP portrait) | 1 kolom, bottom cart sheet |
| `wide` | >= 600dp (tablet / HP landscape) | 2 kolom / side panel untuk POS, grid produk 4+ kolom |

Implementasi:
- `responsive.dart` helper: `Responsive.isWide(context)`.
- Grid produk: `GridLayout` dengan `crossAxisCount` dinamis berdasarkan lebar.
- POS page mengikuti pola di §7.4.
- Orientation bebas; tidak ada `SystemChrome.setPreferredOrientations` global.
- HanyaHindari overflow dengan `SingleChildScrollView` & `Expanded` di region scroll.

### 7.1 Bottom Navigation (Home Shell)
Tabs: `Kasir` · `Produk` · `Laporan` · `Pengeluaran` · `Setting`
- 5 item bottom nav di `compact`. Di `wide` bisa diganti `NavigationRail` kiri (memberi layar utama lebih lebar). Auto-switch via `LayoutBuilder`.

### 7.2 Login Page
- Logo app + tombol besar "Masuk dengan Google"
- Latar gradient sederhana
- Tengah-tengah, regardless lebar.

### 7.3 Onboarding (sekali)
- Form: nama resto, alamat, no telp, footer note
- Pilih ukuran kertas printer (58 / 80)
- Tombol "Mulai"
- Di `wide`: form dibatasi max-width 520dp supaya tidak melebar absurd.

### 7.4 Kasir (POS) Page (paling responsive-critical)

**Compact (HP portrait, < 600dp):**
- Atas: filter kategori + toggle "Ready only"
- Grid produk 2 kolom, scrollable
- Bawah: **bottom bar cart** height ~72dp (icon cart + jumlah item + total + tombol "Bayar")
- Tap bottom bar → buka **bottom sheet** list item + qty +/- + subtotal per item
- Tombol "Bayar" di sheet → checkout dialog

**Wide (>= 600dp, tablet atau HP landscape):**
- 2 kolom:
  - **Kiri (flex 2)**: filter + grid produk (4-5 kolom tergantung lebar)
  - **Kanan (flex 1, fixed width 320-380dp)**: list cart item dengan qty, subtotal, diskon per item
- Atas kanan: total + tombol "Bayar"
- Tidak perlu bottom sheet karena cart selalu visible

**Per item di cart:**
- Tap item di grid → tambah 1 ke cart (atau increment kalau sudah ada)
- Tap item di cart → bottom sheet edit qty, diskon per item (Rp), hapus
- Atau long-press grid item untuk add dengan qty cepat

Layout component:
```
LayoutBuilder(
  builder: (ctx, constraints) {
    final isWide = constraints.maxWidth >= 600;
    return isWide ? _wideLayout() : _compactLayout();
  }
)
```

### 7.5 Produk Page
- List produk (search + filter ready)
- `compact`: ListView 1 kolom
- `wide`: GridView 3-4 kolom卡片 atau 2 kolom list (kolom kiri untuk list, kolom kanan untuk detail/preview saat tap) — MVP: cukup GridView, tap → form full page
- Swipe/edit/hapus item via `Dismissible` atau long-press menu
- Toggle ready cepat via Switch di card
- FAB "+" tambah produk: nama, kategori, harga, HPP, ready
- Form full-page di `compact`, dialog/panel kanan di `wide`

### 7.6 Pengeluaran Page
- List item (tanggal, kategori, note, nominal)
- FAB tambah
- Filter bulan
- `compact`: ListView; `wide`: GridView 2-3 kolom kartu

### 7.7 Laporan Page
- Tab/segmented control: Hari ini / Bulan ini / Custom range
- Cards: Omzet, Pengeluaran, Laba Bersih, Margin %
- Breakdown: laba kotor (sum profit), transaksi count, rata-rata per struk
- List transaksi terbaru (tap → reprint struk)
- `compact`: card 1 kolom + list vertikal
- `wide`: cards horizontal 2x2 grid + list di bawah; atau card + list side-by-side dengan scroll sendiri
- Grafik tahap 2

### 7.8 Settings Page
- Edit profil resto (nama, alamat, telp, footer, toggle logo, upload logo)
- Printer pairing → buka `PrinterPairingPage` (scan BLE, connect test print)
- Ukuran kertas (58/80)
- Logout
- About / versi
- `compact`: ListView grup; `wide`: 2 kolom (grup kiri | grup kanan) atau master-detail layout.

### 7.9 Printer Pairing Page
- Scan perangkat BLE thermal
- Pilih device → connect
- Tombol "Test Print" (cetak kalibrasi)
- Simpan device id di local storage (`shared_preferences`).
- Sama untuk compact & wide; dialog full-screen di HP, dialog rapi di tablet.

---

## 8. Print Struk Spec (ESC/POS)

- Wrapper service `PrinterService` pakai package `bluetooth_print`
- Layout (header -> items -> total -> footer) menyesuaikan `paperWidth`:
  - 58mm → 32 char / line
  - 80mm → 48 char / line
- Contoh:
```
      WARUNG MAMI
   Jl. Mawar No. 1
   Telp 0812xxxx
--------------------------------
No: #12   19/07/26 14:23
--------------------------------
Nasi Goreng  2  x18.000  36.000
Es Teh       1  x5.000   5.000
--------------------------------
Subtotal               41.000
Diskon                      0
Total                  41.000
Tunai                  50.000
Kembali                 9.000
--------------------------------
    Terima kasih
```
- Format uang: `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')`
- Fitur: reprint struk dari laporan
- Handling error: timeout, device disconnect → toast dengan opsi retry

---

## 9. Flow Cross-Cutting

### 9.1 Auth State
- `AuthController` listen ke `FirebaseAuth.instance.authStateChanges()`
- Belum login → `/login`
- Login tapi belum onboarding (profile belum ada) → `/onboarding`
- Lainnya → `/home`

### 9.2 Cart State
- Riverpod `cartItemsProvider` (List<TransactionItem>)
- Direset setelah transaction saved
- Nggak persist (cukup in-memory) di MVP

### 9.3 Offline
- Firestore **cache persistence on by default** di mobile → user tetap bisa lihat data, write akan queue saat online
- Print Bluetooth tetap bisa offline (lokal)
- Login tetap butuh online (Google sign-in)

---

## 10. Build Tasks (Urutan Pengerjaan)

### Phase 0 — Project bootstrap
- [ ] Tambah dependencies di `pubspec.yaml`:
  `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`,
  `go_router`, `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`,
  `bluetooth_print`, `intl`, `shared_preferences`
- [ ] Konfigurasi Firebase project (user lakukan di console + taruh config file)
- [ ] Aktifkan Google Sign-In provider + isi SHA-Android/iOS bundle

### Phase 1 — Core & auth
- [ ] `firebase_service.dart`, `auth_service.dart` (Google Sign-In)
- [ ] Router dengan redirect berbasis state auth + onboarding
- [ ] Login page UI

### Phase 2 — Profil resto + onboarding
- [ ] Model `RestoProfile`
- [ ] Onboarding page + simpan ke Firestore
- [ ] Settings page → edit profil + ukuran kertas

### Phase 3 — Produk
- [ ] Model `Product`, repository CRUD
- [ ] List page (search, filter ready, toggle ready)
- [ ] Form page (nama, kategori, harga, HPP, ready)

### Phase 4 — POS / Transaksi
- [ ] Cart controller
- [ ] POS page: grid produk + cart
- [ ] Checkout dialog: uang dibayar, metode, diskon, change
- [ ] `TransactionRepository.save()` pakai counter `FieldValue.increment`
- [ ] Simpan transaksi + clear cart

### Phase 5 — Print
- [ ] `PrinterService` bluetooth_print wrapper
- [ ] Pairing page (scan + connect + test print)
- [ ] Build ESC/POS bytes dari `Transaction`
- [ ] Print otomatis setelah checkout + reprint dari laporan

### Phase 6 — Pengeluaran
- [ ] `Expense` model + repository
- [ ] List + form page

### Phase 7 — Laporan
- [ ] Report repository: query transactions & expenses by date
- [ ] Report page: card ringkasan + list transaksi (reprint)

### Phase 8 — Polish
- [ ] Linter和分析
- [ ] Icon launcher, app name "Kasir Resto"
- [ ] Empty states, error handling
- [ ] SharedPreferences cache (device printer, preferensi)
- [ ] Build APK release untuk uji di device nyata

---

## 11. Risiko & Mitigasi

| Risiko | Mitigasi |
|---|---|
| Printer BLE nggak kompatibel | pakai package `bluetooth_print` yang sudah uji thd printer umum; sediakan error toast jelas |
| Counter race condition | pakai `FieldValue.increment(1)` dalam transaction |
| Free tier quota Firestore | MVP data kecil, 写入 per transaksi < 10 dokumen, OK |
| Akun Google user di-revoke | instruksi re-login; data tetap aman di uid |
| Cost build APK di shared Firebase | ongkos per user sangat kecil; monitor quota |

---

## 12. Keputusan Fitur (Final Answers)

| # | Pertanyaan | Jawaban | Implikasi Teknis |
|---|---|---|---|
| 1 | Multi-kasir? | **1 akun = pemilik + kasir** | Tidak perlu collection `members` atau role permission. Semua resource ada di `users/{uid}/...` milik pemilik. |
| 2 | Export laporan? | **Tidak, lihat di app saja** | Tidak perlu package PDF/Excel generator. Halaman laporan cukup tampilkan card + list. Reprint struk tetap ada. |
| 3 | Logo di struk? | **Optional, toggle di setting** | Field `profile.useLogo` boolean + `profile.logoUrl` (Firebase Storage). Saat `useLogo=true` & `logoUrl` ada, header struk load & raster logo jadi ESC/POS image. Kalau off → nama tebal saja. |
| 4 | Diskon? | **Diskon total + per item** | `TransactionItem` tambah field `discount` (rupiah) per item. Checkout tambah field `discount` (rupiah/percent) untuk total. Perhitungan: `item.subtotal = (price - itemDiscount) * qty`; `total = sum(item.subtotal) - txnDiscount`. |
| 5 | Pajak/service charge? | **Tidak** | Tidak ada field `tax`/`serviceCharge`. Total = subtotal - diskon saja. Tetap fleksibel kalau nanti mau ditambah (tertulis di section 13). |

### 12.1 Data Model Update (karena jawaban #3 & #4)

`TransactionItem`:
```json
{
  "productId": "p1",
  "name": "Nasi Goreng",
  "price": 18000,
  "hpp": 9000,
  "qty": 2,
  "discount": 0,        // rupiah per item (default 0)
  "subtotal": 36000     // (price - discount) * qty
}
```

`Transaction` (tambahan field `discount`):
```json
{
  "items": [...],
  "subtotal": 36000,
  "discount": 2000,      // rupiah (default 0)
  "total": 34000,
  "paid": 50000,
  "change": 16000,
  "paymentMethod": "cash",
  "profit": 18000,       // sum((price - itemDiscount - hpp) * qty) - txnDiscount
  "printedAt": null,
  "createdAt": "timestamp"
}
```

`RestoProfile` (tambahan field logo):
```json
{
  "name": "Warung Mami",
  "address": "Jl. Mawar No. 1",
  "phone": "0812xxxx",
  "footerNote": "Terima kasih",
  "paperWidth": 58,
  "currency": "IDR",
  "useLogo": false,
  "logoUrl": null,
  "createdAt": "timestamp"
}
```

### 12.2 Build Tasks Tambahan

- [ ] Upload logo di Settings → simpan ke Firebase Storage path `users/{uid}/logo.png` → tulis `profile.logoUrl` & set `useLogo=true`.
- [ ] Toggle "Tampilkan logo di struk" di Settings → update `profile.useLogo`.
- [ ] Print service: jika `useLogo=true`, ambil bytes logo (cache lokal), raster pakai `esc_pos_utils` `Image.decodePng` → sisipkan di atas nama resto.
- [ ] Cart UI: tap item → bottom sheet dengan qty & "Diskon item (Rp)" input.
- [ ] Checkout dialog: tambah "Diskon total (Rp)" input sebelum "Total".

### 12.3 Catatan "diskon per item"

Per item dipakai untuk kasus seperti: item "Nasi Goreng" dikasih diskon Rp 2.000 karena promo. Bukan untuk model "% per item" — supaya tetap simple & kalkulasi integer yang jelas. Kalau nanti butuh diskon % bisa diberi opsi tipe `discountType: "rupiah" | "percent"`. MVP tetap rupiah saja biar tidak ambigu.

### 12.4 Yang Tetap Tidak Ada di MVP

- Multi-user / role permission
- Export PDF/Excel
- Pajak/service charge
- Manajemen meja
- Stok & resep bahan baku
- Pelanggan/member
- Grafik/laporan visual

(Tercantum kembali di section 1.2 Non-Goals.)

---

## 13. Konfigurasi Firebase yang Perlu Disiapkan User

Sebelum Phase 1 bisa jalan end-to-end, user harus:
1. Buat project di https://console.firebase.google.com
2. Aktifkan **Authentication → Sign-in method → Google** (tambah support email)
3. Buat **Cloud Firestore** (mode production — rules lihat §6)
4. Tambah aplikasi Android → download `google-services.json` → taruh di `android/app/`
5. Tambah aplikasi iOS (opsional untuk MVP Android-first) → `GoogleService-Info.plist` ke `ios/Runner/`
6. Isi SHA-1/SHA-256 dari debug keystore (`./gradlew signingReport`) ke Firebase Android app
7. Konfigurasi OAuth consent screen di Google Cloud (atau cukup via Firebase default)

Setelah config file tersedia & kode selesai, app bisa langsung dijalankan `flutter run`.
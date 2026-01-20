# Dokumentasi Teknis Aplikasi Toko Kayu (Kayu Adi)

Aplikasi ini adalah sistem E-Commerce lengkap (Frontend Flutter & Backend Node.js) untuk penjualan kayu, yang mencakup fitur manajemen stok, penjualan, pembayaran online, dan pengiriman.

## 📁 Struktur Proyek
- **Backend**: Node.js, Express, Knex.js (Database CRUD), PostgreSQL (via Supabase).
- **Frontend**: Flutter (Mobile/Web), Provider (State Management), Dio (HTTP).

---

## 🛠️ Prasyarat (Third-Party Services)
Sebelum menjalankan aplikasi, pastikan Anda memiliki akun dan kredensial untuk layanan berikut:
1. **Supabase**: Untuk Database PostgreSQL dan Image Storage.
2. **RajaOngkir (Pro/Starter)**: Untuk get data kota, kecamatan, kelurahan di jawa timur.
3. **Midtrans (Sandbox/Production)**: Untuk gateway pembayaran digital.

---

## 🚀 Instalasi Backend

### 1. Install Dependensi
Masuk ke folder backend dan install library yang dibutuhkan:
```bash
cd backend
npm install
```

### 2. Konfigurasi Environment Variable (`.env`)
Buat atau edit file `.env` di dalam folder `backend/`. Isikan konfigurasi berikut:

```env
# Server Config
PORT=3000
NODE_ENV=development

# Supabase (Database & Storage)
# Dapatkan di: Project Settings -> API
SUPABASE_URL=https://[YOUR_PROJECT_ID].supabase.co
SUPABASE_KEY=[YOUR_ANON_KEY]
SUPABASE_SERVICE_KEY=[YOUR_SERVICE_ROLE_KEY]

# Database Connection (PostgreSQL)
# Gunakan mode 'Session' (port 5432) atau 'Transaction' (port 6543)
DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?sslmode=require

# JWT Authentication Config
JWT_ACCESS_SECRET=kunci_rahasia_untuk_access_token_min_32_karakter
JWT_REFRESH_SECRET=kunci_rahasia_untuk_refresh_token_beda_dengan_atas
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Midtrans Payment Gateway
MIDTRANS_SERVER_KEY=[Dapatkan dari Dashboard Midtrans]
MIDTRANS_CLIENT_KEY=[Dapatkan dari Dashboard Midtrans]
MIDTRANS_IS_PRODUCTION=false

# RajaOngkir API (Pengiriman)
RAJAONGKIR_API_KEY=[Dapatkan dari Dashboard RajaOngkir]

# Admin Seeder (Akun admin pertama kali)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
ADMIN_NAMA=Super Admin
```

### 3. Setup Database (Migrasi & Seeding)
Gunakan **Knex.js** untuk membuat tabel dan mengisi data awal.

```bash
# Membuat semua tabel (users, produk, orders, dll)
npm run migrate

# Mengisi data awal (membuat akun admin default & data master)
npm run seed
```

### 4. Menjalankan Server
Gunakan `nodemon` untuk development agar auto-restart saat ada perubahan file:
```bash
nodemon server.js
```

---

## 📱 Instalasi Frontend (Flutter)

### 1. Install Dependensi
Masuk ke folder frontend dan ambil paket Dart:
```bash
cd frontend
flutter pub get
```

### 2. Konfigurasi Integrasi (`app_config.dart`)
Flutter membutuhkan akses langsung ke Supabase untuk fitur **Realtime**.

Buka file `lib/config/app_config.dart` dan sesuaikan:
```dart
class AppConfig {
  static const String supabaseUrl = 'https://[YOUR_PROJECT_ID].supabase.co';
  static const String supabaseAnonKey = '[YOUR_ANON_KEY]';
  
  // URL Backend (Ganti dengan IP Local komputer Anda jika debugging di HP fisik)
  // Untuk Emulator Android gunakan: 10.0.2.2:3000
  // Untuk Web/iOS Simulator: localhost:3000
  static const String baseUrl = 'http://localhost:3000/api'; 
}
```

### 3. Menjalankan Aplikasi
```bash
# Untuk Web
flutter run -d chrome

# Untuk Android/iOS
flutter run
```

---

## 🔐 Sistem Keamanan & Autentikasi

### 1. Enkripsi Password
Password pengguna **TIDAK** disimpan dalam bentuk teks biasa (plain text).
- Menggunakan library **Bcrypt**.
- Password di-hash sebelum disimpan ke database.
- Saat login, password input user di-compare dengan hash di database.

### 2. JWT (JSON Web Token) strategy
Sistem menggunakan mekanisme **Dual Token** untuk keamanan maksimal:
1.  **Access Token (Pendek, misal 15 menit)**:
    - Digunakan untuk otorisasi setiap request API.
    - Disimpan di memori aplikasi (hilang saat restart) atau secure storage.
2.  **Refresh Token (Panjang, misal 7 hari)**:
    - Digunakan HANYA untuk meminta Access Token baru.
    - Disimpan di database untuk validasi (bisa di-revoke paksa jika akun dicuri).

### 3. Refresh Token Otomatis (Interceptor)
Frontend tidak perlu logout user saat Access Token kadaluwarsa.
- **Dio Interceptor** di `api_service.dart` memantau setiap respon error `401 Unauthorized`.
- Jika `401` terdeteksi, aplikasi secara diam-diam (background) mengirim request ke `/auth/refresh` mengirim Refresh Token.
- Jika berhasil dapat token baru, aplikasi **mengulang kembali** request user yang gagal tadi.
- User merasakan pengalaman yang *seamless* (tidak tiba-tiba logout).

---

## ☁️ Integrasi Fitur Khusus

### 1. Upload Gambar (Supabase Storage)
Gambar produk tidak disimpan sebagai BLOB di database (berat), tapi di Object Storage.
- **Frontend** mengirim file gambar sebagai `Multipart/Form-Data` ke Backend.
- **Backend**:
    1. Menerima buffer file.
    2. Upload file ke Supabase Storage (Bucket: `produk-images`).
    3. Mendapatkan Public URL dari Supabase.
    4. Menyimpan string URL tersebut (contoh: `https://xyz.supabase.co/.../gambar.jpg`) ke kolom `gambar_url` di tabel database `produk`.

### 2. Midtrans (Pembayaran) & RajaOngkir (Pengiriman)
Menggunakan pendekatan **Backend-Centric** demi keamanan:
- **API Key Disembunyikan**: API Key RajaOngkir dan Server Key Midtrans hanya ada di serve (`.env`). Frontend tidak pernah menyimpannya.
- **Alur Midtrans**:
    1. Frontend minta "Buat Transaksi" ke Backend.
    2. Backend bicara ke Midtrans -> dapat `redirect_url`.
    3. Backend kasih URL ke Frontend.
    4. Frontend buka URL itu di WebView/Browser.
    5. Setelah bayar, Midtrans mengirim **Webhook** ke Backend untuk update status otomatis (Pending -> Dibayar/Expired).

### 3. Supabase Realtime
Data (Stok, Order Baru, Notifikasi) tersinkronisasi tanpa refresh manual.
- **Frontend** menggunakan library `supabase_flutter`.
- Aplikasi "mendengarkan" (subscribe) perubahan pada tabel tertentu.
- Saat Backend mengupdate database (via API), Supabase otomatis menyiarkan sinyal ke semua frontend yang sedang connect.
- **PENTING**: Anda harus mengaktifkan Realtime secara manual di Supabase Dashboard:
    1. Menu **Database** -> **Replication**.
    2. Klik **Source**.
    3. Toggle **ON** untuk tabel: `orders`, `produk`, `notifikasi`.

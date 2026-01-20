# Panduan Migrasi ke Project Supabase Baru

Jika Anda membuat project Supabase baru, ikuti langkah-langkah berikut agar aplikasi Kayu Adi berjalan normal.

## 1. Setup Project di Dashboard Supabase
1. Buat **New Project** di Supabase.
2. Simpan **Database Password** Anda (jangan sampai hilang!).
3. Tunggu hingga project selesai dibuat.

## 2. Ambil Kredensial (Credentials)
Masuk ke **Project Settings -> API**:
- Salin `URL` (Project URL).
- Salin `anon` Key (Public).
- Salin `service_role` Key (Secret).

Masuk ke **Project Settings -> Database -> Connection String**:
- Pilih tab **Node.js**.
- Salin connection string. Formatnya mirip: `postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?sslmode=require`.
- **PENTING**: Ganti `[password]` dengan password database yang Anda buat di langkah 1.

## 3. Update Backend (.env)
Buka file `d:\Toko Kayu\backend\.env` dan update bagian ini:

```env
# Supabase API
SUPABASE_URL=https://[PROJECT-ID].supabase.co
SUPABASE_KEY=[ANON_KEY_BARU]
SUPABASE_SERVICE_KEY=[SERVICE_ROLE_KEY_BARU]

# Database Connection
# Gunakan port 6543 (Transaction Pooler) atau 5432 (Session)
# Pastikan password sudah dimasukkan ke URL ini
DATABASE_URL=postgresql://postgres.[REF]:[PASSWORD]@aws...pooler.supabase.com:6543/postgres
```

## 4. Isi Database (Migrasi & Seed)
Backend memiliki script otomatis untuk membuat tabel. Buka terminal di folder `backend`, lalu jalankan:

```bash
# Hapus tabel lama (opsional, tapi project baru pasti kosong) dan buat baru
npm run migrate:rollback   # Jika perlu reset
npm run migrate            # Membuat semua tabel

# Buat user admin default (username: admin, pass: admin123)
npm run seed
```

## 5. Setup Realtime (WAJIB MANUAL)
Supabase mematikan realtime secara default. Anda harus mengaktifkannya agar fitur update otomatis berjalan.

1. Di Dashboard Supabase, buka menu **Database** -> **Replication**.
2. Klik tombol **Source** (0 tables).
3. Anda akan melihat daftar tabel. **Aktifkan (Toggle ON)** untuk tabel berikut:
   - `orders`
   - `produk`
   - `notifikasi`
   - `chat_messages` (jika ada fitur chat)

## 6. Update Frontend
Buka file `d:\Toko Kayu\frontend\lib\config\app_config.dart`.

Update variabel ini dengan kredensial baru:
```dart
static const String supabaseUrl = 'https://[PROJECT-ID].supabase.co';
static const String supabaseAnonKey = '[ANON_KEY_BARU]';
```

## 7. Restart Aplikasi
1. **Backend**: Matikan server (`Ctrl+C`) lalu jalankan lagi: `nodemon server.js`.
2. **Frontend**: Matikan aplikasi Flutter (`q` di terminal) lalu jalankan lagi dengan Hot Restart atau `flutter run`.

## Selesai!
Aplikasi Anda sekarang terhubung ke database baru dengan fitur lengkap.

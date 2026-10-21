# Rencana Pengembangan Aplikasi AyoHemat (Catat Keuangan)

Dokumen ini berisi rencana kerja dan spesifikasi teknis untuk pengembangan fitur baru pada aplikasi AyoHemat.

---

## 🎯 Tujuan Pengembangan

Meningkatkan kenyamanan pengguna (*user experience*) dalam meninjau ringkasan keuangan, memfilter data per periode bulanan, mengakses halaman rincian langsung dari dashboard, mempermudah pencatatan transaksi langsung dari tanggal di kalender, memperkuat identitas branding visual pada header dashboard, serta memberikan kemudahan penginputan nominal dengan pemisah ribuan otomatis.

---

## 📋 Daftar Kebutuhan Fitur (Scope)

1. **Card Total Pemasukan di Halaman Detail Pemasukan** *(Selesai)*
   - Menampilkan card ringkasan total pemasukan di bagian atas halaman pemasukan dengan desain yang konsisten dengan Dashboard (`_SummaryCard`).
   - Nominal total otomatis menyesuaikan dengan bulan yang sedang aktif difilter.

2. **Card Total Pengeluaran di Halaman Detail Pengeluaran** *(Selesai)*
   - Menampilkan card ringkasan total pengeluaran di bagian atas halaman pengeluaran dengan desain yang konsisten dengan Dashboard (`_SummaryCard`).
   - Nominal total otomatis menyesuaikan dengan bulan yang sedang aktif difilter.

3. **Filter Perbulan di Halaman Detail Pengeluaran** *(Selesai)*
   - Kontrol navigasi bulan berupa `< Bulan Tahun >` (contoh: `‹ Oktober 2026 ›`).
   - Tombol panah kiri untuk mundur 1 bulan dan panah kanan untuk maju 1 bulan.
   - Menyaring data list pengeluaran berdasarkan bulan yang dipilih.

4. **Filter Perbulan di Halaman Detail Pemasukan** *(Selesai)*
   - Kontrol navigasi bulan berupa `< Bulan Tahun >` (contoh: `‹ Oktober 2026 ›`).
   - Tombol panah kiri untuk mundur 1 bulan dan panah kanan untuk maju 1 bulan.
   - Menyaring data list pemasukan berdasarkan bulan yang dipilih.

5. **Interaktivitas Card Dashboard: Total Pemasukan** *(Selesai)*
   - Card Total Pemasukan di Dashboard dapat diklik (`onTap` / ripple effect).
   - Membuka halaman Detail Pemasukan (`IncomeScreen`).
   - Otomatis me-refresh data saldo dan total saat kembali ke Dashboard.

6. **Interaktivitas Card Dashboard: Total Pengeluaran** *(Selesai)*
   - Card Total Pengeluaran di Dashboard dapat diklik (`onTap` / ripple effect).
   - Membuka halaman Detail Pengeluaran (`ExpenseScreen`).
   - Otomatis me-refresh data saldo dan total saat kembali ke Dashboard.

7. **Pencatatan Transaksi dari Kalender** *(Selesai)*
   - Pada halaman Kalender, tepat di atas rincian transaksi tanggal terpilih, ditambahkan 2 tombol aksi:
     - 🟢 **Tambah Pemasukan**
     - 🔴 **Tambah Pengeluaran**
   - Ketika salah satu tombol diklik, form input (`IncomeFormScreen` / `ExpenseFormScreen`) terbuka dengan tanggal yang sudah **otomatis terisi** sesuai tanggal yang sedang dipilih pada kalender.
   - Setelah transaksi disimpan, data kalender dan daftar rincian otomatis diperbarui (*refresh*).

8. **Logo & Identitas "byAdani" di Heading Dashboard** *(Selesai)*
   - Menggantikan teks judul `AyoHemat` pada AppBar Dashboard dengan logo gambar `assets/images/AyoHemat.jpg`.
   - Menambahkan teks `byAdani` di samping logo dengan gaya tipografi yang selaras dan rapi.

9. **Pemisah Ribuan Otomatis (Format Titik) pada Input Nominal Form** *(Selesai)*
   - Pada form tambah dan edit (baik Pemasukan maupun Pengeluaran), nominal yang diketikkan pengguna otomatis diformat dengan tanda titik ribuan (contoh: mengetik `50000` otomatis menjadi `50.000`, `1000000` menjadi `1.000.000`).
   - Pada mode edit, nominal lama langsung ditampilkan dengan format titik.
   - Saat disimpan ke database, format titik dibersihkan sehingga tetap tersimpan sebagai nilai numerik/`double` yang valid di SQLite.

---

## 📁 File yang Terlibat & Rencana Perubahan

| File | Komponen / Perubahan yang Dilakukan |
| :--- | :--- |
| `lib/screens/dashboard/dashboard_screen.dart` | Mengganti judul AppBar dengan logo `assets/images/AyoHemat.jpg` dan teks `byAdani`. Menambahkan `onTap` pada `_SummaryCard`. |
| `lib/screens/income/income_screen.dart` | Menambahkan state `_selectedMonth`, navigasi bulan `< Bulan Tahun >`, Card Total Pemasukan bulanan, dan query data perbulan. |
| `lib/screens/expense/expense_screen.dart` | Menambahkan state `_selectedMonth`, navigasi bulan `< Bulan Tahun >`, Card Total Pengeluaran bulanan, dan query data perbulan. |
| `lib/screens/income/income_form_screen.dart` | Menambahkan parameter `initialDate` dan menerapkan `TextInputFormatter` format titik ribuan otomatis pada input nominal. |
| `lib/screens/expense/expense_form_screen.dart` | Menambahkan parameter `initialDate` dan menerapkan `TextInputFormatter` format titik ribuan otomatis pada input nominal. |
| `lib/screens/calendar/calendar_screen.dart` | Menambahkan baris tombol aksi ("Tambah Pemasukan" & "Tambah Pengeluaran") dengan pengiriman `_selectedDay`. |
| `lib/repositories/transaction_repository.dart` & `lib/database/database_helper.dart` | Menyediakan metode query transaksi bulanan per tipe (`getTransactionsByTypeAndMonth`). |

---

## 🛠️ Langkah-Langkah Pengerjaan (Step-by-Step)

### Tahap 1: Repository & Database Query Support (SELESAI)
- Menambahkan metode untuk mengambil transaksi berdasarkan `type` ('income' / 'expense') dan bulan (`year`, `month`) pada `DatabaseHelper` dan `TransactionRepository`.

### Tahap 2: Update Form Input (`initialDate`) (SELESAI)
- Menambahkan parameter `final DateTime? initialDate;` pada konstruktor `IncomeFormScreen` dan `ExpenseFormScreen`.

### Tahap 3: Halaman Detail Pemasukan (`IncomeScreen`) (SELESAI)
- Menambahkan widget navigasi bulan `< Bulan Tahun >`, Card Total Pemasukan bulanan, dan penyaringan query perbulan.

### Tahap 4: Halaman Detail Pengeluaran (`ExpenseScreen`) (SELESAI)
- Menambahkan widget navigasi bulan `< Bulan Tahun >`, Card Total Pengeluaran bulanan, dan penyaringan query perbulan.

### Tahap 5: Dashboard Interaktivitas (SELESAI)
- Menambahkan `onTap` dan `InkWell` pada `_SummaryCard` Dashboard untuk navigasi ke halaman pemasukan dan pengeluaran.

### Tahap 6: Halaman Kalender (`CalendarScreen`) (SELESAI)
- Menambahkan tombol aksi `+ Tambah Pemasukan` dan `+ Tambah Pengeluaran` di atas rincian harian dengan auto-fill tanggal terpilih.

### Tahap 7: Logo & Branding di Header Dashboard (SELESAI)
- Mengubah `title` AppBar pada `DashboardScreen` menjadi `Row` yang memuat `Image.asset('assets/images/AyoHemat.jpg')` dan teks `byAdani`.

### Tahap 8: Auto-Format Titik Ribuan Form Input (SELESAI)
- Membuat/menerapkan `ThousandsSeparatorInputFormatter` pada `TextFormField` nominal di `ExpenseFormScreen` dan `IncomeFormScreen`.
- Memastikan pemformatan saat inisialisasi edit mode dan parsing nominal saat penyimpanan transaksi berjalan mulus tanpa error.

---

## ✅ Skenario Pengujian (Testing & Verifikasi)

1. **Pengujian Dashboard:**
   - [x] Klik Card Total Pemasukan $\rightarrow$ Berpindah ke halaman Detail Pemasukan.
   - [x] Klik Card Total Pengeluaran $\rightarrow$ Berpindah ke halaman Detail Pengeluaran.
   - [x] Tambah/edit data di halaman detail lalu kembali $\rightarrow$ Angka saldo dan total di Dashboard ter-update otomatis.
   - [x] Logo `AyoHemat.jpg` tampil proporsional di AppBar Dashboard berdampingan dengan teks `byAdani`.

2. **Pengujian Detail Pemasukan & Pengeluaran:**
   - [x] Card Total di atas menampilkan nominal yang sesuai dengan data bulan yang sedang aktif.
   - [x] Menekan tombol panah kiri `‹` $\rightarrow$ Bulan mundur 1 bulan, list & total ter-update.
   - [x] Menekan tombol panah kanan `›` $\rightarrow$ Bulan maju 1 bulan, list & total ter-update.
   - [x] Menambah/mengedit/menghapus transaksi di bulan tersebut $\rightarrow$ List dan card total langsung tersinkronisasi.

3. **Pengujian Kalender:**
   - [x] Pilih tanggal tertentu di kalender (misal: 15 Oktober 2026).
   - [x] Klik tombol "Tambah Pemasukan" $\rightarrow$ Tanggal pada form pemasukan otomatis terisi 15 Oktober 2026.
   - [x] Klik tombol "Tambah Pengeluaran" $\rightarrow$ Tanggal pada form pengeluaran otomatis terisi 15 Oktober 2026.
   - [x] Simpan transaksi $\rightarrow$ Kembali ke kalender, titik penanda dan list rincian langsung ter-update.

4. **Pengujian Auto-Format Titik Nominal:**
   - [x] Ketik `50000` di form pengeluaran/pemasukan $\rightarrow$ Otomatis berubah menjadi `50.000`.
   - [x] Ketik nominal jutaan (misal: `1250000`) $\rightarrow$ Otomatis berubah menjadi `1.250.000`.
   - [x] Mode edit $\rightarrow$ Nilai awal muncul dengan format bertitik.
   - [x] Simpan transaksi $\rightarrow$ Nilai tersimpan dan terhitung dengan benar di database.

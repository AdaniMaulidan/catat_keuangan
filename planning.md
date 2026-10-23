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

10. **Donut / Pie Chart Komposisi Kategori Bulanan** *(Selesai)*
    - Menambahkan grafik Donut/Pie Chart pada halaman Grafik (`ChartScreen`) untuk melihat rincian komposisi keuangan berdasarkan kategori transaksi.
    - Kategori diagregasikan secara otomatis dari teks Keterangan (`description`) transaksi. Jika kategori melebihi 5, kategori kecil sisanya digabung otomatis ke kelompok `"Lainnya"`.
    - Di bagian tengah rongga Donut Chart terdapat teks akumulasi total nominal transaksi pada bulan tersebut.
    - Di sisi kanan Donut Chart terdapat Legend vertikal yang memuat indikator warna lingkaran, nama kategori, dan persentase kontribusi (format: `XX,XX%`).
    - Menyediakan kontrol filter perbulan (`‹ Bulan Tahun ›`) yang independen.
    - Menyediakan tombol pemilih / Toggle Pill untuk beralih antara grafik **Pengeluaran** dan **Pemasukan**.
    - Memastikan widget disusun secara responsif (`Expanded` / `Flexible`) agar terhindar dari *RenderFlex overflow* dan menyediakan tampilan *empty state* jika belum ada data.

11. **Pemisahan Aplikasi: Pemulihan APK Lama (Data Asli) & Pemisahan APK Baru (Data Kosong)** *(Selesai)*
    - Memulihkan dan mencetak kembali file APK Lama persis pada titik commit `5dd9eeeb4a3986c5915b2e9bb27733d8c2774594` dengan package ID asli (`com.example.catat_keuangan`) agar aplikasi lama kembali aktif di HP pengguna dan tetap mengikat data transaksi riil yang sudah ada sebelumnya.
    - Menjadikan versi pengembangan baru (dimulai dari `c1d2a1fe8dadd010c98a97f489f0a2febc2537a1` hingga commit terkini) sebagai aplikasi kedua yang berdiri sendiri dengan identitas baru (`applicationId = "com.adani.ayohemat"`) dan nama database terpisah (`catat_keuangan_v2.db`).
    - Memastikan seluruh proses build APK lama dilakukan di direktori kerja terpisah/sementara sehingga kode terkini pada repositori `catat_keuangan` tidak ada yang diubah, di-rollback, ataupun dirusak.
    - Menghasilkan dua aplikasi mandiri yang terpasang berdampingan di HP:
      1. **Aplikasi Lama (`AyoHemat`):** Tampilan versi stabil awal dengan database transaksi asli.
      2. **Aplikasi Baru (`AyoHematbyAdani`):** Tampilan modern (Stitch, Donut Chart, format titik, dll.) dengan database awal kosong.

12. **Show / Hide Toggle (Ikon Mata) untuk Saldo & Ringkasan Nominal** *(Selesai)*
    - Menambahkan tombol toggle ikon mata (`Icons.visibility_rounded` dan `Icons.visibility_off_rounded`) pada kartu Hero Wallet di Dashboard berdampingan dengan label Saldo.
    - Ketika status tersembunyi (Hide), nominal Saldo Utama, Total Pemasukan, dan Total Pengeluaran otomatis di-masking menjadi `••••••••` demi menjaga privasi pengguna.
    - Status preferensi mata disimpan secara permanen menggunakan `shared_preferences` sehingga jika aplikasi ditutup dalam keadaan tersembunyi, saat dibuka kembali nominal tetap tersembunyi.

13. **Fitur Catat Tagihan (Bills Tracker) CRUD & Bayar Otomatis** *(Akan Dikerjakan)*
    - Modul pencatatan tagihan (*bills tracker*) dengan kemampuan CRUD lengkap (Tambah, Lihat, Edit, Hapus).
    - Field data tagihan: `Nominal` (dengan pemisah ribuan otomatis), `Deskripsi` (nama tagihan), dan `Tanggal Jatuh Tempo` (date picker).
    - Status awal tagihan saat dibuat otomatis **"Belum Dibayar"** (*is_paid = 0*).
    - Tombol aksi **"Bayar"** pada item tagihan yang belum lunas:
      - Menampilkan dialog konfirmasi pembayaran.
      - Saat dikonfirmasi, status tagihan berubah menjadi **"Sudah Dibayar"** (*is_paid = 1*) dan tanggal bayar tercatat.
      - Secara otomatis membuat transaksi **Pengeluaran (Expense)** baru di sistem keuangan dengan nominal tagihan, sehingga **saldo langsung berkurang** dan transaksi tercatat transparan di riwayat pengeluaran, kalender, dan grafik.
    - Layar daftar tagihan (`BillScreen`) dilengkapi tab filter (*Semua, Belum Dibayar, Sudah Dibayar*), indikator sisa hari jatuh tempo (*"Jatuh tempo X hari lagi"*, *"Hari ini"*, *"Terlewat"*), dan kartu ringkasan total tagihan belum bayar.
    - Pintu masuk menu diletakkan pada kartu Menu Dashboard dengan badge jumlah tagihan aktif yang belum dibayar.

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
| `lib/widgets/charts/category_pie_chart.dart` | *(File Baru)* Komponen Donut Chart komposisi kategori, filter perbulan, toggle tipe (Pengeluaran/Pemasukan), dan legend list persentase. |
| `lib/screens/chart/chart_screen.dart` | Mengintegrasikan widget `CategoryPieChart` di atas grafik garis, mengelola sinkronisasi data bulanan. |
| `android/app/build.gradle` | Mengubah `applicationId` versi baru menjadi identitas unik terpisah (`com.adani.ayohemat`). |
| `lib/database/database_helper.dart` | Mengisolasi nama database SQLite versi baru (`catat_keuangan_v2.db`), menambahkan tabel `bills`, serta metode query/transaksi tagihan. |
| `pubspec.yaml` | Menambahkan dependensi `shared_preferences` untuk penyimpanan permanen toggle mata. |
| `lib/models/bill_model.dart` | *(File Baru)* Model data tagihan (`BillModel`) mencakup `amount`, `description`, `dueDate`, `isPaid`, dan `paidDate`. |
| `lib/repositories/bill_repository.dart` | *(File Baru)* Repository perantara UI dan database untuk data tagihan. |
| `lib/screens/bill/bill_screen.dart` | *(File Baru)* Layar daftar tagihan dengan tab filter, ringkasan total belum dibayar, tombol bayar, dan aksi edit/hapus. |
| `lib/screens/bill/bill_form_screen.dart` | *(File Baru)* Form tambah dan edit tagihan dengan format nominal bertitik dan date picker jatuh tempo. |
| `lib/screens/dashboard/dashboard_screen.dart` | Mengintegrasikan tombol toggle mata pada Hero Wallet Card dan menambahkan kartu menu "Tagihan" dengan badge pengingat. |

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

### Tahap 9: Donut / Pie Chart Komposisi Kategori (`CategoryPieChart`) (SELESAI)
- Membuat widget `CategoryPieChart` di `lib/widgets/charts/category_pie_chart.dart` menggunakan `fl_chart.PieChart`.
- Menyiapkan logika agregasi transaksi berdasarkan `description` per bulan dan tipe (`income`/`expense`), perhitungan persentase, dan pengelompokan item minor ke "Lainnya".
- Menyusun layout Donut Chart dengan angka total di rongga tengah dan legend persentase di sisi kanan secara responsif.
- Menambahkan tombol toggle tipe (Pengeluaran / Pemasukan) dan navigasi bulan (`‹ Bulan Tahun ›`).
- Memasang widget tersebut ke dalam `SingleChildScrollView` pada `lib/screens/chart/chart_screen.dart`.

### Tahap 10: Pemulihan APK Lama & Pemisahan APK Baru (SELESAI)
- **Bagian 1 (Ekstraksi & Build APK Lama):**
  - Mengekstrak kode commit `5dd9eeeb4a3986c5915b2e9bb27733d8c2774594` ke direktori build sementara (`scratch/old_build`).
  - Melakukan build APK rilis lama (`AyoHemat-Lama.apk`) dengan `applicationId` asli `com.example.catat_keuangan`.
  - Memasang/mengembalikan APK lama tersebut ke HP pengguna sehingga data riil pengguna langsung tersambung kembali.
- **Bagian 2 (Isolasi & Build APK Baru):**
  - Mengubah `applicationId` pada `android/app/build.gradle` menjadi identitas baru (`com.adani.ayohemat`).
  - Memisahkan nama database lokal SQLite di `lib/database/database_helper.dart` menjadi database baru (`catat_keuangan_v2.db`) dengan data kosong.
  - Melakukan build APK baru (`AyoHematbyAdani-Baru.apk`) dan memasangnya ke HP sebagai aplikasi kedua berdampingan.

### Tahap 11: Show / Hide Toggle Saldo & Ringkasan (SELESAI)
- Menambahkan dependensi `shared_preferences` ke `pubspec.yaml`.
- Mengimplementasikan state preferensi `_isBalanceHidden` pada `DashboardScreen` yang disimpan secara persisten.
- Menambahkan tombol ikon mata di `_HeroWalletCard` dan menerapkan masking `••••••••` pada Saldo, Total Pemasukan, dan Total Pengeluaran saat disembunyikan.

### Tahap 12: Fitur Catat Tagihan CRUD & Bayar Otomatis (AKAN DIKERJAKAN)
- **Bagian 1: Skema Database & Model:**
  - Membuat tabel `bills` di `DatabaseHelper` dan membuat model `BillModel`.
  - Membuat `BillRepository` untuk operasi insert, fetch, update, delete, dan bayar tagihan.
- **Bagian 2: Layar Daftar Tagihan & Form:**
  - Membuat `BillFormScreen` untuk input dan edit data tagihan (nominal, deskripsi, tanggal jatuh tempo).
  - Membuat `BillScreen` dengan tab filter (*Semua, Belum Dibayar, Sudah Dibayar*), card tagihan responsif, indikator sisa hari, dan dialog konfirmasi bayar.
- **Bagian 3: Integrasi Dashboard:**
  - Menambahkan kartu menu "Tagihan" di Dashboard dengan badge jumlah tagihan yang belum dibayar.
  - Memastikan aksi bayar tagihan otomatis memotong saldo, membuat transaksi pengeluaran, dan me-refresh dashboard secara instan.

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

5. **Pengujian Donut / Pie Chart Komposisi Kategori:**
   - [x] Buka tab menu "Grafik" $\rightarrow$ Muncul Donut Chart di atas grafik garis.
   - [x] Mengubah filter bulan dengan panah `‹` atau `›` $\rightarrow$ Donut Chart dan persentase rincian kategori otomatis berubah sesuai bulan yang aktif.
   - [x] Mengklik toggle "Pengeluaran" vs "Pemasukan" $\rightarrow$ Grafik beralih menampilkan komposisi sesuai tipe transaksi terpilih.
   - [x] Angka total di tengah Donut Chart sesuai dengan jumlah nominal seluruh transaksi di bulan tersebut.
   - [x] Persentase di legend sisi kanan terhitung dengan akurat (total akumulasi 100%).
   - [x] Ketika tidak ada transaksi pada bulan yang dipilih $\rightarrow$ Tampil *empty state* yang rapi tanpa error render.

6. **Pengujian Pemisahan Aplikasi & Keutuhan Data:**
   - [x] Aplikasi Lama terpasang kembali di HP dan menampilkan seluruh data transaksi riil sebelumnya.
   - [x] Aplikasi Baru terpasang berdampingan di HP tanpa menimpa aplikasi lama.
   - [x] Aplikasi Baru memiliki nama `AyoHematbyAdani` dan icon kotak 2048x2048 yang proporsional.
   - [x] Data di Aplikasi Baru dalam keadaan bersih/kosong saat pertama kali dibuka.
   - [x] Penambahan transaksi di Aplikasi Baru tidak mempengaruhi data di Aplikasi Lama, begitu pun sebaliknya.

7. **Pengujian Show / Hide Toggle Saldo:**
   - [x] Mengklik ikon mata di Hero Wallet Card $\rightarrow$ Saldo, Total Pemasukan, dan Total Pengeluaran berubah menjadi `••••••••`.
   - [x] Mengklik ikon mata lagi $\rightarrow$ Nominal asli kembali tampil.
   - [x] Tutup aplikasi dalam keadaan nominal tersembunyi lalu buka kembali $\rightarrow$ Nominal tetap tersembunyi secara permanen.

8. **Pengujian Fitur Catat Tagihan:**
   - [ ] Menambah tagihan baru melalui form $\rightarrow$ Tagihan tersimpan dengan status "Belum Dibayar".
   - [ ] Tagihan tampil di tab "Belum Dibayar" dan tab "Semua" dengan indikator sisa hari jatuh tempo.
   - [ ] Mengedit tagihan $\rightarrow$ Data nominal/deskripsi/jatuh tempo ter-update dengan benar.
   - [ ] Menghapus tagihan $\rightarrow$ Tagihan terhapus dari daftar.
   - [ ] Mengklik tombol "Bayar" pada tagihan $\rightarrow$ Muncul dialog konfirmasi bayar.
   - [ ] Mengonfirmasi bayar $\rightarrow$ Status tagihan berubah menjadi "Sudah Dibayar", berpindah ke tab Sudah Dibayar.
   - [ ] Cek saldo Dashboard $\rightarrow$ Saldo otomatis berkurang sejumlah nominal tagihan tersebut.
   - [ ] Cek halaman Pengeluaran $\rightarrow$ Muncul transaksi pengeluaran baru bernama `'Tagihan: [Deskripsi Tagihan]'`.

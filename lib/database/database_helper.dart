import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/bill_model.dart';

// DatabaseHelper menggunakan pola Singleton agar seluruh aplikasi
// berbagi satu instance koneksi database yang sama.
//
// Catatan platform:
// - Android/iOS: sqflite bekerja langsung tanpa konfigurasi tambahan.
// - Windows/Linux/macOS: panggil DatabaseHelper.initForDesktop() dari main()
//   sebelum database diakses. Membutuhkan package sqflite_common_ffi.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  // Nama file dan versi database.
  static const String _dbName = 'catat_keuangan_v2.db';
  static const int _dbVersion = 2;

  // Nama tabel dan kolom Transaksi — dijadikan konstanta untuk menghindari typo.
  static const String tableTransactions = 'transactions';
  static const String colId = 'id';
  static const String colType = 'type';
  static const String colAmount = 'amount';
  static const String colDescription = 'description';
  static const String colDate = 'date';

  // Nama tabel dan kolom Tagihan (Bills)
  static const String tableBills = 'bills';
  static const String colBillId = 'id';
  static const String colBillAmount = 'amount';
  static const String colBillDescription = 'description';
  static const String colBillDueDate = 'due_date';
  static const String colBillIsPaid = 'is_paid';
  static const String colBillPaidDate = 'paid_date';

  // Mendapatkan instance database. Jika belum ada, inisialisasi terlebih dahulu.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  // Membuka koneksi dan membuat database beserta tabel.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Dipanggil satu kali saat database pertama kali dibuat di perangkat.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        $colId          INTEGER PRIMARY KEY AUTOINCREMENT,
        $colType        TEXT    NOT NULL CHECK($colType IN ('income', 'expense')),
        $colAmount      REAL    NOT NULL CHECK($colAmount > 0),
        $colDescription TEXT    NOT NULL,
        $colDate        TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableBills (
        $colBillId          INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBillAmount      REAL    NOT NULL CHECK($colBillAmount > 0),
        $colBillDescription TEXT    NOT NULL,
        $colBillDueDate     TEXT    NOT NULL,
        $colBillIsPaid      INTEGER NOT NULL DEFAULT 0,
        $colBillPaidDate    TEXT
      )
    ''');
  }

  // Migrasi skema saat database di-upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableBills (
          $colBillId          INTEGER PRIMARY KEY AUTOINCREMENT,
          $colBillAmount      REAL    NOT NULL CHECK($colBillAmount > 0),
          $colBillDescription TEXT    NOT NULL,
          $colBillDueDate     TEXT    NOT NULL,
          $colBillIsPaid      INTEGER NOT NULL DEFAULT 0,
          $colBillPaidDate    TEXT
        )
      ''');
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE — Menyimpan satu transaksi baru ke database.
  // Mengembalikan id dari baris yang baru dimasukkan.
  // ---------------------------------------------------------------------------
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(
      tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // READ — Mengambil semua transaksi, diurutkan dari yang terbaru.
  // ---------------------------------------------------------------------------
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      orderBy: '$colDate DESC, $colId DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — Mengambil transaksi berdasarkan jenis ('income' atau 'expense').
  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: '$colType = ?',
      whereArgs: [type],
      orderBy: '$colDate DESC, $colId DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — Mengambil transaksi berdasarkan tanggal tertentu (untuk kalender).
  // Parameter date: format 'YYYY-MM-DD'.
  Future<List<TransactionModel>> getTransactionsByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: '$colDate = ?',
      whereArgs: [date],
      orderBy: '$colId DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — Mengambil transaksi dalam satu bulan tertentu (untuk grafik).
  // Parameter: year (misal 2026), month (misal 9 untuk September).
  Future<List<TransactionModel>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    // Format bulan dengan padding nol agar cocok dengan format 'YYYY-MM-DD'.
    final monthStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthStr';

    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: '$colDate LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: '$colDate ASC, $colId ASC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — Mengambil transaksi berdasarkan jenis ('income'/'expense') dalam satu bulan tertentu.
  // Diurutkan dari tanggal terbaru.
  Future<List<TransactionModel>> getTransactionsByTypeAndMonth(
    String type,
    int year,
    int month,
  ) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthStr';

    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: '$colType = ? AND $colDate LIKE ?',
      whereArgs: [type, '$prefix%'],
      orderBy: '$colDate DESC, $colId DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — Menghitung total nominal berdasarkan jenis transaksi.
  // Mengembalikan 0.0 jika tidak ada data.
  Future<double> getTotalByType(String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM($colAmount) AS total FROM $tableTransactions WHERE $colType = ?',
      [type],
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  // READ — Menghitung saldo (total pemasukan - total pengeluaran).
  Future<double> getBalance() async {
    final totalIncome = await getTotalByType(TransactionModel.income);
    final totalExpense = await getTotalByType(TransactionModel.expense);
    return totalIncome - totalExpense;
  }

  // ---------------------------------------------------------------------------
  // UPDATE — Memperbarui data transaksi yang sudah ada berdasarkan id.
  // Mengembalikan jumlah baris yang berhasil diperbarui (0 jika tidak ditemukan).
  // ---------------------------------------------------------------------------
  Future<int> updateTransaction(TransactionModel transaction) async {
    assert(transaction.id != null, 'updateTransaction: id tidak boleh null');
    final db = await database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: '$colId = ?',
      whereArgs: [transaction.id],
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE — Menghapus satu transaksi berdasarkan id.
  // Mengembalikan jumlah baris yang berhasil dihapus.
  // ---------------------------------------------------------------------------
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      tableTransactions,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // TAGIHAN (BILLS) — CRUD & OPERASI PEMBAYARAN
  // ---------------------------------------------------------------------------

  // CREATE — Menambahkan tagihan baru.
  Future<int> insertBill(BillModel bill) async {
    final db = await database;
    return await db.insert(
      tableBills,
      bill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ — Mengambil semua tagihan, diurutkan berdasarkan jatuh tempo terdekat.
  Future<List<BillModel>> getAllBills() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableBills,
      orderBy: '$colBillIsPaid ASC, $colBillDueDate ASC, $colBillId DESC',
    );
    return maps.map((map) => BillModel.fromMap(map)).toList();
  }

  // READ — Mengambil tagihan berdasarkan status bayar (belum / sudah lunas).
  Future<List<BillModel>> getBillsByPaidStatus(bool isPaid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableBills,
      where: '$colBillIsPaid = ?',
      whereArgs: [isPaid ? 1 : 0],
      orderBy: '$colBillDueDate ASC, $colBillId DESC',
    );
    return maps.map((map) => BillModel.fromMap(map)).toList();
  }

  // UPDATE — Memperbarui data tagihan.
  Future<int> updateBill(BillModel bill) async {
    assert(bill.id != null, 'updateBill: id tidak boleh null');
    final db = await database;
    return await db.update(
      tableBills,
      bill.toMap(),
      where: '$colBillId = ?',
      whereArgs: [bill.id],
    );
  }

  // DELETE — Menghapus tagihan berdasarkan id.
  Future<int> deleteBill(int id) async {
    final db = await database;
    return await db.delete(
      tableBills,
      where: '$colBillId = ?',
      whereArgs: [id],
    );
  }

  // OPERASI BAYAR TAGIHAN — Atomik: Ubah status tagihan & buat transaksi pengeluaran.
  Future<void> payBill(BillModel bill) async {
    assert(bill.id != null, 'payBill: id tidak boleh null');
    final db = await database;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      // 1. Update status tagihan menjadi sudah dibayar
      await txn.update(
        tableBills,
        {
          colBillIsPaid: 1,
          colBillPaidDate: today,
        },
        where: '$colBillId = ?',
        whereArgs: [bill.id],
      );

      // 2. Buat transaksi pengeluaran baru otomatis
      await txn.insert(
        tableTransactions,
        {
          colType: TransactionModel.expense,
          colAmount: bill.amount,
          colDescription: 'Tagihan: ${bill.description}',
          colDate: today,
        },
      );
    });
  }

  // Menghitung jumlah tagihan yang belum dibayar.
  Future<int> getUnpaidBillsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableBills WHERE $colBillIsPaid = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Menghitung total nominal tagihan yang belum dibayar.
  Future<double> getTotalUnpaidBillsAmount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM($colBillAmount) as total FROM $tableBills WHERE $colBillIsPaid = 0',
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  // Menutup koneksi database. Opsional — biasanya tidak perlu dipanggil manual.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

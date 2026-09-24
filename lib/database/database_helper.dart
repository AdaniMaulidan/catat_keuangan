import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

// DatabaseHelper menggunakan pola Singleton agar seluruh aplikasi
// berbagi satu instance koneksi database yang sama.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  // Nama file dan versi database.
  static const String _dbName = 'catat_keuangan.db';
  static const int _dbVersion = 1;

  // Nama tabel dan kolom.
  static const String tableTransactions = 'transactions';
  static const String colId = 'id';
  static const String colType = 'type';
  static const String colAmount = 'amount';
  static const String colDescription = 'description';
  static const String colDate = 'date';

  // Inisialisasi FFI untuk platform desktop (Windows/Linux/macOS).
  // Dipanggil sekali dari main() sebelum database diakses.
  // Tidak diperlukan di Android/iOS.
  static void initForDesktop() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }


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
    );
  }

  // Dipanggil satu kali saat database pertama kali dibuat.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        $colId          INTEGER PRIMARY KEY AUTOINCREMENT,
        $colType        TEXT    NOT NULL CHECK($colType IN ('income', 'expense')),
        $colAmount      REAL    NOT NULL,
        $colDescription TEXT    NOT NULL,
        $colDate        TEXT    NOT NULL
      )
    ''');
  }

  // -------------------------------------------------------------------------
  // CREATE — Menyimpan satu transaksi baru ke database.
  // Mengembalikan id dari baris yang baru dimasukkan.
  // -------------------------------------------------------------------------
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(
      tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // -------------------------------------------------------------------------
  // READ — Mengambil semua transaksi, diurutkan dari yang terbaru.
  // -------------------------------------------------------------------------
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
      where: "$colDate LIKE ?",
      whereArgs: ['$prefix%'],
      orderBy: '$colDate ASC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — Menghitung total nominal berdasarkan jenis transaksi.
  // Digunakan untuk menampilkan total pemasukan, pengeluaran, dan saldo.
  Future<double> getTotalByType(String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM($colAmount) as total FROM $tableTransactions WHERE $colType = ?',
      [type],
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  // READ — Menghitung saldo (total pemasukan - total pengeluaran).
  Future<double> getBalance() async {
    final totalIncome = await getTotalByType('income');
    final totalExpense = await getTotalByType('expense');
    return totalIncome - totalExpense;
  }

  // -------------------------------------------------------------------------
  // UPDATE — Memperbarui data transaksi yang sudah ada berdasarkan id.
  // Mengembalikan jumlah baris yang berhasil diperbarui.
  // -------------------------------------------------------------------------
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: '$colId = ?',
      whereArgs: [transaction.id],
    );
  }

  // -------------------------------------------------------------------------
  // DELETE — Menghapus satu transaksi berdasarkan id.
  // Mengembalikan jumlah baris yang berhasil dihapus.
  // -------------------------------------------------------------------------
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      tableTransactions,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  // Menutup koneksi database. Dipanggil saat aplikasi ditutup (opsional).
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

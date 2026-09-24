import '../database/database_helper.dart';
import '../models/transaction_model.dart';

// TransactionRepository adalah perantara antara UI/business logic
// dengan DatabaseHelper (SQLite).
//
// UI tidak perlu tahu cara kerja query SQLite secara langsung.
// Semua akses data transaksi dilakukan melalui class ini.
//
// Penggunaan:
//   final repo = TransactionRepository();
//   final transactions = await repo.getAllTransactions();
class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  // Menambahkan transaksi baru. Mengembalikan ID yang dihasilkan database.
  // Gunakan TransactionModel.income atau TransactionModel.expense untuk type.
  Future<int> addTransaction(TransactionModel transaction) {
    return _db.insertTransaction(transaction);
  }

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  // Mengambil semua transaksi, diurutkan dari tanggal terbaru.
  Future<List<TransactionModel>> getAllTransactions() {
    return _db.getAllTransactions();
  }

  // Mengambil daftar pemasukan saja.
  Future<List<TransactionModel>> getIncomeTransactions() {
    return _db.getTransactionsByType(TransactionModel.income);
  }

  // Mengambil daftar pengeluaran saja.
  Future<List<TransactionModel>> getExpenseTransactions() {
    return _db.getTransactionsByType(TransactionModel.expense);
  }

  // Mengambil transaksi berdasarkan tipe secara generik.
  // Gunakan TransactionModel.income atau TransactionModel.expense.
  Future<List<TransactionModel>> getTransactionsByType(String type) {
    return _db.getTransactionsByType(type);
  }

  // Mengambil transaksi berdasarkan tanggal tertentu.
  // Digunakan oleh kalender dashboard.
  // Parameter date: format 'YYYY-MM-DD', misal '2026-09-24'.
  Future<List<TransactionModel>> getTransactionsByDate(String date) {
    return _db.getTransactionsByDate(date);
  }

  // Mengambil transaksi dalam satu bulan tertentu.
  // Digunakan oleh grafik pemasukan dan pengeluaran.
  // Parameter: year (misal 2026), month (misal 9 untuk September).
  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) {
    return _db.getTransactionsByMonth(year, month);
  }

  // ---------------------------------------------------------------------------
  // AGREGASI — untuk Dashboard
  // ---------------------------------------------------------------------------

  // Menghitung total pemasukan dari seluruh data.
  Future<double> getTotalIncome() {
    return _db.getTotalByType(TransactionModel.income);
  }

  // Menghitung total pengeluaran dari seluruh data.
  Future<double> getTotalExpense() {
    return _db.getTotalByType(TransactionModel.expense);
  }

  // Menghitung saldo = total pemasukan - total pengeluaran.
  Future<double> getBalance() {
    return _db.getBalance();
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  // Memperbarui transaksi yang sudah ada. Transaksi harus memiliki id.
  // Mengembalikan jumlah baris yang berhasil diperbarui (0 = tidak ditemukan).
  Future<int> updateTransaction(TransactionModel transaction) {
    assert(
      transaction.id != null,
      'updateTransaction: transaksi harus memiliki id',
    );
    return _db.updateTransaction(transaction);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  // Menghapus transaksi berdasarkan id.
  // Mengembalikan jumlah baris yang berhasil dihapus (0 = tidak ditemukan).
  Future<int> deleteTransaction(int id) {
    return _db.deleteTransaction(id);
  }
}

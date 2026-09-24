import 'package:flutter/material.dart';
import 'models/transaction_model.dart';
import 'repositories/transaction_repository.dart';

void main() async {
  // Diperlukan sebelum menggunakan plugin native (sqflite) di main().
  WidgetsFlutterBinding.ensureInitialized();

  // Jalankan test repository hanya saat mode debug.
  // Blok assert tidak dieksekusi di mode release/production.
  assert(() {
    _testRepository();
    return true;
  }());

  runApp(const MyApp());
}

// Test sederhana untuk memverifikasi seluruh repository API bekerja.
// Akan dihapus setelah UI selesai dibuat.
Future<void> _testRepository() async {
  final repo = TransactionRepository();
  debugPrint('=== REPOSITORY TEST START ===');

  // --- CREATE ---
  const today = '2026-09-24';

  final incomeId = await repo.addTransaction(
    TransactionModel(
      type: TransactionModel.income,
      amount: 5000000,
      description: 'Gaji September',
      date: today,
    ),
  );
  debugPrint('[CREATE] income id: $incomeId');

  final expenseId = await repo.addTransaction(
    TransactionModel(
      type: TransactionModel.expense,
      amount: 75000,
      description: 'Makan siang',
      date: today,
    ),
  );
  debugPrint('[CREATE] expense id: $expenseId');

  // --- READ: semua transaksi ---
  final all = await repo.getAllTransactions();
  debugPrint('[READ] getAllTransactions: ${all.length} transaksi');

  // --- READ: berdasarkan tipe ---
  final incomes = await repo.getIncomeTransactions();
  debugPrint('[READ] getIncomeTransactions: ${incomes.length}');

  final expenses = await repo.getExpenseTransactions();
  debugPrint('[READ] getExpenseTransactions: ${expenses.length}');

  // --- READ: berdasarkan tanggal (kalender) ---
  final byDate = await repo.getTransactionsByDate(today);
  debugPrint('[READ] getTransactionsByDate($today): ${byDate.length}');

  // --- READ: berdasarkan bulan (grafik) ---
  final byMonth = await repo.getTransactionsByMonth(2026, 9);
  debugPrint('[READ] getTransactionsByMonth(2026,9): ${byMonth.length}');

  // --- AGREGASI ---
  final totalIncome = await repo.getTotalIncome();
  final totalExpense = await repo.getTotalExpense();
  final balance = await repo.getBalance();
  debugPrint('[CALC] getTotalIncome  : $totalIncome');
  debugPrint('[CALC] getTotalExpense : $totalExpense');
  debugPrint('[CALC] getBalance      : $balance');

  // --- UPDATE ---
  final toUpdate = all.firstWhere((t) => t.isIncome);
  final rowsUpdated = await repo.updateTransaction(
    toUpdate.copyWith(amount: 6000000, description: 'Gaji September (revisi)'),
  );
  debugPrint('[UPDATE] rows updated: $rowsUpdated');
  final afterUpdate = await repo.getTotalIncome();
  debugPrint('[UPDATE] total income setelah update: $afterUpdate');

  // --- DELETE ---
  final toDelete = all.firstWhere((t) => t.isExpense);
  final rowsDeleted = await repo.deleteTransaction(toDelete.id!);
  debugPrint('[DELETE] rows deleted: $rowsDeleted');
  final afterDelete = await repo.getAllTransactions();
  debugPrint('[DELETE] total transaksi tersisa: ${afterDelete.length}');

  debugPrint('=== REPOSITORY TEST END ===');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat Keuangan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const _PlaceholderScreen(),
    );
  }
}

// Placeholder sementara — akan diganti dengan halaman utama pada langkah UI.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Keuangan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Fondasi data siap.\nUI akan dibuat pada langkah berikutnya.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/income/income_screen.dart';
import 'screens/expense/expense_screen.dart';

void main() async {
  // Diperlukan sebelum menggunakan plugin native (sqflite) di main().
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      // Halaman pemilihan sementara untuk testing Langkah 7.
      // Akan diganti dengan Dashboard pada langkah berikutnya.
      home: const _TempNavScreen(),
    );
  }
}

// Navigasi sementara untuk mengakses Pemasukan dan Pengeluaran.
// Hanya digunakan untuk testing — akan diganti dengan Dashboard.
class _TempNavScreen extends StatelessWidget {
  const _TempNavScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Keuangan'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tombol ke halaman Pemasukan
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const IncomeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Pemasukan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tombol ke halaman Pengeluaran
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpenseScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Pengeluaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/income/income_screen.dart';

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
      // IncomeScreen sebagai home sementara untuk testing Langkah 6.
      // Akan diganti dengan Dashboard pada langkah berikutnya.
      home: const IncomeScreen(),
    );
  }
}

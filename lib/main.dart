import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/main/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Diperlukan sebelum menggunakan plugin native (sqflite) di main().
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Inisialisasi sqflite untuk Web (Chrome)
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Inisialisasi sqflite untuk Windows/Linux
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  
  // Inisialisasi locale id_ID untuk Kalender dan DateFormat
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AyoHemat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavigationScreen(),
    );
  }
}

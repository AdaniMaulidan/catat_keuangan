import 'package:flutter/services.dart';

// Utility untuk memformat angka menjadi format Rupiah.
// Format yang dihasilkan: "Rp 5.000.000"
// Digunakan oleh UI untuk menampilkan nominal transaksi.
// Data di database tetap disimpan sebagai double, bukan string format ini.
class CurrencyFormatter {
  CurrencyFormatter._(); // mencegah instantiasi

  // Mengubah double menjadi string format Rupiah.
  // Contoh: 5000000.0 → "Rp 5.000.000"
  static String format(double amount) {
    return 'Rp ${formatNumberOnly(amount)}';
  }

  // Mengubah double menjadi string angka dengan titik ribuan tanpa prefix "Rp ".
  // Contoh: 50000.0 → "50.000"
  static String formatNumberOnly(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;

    for (int i = parts.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(parts[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join();
  }

  // Mengubah string input pengguna menjadi double.
  // Mengembalikan null jika input tidak valid.
  // Menangani input seperti: "50000", "50.000", "5.000.000"
  static double? parse(String input) {
    // Hapus titik sebagai pemisah ribuan, pertahankan koma/titik desimal
    final cleaned = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}

// TextInputFormatter untuk menambahkan titik pemisah ribuan secara otomatis saat user mengetik.
// Contoh: mengetik 50000 otomatis menjadi 50.000, 1000000 menjadi 1.000.000.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Jika user menekan backspace tepat di sebelah titik, hapus juga digit di kirinya
    String textToProcess = newValue.text;
    int cursorEnd = newValue.selection.end;

    if (oldValue.text.length - newValue.text.length == 1 &&
        oldValue.selection.end > 0 &&
        oldValue.selection.end <= oldValue.text.length &&
        oldValue.text[oldValue.selection.end - 1] == '.') {
      final deletePos = oldValue.selection.end - 2;
      if (deletePos >= 0) {
        textToProcess = oldValue.text.substring(0, deletePos) +
            oldValue.text.substring(oldValue.selection.end);
        cursorEnd = deletePos;
      }
    }

    final digits = textToProcess.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format dengan titik setiap 3 digit dari belakang
    final chars = digits.split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = chars.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join();

    // Hitung posisi kursor baru yang presisi berdasarkan jumlah digit sebelum kursor
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorEnd && i < textToProcess.length; i++) {
      if (RegExp(r'\d').hasMatch(textToProcess[i])) {
        digitsBeforeCursor++;
      }
    }

    int newOffset = 0;
    int digitCount = 0;
    while (newOffset < formatted.length && digitCount < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[newOffset])) {
        digitCount++;
      }
      newOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

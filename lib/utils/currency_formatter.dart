// Utility untuk memformat angka menjadi format Rupiah.
// Format yang dihasilkan: "Rp 5.000.000"
// Digunakan oleh UI untuk menampilkan nominal transaksi.
// Data di database tetap disimpan sebagai double, bukan string format ini.
class CurrencyFormatter {
  CurrencyFormatter._(); // mencegah instantiasi

  // Mengubah double menjadi string format Rupiah.
  // Contoh: 5000000.0 → "Rp 5.000.000"
  static String format(double amount) {
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

    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  // Mengubah string input pengguna menjadi double.
  // Mengembalikan null jika input tidak valid.
  // Menangani input seperti: "5000000", "5.000.000", "5000000.50"
  static double? parse(String input) {
    // Hapus titik sebagai pemisah ribuan, pertahankan koma/titik desimal
    final cleaned = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}

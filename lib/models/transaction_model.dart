// Model untuk data transaksi (pemasukan dan pengeluaran).
// Field `type` digunakan untuk membedakan jenis transaksi:
//   - TransactionModel.income  → 'income'  : pemasukan
//   - TransactionModel.expense → 'expense' : pengeluaran

class TransactionModel {
  // Konstanta tipe transaksi — gunakan ini agar tidak ada typo string.
  static const String income = 'income';
  static const String expense = 'expense';

  final int? id; // nullable: null ketika transaksi belum disimpan ke DB
  final String type; // hanya 'income' atau 'expense'
  final double amount; // nominal angka positif, bukan format Rupiah
  final String description; // keterangan transaksi, tidak boleh kosong
  final String date; // format: 'YYYY-MM-DD', misal '2026-09-24'

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  }) : assert(
         type == income || type == expense,
         'type harus "income" atau "expense", bukan "$type"',
       ),
       assert(amount > 0, 'amount harus lebih besar dari 0'),
       assert(description.isNotEmpty, 'description tidak boleh kosong'),
       assert(
         RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date),
         'date harus dalam format YYYY-MM-DD, bukan "$date"',
       );

  // Helper getter untuk memudahkan pengecekan tipe tanpa membandingkan string.
  bool get isIncome => type == income;
  bool get isExpense => type == expense;

  // Konversi dari Map (hasil query SQLite) ke objek TransactionModel.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: map['date'] as String,
    );
  }

  // Konversi dari objek TransactionModel ke Map untuk disimpan ke SQLite.
  // id tidak disertakan ketika null (insert baru), agar AUTOINCREMENT bekerja.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date,
    };
  }

  // Membuat salinan objek dengan nilai yang diperbarui (untuk operasi update).
  TransactionModel copyWith({
    int? id,
    String? type,
    double? amount,
    String? description,
    String? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, '
        'description: $description, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.type == type &&
        other.amount == amount &&
        other.description == description &&
        other.date == date;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      description.hashCode ^
      date.hashCode;
}

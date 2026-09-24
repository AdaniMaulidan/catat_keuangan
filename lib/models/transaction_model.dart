// Model untuk data transaksi (pemasukan dan pengeluaran).
// Field `type` digunakan untuk membedakan jenis transaksi:
//   - 'income'  : pemasukan
//   - 'expense' : pengeluaran

class TransactionModel {
  final int? id;
  final String type; // 'income' atau 'expense'
  final double amount; // nominal dalam angka, bukan format Rupiah
  final String description; // keterangan
  final String date; // format: 'YYYY-MM-DD'

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

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
}

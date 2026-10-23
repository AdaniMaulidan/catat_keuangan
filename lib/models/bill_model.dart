class BillModel {
  final int? id;
  final double amount;
  final String description;
  final String dueDate; // Format: 'YYYY-MM-DD'
  final bool isPaid;
  final String? paidDate; // Format: 'YYYY-MM-DD'

  BillModel({
    this.id,
    required this.amount,
    required this.description,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'description': description,
      'due_date': dueDate,
      'is_paid': isPaid ? 1 : 0,
      'paid_date': paidDate,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      dueDate: map['due_date'] as String,
      isPaid: (map['is_paid'] as int) == 1,
      paidDate: map['paid_date'] as String?,
    );
  }

  BillModel copyWith({
    int? id,
    double? amount,
    String? description,
    String? dueDate,
    bool? isPaid,
    String? paidDate,
  }) {
    return BillModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}

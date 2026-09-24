import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';

// Form untuk menambah atau mengedit pengeluaran.
//
// Mode tambah: panggil tanpa parameter `transaction`.
// Mode edit  : panggil dengan `transaction` berisi data yang ingin diedit.
//
// Setelah simpan berhasil, screen ini akan di-pop dengan nilai `true`
// sehingga screen pemanggil bisa refresh daftarnya.
class ExpenseFormScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = mode tambah, non-null = mode edit

  const ExpenseFormScreen({super.key, this.transaction});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _repository = TransactionRepository();
  bool _isSaving = false;

  DateTime? _selectedDate;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _amountController.text =
          widget.transaction!.amount.toStringAsFixed(0);
      _descriptionController.text = widget.transaction!.description;
      try {
        _selectedDate = DateTime.parse(widget.transaction!.date);
      } catch (_) {
        _selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showError('Silakan pilih tanggal transaksi terlebih dahulu.');
      return;
    }

    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Nominal tidak valid.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        final updated = widget.transaction!.copyWith(
          amount: amount,
          description: description,
          date: _formatDate(_selectedDate!),
        );
        await _repository.updateTransaction(updated);
      } else {
        final newTransaction = TransactionModel(
          type: TransactionModel.expense,
          amount: amount,
          description: description,
          date: _formatDate(_selectedDate!),
        );
        await _repository.addTransaction(newTransaction);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal menyimpan: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Edit Pengeluaran' : 'Tambah Pengeluaran';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Field Nominal ---
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  hintText: 'Contoh: 25000',
                  prefixText: 'Rp ',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal tidak boleh kosong.';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) {
                    return 'Nominal harus berupa angka.';
                  }
                  if (parsed <= 0) {
                    return 'Nominal harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Field Deskripsi ---
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Contoh: Makan siang',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Info Tanggal ---
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate != null
                            ? 'Tanggal: ${_formatDate(_selectedDate!)}'
                            : 'Pilih tanggal',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Tombol Simpan ---
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

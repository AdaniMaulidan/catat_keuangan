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

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi field dengan data yang sudah ada.
    if (_isEditMode) {
      _amountController.text =
          widget.transaction!.amount.toStringAsFixed(0);
      _descriptionController.text = widget.transaction!.description;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Mendapatkan tanggal hari ini dalam format YYYY-MM-DD.
  String _getTodayDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _save() async {
    // Validasi form — jika ada field yang invalid, hentikan.
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    // Parse nominal — validasi tambahan untuk memastikan angka valid.
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Nominal tidak valid.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Mode edit: pertahankan id, type (expense), dan tanggal asli.
        final updated = widget.transaction!.copyWith(
          amount: amount,
          description: description,
        );
        await _repository.updateTransaction(updated);
      } else {
        // Mode tambah: type expense, gunakan tanggal hari ini.
        final newTransaction = TransactionModel(
          type: TransactionModel.expense,
          amount: amount,
          description: description,
          date: _getTodayDate(),
        );
        await _repository.addTransaction(newTransaction);
      }

      if (mounted) {
        // Kembalikan true ke screen pemanggil untuk trigger refresh.
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
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
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
                  // Hanya boleh angka
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

              // --- Info Tanggal (read-only) ---
              Container(
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
                      _isEditMode
                          ? 'Tanggal: ${widget.transaction!.date}'
                          : 'Tanggal: ${_getTodayDate()} (hari ini)',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
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

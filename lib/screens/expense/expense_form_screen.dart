import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class ExpenseFormScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = tambah, non-null = edit
  final DateTime? initialDate;

  const ExpenseFormScreen({
    super.key,
    this.transaction,
    this.initialDate,
  });

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
          CurrencyFormatter.formatNumberOnly(widget.transaction!.amount);
      _descriptionController.text = widget.transaction!.description;
      try {
        _selectedDate = DateTime.parse(widget.transaction!.date);
      } catch (_) {
        _selectedDate = null;
      }
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
    } else {
      _selectedDate = DateTime.now();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.rose600,
              onPrimary: Colors.white,
              onSurface: AppTheme.slate800,
            ),
          ),
          child: child!,
        );
      },
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

    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Nominal tidak valid.');
      return;
    }

    final description = _descriptionController.text.trim();

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
        backgroundColor: AppTheme.rose600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Edit Pengeluaran' : 'Tambah Pengeluaran';

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Field 1: Nominal ---
              const Text(
                'NOMINAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                ),
                inputFormatters: [
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: 'Rp  ',
                  prefixStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate400,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal tidak boleh kosong.';
                  }
                  final parsed = CurrencyFormatter.parse(value.trim());
                  if (parsed == null) {
                    return 'Nominal harus berupa angka.';
                  }
                  if (parsed <= 0) {
                    return 'Nominal harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Field 2: Deskripsi ---
              const Text(
                'DESKRIPSI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: AppTheme.slate800),
                decoration: const InputDecoration(
                  hintText: 'Deskripsi pengeluaran...',
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Field 3: Tanggal ---
              const Text(
                'TANGGAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.slate200, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                        color: AppTheme.slate500,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? _formatDate(_selectedDate!)
                              : 'Pilih tanggal',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Submit Button ---
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.floatingShadowRose,
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rose600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Simpan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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

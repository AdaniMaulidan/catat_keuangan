import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../repositories/bill_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class BillFormScreen extends StatefulWidget {
  final BillModel? bill; // null = tambah, non-null = edit

  const BillFormScreen({super.key, this.bill});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _repository = BillRepository();
  bool _isSaving = false;

  DateTime? _selectedDate;

  bool get _isEditMode => widget.bill != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _amountController.text =
          CurrencyFormatter.formatNumberOnly(widget.bill!.amount);
      _descriptionController.text = widget.bill!.description;
      try {
        _selectedDate = DateTime.parse(widget.bill!.dueDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
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
              primary: Color(0xFF4F46E5), // Indigo-600
              onPrimary: Colors.white,
              onSurface: AppTheme.slate800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Pilih tanggal jatuh tempo terlebih dahulu.');
      return;
    }

    final rawAmount = _amountController.text.trim();
    final amount = CurrencyFormatter.parse(rawAmount);
    if (amount == null || amount <= 0) {
      _showError('Nominal tagihan harus lebih dari 0.');
      return;
    }

    final description = _descriptionController.text.trim();

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        final updated = widget.bill!.copyWith(
          amount: amount,
          description: description,
          dueDate: _formatDate(_selectedDate!),
        );
        await _repository.updateBill(updated);
      } else {
        final newBill = BillModel(
          amount: amount,
          description: description,
          dueDate: _formatDate(_selectedDate!),
          isPaid: false,
        );
        await _repository.addBill(newBill);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal menyimpan tagihan: $e');
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
    final title = _isEditMode ? 'Edit Tagihan' : 'Tambah Tagihan';

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Field 1: Nominal ---
              const Text(
                'NOMINAL TAGIHAN',
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal tagihan tidak boleh kosong.';
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

              // --- Field 2: Deskripsi Tagihan ---
              const Text(
                'NAMA / DESKRIPSI TAGIHAN',
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
                maxLines: 2,
                style: const TextStyle(fontSize: 14, color: AppTheme.slate800),
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Listrik PLN, Internet WiFi, Cicilan Motor...',
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  contentPadding: EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi tagihan tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Field 3: Tanggal Jatuh Tempo ---
              const Text(
                'TANGGAL JATUH TEMPO',
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
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF), // Indigo-50
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Color(0xFF4F46E5), // Indigo-600
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jatuh Tempo',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.slate400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDate != null
                                  ? _formatDate(_selectedDate!)
                                  : 'Pilih tanggal',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        size: 20,
                        color: AppTheme.slate400,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Tombol Simpan ---
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? 'Menyimpan...'
                      : (_isEditMode ? 'Simpan Perubahan' : 'Simpan Tagihan'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), // Indigo primary
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

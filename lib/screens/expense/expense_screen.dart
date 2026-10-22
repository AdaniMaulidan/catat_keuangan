import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import 'expense_form_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _repository = TransactionRepository();

  // State: bulan aktif untuk filter
  late DateTime _selectedMonth;

  // State: data pengeluaran
  List<TransactionModel> _expenseList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadExpense();
  }

  // Mengambil data pengeluaran dari repository berdasarkan bulan yang dipilih.
  Future<void> _loadExpense() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getExpenseTransactionsByMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      if (mounted) {
        setState(() {
          _expenseList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Berpindah ke bulan sebelumnya
  void _onPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadExpense();
  }

  // Berpindah ke bulan berikutnya
  void _onNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadExpense();
  }

  // Navigasi ke form tambah pengeluaran.
  Future<void> _navigateToAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ExpenseFormScreen(),
      ),
    );
    if (result == true) {
      await _loadExpense();
    }
  }

  // Navigasi ke form edit pengeluaran.
  Future<void> _navigateToEdit(TransactionModel transaction) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(transaction: transaction),
      ),
    );
    if (result == true) {
      await _loadExpense();
    }
  }

  // Tampilkan dialog konfirmasi sebelum hapus.
  Future<void> _confirmDelete(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Pengeluaran',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengeluaran "${transaction.description}"?',
          style: const TextStyle(color: AppTheme.slate600, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppTheme.slate500, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteExpense(transaction);
    }
  }

  // Menjalankan penghapusan dan refresh daftar.
  Future<void> _deleteExpense(TransactionModel transaction) async {
    try {
      await _repository.deleteTransaction(transaction.id!);
      await _loadExpense();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil dihapus.'),
            backgroundColor: AppTheme.slate800,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppTheme.rose600,
          ),
        );
      }
    }
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];

    if (month < 1 || month > 12) return date;
    return '$day ${months[month]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Pengeluaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
            onPressed: _loadExpense,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.floatingShadowRose,
        ),
        child: FloatingActionButton(
          onPressed: _navigateToAdd,
          backgroundColor: AppTheme.rose500,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tooltip: 'Tambah Pengeluaran',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.rose500,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.rose500),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.slate700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadExpense,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.rose500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalExpense = _expenseList.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Column(
      children: [
        // Month Selector Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _MonthNavigator(
            selectedMonth: _selectedMonth,
            onPreviousMonth: _onPreviousMonth,
            onNextMonth: _onNextMonth,
          ),
        ),

        // Total Pengeluaran Summary Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _TotalExpenseCard(total: totalExpense),
        ),

        // List Transactions or Empty State
        Expanded(
          child: _expenseList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppTheme.rose500,
                  backgroundColor: Colors.white,
                  onRefresh: _loadExpense,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: _expenseList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _expenseList[index];
                      return _ExpenseListItem(
                        transaction: item,
                        formattedDate: _formatDate(item.date),
                        onEdit: () => _navigateToEdit(item),
                        onDelete: () => _confirmDelete(item),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    const monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final monthLabel = '${monthNames[_selectedMonth.month]} ${_selectedMonth.year}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.slate200, width: 1),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pengeluaran di $monthLabel.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tekan tombol + untuk menambah pengeluaran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Month Selector Card
// ---------------------------------------------------------------------------
class _MonthNavigator extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _MonthNavigator({
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static const _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${_monthNames[selectedMonth.month]} ${selectedMonth.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            color: AppTheme.rose500,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.rose50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Bulan sebelumnya',
            onPressed: onPreviousMonth,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.rose50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: AppTheme.rose500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            color: AppTheme.rose500,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.rose50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Bulan berikutnya',
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Total Expense Summary Card
// ---------------------------------------------------------------------------
class _TotalExpenseCard extends StatelessWidget {
  final double total;

  const _TotalExpenseCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.rose50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.rose100.withOpacity(0.5), width: 2),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              size: 26,
              color: AppTheme.rose500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PENGELUARAN',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate400,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.rose500,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Expense List Item
// ---------------------------------------------------------------------------
class _ExpenseListItem extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseListItem({
    required this.transaction,
    required this.formattedDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.rose50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: AppTheme.rose500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Description & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.slate800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- ${CurrencyFormatter.format(transaction.amount)}',
                style: const TextStyle(
                  color: AppTheme.rose500,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.slate400),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.rose500.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

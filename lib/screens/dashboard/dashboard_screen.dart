import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/calendar/transaction_calendar.dart';
import '../../widgets/charts/income_chart.dart';
import '../../widgets/charts/expense_chart.dart';
import '../income/income_screen.dart';
import '../expense/expense_screen.dart';

// Dashboard adalah halaman utama aplikasi.
// Menampilkan:
//   - Saldo, Total Pemasukan, Total Pengeluaran
//   - Kalender transaksi dengan marker income (hijau) & expense (merah)
//   - Daftar transaksi tanggal yang dipilih
//   - Grafik pemasukan 1 bulan (line chart)
//   - Grafik pengeluaran 1 bulan (line chart)
//
// Data diambil dari SQLite melalui TransactionRepository.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = TransactionRepository();

  // --- State keuangan ---
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // --- State kalender ---
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, List<TransactionModel>> _monthTransactions = {};
  List<TransactionModel> _selectedDayTransactions = [];
  bool _isCalendarLoading = false;
  String? _calendarError;

  // --- State grafik pemasukan ---
  late DateTime _chartMonth;
  List<TransactionModel> _chartMonthTransactions = [];
  Map<int, double> _incomeByDate = {};
  bool _isChartLoading = false;
  String? _chartError;

  // --- State grafik pengeluaran ---
  late DateTime _expenseChartMonth;
  List<TransactionModel> _expenseChartMonthTransactions = [];
  Map<int, double> _expenseByDate = {};
  bool _isExpenseChartLoading = false;
  String? _expenseChartError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _chartMonth = DateTime(now.year, now.month);
    _expenseChartMonth = DateTime(now.year, now.month);
    _loadAll();
  }

  // Memuat semua data sekaligus.
  Future<void> _loadAll() async {
    await Future.wait([
      _loadSummary(),
      _loadMonthData(_focusedDay),
    ]);
    
    // Load expense chart specifically if its month is different from focused day.
    // If it's the same, it's handled in _loadMonthData.
    if (_expenseChartMonth.year != _focusedDay.year ||
        _expenseChartMonth.month != _focusedDay.month) {
      await _loadExpenseChartMonthData(_expenseChartMonth);
    }
    
    // Load income chart specifically if its month is different from focused day.
    if (_chartMonth.year != _focusedDay.year ||
        _chartMonth.month != _focusedDay.month) {
      await _loadChartMonthData(_chartMonth);
    }

    if (mounted) _updateSelectedDayTransactions(_selectedDay);
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _repository.getTotalIncome(),
        _repository.getTotalExpense(),
        _repository.getBalance(),
      ]);
      if (mounted) {
        setState(() {
          _totalIncome = results[0];
          _totalExpense = results[1];
          _balance = results[2];
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

  Future<void> _loadMonthData(DateTime month) async {
    setState(() => _isCalendarLoading = true);

    final isChartMonth =
        month.year == _chartMonth.year && month.month == _chartMonth.month;
    final isExpenseChartMonth =
        month.year == _expenseChartMonth.year && month.month == _expenseChartMonth.month;

    if (isChartMonth) setState(() => _isChartLoading = true);
    if (isExpenseChartMonth) setState(() => _isExpenseChartLoading = true);

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );

      final map = <String, List<TransactionModel>>{};
      for (final t in transactions) {
        map.putIfAbsent(t.date, () => []).add(t);
      }

      if (mounted) {
        setState(() {
          _monthTransactions = map;
          _isCalendarLoading = false;
          _calendarError = null;

          if (isChartMonth) {
            _chartMonthTransactions = transactions;
            _incomeByDate = IncomeChartHelper.buildIncomeByDate(transactions);
            _isChartLoading = false;
            _chartError = null;
          }

          if (isExpenseChartMonth) {
            _expenseChartMonthTransactions = transactions;
            _expenseByDate = ExpenseChartHelper.buildExpenseByDate(transactions);
            _isExpenseChartLoading = false;
            _expenseChartError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _calendarError = 'Gagal memuat kalender: $e';
          _isCalendarLoading = false;
          if (isChartMonth) {
            _chartError = 'Gagal memuat grafik pemasukan.';
            _isChartLoading = false;
          }
          if (isExpenseChartMonth) {
            _expenseChartError = 'Gagal memuat grafik pengeluaran.';
            _isExpenseChartLoading = false;
          }
        });
      }
    }
  }

  Future<void> _loadChartMonthData(DateTime month) async {
    setState(() {
      _isChartLoading = true;
      _chartError = null;
    });

    if (month.year == _focusedDay.year && month.month == _focusedDay.month) {
      setState(() {
        _chartMonthTransactions = _monthTransactions.values
            .expand((list) => list)
            .toList();
        _incomeByDate = IncomeChartHelper.buildIncomeByDate(_chartMonthTransactions);
        _isChartLoading = false;
      });
      return;
    }

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );
      if (mounted) {
        setState(() {
          _chartMonthTransactions = transactions;
          _incomeByDate = IncomeChartHelper.buildIncomeByDate(transactions);
          _isChartLoading = false;
          _chartError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartError = 'Gagal memuat grafik pemasukan.';
          _isChartLoading = false;
        });
      }
    }
  }

  Future<void> _loadExpenseChartMonthData(DateTime month) async {
    setState(() {
      _isExpenseChartLoading = true;
      _expenseChartError = null;
    });

    if (month.year == _focusedDay.year && month.month == _focusedDay.month) {
      setState(() {
        _expenseChartMonthTransactions = _monthTransactions.values
            .expand((list) => list)
            .toList();
        _expenseByDate = ExpenseChartHelper.buildExpenseByDate(_expenseChartMonthTransactions);
        _isExpenseChartLoading = false;
      });
      return;
    }

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );
      if (mounted) {
        setState(() {
          _expenseChartMonthTransactions = transactions;
          _expenseByDate = ExpenseChartHelper.buildExpenseByDate(transactions);
          _isExpenseChartLoading = false;
          _expenseChartError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expenseChartError = 'Gagal memuat grafik pengeluaran.';
          _isExpenseChartLoading = false;
        });
      }
    }
  }

  void _updateSelectedDayTransactions(DateTime day) {
    final key = _toDateKey(day);
    setState(() {
      _selectedDayTransactions = _monthTransactions[key] ?? [];
    });
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    _updateSelectedDayTransactions(selected);
  }

  Future<void> _onPageChanged(DateTime focused) async {
    setState(() => _focusedDay = focused);
    await _loadMonthData(focused);
    if (mounted) _updateSelectedDayTransactions(_selectedDay);
  }

  void _onChartPreviousMonth() {
    final prev = DateTime(_chartMonth.year, _chartMonth.month - 1);
    setState(() => _chartMonth = prev);
    _loadChartMonthData(prev);
  }

  void _onChartNextMonth() {
    final next = DateTime(_chartMonth.year, _chartMonth.month + 1);
    setState(() => _chartMonth = next);
    _loadChartMonthData(next);
  }

  void _onExpenseChartPreviousMonth() {
    final prev = DateTime(_expenseChartMonth.year, _expenseChartMonth.month - 1);
    setState(() => _expenseChartMonth = prev);
    _loadExpenseChartMonthData(prev);
  }

  void _onExpenseChartNextMonth() {
    final next = DateTime(_expenseChartMonth.year, _expenseChartMonth.month + 1);
    setState(() => _expenseChartMonth = next);
    _loadExpenseChartMonthData(next);
  }

  Future<void> _goToIncome() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncomeScreen()),
    );
    await _loadAll();
  }

  Future<void> _goToExpense() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
    );
    await _loadAll();
  }

  static String _toDateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('AyoHemat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await _loadAll();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAll();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Card Saldo ---
            _BalanceCard(balance: _balance),
            const SizedBox(height: 16),

            // --- Row: Pemasukan + Pengeluaran ---
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Pemasukan',
                    amount: _totalIncome,
                    color: Colors.green.shade600,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Pengeluaran',
                    amount: _totalExpense,
                    color: Colors.red.shade600,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Section Kalender ---
            _sectionHeader('Kalender Transaksi'),
            const SizedBox(height: 8),

            if (_isCalendarLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_calendarError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _calendarError!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else ...[
              TransactionCalendar(
                monthTransactions: _monthTransactions,
                selectedDay: _selectedDay,
                focusedDay: _focusedDay,
                onDaySelected: _onDaySelected,
                onPageChanged: _onPageChanged,
              ),
              const SizedBox(height: 16),
              SelectedDayTransactionList(
                selectedDay: _selectedDay,
                transactions: _selectedDayTransactions,
                isLoading: false,
              ),
            ],

            const SizedBox(height: 20),

            // --- Section Grafik Pemasukan ---
            _sectionHeader('Grafik Pemasukan'),
            const SizedBox(height: 8),

            IncomeChart(
              incomeByDate: _incomeByDate,
              year: _chartMonth.year,
              month: _chartMonth.month,
              onPreviousMonth: _onChartPreviousMonth,
              onNextMonth: _onChartNextMonth,
              isLoading: _isChartLoading,
              errorMessage: _chartError,
            ),

            const SizedBox(height: 20),

            // --- Section Grafik Pengeluaran ---
            _sectionHeader('Grafik Pengeluaran'),
            const SizedBox(height: 8),

            ExpenseChart(
              expenseByDate: _expenseByDate,
              year: _expenseChartMonth.year,
              month: _expenseChartMonth.month,
              onPreviousMonth: _onExpenseChartPreviousMonth,
              onNextMonth: _onExpenseChartNextMonth,
              isLoading: _isExpenseChartLoading,
              errorMessage: _expenseChartError,
            ),

            const SizedBox(height: 20),

            // --- Section Menu ---
            _sectionHeader('Menu'),
            const SizedBox(height: 8),

            _MenuButton(
              label: 'Pemasukan',
              subtitle: 'Tambah & kelola pemasukan',
              icon: Icons.arrow_downward_rounded,
              color: Colors.green.shade600,
              onTap: _goToIncome,
            ),
            const SizedBox(height: 12),

            _MenuButton(
              label: 'Pengeluaran',
              subtitle: 'Tambah & kelola pengeluaran',
              icon: Icons.arrow_upward_rounded,
              color: Colors.red.shade600,
              onTap: _goToExpense,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Card Saldo
// ---------------------------------------------------------------------------
class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final displayAmount = isNegative
        ? '-${CurrencyFormatter.format(balance.abs())}'
        : CurrencyFormatter.format(balance);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text(
                  'Saldo',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              displayAmount,
              style: TextStyle(
                color: isNegative ? Colors.red.shade700 : Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (isNegative) ...[
              const SizedBox(height: 4),
              Text(
                'Pengeluaran melebihi pemasukan',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Card ringkasan
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Tombol menu
// ---------------------------------------------------------------------------
class _MenuButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}

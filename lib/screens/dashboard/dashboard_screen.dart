import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/calendar/transaction_calendar.dart';
import '../../widgets/charts/income_chart.dart';
import '../income/income_screen.dart';
import '../expense/expense_screen.dart';

// Dashboard adalah halaman utama aplikasi.
// Menampilkan:
//   - Saldo, Total Pemasukan, Total Pengeluaran
//   - Kalender transaksi dengan marker income (hijau) & expense (merah)
//   - Daftar transaksi tanggal yang dipilih
//   - Grafik pemasukan 1 bulan (line chart)
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
  // Bulan yang sedang ditampilkan grafik (independent dari kalender).
  late DateTime _chartMonth;
  // Data transaksi bulan grafik — di-share dengan kalender jika bulan sama.
  List<TransactionModel> _chartMonthTransactions = [];
  Map<int, double> _incomeByDate = {};
  bool _isChartLoading = false;
  String? _chartError;

  @override
  void initState() {
    super.initState();
    _chartMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadAll();
  }

  // Memuat semua data sekaligus.
  Future<void> _loadAll() async {
    await Future.wait([
      _loadSummary(),
      _loadMonthData(_focusedDay),
    ]);
    if (mounted) _updateSelectedDayTransactions(_selectedDay);
  }

  // Mengambil ringkasan keuangan.
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

  // Mengambil transaksi satu bulan — dipakai oleh kalender DAN grafik.
  // Jika bulan kalender == bulan grafik, query cukup sekali.
  Future<void> _loadMonthData(DateTime month) async {
    setState(() => _isCalendarLoading = true);

    final isChartMonth =
        month.year == _chartMonth.year && month.month == _chartMonth.month;
    if (isChartMonth) setState(() => _isChartLoading = true);

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );

      // Kelompokkan untuk kalender.
      final map = <String, List<TransactionModel>>{};
      for (final t in transactions) {
        map.putIfAbsent(t.date, () => []).add(t);
      }

      if (mounted) {
        setState(() {
          _monthTransactions = map;
          _isCalendarLoading = false;
          _calendarError = null;

          // Jika bulan ini juga bulan grafik, update data grafik sekaligus.
          if (isChartMonth) {
            _chartMonthTransactions = transactions;
            _incomeByDate =
                IncomeChartHelper.buildIncomeByDate(transactions);
            _isChartLoading = false;
            _chartError = null;
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
        });
      }
    }
  }

  // Mengambil data khusus untuk grafik (bulan berbeda dari kalender).
  Future<void> _loadChartMonthData(DateTime month) async {
    setState(() {
      _isChartLoading = true;
      _chartError = null;
    });

    // Jika bulan grafik = bulan kalender, reuse data yang sudah ada.
    if (month.year == _focusedDay.year &&
        month.month == _focusedDay.month) {
      setState(() {
        _chartMonthTransactions = _monthTransactions.values
            .expand((list) => list)
            .toList();
        _incomeByDate =
            IncomeChartHelper.buildIncomeByDate(_chartMonthTransactions);
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
          _incomeByDate =
              IncomeChartHelper.buildIncomeByDate(transactions);
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

  // --- Navigasi bulan grafik ---
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

  Future<void> _goToIncome() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncomeScreen()),
    );
    await _loadAll();
    // Refresh grafik jika bulan grafik sama dengan bulan kalender saat ini.
    await _loadChartMonthData(_chartMonth);
  }

  Future<void> _goToExpense() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
    );
    await _loadAll();
    await _loadChartMonthData(_chartMonth);
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
        title: const Text('Catat Keuangan'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await _loadAll();
              await _loadChartMonthData(_chartMonth);
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
        await _loadChartMonthData(_chartMonth);
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade700,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.white.withOpacity(0.85), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Saldo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
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
                color: isNegative ? Colors.red.shade200 : Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (isNegative) ...[
              const SizedBox(height: 4),
              Text(
                'Pengeluaran melebihi pemasukan',
                style: TextStyle(color: Colors.red.shade200, fontSize: 12),
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

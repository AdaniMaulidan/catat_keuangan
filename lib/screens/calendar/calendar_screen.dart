import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/calendar/transaction_calendar.dart';
import '../income/income_form_screen.dart';
import '../expense/expense_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repository = TransactionRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, List<TransactionModel>> _monthTransactions = {};
  List<TransactionModel> _selectedDayTransactions = [];
  bool _isCalendarLoading = false;
  String? _calendarError;

  @override
  void initState() {
    super.initState();
    _loadMonthData(_focusedDay);
  }

  Future<void> _loadMonthData(DateTime month) async {
    setState(() => _isCalendarLoading = true);
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
        });
        _updateSelectedDayTransactions(_selectedDay);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _calendarError = 'Gagal memuat kalender: $e';
          _isCalendarLoading = false;
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
  }

  static String _toDateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<void> _navigateToAddIncome() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IncomeFormScreen(initialDate: _selectedDay),
      ),
    );
    if (result == true) {
      await _loadMonthData(_focusedDay);
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(initialDate: _selectedDay),
      ),
    );
    if (result == true) {
      await _loadMonthData(_focusedDay);
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToAddIncome,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Tambah Pemasukan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToAddExpense,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Tambah Pengeluaran',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.emerald50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.emerald200.withOpacity(0.6), width: 1),
              ),
              child: const Text(
                'AyoHemat',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emerald700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.emerald600,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await _loadMonthData(_focusedDay);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isCalendarLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(color: AppTheme.emerald600, strokeWidth: 2.5),
                  ),
                )
              else if (_calendarError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _calendarError!,
                    style: const TextStyle(color: AppTheme.rose600),
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
                _buildActionButtons(),
                const SizedBox(height: 10),
                SelectedDayTransactionList(
                  selectedDay: _selectedDay,
                  transactions: _selectedDayTransactions,
                  isLoading: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

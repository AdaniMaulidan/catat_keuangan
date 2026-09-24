import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/calendar/transaction_calendar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Kalender'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMonthData(_focusedDay);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }
}

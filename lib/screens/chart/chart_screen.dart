import 'package:flutter/material.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/charts/income_chart.dart';
import '../../widgets/charts/expense_chart.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final _repository = TransactionRepository();

  // --- State grafik pemasukan ---
  late DateTime _chartMonth;
  Map<int, double> _incomeByDate = {};
  bool _isChartLoading = false;
  String? _chartError;

  // --- State grafik pengeluaran ---
  late DateTime _expenseChartMonth;
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

  Future<void> _loadAll() async {
    await Future.wait([
      _loadChartMonthData(_chartMonth),
      _loadExpenseChartMonthData(_expenseChartMonth),
    ]);
  }

  Future<void> _loadChartMonthData(DateTime month) async {
    setState(() {
      _isChartLoading = true;
      _chartError = null;
    });

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );
      if (mounted) {
        setState(() {
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

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );
      if (mounted) {
        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Grafik'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }
}

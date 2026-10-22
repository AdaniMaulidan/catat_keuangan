import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/income_chart.dart';
import '../../widgets/charts/expense_chart.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final _repository = TransactionRepository();

  // --- State grafik komposisi kategori ---
  late DateTime _pieChartMonth;
  List<TransactionModel> _pieChartTransactions = [];
  bool _isPieChartLoading = false;
  String? _pieChartError;

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
    _pieChartMonth = DateTime(now.year, now.month);
    _chartMonth = DateTime(now.year, now.month);
    _expenseChartMonth = DateTime(now.year, now.month);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadPieChartMonthData(_pieChartMonth),
      _loadChartMonthData(_chartMonth),
      _loadExpenseChartMonthData(_expenseChartMonth),
    ]);
  }

  Future<void> _loadPieChartMonthData(DateTime month) async {
    setState(() {
      _isPieChartLoading = true;
      _pieChartError = null;
    });

    try {
      final transactions = await _repository.getTransactionsByMonth(
        month.year,
        month.month,
      );
      if (mounted) {
        setState(() {
          _pieChartTransactions = transactions;
          _isPieChartLoading = false;
          _pieChartError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pieChartError = 'Gagal memuat komposisi kategori.';
          _isPieChartLoading = false;
        });
      }
    }
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

  void _onPieChartPreviousMonth() {
    final prev = DateTime(_pieChartMonth.year, _pieChartMonth.month - 1);
    setState(() => _pieChartMonth = prev);
    _loadPieChartMonthData(prev);
  }

  void _onPieChartNextMonth() {
    final next = DateTime(_pieChartMonth.year, _pieChartMonth.month + 1);
    setState(() => _pieChartMonth = next);
    _loadPieChartMonthData(next);
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
        const Expanded(child: Divider(color: AppTheme.slate200, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate400,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.slate200, thickness: 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Grafik'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.emerald50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.emerald200.withOpacity(0.5), width: 1),
              ),
              child: const Text(
                'Bulanan',
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
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('KOMPOSISI KATEGORI'),
              const SizedBox(height: 12),
              CategoryPieChart(
                transactions: _pieChartTransactions,
                year: _pieChartMonth.year,
                month: _pieChartMonth.month,
                onPreviousMonth: _onPieChartPreviousMonth,
                onNextMonth: _onPieChartNextMonth,
                isLoading: _isPieChartLoading,
                errorMessage: _pieChartError,
              ),
              const SizedBox(height: 24),
              _sectionHeader('GRAFIK PEMASUKAN'),
              const SizedBox(height: 12),
              IncomeChart(
                incomeByDate: _incomeByDate,
                year: _chartMonth.year,
                month: _chartMonth.month,
                onPreviousMonth: _onChartPreviousMonth,
                onNextMonth: _onChartNextMonth,
                isLoading: _isChartLoading,
                errorMessage: _chartError,
              ),
              const SizedBox(height: 24),
              _sectionHeader('GRAFIK PENGELUARAN'),
              const SizedBox(height: 12),
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

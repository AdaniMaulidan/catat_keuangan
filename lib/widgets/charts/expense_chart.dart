import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class ExpenseChart extends StatefulWidget {
  final Map<int, double> expenseByDate;
  final int year;
  final int month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool isLoading;
  final String? errorMessage;

  const ExpenseChart({
    super.key,
    required this.expenseByDate,
    required this.year,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  static const _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _formatAxisLabel(double value) {
    if (value == 0) return '0';
    if (value >= 1000000) {
      final jt = value / 1000000;
      return '${jt % 1 == 0 ? jt.toInt() : jt.toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      final rb = value / 1000;
      return '${rb % 1 == 0 ? rb.toInt() : rb.toStringAsFixed(0)} rb';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 18),
          _buildChartContent(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final monthLabel = '${_monthNames[widget.month]} ${widget.year}';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.rose50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.trending_down_rounded,
            size: 20,
            color: AppTheme.rose500,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Pengeluaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
        ),
        // Month Pill Navigator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.slate200, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                color: AppTheme.slate500,
                onPressed: widget.onPreviousMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Bulan sebelumnya',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                color: AppTheme.slate500,
                onPressed: widget.onNextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Bulan berikutnya',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.rose500, strokeWidth: 2.5),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            widget.errorMessage!,
            style: const TextStyle(color: AppTheme.rose600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final hasData = widget.expenseByDate.values.any((v) => v > 0);
    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.slate200, width: 1),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 28,
                  color: AppTheme.slate400,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum ada pengeluaran pada bulan ini.',
                style: TextStyle(color: AppTheme.slate500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildLineChart();
  }

  Widget _buildLineChart() {
    final days = _daysInMonth(widget.year, widget.month);
    final maxY = widget.expenseByDate.values.fold(0.0, (a, b) => a > b ? a : b);
    final chartMaxY = (maxY * 1.25) > 0 ? (maxY * 1.25) : 100000.0;

    final spots = List.generate(days, (i) {
      final day = i + 1;
      final amount = widget.expenseByDate[day] ?? 0.0;
      return FlSpot(day.toDouble(), amount);
    });

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.slate900,
              tooltipRoundedRadius: 10,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final day = spot.x.toInt();
                  final amount = spot.y;
                  return LineTooltipItem(
                    '$day ${_monthNames[widget.month]}\n',
                    const TextStyle(
                      color: AppTheme.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: CurrencyFormatter.format(amount),
                        style: const TextStyle(
                          color: AppTheme.rose400,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4 > 0 ? chartMaxY / 4 : 25000,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppTheme.slate100,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatAxisLabel(value),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slate400,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day == 1 || day % 5 == 0) {
                    return Text(
                      '$day',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate400,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 1,
          maxX: days.toDouble(),
          minY: 0,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppTheme.rose500,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (spot.y > 0) {
                    return FlDotCirclePainter(
                      radius: 3.5,
                      color: AppTheme.rose500,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(radius: 0);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.rose500.withOpacity(0.2),
                    AppTheme.rose500.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseChartHelper {
  ExpenseChartHelper._();

  static Map<int, double> buildExpenseByDate(List<TransactionModel> transactions) {
    final map = <int, double>{};
    for (final t in transactions) {
      if (!t.isExpense) continue;
      try {
        final dt = DateTime.parse(t.date);
        map[dt.day] = (map[dt.day] ?? 0.0) + t.amount;
      } catch (_) {}
    }
    return map;
  }
}

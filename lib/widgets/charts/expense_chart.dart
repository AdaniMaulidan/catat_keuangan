import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';

// Widget grafik pengeluaran bulanan.
//
// Menampilkan line chart pengeluaran per tanggal dalam satu bulan.
// Data di-supply dari luar (dari DashboardScreen) — widget ini tidak query DB.
class ExpenseChart extends StatefulWidget {
  final Map<int, double> expenseByDate; // key: tanggal (1-31), value: total
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthHeader(),
            const SizedBox(height: 16),
            _buildChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    final monthLabel =
        '${_monthNames[widget.month]} ${widget.year}';

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.red.shade100,
          child: Icon(Icons.trending_down,
              size: 16, color: Colors.red.shade700),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pengeluaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.red.shade700),
          onPressed: widget.onPreviousMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Bulan sebelumnya',
        ),
        Text(
          monthLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: Colors.red.shade700),
          onPressed: widget.onNextMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Bulan berikutnya',
        ),
      ],
    );
  }

  Widget _buildChartContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.errorMessage != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            widget.errorMessage!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final hasData = widget.expenseByDate.values.any((v) => v > 0);
    if (!hasData) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 36, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'Belum ada pengeluaran pada bulan ini.',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
    final chartMaxY = maxY * 1.2;

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
              getTooltipColor: (_) => Colors.red.shade800,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final day = spot.x.toInt();
                  final amount = spot.y;
                  return LineTooltipItem(
                    '$day ${_monthNames[widget.month]}\n'
                    '${CurrencyFormatter.format(amount)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          minX: 1,
          maxX: days.toDouble(),
          minY: 0,
          maxY: chartMaxY == 0 ? 1 : chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: chartMaxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatAxisLabel(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
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
                reservedSize: 24,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day == 1 || day % 5 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.red.shade600,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot.y > 0,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red.shade600,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400.withOpacity(0.3),
                    Colors.red.shade100.withOpacity(0.05),
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

  static Map<int, double> buildExpenseByDate(
      List<TransactionModel> monthTransactions) {
    final map = <int, double>{};
    for (final t in monthTransactions) {
      if (!t.isExpense) continue;
      final parts = t.date.split('-');
      if (parts.length != 3) continue;
      final day = int.tryParse(parts[2]);
      if (day == null) continue;
      map[day] = (map[day] ?? 0) + t.amount;
    }
    return map;
  }
}

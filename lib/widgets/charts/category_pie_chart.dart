import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

/// Data representasi satu slice / kategori pada Donut Chart
class CategorySliceData {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  CategorySliceData({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class CategoryPieChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final int year;
  final int month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool isLoading;
  final String? errorMessage;

  const CategoryPieChart({
    super.key,
    required this.transactions,
    required this.year,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  String _selectedType = TransactionModel.expense; // default pengeluaran sesuai acuan
  int _touchedIndex = -1;

  static const _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  // Palet warna modern kontras untuk slice kategori
  static const List<Color> _palette = [
    Color(0xFFEAB308), // Amber / Emas (Makanan di referensi)
    Color(0xFF0EA5E9), // Sky Blue (Hiburan di referensi)
    Color(0xFFF43F5E), // Rose (Bensin di referensi)
    Color(0xFF10B981), // Emerald (Cukur Rambut di referensi)
    Color(0xFF8B5CF6), // Ungu Violet
    Color(0xFFF97316), // Oranye
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
  ];

  static const Color _otherColor = Color(0xFF64748B); // Slate-500 untuk 'Lainnya'

  List<CategorySliceData> _computeSlices(List<TransactionModel> transactions, String type) {
    final filtered = transactions.where((t) => t.type == type).toList();
    if (filtered.isEmpty) return [];

    final Map<String, double> map = {};
    double grandTotal = 0;

    for (final t in filtered) {
      final raw = t.description.trim();
      final key = raw.isEmpty ? 'Tanpa Keterangan' : raw;
      final normalized = key[0].toUpperCase() + key.substring(1);
      map[normalized] = (map[normalized] ?? 0) + t.amount;
      grandTotal += t.amount;
    }

    if (grandTotal <= 0) return [];

    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<CategorySliceData> result = [];
    const maxMainCategories = 5;

    if (entries.length <= maxMainCategories) {
      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        final pct = (e.value / grandTotal) * 100;
        final color = _palette[i % _palette.length];
        result.add(CategorySliceData(
          name: e.key,
          amount: e.value,
          percentage: pct,
          color: color,
        ));
      }
    } else {
      // 4 kategori teratas individual, sisanya digabung jadi 'Lainnya'
      for (int i = 0; i < 4; i++) {
        final e = entries[i];
        final pct = (e.value / grandTotal) * 100;
        final color = _palette[i % _palette.length];
        result.add(CategorySliceData(
          name: e.key,
          amount: e.value,
          percentage: pct,
          color: color,
        ));
      }

      double otherTotal = 0;
      for (int i = 4; i < entries.length; i++) {
        otherTotal += entries[i].value;
      }

      if (otherTotal > 0) {
        final otherPct = (otherTotal / grandTotal) * 100;
        result.add(CategorySliceData(
          name: 'Lainnya',
          amount: otherTotal,
          percentage: otherPct,
          color: _otherColor,
        ));
      }
    }

    return result;
  }

  String _formatPercentage(double pct) {
    return '${pct.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthNames[widget.month]} ${widget.year}';
    final slices = _computeSlices(widget.transactions, _selectedType);
    final totalAmount = slices.fold<double>(0, (sum, s) => sum + s.amount);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card: Title + Month Navigator
          _buildHeader(monthLabel),
          const SizedBox(height: 16),

          // Toggle Pill: Pengeluaran vs Pemasukan
          _buildTypeToggle(),
          const SizedBox(height: 20),

          // Content: Loading, Error, Empty, or Donut Chart + Legend
          _buildBody(slices, totalAmount, monthLabel),
        ],
      ),
    );
  }

  Widget _buildHeader(String monthLabel) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _selectedType == TransactionModel.expense
                ? AppTheme.rose50
                : AppTheme.emerald50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.pie_chart_rounded,
            size: 20,
            color: _selectedType == TransactionModel.expense
                ? AppTheme.rose600
                : AppTheme.emerald600,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Komposisi Kategori',
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

  Widget _buildTypeToggle() {
    final isExpense = _selectedType == TransactionModel.expense;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200, width: 0.8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          // Option: Pengeluaran
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isExpense) {
                  setState(() {
                    _selectedType = TransactionModel.expense;
                    _touchedIndex = -1;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isExpense ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isExpense
                      ? [
                          BoxShadow(
                            color: AppTheme.rose500.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: isExpense ? AppTheme.rose600 : AppTheme.slate500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pengeluaran',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isExpense ? FontWeight.w700 : FontWeight.w500,
                        color: isExpense ? AppTheme.rose600 : AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Option: Pemasukan
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isExpense) {
                  setState(() {
                    _selectedType = TransactionModel.income;
                    _touchedIndex = -1;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isExpense ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: !isExpense
                      ? [
                          BoxShadow(
                            color: AppTheme.emerald600.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: !isExpense ? AppTheme.emerald600 : AppTheme.slate500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pemasukan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !isExpense ? FontWeight.w700 : FontWeight.w500,
                        color: !isExpense ? AppTheme.emerald700 : AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<CategorySliceData> slices, double totalAmount, String monthLabel) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.emerald600,
          ),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.rose500, size: 28),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
            ),
          ],
        ),
      );
    }

    if (slices.isEmpty || totalAmount <= 0) {
      final isExpense = _selectedType == TransactionModel.expense;
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.slate200, width: 0.8),
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                size: 26,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada ${isExpense ? 'pengeluaran' : 'pemasukan'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tidak ada transaksi di bulan $monthLabel.',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.slate400,
              ),
            ),
          ],
        ),
      );
    }

    // Chart + Legend View
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Donut Chart with center total amount
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2.5,
                  centerSpaceRadius: 40,
                  sections: List.generate(slices.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final radius = isTouched ? 22.0 : 17.0;
                    final slice = slices[i];
                    return PieChartSectionData(
                      color: slice.color,
                      value: slice.amount,
                      title: '', // Tanpa teks di irisan chart agar tetap bersih
                      radius: radius,
                    );
                  }),
                ),
              ),
              // Inside Center Hole: Total Nominal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate400,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatNumberOnly(totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Vertical Legend List
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: slices.asMap().entries.map((entry) {
              final idx = entry.key;
              final slice = entry.value;
              final isTouched = idx == _touchedIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.5),
                child: Row(
                  children: [
                    // Ring / Circle Indicator (sesuai gambar referensi)
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slice.color.withOpacity(0.18),
                        border: Border.all(
                          color: slice.color,
                          width: 3.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category Name
                    Expanded(
                      child: Text(
                        slice.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isTouched ? FontWeight.w700 : FontWeight.w600,
                          color: isTouched ? AppTheme.slate900 : AppTheme.slate700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Percentage
                    Text(
                      _formatPercentage(slice.percentage),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isTouched ? slice.color : AppTheme.slate800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

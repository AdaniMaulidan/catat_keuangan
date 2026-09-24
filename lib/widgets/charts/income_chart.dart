import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';

// Widget grafik pemasukan bulanan.
//
// Menampilkan line chart pemasukan per tanggal dalam satu bulan.
// Data di-supply dari luar (dari DashboardScreen) — widget ini tidak query DB.
//
// Menerima:
//   - [incomeByDate]: total pemasukan per tanggal, key: nomor tanggal (1-31).
//   - [year]: tahun bulan yang ditampilkan.
//   - [month]: bulan yang ditampilkan (1-12).
//   - [onPreviousMonth]: callback tombol bulan sebelumnya.
//   - [onNextMonth]: callback tombol bulan berikutnya.
//   - [isLoading]: menampilkan loading indicator.
//   - [errorMessage]: menampilkan pesan error jika ada.
class IncomeChart extends StatefulWidget {
  final Map<int, double> incomeByDate; // key: tanggal (1-31), value: total
  final int year;
  final int month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool isLoading;
  final String? errorMessage;

  const IncomeChart({
    super.key,
    required this.incomeByDate,
    required this.year,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<IncomeChart> createState() => _IncomeChartState();
}

class _IncomeChartState extends State<IncomeChart> {
  // Nama bulan dalam bahasa Indonesia.
  static const _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // Jumlah hari dalam bulan tertentu.
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Memformat nominal besar menjadi singkatan ringkas untuk label sumbu Y.
  // Contoh: 5000000 → '5 jt', 500000 → '500 rb', 25000 → '25 rb'
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
            // --- Header: navigasi bulan ---
            _buildMonthHeader(),
            const SizedBox(height: 16),

            // --- Konten grafik ---
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
        // Ikon pemasukan
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.trending_up,
              size: 16, color: Colors.green.shade700),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pemasukan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        // Tombol bulan sebelumnya
        IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.green.shade700),
          onPressed: widget.onPreviousMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Bulan sebelumnya',
        ),
        // Label bulan
        Text(
          monthLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        // Tombol bulan berikutnya
        IconButton(
          icon: Icon(Icons.chevron_right, color: Colors.green.shade700),
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

    // Cek apakah ada data pemasukan di bulan ini.
    final hasData = widget.incomeByDate.values.any((v) => v > 0);
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
                'Belum ada pemasukan pada bulan ini.',
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
    final maxY = widget.incomeByDate.values.fold(0.0, (a, b) => a > b ? a : b);
    // Beri ruang 20% di atas maksimum agar titik tidak terpotong.
    final chartMaxY = maxY * 1.2;

    // Bangun spots: satu titik per hari dalam bulan.
    final spots = List.generate(days, (i) {
      final day = i + 1;
      final amount = widget.incomeByDate[day] ?? 0.0;
      return FlSpot(day.toDouble(), amount);
    });

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          // --- Sentuhan/tooltip ---
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.green.shade800,
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

          // --- Rentang sumbu ---
          minX: 1,
          maxX: days.toDouble(),
          minY: 0,
          maxY: chartMaxY == 0 ? 1 : chartMaxY,

          // --- Grid ---
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMaxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),

          // --- Border ---
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),

          // --- Sumbu X ---
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
                // Tampilkan label tiap 5 hari: 1, 5, 10, 15, 20, 25, 30
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

          // --- Data garis ---
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.green.shade600,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot.y > 0,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green.shade600,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              // Area di bawah garis — gradien hijau transparan
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400.withOpacity(0.3),
                    Colors.green.shade100.withOpacity(0.05),
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

// ---------------------------------------------------------------------------
// Helper: konversi List<TransactionModel> bulan ke Map<int, double>
// (tanggal → total income).
// Digunakan oleh DashboardScreen untuk menyiapkan data sebelum dikirim
// ke IncomeChart.
// ---------------------------------------------------------------------------
class IncomeChartHelper {
  IncomeChartHelper._();

  /// Mengambil transaksi bulan dan mengelompokkan total income per tanggal.
  /// Hanya menghitung transaksi dengan [type == TransactionModel.income].
  /// Mengembalikan Map<int, double> dimana key = hari (1-31).
  static Map<int, double> buildIncomeByDate(
      List<TransactionModel> monthTransactions) {
    final map = <int, double>{};
    for (final t in monthTransactions) {
      if (!t.isIncome) continue;
      // Ambil nomor hari dari string 'YYYY-MM-DD'.
      final parts = t.date.split('-');
      if (parts.length != 3) continue;
      final day = int.tryParse(parts[2]);
      if (day == null) continue;
      map[day] = (map[day] ?? 0) + t.amount;
    }
    return map;
  }
}

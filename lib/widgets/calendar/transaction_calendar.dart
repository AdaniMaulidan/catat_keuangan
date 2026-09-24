import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';

// Widget kalender transaksi.
//
// Menerima:
//   - [monthTransactions]: semua transaksi dalam bulan aktif (dari repository),
//     sudah dikelompokkan berdasarkan tanggal 'YYYY-MM-DD'.
//   - [selectedDay]: tanggal yang sedang dipilih.
//   - [focusedDay]: tanggal yang sedang di-focus (digunakan table_calendar
//     untuk navigasi bulan).
//   - [onDaySelected]: callback saat user memilih tanggal.
//   - [onPageChanged]: callback saat user berpindah bulan.
//
// Widget ini TIDAK melakukan query ke database.
// Semua data disupply dari luar (dari DashboardScreen).
class TransactionCalendar extends StatelessWidget {
  final Map<String, List<TransactionModel>> monthTransactions;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  const TransactionCalendar({
    super.key,
    required this.monthTransactions,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  // Mengambil list transaksi untuk tanggal tertentu dari map.
  List<TransactionModel> _getTransactionsForDay(DateTime day) {
    final key = _toDateKey(day);
    return monthTransactions[key] ?? [];
  }

  // Mengubah DateTime ke string key 'YYYY-MM-DD'.
  static String _toDateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TableCalendar<TransactionModel>(
          locale: 'id_ID',
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: _getTransactionsForDay,
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
          // Sembunyikan baris yang tidak perlu agar kalender kompak
          rowHeight: 48,
          daysOfWeekHeight: 28,
          calendarStyle: CalendarStyle(
            // Gaya tanggal terpilih
            selectedDecoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            // Gaya tanggal hari ini (saat tidak dipilih)
            todayDecoration: BoxDecoration(
              color: Colors.green.shade200,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: Colors.green.shade900,
              fontWeight: FontWeight.bold,
            ),
            // Marker dot — akan dioverride oleh markerBuilder
            markersMaxCount: 2,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            leftChevronIcon: Icon(Icons.chevron_left,
                color: Colors.green.shade700),
            rightChevronIcon: Icon(Icons.chevron_right,
                color: Colors.green.shade700),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            weekendStyle: TextStyle(
              fontSize: 12,
              color: Colors.red.shade400,
            ),
          ),
          // Marker custom: dot hijau untuk income, merah untuk expense
          calendarBuilders: CalendarBuilders<TransactionModel>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();

              final hasIncome = events.any((e) => e.isIncome);
              final hasExpense = events.any((e) => e.isExpense);

              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasIncome) _dot(Colors.green.shade600),
                    if (hasIncome && hasExpense)
                      const SizedBox(width: 2),
                    if (hasExpense) _dot(Colors.red.shade600),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget daftar transaksi untuk tanggal yang dipilih.
// Ditampilkan di bawah kalender pada Dashboard.
// ---------------------------------------------------------------------------
class SelectedDayTransactionList extends StatelessWidget {
  final DateTime selectedDay;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? errorMessage;

  const SelectedDayTransactionList({
    super.key,
    required this.selectedDay,
    required this.transactions,
    required this.isLoading,
    this.errorMessage,
  });

  String _formatDate(DateTime date) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header tanggal terpilih
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _formatDate(selectedDay),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          )
        else if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Tidak ada transaksi pada tanggal ini.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          )
        else
          ...transactions.map((t) => _TransactionItem(transaction: t)),
      ],
    );
  }
}

// Item transaksi dalam daftar tanggal terpilih.
class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green.shade600 : Colors.red.shade600;
    final prefix = isIncome ? '+' : '-';
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.07),
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, size: 16, color: color),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '$prefix ${CurrencyFormatter.format(transaction.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

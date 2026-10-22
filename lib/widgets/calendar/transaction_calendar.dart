import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

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

  List<TransactionModel> _getTransactionsForDay(DateTime day) {
    final key = _toDateKey(day);
    return monthTransactions[key] ?? [];
  }

  static String _toDateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: TableCalendar<TransactionModel>(
        locale: 'id_ID',
        firstDay: DateTime(2020),
        lastDay: DateTime(2100),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: _getTransactionsForDay,
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        rowHeight: 46,
        daysOfWeekHeight: 32,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.slate700,
          ),
          weekendTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.rose500,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.emerald600,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33059669),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.emerald100,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: AppTheme.emerald800,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          markersMaxCount: 2,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.slate800,
            letterSpacing: -0.2,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppTheme.emerald600,
            size: 22,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.emerald600,
            size: 22,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate500,
          ),
          weekendStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.rose500,
          ),
        ),
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
                  if (hasIncome) _dot(AppTheme.emerald500),
                  if (hasIncome && hasExpense) const SizedBox(width: 2.5),
                  if (hasExpense) _dot(AppTheme.rose500),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 5.5,
      height: 5.5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Selected Day Transaction List
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
        // Date Header
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Text(
            _formatDate(selectedDay),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
              letterSpacing: -0.2,
            ),
          ),
        ),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppTheme.emerald600, strokeWidth: 2.5),
            ),
          )
        else if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppTheme.rose600, fontSize: 13),
            ),
          )
        else if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.slate200, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 22,
                    color: AppTheme.slate400,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tidak ada transaksi pada tanggal ini.',
                  style: TextStyle(color: AppTheme.slate400, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...transactions.map((t) => _TransactionItem(transaction: t)),
      ],
    );
  }
}

// Item transaksi dalam daftar tanggal terpilih
class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final badgeBg = isIncome ? AppTheme.emerald50 : AppTheme.rose50;
    final color = isIncome ? AppTheme.emerald600 : AppTheme.rose500;
    final prefix = isIncome ? '+' : '-';
    final icon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$prefix ${CurrencyFormatter.format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../repositories/transaction_repository.dart';
import '../../utils/currency_formatter.dart';
import '../income/income_screen.dart';
import '../expense/expense_screen.dart';

// Dashboard adalah halaman utama aplikasi.
// Menampilkan ringkasan keuangan: saldo, total pemasukan, total pengeluaran.
// Data diambil dari SQLite melalui TransactionRepository.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = TransactionRepository();

  // State keuangan
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  // Mengambil ringkasan keuangan dari repository.
  // Dipanggil saat pertama kali masuk dan setiap kali kembali dari CRUD.
  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ambil ketiga nilai secara bersamaan untuk efisiensi.
      final results = await Future.wait([
        _repository.getTotalIncome(),
        _repository.getTotalExpense(),
        _repository.getBalance(),
      ]);

      if (mounted) {
        setState(() {
          _totalIncome = results[0];
          _totalExpense = results[1];
          _balance = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Navigasi ke IncomeScreen dan refresh dashboard saat kembali.
  Future<void> _goToIncome() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncomeScreen()),
    );
    // Selalu refresh setelah kembali — data mungkin berubah.
    await _loadSummary();
  }

  // Navigasi ke ExpenseScreen dan refresh dashboard saat kembali.
  Future<void> _goToExpense() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
    );
    await _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Catat Keuangan'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Card Saldo ---
            _BalanceCard(balance: _balance),
            const SizedBox(height: 16),

            // --- Row: Pemasukan + Pengeluaran ---
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Pemasukan',
                    amount: _totalIncome,
                    color: Colors.green.shade600,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Pengeluaran',
                    amount: _totalExpense,
                    color: Colors.red.shade600,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Divider dengan label ---
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // --- Tombol Pemasukan ---
            _MenuButton(
              label: 'Pemasukan',
              subtitle: 'Tambah & kelola pemasukan',
              icon: Icons.arrow_downward_rounded,
              color: Colors.green.shade600,
              onTap: _goToIncome,
            ),
            const SizedBox(height: 12),

            // --- Tombol Pengeluaran ---
            _MenuButton(
              label: 'Pengeluaran',
              subtitle: 'Tambah & kelola pengeluaran',
              icon: Icons.arrow_upward_rounded,
              color: Colors.red.shade600,
              onTap: _goToExpense,
            ),

            // Ruang untuk area bawah (placeholder Kalender & Grafik)
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Card Saldo
// ---------------------------------------------------------------------------
class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final displayAmount = isNegative
        ? '-${CurrencyFormatter.format(balance.abs())}'
        : CurrencyFormatter.format(balance);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade700,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.white.withOpacity(0.85), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Saldo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              displayAmount,
              style: TextStyle(
                color: isNegative ? Colors.red.shade200 : Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (isNegative) ...[
              const SizedBox(height: 4),
              Text(
                'Pengeluaran melebihi pemasukan',
                style: TextStyle(
                  color: Colors.red.shade200,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Card ringkasan (pemasukan / pengeluaran)
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Tombol menu navigasi ke Income/Expense
// ---------------------------------------------------------------------------
class _MenuButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}

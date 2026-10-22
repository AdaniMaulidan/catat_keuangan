import 'package:flutter/material.dart';
import '../../repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../income/income_screen.dart';
import '../expense/expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = TransactionRepository();

  // --- State keuangan ---
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
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

  Future<void> _goToIncome() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncomeScreen()),
    );
    await _loadAll();
  }

  Future<void> _goToExpense() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
    );
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/AyoHemat.jpg',
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.emerald100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.emerald600,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    children: [
                      TextSpan(
                        text: 'Ayo',
                        style: TextStyle(color: AppTheme.rose500),
                      ),
                      TextSpan(
                        text: 'Hemat',
                        style: TextStyle(color: AppTheme.emerald600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'byAdani',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.slate200, width: 0.8),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppTheme.slate600,
                ),
              ),
              tooltip: 'Segarkan data',
              onPressed: _loadAll,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.emerald600,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.rose50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppTheme.rose500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.slate700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.emerald600,
      backgroundColor: Colors.white,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Hero Wallet Card (Saldo) ---
            _HeroWalletCard(balance: _balance),
            const SizedBox(height: 16),

            // --- Row: Quick Stats (Pemasukan + Pengeluaran) ---
            Row(
              children: [
                Expanded(
                  child: _SummaryStatCard(
                    label: 'Total Pemasukan',
                    amount: _totalIncome,
                    isIncome: true,
                    onTap: _goToIncome,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryStatCard(
                    label: 'Total Pengeluaran',
                    amount: _totalExpense,
                    isIncome: false,
                    onTap: _goToExpense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Section Divider: Menu ---
            _buildSectionDivider('MENU'),
            const SizedBox(height: 12),

            // --- Menu Action Cards ---
            _MenuActionCard(
              title: 'Pemasukan',
              subtitle: 'Tambah & kelola pemasukan',
              icon: Icons.arrow_downward_rounded,
              isIncome: true,
              onTap: _goToIncome,
            ),
            const SizedBox(height: 12),

            _MenuActionCard(
              title: 'Pengeluaran',
              subtitle: 'Tambah & kelola pengeluaran',
              icon: Icons.arrow_upward_rounded,
              isIncome: false,
              onTap: _goToExpense,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
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
}

// ---------------------------------------------------------------------------
// Widget: Hero Wallet Card (Saldo Rekening)
// ---------------------------------------------------------------------------
class _HeroWalletCard extends StatelessWidget {
  final double balance;

  const _HeroWalletCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final displayAmount = isNegative
        ? '-${CurrencyFormatter.format(balance.abs())}'
        : CurrencyFormatter.format(balance);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroWalletGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.heroCardShadow,
      ),
      child: Stack(
        children: [
          // Background subtle ambient glows
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.emerald500.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 16,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withOpacity(0.06),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Badge + Label
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: AppTheme.emerald200,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Saldo Rekening',
                      style: TextStyle(
                        color: AppTheme.slate300,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Balance Big Typography
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayAmount,
                    style: TextStyle(
                      color: isNegative ? AppTheme.rose200 : Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / indicator
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isNegative ? AppTheme.rose400 : AppTheme.emerald400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isNegative
                            ? 'Pengeluaran melebihi pemasukan'
                            : 'Terupdate otomatis',
                        style: TextStyle(
                          color: isNegative ? AppTheme.rose200 : AppTheme.slate400,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Quick Stats Card (Pemasukan / Pengeluaran)
// ---------------------------------------------------------------------------
class _SummaryStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  final VoidCallback onTap;

  const _SummaryStatCard({
    required this.label,
    required this.amount,
    required this.isIncome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isIncome ? AppTheme.emerald50 : AppTheme.rose50;
    final borderColor = isIncome ? AppTheme.emerald100 : AppTheme.rose100;
    final iconBgColor = isIncome ? AppTheme.emerald100 : AppTheme.rose100;
    final primaryColor = isIncome ? AppTheme.emerald600 : AppTheme.rose500;
    final iconData = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: borderColor.withOpacity(0.5),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with icon badge & label
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Menu Action Card
// ---------------------------------------------------------------------------
class _MenuActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isIncome;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isIncome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isIncome ? AppTheme.emerald50 : AppTheme.rose50;
    final iconColor = isIncome ? AppTheme.emerald600 : AppTheme.rose500;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate100, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isIncome ? AppTheme.emerald50 : AppTheme.rose50,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Leading Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Chevron
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppTheme.slate50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.slate300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

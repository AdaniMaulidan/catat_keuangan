import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../repositories/bill_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import 'bill_form_screen.dart';

enum BillFilter { all, unpaid, paid }

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final _repository = BillRepository();

  BillFilter _selectedFilter = BillFilter.unpaid;
  List<BillModel> _bills = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _unpaidCount = 0;
  double _totalUnpaidAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getAllBills(),
        _repository.getUnpaidBillsCount(),
        _repository.getTotalUnpaidBillsAmount(),
      ]);

      if (mounted) {
        setState(() {
          _bills = results[0] as List<BillModel>;
          _unpaidCount = results[1] as int;
          _totalUnpaidAmount = results[2] as double;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat tagihan: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<BillModel> get _filteredBills {
    switch (_selectedFilter) {
      case BillFilter.unpaid:
        return _bills.where((b) => !b.isPaid).toList();
      case BillFilter.paid:
        return _bills.where((b) => b.isPaid).toList();
      case BillFilter.all:
      default:
        return _bills;
    }
  }

  Future<void> _goToAddBill() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BillFormScreen()),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _goToEditBill(BillModel bill) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BillFormScreen(bill: bill)),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _confirmDelete(BillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Tagihan?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus tagihan "${bill.description}" sebesar ${CurrencyFormatter.format(bill.amount)}?',
          style: const TextStyle(fontSize: 14, color: AppTheme.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.slate500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && bill.id != null) {
      try {
        await _repository.deleteBill(bill.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tagihan "${bill.description}" berhasil dihapus.'),
              backgroundColor: AppTheme.slate800,
            ),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus tagihan: $e'),
              backgroundColor: AppTheme.rose600,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmPayBill(BillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.emerald100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payments_rounded,
                size: 20,
                color: AppTheme.emerald700,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bayar Tagihan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfirmasi pembayaran untuk "${bill.description}"?',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.slate700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nominal Bayar:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(bill.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Amber-100
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transaksi pengeluaran baru akan dicatat otomatis dan saldo langsung dipotong.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.slate500)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Ya, Bayar Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.payBill(bill);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Tagihan "${bill.description}" berhasil dibayar! Saldo terpotong.'),
              backgroundColor: AppTheme.emerald600,
            ),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memproses pembayaran: $e'),
              backgroundColor: AppTheme.rose600,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        title: const Text(
          'Daftar Tagihan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadData,
            tooltip: 'Segarkan data',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddBill,
        backgroundColor: const Color(0xFF4F46E5), // Indigo-600
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Tambah Tagihan',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.rose50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: AppTheme.rose500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.slate700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayedBills = _filteredBills;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // --- Top Summary Card ---
          _buildSummaryCard(),
          const SizedBox(height: 16),

          // --- Filter Tabs ---
          _buildFilterTabs(),
          const SizedBox(height: 16),

          // --- Bills List / Empty State ---
          if (displayedBills.isEmpty)
            _buildEmptyState()
          else
            ...displayedBills.map((bill) => _buildBillCard(bill)),
          const SizedBox(height: 80), // Padding for FAB
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B), // Indigo-950
            Color(0xFF312E81), // Indigo-900
            Color(0xFF4338CA), // Indigo-700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: Color(0xFFC7D2FE),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Total Tagihan Belum Dibayar',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(_totalUnpaidAmount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _unpaidCount > 0
                      ? const Color(0xFFFBBF24) // Amber
                      : AppTheme.emerald400,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _unpaidCount > 0
                    ? '$_unpaidCount tagihan menunggu pembayaran'
                    : 'Semua tagihan lunas 🎉',
                style: TextStyle(
                  color: _unpaidCount > 0
                      ? const Color(0xFFFDE68A)
                      : AppTheme.emerald200,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildFilterChip('Belum Dibayar', BillFilter.unpaid,
              badgeCount: _unpaidCount),
          _buildFilterChip('Semua', BillFilter.all),
          _buildFilterChip('Sudah Dibayar', BillFilter.paid),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BillFilter filter, {int? badgeCount}) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = filter);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : AppTheme.slate500,
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Belum ada tagihan.';
    if (_selectedFilter == BillFilter.unpaid) {
      message = 'Hore! Tidak ada tagihan yang belum dibayar.';
    } else if (_selectedFilter == BillFilter.paid) {
      message = 'Belum ada riwayat tagihan yang sudah dibayar.';
    }

    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(BillModel bill) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? dueDate;
    try {
      dueDate = DateTime.parse(bill.dueDate);
    } catch (_) {}

    int? diffDays;
    if (dueDate != null) {
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      diffDays = dueDateOnly.difference(today).inDays;
    }

    // Tentukan status badge & warna
    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData statusIcon;
    Color statusIconColor;
    Color statusIconBg;

    if (bill.isPaid) {
      badgeBg = AppTheme.emerald100;
      badgeText = AppTheme.emerald800;
      badgeLabel = 'LUNAS';
      statusIcon = Icons.check_circle_rounded;
      statusIconColor = AppTheme.emerald600;
      statusIconBg = AppTheme.emerald50;
    } else if (diffDays != null) {
      if (diffDays < 0) {
        badgeBg = AppTheme.rose100;
        badgeText = AppTheme.rose700;
        badgeLabel = 'TERLEWAT ${diffDays.abs()} HARI';
        statusIcon = Icons.warning_amber_rounded;
        statusIconColor = AppTheme.rose500;
        statusIconBg = AppTheme.rose50;
      } else if (diffDays == 0) {
        badgeBg = const Color(0xFFFEF3C7); // Amber-100
        badgeText = const Color(0xFF92400E); // Amber-800
        badgeLabel = 'HARI INI';
        statusIcon = Icons.access_time_filled_rounded;
        statusIconColor = const Color(0xFFD97706);
        statusIconBg = const Color(0xFFFFFBEB);
      } else {
        badgeBg = const Color(0xFFEEF2FF); // Indigo-50
        badgeText = const Color(0xFF4338CA); // Indigo-700
        badgeLabel = '$diffDays HARI LAGI';
        statusIcon = Icons.schedule_rounded;
        statusIconColor = const Color(0xFF4F46E5);
        statusIconBg = const Color(0xFFEEF2FF);
      }
    } else {
      badgeBg = AppTheme.slate100;
      badgeText = AppTheme.slate600;
      badgeLabel = bill.dueDate;
      statusIcon = Icons.receipt_rounded;
      statusIconColor = AppTheme.slate600;
      statusIconBg = AppTheme.slate100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bill.isPaid
              ? AppTheme.slate200
              : (diffDays != null && diffDays <= 0
                  ? AppTheme.rose200
                  : AppTheme.slate200),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon + Description + Badge & Popup Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, size: 20, color: statusIconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeText,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            bill.isPaid
                                ? 'Dibayar: ${bill.paidDate ?? '-'}'
                                : 'Jatuh tempo: ${bill.dueDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 20, color: AppTheme.slate400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _goToEditBill(bill);
                    } else if (value == 'delete') {
                      _confirmDelete(bill);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: AppTheme.slate600),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppTheme.rose500),
                          SizedBox(width: 8),
                          Text('Hapus',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.rose600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.slate100, height: 1),
            const SizedBox(height: 12),

            // Row 2: Amount & Pay Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nominal',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(bill.amount),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                if (!bill.isPaid)
                  ElevatedButton.icon(
                    onPressed: () => _confirmPayBill(bill),
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16),
                    label: const Text(
                      'Bayar',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.emerald200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_rounded,
                            size: 14, color: AppTheme.emerald600),
                        SizedBox(width: 4),
                        Text(
                          'Sudah Dibayar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.emerald700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

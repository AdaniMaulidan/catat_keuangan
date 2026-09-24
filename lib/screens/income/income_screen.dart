import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';
import '../../utils/currency_formatter.dart';
import 'income_form_screen.dart';

// Screen daftar pemasukan.
// Menampilkan semua transaksi dengan type 'income'.
// Menyediakan aksi: tambah, edit, dan hapus.
class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _repository = TransactionRepository();

  // State: data pemasukan
  List<TransactionModel> _incomeList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIncome();
  }

  // Mengambil data pemasukan dari repository.
  Future<void> _loadIncome() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getIncomeTransactions();
      if (mounted) {
        setState(() {
          _incomeList = data;
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

  // Navigasi ke form tambah pemasukan.
  Future<void> _navigateToAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const IncomeFormScreen(),
      ),
    );
    // Jika form mengembalikan true (berhasil simpan), refresh daftar.
    if (result == true) {
      await _loadIncome();
    }
  }

  // Navigasi ke form edit pemasukan.
  Future<void> _navigateToEdit(TransactionModel transaction) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IncomeFormScreen(transaction: transaction),
      ),
    );
    if (result == true) {
      await _loadIncome();
    }
  }

  // Tampilkan dialog konfirmasi sebelum hapus.
  Future<void> _confirmDelete(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pemasukan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pemasukan\n'
          '"${transaction.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteIncome(transaction);
    }
  }

  // Menjalankan penghapusan dan refresh daftar.
  Future<void> _deleteIncome(TransactionModel transaction) async {
    try {
      await _repository.deleteTransaction(transaction.id!);
      await _loadIncome();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pemasukan berhasil dihapus.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Mengubah format tanggal dari 'YYYY-MM-DD' ke tampilan yang lebih mudah dibaca.
  // Contoh: '2026-09-24' → '24 Sep 2026'
  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = parts[0];

    if (month < 1 || month > 12) return date;
    return '$day ${months[month]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemasukan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
        actions: [
          // Tombol refresh manual
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadIncome,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Pemasukan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    // State: loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // State: error
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
              onPressed: _loadIncome,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    // State: data kosong
    if (_incomeList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada pemasukan.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah pemasukan.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // State: data tersedia
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _incomeList.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _incomeList[index];
        return _IncomeListItem(
          transaction: item,
          formattedDate: _formatDate(item.date),
          onEdit: () => _navigateToEdit(item),
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }
}

// Widget item dalam daftar pemasukan.
// Dipisahkan agar build method IncomeScreen tetap bersih.
class _IncomeListItem extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IncomeListItem({
    required this.transaction,
    required this.formattedDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.arrow_downward, color: Colors.green.shade700),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        formattedDate,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nominal
          Text(
            CurrencyFormatter.format(transaction.amount),
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          // Tombol edit
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          // Tombol hapus
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
            tooltip: 'Hapus',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

import '../database/database_helper.dart';
import '../models/bill_model.dart';

class BillRepository {
  final DatabaseHelper _dbHelper;

  BillRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> addBill(BillModel bill) => _dbHelper.insertBill(bill);

  Future<List<BillModel>> getAllBills() => _dbHelper.getAllBills();

  Future<List<BillModel>> getBillsByPaidStatus(bool isPaid) =>
      _dbHelper.getBillsByPaidStatus(isPaid);

  Future<int> updateBill(BillModel bill) => _dbHelper.updateBill(bill);

  Future<int> deleteBill(int id) => _dbHelper.deleteBill(id);

  Future<void> payBill(BillModel bill) => _dbHelper.payBill(bill);

  Future<int> getUnpaidBillsCount() => _dbHelper.getUnpaidBillsCount();

  Future<double> getTotalUnpaidBillsAmount() =>
      _dbHelper.getTotalUnpaidBillsAmount();
}

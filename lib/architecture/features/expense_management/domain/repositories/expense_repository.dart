import '../../../../../model/GatePass/CancelgatepassResponse.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<CancelGatepassResponse> submitExpense(
    Expense expense,
    String token,
  );
}

import '../../../../../model/GatePass/CancelgatepassResponse.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class SubmitExpenseUseCase {
  final ExpenseRepository repository;

  SubmitExpenseUseCase(this.repository);

  Future<CancelGatepassResponse> call(
    Expense expense,
    String token,
  ) {
    return repository.submitExpense(
      expense,
      token,
    );
  }
}

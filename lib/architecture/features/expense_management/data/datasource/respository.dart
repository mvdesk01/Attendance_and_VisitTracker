import '../../../../../model/GatePass/CancelgatepassResponse.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../model/expense_model.dart';
import 'expenseremote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseremoteDatasource remoteDataSource;

  ExpenseRepositoryImpl(this.remoteDataSource);

  @override
  Future<CancelGatepassResponse> submitExpense(Expense expense, String token) {
    final model = ExpenseModel(
      todayDate: expense.todayDate,
      staffCode: expense.staffCode,
      staffName: expense.staffName,
      visitLocation: expense.visitLocation,
      visitPurpose: expense.visitPurpose,
      flagValue: expense.flagValue,
      advanceTaken: expense.advanceTaken,
      calculateExpense: expense.calculateExpense,
      balanceAmount: expense.balanceAmount,
      expenditureDate: expense.expenditureDate,
      amount: expense.amount,
      expenditureDetails: expense.expenditureDetails,
      document: expense.document,
    );

    return remoteDataSource.submitexpense(
      model,
      token,
    );
  }
}

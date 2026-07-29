import 'package:attendance_system_ios/architecture/features/expense_management/data/model/expense_model.dart'
    as modell;
import 'package:attendance_system_ios/model/Expense/Submitexpenserecords.dart';
import 'package:attendance_system_ios/model/GatePass/CancelgatepassResponse.dart';
import 'package:attendance_system_ios/service/WebService.dart';

class ExpenseremoteDatasource {
  final WebService webservice;

  ExpenseremoteDatasource(this.webservice);

  Future<CancelGatepassResponse> submitexpense(
    modell.ExpenseModel model,
    String token,
  ) {
    return webservice.submitExpenseRecords(model as ExpenseModel, token);
  }
}

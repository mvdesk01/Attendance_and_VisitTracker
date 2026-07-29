import '../../../../../model/GatePass/CancelgatepassResponse.dart';

abstract class ExpenseState {}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final CancelGatepassResponse response;

  ExpenseLoaded(this.response);
}

class ExpenseError extends ExpenseState {
  final String message;

  ExpenseError(this.message);
}

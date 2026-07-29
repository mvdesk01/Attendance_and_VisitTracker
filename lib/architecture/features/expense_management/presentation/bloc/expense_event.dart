import '../../domain/entities/expense.dart';

abstract class ExpenseEvent {}

class SubmitExpenseEvent extends ExpenseEvent {
  final Expense expense;
  final String token;

  SubmitExpenseEvent({
    required this.expense,
    required this.token,
  });
}
//class SubmitExpensedata extends MainEvent{
//   ExpenseModel expensemodell;
//   String token;
//   SubmitExpensedata({required this.expensemodell, required this.token});
// }

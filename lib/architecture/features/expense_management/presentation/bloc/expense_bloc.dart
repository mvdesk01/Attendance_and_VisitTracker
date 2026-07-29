import 'package:attendance_system_ios/architecture/features/expense_management/domain/usecase/expensesubmit_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final SubmitExpenseUseCase submitExpenseUseCase;

  ExpenseBloc(this.submitExpenseUseCase) : super(ExpenseInitial()) {
    on<SubmitExpenseEvent>(_submitExpense);
  }

  Future<void> _submitExpense(
    SubmitExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());

    try {
      final response = await submitExpenseUseCase(
        event.expense,
        event.token,
      );

      emit(ExpenseLoaded(response));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}

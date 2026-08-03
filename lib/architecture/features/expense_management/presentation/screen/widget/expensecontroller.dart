import 'package:flutter/cupertino.dart';

class ExpenseFormController {
  final staffCode = TextEditingController();
  final staffName = TextEditingController();
  final appliedDate = TextEditingController();
  final visitLocation = TextEditingController();
  final visitPurpose = TextEditingController();
  final TextEditingController advanceTaken = TextEditingController(text: '0.0');
  final TextEditingController calculatedExpense =
      TextEditingController(text: '0.0');
  final TextEditingController receivingAmount =
      TextEditingController(text: '0.0');
  final TextEditingController expenseAmount = TextEditingController();
  final TextEditingController expenseDate = TextEditingController();
  final TextEditingController expenseDetails = TextEditingController();
  final TextEditingController _expenseDocuments = TextEditingController();

  void dispose() {
    staffCode.dispose();
    staffName.dispose();
    appliedDate.dispose();
    visitLocation.dispose();
    visitPurpose.dispose();
    advanceTaken.dispose();
    calculatedExpense.dispose();
    receivingAmount.dispose();
    expenseAmount.dispose();
    expenseDate.dispose();
    expenseDetails.dispose();
  }
}

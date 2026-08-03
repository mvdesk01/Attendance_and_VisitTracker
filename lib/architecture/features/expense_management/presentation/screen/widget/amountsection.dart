import 'package:flutter/cupertino.dart';

import 'commantextfeild.dart';
import 'expensecontroller.dart';

class AmountSection extends StatelessWidget {
  final ExpenseFormController controller;

  const AmountSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonTextField(
          controller: controller.advanceTaken,
          label: "Advance Taken",
        ),
        SizedBox(height: 12),
        CommonTextField(
          controller: controller.expenseAmount,
          label: "Expense Amount",
        ),
        SizedBox(height: 12),
        CommonTextField(
          controller: controller.calculatedExpense,
          label: "Calculated Expense",
          readOnly: true,
        ),
        SizedBox(height: 12),
        CommonTextField(
          controller: controller.receivingAmount,
          label: "Receiving Amount",
          readOnly: true,
        ),
      ],
    );
  }
}

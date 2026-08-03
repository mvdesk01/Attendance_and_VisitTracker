import 'package:flutter/cupertino.dart';

import 'commandatefeild.dart';
import 'commantextfeild.dart';
import 'expensecontroller.dart';

class ExpenseDetailSection extends StatelessWidget {
  final ExpenseFormController controller;

  const ExpenseDetailSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonTextField(
          controller: controller.expenseDetails,
          label: "Expense Details",
        ),
        SizedBox(height: 12),
        CommonDateField(
          controller: controller.expenseDate,
        ),
      ],
    );
  }
}

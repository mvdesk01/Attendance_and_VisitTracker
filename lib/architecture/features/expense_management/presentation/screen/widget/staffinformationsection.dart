import 'package:flutter/cupertino.dart';

import 'commantextfeild.dart';
import 'expensecontroller.dart';

class StaffInformationSection extends StatelessWidget {
  final ExpenseFormController controller;

  const StaffInformationSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonTextField(
          controller: controller.staffCode,
          label: "Staff Code",
          readOnly: true,
        ),
        SizedBox(height: 12),
        CommonTextField(
          controller: controller.staffName,
          label: "Staff Name",
          readOnly: true,
        ),
        SizedBox(height: 12),
        CommonTextField(
          controller: controller.appliedDate,
          label: "Applied Date",
          readOnly: true,
        ),
      ],
    );
  }
}

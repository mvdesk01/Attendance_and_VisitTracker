import 'package:flutter/cupertino.dart';

import 'commantextfeild.dart';
import 'expensecontroller.dart';

class VisitInformationSection extends StatelessWidget {
  final ExpenseFormController controller;

  const VisitInformationSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonTextField(
          controller: controller.visitLocation,
          label: "Visit Location",
        ),
        SizedBox(height: 12),
        CommonTextField(
          controller: controller.visitPurpose,
          label: "Visit Purpose",
        ),
      ],
    );
  }
}

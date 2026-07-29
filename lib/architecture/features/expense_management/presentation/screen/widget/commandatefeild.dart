import 'package:flutter/material.dart';

class CommonDateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTap;

  const CommonDateField({
    super.key,
    required this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: "Expense Date",
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_month),
      ),
    );
  }
}

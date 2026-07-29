import 'package:flutter/material.dart';

import 'amountsection.dart';
import 'documentupload.dart';
import 'expensecontroller.dart';
import 'expensedetails.dart';
import 'staffinformationsection.dart';
import 'submitbutton.dart';
import 'visitinformation.dart';

class ExpenseForm extends StatelessWidget {
  final ExpenseFormController controller;
  final VoidCallback onPickDocument;
  final VoidCallback onSubmit;
  final String? selectedFileName;

  const ExpenseForm({
    super.key,
    required this.controller,
    required this.onPickDocument,
    required this.onSubmit,
    required this.selectedFileName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          StaffInformationSection(controller: controller),
          const SizedBox(height: 20),
          VisitInformationSection(controller: controller),
          const SizedBox(height: 20),
          AmountSection(controller: controller),
          const SizedBox(height: 20),
          ExpenseDetailSection(controller: controller),
          const SizedBox(height: 20),
          DocumentUploadSection(
            fileName: selectedFileName,
            onPickDocument: onPickDocument,
          ),
          const SizedBox(height: 20),
          SubmitButton(
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

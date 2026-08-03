import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/architecture/features/expense_management/presentation/screen/widget/expense_form.dart';
import 'package:attendance_system_ios/architecture/features/expense_management/presentation/screen/widget/expensecontroller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../../bloc/main_bloc.dart';
import '../../../../../bloc/main_event.dart';
import '../../../../../service/log_file_manager.dart';
import '../../domain/entities/expense.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

class ExpenseManagementScreen extends StatefulWidget {
  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  String? _selectedFileName;
  late final ExpenseFormController formController;

  // late final ExpenseFormController formController;
  bool _isLoading = false;
  String? staffcode = "";
  String? auth_token = "";
  final storage = FlutterSecureStorage();
  late MainBloc mainbloc;
  String? _selectedDocumentBase64; // <-- Add this back

  @override
  void initState() {
    super.initState();
    formController = ExpenseFormController();
    mainbloc = BlocProvider.of(context);
    _initializeData();
  }

  Future<void> _initializeData() async {
    staffcode = await storage.read(key: 'Staff_Code');
    print("staffCode-->" + staffcode!);
    auth_token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->" + auth_token!);
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    formController.appliedDate.text = today;
    formController.expenseDate.text = today;
    mainbloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));

// mainbloc.add(SubmitExpensedata(expensemodell: [], token: auth_token!));
//     final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
//     _appliedDateController.text = today;
//     _expendedDateController.text = today;
  }

  @override
  Widget build(BuildContext context) {
    return Provider<ExpenseFormController>.value(
      value: formController,
      child: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Expense Management"),
            ),
            body: ExpenseForm(
              selectedFileName: _selectedFileName,
              onPickDocument: _pickDocument,
              onSubmit: _submitExpense,
              controller: formController,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    formController.dispose();
    super.dispose();
  }

  void _pickDocument() async {
    setState(() {
      _isLoading = true; // Show progress indicator
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String base64File = "";

      // Check file size (limit to 5MB)
      if (file.lengthSync() > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 5MB')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Convert file to Base64
      if (result.files.single.extension == 'pdf') {
        base64File = await _convertFileToBase64(file);
      } else {
        File? compressedImage = await _compressImage(file);
        if (compressedImage != null) {
          base64File = await _convertFileToBase64(compressedImage);
        } else {
          base64File = await _convertFileToBase64(
              file); // Use original if compression fails
        }
      }

      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedDocumentBase64 = base64File;
        _isLoading = false; // Hide progress indicator
      });

      print("Selected File Name: $_selectedFileName");
      print(
          "Base64 File String (first 100 chars): ${base64File.substring(0, 100)}...");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
    } else {
      setState(() {
        _isLoading = false; // Hide progress indicator
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File selection canceled')),
      );
    }
  }

  Future<String> _convertFileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<File> _compressImage(File file) async {
    final directory = await getTemporaryDirectory();

    final compressedPath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      compressedPath,
      quality: 50,
      minWidth: 300,
      minHeight: 300,
    );

    if (result != null) {
      return File(result.path);
    }

    return file;
  }

  void _submitExpense() async {
    print("Submit button clicked");
    // final controller = context.read<ExpenseFormController>();
    final controller = formController;
    if (controller.visitLocation.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill Visit Location",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }
    if (controller.visitPurpose.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill Visit Purpose",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // ✅ Prevent submission if Expended Amount is 0.0 or empty
    if (controller.expenseAmount.text == '0.0' ||
        controller.expenseAmount.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Expended Amount cannot be 0.0 or empty",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }
    if (controller.expenseDetails.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill Details of expense",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }
    if (_selectedDocumentBase64 == null || _selectedDocumentBase64!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please upload a document",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = Expense(
        todayDate: controller.appliedDate.text,
        staffCode: controller.staffCode.text,
        staffName: controller.staffName.text,
        visitLocation: controller.visitLocation.text,
        visitPurpose: controller.visitPurpose.text,
        flagValue: "Submit",
        advanceTaken: controller.advanceTaken.text,
        calculateExpense: controller.calculatedExpense.text,
        balanceAmount: controller.receivingAmount.text,
        expenditureDate: controller.expenseDate.text,
        amount: controller.expenseAmount.text,
        expenditureDetails: controller.expenseDetails.text,
        document: _selectedDocumentBase64 ?? "",
      );
      print(expense.toString());
      context.read<ExpenseBloc>().add(
            SubmitExpenseEvent(
              expense: expense,
              token: auth_token!,
            ),
          );
      clear();
    } catch (e) {
      LogFileManager.writeLog("submit expense catch $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void clear() {
    final controller = formController;
    setState(() {
      controller.expenseDetails.text = "N/A";
      controller.visitLocation.text = "N/A";
      controller.visitPurpose.text = "N/A";
      controller.expenseAmount.text = "0.0"; // Reset Expended Amount
      _selectedDocumentBase64 = null;
      controller.receivingAmount.text = "0.0";
      controller.calculatedExpense.text = "0.0";
      controller.advanceTaken.text = "0.0";
      _selectedFileName = null;
    });
  }
}

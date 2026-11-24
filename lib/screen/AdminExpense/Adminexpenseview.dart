import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../bloc/main_state.dart';
import '../../model/Expense/ViewexpenseAdmin.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';

//adminexpense view git test2
//dgyhs
class AdminexpenseView extends StatefulWidget {
  Message datum;

  AdminexpenseView({
    Key? key,
    required this.datum,
  }) : super(key: key);

  @override
  State<AdminexpenseView> createState() => _createadminexpensescreen();
}
// --- NOTE ---
// This file is a cleaned, refactored and UI-enhanced version of the
// user's Admin Expense screen. Functionality (APIs / download behavior)
// remains exactly the same as requested.
// Make sure your project has these packages in pubspec.yaml:
// flutter_bloc, flutter_secure_storage, fluttertoast, open_file_plus, path_provider

class _createadminexpensescreen extends State<AdminexpenseView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController staffcodeController = TextEditingController();
  final TextEditingController applieddateController = TextEditingController();
  final TextEditingController visitlocationController = TextEditingController();
  final TextEditingController visitpurposeController = TextEditingController();
  final TextEditingController calculatedexpenseController =
      TextEditingController();
  final TextEditingController balanceamountController = TextEditingController();
  final TextEditingController srnoController = TextEditingController();
  final TextEditingController expendituredateController =
      TextEditingController();
  final TextEditingController expenditureamountController =
      TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController documentController = TextEditingController();

  late MainBloc mainbloc;
  bool _isLoading = false;
  final storage = const FlutterSecureStorage();
  String? auth_token = "";

  @override
  void initState() {
    super.initState();
    mainbloc = BlocProvider.of<MainBloc>(context);
    getData();
  }

  Future<void> getData() async {
    auth_token = await storage.read(key: 'Auth_Token');
    // Keep existing behaviour - dispatch event to load expenses
    mainbloc.add(ShowexpenseAdmin(
        staffcode: widget.datum.staffCode!, token: auth_token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Expense Management'),
          elevation: 2,
          backgroundColor: Colors.white24),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: BlocBuilder<MainBloc, MainState>(
          builder: (context, state) {
            if (state is showexpensedetailsadminLoadingState) {
              _isLoading = true;
              return const Center(child: CircularProgressIndicator());
            } else if (state is showexpensedetailsadminLoadedState) {
              _isLoading = false;
              final data = state.expenses;
              return _buildExpenseDetailsUI(context, data);
            } else {
              return const Center(
                child: Text(
                  'NO DATA FOR DISPLAY',
                  style: TextStyle(fontSize: 18, color: Colors.blue),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildExpenseDetailsUI(
      BuildContext context, List<ViewExpenseModel> data) {
    if (data.isEmpty) {
      Fluttertoast.showToast(
        msg: "No data available",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return const Center(child: Text('No Expense Details Found'));
    }

    // Use the first item's expenditureDetails only for the header info
    final header = data[0].expenditureDetails;

    nameController.text = header?.staffName ?? "";
    applieddateController.text = header?.todayDate ?? "";
    visitlocationController.text = header?.visitLocation ?? "";
    visitpurposeController.text = header?.visitPurpose ?? "";

    return Column(
      children: [
        // Header card with staff + visit summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (header?.staffName ?? "").isNotEmpty
                          ? header!.staffName![0].toUpperCase()
                          : "A",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(header?.staffName ?? 'Unknown Staff',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Staff Code: ${widget.datum.staffCode ?? "N/A"}',
                            style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              backgroundColor: Colors.green.shade50,
                              label: Text(header?.todayDate ?? '',
                                  style: const TextStyle(color: Colors.green)),
                            ),
                            const SizedBox(width: 8),
                            /*Expanded(
                              child: Text(header?.visitPurpose ?? '',
                                  style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis),
                            ),*/
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Title row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Financial Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // List of expense cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final expense = data[index];
              final expDetails = expense.expenditureDetails;
              final detail = expense.financialDetails; // single object per item

              if (detail == null) return const SizedBox.shrink();

              return _buildExpenseCard(expDetails, detail);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(
      ExpenditureDetails? expDetails, FinancialDetails detail) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row: date + amount
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expDetails?.todayDate ?? '-',
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black)),
                      const SizedBox(height: 6),
                      Text(expDetails?.visitPurpose ?? '-',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹ ${detail.amount?.toString() ?? '0'}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    const SizedBox(height: 6),
                    // Text(detail.expenditureDate ?? '-', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // // details text
            // if ((detail.expenditureDetails ?? '').isNotEmpty) ...[
            //   Text(detail.expenditureDetails ?? '', style: const TextStyle(color: Colors.black87)),
            //   const SizedBox(height: 12),
            // ],

            // action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // left: sr no / id
                Text('SrNo: ${detail.srNo ?? '-'}',
                    style: const TextStyle(fontSize: 15, color: Colors.black)),
                // right: download
                if (detail.document != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Download',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      String base64Data = detail.document!;
                      String fileType = getFileExtensionFromBase64(base64Data);
                      String fileName = 'downloaded_file.$fileType';
                      downloadAndOpenFile(base64Data, fileName, fileType);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> downloadAndOpenFile(
      String base64String, String fileName, String fileType) async {
    try {
      String normalizedBase64 =
          base64String.replaceAll("\n", "").replaceAll("\r", "");
      while (normalizedBase64.length % 4 != 0) {
        normalizedBase64 += "=";
      }

      Uint8List fileBytes = base64Decode(normalizedBase64);

      String fileTypeDetected = getFileExtensionFromBase64(base64String);
      String fileNameDetected = "downloaded_file.$fileTypeDetected";

      Directory tempDir = await getTemporaryDirectory();
      String filePath = "${tempDir.path}/$fileNameDetected";

      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (fileTypeDetected == "pdf") {
        await OpenFile.open(filePath);
      } else if (fileTypeDetected == "jpg" ||
          fileTypeDetected == "jpeg" ||
          fileTypeDetected == "png") {
        await OpenFile.open(filePath);
      } else {
        Fluttertoast.showToast(
          msg: "Unsupported file type",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e, stack) {
      debugPrint("Error downloading file: $e");
      Fluttertoast.showToast(
        msg: "Failed to download file",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed to download file',
      );
    }
  }

  String normalizeBase64(String base64String) {
    while (base64String.length % 4 != 0) {
      base64String += '=';
    }
    return base64String;
  }

  String getFileExtensionFromBase64(String base64String) {
    if (base64String.startsWith("/9j/")) {
      return "jpg";
    } else if (base64String.startsWith("JVBER")) {
      return "pdf";
    } else if (base64String.startsWith("iVBOR")) {
      return "png";
    } else {
      return "unknown";
    }
  }
}

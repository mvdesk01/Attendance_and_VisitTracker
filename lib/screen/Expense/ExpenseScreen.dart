import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/util/DialogForUpdate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_state.dart';
import '../../model/Expense/Submitexpenserecords.dart';
import '../../service/log_file_manager.dart';
import '../../util/MyColor.dart';

class Expensemanagmentscreen extends StatefulWidget {
  const Expensemanagmentscreen({super.key});

  @override
  State<Expensemanagmentscreen> createState() =>
      _ExpensemanagementscreenState();
}

class _ExpensemanagementscreenState extends State<Expensemanagmentscreen> {
  bool _isLoading = false;
  String? staffcode = "";
  String? auth_token = "";
  final storage = FlutterSecureStorage();
  late MainBloc mainbloc;
  String? _selectedDocumentBase64; // Store base64 of the selected file
  String? _selectedFileName; // Store the file name

  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _appliedDateController = TextEditingController();
  final TextEditingController _visitLocationController =
      TextEditingController();
  final TextEditingController _visitPurposeController = TextEditingController();
  final TextEditingController _advanceTakenController =
      TextEditingController(text: '0.0');
  final TextEditingController _calculatedExpenseController =
      TextEditingController(text: '0.0');
  final TextEditingController _receivingAmountController =
      TextEditingController(text: '0.0');
  final TextEditingController _expendedamountController =
      TextEditingController();
  final TextEditingController _expendedDateController = TextEditingController();
  final TextEditingController _expendedDeatils = TextEditingController();
  final TextEditingController _expenseDocuments = TextEditingController();

  @override
  void initState() {
    super.initState();
    mainbloc = BlocProvider.of(context);
    _initializeData();
    _expendedamountController.text = "0.0";
  }

  Future<void> _selectExpenseDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 40)),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _expendedDateController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _initializeData() async {
    staffcode = await storage.read(key: 'Staff_Code');
    print("staffCode-->" + staffcode!);
    auth_token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->" + auth_token!);
    mainbloc.add(GetUserInfoEvents(Staffcode: staffcode!, token: auth_token!));

// mainbloc.add(SubmitExpensedata(expensemodell: [], token: auth_token!));
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _appliedDateController.text = today;
    _expendedDateController.text = today;
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
        _expenseDocuments.text = _selectedFileName ?? "Document Selected";
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
    List<int> fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  }

  Future<File> _compressImage(File file) async {
    final directory = await getTemporaryDirectory();
    final compressedFilePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      compressedFilePath,
      quality: 50,
      minWidth: 300,
      minHeight: 300,
    );

    if (result is File) {
      return File(result!.path);
    } else {
      return file; // fallback
    }
  }

  void _updateCalculations() {
    double calculatedExpense = 0.0;
    if (_expendedamountController.text.isNotEmpty) {
      calculatedExpense +=
          double.tryParse(_expendedamountController.text) ?? 0.0;
    }

    double advanceTaken = double.tryParse(_advanceTakenController.text) ?? 0.0;
    double receivingAmount = calculatedExpense - advanceTaken;

    setState(() {
      _calculatedExpenseController.text = calculatedExpense.toStringAsFixed(2);
      _receivingAmountController.text = receivingAmount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if (state is GetUserinfoLoadingState) {
          setState(() {
            _isLoading = true;
          });
        }
        if (state is GetUserinfoLoadedState) {
          final user = state.profileuserinfo.message;

          setState(() {
            _isLoading = false;

            // Populate the text fields
            _staffNameController.text = user?.displayName ?? '';
            _staffCodeController.text = user?.staffCode ?? '';
            // Handle profile picture
          });
        } else if (state is GetUserinfoErrorState) {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: "   Failed To Connect Server...!   ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        }

        if (state is SubmitexpenseLoadingState) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is SubmitexpenseLoadedState) {
          setState(() {
            _isLoading = false;
          });
          if (state.cancelGatepassResponse.message ==
              "Record Inserted Successfully") {
            DialogForUpdate().popUp(context, "Expense details submitted", "3");
          }
          _visitPurposeController.clear();
          _visitLocationController.clear();
          _expendedDeatils.clear();
          _expenseDocuments.clear();

          Fluttertoast.showToast(msg: 'Expense record submitted');
        } else if (state is SubmitexpenseErrorstate) {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(msg: 'error in submitting');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Expense Management')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: _staffCodeController,
                  enabled: false,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Staff Code',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // _buildTextField(
                //     'Staff Code', _staffCodeController, readOnly: true,
                //     isRequired: true),
                TextField(
                  controller: _staffNameController,
                  enabled: false,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Staff Name',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // _buildTextField(
                //     'Staff Name', _staffNameController, readOnly: true,
                //     isRequired: true),
                TextField(
                  controller: _appliedDateController,
                  enabled: false,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Applied Date',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // _buildTextField(
                //     'Application Date', _appliedDateController, readOnly: true,
                //     showIcon: false, isRequired: true),
                // _buildTextField('Visit Location', _visitLocationController,
                //     isRequired: true),
                TextField(
                  controller: _visitLocationController,
                  enabled: true,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Visit Location',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // _buildTextField(
                //     'Visit Purpose', _visitPurposeController, isRequired: true),
                TextField(
                  controller: _visitPurposeController,
                  enabled: true,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Visit Purpose',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _advanceTakenController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    _updateCalculations();
                  },
                  style: TextStyle(color: Colors.red),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                    // Restricts to 2 decimal places
                  ],
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Advance Taken: ',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                // _buildTextField(
                //   'Calculated Expense', _calculatedExpenseController,
                //   textColor: Colors.blue,readOnly: true,isRequired: true,),
                const SizedBox(height: 12),
                TextField(
                  controller: _expendedamountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  },
                  style: TextStyle(color: Colors.blue),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                    // Restricts to 2 decimal places
                  ],
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Expended Amount ',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _receivingAmountController,
                  enabled: false,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.green),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                    // Restricts to 2 decimal places
                  ],
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Amount Received',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                // _buildTextField('Amount Received', _receivingAmountController,
                //     textColor: Colors.green, readOnly: true, isRequired: true),

                const SizedBox(height: 12),
                /*   TextField(
                  controller: _expendedDeatils,
                  style: TextStyle(color: Colors.blue),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}$')),
                    // Restricts to 2 decimal places
                  ],
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Expended Details ',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Colors
                                .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),*/
                TextField(
                  controller: _expendedDeatils,
                  enabled: true,
                  // onChanged: (value) {
                  //   _updateCalculations(); // Call this method to update calculations when Expended Amount changes
                  // },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Expended Details',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),
                // _buildTextField('Details of Expense', _expendedDeatils,
                //     textColor: Colors.blue, isRequired: true),
                TextField(
                  controller: _expendedDateController,
                  onTap: _selectExpenseDate,
                  decoration: InputDecoration(
                    label: RichText(
                      text: TextSpan(
                        text: 'Expended Date',
                        style: TextStyle(color: Colors.black),
                        // Normal label color
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                                color: Colors
                                    .red), // Red asterisk for required field
                          ),
                        ],
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _selectExpenseDate(),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDocument(),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: 'Attach Document ',
                          style: TextStyle(color: Colors.black),
                          // Normal label color
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                  color: Colors
                                      .red), // Red asterisk for required field
                            ),
                          ],
                        ),
                      ),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.attach_file),
                        onPressed: () => _pickDocument(),
                      ),
                    ),
                    child: Text(_selectedFileName ?? "Select a document"),
                  ),
                ),

                //'advance table'
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitExpense,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

/*  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, bool showIcon = false, Color? textColor,  bool isRequired = false,}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        if (isRequired) // ✅ Conditionally add * mark
          Text(
            " *",
            style: TextStyle(fontSize: 18, color: MyColors.redColorCode),
          ),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: showIcon ? const Icon(Icons.calendar_today) : null,
          ),
          style: TextStyle(color: textColor),
        ),
        const SizedBox(height: 10),
      ],
    );
  }*/
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool showIcon = false,
    Color? textColor,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            if (isRequired) // ✅ Conditionally add * mark
              Text(
                " *",
                style: TextStyle(fontSize: 18, color: MyColors.redColorCode),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: showIcon ? const Icon(Icons.calendar_today) : null,
          ),
          style: TextStyle(color: textColor),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _submitExpense() async {
    if (_visitLocationController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill Visit Location",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }
    if (_visitPurposeController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill Visit Purpose",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // ✅ Prevent submission if Expended Amount is 0.0 or empty
    if (_expendedamountController.text == '0.0' ||
        _expendedamountController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Expended Amount cannot be 0.0 or empty",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }
    if (_expendedDeatils.text.isEmpty) {
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
      ExpenseModel expenseModel = ExpenseModel(
          todayDate: _appliedDateController.text,
          staffCode: staffcode!,
          staffName: _staffNameController.text,
          visitLocation: _visitLocationController.text,
          visitPurpose: _visitPurposeController.text,
          flagValue: "Submit",
          advanceTaken: _advanceTakenController.text,
          calculateExpense: _calculatedExpenseController.text,
          balanceAmount: _receivingAmountController.text,
          expenditureDate: _expendedDateController.text,
          amount: _expendedamountController.text,
          expenditureDetails: _expendedDeatils.text,
          document: _selectedDocumentBase64 ?? ""
          //document: "iVBORw0KGgoAAAANSUhEUgAAAAAAACAIAAADwVnY8AAAAAElEQVRIDbXBAQEAAAABIP6/PcLAAAAAElFTkSuQmCC" // Use pre-converted base64 here
          );
      print(expenseModel.toJson());
      print(expenseModel.toString());
      mainbloc.add(SubmitExpensedata(
        expensemodell: expenseModel,
        token: auth_token!,
      ));
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
    setState(() {
      _expendedDeatils.text = "N/A";
      _visitLocationController.text = "N/A";
      _visitPurposeController.text = "N/A";
      _expendedamountController.text = "0.0"; // Reset Expended Amount
      _selectedDocumentBase64 = null;
      _expenseDocuments.clear();
      _receivingAmountController.text = "0.0";
      _calculatedExpenseController.text = "0.0";
      _advanceTakenController.text = "0.0";
      _selectedFileName = null;
    });
  }
}

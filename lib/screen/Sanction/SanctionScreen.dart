import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/SanctionModel/SanctionApprove.dart';
import '../../model/SanctionModel/Sanctionn.dart';
import '../../util/MyColor.dart';

class SanctionRequest extends StatefulWidget {
  const SanctionRequest({super.key});

  @override
  _SanctionRequestState createState() => _SanctionRequestState();
}

// class _SanctionRequestState extends State<SanctionRequest> {
//   String? _status = 'Approved'; // Default selected value
//   late MainBloc mainBloc;
//   final storage = FlutterSecureStorage();
//   late bool _isLoading = false;
//   String? staffCode = "";
//   String? authToken = "";
//   List<ApprovedSanctionRecords> _records = [];
//   Map<String, String> rejectReasons = {};
//   Map<String, bool> approveMap = {};
//   Map<String, bool> rejectMap = {};// To store reject reasons for each record
//
//   @override
//   void initState() {
//     super.initState();
//     mainBloc = BlocProvider.of<MainBloc>(context);
//     getData();
//   }
//
//   void _onStatusChanged(String? value) {
//     setState(() {
//       _status = value;
//     });
//
//     if (authToken != null) {
//       print("Status Changed: $_status");
//       print("ReportingLevelStaffCode: ${_status == 'Approved' ? 'CD00490' : 'MDIR003'}");
//       print("Flag: ${_status == 'Approved' ? 'P' : 'S'}");
//       print("AuthToken: $authToken");
//
//       mainBloc.add(AllApproveSanctionEvents(
//         ReportingLevelStaffCode: _status == 'Approved' ? 'CD00490' : 'MDIR003',
//         Flag: _status == 'Approved' ? 'P' : 'S',
//         token: authToken!,
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sanction/Reject'),
//       ),
//       /*  body: Padding(padding:
//       const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Under Development',
//               style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),*/
//
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Sanction/Approve/Reject',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Radio<String>(
//                   value: 'Approved',
//                   groupValue: _status,
//                   onChanged: _onStatusChanged,
//                 ),
//                 const Text('Approved'),
//                 const SizedBox(width: 20),
//                 // Radio<String>(
//                 //   value: 'Sanctioned',
//                 //   groupValue: _status,
//                 //   onChanged: _onStatusChanged,
//                 // ),
//                 //
//                 // const Text('Sanctioned'),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: BlocListener<MainBloc, MainState>(
//                 listener: (context, state) async {
//                   if (state is ApproveSanctionLoadingState) {
//                     setState(() {
//                       _isLoading = true;
//                     });
//                   } else if (state is ApproveSanctionLoadedState) {
//                     setState(() {
//                       _isLoading = false;
//                       _records = state.approvedsanctionrecords;
//                     });
//                   } else if (state is ApproveSanctionErrorState) {
//                     setState(() {
//                       _isLoading = false;
//                     });
//                     Fluttertoast.showToast(
//                       msg: "   Failed To Connect Server!   ",
//                       toastLength: Toast.LENGTH_SHORT,
//                       timeInSecForIosWeb: 1,
//                     );
//                   }
//                 },
//                 child: _isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : _records.isNotEmpty
//                     ? _buildDataTable(_records)
//                     : const Center(child: Text('No data available.')),
//               ),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     // Validation for reject reason
//                     bool isValid = true;
//                     for (var record in _records) {
//                       if (rejectReasons[record.staffCode] == null &&
//                           record.aFlag == 'Reject') {
//                         isValid = false;
//                         Fluttertoast.showToast(
//                           msg: 'Please fill reject reason for ${record.name}',
//                           toastLength: Toast.LENGTH_SHORT,
//                           timeInSecForIosWeb: 1,
//                         );
//                         break;
//                       }
//                     }
//                     if (isValid) {
//                       // Build the submission data
//                       List<SanctionRequestModel> submissionData = _buildSubmissionData();
//
//                       // Now send the request to the server
//                       mainBloc.add(SubmitSactionEvents(
//                         sanctionmodels: submissionData, // Pass the list here
//                         token: authToken!,
//                       ));
//                       getData();
//                     }
//                   },
//                   child: const Text('Submit'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Close'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
// /*  Widget _buildDataTable(List<ApprovedSanctionRecords> records) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         columns: const [
//           DataColumn(label: Text('Staff Code')),
//           DataColumn(label: Text('Name')),
//           DataColumn(label: Text('Date')),
//           DataColumn(label: Text('Request Type')),
//           DataColumn(label: Text('Days/Hrs')),
//           DataColumn(label: Text('Coff/GptType')),
//           DataColumn(label: Text('Status')),
//           DataColumn(label: Text('Approve')),
//           DataColumn(label: Text('Reject')),
//           DataColumn(label: Text('Reject Reason')),
//         ],
//         rows: List<DataRow>.generate(
//           records.length,
//               (index) {
//             final record = records[index];
//             return DataRow(
//               cells: [
//                 DataCell(Text(record.staffCode)),
//                 DataCell(Text(record.name)),
//                 DataCell(Text(record.date)),
//                 DataCell(Text(record.type)),
//                 DataCell(Text(record.daysHours)),
//                 DataCell(Text(record.coffType)),
//                 DataCell(Text(record.aFlag)),
//                 DataCell(
//                   Radio<String>(
//                     value: 'Approve',
//                     groupValue: rejectReasons[index], // Unique to this row using index
//                     onChanged: (value) {
//                       setState(() {
//                         rejectReasons[index as String] = 'Approve';
//                       });
//                     },
//                   ),
//                 ),
//                 DataCell(
//                   Radio<String>(
//                     value: 'Reject',
//                     groupValue: rejectReasons[index], // Unique to this row using index
//                     onChanged: (value) {
//                       setState(() {
//                         // Check if a reason is already entered
//                         if (rejectReasons[index] != 'Approve' &&
//                             (rejectReasons[index]?.isEmpty ?? true)) {
//                           Fluttertoast.showToast(
//                             msg: 'Please provide a reason for rejection.',
//                             toastLength: Toast.LENGTH_SHORT,
//                             timeInSecForIosWeb: 1,
//                           );
//                         } else {
//                           rejectReasons[index as String] = 'Reject';
//                         }
//                       });
//                     },
//                   ),
//                 ),
//                 DataCell(
//                   TextField(
//                     onChanged: (value) {
//                       setState(() {
//                         rejectReasons[index as String] = value;
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Enter reason',
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }*/
//
//   Widget _buildDataTable(List<ApprovedSanctionRecords> records) {
//     return Expanded(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.vertical,
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             columns: const [
//               DataColumn(label: Text('Staff Code')),
//               DataColumn(label: Text('Name')),
//               DataColumn(label: Text('Date')),
//               DataColumn(label: Text('Request Type')),
//               DataColumn(label: Text('Days/Hrs')),
//               DataColumn(label: Text('Coff/GptType')),
//               DataColumn(label: Text('Status')),
//               DataColumn(label: Text('Approve')),
//               DataColumn(label: Text('Reject')),
//               DataColumn(label: Text('Reject Reason')),
//             ],
//             rows: List<DataRow>.generate(
//               records.length,
//                   (index) {
//                 final record = records[index];
//                 final String uniqueKey = '${record.staffCode}_${record.tid}';
//
//                 return DataRow(
//                   cells: [
//                     DataCell(Text(record.staffCode)),
//                     DataCell(Text(record.name)),
//                     DataCell(Text(record.date)),
//                     DataCell(Text(record.type)),
//                     DataCell(Text(record.daysHours)),
//                     DataCell(Text(record.coffType)),
//                     DataCell(Text(record.aFlag)),
//
//                     // ✅ Approve Checkbox
//                     DataCell(
//                       Checkbox(
//                         value: approveMap[uniqueKey] ?? false,
//                         onChanged: (value) {
//                           setState(() {
//                             approveMap[uniqueKey] = value ?? false;
//                             // Ensure only one action is selected at a time
//                             if (value == true) {
//                               rejectMap[uniqueKey] = false;  // Deselect reject when approve is selected
//                             }
//                           });
//                         },
//                       ),
//                     ),
//
//                     DataCell(
//                       Checkbox(
//                         value: rejectMap[uniqueKey] ?? false,
//                         onChanged: (value) {
//                           setState(() {
//                             rejectMap[uniqueKey] = value ?? false;
//                             // Ensure only one action is selected at a time
//                             if (value == true) {
//                               approveMap[uniqueKey] = false;  // Deselect approve when reject is selected
//                             }
//                           });
//                         },
//                       ),
//                     ),
//
//
//                     // ✅ Reject Reason TextField (visible only if Reject is checked)
//                     DataCell(
//                       rejectMap[uniqueKey] == true
//                           ? TextField(
//                         onChanged: (value) {
//                           setState(() {
//                             rejectReasons[uniqueKey] = value;
//                           });
//                         },
//                         decoration: const InputDecoration(
//                           hintText: 'Enter reason',
//                         ),
//                       )
//                           : const Text(''), // Empty if reject is not checked
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> getData() async {
//     try {
//       staffCode = await storage.read(key: 'Staff_Code');
//       authToken = await storage.read(key: 'Auth_Token');
//
//       if (authToken != null) {
//         mainBloc.add(AllApproveSanctionEvents(
//           ReportingLevelStaffCode: 'CD00490', // Example staff code
//           Flag: 'P', // Example flag
//           token: authToken!,
//         ));
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error fetching data: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         timeInSecForIosWeb: 1,
//       );
//     }
//   }
//
//   List<SanctionRequestModel> _buildSubmissionData() {
//     return _records.where((record) {
//       final uniqueKey = '${record.staffCode}_${record.tid}';
//
//       // ✅ Filter only the selected records
//       bool isApproved = approveMap[uniqueKey] ?? false;
//       bool isRejected = rejectMap[uniqueKey] ?? false;
//
//       return isApproved || isRejected;  // Only include selected records
//     }).map((record) {
//       final uniqueKey = '${record.staffCode}_${record.tid}';
//
//       // ✅ Extract only the numerical part using regex
//       String numericTtlDays = RegExp(r'\d+').stringMatch(record.daysHours) ?? '0';
//
//       return SanctionRequestModel(
//         tid: record.tid.toString(),
//         staffCode: record.staffCode,
//         requestType: record.type,
//         ttlDays: numericTtlDays,      // ✅ Use only the numerical part
//         sDate: record.date,
//         eDate: record.eDate,
//
//         // ✅ Use the map values directly for bool flags
//         appRadio: approveMap[uniqueKey] ?? false,
//         rejRadio: rejectMap[uniqueKey] ?? false,
//         rejectReason: rejectMap[uniqueKey] == true ? (rejectReasons[uniqueKey] ?? '') : '',
//         approvalRadio: _status == 'Approved',
//         sanctionRadio: _status == 'Sanctioned',
//       );
//     }).toList();
//   }
//
// }



// Assuming these imports exist in your project
// import 'your_bloc_path.dart';
// import 'your_models_path.dart';
// import 'your_colors_path.dart';

class _SanctionRequestState extends State<SanctionRequest> {
  String? _status = 'Approved';
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  late bool _isLoading = false;
  String? staffCode = "";
  String? authToken = "";
  List<ApprovedSanctionRecords> _records = [];
  Map<String, String> rejectReasons = {};
  Map<String, bool> approveMap = {};
  Map<String, bool> rejectMap = {};

  final TextEditingController staffController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isVerified = false;
  bool enablePassword = false;
  bool _obscurePassword = true; // For password visibility toggle
  String loginError = "";
  String loggedInStaffCode = "";

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);
    isVerified = false;
    loginError = "";
  }

  void _onStatusChanged(String? value) {
    setState(() {
      _status = value;
    });

    if (authToken != null && isVerified == true) {
      String reportingLevelStaffCode;
      String flag;

      if (loggedInStaffCode.toUpperCase() == "CD00490") {
        reportingLevelStaffCode = "CD00490";
        flag = "P";
      } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
        reportingLevelStaffCode = "MDIR003";
        flag = "S";
      } else {
        reportingLevelStaffCode = _status == 'Approved' ? 'CD00490' : 'MDIR003';
        flag = _status == 'Approved' ? 'P' : 'S';
      }

      mainBloc.add(AllApproveSanctionEvents(
        ReportingLevelStaffCode: reportingLevelStaffCode,
        Flag: flag,
        token: authToken!,
      ));
    }
  }

  void onCheckList() {
    setState(() {
      loginError = "";
    });

    if (staffController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Staff Code");
      return;
    }

    if (passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Password");
      return;
    }

    mainBloc.add(LoginEvents(
      username: staffController.text,
      password: passwordController.text,
    ));
  }

  void refreshSanctionData() {
    if (authToken != null && isVerified == true) {
      String reportingLevelStaffCode;
      String flag;

      if (loggedInStaffCode.toUpperCase() == "CD00490") {
        reportingLevelStaffCode = "CD00490";
        flag = "P";
      } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
        reportingLevelStaffCode = "MDIR003";
        flag = "S";
      } else {
        reportingLevelStaffCode = staffController.text;
        flag = 'P';
      }

      mainBloc.add(AllApproveSanctionEvents(
        ReportingLevelStaffCode: reportingLevelStaffCode,
        Flag: flag,
        token: authToken!,
      ));
    }
  }

  void clearSelectionStates() {
    setState(() {
      approveMap.clear();
      rejectMap.clear();
      rejectReasons.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sanction/Reject Request', style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.blueColorCode,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) async {
          if (state is LoginLoadingState) {
            setState(() {
              _isLoading = true;
              loginError = "";
            });
          }
          else if (state is LoginLoadedState) {
            String? token = state.loginResponse?.token?.result?.token;

            if (token != null && token.isNotEmpty) {
              setState(() {
                _isLoading = false;
                isVerified = true;
                authToken = token;
                loggedInStaffCode = staffController.text;
                loginError = "";
              });

              String reportingLevelStaffCode;
              String flag;

              if (loggedInStaffCode.toUpperCase() == "CD00490") {
                reportingLevelStaffCode = "CD00490";
                flag = "P";
                _status = "Approved";
              } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
                reportingLevelStaffCode = "MDIR003";
                flag = "S";
                _status = "Sanctioned";
              } else {
                reportingLevelStaffCode = staffController.text;
                flag = "P";
              }

              mainBloc.add(AllApproveSanctionEvents(
                ReportingLevelStaffCode: reportingLevelStaffCode,
                Flag: flag,
                token: authToken!,
              ));
            } else {
              setState(() {
                _isLoading = false;
                isVerified = false;
                authToken = null;
                loginError = "Invalid Staff Code or Password";
              });
              Fluttertoast.showToast(msg: "Please enter valid credentials");
            }
          }
          else if (state is LoginErrorState) {
            setState(() {
              _isLoading = false;
              isVerified = false;
              authToken = null;
              loginError = "Login Failed. Please check your credentials.";
            });
            Fluttertoast.showToast(msg: "Please enter valid credentials");
          }

          if (isVerified == true) {
            if (state is ApproveSanctionLoadingState) {
              setState(() => _isLoading = true);
            }
            else if (state is ApproveSanctionLoadedState) {
              setState(() {
                _isLoading = false;
                _records = state.approvedsanctionrecords;
                clearSelectionStates();
              });
            }
            else if (state is ApproveSanctionErrorState) {
              setState(() => _isLoading = false);
              Fluttertoast.showToast(msg: "Failed To Connect Server!");
            }
          }

          if (state is SubmitApprovesanctionLoadingState) {
            setState(() => _isLoading = true);
          }
          else if (state is SubmitApprovesanctionLoadedState) {
            setState(() => _isLoading = false);
            clearSelectionStates();
            Future.delayed(const Duration(milliseconds: 500), () {
              refreshSanctionData();
              Fluttertoast.showToast(msg: "Data refreshed successfully");
            });
          }
          else if (state is SubmitApproveSanctionErrorState) {
            setState(() => _isLoading = false);
            Fluttertoast.showToast(msg: "Failed to submit. Please try again.");
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : isVerified
            ? _buildMainContent()
            : _buildLoginUI(),
      ),
    );
  }

  Widget _buildLoginUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded, size: 60, color: MyColors.blueColorCode),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Please login to manage sanctions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 30),

                TextField(
                  controller: staffController,
                  decoration: InputDecoration(
                    labelText: 'Staff Code',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      enablePassword = value.isNotEmpty;
                      loginError = "";
                    });
                  },
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  enabled: enablePassword,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      loginError = "";
                    });
                  },
                ),

                if (loginError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      loginError,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.blueColorCode,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onCheckList,
                    child: const Text("LOGIN & CHECK LIST",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    bool showApprovedRadio = loggedInStaffCode.toUpperCase() == "CD00490";
    bool showSanctionedRadio = loggedInStaffCode.toUpperCase() == "MDIR003";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reporting Staff', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        staffController.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: MyColors.blueColorCode, size: 28),
                    onPressed: () {
                      refreshSanctionData();
                      Fluttertoast.showToast(msg: "Refreshing data...");
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  if (showApprovedRadio || (!showApprovedRadio && !showSanctionedRadio)) ...[
                    Radio<String>(
                      value: 'Approved',
                      activeColor: MyColors.blueColorCode,
                      groupValue: _status,
                      onChanged: _onStatusChanged,
                    ),
                    const Text('Approved'),
                  ],
                  if (showSanctionedRadio || (!showApprovedRadio && !showSanctionedRadio)) ...[
                    const SizedBox(width: 10),
                    Radio<String>(
                      value: 'Sanctioned',
                      activeColor: MyColors.blueColorCode,
                      groupValue: _status,
                      onChanged: _onStatusChanged,
                    ),
                    const Text('Sanctioned'),
                  ],
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _records.isNotEmpty
                  ? _buildDataTable(_records)
                  : const Center(child: Text('No pending records found.')),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: MyColors.blueColorCode),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      isVerified = false;
                      _records.clear();
                      approveMap.clear();
                      rejectMap.clear();
                      rejectReasons.clear();
                      staffController.clear();
                      passwordController.clear();
                      loginError = "";
                      loggedInStaffCode = "";
                    });
                    Navigator.pop(context);
                  },
                  child: Text('CLOSE', style: TextStyle(color: MyColors.blueColorCode, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.blueColorCode,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    bool hasSelected = false;
                    for (var record in _records) {
                      final key = '${record.staffCode}_${record.tid}';
                      if (approveMap[key] == true || rejectMap[key] == true) {
                        hasSelected = true;
                        break;
                      }
                    }

                    if (!hasSelected) {
                      Fluttertoast.showToast(msg: "Select at least one record");
                      return;
                    }

                    bool isValid = true;
                    for (var record in _records) {
                      final key = '${record.staffCode}_${record.tid}';
                      if (rejectMap[key] == true && (rejectReasons[key]?.isEmpty ?? true)) {
                        isValid = false;
                        Fluttertoast.showToast(msg: 'Enter reason for ${record.name}');
                        break;
                      }
                    }

                    if (isValid) {
                      mainBloc.add(SubmitSactionEvents(
                        sanctionmodels: _buildSubmissionData(),
                        token: authToken!,
                      ));
                    }
                  },
                  child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<ApprovedSanctionRecords> records) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.grey[200]),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: MyColors.blueColorCode),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Staff Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Days/Hrs')),
              DataColumn(label: Text('Coff Type')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Approve')),
              DataColumn(label: Text('Reject')),
              DataColumn(label: Text('Reject Reason')),
            ],
            rows: List<DataRow>.generate(
              records.length,
                  (index) {
                final record = records[index];
                final String uniqueKey = '${record.staffCode}_${record.tid}';

                return DataRow(
                  cells: [
                    DataCell(Text(record.staffCode)),
                    DataCell(Text(record.name)),
                    DataCell(Text(record.date)),
                    DataCell(Text(record.type)),
                    DataCell(Text(record.daysHours)),
                    DataCell(Text(record.coffType)),
                    DataCell(Text(record.aFlag)),
                    DataCell(
                      Checkbox(
                        activeColor: Colors.green,
                        value: approveMap[uniqueKey] ?? false,
                        onChanged: (value) {
                          setState(() {
                            approveMap[uniqueKey] = value ?? false;
                            if (value == true) rejectMap[uniqueKey] = false;
                          });
                        },
                      ),
                    ),
                    DataCell(
                      Checkbox(
                        activeColor: Colors.red,
                        value: rejectMap[uniqueKey] ?? false,
                        onChanged: (value) {
                          setState(() {
                            rejectMap[uniqueKey] = value ?? false;
                            if (value == true) approveMap[uniqueKey] = false;
                          });
                        },
                      ),
                    ),
                    DataCell(
                      rejectMap[uniqueKey] == true
                          ? SizedBox(
                        width: 150,
                        child: TextField(
                          style: const TextStyle(fontSize: 13),
                          onChanged: (value) => setState(() => rejectReasons[uniqueKey] = value),
                          decoration: const InputDecoration(
                            hintText: 'Required reason',
                            isDense: true,
                          ),
                        ),
                      )
                          : const Text('—', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getData() async {
    try {
      staffCode = await storage.read(key: 'Staff_Code');
      authToken = await storage.read(key: 'Auth_Token');

      if (authToken != null && isVerified == true) {
        String reportingLevelStaffCode;
        String flag;

        if (loggedInStaffCode.toUpperCase() == "CD00490") {
          reportingLevelStaffCode = "CD00490";
          flag = "P";
        } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
          reportingLevelStaffCode = "MDIR003";
          flag = "S";
        } else {
          reportingLevelStaffCode = "CD00490";
          flag = "P";
        }

        mainBloc.add(AllApproveSanctionEvents(
          ReportingLevelStaffCode: reportingLevelStaffCode,
          Flag: flag,
          token: authToken!,
        ));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching data: $e");
    }
  }

  List<SanctionRequestModel> _buildSubmissionData() {
    return _records.where((record) {
      final uniqueKey = '${record.staffCode}_${record.tid}';
      return (approveMap[uniqueKey] ?? false) || (rejectMap[uniqueKey] ?? false);
    }).map((record) {
      final uniqueKey = '${record.staffCode}_${record.tid}';
      String numericTtlDays = RegExp(r'\d+').stringMatch(record.daysHours) ?? '0';

      return SanctionRequestModel(
        tid: record.tid.toString(),
        staffCode: record.staffCode,
        requestType: record.type,
        ttlDays: numericTtlDays,
        sDate: record.date,
        eDate: record.eDate,
        appRadio: approveMap[uniqueKey] ?? false,
        rejRadio: rejectMap[uniqueKey] ?? false,
        rejectReason: rejectMap[uniqueKey] == true ? (rejectReasons[uniqueKey] ?? '') : '',
        approvalRadio: _status == 'Approved',
        sanctionRadio: _status == 'Sanctioned',
      );
    }).toList();
  }

  @override
  void dispose() {
    staffController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

///
// class _SanctionRequestState extends State<SanctionRequest> {
//   String? _status = 'Approved'; // Default selected value
//   late MainBloc mainBloc;
//   final storage = FlutterSecureStorage();
//   late bool _isLoading = false;
//   String? staffCode = "";
//   String? authToken = "";
//   List<ApprovedSanctionRecords> _records = [];
//   Map<String, String> rejectReasons = {};
//   Map<String, bool> approveMap = {};
//   Map<String, bool> rejectMap = {};
//
//   final TextEditingController staffController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   bool isVerified = false;   // controls UI switch
//   bool enablePassword = false;
//   String loginError = "";    // Track login error
//
//   // ✅ Track which type of staff logged in
//   String loggedInStaffCode = "";
//
//   @override
//   void initState() {
//     super.initState();
//     mainBloc = BlocProvider.of<MainBloc>(context);
//     // Reset authentication state on init
//     isVerified = false;
//     loginError = "";
//   }
//
//   void _onStatusChanged(String? value) {
//     setState(() {
//       _status = value;
//     });
//
//     if (authToken != null && isVerified == true) {
//       print("Status Changed: $_status");
//
//       // ✅ Determine ReportingLevelStaffCode and Flag based on logged in staff code
//       String reportingLevelStaffCode;
//       String flag;
//
//       if (loggedInStaffCode.toUpperCase() == "CD00490") {
//         // For CD00490 - Only Approved
//         reportingLevelStaffCode = "CD00490";
//         flag = "P";
//       } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
//         // For MDIR003 - Only Sanctioned
//         reportingLevelStaffCode = "MDIR003";
//         flag = "S";
//       } else {
//         // Default based on selection
//         reportingLevelStaffCode = _status == 'Approved' ? 'CD00490' : 'MDIR003';
//         flag = _status == 'Approved' ? 'P' : 'S';
//       }
//
//       print("ReportingLevelStaffCode: $reportingLevelStaffCode");
//       print("Flag: $flag");
//       print("AuthToken: $authToken");
//
//       mainBloc.add(AllApproveSanctionEvents(
//         ReportingLevelStaffCode: reportingLevelStaffCode,
//         Flag: flag,
//         token: authToken!,
//       ));
//     }
//   }
//
//   void onCheckList() {
//     setState(() {
//       loginError = "";
//     });
//
//     if (staffController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Enter Staff Code");
//       return;
//     }
//
//     if (passwordController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Enter Password");
//       return;
//     }
//
//     // Call LOGIN via Bloc
//     mainBloc.add(LoginEvents(
//       username: staffController.text,
//       password: passwordController.text,
//     ));
//   }
//
//   // ✅ Method to refresh sanction data after submission
//   void refreshSanctionData() {
//     if (authToken != null && isVerified == true) {
//       String reportingLevelStaffCode;
//       String flag;
//
//       if (loggedInStaffCode.toUpperCase() == "CD00490") {
//         reportingLevelStaffCode = "CD00490";
//         flag = "P";
//       } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
//         reportingLevelStaffCode = "MDIR003";
//         flag = "S";
//       } else {
//         reportingLevelStaffCode = staffController.text;
//         flag = 'P';
//       }
//
//       mainBloc.add(AllApproveSanctionEvents(
//         ReportingLevelStaffCode: reportingLevelStaffCode,
//         Flag: flag,
//         token: authToken!,
//       ));
//     }
//   }
//
//   // ✅ Method to clear all selection states
//   void clearSelectionStates() {
//     setState(() {
//       approveMap.clear();
//       rejectMap.clear();
//       rejectReasons.clear();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sanction/Reject'),
//       ),
//       body: BlocListener<MainBloc, MainState>(
//         listener: (context, state) async {
//           // LOGIN STATES
//           if (state is LoginLoadingState) {
//             setState(() {
//               _isLoading = true;
//               loginError = "";
//             });
//           }
//           else if (state is LoginLoadedState) {
//             String? token = state.loginResponse?.token?.result?.token;
//
//             if (token != null && token.isNotEmpty) {
//               setState(() {
//                 _isLoading = false;
//                 isVerified = true;
//                 authToken = token;
//                 loggedInStaffCode = staffController.text; // ✅ Store logged in staff code
//                 loginError = "";
//               });
//
//               // ✅ Call appropriate sanction API based on staff code
//               String reportingLevelStaffCode;
//               String flag;
//
//               if (loggedInStaffCode.toUpperCase() == "CD00490") {
//                 reportingLevelStaffCode = "CD00490";
//                 flag = "P";
//                 _status = "Approved"; // ✅ Set default status
//               } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
//                 reportingLevelStaffCode = "MDIR003";
//                 flag = "S";
//                 _status = "Sanctioned"; // ✅ Set default status
//               } else {
//                 reportingLevelStaffCode = staffController.text;
//                 flag = "P";
//               }
//
//               mainBloc.add(AllApproveSanctionEvents(
//                 ReportingLevelStaffCode: reportingLevelStaffCode,
//                 Flag: flag,
//                 token: authToken!,
//               ));
//             } else {
//               setState(() {
//                 _isLoading = false;
//                 isVerified = false;
//                 authToken = null;
//                 loginError = "Invalid Staff Code or Password";
//               });
//               Fluttertoast.showToast(msg: "Please enter valid credentials");
//             }
//           }
//           else if (state is LoginErrorState) {
//             setState(() {
//               _isLoading = false;
//               isVerified = false;
//               authToken = null;
//               loginError = "Login Failed. Please check your credentials.";
//             });
//             Fluttertoast.showToast(msg: "Please enter valid credentials");
//           }
//
//           // SANCTION STATES (only if authenticated)
//           if (isVerified == true) {
//             if (state is ApproveSanctionLoadingState) {
//               setState(() => _isLoading = true);
//             }
//             else if (state is ApproveSanctionLoadedState) {
//               setState(() {
//                 _isLoading = false;
//                 _records = state.approvedsanctionrecords;
//                 // ✅ Clear selection states when new data is loaded
//                 clearSelectionStates();
//               });
//             }
//             else if (state is ApproveSanctionErrorState) {
//               setState(() => _isLoading = false);
//               Fluttertoast.showToast(msg: "Failed To Connect Server!");
//             }
//           }
//
//           // ✅ SUBMIT SANCTION STATES
//           if (state is SubmitApprovesanctionLoadingState) {
//             setState(() => _isLoading = true);
//           }
//           else if (state is SubmitApprovesanctionLoadedState) {
//             setState(() => _isLoading = false);
//
//             // ✅ Handle success message
//             String message = state.sanctionrequestmodels.toString();
//
//             clearSelectionStates();
//
//             // Small delay to ensure toast is shown before refresh
//             Future.delayed(Duration(milliseconds: 500), () {
//               // Refresh the sanction list
//               refreshSanctionData();
//               Fluttertoast.showToast(msg: "Data refreshed successfully");
//             });
//           }
//           else if (state is SubmitApproveSanctionErrorState) {
//             setState(() => _isLoading = false);
//             Fluttertoast.showToast(msg: "Failed to submit. Please try again.");
//           }
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : isVerified
//               ? _buildMainContent()
//               : _buildLoginUI(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoginUI() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'Enter Details',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//
//           TextField(
//             controller: staffController,
//             decoration: const InputDecoration(
//               labelText: 'Staff Code',
//               border: OutlineInputBorder(),
//             ),
//             onChanged: (value) {
//               setState(() {
//                 enablePassword = value.isNotEmpty;
//                 loginError = "";
//               });
//             },
//           ),
//
//           const SizedBox(height: 20),
//
//           TextField(
//             controller: passwordController,
//             enabled: enablePassword,
//             obscureText: true,
//             decoration: const InputDecoration(
//               labelText: 'Password',
//               border: OutlineInputBorder(),
//             ),
//             onChanged: (value) {
//               setState(() {
//                 loginError = "";
//               });
//             },
//           ),
//
//           if (loginError.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 12.0),
//               child: Text(
//                 loginError,
//                 style: TextStyle(color: Colors.red, fontSize: 14),
//               ),
//             ),
//
//           const SizedBox(height: 20),
//
//           ElevatedButton(
//             onPressed: onCheckList,
//             child: const Text("Check List"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMainContent() {
//     // ✅ Determine if radio buttons should be shown based on staff code
//     bool showApprovedRadio = loggedInStaffCode.toUpperCase() == "CD00490";
//     bool showSanctionedRadio = loggedInStaffCode.toUpperCase() == "MDIR003";
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Reporting Staff Code: ${staffController.text}',
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             // ✅ Add Refresh button
//             IconButton(
//               icon: Icon(Icons.refresh, color: Colors.blue),
//               onPressed: () {
//                 refreshSanctionData();
//                 Fluttertoast.showToast(msg: "Refreshing data...");
//               },
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 10),
//
//         const Text(
//           'Sanction/Approve/Reject',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//
//         const SizedBox(height: 20),
//
//         // ✅ Show radio buttons based on staff code
//         Row(
//           children: [
//             if (showApprovedRadio) ...[
//               Radio<String>(
//                 value: 'Approved',
//                 groupValue: _status,
//                 onChanged: _onStatusChanged,
//               ),
//               const Text('Approved'),
//             ],
//             if (showSanctionedRadio) ...[
//               const SizedBox(width: 20),
//               Radio<String>(
//                 value: 'Sanctioned',
//                 groupValue: _status,
//                 onChanged: _onStatusChanged,
//               ),
//               const Text('Sanctioned'),
//             ],
//             // If neither, show both (fallback)
//             if (!showApprovedRadio && !showSanctionedRadio) ...[
//               Radio<String>(
//                 value: 'Approved',
//                 groupValue: _status,
//                 onChanged: _onStatusChanged,
//               ),
//               const Text('Approved'),
//               const SizedBox(width: 20),
//               Radio<String>(
//                 value: 'Sanctioned',
//                 groupValue: _status,
//                 onChanged: _onStatusChanged,
//               ),
//               const Text('Sanctioned'),
//             ],
//           ],
//         ),
//
//         const SizedBox(height: 20),
//
//         Expanded(
//           child: _records.isNotEmpty
//               ? _buildDataTable(_records)
//               : const Center(child: Text('No data available.')),
//         ),
//
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 // Check if any record is selected
//                 bool hasSelected = false;
//                 for (var record in _records) {
//                   final key = '${record.staffCode}_${record.tid}';
//                   if (approveMap[key] == true || rejectMap[key] == true) {
//                     hasSelected = true;
//                     break;
//                   }
//                 }
//
//                 if (!hasSelected) {
//                   Fluttertoast.showToast(msg: "Please select at least one record to approve or reject");
//                   return;
//                 }
//
//                 // Validate reject reasons
//                 bool isValid = true;
//                 for (var record in _records) {
//                   final key = '${record.staffCode}_${record.tid}';
//                   if (rejectMap[key] == true &&
//                       (rejectReasons[key]?.isEmpty ?? true)) {
//                     isValid = false;
//                     Fluttertoast.showToast(
//                         msg: 'Enter reject reason for ${record.name}');
//                     break;
//                   }
//                 }
//
//                 if (isValid) {
//                   mainBloc.add(SubmitSactionEvents(
//                     sanctionmodels: _buildSubmissionData(),
//                     token: authToken!,
//                   ));
//                 }
//               },
//               child: const Text('Submit'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // Reset and go back
//                 setState(() {
//                   isVerified = false;
//                   _records.clear();
//                   approveMap.clear();
//                   rejectMap.clear();
//                   rejectReasons.clear();
//                   staffController.clear();
//                   passwordController.clear();
//                   loginError = "";
//                   loggedInStaffCode = "";
//                 });
//                 Navigator.pop(context);
//               },
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDataTable(List<ApprovedSanctionRecords> records) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.vertical,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columns: const [
//             DataColumn(label: Text('Staff Code')),
//             DataColumn(label: Text('Name')),
//             DataColumn(label: Text('Date')),
//             DataColumn(label: Text('Request Type')),
//             DataColumn(label: Text('Days/Hrs')),
//             DataColumn(label: Text('Coff/GptType')),
//             DataColumn(label: Text('Status')),
//             DataColumn(label: Text('Approve')),
//             DataColumn(label: Text('Reject')),
//             DataColumn(label: Text('Reject Reason')),
//           ],
//           rows: List<DataRow>.generate(
//             records.length,
//                 (index) {
//               final record = records[index];
//               final String uniqueKey = '${record.staffCode}_${record.tid}';
//
//               return DataRow(
//                 cells: [
//                   DataCell(Text(record.staffCode)),
//                   DataCell(Text(record.name)),
//                   DataCell(Text(record.date)),
//                   DataCell(Text(record.type)),
//                   DataCell(Text(record.daysHours)),
//                   DataCell(Text(record.coffType)),
//                   DataCell(Text(record.aFlag)),
//
//                   // Approve Checkbox
//                   DataCell(
//                     Checkbox(
//                       value: approveMap[uniqueKey] ?? false,
//                       onChanged: (value) {
//                         setState(() {
//                           approveMap[uniqueKey] = value ?? false;
//                           if (value == true) {
//                             rejectMap[uniqueKey] = false;
//                           }
//                         });
//                       },
//                     ),
//                   ),
//
//                   // Reject Checkbox
//                   DataCell(
//                     Checkbox(
//                       value: rejectMap[uniqueKey] ?? false,
//                       onChanged: (value) {
//                         setState(() {
//                           rejectMap[uniqueKey] = value ?? false;
//                           if (value == true) {
//                             approveMap[uniqueKey] = false;
//                           }
//                         });
//                       },
//                     ),
//                   ),
//
//                   // Reject Reason TextField
//                   DataCell(
//                     rejectMap[uniqueKey] == true
//                         ? TextField(
//                       onChanged: (value) {
//                         setState(() {
//                           rejectReasons[uniqueKey] = value;
//                         });
//                       },
//                       decoration: const InputDecoration(
//                         hintText: 'Enter reason',
//                       ),
//                     )
//                         : const Text(''),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> getData() async {
//     try {
//       staffCode = await storage.read(key: 'Staff_Code');
//       authToken = await storage.read(key: 'Auth_Token');
//
//       if (authToken != null && isVerified == true) {
//         String reportingLevelStaffCode;
//         String flag;
//
//         if (loggedInStaffCode.toUpperCase() == "CD00490") {
//           reportingLevelStaffCode = "CD00490";
//           flag = "P";
//         } else if (loggedInStaffCode.toUpperCase() == "MDIR003") {
//           reportingLevelStaffCode = "MDIR003";
//           flag = "S";
//         } else {
//           reportingLevelStaffCode = "CD00490";
//           flag = "P";
//         }
//
//         mainBloc.add(AllApproveSanctionEvents(
//           ReportingLevelStaffCode: reportingLevelStaffCode,
//           Flag: flag,
//           token: authToken!,
//         ));
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error fetching data: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         timeInSecForIosWeb: 1,
//       );
//     }
//   }
//
//   List<SanctionRequestModel> _buildSubmissionData() {
//     return _records.where((record) {
//       final uniqueKey = '${record.staffCode}_${record.tid}';
//       bool isApproved = approveMap[uniqueKey] ?? false;
//       bool isRejected = rejectMap[uniqueKey] ?? false;
//       return isApproved || isRejected;
//     }).map((record) {
//       final uniqueKey = '${record.staffCode}_${record.tid}';
//       String numericTtlDays = RegExp(r'\d+').stringMatch(record.daysHours) ?? '0';
//
//       return SanctionRequestModel(
//         tid: record.tid.toString(),
//         staffCode: record.staffCode,
//         requestType: record.type,
//         ttlDays: numericTtlDays,
//         sDate: record.date,
//         eDate: record.eDate,
//         appRadio: approveMap[uniqueKey] ?? false,
//         rejRadio: rejectMap[uniqueKey] ?? false,
//         rejectReason: rejectMap[uniqueKey] == true ? (rejectReasons[uniqueKey] ?? '') : '',
//         approvalRadio: _status == 'Approved',
//         sanctionRadio: _status == 'Sanctioned',
//       );
//     }).toList();
//   }
//
//   @override
//   void dispose() {
//     staffController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
// }



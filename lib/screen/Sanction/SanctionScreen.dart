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


class _SanctionRequestState extends State<SanctionRequest> {
  String? _status = 'Approved'; // Default selected value
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

  bool isVerified = false;   // controls UI switch
  bool enablePassword = false;// To store reject reasons for each record

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);
    //getData();
  }

  void _onStatusChanged(String? value) {
    setState(() {
      _status = value;
    });

    if (authToken != null) {
      print("Status Changed: $_status");
      print("ReportingLevelStaffCode: ${_status == 'Approved' ? 'CD00490' : 'MDIR003'}");
      print("Flag: ${_status == 'Approved' ? 'P' : 'S'}");
      print("AuthToken: $authToken");

      mainBloc.add(AllApproveSanctionEvents(
        ReportingLevelStaffCode: _status == 'Approved' ? 'CD00490' : 'MDIR003',
        Flag: _status == 'Approved' ? 'P' : 'S',
        token: authToken!,
      ));
    }
  }

  void onCheckList() {
    if (staffController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Staff Code");
      return;
    }

    if (passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Password");
      return;
    }

    // 🔹 Call LOGIN via Bloc
    mainBloc.add(LoginEvents(
      username: staffController.text,
      password: passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanction/Reject'),
      ),
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) async {

          // 🔹 LOGIN STATES
          if (state is LoginLoadingState) {
            setState(() => _isLoading = true);
          }
          else if (state is LoginLoadedState) {
            setState(() {
              _isLoading = false;
              isVerified = true;
              authToken = authToken = state.loginResponse?.token?.result?.token;
            });

            // 🔹 Call sanction API AFTER login success
            mainBloc.add(AllApproveSanctionEvents(
              ReportingLevelStaffCode: staffController.text,
              Flag: 'P',
              token: authToken!,
            ));
          }
          else if (state is LoginErrorState) {
            setState(() => _isLoading = false);
            Fluttertoast.showToast(msg: "Login Failed");
          }

          // 🔹 SANCTION STATES
          if (state is ApproveSanctionLoadingState) {
            setState(() => _isLoading = true);
          }
          else if (state is ApproveSanctionLoadedState) {
            setState(() {
              _isLoading = false;
              _records = state.approvedsanctionrecords;
            });
          }
          else if (state is ApproveSanctionErrorState) {
            setState(() => _isLoading = false);
            Fluttertoast.showToast(msg: "Failed To Connect Server!");
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : isVerified
              ? _buildMainContent()
              : _buildLoginUI(),
        ),
      ),
    );
  }
  Widget _buildLoginUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 🔹 Staff Code
          TextField(
            controller: staffController,
            decoration: const InputDecoration(
              labelText: 'Staff Code',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                enablePassword = value.isNotEmpty;
              });
            },
          ),

          const SizedBox(height: 20),

          // 🔹 Password
          TextField(
            controller: passwordController,
            enabled: enablePassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: onCheckList,
            child: const Text("Check List"),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporting Staff Code: ${staffController.text}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        const Text(
          'Sanction/Approve/Reject',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Radio<String>(
              value: 'Approved',
              groupValue: _status,
              onChanged: _onStatusChanged,
            ),
            const Text('Approved'),
          ],
        ),

        const SizedBox(height: 20),

          Expanded(
            child: _records.isNotEmpty
                ? _buildDataTable(_records)
                : const Center(child: Text('No data available.')),
          ),
          // child: BlocListener<MainBloc, MainState>(
          //   listener: (context, state) async {
          //     if (state is ApproveSanctionLoadingState) {
          //       setState(() => _isLoading = true);
          //     } else if (state is ApproveSanctionLoadedState) {
          //       setState(() {
          //         _isLoading = false;
          //         _records = state.approvedsanctionrecords;
          //       });
          //     } else if (state is ApproveSanctionErrorState) {
          //       setState(() => _isLoading = false);
          //       Fluttertoast.showToast(msg: "Failed To Connect Server!");
          //     }
          //
          //     if (state is LoginLoadingState) {
          //       setState(() => _isLoading = true);
          //     }
          //     else if (state is LoginLoadedState) {
          //       setState(() {
          //         _isLoading = false;
          //         isVerified = true;
          //         authToken = state.loginResponse?.token.toString(); // adjust based on your model
          //       });
          //
          //       // 🔹 Now call sanction API AFTER login success
          //       mainBloc.add(AllApproveSanctionEvents(
          //         ReportingLevelStaffCode: staffController.text,
          //         Flag: 'P',
          //         token: authToken!,
          //       ));
          //     }
          //     else if (state is LoginErrorState) {
          //       setState(() => _isLoading = false);
          //
          //       Fluttertoast.showToast(
          //         msg: "Login Failed",
          //       );
          //     }
          //   },
          //   child: _isLoading
          //       ? const Center(child: CircularProgressIndicator())
          //       : _records.isNotEmpty
          //       ? _buildDataTable(_records)
          //       : const Center(child: Text('No data available.')),
          // ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                bool isValid = true;

                for (var record in _records) {
                  final key = '${record.staffCode}_${record.tid}';
                  if (rejectMap[key] == true &&
                      (rejectReasons[key]?.isEmpty ?? true)) {
                    isValid = false;
                    Fluttertoast.showToast(
                        msg: 'Enter reject reason for ${record.name}');
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
              child: const Text('Submit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
/*  Widget _buildDataTable(List<ApprovedSanctionRecords> records) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Staff Code')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Request Type')),
          DataColumn(label: Text('Days/Hrs')),
          DataColumn(label: Text('Coff/GptType')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Approve')),
          DataColumn(label: Text('Reject')),
          DataColumn(label: Text('Reject Reason')),
        ],
        rows: List<DataRow>.generate(
          records.length,
              (index) {
            final record = records[index];
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
                  Radio<String>(
                    value: 'Approve',
                    groupValue: rejectReasons[index], // Unique to this row using index
                    onChanged: (value) {
                      setState(() {
                        rejectReasons[index as String] = 'Approve';
                      });
                    },
                  ),
                ),
                DataCell(
                  Radio<String>(
                    value: 'Reject',
                    groupValue: rejectReasons[index], // Unique to this row using index
                    onChanged: (value) {
                      setState(() {
                        // Check if a reason is already entered
                        if (rejectReasons[index] != 'Approve' &&
                            (rejectReasons[index]?.isEmpty ?? true)) {
                          Fluttertoast.showToast(
                            msg: 'Please provide a reason for rejection.',
                            toastLength: Toast.LENGTH_SHORT,
                            timeInSecForIosWeb: 1,
                          );
                        } else {
                          rejectReasons[index as String] = 'Reject';
                        }
                      });
                    },
                  ),
                ),
                DataCell(
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        rejectReasons[index as String] = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter reason',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }*/

  Widget _buildDataTable(List<ApprovedSanctionRecords> records) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Staff Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Request Type')),
              DataColumn(label: Text('Days/Hrs')),
              DataColumn(label: Text('Coff/GptType')),
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

                    // ✅ Approve Checkbox
                    DataCell(
                      Checkbox(
                        value: approveMap[uniqueKey] ?? false,
                        onChanged: (value) {
                          setState(() {
                            approveMap[uniqueKey] = value ?? false;
                            // Ensure only one action is selected at a time
                            if (value == true) {
                              rejectMap[uniqueKey] = false;  // Deselect reject when approve is selected
                            }
                          });
                        },
                      ),
                    ),

                    DataCell(
                      Checkbox(
                        value: rejectMap[uniqueKey] ?? false,
                        onChanged: (value) {
                          setState(() {
                            rejectMap[uniqueKey] = value ?? false;
                            // Ensure only one action is selected at a time
                            if (value == true) {
                              approveMap[uniqueKey] = false;  // Deselect approve when reject is selected
                            }
                          });
                        },
                      ),
                    ),


                    // ✅ Reject Reason TextField (visible only if Reject is checked)
                    DataCell(
                      rejectMap[uniqueKey] == true
                          ? TextField(
                        onChanged: (value) {
                          setState(() {
                            rejectReasons[uniqueKey] = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Enter reason',
                        ),
                      )
                          : const Text(''), // Empty if reject is not checked
                    ),
                  ],
                );
              },
            ),
          ),
        ),
    );
  }

  Future<void> getData() async {
    try {
      staffCode = await storage.read(key: 'Staff_Code');
      authToken = await storage.read(key: 'Auth_Token');

      if (authToken != null) {
        mainBloc.add(AllApproveSanctionEvents(
          ReportingLevelStaffCode: 'CD00490', // Example staff code
          Flag: 'P', // Example flag
          token: authToken!,
        ));
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error fetching data: $e",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
  }

  List<SanctionRequestModel> _buildSubmissionData() {
    return _records.where((record) {
      final uniqueKey = '${record.staffCode}_${record.tid}';

      // ✅ Filter only the selected records
      bool isApproved = approveMap[uniqueKey] ?? false;
      bool isRejected = rejectMap[uniqueKey] ?? false;

      return isApproved || isRejected;  // Only include selected records
    }).map((record) {
      final uniqueKey = '${record.staffCode}_${record.tid}';

      // ✅ Extract only the numerical part using regex
      String numericTtlDays = RegExp(r'\d+').stringMatch(record.daysHours) ?? '0';

      return SanctionRequestModel(
        tid: record.tid.toString(),
        staffCode: record.staffCode,
        requestType: record.type,
        ttlDays: numericTtlDays,      // ✅ Use only the numerical part
        sDate: record.date,
        eDate: record.eDate,

        // ✅ Use the map values directly for bool flags
        appRadio: approveMap[uniqueKey] ?? false,
        rejRadio: rejectMap[uniqueKey] ?? false,
        rejectReason: rejectMap[uniqueKey] == true ? (rejectReasons[uniqueKey] ?? '') : '',
        approvalRadio: _status == 'Approved',
        sanctionRadio: _status == 'Sanctioned',
      );
    }).toList();
  }

}





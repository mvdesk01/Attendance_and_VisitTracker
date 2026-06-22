import 'package:attendance_system_ios/screen/Leave/apply_leave.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/Leave/LeavePendingResponse.dart';
import 'leave.dart';

class AddLeavePage extends StatefulWidget {
  final int flag; // Accept the flag value
  final dynamic leaveData;

  const AddLeavePage({super.key, required this.flag, required this.leaveData});

  @override
  _AddLeavePageState createState() => _AddLeavePageState();
}

class _AddLeavePageState extends State<AddLeavePage> {
  bool isUpdate = true;
  final leaveTypes = ['Please Select', 'CL', 'PL', 'SL', 'LWP'];
  String selectedLeaveType = 'Please Select';
  bool showNextScreenContent = false;
  bool fromTimeSelected = false;
  TextEditingController _StaffcodeController = new TextEditingController();
  TextEditingController _StaffnameController = new TextEditingController();
  TextEditingController _StaffplantnameController = new TextEditingController();
  TextEditingController _StaffdepartmentnameController =
      new TextEditingController();
  TextEditingController _StaffDOJController = new TextEditingController();
  final TextEditingController leaveBalanceController = TextEditingController();
  late Message leaveDetailss;
  late String transactioniD;
  bool showTable = false; // Track whether the table should be displayed
  List<Map<String, String>> leaveDetails = []; // Table data
  DateTime selectedDate = DateTime.now();
  late String date = '';
  List<String> yearlist = [];
  String year = "2026";
  bool isYearselected = false;
  bool ClickStatus = false;
  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    print("Received Flag: ${widget.flag}");
    mainBloc = BlocProvider.of(context);

    getData();
  }

  Future<void> getData() async {
    print("Received Flag: ${widget.flag}");

    // Retrieve staff code and token
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("authtoken->" + Auth_Token!);

    // Set leave details from the widget
    // leaveDetailss = widget.leaveData;
    if (widget.leaveData != null) {
      leaveDetailss = widget.leaveData;
      print("leaveDetails --> " + leaveDetailss.transactionId.toString());
    } else {
      print("leaveData is null. Creating an empty instance.");
      leaveDetailss = Message(); // Create a default Message instance
    }

    //transactioniD = leaveDetailss.transactionId.toString();

    print("Auth_Token-->${Auth_Token!}");
    print(leaveDetailss);
    print("leaveDetails -->" + leaveDetailss.transactionId.toString());

    mainBloc
        .add(GetLeaveStaffDetails(StaffCode: staffCode!, token: Auth_Token!));
  }

  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider(
                          create: (context) {
                            return MainBloc(webService: WebService());
                          },
                          child: PendingLeave())))),
          title: const Text("Apply For Leave"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
        ),
        body: BlocListener<MainBloc, MainState>(
          listener: (context, state) {
            if (state is GetLeaveStaffDetailsLoadingtstate) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is GetLeaveStaffDetailsLoadedtstate) {
              setState(() {
                _isLoading = false;
              });

              _StaffcodeController.text =
                  state.staffdetails.message!.staffCode!;
              _StaffnameController.text = state.staffdetails.message!.fullName!;
              _StaffplantnameController.text =
                  state.staffdetails.message!.plantName!;
              _StaffdepartmentnameController.text =
                  state.staffdetails.message!.department!;
              _StaffDOJController.text = "05/02/2025";
              // parseAndSetDate(state.staffdetails.message!.dateOfJoining);
              print(state.staffdetails.message?.dateOfJoining);
              Fluttertoast.showToast(
                msg: "Success!",
                toastLength: Toast.LENGTH_SHORT,
              );
            } else if (state is GetLeaveStaffDetailsErrorState) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(
                msg: "Failed To Connect Server!",
                toastLength: Toast.LENGTH_SHORT,
              );
            }

            if (state is GetLeaveTypeLoadingState) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is GetLeaveTypeLoadedState) {
              setState(() {
                _isLoading = false;
                leaveDetails = state.leavedetails.leaveTypes!.map((detail) {
                  return {
                    'Code': detail.leaveTypeCode.toString(),
                    'Leave Type': detail.leaveTypeName.toString(),
                    'Days Remaining': detail.daysRemaining.toString(),
                    'Total Days': detail.totalDays.toString(),
                    'Min Days Allowed': detail.minDaysAllowed.toString(),
                    'Max Days Allowed': detail.maxDaysAllowed.toString(),
                  };
                }).toList();
              });
            } else if (state is GetLeaveTypeErrorState) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(msg: "No Leave Details Found");
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Staff code row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: _StaffcodeController,
                          decoration: InputDecoration(
                            labelText: 'Staff Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          //Fluttertoast.showToast(msg: "under progress");
                          setState(() {
                            showTable = true;
                          });
                          if (staffCode != null && Auth_Token != null) {
                            mainBloc.add(GetLeavetypeEvents(
                              StaffCode: staffCode!,
                              token: Auth_Token!,
                              Year: year,
                            ));
                            print("error" + staffCode! + Auth_Token! + year);
                          }
                        },
                        child: Text('OK'),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: year,
                        items: ['2026']
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            year = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Table
                  if (showTable && leaveDetails.isNotEmpty)
                    Table(
                      border: TableBorder.all(),
                      columnWidths: {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(4),
                        3: FlexColumnWidth(3),
                        4: FlexColumnWidth(4),
                        5: FlexColumnWidth(4),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[300]),
                          children: [
                            TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Code',
                                        textAlign: TextAlign.center))),
                            TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Leave Type',
                                        textAlign: TextAlign.center))),
                            TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Days Remaining',
                                        textAlign: TextAlign.center))),
                            TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Total Days',
                                        textAlign: TextAlign.center))),
                            TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Min Days Allowed',
                                        textAlign: TextAlign.center))),
                            TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Max Days Allowed',
                                        textAlign: TextAlign.center))),
                          ],
                        ),
                        ...leaveDetails.map((row) {
                          return TableRow(
                            children: row.values.map((cell) {
                              return TableCell(
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(cell,
                                        textAlign: TextAlign.center)),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ],
                    ),
                  SizedBox(height: 20),

                  // Staff name controller
                  TextField(
                    readOnly: true,
                    controller: _StaffnameController,
                    decoration: InputDecoration(
                      labelText: 'Staff Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Plant name and department row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: _StaffplantnameController,
                          decoration: InputDecoration(
                            labelText: 'Plant Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _StaffdepartmentnameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Date of joining controller
                  // TextField(
                  //   controller: _StaffDOJController,
                  //   decoration: InputDecoration(
                  //     labelText: 'Date of Joining',
                  //     border: OutlineInputBorder(),
                  //   ),
                  // ),
                  SizedBox(height: 20),

                  // Navigation button
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Store the selected year in FlutterSecureStorage
                        await storage.write(key: 'selectedYear', value: year);
                        await storage.write(
                            key: 'stafcodeee', value: staffCode);
                        await storage.write(
                            key: 'authtokenn', value: Auth_Token);
                        await storage.write(
                            key: 'staffname', value: _StaffnameController.text);
                        await storage.write(
                            key: 'doj', value: _StaffDOJController.text);
                        await storage.write(
                            key: 'plantname',
                            value: _StaffplantnameController.text);
                        await storage.write(
                            key: 'department',
                            value: _StaffdepartmentnameController.text);
                        // await storage.write(key:"leavetypecode",value: )
                        print((key: 'stafcodeee', value: staffCode));
                        // Navigate to the next page

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: BlocProvider.of<MainBloc>(context),
                              child: LeaveDetailsPage(
                                flag: 1,
                                tokennn: Auth_Token!,
                                leaveData: leaveDetailss,
                              ),
                            ),
                          ),
                        ).then((result) {
                          // This will be called when the details page is popped
                          if (result == true) {
                            getData(); // Refresh your data
                          }
                        });
                      },
                      child: Text('Next Page'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void parseAndSetDate(String? originalDOJ) {
    print("Received DOJ: '$originalDOJ'"); // Debugging output

    if (originalDOJ != null && originalDOJ.trim().isNotEmpty) {
      // Trim spaces and check
      try {
        String formattedDate = _formatDate(originalDOJ);
        _StaffDOJController.text = formattedDate;
      } catch (e) {
        _StaffDOJController.text = "Invalid Date Format";
        print("Error setting DOJ: $e");
      }
    } else {
      _StaffDOJController.text = "N/A";
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    try {
      // Remove extra spaces
      String cleanedDate = date.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Define the input format
      DateFormat inputFormat = DateFormat("MMM d yyyy h:mma");
      // Define the output format
      DateFormat outputFormat = DateFormat("dd/MM/yyyy");

      // Parse and format the date
      DateTime parsedDate = inputFormat.parse(cleanedDate);
      return outputFormat.format(parsedDate);
    } catch (e) {
      print("Error parsing date: $e");
      return "Invalid Date";
    }
  }
}

///new ui
// class _AddLeavePageState extends State<AddLeavePage> {
//   // ... Keep all your existing variables/logic here ...
//   bool isUpdate = true;
//   final leaveTypes = ['Please Select', 'CL', 'PL', 'SL', 'LWP'];
//   String selectedLeaveType = 'Please Select';
//   bool showNextScreenContent = false;
//   bool fromTimeSelected = false;
//   TextEditingController _StaffcodeController = TextEditingController();
//   TextEditingController _StaffnameController = TextEditingController();
//   TextEditingController _StaffplantnameController = TextEditingController();
//   TextEditingController _StaffdepartmentnameController =
//       TextEditingController();
//   TextEditingController _StaffDOJController = TextEditingController();
//   final TextEditingController leaveBalanceController = TextEditingController();
//   late Message leaveDetailss;
//   bool showTable = false;
//   List<Map<String, String>> leaveDetails = [];
//   String year = "2026";
//   String? staffCode = "";
//   String? Auth_Token = "";
//   late bool _isLoading = false;
//   late MainBloc mainBloc;
//   final storage = const FlutterSecureStorage();
//
//   @override
//   void initState() {
//     super.initState();
//     mainBloc = BlocProvider.of<MainBloc>(context);
//     getData();
//   }
//
//   Future<void> getData() async {
//     print("Received Flag: ${widget.flag}");
//
//     // Retrieve staff code and token
//     staffCode = await storage.read(key: 'Staff_Code');
//     print("staffCode-->" + staffCode!);
//     Auth_Token = await storage.read(key: 'Auth_Token');
//     print("authtoken->" + Auth_Token!);
//
//     // Set leave details from the widget
//     // leaveDetailss = widget.leaveData;
//     if (widget.leaveData != null) {
//       leaveDetailss = widget.leaveData;
//       print("leaveDetails --> " + leaveDetailss.transactionId.toString());
//     } else {
//       print("leaveData is null. Creating an empty instance.");
//       leaveDetailss = Message(); // Create a default Message instance
//     }
//
//     //transactioniD = leaveDetailss.transactionId.toString();
//
//     print("Auth_Token-->${Auth_Token!}");
//     print(leaveDetailss);
//     print("leaveDetails -->" + leaveDetailss.transactionId.toString());
//
//     mainBloc
//         .add(GetLeaveStaffDetails(StaffCode: staffCode!, token: Auth_Token!));
//   }
//
//   // ... [Keep your getData() and formatting logic identical] ...
//
//   @override
//   Widget build(BuildContext context) {
//     return LoadingOverlay(
//       isLoading: _isLoading,
//       opacity: 0.3,
//       color: Colors.white,
//       progressIndicator: const CircularProgressIndicator(),
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF4F7FA), // Modern subtle background
//         appBar: AppBar(
//           elevation: 0,
//           toolbarHeight: 70,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                 color: Colors.white, size: 22),
//             onPressed: () => _navigateToPending(),
//           ),
//           title: Text(
//             "Apply Leave Request",
//             style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white),
//           ),
//           backgroundColor: MyColors.lightBlue,
//           centerTitle: true,
//         ),
//         body: BlocListener<MainBloc, MainState>(
//           listener: _handleStateChanges,
//           child: Column(
//             children: [
//               // _buildStepIndicator(),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildYearSelectionRow(),
//                       const SizedBox(height: 25),
//                       _buildInfoSection(),
//                       const SizedBox(height: 25),
//                       if (showTable && leaveDetails.isNotEmpty)
//                         _buildLeaveBalanceTable(),
//                       const SizedBox(height: 40),
//                       _buildNextButton(),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStepIndicator() {
//     return Container(
//       color: MyColors.lightBlue,
//       padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
//       child: Row(
//         children: [
//           _stepCircle("1", "Details", true),
//           _stepLine(false),
//           _stepCircle("2", "Duration", false),
//         ],
//       ),
//     );
//   }
//
//   Widget _stepCircle(String num, String label, bool isActive) {
//     return Row(
//       children: [
//         CircleAvatar(
//           radius: 14,
//           backgroundColor: isActive ? Colors.white : Colors.white24,
//           child: Text(num,
//               style: TextStyle(
//                   color: isActive ? MyColors.lightBlue : Colors.white,
//                   fontWeight: FontWeight.bold)),
//         ),
//         const SizedBox(width: 8),
//         Text(label,
//             style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                 fontSize: 16)),
//       ],
//     );
//   }
//
//   Widget _stepLine(bool isActive) {
//     return Expanded(
//       child: Container(
//         height: 2,
//         margin: const EdgeInsets.symmetric(horizontal: 15),
//         color: isActive ? Colors.white : Colors.white24,
//       ),
//     );
//   }
//
//   Widget _buildYearSelectionRow() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("ACADEMIC YEAR",
//                     style: GoogleFonts.poppins(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey)),
//                 DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     value: year,
//                     isExpanded: true,
//                     style: GoogleFonts.poppins(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87),
//                     items: ['2026']
//                         .map((y) => DropdownMenuItem(value: y, child: Text(y)))
//                         .toList(),
//                     onChanged: (v) => setState(() => year = v!),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 15),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: MyColors.lightBlue,
//               padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//             ),
//             onPressed: _fetchLeaveDetails,
//             child: const Text("CHECK BALANCE",
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("STAFF INFORMATION",
//             style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blueGrey)),
//         const SizedBox(height: 12),
//         _infoCard(
//             "Staff Name", _StaffnameController.text, Icons.person_outline),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//                 child: _infoCard("Staff Code", _StaffcodeController.text,
//                     Icons.badge_outlined)),
//             const SizedBox(width: 12),
//             Expanded(
//                 child: _infoCard("Dept", _StaffdepartmentnameController.text,
//                     Icons.account_tree_outlined)),
//           ],
//         ),
//         const SizedBox(height: 12),
//         _infoCard("Plant / Location", _StaffplantnameController.text,
//             Icons.location_on_outlined),
//       ],
//     );
//   }
//
//   Widget _infoCard(String label, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: MyColors.lightBlue, size: 24),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
//               Text(value.isEmpty ? "---" : value,
//                   style: GoogleFonts.poppins(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLeaveBalanceTable() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("LEAVE BALANCE DETAILS",
//             style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blueGrey)),
//         const SizedBox(height: 12),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
//               columns: const [
//                 DataColumn(
//                     label: Text('Type',
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 DataColumn(
//                     label: Text('Remaining',
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 DataColumn(
//                     label: Text('Total',
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 DataColumn(
//                     label: Text('Min/Max Allowed',
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//               ],
//               rows: leaveDetails
//                   .map((row) => DataRow(cells: [
//                         DataCell(Text(row['Code'] ?? '',
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue))),
//                         DataCell(Text(row['Days Remaining'] ?? '',
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold))),
//                         DataCell(Text(row['Total Days'] ?? '')),
//                         DataCell(Text(
//                             "${row['Min Days Allowed']}/${row['Max Days Allowed']}")),
//                       ]))
//                   .toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildNextButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 60,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green.shade600,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           elevation: 3,
//         ),
//         onPressed: _handleNextPage,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text("PROCEED TO DATES",
//                 style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white)),
//             const SizedBox(width: 10),
//             const Icon(Icons.arrow_forward_rounded, color: Colors.white),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // --- Logic Helper Methods ---
//
//   void _navigateToPending() {
//     Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (_) => BlocProvider(
//                 create: (context) => MainBloc(webService: WebService()),
//                 child: PendingLeave())));
//   }
//
//   void _fetchLeaveDetails() {
//     setState(() => showTable = true);
//     if (staffCode != null && Auth_Token != null) {
//       mainBloc.add(GetLeavetypeEvents(
//           StaffCode: staffCode!, token: Auth_Token!, Year: year));
//     }
//   }
//
//   void _handleNextPage() async {
//     await storage.write(key: 'selectedYear', value: year);
//     await storage.write(key: 'stafcodeee', value: staffCode);
//     await storage.write(key: 'authtokenn', value: Auth_Token);
//     await storage.write(key: 'staffname', value: _StaffnameController.text);
//     await storage.write(
//         key: 'plantname', value: _StaffplantnameController.text);
//     await storage.write(
//         key: 'department', value: _StaffdepartmentnameController.text);
//
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => BlocProvider.value(
//             value: BlocProvider.of<MainBloc>(context),
//             child: LeaveDetailsPage(
//                 flag: 1, tokennn: Auth_Token!, leaveData: leaveDetailss),
//           ),
//         )).then((result) {
//       if (result == true) getData();
//     });
//   }
//
//   void _handleStateChanges(context, state) {
//     if (state is GetLeaveStaffDetailsLoadingtstate) {
//       setState(() => _isLoading = true);
//     } else if (state is GetLeaveStaffDetailsLoadedtstate) {
//       setState(() {
//         _isLoading = false;
//         _StaffcodeController.text = state.staffdetails.message!.staffCode!;
//         _StaffnameController.text = state.staffdetails.message!.fullName!;
//         _StaffplantnameController.text = state.staffdetails.message!.plantName!;
//         _StaffdepartmentnameController.text =
//             state.staffdetails.message!.department!;
//       });
//     } else if (state is GetLeaveStaffDetailsErrorState) {
//       setState(() => _isLoading = false);
//       Fluttertoast.showToast(msg: "Failed to connect to server");
//     } else if (state is GetLeaveTypeLoadedState) {
//       setState(() {
//         _isLoading = false;
//         leaveDetails = state.leavedetails.leaveTypes!
//             .map((detail) => {
//                   'Code': detail.leaveTypeCode.toString(),
//                   'Days Remaining': detail.daysRemaining.toString(),
//                   'Total Days': detail.totalDays.toString(),
//                   'Min Days Allowed': detail.minDaysAllowed.toString(),
//                   'Max Days Allowed': detail.maxDaysAllowed.toString(),
//                 })
//             .toList();
//       });
//     }
//   }
// }

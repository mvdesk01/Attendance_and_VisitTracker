import 'package:attendance_system_ios/screen/Leave/apply_leave.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
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
  TextEditingController _StaffdepartmentnameController = new TextEditingController();
  TextEditingController _StaffDOJController = new TextEditingController();
  final TextEditingController leaveBalanceController = TextEditingController();
  late Message leaveDetailss;
  late String transactioniD;
  bool showTable = false; // Track whether the table should be displayed
  List<Map<String, String>> leaveDetails = []; // Table data
  DateTime selectedDate = DateTime.now();
  late String date = '';
  List<String> yearlist = [];
  String year = "2025";
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
    print("authtoken->"+Auth_Token!);

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
    print( leaveDetailss);
    print("leaveDetails -->" + leaveDetailss.transactionId.toString());

    mainBloc.add(
        GetLeaveStaffDetails(StaffCode: staffCode!, token: Auth_Token!));
  }

  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading:IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () =>
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BlocProvider(
                              create: (context) {
                                return MainBloc(
                                    webService: WebService());
                              },
                              child: PendingLeave())))

          ),
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
            }
            else if (state is GetLeaveStaffDetailsLoadedtstate) {
              setState(() {
                _isLoading = false;
              });

              _StaffcodeController.text = state.staffdetails.message!.staffCode!;
              _StaffnameController.text = state.staffdetails.message!.fullName!;
              _StaffplantnameController.text = state.staffdetails.message!.plantName!;
              _StaffdepartmentnameController.text = state.staffdetails.message!.department!;
              _StaffDOJController.text = "05/02/2025";
              // parseAndSetDate(state.staffdetails.message!.dateOfJoining);
              print(state.staffdetails.message?.dateOfJoining);
              Fluttertoast.showToast(
                msg: "Success!",
                toastLength: Toast.LENGTH_SHORT,
              );
            }
            else if (state is GetLeaveStaffDetailsErrorState) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(
                msg: "Failed To Connect Server!",
                toastLength: Toast.LENGTH_SHORT,
              );
            }

            if(state is GetLeaveTypeLoadingState ){
              setState(() {
                _isLoading=true;
              });

            }
            else if (state is GetLeaveTypeLoadedState) {
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
            }
            else if(state is GetLeaveTypeErrorState){
              setState(() {
                _isLoading=false;
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
                            showTable=true;
                          });
                          if (staffCode != null && Auth_Token != null) {
                            mainBloc.add(GetLeavetypeEvents(
                              StaffCode: staffCode!,
                              token: Auth_Token!,
                              Year: year,
                            ));
                            print("error"+ staffCode! + Auth_Token! + year);
                          }
                        },
                        child: Text('OK'),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: year,
                        items: ['2024', '2025','2026']
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
                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Code', textAlign: TextAlign.center))),
                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Leave Type', textAlign: TextAlign.center))),
                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Days Remaining', textAlign: TextAlign.center))),
                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Total Days', textAlign: TextAlign.center))),
                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Min Days Allowed', textAlign: TextAlign.center))),
                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Max Days Allowed', textAlign: TextAlign.center))),
                          ],
                        ),
                        ...leaveDetails.map((row) {
                          return TableRow(
                            children: row.values.map((cell) {
                              return TableCell(
                                child: Padding(padding: EdgeInsets.all(8.0), child: Text(cell, textAlign: TextAlign.center)),
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

/*                  // Date of joining controller
                  TextField(
                    controller: _StaffDOJController,
                    decoration: InputDecoration(
                      labelText: 'Date of Joining',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),*/

                  // Navigation button
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Store the selected year in FlutterSecureStorage
                        await storage.write(key: 'selectedYear', value: year);
                        await storage.write(key: 'stafcodeee', value: staffCode);
                        await storage.write(key: 'authtokenn', value: Auth_Token);
                        await storage.write(key: 'staffname', value: _StaffnameController.text);
                        await storage.write(key: 'doj', value: _StaffDOJController.text);
                        await storage.write(key: 'plantname', value: _StaffplantnameController.text);
                        await storage.write(key: 'department', value: _StaffdepartmentnameController.text);
                        print((key: 'stafcodeee', value: staffCode));
                        // Navigate to the next page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider<MainBloc>(
                              create: (context) => MainBloc(webService: WebService()),
                              child: LeaveDetailsPage(
                                flag: 1,
                                tokennn: Auth_Token!,
                                leaveData: leaveDetailss,
                              ),
                            ),
                          ),
                        );
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

    if (originalDOJ != null && originalDOJ.trim().isNotEmpty) { // Trim spaces and check
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

//LEAVE
/*
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/Leave/CancelLeave.dart';
import '../../util/MyColor.dart';
import 'add_leave.dart';
import 'apply_leave.dart';

class PendingLeave extends StatefulWidget {
  const PendingLeave({super.key});

  @override
  State<PendingLeave> createState() => _PendingLeaveState();
}

class _PendingLeaveState extends State<PendingLeave> {
  late bool _isLoading = false;
  bool showtable = false;
  bool isUpdate = true;


  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staffCode="";
  String? Auth_Token="";
  String ApprovedFlag="P";
  late List<Message> pendingLeaveList=[];

  ScrollController vendorRecordController = new ScrollController();

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    // Ensure both staffCode and Auth_Token are not null or empty
    if (staffCode == null || staffCode!.isEmpty) {
      // Handle error: staffCode should be valid
      Fluttertoast.showToast(msg: "Staff code is missing!");
      return;
    }

    if (Auth_Token == null || Auth_Token!.isEmpty) {
      // Handle error: Auth_Token should be valid
      Fluttertoast.showToast(msg: "Auth token is missing!");
      return;
    }

    ApprovedFlag = "P"; // Change based on your requirements

    print("StaffCode: $staffCode, Auth_Token: $Auth_Token, ApprovedFlag: $ApprovedFlag");

    // Make the API call
    mainBloc.add(GetPendingLeaveEvents(
        StaffCode: staffCode!,
        token: Auth_Token!,
        ApprovedFlag: ApprovedFlag
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar:
      AppBar(
          leading: IconButton(
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
                          child: HomeScreen())))
          ),

          title: const Text(" Leave "),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(
            color: Colors.white,
          )
      ),

      body: */
/*const Center(
        child: Text("Gate Pass Screen", style: TextStyle(fontFamily: 'Dubai'),),
      )*/
/*
WillPopScope(
        onWillPop: () async {
          */
/*   Navigator.pop(context, {"FilterAlert":false});
            return false;*/
/*

          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // You can also handle custom back button logic here
            // For example, exit the app, show a confirmation dialog, etc.

            print("Else Navigatorrrrrrrrrrrrr");

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(
                              webService: WebService());
                        },
                        child: HomeScreen())));
            return false;  // Prevent the app from closing
          }
          return true;
        },
        child:
        _leavescreen(),),

      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.lightBlue,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: AddLeavePage(
                  flag: 1,
                  leaveData: pendingLeaveList.isNotEmpty ? pendingLeaveList.first: null,
                  // Pass first leave data if available
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  _leavescreen() {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: CircularProgressIndicator(
        backgroundColor: Color(0xFFCE4A6F),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
      child: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          // Handling Pending Leave State Changes
          if (state is GetPendingLeaveLoadingStatae) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is GetPendingLeaveLoadedState) {
            setState(() {
              _isLoading = false;
              pendingLeaveList.clear();
              pendingLeaveList.addAll(state.leavependingresponse.message!);
            });

            Fluttertoast.showToast(
              msg: "   Success!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
          else if (state is GetPendingLeaveErrorState) {
            setState(() {
              _isLoading = false;

            });
            Fluttertoast.showToast(
              msg: "Error in fetching data!!.",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }

          // Handling Cancel Leave State Changes
          if (state is GetCancelLeaveLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is GetCancelLeaveLoadedState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(msg: "Leave record deleted successfully!");
            pendingLeaveList.removeWhere((leave) => leave.transactionId == state.cancelleavebodyy?.tid);
          } else if (state is GetCancelLeaveErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "Failed to delete leave: ${state.msg}",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
        },
        child: pendingLeaveList.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/icons/no_data.png", // Ensure this image exists in your assets folder
                height: 150,
              ),
              SizedBox(height: 20),
              Text(
                "No Data Available",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        )
            : ListView.builder(
          controller: vendorRecordController,
          shrinkWrap: true,
          itemCount: pendingLeaveList.length,
          itemBuilder: (context, index) {
            Message leave = pendingLeaveList[index];
            return Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("STATUS: PENDING",
                            style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.greenColorCode)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider(
                                      create: (context) => MainBloc(webService: WebService()),
                                      child: LeaveDetailsPage(flag: 2, leaveData: pendingLeaveList[index]),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 32,
                                margin: EdgeInsets.only(top: 7, left: 20),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                decoration: BoxDecoration(
                                    color: MyColors.blueColorCode,
                                    borderRadius: BorderRadius.all(Radius.circular(10))),
                                child: Text(
                                  "EDIT",
                                  style: TextStyle(color: MyColors.whiteColorCode, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showDeleteDialog(context, leave);
                              },
                              child: Container(
                                height: 32,
                                margin: EdgeInsets.only(left: 20),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                decoration: BoxDecoration(
                                    color: MyColors.redColorCode, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  "DELETE",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.whiteColorCode, fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildRow("Applied Date", _formatDate(leave.transactionDate)),
                    _buildRow("From Date", _formatDate(leave.startingDate)),
                    _buildRow("To Date", _formatDate(leave.endingDate)),
                    _buildRow("Reason", leave.reason ?? "N/A"),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

// Helper to Build Rows
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: MyColors.textprofiledetailColorCode, fontSize: 18)),
          Text(value, style: TextStyle(color: MyColors.text5ColorCode, fontSize: 18)),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
  }
// Show Delete Dialog
  void _showDeleteDialog(BuildContext context, Message leave) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Leave"),
          content: Text("Are you sure you want to delete this leave record?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("No",style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteLeave(context, leave);
              },
              child: Text("Yes",style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// Call Cancel Leave API
  Future<void> _deleteLeave(BuildContext context, Message leave) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      CancelLeaveBody request = CancelLeaveBody(
        flag: "C",
        tid: leave.transactionId.toString(),
        rReason: leave.reason ?? "",
        staffcode: staffCode!,
      );

      // Dispatch the cancel leave event
      mainBloc.add(CancelLeaveEvents(
        cancelleavebody: request,
        token: Auth_Token!,
      ));

      // Immediately remove the item from the list
      setState(() {
        pendingLeaveList.removeWhere((item) => item.transactionId == leave.transactionId); // Corrected predicate
      });

      Fluttertoast.showToast(msg: "Leave record deleted successfully!");
      LogFileManager.writeLog("delete record $request");
    } catch (e) {
      LogFileManager.writeLog("delete record $e");
      Fluttertoast.showToast(msg: "Failed to delete leave: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

}
// appBar: AppBar(
//   leading: IconButton(
//     icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//     onPressed: () => Navigator.of(context).pop(),
//   ),
//   title: const Text("Leave"),
//   backgroundColor: MyColors.lightBlue,
//   centerTitle: true,
//   titleTextStyle: GoogleFonts.roboto(
//     fontWeight: FontWeight.bold,
//     fontSize: 18.0,
//   ).copyWith(
//     color: Colors.white,
//   ),
// ),
// body: WillPopScope(
//   onWillPop: () async {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     } else {
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => BlocProvider(
//                   create: (context) {
//                     return MainBloc(webService: WebService());
//                   },
//                   child: HomeScreen())));
//       return false;
//     }
//     return true;
//   },
//   child: _leavescreen(),
// ),
*/

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/Leave/CancelLeave.dart';
import '../../util/MyColor.dart';
import 'add_leave.dart';
import 'apply_leave.dart';

class PendingLeave extends StatefulWidget {
  const PendingLeave({super.key});

  @override
  State<PendingLeave> createState() => _PendingLeaveState();
}

class _PendingLeaveState extends State<PendingLeave> {
  late bool _isLoading = false;
  bool showtable = false;
  bool isUpdate = true;


  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode="";
  String? Auth_Token="";
  String ApprovedFlag="P";
  late List<Message> pendingLeaveList=[];

  ScrollController vendorRecordController = new ScrollController();

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    //Ensure both staffCode and Auth_Token are not null or empty
    if (staffCode == null || staffCode!.isEmpty) {
      // Handle error: staffCode should be valid
      Fluttertoast.showToast(msg: "Staff code is missing!");
      return;
    }

    if (Auth_Token == null || Auth_Token!.isEmpty) {
      // Handle error: Auth_Token should be valid
      Fluttertoast.showToast(msg: "Auth token is missing!");
      return;
    }

    ApprovedFlag = "P"; // Change based on your requirements

    print("StaffCode: 'cd03184', Auth_Token: $Auth_Token, ApprovedFlag: $ApprovedFlag");

    // Make the API call
    mainBloc.add(GetPendingLeaveEvents(
        StaffCode: staffCode!,
        token: Auth_Token!,
        ApprovedFlag: ApprovedFlag
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar:
      AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () =>
              (Navigator.canPop(context))? Navigator.pop(context):   Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider(
                          create: (context) {
                            return MainBloc(
                                webService: WebService());
                          },
                          child: HomeScreen())))
          ),

          title: const Text(" Leave "),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(
            color: Colors.white,
          )
      ),

      body: /*const Center(
        child: Text("Gate Pass Screen", style: TextStyle(fontFamily: 'Dubai'),),
      )*/WillPopScope(
        onWillPop: () async {
          /*   Navigator.pop(context, {"FilterAlert":false});
            return false;*/
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // You can also handle custom back button logic here
            // For example, exit the app, show a confirmation dialog, etc.

            print("Else Navigatorrrrrrrrrrrrr");

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(
                              webService: WebService());
                        },
                        child: HomeScreen())));
            return false;  // Prevent the app from closing
          }
          return true;
        },
        child:
        _leavescreen(),),

      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.lightBlue,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: AddLeavePage(
                  flag: 1,
                  leaveData: pendingLeaveList.isNotEmpty ? pendingLeaveList.first: null,
                  // Pass first leave data if available
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  _leavescreen() {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: CircularProgressIndicator(
        backgroundColor: Color(0xFFCE4A6F),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
      child: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          // Handling Pending Leave State Changes
          if (state is GetPendingLeaveLoadingStatae) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is GetPendingLeaveLoadedState) {
            setState(() {
              _isLoading = false;
              pendingLeaveList.clear();
              pendingLeaveList.addAll(state.leavependingresponse.message!);
            });

            Fluttertoast.showToast(
              msg: "   Success!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
          //////Response Body: Availiable leave is less than leave entered / Leave Already Pending for particular leave type
          // ///Response Body: Leaves Not Applicable for Staff!!
          // // I/flutter (23822): Response Status Code: 200
          // // I/flutter (23822): Response Status Code: 200
          else if (state is GetPendingLeaveErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "Error in fetching data!!.",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }

          // Handling Cancel Leave State Changes
          if (state is GetCancelLeaveLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is GetCancelLeaveLoadedState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(msg: "Leave record deleted successfully!");
            pendingLeaveList.removeWhere((leave) => leave.transactionId == state.cancelleavebodyy?.tid);
          } else if (state is GetCancelLeaveErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "Failed to delete leave: ${state.msg}",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
        },
        child: pendingLeaveList.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/icons/no_data.png", // Ensure this image exists in your assets folder
                height: 150,
              ),
              SizedBox(height: 20),
              Text(
                "No Data Available",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        )
            : ListView.builder(
          controller: vendorRecordController,
          shrinkWrap: true,
          itemCount: pendingLeaveList.length,
          itemBuilder: (context, index) {
            Message leave = pendingLeaveList[index];
            return Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("STATUS: PENDING",
                            style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.greenColorCode)),
                        Row(
                          children: [
                            GestureDetector(
                              // onTap: () async {
                              //
                              //   await Navigator.of(context)
                              //       .push(
                              //     new MaterialPageRoute(
                              //         builder: (_) =>
                              //             BlocProvider(
                              //                 create: (context) {
                              //                   return MainBloc(webService: WebService());
                              //                 },
                              //                 child: LeaveDetailsPage(flag: 2,tokennn: Auth_Token! ,leaveData:  pendingLeaveList[index])
                              //             )
                              //     ),
                              //   );
                              // },
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider(
                                        create: (context) => MainBloc(webService: WebService()),
                                        child: LeaveDetailsPage(flag: 2, tokennn: Auth_Token!, leaveData: pendingLeaveList[index])
                                    ),
                                  ),
                                );
                                // Refresh data after returning from edit
                                getData();
                              },
                              child: Container(
                                height: 32,
                                margin: EdgeInsets.only(top: 7, left: 20),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                decoration: BoxDecoration(
                                    color: MyColors.blueColorCode,
                                    borderRadius: BorderRadius.all(Radius.circular(10))),
                                child: Text(
                                  "EDIT",
                                  style: TextStyle(color: MyColors.whiteColorCode, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showDeleteDialog(context, leave);
                              },
                              child: Container(
                                height: 32,
                                margin: EdgeInsets.only(left: 20),
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                decoration: BoxDecoration(
                                    color: MyColors.redColorCode, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  "DELETE",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.whiteColorCode, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildRow("Applied Date", _formatDate(leave.transactionDate)),
                    _buildRow("From Date", _formatDate(leave.startingDate)),
                    _buildRow("To Date", _formatDate(leave.endingDate)),
                    _buildRow("Reason", leave.reason ?? "N/A"),
                    _buildRow('Leave', leave.leaveTypeCode!),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

// Helper to Build Rows
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: MyColors.black, fontSize: 18)),
          Text(value, style: TextStyle(color: MyColors.black, fontSize: 18)),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
  }
// Show Delete Dialog
  void _showDeleteDialog(BuildContext context, Message leave) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Leave"),
          content: Text("Are you sure you want to delete this leave record?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("No",style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteLeave(context, leave);
              },
              child: Text("Yes",style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// Call Cancel Leave API
  Future<void> _deleteLeave(BuildContext context, Message leave) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      CancelLeaveBody request = CancelLeaveBody(
        flag: "C",
        tid: leave.transactionId.toString(),
        rReason: leave.reason ?? "",
        staffcode: staffCode!,
      );

      // Dispatch the cancel leave event
      mainBloc.add(CancelLeaveEvents(
        cancelleavebody: request,
        token: Auth_Token!,
      ));

      // Immediately remove the item from the list
      setState(() {
        pendingLeaveList.removeWhere((item) => item.transactionId == leave.transactionId); // Corrected predicate
      });

      Fluttertoast.showToast(msg: "Leave record deleted successfully!");
      LogFileManager.writeLog("delete record $request");
    } catch (e) {
      LogFileManager.writeLog("delete record $e");
      Fluttertoast.showToast(msg: "Failed to delete leave: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

}
// appBar: AppBar(
//   leading: IconButton(
//     icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//     onPressed: () => Navigator.of(context).pop(),
//   ),
//   title: const Text("Leave"),
//   backgroundColor: MyColors.lightBlue,
//   centerTitle: true,
//   titleTextStyle: GoogleFonts.roboto(
//     fontWeight: FontWeight.bold,
//     fontSize: 18.0,
//   ).copyWith(
//     color: Colors.white,
//   ),
// ),
// body: WillPopScope(
//   onWillPop: () async {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     } else {
//       Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (_) => BlocProvider(
//                   create: (context) {
//                     return MainBloc(webService: WebService());
//                   },
//                   child: HomeScreen())));
//       return false;
//     }
//     return true;
//   },
//   child: _leavescreen(),
// ),

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/Leave/CancelLeave.dart';
import '../../service/log_file_manager.dart';
import '../../util/MyColor.dart';
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

  String? staffCode = "";
  String? Auth_Token = "";
  String ApprovedFlag = "P";
  late List<Message> pendingLeaveList = [];

  ScrollController vendorRecordController = ScrollController();

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    if (staffCode == null || staffCode!.isEmpty) {
      Fluttertoast.showToast(msg: "Staff code is missing!");
      return;
    }

    if (Auth_Token == null || Auth_Token!.isEmpty) {
      Fluttertoast.showToast(msg: "Auth token is missing!");
      return;
    }

    ApprovedFlag = "P";

    print(
        "StaffCode: 'cd03184', Auth_Token: $Auth_Token, ApprovedFlag: $ApprovedFlag");

    mainBloc.add(GetPendingLeaveEvents(
        StaffCode: staffCode!, token: Auth_Token!, ApprovedFlag: ApprovedFlag));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => (Navigator.canPop(context))
                ? Navigator.pop(context)
                : Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: HomeScreen())))),
        title: const Text(
          "Leave",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ).copyWith(
          color: Colors.white,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            print("Else Navigatorrrrrrrrrrrrr");
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(webService: WebService());
                        },
                        child: HomeScreen())));
            return false;
          }
          return true;
        },
        child: _leavescreen(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyColors.lightBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Apply Leave",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          // KEEP EXISTING CODE
        },
      ),
    );
  }

  _leavescreen() {
    // SOLUTION 1: Use BlocBuilder instead of BlocListener for UI
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        // Handle loading states
        if (state is GetPendingLeaveLoadingStatae) {
          _isLoading = true;
        } else if (state is GetPendingLeaveLoadedState) {
          _isLoading = false;

          // 🔥 ALWAYS RESET FIRST
          pendingLeaveList = [];

          if (state.leavependingresponse.message != null &&
              state.leavependingresponse.message!.isNotEmpty) {
            pendingLeaveList = List.from(state.leavependingresponse.message!);
          }

          print("Updated List Count: ${pendingLeaveList.length}");
        } else if (state is GetPendingLeaveErrorState) {
          _isLoading = false;
          print("GetPendingLeaveErrorState mess: ${state.msg}");
          LogFileManager.writeLog("Error in fetching leave data: ${state.msg}");
        } else if (state is GetCancelLeaveLoadingState) {
          _isLoading = true;
        } else if (state is GetCancelLeaveLoadedState) {
          _isLoading = false;
          Fluttertoast.showToast(msg: "Leave record deleted successfully!");
          pendingLeaveList.clear();
          // Refresh data
          getData();
        } else if (state is GetCancelLeaveErrorState) {
          _isLoading = false;
          Fluttertoast.showToast(
            msg: "Failed to delete leave: ${state.msg}",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        }

        return LoadingOverlay(
          isLoading: _isLoading,
          opacity: 0.5,
          color: Colors.white,
          progressIndicator: CircularProgressIndicator(
            backgroundColor: Color(0xFFCE4A6F),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          child: RefreshIndicator(
            onRefresh: getData,
            child: pendingLeaveList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/no_data.png",
                            height: 170,
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            "No Pending Leave",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the Apply Leave button to create a leave request.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    // key: UniqueKey(),
                    // Force rebuild when list changes
                    controller: vendorRecordController,
                    shrinkWrap: true,
                    itemCount: pendingLeaveList.length,
                    itemBuilder: (context, index) {
                      Message leave = pendingLeaveList[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1, color: MyColors.textBoxBorderColorCode),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.green,
                                          size: 8,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Pending",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Your gesture detector content
                                      Container(
                                        height: 32,
                                        margin:
                                            EdgeInsets.only(top: 7, left: 20),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: MyColors.blueColorCode,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        child: OutlinedButton.icon(
                                          icon:
                                              const Icon(Icons.edit, size: 18),
                                          label: const Text("Edit"),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                MyColors.blueColorCode,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BlocProvider(
                                                  create: (context) => MainBloc(
                                                      webService: WebService()),
                                                  child: LeaveDetailsPage(
                                                    flag: 2,
                                                    tokennn: Auth_Token!,
                                                    leaveData:
                                                        pendingLeaveList[index],
                                                  ),
                                                ),
                                              ),
                                            );
                                            // Refresh data if update was successful
                                            if (result == true) {
                                              getData();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        height: 32,
                                        margin:
                                            EdgeInsets.only(top: 7, left: 20),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: MyColors.redColorCode,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18),
                                          label: const Text("Delete"),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          onPressed: () {
                                            _showDeleteDialog(context, leave);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              _infoTile(
                                Icons.calendar_today,
                                "Applied Date",
                                _formatDate(leave.transactionDate),
                              ),
                              const SizedBox(height: 12),
                              _infoTile(
                                Icons.event,
                                "From Date",
                                _formatDate(leave.startingDate),
                              ),
                              const SizedBox(height: 12),
                              _infoTile(
                                Icons.event_available,
                                "To Date",
                                _formatDate(leave.endingDate),
                              ),
                              const SizedBox(height: 12),
                              _infoTile(
                                Icons.info_outline,
                                "Reason",
                                leave.reason ?? "N/A",
                              ),
                              const SizedBox(height: 12),
                              _infoTile(
                                Icons.category_outlined,
                                "Leave Type",
                                leave.leaveTypeCode ?? "",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: MyColors.lightBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                Navigator.of(context).pop();
              },
              child: Text("No", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteLeave(context, leave);
              },
              child: Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLeave(BuildContext context, Message leave) async {
    try {
      CancelLeaveBody request = CancelLeaveBody(
        flag: "C",
        tid: leave.transactionId.toString(),
        rReason: leave.reason ?? "",
        staffcode: staffCode!,
      );

      mainBloc.add(CancelLeaveEvents(
        cancelleavebody: request,
        token: Auth_Token!,
      ));

      LogFileManager.writeLog("delete record $request");
    } catch (e) {
      LogFileManager.writeLog("delete record $e");
      Fluttertoast.showToast(msg: "Failed to delete leave: $e");
    }
  }
}

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingDataByVisitSrNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMALLDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMRowDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/UpdateMMAllData.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/UpdateMMData.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Visit%20History/Visit_History_Screen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/DialogForUpdate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';

// import '../../model/GatePass/GatePassResponse.dart';
import '../../util/MyColor.dart';

class MinutesOfTheMeetingFormScreen extends StatefulWidget {
  late String visitSrNo;
  late String minuteforno;

  MinutesOfTheMeetingFormScreen(
      {Key? key, required this.visitSrNo, required this.minuteforno})
      : super(key: key);

  @override
  State<MinutesOfTheMeetingFormScreen> createState() =>
      _MinutesOfTheMeetingFormScreenState();
}

class _MinutesOfTheMeetingFormScreenState
    extends State<MinutesOfTheMeetingFormScreen> {
  TextEditingController _gatepassdatecontroller = new TextEditingController();
  TextEditingController _memberAbsentController = new TextEditingController();
  TextEditingController _memberPresentController = new TextEditingController();
  TextEditingController _subjectController = new TextEditingController();
  TextEditingController _purposecontroller = new TextEditingController();

  bool isUpdateMode = false;
  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  DateTime selectedDate = DateTime.now();
  late String date = '';
  List<String> gatepasstypeList = [];
  List<String> gatepassReasonsList = [];
  String gatePasstype = "Select";
  String gatePassReason = "Select";
  bool isGatepasscontainerselected = false;
  bool isReasoncontainerselected = false;
  bool ClickStatus = false;
  var fromTimeController;
  TextEditingController fromTimeInput = TextEditingController();
  var toTimeController;
  TextEditingController toTimeInput = TextEditingController();
  String srno = "";
  String SRNOtable = "";
  String? Auth_Token = "";

  String? staffCode = "";

  String designation = "";

  String departmentName = "";
  List<Widget> dynamicRows = [];
  bool _isFormEdited = false;
  List<GlobalKey<_DynamicRowState>> rowKeys = [];
  TextEditingController dateController1 = TextEditingController();
  TextEditingController dateController2 = TextEditingController();
  TextEditingController textFieldController1 = TextEditingController();
  TextEditingController textFieldController2 = TextEditingController();
  TextEditingController textFieldController3 = TextEditingController();
  TextEditingController textFieldController4 = TextEditingController();
  TextEditingController textFieldController5 = TextEditingController();
  List<Message> listofRows = [];
  int index = 0;

  @override
  void initState() {
    mainBloc = BlocProvider.of(context);
    print("srno:+${widget.visitSrNo}");
    print("minuteforno +${widget.minuteforno}");
    gatepasstypeList.add("Personal");
    gatepasstypeList.add("Official");
    gatepasstypeList.add("Lunch");
    gatepassReasonsList.add("Birthday");
    gatepassReasonsList.add("Client Visit");
    gatepassReasonsList.add("Late Coming");
    gatepassReasonsList.add("Lunch");
    gatepassReasonsList.add("Official Work");
    gatepassReasonsList.add("Personal Work");
    gatepassReasonsList.add("Marriage Anniversary");
    getData();
    setState(() {
      dateController1.text = "TARGET DATE";
      dateController2.text = "NEXT TARGET DATE";
      textFieldController1.text = "POINT/ISSUE";
      textFieldController2.text = "DISCUSSED WITH";
      textFieldController3.text = "DECISION TAKEN / ACTION PLAN";
      textFieldController4.text = "RESPONSIBILITY";
      textFieldController5.text = "STATUS / REMARK";
    });
    //getminutesdata();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->" + Auth_Token!);

    mainBloc.add(GetMinutesOfTheMeetingAllDataByVisitSrNoEvents(
        token: Auth_Token!, SrNo: widget.visitSrNo));

    mainBloc.add(GetMinutesOfTheMeetingDataByVisitSrNoEvents(
        token: Auth_Token!, VisitSrNo: widget.visitSrNo));
    // GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));
    /*dynamicRows.add(DynamicRow(
      index: index,
      onDelete: (int deleteIndex) => deleteRow(deleteIndex),
    ));
    index++;*/
  }

  // void getminutesdata() {
  //
  //   mainBloc.add(GetMinutesOfTheMeetingAllDataByVisitSrNoEvents(SrNo: widget.visitSrNo, token: Auth_Token!));
  // }

  void getAllRowsData() {
    List<Map<String, String>> allRowsData = [];

    // Iterate over each row and use the GlobalKey to access the state and fetch data
    for (var key in rowKeys) {
      Map<String, String> rowData = key.currentState!.getRowData();
      allRowsData.add(rowData);
    }
    print("allRowsData : " + allRowsData.length.toString());

    // Printing the data of all rows
    for (var rowData in allRowsData) {
      print(rowData);
    }

    if (allRowsData.length == 0) {
      Fluttertoast.showToast(
        msg: "  Please Enter All Fields...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      for (int i = 0; i < allRowsData.length; i++) {
        Map<String, String> rowData = allRowsData.elementAt(i);
        print("rowData :" + rowData.length.toString());
        String pointsOrIssues = rowData['pointsOrIssues'].toString();

        if (rowData['pointsOrIssues']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter pointsOrIssues...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['discussedWith']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter discussedWith...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['decisionTaken']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter decisionTaken...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['responsibility']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter responsibility...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['statusOrRemark']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter statusOrRemark...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['targetDate']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter targetDate...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['nextDate']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter nextDate...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (i == allRowsData.length - 1) {
          //_updateMinutesOfTheMeetingForm(allRowsData);
          _addMinutesOfTheMeetingForm(allRowsData);
        }
        // break;
      }
    }
  }

  void getAllRowsDataupdate() {
    List<Map<String, String>> allRowsData = [];

    // Iterate over each row and use the GlobalKey to access the state and fetch data
    for (var key in rowKeys) {
      Map<String, String> rowData = key.currentState!.getRowData();
      allRowsData.add(rowData);
    }
    print("allRowsData : " + allRowsData.length.toString());

    // Printing the data of all rows
    for (var rowData in allRowsData) {
      print(rowData);
    }

    if (allRowsData.length == 0) {
      Fluttertoast.showToast(
        msg: "  Please Enter All Fields...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      for (int i = 0; i < allRowsData.length; i++) {
        Map<String, String> rowData = allRowsData.elementAt(i);
        print("rowData :" + rowData.length.toString());
        String pointsOrIssues = rowData['pointsOrIssues'].toString();

        if (rowData['pointsOrIssues']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter pointsOrIssues...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['discussedWith']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter discussedWith...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['decisionTaken']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter decisionTaken...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['responsibility']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter responsibility...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['statusOrRemark']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter statusOrRemark...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['targetDate']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter targetDate...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (rowData['nextDate']!.isEmpty) {
          Fluttertoast.showToast(
            msg: "  Please Enter nextDate...!  ",
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 1,
          );
        } else if (i == allRowsData.length - 1) {
          _updateMinutesOfTheMeetingForm(allRowsData);
          //_addMinutesOfTheMeetingForm(allRowsData);
        }
        // break;
      }
    }
  }

/*
  void addRow() {
    GlobalKey<_DynamicRowState> key = GlobalKey<_DynamicRowState>();

    setState(() {
      rowKeys.add(key);
      dynamicRows.add(
        DynamicRow(
          key: key,
          index: dynamicRows.length, // Use current length as new index
          onDelete: deleteRow,
        ),
      );
      index = dynamicRows.length;
    });

    print('Added row. Total rows now: ${dynamicRows.length}');
  }*/
  void addRow() {
    GlobalKey<_DynamicRowState> key = GlobalKey<_DynamicRowState>();

    setState(() {
      // Insert at the beginning (index 0) instead of adding at the end
      rowKeys.insert(0, key);

      // Create new row and insert at beginning
      dynamicRows.insert(
          0,
          DynamicRow(
            key: key,
            index: 0, // New row gets index 0
            onDelete: deleteRow,
          ));

      // Update indices for all existing rows
      for (int i = 0; i < dynamicRows.length; i++) {
        // Only update the row if it's not the newly added one (index 0)
        // We need to update the index property of each DynamicRow
        dynamicRows[i] = DynamicRow(
          key: rowKeys[i],
          index: i,
          onDelete: deleteRow,
        );
      }
    });

    // Wait for widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If nextDate empty → keep it grey
      if (key.currentState?.dateController2.text.isEmpty ?? true) {
        key.currentState?.enableNextDate();
      }
    });

    print('Added row at start. Total rows now: ${dynamicRows.length}');
  }

/*
  void deleteRow(int deleteIndex) {
    setState(() {
      dynamicRows.removeAt(deleteIndex);
      rowKeys.removeAt(deleteIndex);

      // 🔄 rebuild rows with up-to-date indices
      for (int i = 0; i < dynamicRows.length; i++) {
        dynamicRows[i] = DynamicRow(
          key: rowKeys[i],
          index: i, // ← new, correct index
          onDelete: deleteRow,
        );
      }
    });
  }*/

  void deleteRow(int deleteIndex) {
    if (deleteIndex < 0 || deleteIndex >= dynamicRows.length) {
      print("Invalid delete index: $deleteIndex");
      return; // ✅ prevents crash
    }

    setState(() {
      dynamicRows.removeAt(deleteIndex);
      rowKeys.removeAt(deleteIndex);

      // 🔄 Rebuild rows with correct indices
      for (int i = 0; i < dynamicRows.length; i++) {
        dynamicRows[i] = DynamicRow(
          key: rowKeys[i],
          index: i,
          onDelete: deleteRow,
        );
      }
    });
  }

  void addRowFromData(String points,
      String discussed,
      String decision,
      String responsibility,
      String status,
      String targetDate,
      String nextDate,
      int index) {
    GlobalKey<_DynamicRowState> key = GlobalKey<_DynamicRowState>();
    // rowKeys.add(key);
    //
    // final row = DynamicRow(
    //   key: key,
    //   index: index,
    //   onDelete: (int deleteIndex) {
    //     deleteRow(deleteIndex);
    //   },
    // );
    //
    // setState(() {
    //   dynamicRows.add(row);
    //   index++;
    // });
    setState(() {
      rowKeys.add(key);
      dynamicRows.add(
        DynamicRow(
          key: key,
          index: dynamicRows.length,
          onDelete: deleteRow,
        ),
      );
      index = dynamicRows.length;
    });
    // Set the data to controllers after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      key.currentState?.textFieldController1.text = points;
      key.currentState?.textFieldController2.text = discussed;
      key.currentState?.textFieldController3.text = decision;
      key.currentState?.textFieldController4.text = responsibility;
      key.currentState?.textFieldController5.text = status;
      key.currentState?.dateController1.text = targetDate;
      key.currentState?.dateController2.text = nextDate;
      if (nextDate
          .trim()
          .isEmpty) {
        key.currentState?.enableNextDate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              // Always navigate to VisitHistoryScreen and replace the current route
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BlocProvider(
                        create: (context) => MainBloc(webService: WebService()),
                        child: VisitHistoryScreen(),
                      ),
                ),
              );
            },
          ),
          title: const Text("Minutes Of The Meeting Form"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(
            color: Colors.white,
          )),
      body: WillPopScope(
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
                    builder: (_) =>
                        BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: HomeScreen())));
            return false; // Prevent the app from closing
          }
          return true;
        },
        child: _addForm(),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _gatepassdatecontroller.clear();
                    ClickStatus = false;
                    fromTimeInput.text = "";
                    toTimeInput.text = "";
                    _subjectController.clear();
                    _memberAbsentController.clear();
                    _memberPresentController.clear();
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phonelink_erase_rounded,
                      color: MyColors.text4ColorCode,
                    ),
                    Text("Clear",
                        style: TextStyle(
                            color: MyColors.text4ColorCode,
                            decoration: TextDecoration.underline,
                            fontSize: 20)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                    print(" Navigatorrrrrrrrrrrrr");
                  } else {
                    // You can also handle custom back button logic here
                    // For example, exit the app, show a confirmation dialog, etc.

                    print("Else Navigatorrrrrrrrrrrrr");

                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                BlocProvider(
                                    create: (context) {
                                      return MainBloc(webService: WebService());
                                    },
                                    child: VisitHistoryScreen())));
                    // Prevent the app from closing
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 25, color: MyColors.text4ColorCode),
                    Text(
                      "Cancel",
                      style: TextStyle(
                          color: MyColors.text4ColorCode,
                          decoration: TextDecoration.underline,
                          fontSize: 20),
                    ),
                  ],
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //     _validation();
              //   },
              //   child: Container(
              //     alignment: Alignment.center,
              //     width: 148,
              //     height: 56,
              //     margin: const EdgeInsets.only(left: 15),
              //     padding: const EdgeInsets.only(
              //         top: 6.0, bottom: 6, left: 20, right: 20),
              //     decoration: BoxDecoration(
              //         color: MyColors.blueColorCode,
              //         borderRadius: BorderRadius.all(Radius.circular(10)),
              //         border:
              //         Border.all(color: MyColors.textBoxBorderColorCode)),
              //     child: Text(
              //       "Save",
              //       style:
              //       TextStyle(color: MyColors.whiteColorCode, fontSize: 20),
              //     ),
              //   ),
              // )
              Row(
                children: [
                  if (!isUpdateMode)
                    GestureDetector(
                      onTap: () {
                        _validation(); // Save action
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 140,
                        height: 56,
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 20),
                        decoration: BoxDecoration(
                          color: MyColors.blueColorCode,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: MyColors.textBoxBorderColorCode),
                        ),
                        child: Text(
                          "Save",
                          style: TextStyle(
                              color: MyColors.whiteColorCode, fontSize: 20),
                        ),
                      ),
                    ),
                  if (isUpdateMode)
                  /*  GestureDetector(
                      onTap: () {
                        _updatevalidation();
                        Fluttertoast.showToast(msg: "Update button clicked!");
                        // TODO: Add your update logic here
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 140,
                        height: 56,
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: MyColors.textBoxBorderColorCode),
                        ),
                        child: Text(
                          "Update",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),*/
                  // Replace the update button GestureDetector with this:
                    GestureDetector(
                      onTap: _isFormEdited ? _updatevalidation : null,
                      child: Container(
                        alignment: Alignment.center,
                        width: 140,
                        height: 56,
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 20),
                        decoration: BoxDecoration(
                          color: _isFormEdited ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: MyColors.textBoxBorderColorCode),
                        ),
                        child: Text(
                          "Update",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkForFormEdits() {
    bool hasEdits = false;

    // Check all text controllers for changes
    if (_gatepassdatecontroller.text.isNotEmpty ||
        fromTimeInput.text.isNotEmpty ||
        _subjectController.text.isNotEmpty ||
        _memberPresentController.text.isNotEmpty ||
        _memberAbsentController.text.isNotEmpty) {
      hasEdits = true;
    }

    // Check dynamic rows for changes
    for (var key in rowKeys) {
      final rowData = key.currentState?.getRowData() ?? {};
      if (rowData.values
          .any((value) => value.isNotEmpty && value != "Not provided")) {
        hasEdits = true;
        break;
      }
    }

    if (hasEdits != _isFormEdited) {
      setState(() {
        _isFormEdited = hasEdits;
      });
    }
  }

  _addForm() {
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
          if (state is InsertMMRowsDataLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is InsertMMRowsDataLoadedState) {
            setState(() {
              _isLoading = false;
            });
            print("InsertMMRowsDataLoadedState ");
            Fluttertoast.showToast(
              msg: "   Record Inserted Successfully..!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            DialogForUpdate().popUp(
                context,
                " Your Minutes Of The Meeting Form Submitted Successfully!",
                "4");
          } else if (state is InsertMMRowsDataErrorState) {
            setState(() {
              _isLoading = false;
            });
          }
//-----------------------
          if (state is InsertMMAllDataLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is InsertMMAllDataLoadedState) {
//             setState(() {
//               _isLoading = false;
//             });
//             print("InsertMMAllDataLoadedState......... ");
// //insertMMALLDataRequest response :Record Inserted Successfully. SrNo - 54
            Fluttertoast.showToast(
              msg: state.cancelGatepassResponse,
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            String input = state.cancelGatepassResponse!;
            RegExp regExp = RegExp(r"SrNo - (\d+)");

            Match? match = regExp.firstMatch(input);

            if (match != null) {
              String srNo = match
                  .group(1)!; // Extract the first capturing group (the number)
              print("srNo : " + srNo); // Output: 54

              mainBloc.add(UpdateMeetingFormNoEvents(
                  FormNo: int.parse(srNo), SrNo: 3531, token: Auth_Token!));
            } else {
              print("No SrNo found.");
            }
            // setState(() {
            //   _isLoading = false;
            // });
            // print("InsertMMRowsDataLoadedState ");
            // Fluttertoast.showToast(
            //   msg: "   Record Inserted Successfully..!   ",
            //   toastLength: Toast.LENGTH_SHORT,
            //   timeInSecForIosWeb: 1,
            // );
            //
            // DialogForUpdate().popUp(
            //     context, " Your Minutes Of The Meeting Form Submitted Successfully!", "4");
          } else if (state is InsertMMAllDataErrorState) {
            setState(() {
              _isLoading = false;
            });
          }

          ///////////////

          // if (state is UpdateMeetingFormNoLoadingState) {
          //   setState(() {
          //     _isLoading = true;
          //   });
          //
          // }
          // else if (state is UpdateMeetingFormNoLoadedState) {
          //   setState(() {
          //     _isLoading = false;
          //   });
          //   print("UpdateMeetingFormNoLoadedState......... ");
          //   Fluttertoast.showToast(
          //     msg: state.cancelGatepassResponse.message!,
          //     toastLength: Toast.LENGTH_SHORT,
          //     timeInSecForIosWeb: 1,
          //   );
          //
          // }
          // else if (state is UpdateMeetingFormNoErrorState) {
          //   setState(() {
          //     _isLoading = false;
          //   });
          //
          // }

          //
          if (state is GetMinutesOfTheMeetingAllDataByVisitSrNoLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state
          is GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState) {
            setState(() {
              _isLoading = false;
            });
            print("GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState ");
            Fluttertoast.showToast(
              msg: "   Success..!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            // setState(() {
            //   if (state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse!
            //       .message!.isNotEmpty) {
            //     srno = state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!.first!.srNo
            //         .toString();
            //     _gatepassdatecontroller.text = state
            //         .getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!
            //         .first!
            //         .date!;
            //     _memberAbsentController.text = state
            //         .getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!
            //         .first!
            //         .memberAbsent!;
            //     _memberPresentController.text = state
            //         .getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!
            //         .first!
            //         .memberPresent!;
            //     _subjectController.text = state
            //         .getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!
            //         .first!
            //         .subject!;
            //     fromTimeInput.text = state
            //         .getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!
            //         .first!
            //         .time!;
            //     String allrecorddata = state
            //         .getMinutesOfTheMeetingAllDataByVisitSrNoResponse
            //         .message!
            //         .first
            //         .allrecordIds!;
            //     print("allrecorddata" + allrecorddata);
            //   }
            // });
          } else if (state
          is GetMinutesOfTheMeetingAllDataByVisitSrNoErrorState) {
            setState(() {
              _isLoading = false;
            });
          }
//GetMinutesOfTheMeetingDataByVisitSrNoEvents

          if (state is GetMinutesOfTheMeetingDataByVisitSrNoLoadingState) {
            setState(() {
              _isLoading = true;
            });
            print("GetMinutesOfTheMeetingDataByVisitSrNoLoadingState ");
          } else if (state
          is GetMinutesOfTheMeetingDataByVisitSrNoLoadedState) {
            setState(() {
              _isLoading = false;
            });
            print("GetMinutesOfTheMeetingDataByVisitSrNoLoadedState ");
            Fluttertoast.showToast(
              msg: "   Success..!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            listofRows.addAll(
                state.getMinutesOfTheMeetingDataByVisitSrNoResponse.message!);

            String? pointsOrIssues = "";
            String? discussedWith = "";
            String? decisionTaken = "";
            String? responsibility = "";
            String? statusOrRemark = "";
            String? targetDate = "";
            String? nextDate = "";
            print("listofRows size..." + listofRows.length.toString());
            if (listofRows.length > 0) {
              setState(() {
                isUpdateMode = true; // 👈 Add this line
              });
              for (int i = 0; i < listofRows.length; i++) {
                SRNOtable = listofRows[i].srNo.toString();
                pointsOrIssues = listofRows[i].pointsOrIssues!;
                discussedWith = listofRows[i].disccussedwith!;
                decisionTaken = listofRows[i].decisionTaken!;
                responsibility = listofRows[i].responsibility!;
                statusOrRemark = listofRows[i].statusOrRemark!;
                targetDate = listofRows[i].targateDate!;
                nextDate = listofRows[i].nextDate!;
                addRowFromData(
                    pointsOrIssues,
                    discussedWith,
                    decisionTaken,
                    responsibility,
                    statusOrRemark,
                    targetDate,
                    nextDate,
                    i);
              }
              print("table:" +
                  pointsOrIssues! +
                  discussedWith! +
                  decisionTaken! +
                  responsibility! +
                  statusOrRemark! +
                  targetDate! +
                  nextDate!);
            }
          } else if (state is GetMinutesOfTheMeetingDataByVisitSrNoErrorState) {
            setState(() {
              _isLoading = false;
            });
          }

//UpdateMMALLData
          if (state is UpdateMMALlDataLoadingState) {
            _isLoading = true;
          } else if (state is UpdateMMAllDataLoadedState) {
            _isLoading = false;
            Fluttertoast.showToast(msg: "Recordssss updated successfully");
          } else if (state is UpdateMMAllDataErrorState) {
            _isLoading = false;
            Fluttertoast.showToast(msg: "Recordssss updated successfullyy");
          }
//UpdateMMData
          if (state is UpdateMMDataLoadingState) {
            _isLoading = true;
          } else if (state is UpdateMMDataLoadedState) {
            _isLoading = false;
            Fluttertoast.showToast(msg: "table Records updated successfully");
          } else if (state is UpdateMMDataErrorState) {
            _isLoading = false;
            Fluttertoast.showToast(msg: "table Records updated successfullyy");
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 20.0, left: 15, right: 15, bottom: 20),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Date",
                            style: TextStyle(fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Text("*",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: MyColors.redColorCode)),
                          )
                        ],
                      ),
                    )),
                TextField(
                  controller: _gatepassdatecontroller,
                  onChanged: (value) => _checkForFormEdits(),
                  enabled: true,
                  readOnly: true,
                  onTap: () {
                    FocusScope.of(context).requestFocus(new FocusNode());
                    _selectDate(context);
                  },
                  // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.whiteColorCode,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide:
                      BorderSide(width: 1, color: MyColors.buttonColorCode),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 1, color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                          width: 1, color: MyColors.textBoxBorderColorCode),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                          width: 1,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode)),
                    hintText: "DD/MM/YYYY",
                    suffixIcon: Icon(
                      Icons.calendar_month,
                      size: 24,
                      color: MyColors.dateIconColorCode,
                    ),
                    hintStyle: TextStyle(
                        fontSize: 16, color: MyColors.datePlacehoderColorCode),
                    errorText: "",
                  ),
                  // controller: _passwordController,
                  // onChanged: _authenticationFormBloc.onPasswordChanged,
                  obscureText: false,
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "From Time ",
                            style: TextStyle(fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Text("*",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: MyColors.redColorCode)),
                          )
                        ],
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: TextField(
                    // onChanged: (value) {
                    //   fromTimeController = value;
                    // },
                    onTap: () async {
                      final DateFormat formatter = DateFormat('H:mm',
                          Localizations.localeOf(context).toLanguageTag());
                      final TimeOfDay? picked = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      builder:
                          (BuildContext context, Widget? child) {
                        return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!);
                      };
                      if (picked != null) {
                        final String fromTime = formatter.format(
                            DateTime(0, 1, 1, picked.hour, picked.minute));
                        fromTimeController = fromTime;
                        setState(() {
                          fromTimeInput.text = fromTimeController;
                          _checkForFormEdits();
                        });
                      }
                    },
                    readOnly: true,
                    enabled: true,
                    // to trigger disabledBorder
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: MyColors.whiteColorCode,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.buttonColorCode),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1, color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide:
                        BorderSide(width: 1, color: MyColors.textColorCode),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                            width: 1,
                          )),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                              width: 1,
                              color: MyColors.textBoxBorderColorCode)),
                      focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide: BorderSide(
                              width: 2, color: MyColors.buttonColorCode)),
                      hintText: "hh:mm:AM",
                      suffixIcon: Icon(
                        Icons.watch_later_outlined,
                        size: 24,
                        color: MyColors.dateIconColorCode,
                      ),
                      hintStyle: TextStyle(
                          fontSize: 18, color: MyColors.searchTextColorCode),
                      errorText: "",
                    ),
                    controller: fromTimeInput,
                    // controller: _passwordController,
                    // onChanged: _authenticationFormBloc.onPasswordChanged,
                    obscureText: false,
                  ),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Subject",
                            style: TextStyle(fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Text("*",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: MyColors.redColorCode)),
                          )
                        ],
                      ),
                    )),
                TextField(
                  controller: _subjectController,
                  onChanged: (value) => _checkForFormEdits(),
                  enabled: true,
                  // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.whiteColorCode,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide:
                      BorderSide(width: 1, color: MyColors.buttonColorCode),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 1, color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                          width: 1, color: MyColors.textBoxBorderColorCode),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                          width: 1,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode)),
                    // hintText: "HintText",
                    hintStyle: TextStyle(
                        fontSize: 16, color: MyColors.textBoxColorCode),
                    errorText: "",
                  ),
                  // controller: _passwordController,
                  // onChanged: _authenticationFormBloc.onPasswordChanged,
                  obscureText: false,
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Member Present",
                            style: TextStyle(fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Text("*",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: MyColors.redColorCode)),
                          )
                        ],
                      ),
                    )),
                TextField(
                  controller: _memberPresentController,
                  onChanged: (value) => _checkForFormEdits(),
                  enabled: true,
                  // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.whiteColorCode,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide:
                      BorderSide(width: 1, color: MyColors.buttonColorCode),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 1, color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                          width: 1, color: MyColors.textBoxBorderColorCode),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                          width: 1,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode)),
                    // hintText: "HintText",
                    hintStyle: TextStyle(
                        fontSize: 16, color: MyColors.textBoxColorCode),
                    errorText: "",
                  ),
                  // controller: _passwordController,
                  // onChanged: _authenticationFormBloc.onPasswordChanged,
                  obscureText: false,
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Member Absent",
                            style: TextStyle(fontSize: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Text("*",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: MyColors.redColorCode)),
                          )
                        ],
                      ),
                    )),
                TextField(
                  controller: _memberAbsentController,
                  onChanged: (value) => _checkForFormEdits(),
                  enabled: true,
                  // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.whiteColorCode,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide:
                      BorderSide(width: 1, color: MyColors.buttonColorCode),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(width: 1, color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                          width: 1, color: MyColors.textBoxBorderColorCode),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                          width: 1,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode)),
                    // hintText: "HintText",
                    hintStyle: TextStyle(
                        fontSize: 16, color: MyColors.textBoxColorCode),
                    errorText: "",
                  ),
                  // controller: _passwordController,
                  // onChanged: _authenticationFormBloc.onPasswordChanged,
                  obscureText: false,
                ),
                ////////////////////////////
                /*  SingleChildScrollView(
                  scrollDirection: Axis.vertical, // Horizontal scroll
                  child: Row(
                    children: [*/
                // Spread dynamic rows list here

                //],
                //   ),
                //    ),
                Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width, // You can adjust the width of each row
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: addRow,
                        child: Text("Add Row",
                            style: TextStyle(
                                color: MyColors.blueColorCode,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          // Horizontal scrolling for the Row
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 180, // Adjust the width as needed
                                    child: _buildDynamicTextField(
                                        "Field 1", textFieldController1),
                                  ),
                                  SizedBox(
                                    width: 200, // Adjust the width as needed
                                    child: _buildDynamicTextField(
                                        "Field 2", textFieldController2),
                                  ),
                                  SizedBox(
                                    width: 300, // Adjust the width as needed
                                    child: _buildDynamicTextField(
                                        "Field 3", textFieldController3),
                                  ),
                                  SizedBox(
                                    width: 200, // Adjust the width as needed
                                    child: _buildDynamicTextField(
                                        "Field 4", textFieldController4),
                                  ),
                                  SizedBox(
                                    width: 200, // Adjust the width as needed
                                    child: _buildDynamicTextField(
                                        "Field 5", textFieldController5),
                                  ),
                                  SizedBox(
                                    width: 150, // Adjust the width as needed
                                    child: _buildDynamicTextField(
                                        "POINT/ISSUE", dateController1),
                                  ),
                                  SizedBox(
                                    width: 200, // Adjust the width as needed

                                    child: _buildDynamicTextField(
                                        "Field 5", dateController2),
                                  ),
                                ],
                              ),
                              ...dynamicRows,
                            ],
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTextField(String label,
      TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: false,
      // to trigger disabledBorder
      decoration: InputDecoration(
        filled: true,
        fillColor: MyColors.textFieldBackgroundColorCode,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: MyColors.buttonColorCode),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.orange),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide:
          BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(
              width: 1,
            )),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide:
            BorderSide(width: 1, color: MyColors.textBoxBorderColorCode)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 2, color: MyColors.buttonColorCode)),
        // hintText: "HintText",
        hintStyle: TextStyle(fontSize: 16, color: MyColors.blackColorCode),
        errorText: "",
      ),
      style: TextStyle(
        color: Colors.black, // Set the text color to black
        fontWeight: FontWeight.bold, // Make the text bold
      ),
      // controller: _passwordController,
      // onChanged: _authenticationFormBloc.onPasswordChanged,
      obscureText: false,
    );
  }

  _validation() {
    if (_gatepassdatecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select  Date...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (fromTimeInput.text == "") {
      Fluttertoast.showToast(
        msg: "  Please Select  FromTime...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_subjectController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Subject...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_memberPresentController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Member Present...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_memberAbsentController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select Absent members...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      print(" _else..............");
      getAllRowsData();
    }
  }

  _updatevalidation() {
    if (_gatepassdatecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select  Date...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (fromTimeInput.text == "") {
      Fluttertoast.showToast(
        msg: "  Please Select  FromTime...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_subjectController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Subject...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_memberPresentController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Member Present...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_memberAbsentController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select Absent members...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      print(" _else..............");
      getAllRowsDataupdate();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 15)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _gatepassdatecontroller.text = selectedDate.day.toString() +
            "/" +
            selectedDate.month.toString() +
            "/" +
            selectedDate.year.toString();
        date = selectedDate.year.toString() +
            "-" +
            selectedDate.month.toString() +
            "-" +
            selectedDate.day.toString();
        _checkForFormEdits();
      });
    }
  }

  void _updateMinutesOfTheMeetingForm(List<Map<String, String>> allRowsData) {
    // mainBloc.add(UpdateMMALLDataEvents(
    //     updateMMAllData: UpdateMMAllData(
    //         srNo: srno,
    //
    //
    //     ), token: Auth_Token!));
    mainBloc.add(UpdateMMALLDataEvents(
        updateMMAllData: UpdateMMAllData(
            srNo: srno,
            date: _gatepassdatecontroller.text,
            time: fromTimeInput.text,
            subject: _subjectController.text,
            memberPresent: _memberPresentController.text,
            memberAbsent: _memberAbsentController.text,
            allRecordsIds: "",
            visitSrNo: widget.visitSrNo,
            custCode: ''),
        token: Auth_Token!));

    for (int i = 0; i < allRowsData.length; i++) {
      Map<String, String> rowData = allRowsData.elementAt(i);
      print("rowData :" + rowData.length.toString());
      String pointsOrIssues = rowData['pointsOrIssues'] ?? 'Not provided';
      mainBloc.add(UpdateMMDataEvents(
          updateMMData: UpdateMMData(
              srNo: SRNOtable,
              pointsOrIssues: rowData['pointsOrIssues'] ?? 'Not provided',
              discussedWith: rowData['discussedWith'] ?? 'Not provided',
              decisionTaken: rowData['decisionTaken'] ?? 'Not provided',
              responsibility: rowData['responsibility'] ?? 'Not provided',
              targetDate: rowData['targetDate'] ?? 'Not provided',
              statusOrRemark: rowData['statusOrRemark'] ?? 'Not provided',
              nextDate: rowData['nextDate'] ?? 'Not provided',
              visitSrNo: widget.visitSrNo),
          token: Auth_Token!));
      // mainBloc.add(InsertMMRowsDataEvents(
      //     insertMMRowDataRequest: InsertMMRowDataRequest(
      //       pointsOrIssues: rowData['pointsOrIssues'] ?? 'Not provided',
      //       discussedWith: rowData['discussedWith'] ?? 'Not provided',
      //       decisionTaken: rowData['decisionTaken'] ?? 'Not provided',
      //       responsibility: rowData['responsibility'] ?? 'Not provided',
      //       targetDate: rowData['targetDate'] ?? 'Not provided',
      //       statusOrRemark: rowData['statusOrRemark'] ?? 'Not provided',
      //       nextDate: rowData['nextDate'] ?? 'Not provided',
      //       visitSrNo: "3531",
      //     ),
      //     token: Auth_Token!)) ;
      // break;
    }
  }

  void _addMinutesOfTheMeetingForm(List<Map<String, String>> allRowsData) {
    mainBloc.add(InsertMMAllDataEvents(
        insertMMALLDataRequest: InsertMMALLDataRequest(
          date: _gatepassdatecontroller.text,
          time: fromTimeInput.text,
          subject: _subjectController.text,
          memberPresent: _memberPresentController.text,
          memberAbsent: _memberAbsentController.text,
          allRecordsIds: " ",
          visitSrNo: widget.visitSrNo,
        ),
        token: Auth_Token!));

    for (int i = 0; i < allRowsData.length; i++) {
      Map<String, String> rowData = allRowsData.elementAt(i);
      print("rowData :" + rowData.length.toString());
      String pointsOrIssues = rowData['pointsOrIssues'] ?? 'Not provided';
      mainBloc.add(InsertMMRowsDataEvents(
          insertMMRowDataRequest: InsertMMRowDataRequest(
            pointsOrIssues: rowData['pointsOrIssues'] ?? 'Not provided',
            discussedWith: rowData['discussedWith'] ?? 'Not provided',
            decisionTaken: rowData['decisionTaken'] ?? 'Not provided',
            responsibility: rowData['responsibility'] ?? 'Not provided',
            targetDate: rowData['targetDate'] ?? 'Not provided',
            statusOrRemark: rowData['statusOrRemark'] ?? 'Not provided',
            nextDate: rowData['nextDate'] ?? 'Not provided',
            visitSrNo: widget.visitSrNo,
          ),
          token: Auth_Token!));
      // break;
    }
  }
}

class DynamicRow extends StatefulWidget {
//  final VoidCallback onDelete;
  final Function(int) onDelete;
  final int index;

  int deleteIndex = 0;

  DynamicRow({Key? key, required this.index, required this.onDelete})
      : super(key: key);

  @override
  _DynamicRowState createState() => _DynamicRowState();
}

class _DynamicRowState extends State<DynamicRow> {
  late int rowNumber;
  TextEditingController dateController1 = TextEditingController();
  TextEditingController dateController2 = TextEditingController();
  TextEditingController textFieldController1 = TextEditingController();
  TextEditingController textFieldController2 = TextEditingController();
  TextEditingController textFieldController3 = TextEditingController();
  TextEditingController textFieldController4 = TextEditingController();
  TextEditingController textFieldController5 = TextEditingController();
  bool isNextDateEnabled = false;

  Map<String, String> getRowData() {
    return {
      'pointsOrIssues': textFieldController1.text,
      'discussedWith': textFieldController2.text,
      'decisionTaken': textFieldController3.text,
      'responsibility': textFieldController4.text,
      'statusOrRemark': textFieldController5.text,
      'targetDate': dateController1.text,
      'nextDate': dateController2.text,
    };
  }

  @override
  void initState() {
    super.initState();
    rowNumber = widget.index;
  }

  void enableNextDate() {
    setState(() {
      isNextDateEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Horizontal scrolling for the Row
            child: Row(
              children: [
                // No need for SizedBox or Expanded here, just use TextField directly

                // Removing Expanded from here
                SizedBox(
                  width: 180,
                  child:
                  _buildDynamicTextField("Field 1", textFieldController1),
                ),
                SizedBox(
                  width: 200,
                  child:
                  _buildDynamicTextField("Field 2", textFieldController2),
                ),
                SizedBox(
                  width: 300,
                  child:
                  _buildDynamicTextField("Field 3", textFieldController3),
                ),
                SizedBox(
                  width: 200,
                  child:
                  _buildDynamicTextField("Field 4", textFieldController4),
                ),
                SizedBox(
                  width: 200,
                  child:
                  _buildDynamicTextField("Field 5", textFieldController5),
                ),
                SizedBox(
                  width: 150, // Adjust the width as needed
                  child: TextField(
                    controller: dateController1,
                    enabled: true,
                    readOnly: true,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      _selectDate(context, dateController1);
                    },
                    // to trigger disabledBorder
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: MyColors.whiteColorCode,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.buttonColorCode),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1, color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode),
                      ),
                      hintText: "DD/MM/YYYY",
                      suffixIcon: Icon(
                        Icons.calendar_month,
                        size: 24,
                        color: MyColors.dateIconColorCode,
                      ),
                      hintStyle: TextStyle(
                          fontSize: 16,
                          color: MyColors.datePlacehoderColorCode),
                      errorText: "",
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 30.0,
                          horizontal:
                          10.0), // Increase vertical padding to increase height
                    ),
                    obscureText: false,
                  ),
                ),
                SizedBox(
                  width: 200, // Adjust the width as needed
                  child: TextField(
                    controller: dateController2,
                    enabled: true,
                    readOnly: true,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      _selectDate(context, dateController2);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: MyColors.whiteColorCode,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.buttonColorCode),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1, color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode),
                      ),
                      hintText: "DD/MM/YYYY",
                      suffixIcon: Icon(
                        Icons.calendar_month,
                        size: 24,
                        color: MyColors.dateIconColorCode,
                      ),
                      hintStyle: TextStyle(
                          fontSize: 16,
                          color: MyColors.datePlacehoderColorCode),
                      errorText: "",
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 30.0, horizontal: 10.0),
                    ),
                    obscureText: false,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 20.0, left: 15, right: 15, bottom: 40),
                    child: GestureDetector(
                      child: Icon(
                        Icons.delete_rounded,
                        size: 24,
                        color: MyColors.redColorCode,
                      ),
                      onTap: () {
                        print("Clicked index" + widget.index.toString());
                        setState(() {
                          widget.onDelete(widget.index);
                          // widget.onDelete();
                        });
                      }, // Trigger the onDelete callback,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateIndex(int newIndex) {
    setState(() {
      rowNumber = newIndex;
    });
  }

  // final DateTime? picked = await showDatePicker(
  // context: context,
  // initialDate: DateTime.now(),
  // firstDate: DateTime.now().subtract(const Duration(days: 15)),
  // lastDate: DateTime.now().add(const Duration(days: 15)),
  // );
  // Method to open a date picker
  void _selectDate(BuildContext context,
      TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 15)),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Widget _buildDynamicTextField(String label,
      TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context
              .findAncestorStateOfType<_MinutesOfTheMeetingFormScreenState>()
              ?._checkForFormEdits();
        });
      },
      enabled: true,
      // to trigger disabledBorder
      decoration: InputDecoration(
        filled: true,
        fillColor: MyColors.whiteColorCode,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: MyColors.buttonColorCode),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.orange),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide:
          BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide:
          BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 2, color: MyColors.buttonColorCode),
        ),
        hintStyle: TextStyle(fontSize: 16, color: MyColors.textBoxColorCode),
        errorText: "",
        contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
      ),
      obscureText: false,
    );
  }
}

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/CoffCredit/CreditCOffEntryRequest.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/CoffCredit/FetchCoffTransactionsResponse.dart';
import '../../util/MyColor.dart';
import 'CoffCreditScreen.dart';

class AddCoffScreen extends StatefulWidget {
  //const AddGatePass({super.key});
  int flag;
  Message datum;

  AddCoffScreen({
    Key? key,
    required this.flag,
    required this.datum,
  }) : super(key: key);

  @override
  State<AddCoffScreen> createState() => _AddCoffScreenState();
}

class _AddCoffScreenState extends State<AddCoffScreen> {
  TextEditingController _TransactionidController = new TextEditingController();
  TextEditingController _gatepassdatecontroller = new TextEditingController();
  TextEditingController _staffCodecontroller = new TextEditingController();
  TextEditingController _staffNamecontroller = new TextEditingController();
  TextEditingController _departmentNamecontroller = new TextEditingController();
  TextEditingController _designationController = new TextEditingController();
  TextEditingController _purposecontroller = new TextEditingController();
  TextEditingController _shiftController = new TextEditingController();
  TextEditingController _totalhrsController = new TextEditingController();
  TextEditingController _balancehrsController = new TextEditingController();

  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  DateTime selectedDate = DateTime.now();
  late String date = '';
  List<String> typeList = [];
  List<String> reasonsList = [];
  String gatePasstype = "Select";
  String gatePassReason = "Select";
  bool isGatepasscontainerselected = false;
  bool isReasoncontainerselected = false;
  bool ClickStatus = false;
  var fromTimeController;
  TextEditingController fromTimeInput = TextEditingController();
  var toTimeController;
  TextEditingController toTimeInput = TextEditingController();

  String? Auth_Token = "";

  String? staffCode = "";

  String designation = "";

  String departmentName = "";

  bool isTypecontainerselected = false;

  String type = "H/WOFF";

  String reason = "Select";

  @override
  @override
  void initState() {
    mainBloc = BlocProvider.of(context);
    typeList.add("H/WOFF");
    typeList.add("COFF");

    reasonsList.add("Birthday");
    reasonsList.add("Bus Miss");
    reasonsList.add("Late Come");
    reasonsList.add("Personal Reason");
    reasonsList.add("Work Load");
    reasonsList.add("Work On Holiday");
    reasonsList.add("Work On Weekly Off");

    if (widget.flag == 2) {
      print("widget.flag == 2");

      // ✅ FIX: Map "HW" to "H/WOFF" and set type
      String savedType = widget.datum.type.toString();
      if (savedType == "HW ") {
        type = "H/WOFF"; // Set to H/WOFF if saved value is HW
      } else {
        type = savedType;
      }

      _totalhrsController.text = widget.datum.ttlHrs.toString();

      DateTime parsedDate = parseDate(widget.datum.otDate.toString());
      selectedDate = parsedDate;

      _gatepassdatecontroller.text =
          DateFormat('dd/MM/yyyy').format(parsedDate);
      date = DateFormat('yyyy-MM-dd').format(parsedDate);

      getData();
    } else {
      print("widget.flag == 1");
      getData();
    }
  }

  DateTime parseDate(String input) {
    try {
      // Case 1: yyyy-MM-dd (API format)
      return DateTime.parse(input);
    } catch (e) {
      try {
        // Case 2: dd/MM/yyyy (UI format)
        return DateFormat('dd/MM/yyyy').parse(input);
      } catch (e) {
        return DateTime.now(); // fallback
      }
    }
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->" + Auth_Token!);

    _staffCodecontroller.text = staffCode!;

    // ✅ FIX: Don't overwrite date when flag == 2
    if (widget.flag != 2) {
      DateTime now = DateTime.now();
      _gatepassdatecontroller.text = DateFormat('dd/MM/yyyy').format(now);
      date = DateFormat('yyyy-MM-dd').format(now);
      selectedDate = now;
    } else {
      // ✅ For edit mode, keep the existing date from initState
      // Just use the date already set in _gatepassdatecontroller
      // Don't set it to current date
      date = DateFormat('yyyy-MM-dd').format(selectedDate);
    }

    // Use the appropriate formatted date for API call
    String formattedDate = widget.flag == 2
        ? _gatepassdatecontroller.text // Use existing date for edit
        : DateFormat('dd/MM/yyyy')
        .format(DateTime.now()); // Current date for new

    mainBloc.add(GetStaffDetailsForCoffEvents(
        type: type,
        staffCode: staffCode!,
        date: formattedDate,
        token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          child: Coffcreditscreen())))),
          title: const Text("C-Off Credit (+)"),
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
                        child: GatePass())));
            return false; // Prevent the app from closing
          }
          return true;
        },
        child: _addGatePass(),
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
                    _designationController.clear();
                    _purposecontroller.clear();
                    gatePasstype = "Select";
                    gatePassReason = "Select";
                    ClickStatus = false;
                    fromTimeInput.text = "";
                    toTimeInput.text = "";
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
                            builder: (_) => BlocProvider(
                                create: (context) {
                                  return MainBloc(webService: WebService());
                                },
                                child: HomeScreen())));
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
              GestureDetector(
                onTap: () {
                  _validation();
                },
                child: Container(
                  alignment: Alignment.center,
                  width: 148,
                  height: 56,
                  margin: const EdgeInsets.only(left: 15),
                  padding: const EdgeInsets.only(
                      top: 6.0, bottom: 6, left: 20, right: 20),
                  decoration: BoxDecoration(
                      color: MyColors.blueColorCode,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      border:
                      Border.all(color: MyColors.textBoxBorderColorCode)),
                  child: Text(
                    "Save",
                    style:
                    TextStyle(color: MyColors.whiteColorCode, fontSize: 20),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _addGatePass() {
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
          if (state is GetStaffDetailsForCoffLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is GetStaffDetailsForCoffLoadedState) {
            setState(() {
              _isLoading = false;
            });
            /*  Fluttertoast.showToast(
              msg: "   sucessss...!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );*/
            _staffNamecontroller.text =
            state.getStaffDetailsForCoffResponse.message!.name!;
            _departmentNamecontroller.text =
            state.getStaffDetailsForCoffResponse.message!.department!;
            _designationController.text =
            state.getStaffDetailsForCoffResponse.message!.designation!;
            _shiftController.text = "GS";
            _balancehrsController.text =
            state.getStaffDetailsForCoffResponse.message!.balanceHours!;

            /* if(widget.flag==1) {

              _TransactionidController.text =
                  state.staffDetailsResponse.message!.transactionID.toString();
              _staffCodecontroller.text =
                  state.staffDetailsResponse.message!.staffCode.toString();
              _staffNamecontroller.text =
                  state.staffDetailsResponse.message!.staffName.toString();
              _departmentNamecontroller.text =
                  state.staffDetailsResponse.message!.departmentName.toString();
              designation =
                  state.staffDetailsResponse.message!.designation.toString();
            }else if(widget.flag==2){
              _departmentNamecontroller.text=state.staffDetailsResponse.message!.departmentName.toString();
*/
            /* }
            setState(() {
              departmentName=state.staffDetailsResponse.message!.departmentName.toString();

            });*/
          } else if (state is GetStaffDetailsForCoffErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "   Failed To Connect Server...!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
//-----------------------------------------------------------------------------
          if (state is SubmitCoffEventsLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is SubmitCoffEventsLoadedState) {
            setState(() {
              _isLoading = false;
            });

            // Check if it's an update or insert based on flag
            if (widget.flag == 1) {
              // INSERT new record
              if (state.cancelGatepassResponse.message ==
                  "Your Attendance data is not available on selected date") {
                Fluttertoast.showToast(
                    msg: "No attendance available for selected date");
              } else if (state.cancelGatepassResponse.message ==
                  "Shift not found for staff ! OT/WOFF is not allowed") {
                Fluttertoast.showToast(msg: "No shift details found!!");
              } else if (state.cancelGatepassResponse.message ==
                  "Record Inserted Successfully") {
                // ✅ Show success toast
                Fluttertoast.showToast(msg: "COFF Saved Successfully!");

                // ✅ GO BACK TO PREVIOUS SCREEN
                Navigator.pop(context, true);
              } else if (state.cancelGatepassResponse.message == null) {
                Fluttertoast.showToast(msg: "Enter correct data");
              } else {
                // ✅ Handle any other messages
                Fluttertoast.showToast(
                    msg: state.cancelGatepassResponse.message ??
                        "Something went wrong");
              }
            } else if (widget.flag == 2) {
              // UPDATE existing record
              if (state.cancelGatepassResponse.message ==
                  "Record Updated Successfully") {
                // ✅ Show success toast for update
                Fluttertoast.showToast(msg: "COFF Updated Successfully!");

                // ✅ GO BACK TO PREVIOUS SCREEN
                Navigator.pop(context, true);
              } else if (state.cancelGatepassResponse.message ==
                  "COff Updated Successfully!") {
                // Handle both possible success messages
                Fluttertoast.showToast(msg: "COFF Updated Successfully!");
                Navigator.pop(context, true);
              } else {
                // ✅ Show error message if update fails
                Fluttertoast.showToast(
                    msg: state.cancelGatepassResponse.message ??
                        "Update failed");
              }
            }
          } else if (state is SubmitCoffEventsErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "   Failed To Connect Server...!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 20.0, left: 15, right: 15, bottom: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        "Type",
                        style: TextStyle(fontSize: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: Text("*",
                            style: TextStyle(
                                fontSize: 18, color: MyColors.redColorCode)),
                      )
                    ],
                  ),
                ),
                // GestureDetector(
                //   onTap: () {
                //     setState(() {});
                //   },
                //   child: Padding(
                //       padding: const EdgeInsets.only(bottom: 2),
                //       child: Container(
                //         margin:
                //             EdgeInsets.only(top: 10.0, right: 3.0, left: 3.0),
                //         height: 50.0,
                //         width: double.maxFinite,
                //         decoration: BoxDecoration(
                //           border: Border.all(width: 1.0, color: Colors.grey),
                //         ),
                //         child: ListTile(
                //           leading: Text(type ?? gatePasstype.toString(),
                //               style: TextStyle(
                //                 fontSize: 15.0,
                //               )),
                //           trailing: isGatepasscontainerselected
                //               ? IconButton(
                //                   icon: Icon(
                //                     Icons.keyboard_arrow_up,
                //                   ),
                //                   onPressed: () {
                //                     isTypecontainerselected = false;
                //                     setState(() {});
                //                   },
                //                 )
                //               : IconButton(
                //                   icon: Icon(Icons.keyboard_arrow_down),
                //                   onPressed: () {
                //                     isTypecontainerselected = true;
                //                     setState(() {});
                //                   },
                //                 ),
                //         ),
                //       )),
                // ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isTypecontainerselected =
                      !isTypecontainerselected; // Toggle the state
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      margin: EdgeInsets.only(top: 10.0, right: 3.0, left: 3.0),
                      height: 50.0,
                      width: double.maxFinite,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.grey),
                      ),
                      child: ListTile(
                        leading: Text(type ?? gatePasstype.toString(),
                            style: TextStyle(fontSize: 15.0)),
                        trailing:
                        isTypecontainerselected // ✅ Changed from isGatepasscontainerselected
                            ? IconButton(
                          icon: Icon(Icons.keyboard_arrow_up),
                          onPressed: () {
                            setState(() {
                              isTypecontainerselected = false;
                            });
                          },
                        )
                            : IconButton(
                          icon: Icon(Icons.keyboard_arrow_down),
                          onPressed: () {
                            setState(() {
                              isTypecontainerselected = true;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                isTypecontainerselected
                    ? Card(
                  elevation: 3.0,
                  child: Container(
                    height: 90.0,
                    width: double.maxFinite,
                    margin: EdgeInsets.only(left: 20.0, right: 20.0),
                    child: ListView.builder(
                      itemCount: typeList!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isTypecontainerselected = false;

                                  type = typeList[index].toString();
                                });
                                DateTime now = DateTime.now();

                                // Format the date in dd/MM/yyyy format
                                String formattedDate =
                                DateFormat('dd/MM/yyyy').format(now);
                                if (type == "COFF") {
                                  mainBloc.add(
                                      GetStaffDetailsForCoffEvents(
                                          type: "COFF",
                                          staffCode: staffCode!,
                                          date: formattedDate,
                                          token: Auth_Token!));
                                  //event
                                }
                                String selectedGatepassType =
                                typeList![index].toString();
                                print("type : " + type);
                              },
                              child: SizedBox(
                                height: 20.0,
                                width: 10.0,
                                child: Text(typeList![index].toString()),
                              ),
                            ));
                      },
                    ),
                  ),
                )
                    : SizedBox(),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Staff Code ",
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
                  controller: _staffCodecontroller,
                  enabled: false, // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.textFieldBackgroundColorCode,
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
                            "Staff Name ",
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
                  controller: _staffNamecontroller,
                  enabled: false, // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.textFieldBackgroundColorCode,
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
                            "Department ",
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
                  controller: _departmentNamecontroller,
                  enabled: false, // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.textFieldBackgroundColorCode,
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
                            "Designation ",
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
                  controller: _designationController,
                  enabled: false, // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.textFieldBackgroundColorCode,
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
                            "Shift ",
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
                  controller: _shiftController,
                  enabled: false, // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.textFieldBackgroundColorCode,
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
                  readOnly: true,
                  enabled: true,
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
                            "Balance Hrs ",
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
                  controller: _balancehrsController,
                  enabled: false, // to trigger disabledBorder
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
                            "Total Hrs(HH.MM) ",
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
                  controller: _totalhrsController,
                  enabled: true, // to trigger disabledBorder
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: MyColors.textFieldBackgroundColorCode,
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
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        "Reason",
                        style: TextStyle(fontSize: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: Text("*",
                            style: TextStyle(
                                fontSize: 18, color: MyColors.redColorCode)),
                      )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {});
                  },
                  child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        margin:
                        EdgeInsets.only(top: 10.0, right: 3.0, left: 3.0),
                        height: 50.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(width: 1.0, color: Colors.grey),
                        ),
                        child: ListTile(
                          leading: Text(reason,
                              style: TextStyle(
                                fontSize: 15.0,
                              )),
                          trailing: isReasoncontainerselected
                              ? IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_up,
                            ),
                            onPressed: () {
                              isReasoncontainerselected = false;
                              setState(() {});
                            },
                          )
                              : IconButton(
                            icon: Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              isReasoncontainerselected = true;
                              setState(() {});
                            },
                          ),
                        ),
                      )),
                ),
                isReasoncontainerselected
                    ? Card(
                  elevation: 3.0,
                  child: Container(
                    height: 150.0,
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 20.0, right: 20.0),
                    child: ListView.builder(
                      itemCount: reasonsList!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isReasoncontainerselected = false;

                                  reason = reasonsList[index].toString();
                                });

                                String selectedGatepassType =
                                reasonsList![index].toString();
                                print("reason : " + reason);
                              },
                              child: SizedBox(
                                height: 40.0,
                                width: 50.0,
                                child:
                                Text(reasonsList![index].toString()),
                              ),
                            ));
                      },
                    ),
                  ),
                )
                    : SizedBox(),
                Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 25),
                        child: CheckboxListTile(
                          title:
                          Text("Please Check Mark To Enter Other Details",
                              style: TextStyle(
                                fontSize: 17.0,
                              )),
                          //    <-- label
                          value: ClickStatus,
                          activeColor: Colors.red,
                          checkColor: Colors.white,
                          onChanged: (newValue) {
                            setState(() {
                              ClickStatus = newValue!;
                              //   ClickStatus?_purposecontroller.clear():" Enter Purpose ";
                              if (ClickStatus) {
                                String value = _purposecontroller.text;
                                print("purpose value---" + value.toString());
                              } else {
                                _purposecontroller.clear();
                              }
                              print("checkvalue---" + newValue.toString());
                            });
                          },
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.all(0),
                        ))),
                ClickStatus
                    ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Other Details",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ))
                    : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )),
                ClickStatus
                    ? TextField(
                  controller: _purposecontroller,
                  enabled: true, // to trigger disabledBorder

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
                      borderSide:
                      BorderSide(width: 1, color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(
                          width: 1,
                          color: MyColors.textBoxBorderColorCode),
                    ),
                    border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                          width: 1,
                        )),
                    errorBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1,
                            color: MyColors.textBoxBorderColorCode)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.all(Radius.circular(4)),
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
                )
                    : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  _validation() {
    if (_totalhrsController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Total Hours...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (reason == "Select") {
      Fluttertoast.showToast(
        msg: "  Please Select Reason...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (ClickStatus == true) {
      if (_purposecontroller.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "  Please Enter Purpose...!  ",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
      } else {
        print(" ifffffff_else..............");

        _CoffCredit();
      }
    } else {
      print(" _else..............");

      _CoffCredit();
    }
  }

  _CoffCredit() {
    print(" _CoffCredit() called ClickStatus.............." +
        ClickStatus.toString());

    mainBloc.add(SubmitCoffEvents(
        creditCOffEntryRequest: CreditCOffEntryRequest(
          otid: widget.flag == 1 ? "" : widget.datum.otwofFid,
          type: type,
          staffCode: _staffCodecontroller.text,
          name: _staffNamecontroller.text,
          department: _departmentNamecontroller.text,
          date: _gatepassdatecontroller.text,
          designation: _designationController.text,
          shift: _shiftController.text,
          totalHrs: _totalhrsController.text,
          balanceHrs: _balancehrsController.text,
          reason: reason,
          otherDetails: _purposecontroller.text,
          otherChecked: ClickStatus,
        ),
        token: Auth_Token!));

    clearfields();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: selectedDate.subtract(Duration(days: 40)),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;

        // ✅ Correct format with leading zeros
        _gatepassdatecontroller.text =
            DateFormat('dd/MM/yyyy').format(selectedDate);

        // API format (if needed)
        date = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  void calculateTotalMin() {
    // Define start and end time as strings
    String startTimeStr = fromTimeInput.text; // Start time as string
    String endTimeStr = toTimeInput.text; // End time as string
    // Parse the time strings into DateTime objects (using today's date)
    DateTime time1 = _parseTime(startTimeStr);
    DateTime time2 = _parseTime(endTimeStr);

    // Calculate the difference between the two times
    Duration difference = time2.difference(time1);

    // Get the difference in minutes
    int minutes = difference.inMinutes;

    print('The difference in minutes is: $minutes');

    // _totalmincontroller.text=minutes.toString();
  }

// Helper function to parse time string into DateTime
  DateTime _parseTime(String timeStr) {
    // Split the time string into hours and minutes
    List<String> parts = timeStr.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    // Return a DateTime object with today's date and the given time
    return DateTime(
        2024, 1, 1, hours, minutes); // Using arbitrary date (e.g., 2024-01-01)
  }

  void clearfields() {
    setState(() {
      _totalhrsController.clear();
      reason = "Select";
    });
  }
}

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/CoffDebit/SubmitCoffDebitRequest.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/DialogForUpdate.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../../model/CoffDebit/GetCoffsTransactionsResponse.dart';

class Debitcoffscreen extends StatefulWidget {
  //const AddGatePass({super.key});
  int flag;
  Message datum;

  Debitcoffscreen({
    Key? key,
    required this.flag,
    required this.datum,
  }) : super(key: key);

  @override
  State<Debitcoffscreen> createState() => _DebitcoffscreenState();
}

class _DebitcoffscreenState extends State<Debitcoffscreen> {
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

  String reason = "Select";

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

    //getData();

    if (widget.flag == 2) {
      print("widget.flag == 2");

      //type=widget.datum.type.toString();
      //type="COFF";

      // _totalhrsController.text=widget.datum.ttlHrs.toString();
      //  _gatepassdatecontroller.text=widget.datum.otDate.toString();
      //   gatePasstype=widget.datum.type.toString();
      // _purposecontroller.text=widget.datum.customerName.toString();

      fromTimeInput.text = widget.datum.fromTime.toString();
      toTimeInput.text = widget.datum.toTime.toString();
      getData();
    } else {
      print("widget.flag == 1");
      getData();
    }
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->" + Auth_Token!);

    // _staffCodecontroller.text="cd02851";
    _staffCodecontroller.text = staffCode!;

    DateTime now = DateTime.now();

    // Format the date in dd/MM/yyyy format
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);

    if (widget.flag == 2) {
      _gatepassdatecontroller.text = widget.datum.cOffDate.toString();
    } else {
      _gatepassdatecontroller.text = formattedDate;
    }

    mainBloc.add(GetStaffDetailsForCoffEvents(
        type: "H/WOFF",
        staffCode: staffCode!,
        date: formattedDate,
        token: Auth_Token!));
    // mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.of(context).pop(), // Simple pop to go back
          ),
          title: const Text("C-Off Debit (-)"),
          backgroundColor: MyColors.darkBlue,
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
                        child: HomeScreen())));
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
                    _purposecontroller.clear();
                    gatePasstype = "Select";
                    reason = "Select";
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
                                child: GatePass())));
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
          if (state is SubmitCoffDebitLoadingState) {
            print("SubmitCoffEventsLoadingState");

            setState(() {
              _isLoading = true;
            });
          } else if (state is SubmitCoffDebitLoadedState) {
            print("SubmitCoffEventsLoadedState" +
                state.cancelGatepassResponse.message!);
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: state.cancelGatepassResponse.message!,
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
            if (widget.flag == 1) {
              if (state.cancelGatepassResponse.message ==
                  "C-Off details saved successfully !") {
                DialogForUpdate()
                    .popUp(context, "C-OFF Debit Saved Successfully!", "1");
              }
            } else if (widget.flag == 2) {
              if (state.cancelGatepassResponse.message ==
                  "C-Off details updated successfully !") {
                DialogForUpdate()
                    .popUp(context, "C-OFF Debit Updated Successfully!", "1");
              }
            } else {}
          } else if (state is SubmitCoffDebitErrorState) {
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
                            " D-Off Date",
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
                            "From Time (HH:MM) ",
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
                      final DateFormat formatter = DateFormat('HH:mm',
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
                            "To Time (HH:MM) ",
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
                      final DateFormat formatter = DateFormat('HH:mm',
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
                        toTimeController = fromTime;
                        setState(() {
                          toTimeInput.text = toTimeController;
                        });

                        //    calculateTotalMin( );
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
                    controller: toTimeInput,
                    // controller: _passwordController,
                    // onChanged: _authenticationFormBloc.onPasswordChanged,
                    obscureText: false,
                  ),
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
                          title: Text("Please Check Mark To Enter Purpose",
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

                                //    _purposecontroller.clear();
                                //     _purposecontroller.text=" Enter Purpose ";
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
                                "Purpose",
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
    if (_gatepassdatecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select Date...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (fromTimeInput.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select From Time...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (toTimeInput.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select To Time...!  ",
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
        // _CoffDebit();
        calculateTotalMin();
      }
    } else {
      print(" _else..............");

      calculateTotalMin();
    }
  }

  _CoffDebit() {
    print(" _CoffDebit() called ClickStatus.............." +
        ClickStatus.toString());

    if (widget.flag == 1) {
      mainBloc.add(SubmitCoffDebitEvents(
          submitCoffDebitRequest: SubmitCoffDebitRequest(
              coffID: "",
              staffCode: _staffCodecontroller.text,
              staffName: _staffNamecontroller.text,
              coffDate: _gatepassdatecontroller.text,
              department: _departmentNamecontroller.text,
              designation: _designationController.text,
              shift: "GS",
              balance: _balancehrsController.text,
              fromTime: fromTimeInput.text,
              toTime: toTimeInput.text,
              reason: reason,
              check: ClickStatus.toString(),
              purpose: _purposecontroller.text,
              add: true),
          token: Auth_Token!));
      _clearFields();
    } else if (widget.flag == 2) {
      mainBloc.add(SubmitCoffDebitEvents(
          submitCoffDebitRequest: SubmitCoffDebitRequest(
              coffID: widget.datum.cOffId.toString(),
              staffCode: _staffCodecontroller.text,
              staffName: _staffNamecontroller.text,
              coffDate: _gatepassdatecontroller.text,
              department: _departmentNamecontroller.text,
              designation: _designationController.text,
              shift: "GS",
              balance: _balancehrsController.text,
              fromTime: fromTimeInput.text,
              toTime: toTimeInput.text,
              reason: reason,
              check: ClickStatus.toString(),
              purpose: _purposecontroller.text,
              add: false),
          token: Auth_Token!));
      _clearFields();
    }
  }

  // Future<void> _selectDate(BuildContext context) async {
  //   DateTime now = DateTime.now();
  //
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //
  //     initialDate: now, // always safe
  //
  //     firstDate: now.subtract(Duration(days: 40)),
  //
  //     lastDate: DateTime(now.year + 1), // FIXED (was wrong)
  //   );
  //
  //   if (picked != null) {
  //     setState(() {
  //       selectedDate = picked;
  //
  //       _gatepassdatecontroller.text =
  //           DateFormat('dd/MM/yyyy').format(selectedDate);
  //
  //       date = DateFormat('yyyy-MM-dd').format(selectedDate);
  //     });
  //   }
  // }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,

      // ✅ allow from 2010
      firstDate: DateTime(2010),

      // ✅ allow far future
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;

        final DateFormat formatter = DateFormat('dd/MM/yyyy');
        _gatepassdatecontroller.text = formatter.format(selectedDate);
        date = formatter.format(selectedDate);
      });
    }
  }

  void calculateTotalMin() {
    String startTimeStr = fromTimeInput.text;
    String endTimeStr = toTimeInput.text;

    // Parse the time strings into DateTime objects
    DateTime time1 = _parseTime(startTimeStr);
    DateTime time2 = _parseTime(endTimeStr);

    // Calculate the difference between the two times
    Duration difference = time2.difference(time1);
    int calculatedMinutes = difference.inMinutes;

    // Convert balance time to minutes
    String balanceStr = _balancehrsController.text; // Example: "04:44"
    List<String> balanceParts = balanceStr.split(":");
    int balanceMinutes =
        (int.parse(balanceParts[0]) * 60) + int.parse(balanceParts[1]);

    print('Calculated Time in minutes: $calculatedMinutes');
    print('Balance Time in minutes: $balanceMinutes');

    // Check if calculated time exceeds available balance
    if (calculatedMinutes > balanceMinutes) {
      Fluttertoast.showToast(
        msg: "Cannot apply for debit as insufficient balance",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      // Proceed with debit submission
      _CoffDebit();
    }
  }

// Helper function to parse time string into DateTime
  DateTime _parseTime(String timeStr) {
    List<String> parts = timeStr.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return DateTime(
        2024, 1, 1, hours, minutes); // Arbitrary date for time calculation
  }

  void _clearFields() {
    setState(() {
      fromTimeInput.clear();
      toTimeInput.clear();
      reason = "Select"; // Reset reason to its default value
    });
  }

//
// // Helper function to parse time string into DateTime
//   DateTime _parseTime(String timeStr) {
//     List<String> parts = timeStr.split(":");
//     int hours = int.parse(parts[0]);
//     int minutes = int.parse(parts[1]);
//     return DateTime(2024, 1, 1, hours, minutes); // Arbitrary date
//   }
}

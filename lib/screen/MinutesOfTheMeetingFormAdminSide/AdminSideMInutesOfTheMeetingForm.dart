
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/main.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingDataByVisitSrNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/DynamicRowData.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMALLDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMRowDataRequest.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/DialogForUpdate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../../util/MyColor.dart';

class AdminSideMinutesOfTheMeetingFormScreen extends StatefulWidget {
  String SrNo;
  String staffCode;
  String minuteforno;

  AdminSideMinutesOfTheMeetingFormScreen({
    Key? key,
    required this.SrNo,
    required this.staffCode,
    required this.minuteforno,
  }): super(key: key);



  @override
  State<AdminSideMinutesOfTheMeetingFormScreen> createState() => _AdminSideMinutesOfTheMeetingFormScreenState();
}


class _AdminSideMinutesOfTheMeetingFormScreenState extends State<AdminSideMinutesOfTheMeetingFormScreen> {

  TextEditingController _gatepassdatecontroller = new TextEditingController();
  TextEditingController _memberAbsentController = new TextEditingController();
  TextEditingController _memberPresentController = new TextEditingController();
  TextEditingController _subjectController = new TextEditingController();
  TextEditingController _purposecontroller = new TextEditingController();

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

  String? Auth_Token = "";

  String? staffCode = "";

  String designation = "";

  String departmentName = "";
  List<Widget> dynamicRows = [];
  List<GlobalKey<_DynamicRowState>> rowKeys = [];
  TextEditingController dateController1 = TextEditingController();
  TextEditingController dateController2 = TextEditingController();
  TextEditingController textFieldController1 = TextEditingController();
  TextEditingController textFieldController2 = TextEditingController();
  TextEditingController textFieldController3 = TextEditingController();
  TextEditingController textFieldController4 = TextEditingController();
  TextEditingController textFieldController5 = TextEditingController();
  List<Message> listofRows=[];
  int index = 0;

  @override
  void initState() {
    mainBloc = BlocProvider.of(context);

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
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->" + Auth_Token!);


    mainBloc.add(GetMinutesOfTheMeetingAllDataByVisitSrNoEvents(token: Auth_Token!,SrNo: widget.SrNo));



    mainBloc.add(GetMinutesOfTheMeetingDataByVisitSrNoEvents(token: Auth_Token!,VisitSrNo: widget.SrNo));
  }



  // Method to add a new row
  void addRow(String pointsOrIssues,
      String discussedWith,
      String decisionTaken,
      String responsibility,
      String statusOrRemark,
      String targetDate,
      String nextDate,
      int index
      ) {

    print("index :"+index.toString());

    setState(() {
      dynamicRows.add(DynamicRow(

        pointsOrIssues: pointsOrIssues,
        discussedWith:discussedWith,
        decisionTaken:decisionTaken,
        responsibility: responsibility,
        statusOrRemark:statusOrRemark,
        targetDate:targetDate,
        nextDate:nextDate,

      ));

    });
  }

  // Method to delete a specific row
  void deleteRow(int sindex) {
    setState(() {
      print("deleteRow : " + sindex.toString());
      dynamicRows.removeAt(sindex);

      index--;
      print("deleteRow : " + index.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        /*    leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () =>
              (Navigator.canPop(context)) ? Navigator.pop(context) : Navigator
                  .pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          BlocProvider(
                              create: (context) {
                                return MainBloc(
                                    webService: WebService());
                              },
                              child: AdminHomeScreen())))

          ),*/

          title: const Text("Minutes Of The Meeting Form"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(
            color: Colors.white,
          )
      ),


      body:
      WillPopScope(
        onWillPop: () async {
          /*   Navigator.pop(context, {"FilterAlert":false});
            return false;*/


          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // You can also handle custom back button logic here
            // For example, exit the app, show a confirmation dialog, etc.

            print("Else Navigatorrrrrrrrrrrrr");

            /*  Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        BlocProvider(
                            create: (context) {
                              return MainBloc(
                                  webService: WebService());
                            },
                            child: HomeScreen())));*/
            return false; // Prevent the app from closing
          }
          return true;
        },
        child:
        _addForm(),),
      /* bottomNavigationBar: BottomAppBar(
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
                            builder: (_) =>
                                BlocProvider(
                                    create: (context) {
                                      return MainBloc(
                                          webService: WebService());
                                    },
                                    child: GatePass()))
                    );
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
      ),*/
    );
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
          if (state is GetMinutesOfTheMeetingAllDataByVisitSrNoLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          else if (state is GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState) {
            setState(() {
              _isLoading = false;
            });
            print("GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState ");
            Fluttertoast.showToast(
              msg: "   Success..!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            setState(() {
              if(state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse!.message!.isNotEmpty)
              {
                _gatepassdatecontroller.text=state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse.message!.first!.date!;
                _memberAbsentController.text=state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse.message!.first!.memberAbsent!;
                _memberPresentController.text=state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse.message!.first!.memberPresent!;
                _subjectController.text=state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse.message!.first!.subject!;
                fromTimeInput.text=state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse.message!.first!.time!;

              }
            });


          }
          else if (state is GetMinutesOfTheMeetingAllDataByVisitSrNoErrorState) {
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

          }
          else if (state is GetMinutesOfTheMeetingDataByVisitSrNoLoadedState) {
            setState(() {
              _isLoading = false;
            });
            print("GetMinutesOfTheMeetingDataByVisitSrNoLoadedState ");
            Fluttertoast.showToast(
              msg: "   Success..!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            listofRows.addAll(state.getMinutesOfTheMeetingDataByVisitSrNoResponse!.message!);

            String? pointsOrIssues="";
            String? discussedWith="";
            String? decisionTaken="";
            String? responsibility="";
            String? statusOrRemark="";
            String? targetDate="";
            String? nextDate="";
            print("listofRows size..."+listofRows.length.toString());
            if(listofRows.length>0)
            {
              for(int i=0;i<listofRows.length;i++)
              {
                pointsOrIssues=listofRows[i].pointsOrIssues!;
                discussedWith=listofRows[i].disccussedwith!;
                decisionTaken=listofRows[i].decisionTaken!;
                responsibility=listofRows[i].responsibility!;
                statusOrRemark=listofRows[i].statusOrRemark!;
                targetDate=listofRows[i].targateDate!;
                nextDate=listofRows[i].nextDate!;
                addRow(pointsOrIssues,discussedWith,decisionTaken,responsibility,statusOrRemark,
                    targetDate,nextDate,i);
              }

            }


          }
          else if (state is GetMinutesOfTheMeetingDataByVisitSrNoErrorState) {
            setState(() {
              _isLoading = false;
            });

          }
        },
        child:
        SingleChildScrollView(
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
                  enabled: false,
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
                        borderSide: BorderSide(width: 1,)
                    ),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 1, color: MyColors.textBoxBorderColorCode)
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(
                            width: 2, color: MyColors.buttonColorCode)
                    ),
                    hintText: "DD/MM/YYYY",
                    suffixIcon:
                    Icon(
                      Icons
                          .calendar_month,
                      size: 24,
                      color: MyColors
                          .dateIconColorCode,
                    ),
                    hintStyle: TextStyle(
                        fontSize: 16, color: MyColors.datePlacehoderColorCode),
                    errorText: "",
                  ),
                  style: TextStyle(
                    color: Colors.black, // Change this to any color you prefer
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
                  child:
                  TextField(
                    // onChanged: (value) {
                    //   fromTimeController = value;
                    // },
                    onTap: () async {
                      final DateFormat
                      formatter =
                      DateFormat(
                          'H:mm',
                          Localizations.localeOf(
                              context)
                              .toLanguageTag());
                      final TimeOfDay? picked =
                      await showTimePicker(
                          context:
                          context,
                          initialTime:
                          TimeOfDay
                              .now());
                      builder:
                          (BuildContext
                      context,
                          Widget? child) {
                        return MediaQuery(
                            data: MediaQuery.of(
                                context)
                                .copyWith(
                                alwaysUse24HourFormat:
                                true),
                            child:
                            child!);
                      };
                      if (picked !=
                          null) {
                        final String
                        fromTime =
                        formatter.format(
                            DateTime(
                                0,
                                1,
                                1,
                                picked
                                    .hour,
                                picked
                                    .minute));
                        fromTimeController =
                            fromTime;
                        setState(() {
                          fromTimeInput
                              .text =
                              fromTimeController;
                        });
                      }
                    },
                    readOnly: true,
                    enabled:
                    false,
                    // to trigger disabledBorder
                    decoration:
                    const InputDecoration(
                      filled: true,
                      fillColor: MyColors
                          .whiteColorCode,
                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .all(Radius
                            .circular(
                            4)),
                        borderSide: BorderSide(
                            width: 1,
                            color: MyColors
                                .buttonColorCode),
                      ),
                      disabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .all(Radius
                            .circular(
                            4)),
                        borderSide: BorderSide(
                            width: 1,
                            color: Colors
                                .orange),
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .all(Radius
                            .circular(
                            4)),
                        borderSide: BorderSide(
                            width: 1,
                            color: MyColors
                                .textColorCode),
                      ),
                      border:
                      OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(
                              4)),
                          borderSide:
                          BorderSide(
                            width: 1,
                          )),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius
                              .all(Radius
                              .circular(
                              4)),
                          borderSide: BorderSide(
                              width: 1,
                              color: MyColors
                                  .textBoxBorderColorCode)),
                      focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius
                              .all(Radius
                              .circular(
                              4)),
                          borderSide: BorderSide(
                              width: 2,
                              color: MyColors
                                  .buttonColorCode)),
                      hintText:
                      "hh:mm:AM",
                      suffixIcon:
                      Icon(
                        Icons
                            .watch_later_outlined,
                        size: 24,
                        color: MyColors
                            .dateIconColorCode,
                      ),
                      hintStyle: TextStyle(
                          fontSize: 18,
                          color: MyColors
                              .searchTextColorCode),
                      errorText: "",
                    ),
                    controller:
                    fromTimeInput,
                    // controller: _passwordController,
                    // onChanged: _authenticationFormBloc.onPasswordChanged,
                    obscureText: false,
                    style: TextStyle(
                      color: Colors.black, // Change this to any color you prefer
                    ),
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
                  style: TextStyle(
                    color: Colors.black, // Change this to any color you prefer
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
                  style: TextStyle(
                    color: Colors.black, // Change this to any color you prefer
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
                  style: TextStyle(
                    color: Colors.black, // Change this to any color you prefer
                  ),
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
                  child:


                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,


                    children: [


                      SizedBox(height: 8),

                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          // Horizontal scrolling for the Row
                          child:
                          Column(
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
                                    child:
                                    _buildDynamicTextField(
                                        "Field 2", textFieldController2),
                                  ),
                                  SizedBox(
                                    width: 300, // Adjust the width as needed
                                    child:
                                    _buildDynamicTextField(
                                        "Field 3", textFieldController3),
                                  ),
                                  SizedBox(
                                    width: 200, // Adjust the width as needed
                                    child:
                                    _buildDynamicTextField(
                                        "Field 4", textFieldController4),
                                  ),
                                  SizedBox(
                                    width: 200, // Adjust the width as needed
                                    child:
                                    _buildDynamicTextField(
                                        "Field 5", textFieldController5),),
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
                          )


                      ),

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
      decoration:
      InputDecoration(
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
            fontSize: 16, color: MyColors.black),
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




  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: selectedDate.subtract(Duration(days: 40)),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _gatepassdatecontroller.text =
            selectedDate.day.toString() + "/" + selectedDate.month.toString() +
                "/" + selectedDate.year.toString();
        date =
            selectedDate.year.toString() + "-" + selectedDate.month.toString() +
                "-" + selectedDate.day.toString();
      });
    }
  }

}

class DynamicRow extends StatefulWidget {
//  final VoidCallback onDelete;



  String pointsOrIssues;
  String discussedWith;
  String decisionTaken;
  String responsibility;
  String statusOrRemark;
  String targetDate;
  String nextDate;



  DynamicRow({Key? key
    ,required this.pointsOrIssues,
    required this.discussedWith,
    required this.decisionTaken,
    required this.responsibility,
    required this.statusOrRemark,
    required this.targetDate
    ,required this.nextDate



  }) : super(key: key);
  @override
  _DynamicRowState createState() => _DynamicRowState();
}

class _DynamicRowState extends State<DynamicRow> {
  TextEditingController dateController1 = TextEditingController();
  TextEditingController dateController2 = TextEditingController();
  TextEditingController textFieldController1 = TextEditingController();
  TextEditingController textFieldController2 = TextEditingController();
  TextEditingController textFieldController3 = TextEditingController();
  TextEditingController textFieldController4 = TextEditingController();
  TextEditingController textFieldController5 = TextEditingController();
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
    textFieldController1.text=widget.pointsOrIssues;
    textFieldController2.text=widget.discussedWith;
    textFieldController3.text=widget.decisionTaken;
    textFieldController4.text=widget.responsibility;
    textFieldController5.text=widget.statusOrRemark;
    dateController1.text=widget.targetDate;
    dateController2.text=widget.nextDate;

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Horizontal scrolling for the Row
            child: Row(
              children: [
                // No need for SizedBox or Expanded here, just use TextField directly

                // Removing Expanded from here
                SizedBox(
                  width: 180,
                  child: _buildDynamicTextField("Field 1", textFieldController1),
                ),
                SizedBox(
                  width: 200,
                  child: _buildDynamicTextField("Field 2", textFieldController2),
                ),
                SizedBox(
                  width: 300,
                  child: _buildDynamicTextField("Field 3", textFieldController3),
                ),
                SizedBox(
                  width: 200,
                  child: _buildDynamicTextField("Field 4", textFieldController4),
                ),
                SizedBox(
                  width: 200,
                  child: _buildDynamicTextField("Field 5", textFieldController5),
                ),
                SizedBox(
                  width: 150, // Adjust the width as needed
                  child: TextField(
                    controller: dateController1,
                    enabled: false,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      _selectDate(context, dateController1);
                    }, // to trigger disabledBorder
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
                        borderSide: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 2, color: MyColors.buttonColorCode),
                      ),
                      hintText: "DD/MM/YYYY",
                      suffixIcon: Icon(
                        Icons.calendar_month,
                        size: 24,
                        color: MyColors.dateIconColorCode,
                      ),
                      hintStyle: TextStyle(fontSize: 16, color: MyColors.datePlacehoderColorCode),
                      errorText: "",
                      contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0), // Increase vertical padding to increase height
                    ),
                    obscureText: false,
                  ),
                ),
                SizedBox(
                  width: 200, // Adjust the width as needed
                  child: TextField(
                    controller: dateController2,
                    enabled: false,
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      _selectDate(context, dateController2);
                    },
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
                        borderSide: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(width: 2, color: MyColors.buttonColorCode),
                      ),
                      hintText: "DD/MM/YYYY",
                      suffixIcon: Icon(
                        Icons.calendar_month,
                        size: 24,
                        color: MyColors.dateIconColorCode,
                      ),
                      hintStyle: TextStyle(fontSize: 16, color: MyColors.datePlacehoderColorCode),
                      errorText: "",
                      contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
                    ),
                    obscureText: false,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to open a date picker
  void _selectDate(BuildContext context,
      TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Widget _buildDynamicTextField(String label, TextEditingController controller) {
    return

      TextField(
        controller: controller,
        enabled: false, // to trigger disabledBorder
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
            borderSide: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 2, color: MyColors.buttonColorCode),
          ),
          hintStyle: TextStyle(fontSize: 16, color: MyColors.black),
          errorText: "",
          contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
        ),
        obscureText: false,
      );

  }

}

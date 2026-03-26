import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/GatePass/AddGatepassRequest.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/DialogForUpdate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../../model/GatePass/GatePassResponse.dart';
import '../../util/MyColor.dart';

class AddGatePass extends StatefulWidget {
  //const AddGatePass({super.key});
  int flag;
  Message datum;

  AddGatePass(
      {
        Key? key,
        required this.flag,
        required this.datum,
      })
      : super(key: key);
  @override
  State<AddGatePass> createState() => _AddGatePassState();
}

class _AddGatePassState extends State<AddGatePass> {

  TextEditingController _TransactionidController = new TextEditingController();
  TextEditingController _gatepassdatecontroller = new TextEditingController();
  TextEditingController _staffCodecontroller = new TextEditingController();
  TextEditingController _staffNamecontroller = new TextEditingController();
  TextEditingController _departmentNamecontroller = new TextEditingController();
  TextEditingController _totalmincontroller = new TextEditingController();
  TextEditingController _purposecontroller = new TextEditingController();

  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  DateTime selectedDate = DateTime.now();
  late String date='';
  List<String> gatepasstypeList = [];
  List<String> gatepassReasonsList = [];
  String gatePasstype="Select";
  String gatePassReason="Select";
  bool isGatepasscontainerselected = false;
  bool isReasoncontainerselected = false;
  bool ClickStatus=false;
  var fromTimeController;
  TextEditingController fromTimeInput = TextEditingController();
  var toTimeController;
  TextEditingController toTimeInput = TextEditingController();

  String? Auth_Token="";

  String? staffCode="";

  String designation="";

  String departmentName="";

  @override
  void initState() {
    mainBloc=BlocProvider.of(context);
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

    if (widget.flag == 2)
    {

      print("widget.flag == 2");
      _TransactionidController.text = widget.datum.transactionId.toString();
      _staffCodecontroller.text=widget.datum.staffCode.toString();
      _staffNamecontroller.text=widget.datum.name.toString();
      _departmentNamecontroller.text=departmentName.toString();
      // _gatepassdatecontroller.text=widget.datum.gatePassDate.toString();
      _gatepassdatecontroller.text =
          DateFormat("dd/MM/yyyy").format(DateTime.parse(widget.datum.gatePassDate.toString()));
      gatePasstype=widget.datum.type.toString();
      // fromTimeInput.text=widget.datum.fromTime.toString();
      fromTimeInput.text =
          DateFormat("HH:mm").format(DateTime.parse(widget.datum.fromTime.toString()));
      toTimeInput.text =
          DateFormat("HH:mm").format(DateTime.parse(widget.datum.toTime.toString()));
      // toTimeInput.text=widget.datum.toTime.toString();
      calculateTotalMin();
      _purposecontroller.text=widget.datum.customerName.toString();

    }
    else
    {
      print("widget.flag == 1");
      getData();
    }

  }
  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCodee---->"+staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Tokenn---->"+Auth_Token!);

    mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
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
                              child: GatePass())))

          ),

          title: const Text("Add Gate Pass"),
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

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(
                              webService: WebService());
                        },
                        child: GatePass())));
            return false;  // Prevent the app from closing
          }
          return true;
        },
        child:
        _addGatePass(),),
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
                    _totalmincontroller.clear();
                    _purposecontroller.clear();
                    gatePasstype="Select";
                    gatePassReason="Select";
                    ClickStatus=false;
                    fromTimeInput.text="";
                    toTimeInput.text="";
                  });
                },
                child: const Column(
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
                                  return MainBloc(
                                      webService: WebService());
                                },
                                child: const GatePass()))
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
          if (state is GetStaffDetailsLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          else if (state is GetStaffDetailsLoadedState)
          {
            setState(() {
              _isLoading = false;
            });
            // Fluttertoast.showToast(
            //   msg: "   sucessss...!   ",
            //   toastLength: Toast.LENGTH_SHORT,
            //   timeInSecForIosWeb: 1,
            // );
            if(widget.flag==1) {
              _TransactionidController.text =
                  state.staffDetailsResponse!.message!.transactionID.toString();
              _staffCodecontroller.text =
                  state.staffDetailsResponse!.message!.staffCode.toString();
              _staffNamecontroller.text =
                  state.staffDetailsResponse!.message!.staffName.toString();
              _departmentNamecontroller.text =
                  state.staffDetailsResponse!.message!.departmentName.toString();
              designation =
                  state.staffDetailsResponse!.message!.designation.toString();
            }else if(widget.flag==2){
              _departmentNamecontroller.text=state.staffDetailsResponse!.message!.departmentName.toString();
            }
            setState(() {
              departmentName=state.staffDetailsResponse!.message!.departmentName.toString();
            });
            print(state.staffDetailsResponse!.message!.transactionID.toString());
          }
          else if (state is GetStaffDetailsErrorState)
          {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "   Failed To Connect Server...!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
//-----------------------
          if (state is AddGatePassLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          else if (state is AddGatePassLoadedState)
          {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: state.cancelGatepassResponse!.message!,
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
            if(widget.flag==1) {
              if (state.cancelGatepassResponse!.message ==
                  "Gate Pass Details Saved Successfully!") {
                DialogForUpdate().popUp(
                    context, "Gate Pass Details Saved Successfully!", "3");
              }
            }
            else if(widget.flag==2)
            {

              if (state.cancelGatepassResponse!.message ==
                  "Gate Pass Details Updated Successfully!") {
                DialogForUpdate().popUp(
                    context, "Gate Pass Updated Successfully!", "3");
              }
            }else
            {
            }
          }
          else if (state is AddGatePassErrorState)
          {
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
        child:
        SingleChildScrollView(
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
                        "Transaction ID ",
                        style: TextStyle(fontSize: 18),
                      ),

                    ],
                  ),
                ),
                TextField(
                  controller: _TransactionidController,
                  enabled: false, // to trigger disabledBorder
                  keyboardType: TextInputType.number,
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
                            "Staff Code ",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _staffCodecontroller,
                  enabled: false, // to trigger disabledBorder
                  /* inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
                  ],*/
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
                            "Staff Name",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _staffNamecontroller,
                  enabled: false, // to trigger disabledBorder
                  /* inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
                  ],*/
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
                            "Department Name",
                            style: TextStyle(fontSize: 18),
                          ),

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
                            "GatePass Date",
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
                  onTap: (){
                    FocusScope.of(context).requestFocus(new FocusNode());
                    _selectDate(context);
                  },// to trigger disabledBorder
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
                    ) ,
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
                            "Gate Pass Type",
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
                GestureDetector(
                  onTap: () {

                    setState(() {});
                  },
                  child:

                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child:
                      Container(
                        margin: EdgeInsets.only(top: 10.0, right: 3.0, left: 3.0),
                        height: 50.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(width: 1.0, color: Colors.grey),

                        ),
                        /* height: 40.0,
                            width: double.infinity,
                            margin: EdgeInsets.only(left: 20.0, right: 20.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.grey)),*/
                        child: ListTile(
                          leading: Text(gatePasstype ?? gatePasstype.toString(),style: TextStyle(fontSize: 15.0, )),
                          trailing:
                          isGatepasscontainerselected?
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_up,
                            ),
                            onPressed: () {
                              isGatepasscontainerselected = false;
                              setState(() {});
                            },
                          )
                              :

                          IconButton(
                            icon: Icon(
                                Icons.keyboard_arrow_down),

                            onPressed: () {
                              isGatepasscontainerselected = true;


                              setState(() {});
                            },
                          ),

                        ),

                      )),
                ),
                isGatepasscontainerselected
                    ?
                Card(
                  elevation: 3.0,
                  child: Container(
                    height: 150.0,
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 20.0, right: 20.0),
                    child: ListView.builder(
                      itemCount: gatepasstypeList!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {


                                setState(() {
                                  isGatepasscontainerselected = false;

                                  gatePasstype =gatepasstypeList[index].toString();
                                });

                                String selectedGatepassType = gatepasstypeList![index].toString();
                                print("selectedGatepassType : "+selectedGatepassType);
                              },
                              child: SizedBox(
                                height: 40.0,
                                width: 50.0,
                                child: Text(gatepasstypeList![index].toString()),
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
                        calculateTotalMin( );
                      }
                    },
                    readOnly: true,
                    enabled:
                    true, // to trigger disabledBorder
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
                  ),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "To Time ",
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
                        toTimeController =
                            fromTime;
                        setState(() {
                          toTimeInput
                              .text =
                              toTimeController;
                        });
                        calculateTotalMin( );
                      }
                    },
                    readOnly: true,
                    enabled:
                    true, // to trigger disabledBorder
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
                      suffixIcon: Icon(
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
                    toTimeInput,
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
                            "Total Minutes",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _totalmincontroller,
                  enabled: false,
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
                            "Reason",
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
                GestureDetector(
                  onTap: () {

                    setState(() {});
                  },
                  child:

                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child:
                      Container(
                        margin: EdgeInsets.only(top: 10.0, right: 3.0, left: 3.0),
                        height: 50.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(width: 1.0, color: Colors.grey),

                        ),
                        /* height: 40.0,
                            width: double.infinity,
                            margin: EdgeInsets.only(left: 20.0, right: 20.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.grey)),*/
                        child: ListTile(
                          leading: Text(gatePassReason ?? gatePassReason.toString(),style: TextStyle(fontSize: 15.0, )),
                          trailing:
                          isReasoncontainerselected?
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_up,
                            ),
                            onPressed: () {
                              isReasoncontainerselected = false;
                              setState(() {});
                            },
                          )
                              :

                          IconButton(
                            icon: Icon(
                                Icons.keyboard_arrow_down),

                            onPressed: () {
                              isReasoncontainerselected = true;
                              setState(() {});
                            },
                          ),

                        ),

                      )),
                ),
                isReasoncontainerselected
                    ?
                Card(
                  elevation: 3.0,
                  child: Container(
                    height: 150.0,
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 20.0, right: 20.0),
                    child: ListView.builder(
                      itemCount: gatepassReasonsList!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {

                                setState(() {
                                  isReasoncontainerselected = false;

                                  gatePassReason =gatepassReasonsList[index].toString();
                                });

                                String gatePassReasonn = gatepassReasonsList![index].toString();
                                print("gatePassReason : "+gatePassReasonn);
                              },
                              child: SizedBox(
                                height: 40.0,
                                width: 50.0,
                                child: Text(gatepassReasonsList![index].toString()),
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
                        padding: const EdgeInsets.only(bottom: 8,left: 25),
                        child:CheckboxListTile(
                          title: Text("Please Check Mark To Enter Purpose",style: TextStyle(fontSize: 17.0, )), //    <-- label
                          value: ClickStatus,
                          activeColor: Colors.red,
                          checkColor: Colors.white,
                          onChanged: (newValue) {
                            setState(()  {
                              ClickStatus=newValue!;
                              //   ClickStatus?_purposecontroller.clear():" Enter Purpose ";
                              if(ClickStatus)
                              {
                                String value=_purposecontroller.text;
                                print("purpose value---" +value.toString());

                                //    _purposecontroller.clear();
                                //     _purposecontroller.text=" Enter Purpose ";
                              }
                              else{
                                _purposecontroller.clear();
                              }
                              print("checkvalue---" +newValue.toString());

                            });

                          },
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.all(0),
                        ))   ),

                ClickStatus?
                Align(
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
                    )):Align(
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
                ClickStatus?
                TextField(
                  controller: _purposecontroller,
                  enabled: true, // to trigger disabledBorder

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
                ):Align(
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
        msg: "  Please Select GatePass Date...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (gatePasstype=="Select") {
      Fluttertoast.showToast(
        msg: "  Please Select GatePass Type...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (fromTimeInput.text=="") {
      Fluttertoast.showToast(
        msg: "  Please Select GatePass FromTime...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (toTimeInput.text=="") {
      Fluttertoast.showToast(
        msg: "  Please Select GatePass ToTime...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (_totalmincontroller.text=="") {
      Fluttertoast.showToast(
        msg: "  Please Select From Time & To time...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );

    }
    else if (gatePassReason=="") {
      Fluttertoast.showToast(
        msg: "  Please Select GatePass Reason...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );}
    else if (gatePassReason=="Select") {
      Fluttertoast.showToast(
        msg: "  Please Select GatePass Reason...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (ClickStatus==true) {

      if(_purposecontroller.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "  Please Enter Purpose...!  ",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
      }
      else if (!RegExp(r'^[a-zA-Z\s-]{1,50}$').hasMatch(_purposecontroller.text))  {
        // Handle invalid input (show an error message, etc.)
        Fluttertoast.showToast(
          msg: " Please enter valid purpose!!  ",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
      }
      else{
        print(" ifffffff_else..............");

        _addGatePassData();

      }
    }
    else
    {
      print(" _else..............");

      _addGatePassData();
    }

  }
  _addGatePassData(){
    print(" _addGatePassData() called ClickStatus.............."+ClickStatus.toString());
    print(_gatepassdatecontroller.text);
    print(fromTimeInput.text);
    print(toTimeInput.text);

    if(widget.flag==1){
      mainBloc.add(AddGatePassEvents(
          addGatepassRequest: AddGatepassRequest(
              transactionID:_TransactionidController.text,
              gatePassDate:_gatepassdatecontroller.text,
              staffCode:_staffCodecontroller.text,
              designation:designation,
              dept:_departmentNamecontroller.text,
              gatePassTypeCode:gatePasstype,
              fromTime:fromTimeInput.text,
              toTime:toTimeInput.text,
              totalTime:int.parse(_totalmincontroller.text),
              shiftCode:"GS",
              reason:gatePassReason,
              purpose:_purposecontroller.text,
              chkActive:ClickStatus,
              add:true
          ),
          token: Auth_Token!)

      );

    }
    else if(widget.flag==2){
      mainBloc.add(AddGatePassEvents(
          addGatepassRequest: AddGatepassRequest(
              transactionID:_TransactionidController.text,
              gatePassDate:_gatepassdatecontroller.text,
              staffCode:_staffCodecontroller.text,
              designation:designation,
              dept:_departmentNamecontroller.text,
              gatePassTypeCode:gatePasstype,
              fromTime:fromTimeInput.text,
              toTime:toTimeInput.text,
              totalTime:int.parse(_totalmincontroller.text),
              shiftCode:"GS",
              reason:gatePassReason,
              purpose:_purposecontroller.text,
              chkActive:ClickStatus,
              add:false
          ),
          token: Auth_Token!));
    }
  }

  // Future<void> _selectDate(BuildContext context) async {
  // //  DateTime dateBefore45Days = selectedDate.subtract(Duration(days: 45));
  //   final DateTime? picked = await showDatePicker(
  //       context: context,
  //       initialDate: selectedDate,
  //      // firstDate: DateTime.now(),
  //       // firstDate: DateTime(2015, 8),
  //       // firstDate: DateTime.now().subtract(Duration(days: 1)),
  //       firstDate: selectedDate.subtract(Duration(days:40)),
  //       lastDate: DateTime(2030),
  //      // lastDate: DateTime(2102)
  //   );
  //   if (picked != null && picked != selectedDate) {
  //     setState(() {
  //       selectedDate = picked;
  //       _gatepassdatecontroller.text=selectedDate.day.toString()+"/"+selectedDate.month.toString()+"/"+selectedDate.year.toString();
  //       date=selectedDate.year.toString()+"-"+selectedDate.month.toString()+"-"+selectedDate.day.toString();
  //
  //     });
  //   }
  // }

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

        // Format the date as dd/MM/yyyy
        final DateFormat formatter = DateFormat('dd/MM/yyyy');
        _gatepassdatecontroller.text = formatter.format(selectedDate);

        // Additional date formatting if needed
        date = formatter.format(selectedDate);
      });
    }
  }

/*  void calculateTotalMin() {
    // Define start and end time as strings
    String startTimeStr = fromTimeInput.text;  // Start time as string
    String endTimeStr = toTimeInput.text;    // End time as string
    // Parse the time strings into DateTime objects (using today's date)
    DateTime time1 = _parseTime(startTimeStr);
    DateTime time2 = _parseTime(endTimeStr);

    // Calculate the difference between the two times
    Duration difference = time2.difference(time1);

    // Get the difference in minutes
    int minutes = difference.inMinutes;

    print('The difference in minutes is: $minutes');

    _totalmincontroller.text=minutes.toString();
  }*/
  void calculateTotalMin() {
    String startTimeStr = fromTimeInput.text;
    String endTimeStr = toTimeInput.text;

    // Parse the entered times
    DateTime time1 = _parseTime(startTimeStr);
    DateTime time2 = _parseTime(endTimeStr);

    // Define the valid time range
    DateTime minAllowedTime = _parseTime("08:30");
    DateTime maxAllowedTime = _parseTime("18:00");

    // Validation: From Time should not be before 08:30 AM
    if (time1.isBefore(minAllowedTime)) {
      Fluttertoast.showToast(
        msg: "From Time should not be before 08:30 AM",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    // Validation: To Time should not be after 18:00 PM
    if (time2.isAfter(maxAllowedTime)) {
      Fluttertoast.showToast(
        msg: "To Time should not be after 18:00 PM",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    // Validation: From Time and To Time cannot be the same
    if (time1 == time2) {
      Fluttertoast.showToast(
        msg: "From Time and To Time cannot be the same",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    // Validation: To Time cannot be before From Time
    if (time2.isBefore(time1)) {
      Fluttertoast.showToast(
        msg: "To Time cannot be before From Time",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    // Calculate the time difference if all conditions are satisfied
    Duration difference = time2.difference(time1);
    int minutes = difference.inMinutes;

    print('The difference in minutes is: $minutes');

    _totalmincontroller.text = minutes.toString();
  }



// Helper function to parse time string into DateTime
  DateTime _parseTime(String timeStr) {
    // Split the time string into hours and minutes
    List<String> parts = timeStr.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    // Return a DateTime object with today's date and the given time
    return DateTime(2024, 1, 1, hours, minutes); // Using arbitrary date (e.g., 2024-01-01)
  }

}
//shift not found---abhishek

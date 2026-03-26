
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/GatePass/AddGatepassRequest.dart';
import 'package:attendance_system_ios/model/UsersList/AddStaffRequest.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/UserListScreen/UserListScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/DialogForUpdate.dart';
import 'package:attendance_system_ios/util/custome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/GatePass/GatePassResponse.dart';
import '../../util/MyColor.dart';

class AddNewStaffScreen extends StatefulWidget {
  //const AddGatePass({super.key});

  @override
  State<AddNewStaffScreen> createState() => _AddNewStaffScreenState();

  AddNewStaffScreen();
}

class _AddNewStaffScreenState extends State<AddNewStaffScreen> {

  TextEditingController _StaffCodeController = new TextEditingController();
  TextEditingController _FirstNamecontroller = new TextEditingController();
  TextEditingController _Middlenamecontroller = new TextEditingController();

  TextEditingController _LastNamecontroller = new TextEditingController();
  TextEditingController _DisplayNameController = new TextEditingController();
  TextEditingController _DOBController = new TextEditingController();
  TextEditingController _DOJController = new TextEditingController();
  TextEditingController _PlantCodeController = new TextEditingController();




  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  DateTime selectedDate = DateTime.now();
  DateTime selectedDateofjoining = DateTime.now();

  late String date='';
  bool ClickStatus=false;
  var fromTimeController;
  TextEditingController fromTimeInput = TextEditingController();
  var toTimeController;
  TextEditingController toTimeInput = TextEditingController();

  String? Auth_Token="";



  String designation="";

  String departmentName="";

  List<String> planCodeList=[];
  String PlantCode="Select";

  bool isPlantCodecontainerselected=false;

  @override
  void initState() {

    mainBloc = BlocProvider.of<MainBloc>(context);


    getData();

    planCodeList.add("Select");
    planCodeList.add("001");

  }


  Future<void> getData() async {

    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->"+Auth_Token!);


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
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
                          child: UserListScreen())))

          ),

          title: const Text("Add Staff Entry"),
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
                        child: UserListScreen())));
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
                    _StaffCodeController.clear();
                    _FirstNamecontroller.clear();
                    _Middlenamecontroller.clear();
                    _LastNamecontroller.clear();
                    _DisplayNameController.clear();
                    _DOJController.clear();
                    _DOBController.clear();


                    PlantCode="Select";

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
                                  return MainBloc(
                                      webService: WebService());
                                },
                                child: UserListScreen())));
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
          if (state is AddStaffEntryLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          else if (state is AddStaffEntryLoadedState)
          {
            setState(() {
              _isLoading = false;
            });
            if(state.cancelGatepassResponse.message == "Record Added Successfully..." ){
              Fluttertoast.showToast(
                msg: "   Record added successfully...!   ",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
              setState(() {
                _StaffCodeController.clear();
                _FirstNamecontroller.clear();
                _Middlenamecontroller.clear();
                _LastNamecontroller.clear();
                _DisplayNameController.clear();
                _DOJController.clear();
                _DOBController.clear();

                PlantCode="Select";

              });
            }
            else if(state.cancelGatepassResponse.message == "Record is Already Present.."){
              Fluttertoast.showToast(
                msg: "   Staffcode already present!   ",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
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
//-----------------------
          if (state is AddGatePassLoadingState) {
            setState(() {
              _isLoading = true;
            });
          }
          else if (state is AddGatePassLoadedState)
          {

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
                        "Staff Code ",
                        style: TextStyle(fontSize: 18),
                      ),

                    ],
                  ),
                ),

                TextField(
                  controller: _StaffCodeController,
                  enabled: true, // to trigger disabledBorder
                  /* inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
                  ],*/
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
                            "First Name ",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _FirstNamecontroller,
                  enabled: true, // to trigger disabledBorder
                  /* inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
                  ],*/
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
                            "Middle Name",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _Middlenamecontroller,
                  enabled: true, // to trigger disabledBorder
                  /* inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]")),
                  ],*/
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
                            "Last Name",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _LastNamecontroller,
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
                        )
                    ),
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
                            "Display Name",
                            style: TextStyle(fontSize: 18),
                          ),

                        ],
                      ),
                    )),
                TextField(
                  controller: _DisplayNameController,
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
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Date Of Birth",
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
                  controller: _DOBController,
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
                            "Date Of Joining",
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
                  controller: _DOJController,
                  readOnly: true,
                  enabled: true,
                  onTap: (){
                    FocusScope.of(context).requestFocus(new FocusNode());
                    _selectDateOfJoining(context);
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
                            "Plant Code",
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
                          leading: Text(PlantCode ?? PlantCode.toString(),style: TextStyle(fontSize: 15.0, )),
                          trailing:
                          isPlantCodecontainerselected?
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_up,
                            ),
                            onPressed: () {
                              isPlantCodecontainerselected = false;
                              setState(() {});
                            },
                          )
                              :

                          IconButton(
                            icon: Icon(
                                Icons.keyboard_arrow_down),

                            onPressed: () {
                              isPlantCodecontainerselected = true;


                              setState(() {});
                            },
                          ),

                        ),

                      )),
                ),
                isPlantCodecontainerselected
                    ?
                Card(
                  elevation: 3.0,
                  child: Container(
                    height: 150.0,
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 20.0, right: 20.0),
                    child: ListView.builder(
                      itemCount: planCodeList!.length,
                      itemBuilder: (BuildContext context, int index) {

                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {


                                setState(() {
                                  isPlantCodecontainerselected = false;

                                  PlantCode =planCodeList[index].toString();
                                });

                                String selectedCode = planCodeList![index].toString();
                                print("PlantCode : "+selectedCode);
                              },
                              child: SizedBox(
                                height: 40.0,
                                width: 50.0,
                                child: Text(planCodeList![index].toString()),
                              ),
                            ));
                      },
                    ),
                  ),
                )
                    : SizedBox(),

              ],
            ),
          ),
        ),
      ),
    );
  }

  _validation() {

    if (_StaffCodeController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Staff Code...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (_StaffCodeController.text.length<7) {
      Fluttertoast.showToast(
        msg: "  Please Enter 7 Digits Staff Code...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (_StaffCodeController.text.length>7) {
      Fluttertoast.showToast(
        msg: "  Please Enter 7 Digits Staff Code...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (_FirstNamecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter First Name...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );

    }
    else if (_Middlenamecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Middle Name...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );

    }
    else if (_LastNamecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Last Name...! ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );

    }
    else if (_DisplayNameController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Enter Display Name...! ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );

    }
    else if (_DOBController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select Date Of Birth...! ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else {
      DateTime today = DateTime.now();
      String dobText = _DOBController.text; // Should now be in yyyy-MM-dd format

      // Parse using the expected format
      DateTime dob = DateFormat('yyyy-MM-dd').parse(dobText);

      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      if (dob.isAfter(today)) {
        Fluttertoast.showToast(
          msg: "Date of birth cannot be in the future!",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
        return;
      }
      else if (age < 18) {
        Fluttertoast.showToast(
          msg: "Please Enter Valid DOB. You must be at least 18 years old!",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
        return;
      }
    }

    if (_DOJController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "  Please Select Date Of Joining...! ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;

    }

    else if (PlantCode=="Select") {
      Fluttertoast.showToast(
        msg: "  Please Select Plant Code...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    print(" _else..............");

    _addStaffEntry();


  }

  _addStaffEntry(){
    DateTime dateOfBirth = DateTime(selectedDate.year,selectedDate.month,selectedDate.day); // Example DateTime
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateOfBirth);
    DateTime joiningDate = DateTime(selectedDateofjoining.year,selectedDateofjoining.month,selectedDateofjoining.day); // Example DateTime
    String formattedjoiningDate = DateFormat('yyyy-MM-dd').format(joiningDate);

    mainBloc.add(AddStaffEntryEvents(
        addStaffRequest: AddStaffRequest(

            staffCode: _StaffCodeController.text,
            firstName: _FirstNamecontroller.text,
            middleName: _Middlenamecontroller.text,
            lastName: _LastNamecontroller.text,
            displayName: _DisplayNameController.text,
            dateOfBirth: formattedDate,
            joiningDate: formattedjoiningDate,
            plantCode: PlantCode

        ),
        token: Auth_Token!));


  }

/*  Future<void> _selectDate(BuildContext context) async {
    //  DateTime dateBefore45Days = selectedDate.subtract(Duration(days: 45));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      // firstDate: DateTime.now(),
      // firstDate: DateTime(2015, 8),
      // firstDate: DateTime.now().subtract(Duration(days: 1)),
      firstDate: DateTime(1900, 8),
      lastDate: DateTime.now(),
      // lastDate: DateTime(2102)
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _DOBController.text=selectedDate.day.toString()+"/"+selectedDate.month.toString()+"/"+selectedDate.year.toString();
        date=selectedDate.year.toString()+"-"+selectedDate.month.toString()+"-"+selectedDate.day.toString();

      });
    }
  }*/
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900, 8),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Format the selected date as yyyy-MM-dd
        _DOBController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
        date = _DOBController.text;
      });
    }
  }


  Future<void> _selectDateOfJoining(BuildContext context) async {
    //  DateTime dateBefore45Days = selectedDate.subtract(Duration(days: 45));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateofjoining,
      // firstDate: DateTime.now(),
      // firstDate: DateTime(2015, 8),
      // firstDate: DateTime.now().subtract(Duration(days: 1)),
      firstDate: selectedDateofjoining.subtract(Duration(days:40)),
      lastDate: DateTime(2100),
      // lastDate: DateTime(2102)
    );
    if (picked != null && picked != selectedDateofjoining) {
      setState(() {
        selectedDateofjoining = picked;
        _DOJController.text=selectedDateofjoining.day.toString()+"/"+selectedDateofjoining.month.toString()+"/"+selectedDateofjoining.year.toString();
        date=selectedDateofjoining.year.toString()+"-"+selectedDateofjoining.month.toString()+"-"+selectedDateofjoining.day.toString();

      });
    }
  }

/*  Future<void> _selectDateOfJoining(BuildContext context) async {
    //  DateTime dateBefore45Days = selectedDate.subtract(Duration(days: 45));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateofjoining,
      firstDate: DateTime(1900, 8),
      lastDate: DateTime.now(),
      // lastDate: DateTime(2102)
    );
    if (picked != null && picked != selectedDateofjoining) {
      setState(() {
        selectedDateofjoining = picked;
        _DOJController.text=selectedDateofjoining.day.toString()+"/"+selectedDateofjoining.month.toString()+"/"+selectedDateofjoining.year.toString();
        date=selectedDateofjoining.year.toString()+"-"+selectedDateofjoining.month.toString()+"-"+selectedDateofjoining.day.toString();

      });
    }
  }*/



}
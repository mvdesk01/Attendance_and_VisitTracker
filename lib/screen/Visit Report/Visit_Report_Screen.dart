import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/Visit%20Report/VisitReportDetailedScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:attendance_system_ios/util/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/UsersList/GetAllusersListResponse.dart';
import '../../model/VisitReport/VisitRecordsResponse.dart';

class VisitReportScreen extends StatefulWidget {

  Message datum;

  VisitReportScreen(
      {
        Key? key,
        required this.datum,
      })
      : super(key: key);

  @override
  State<VisitReportScreen> createState() => _VisitReportScreenState();
}

class _VisitReportScreenState extends State<VisitReportScreen> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;

  final controller = ScrollController();
  TextEditingController _fromdatecontroller = new TextEditingController();
  TextEditingController _fromTimecontroller = new TextEditingController();
  TextEditingController _todatecontroller = new TextEditingController();
  TextEditingController _toTimecontroller = new TextEditingController();
  late String date1 = '', todate1 = '', fromTime1 = '', toTime1 = '';
  late String date = '', todate = '', fromTime = '', toTime = '';
  DateTime currentdate = DateTime.now();

  DateTime selectedDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TimeOfDay selectedToTime = TimeOfDay.now();
  late Message data;

  List<Data> visitList=[];
  ScrollController visitRecordController=new ScrollController();

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    data=widget.datum;

    setState(() {
      // Format the current date with Jiffy using the correct constructor
      todate= Jiffy.now().format(pattern: 'dd/MM/yyyy'); // Mar 2nd 21
      date=Jiffy.now().format(pattern: 'd/MM/yyyy');
      fromTime = "0:1";
      toTime = "23:59";

      todate1 =Jiffy.now().format(pattern: 'dd/MM/yyyy');
      date1 =Jiffy.now().format(pattern: 'dd/MM/yyyy');
      fromTime1 = "0:1";
      toTime1 = "23:59";
    });

    getData();

  }
  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");
    mainBloc.add(GetVisitByFromDateToDate(UserId: data.staffCode!,
        pageNumber: 1,
        pageSize: 50,
        fromDate: date1,
        toDate: todate1,
        token: Auth_Token!));

  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 28,
          ),
          title: const Text("Visit Report"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ).copyWith(
            color: Colors.white,
          ),
        ),
        drawer: MenuDrawer(),
        backgroundColor: MyColors.backgroundColorCode,
        body: LoadingOverlay(
          isLoading: _isLoading,
          opacity: 0.5,
          color: Colors.white,
          progressIndicator: CircularProgressIndicator(
            backgroundColor: Color(0xFFCE4A6F),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          child: BlocListener<MainBloc, MainState>(
            listener: (context, state) async {
              if (state is GetVisitByFromDateToDateLoadingState) {
                print("GetVisitByFromDateToDateLoadingState called...");

                setState(() {
                  _isLoading = true;
                });
              }
              else if (state is GetVisitByFromDateToDateLoadedState) {
                print("GetVisitByFromDateToDateLoadedState called...");


                setState(() {
                  _isLoading = false;
                  visitList.clear();
                });
                /*Fluttertoast.showToast(
                  msg: "   Success!   ",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                );*/
                print("visitList Size....${visitList.length}");
                if(state.visitRecordsResponse!.data !=null) {
                  setState(() {
                    visitList.addAll(state.visitRecordsResponse!.data!);

                  });
                  print("visitList Size...........${visitList.length}");

                }else{
                  print("visitList Size....${visitList.length}");

                }

                if(visitList.length==0)
                  {

                  }
              }
              else if (state is GetVisitByFromDateToDateErrorState) {
                print("GetVisitByFromDateToDateErrorState called...");

                setState(() {
                  _isLoading = false;
                });
                Fluttertoast.showToast(
                  msg: "   Failed To Connect Server!   ",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                );
              }
            },
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  Container(
                    padding:
                    EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                        color: MyColors.lightgreyColorCode,
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 10, color: MyColors.shadowGreyColorCode)
                        ]),
                    // width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text( " From date ",style: TextStyle(fontWeight: FontWeight.bold),),
                              Text(_fromdatecontroller.text.isEmpty
                                  ? date1
                                  : _fromdatecontroller.text),
                              /*Text(_fromTimecontroller.text.isEmpty
                                  ? fromTime1
                                  : _fromTimecontroller.text),*/
                            ],
                          ),
                        ),
                        Text("-"),
                        Expanded(
                          child: Column(
                            children: [
                              Text( " To date ",style: TextStyle(fontWeight: FontWeight.bold),),
                              Text(_todatecontroller.text.isEmpty
                                  ? todate1
                                  : _todatecontroller.text),
                             /* Text(_toTimecontroller.text.isEmpty
                                  ? toTime1
                                  : _toTimecontroller.text),*/
                            ],
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _fromdatecontroller.text=date1;
                              _fromTimecontroller.text=fromTime1;
                              _todatecontroller.text=todate1;
                              _toTimecontroller.text=toTime1;
                              changeDatepopUp(context);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.only(
                                  left: 15, right: 15, top: 10, bottom: 10),
                              decoration: BoxDecoration(
                                  color: MyColors.greyColorCode,
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                              child: Text(
                                "Change",
                                style: TextStyle(
                                    color: MyColors.text4ColorCode, fontSize: 18),
                              ),
                            ),
                          ),
                        )

                        // Text("10 NOTIFICATIONS",style: TextStyle(fontSize: 18),),
                        // Text("CLEAR ALL",style: TextStyle(decoration: TextDecoration.underline,color: MyColors.appDefaultColorCode,fontSize: 18),),
                      ],
                    ),
                  ),
                   Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: MyColors.lightBlue),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Total Visit Records  : " + visitList.length.toString(),
                            style: TextStyle(
                                color: MyColors.blueColorCode,
                                fontSize: 18, fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListView.builder(
                      controller: visitRecordController,
                      shrinkWrap: true,
                      itemCount: visitList.length,
                      itemBuilder: (context,index){
                        return GestureDetector(onTap: (){
                        },
                            child:
                            Card(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 1,color: MyColors.textBoxBorderColorCode),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child:
                              Container(
                                padding: EdgeInsets.only(top:15,left:14,right:14,bottom: 15),
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                            child:
                                            visitList[index].status=="C"?
                                            Icon(Icons.circle,size:10,color: MyColors.redColorCode):
                                            visitList[index].status=="S"?
                                            Icon(Icons.circle,size:10,color: MyColors.greenColorCode)
                                                :
                                            visitList[index].status=="P"?

                                            Icon(Icons.circle,size:10,color: MyColors.blueColorCode)

                                                :
                                            Icon(Icons.circle,size:10,color: MyColors.blueColorCode)

                                        ),
                                        Expanded(
                                          child: visitList[index].status=="C"?
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: Text("Completed",style: TextStyle(color: MyColors.redColorCode,fontWeight: FontWeight.bold,
                                              fontSize: 18.0,),
                                            ),
                                          ):
                                          visitList[index].status=="S"?
                                          Text("Started",style: TextStyle(color: MyColors.greenColorCode,fontWeight: FontWeight.bold,
                                            fontSize: 18.0,),)
                                              :visitList[index].status=="P"
                                              ?
                                          Text("Pending",style: TextStyle(color: MyColors.blueColorCode,fontWeight: FontWeight.bold,
                                            fontSize: 18.0,),):
                                          Text("",style: TextStyle(color: MyColors.greenColorCode,fontWeight: FontWeight.bold,
                                            fontSize: 18.0,),),
                                        ),
                                        Expanded(
                                          child:
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              visitList[index].status=="C" ||visitList[index].status=="S"?
                                              MaterialButton(
                                                onPressed: () {

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => BlocProvider(
                                                          create: (context) {
                                                            return MainBloc(webService: WebService());
                                                          },
                                                          child: VisitReportDetailedScreen(StaffCode:visitList![index].userId,visitsrNo:visitList![index].srNo.toString(),selectdate: visitList![index].selectDate ,record: visitList[index],)),
                                                    ),
                                                  );
                                                },
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.all(Radius.circular(10))),
                                                child: Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 2.0, right: 8, top: 8, bottom: 8),
                                                  child: Text(
                                                    "Show Report",
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        color: MyColors.whiteColorCode),
                                                  ),
                                                ),
                                                color: MyColors.fontBlue,
                                              ):
                                              SizedBox()
                                            ],),)
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 15.0,bottom: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("Visit Name ",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                                Text(visitList[index].source.toString()!=null ? visitList[index].source.toString()+" - "+visitList[index].destination.toString() : "NA",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Visit Date",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                                  Text(visitList[index].selectDate!=null ? visitList[index].selectDate! :  "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                                ],
                                              )
                                          )
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("FromTime-ToTime",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                                Text(visitList[index].fromtime!=null ? visitList[index].fromtime!+" - "+visitList[index].totime! :  "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                              ],
                                            )
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Reason",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                              Text(visitList[index].reason!=null ? visitList[index].reason! : "",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                            ],
                                          ),
                                        ),

                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ));

                      }
                  ),

                ],
              ),
            ),


          ),
        ),
      ),
    );

  }

  changeDatepopUp(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: 350,
              width: MediaQuery.of(context).size.width - 20,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 10),
                      child: Text(
                        "From Date",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _fromdatecontroller,
                            enabled: true, // to trigger disabledBorder
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: MyColors.whiteColorCode,
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                                borderSide: BorderSide(
                                    width: 1, color: MyColors.buttonColorCode),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                                borderSide:
                                BorderSide(width: 1, color: Colors.orange),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                                borderSide: BorderSide(
                                    width: 1, color: MyColors.textColorCode),
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
                                      width: 2,
                                      color: MyColors.buttonColorCode)),
                              hintText: "DD/MM/YY",
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 24,
                                color: MyColors.dateIconColorCode,
                              ),
                              hintStyle: TextStyle(
                                  fontSize: 18,
                                  color: MyColors.searchTextColorCode),
                              errorText: "",
                            ),
                            // controller: _passwordController,
                            // onChanged: _authenticationFormBloc.onPasswordChanged,
                            obscureText: false,
                            onTap: () {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                              _selectDate(context);
                            },
                          ),
                        ),

                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 10),
                      child: Text(
                        "To Date",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _todatecontroller,
                            enabled: true, // to trigger disabledBorder
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: MyColors.whiteColorCode,
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                                borderSide: BorderSide(
                                    width: 1, color: MyColors.buttonColorCode),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                                borderSide:
                                BorderSide(width: 1, color: Colors.orange),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                                borderSide: BorderSide(
                                    width: 1, color: MyColors.textColorCode),
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
                                      width: 2,
                                      color: MyColors.buttonColorCode)),
                              hintText: "DD/MM/YY",
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 24,
                                color: MyColors.dateIconColorCode,
                              ),
                              hintStyle: TextStyle(
                                  fontSize: 18,
                                  color: MyColors.searchTextColorCode),
                              errorText: "",
                            ),
                            // controller: _passwordController,
                            // onChanged: _authenticationFormBloc.onPasswordChanged,
                            obscureText: false,
                            onTap: () {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                              _toDate(context);
                            },
                          ),
                        ),

                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              // _fromdatecontroller.clear();
                              // _toTimecontroller.clear();
                              // _fromTimecontroller.clear();
                              // _todatecontroller.clear();
                              _fromdatecontroller.text = "";
                              _toTimecontroller.text = "";
                              _fromTimecontroller.text = "";
                              _todatecontroller.text = "";
                              setState(() {
                                // searchDateWiseData!.clear();
                                // isDateWiseSearch=false;
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
                        ),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close,
                                  color: MyColors.text4ColorCode,
                                ),
                                Text("Close",
                                    style: TextStyle(
                                        color: MyColors.text4ColorCode,
                                        decoration: TextDecoration.underline,
                                        fontSize: 20)),
                              ],
                            ),
                          ),
                        ),
                        // IconButton(
                        //     onPressed: (){
                        //
                        //     },
                        //     icon: Icon(Icons.)),
                        Expanded(
                          flex: 2,
                          child: MaterialButton(
                            onPressed: () {


                              _validation();
                              // Navigator.of(context).pop();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0, right: 8, top: 8, bottom: 8),
                              child: Text(
                                "Apply",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: MyColors.whiteColorCode),
                              ),
                            ),
                            color: MyColors.buttonColorCode,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        // firstDate: DateTime.now(),
        firstDate: DateTime(2023, 8),
        // firstDate: DateTime.now().subtract(Duration(days: 1)),
        lastDate: DateTime.now());
    if (picked != null /*&& picked != selectedDate*/) {
      setState(() {
        selectedDate = picked;
        /*_fromdatecontroller.text = selectedDate.day.toString() +
            "/" +
            selectedDate.month.toString() +
            "/" +
            selectedDate.year.toString();*/
        // date=selectedDate.year.toString()+"-"+selectedDate.month.toString()+"-"+selectedDate.day.toString();
    //    date = Jiffy(selectedDate).format('d-MMMM-yyyy');
      //  date = Jiffy.now().format('d-MMMM-yyyy');
      date = DateFormat('dd/MM/yyyy').format(selectedDate);

        print("fromDate---"+date);
        _fromdatecontroller.text=date;
        date1=_fromdatecontroller.text;
        //print(date);
      });
    }
  }
  Future<void> _toDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedToDate,
        firstDate: DateTime(2023, 8),
        lastDate: DateTime.now());
    if (picked != null /* && picked != selectedToDate*/) {
      setState(() {
        selectedToDate = picked;

        todate = DateFormat('dd/MM/yyyy').format(selectedToDate);
        _todatecontroller.text=todate;
        print("toDate---"+todate);
        todate1= _todatecontroller.text;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (timeOfDay != null /* && timeOfDay != selectedTime*/) {
      setState(() {
        selectedTime = timeOfDay;
        _fromTimecontroller.text =
            selectedTime.hour.toString() + ":" + selectedTime.minute.toString();
        fromTime =
            selectedTime.hour.toString() + ":" + selectedTime.minute.toString();
        //print(selectedTime);
        fromTime1=_fromTimecontroller.text;
      });
    }
  }

  Future<void> _selectToTime(BuildContext context) async {
    TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedToTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (timeOfDay != null /* && timeOfDay != selectedToTime*/) {
      setState(() {
        selectedToTime = timeOfDay;
        _toTimecontroller.text = selectedToTime.hour.toString() +
            ":" +
            selectedToTime.minute.toString();
        //print(selectedToTime);
        toTime = selectedToTime.hour.toString() +
            ":" +
            selectedToTime.minute.toString();
        toTime1=_toTimecontroller.text;

      });
    }
  }

  _validation() {
    if (_fromdatecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please Select From Date",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_fromTimecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please Select From Time",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_todatecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please Select To Date",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (_toTimecontroller.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please Select To Time",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else if (selectedDate.compareTo(selectedToDate) == 1) {
      Fluttertoast.showToast(
        msg:
        "Please check Start & End date! Start date should be less than to End date...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if (selectedDate.day == selectedToDate.day && fromTime1 == toTime1) {
      Fluttertoast.showToast(
        msg:
        "Please Select From & To Time! FromTime And ToTime Should Not Be Same...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else {

      Navigator.pop(context);

     mainBloc.add(GetVisitByFromDateToDate(UserId: data.staffCode!,
         pageNumber: 1,
         pageSize: 50,
         fromDate: _fromdatecontroller.text,
         toDate: _todatecontroller.text,
         token: Auth_Token!));





    }
  }





}
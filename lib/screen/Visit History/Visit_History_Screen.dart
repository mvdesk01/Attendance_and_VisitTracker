import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/Visit%20History/VisitHistoryTrack_Screen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';

// import '../../model/CoffCredit/FetchCoffTransactionsResponse.dart';
import '../../database/database_helper.dart';
import '../../main.dart';
import '../../model/VisitReport/VisitDetailedRecordsResponse.dart';
import '../../model/VisitReport/VisitRecordsResponse.dart';
import '../MinutesOfTheMeetingForm.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staffCode = "";
  String? Auth_Token = "";
  late List<Message> latLongList = [];
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
  List<Data> visitList = [];
  ScrollController visitRecordController = new ScrollController();
  final formatter = DateFormat("dd/MM/yyyy hh:mm a");
  bool _hasNavigated = false;

  String? value;
  bool isVisitRunning = false;

  String visitDateMOM = '';
  String toTimeMOM = '';
  String vistNameMOM = '';

  @override
  void initState() {
    //  data=widget.datum;
    setState(() {
      // Format the current date with Jiffy using the correct constructor
      todate = Jiffy.now().format(pattern: 'dd/MM/yyyy'); // Mar 2nd 21
      date = Jiffy.now().format(pattern: 'd/MM/yyyy');
      fromTime = "0:1";
      toTime = "23:59";

      todate1 = Jiffy.now().format(pattern: 'dd/MM/yyyy');
      date1 = Jiffy.now().format(pattern: 'dd/MM/yyyy');
      fromTime1 = "0:1";
      toTime1 = "23:59";
    });
    getData();
    remaningCountOfTrackingData();
    // isVisitRunning = value == "true";
  }

  Future<void> remaningCountOfTrackingData() async {
    final remaining = (await DatabaseHelper().getStoredLocations()).length;
    VisitState.countRemainingLatLong.value = remaining;
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    value = await storage.read(key: 'isVisitRunning');

    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");

    // setState(() {
    isVisitRunning = value == "true";
    // });
    mainBloc.add(GetVisitByFromDateToDate(
        UserId: staffCode!,
        pageNumber: 1,
        pageSize: 50,
        fromDate: date1,
        toDate: todate1,
        token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 28,
          ),
          title: const Text("Visit History"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ).copyWith(
            color: Colors.white,
          ),
        ),
        // drawer: MenuDrawer(),
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
              } else if (state is GetVisitByFromDateToDateLoadedState) {
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
                if (state.visitRecordsResponse!.data != null) {
                  setState(() {
                    visitList.addAll(state.visitRecordsResponse!.data!);
                  });
                  print("visitList Size...........${visitList.length}");
                } else {
                  print("visitList Size....${visitList.length}");
                }

                // if(visitList.length==0)
                // {
                //   Fluttertoast.showToast(
                //     msg: "Visit records Not Found",
                //     toastLength: Toast.LENGTH_SHORT,
                //     timeInSecForIosWeb: 1,
                //   );
                // }
              } else if (state is GetVisitByFromDateToDateErrorState) {
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

              if (state is GetVisitDetailedRecordsLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              }
              // else if (state is GetVisitDetailedRecordsLoadedState)
              // {
              //   setState(() {
              //     _isLoading = false;
              //     latLongList.clear();
              //   });
              //     Fluttertoast.showToast(
              //     msg: "   sucessss...!   ",
              //     toastLength: Toast.LENGTH_SHORT,
              //     timeInSecForIosWeb: 1,
              //   );
              //   // latLongList.addAll(state.visitLatLongListResponse!.message!);
              //   latLongList.addAll(state.visitDetailedRecordsResponse!.message!);
              //
              //   print("latLongList Size...."+latLongList!.length.toString());
              //   Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (_) => BlocProvider(
              //               create: (context) {
              //                 return MainBloc(
              //                     webService:
              //                     WebService());
              //               },
              //               child:
              //               VisitHistoryTrackScreen(latLongList: latLongList,)
              //           )));
              //   if(state.visitDetailedRecordsResponse?.message?.toString() == "{message: {message: Record Not Found...}}");
              // }
              else if (state is GetVisitDetailedRecordsLoadedState) {
                setState(() {
                  _isLoading = false;
                  latLongList.clear();
                });

                if (state.visitDetailedRecordsResponse == null) {
                  Fluttertoast.showToast(msg: "No data to track");
                  return;
                }

                // Handle "Record Not Found" case
                // if (state.visitDetailedRecordsResponse!.message is Map) {
                //   final message = state.visitDetailedRecordsResponse!.message as Map;
                //   if (message["message"] == "Record Not Found...") {
                //     Fluttertoast.showToast(msg: "No data to track");
                //     return;
                //   }
                // }

                // Handle valid data case
                if (state.visitDetailedRecordsResponse!.message
                    is List<Message>) {
                  latLongList.addAll(state.visitDetailedRecordsResponse!.message
                      as List<Message>);
                  print("latLongList Size....${latLongList.length}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (context) => MainBloc(webService: WebService()),
                        child:
                            VisitHistoryTrackScreen(latLongList: latLongList),
                      ),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(msg: "Invalid data format");
                }
              } else if (state is GetVisitDetailedRecordsErrorState) {
                setState(() {
                  _isLoading = false;
                });
              }

              if (state is GetMinutesOfMeetingFormNoLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              }
              // else if (state is GetMinutesOfMeetingFormNoLoadedState) {
              //   setState(() {
              //     _isLoading = false;
              //   });
              //   print("GetMinutesOfMeetingFormNoLoadedState.........");
              //   //   int formVal=state.getMinutesOfMeetingFormNoResponse.message!.srNo;
              //   // print("GetMinutesOfMeetingFormNoLoadedState........."+formVal.toString());
              //
              //   if (state.getMinutesOfMeetingFormNoResponse.message!.srNo ==
              //           null ||
              //       state.getMinutesOfMeetingFormNoResponse.message!
              //               .minutesofMeetFormNo ==
              //           null) {
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (_) => BlocProvider(
              //                 create: (context) {
              //                   return MainBloc(webService: WebService());
              //                 },
              //                 child: MinutesOfTheMeetingFormScreen(
              //                     visitSrNo: state
              //                         .getMinutesOfMeetingFormNoResponse
              //                         .message!
              //                         .srNo
              //                         .toString(),
              //                     minuteforno: state
              //                         .getMinutesOfMeetingFormNoResponse
              //                         .message!
              //                         .minutesofMeetFormNo
              //                         .toString(),
              //                     visitDateMOM: visitDateMOM,
              //                     toTimeMOM: toTimeMOM,
              //                     visitNameMOM: vistNameMOM))));
              //
              //     print("not Filled yet...");
              //   } else {
              //     print("Form is Filled ..");
              //
              //     Fluttertoast.showToast(
              //       msg:
              //           "   Minutes of the Meeting form has already been filled out for this visit...!   ",
              //       toastLength: Toast.LENGTH_SHORT,
              //       timeInSecForIosWeb: 1,
              //     );
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (_) => BlocProvider(
              //                 create: (context) {
              //                   return MainBloc(webService: WebService());
              //                 },
              //                 child: MinutesOfTheMeetingFormScreen(
              //                     visitSrNo: state
              //                         .getMinutesOfMeetingFormNoResponse
              //                         .message!
              //                         .srNo
              //                         .toString(),
              //                     minuteforno: state
              //                         .getMinutesOfMeetingFormNoResponse
              //                         .message!
              //                         .minutesofMeetFormNo
              //                         .toString(),
              //                     visitDateMOM: visitDateMOM,
              //                     toTimeMOM: toTimeMOM,
              //                     visitNameMOM: vistNameMOM))));
              //   }
              // }
              else if (state is GetMinutesOfMeetingFormNoLoadedState) {
                if (_hasNavigated) return; // prevent duplicate calls
                _hasNavigated = true;

                setState(() {
                  _isLoading = false;
                });

                final data = state.getMinutesOfMeetingFormNoResponse.message!;

                bool isFormFilled =
                    data.srNo != null && data.minutesofMeetFormNo != null;

                if (isFormFilled) {
                  print("Form is Filled ..");

                  Fluttertoast.showToast(
                    msg: "Minutes of the Meeting form already filled!",
                  );
                } else {
                  print("Form NOT filled...");
                }

                // ✅ NAVIGATION ONLY ONCE
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => BlocProvider(
                //       create: (_) => MainBloc(webService: WebService()),
                //       child: MinutesOfTheMeetingFormScreen(
                //         visitSrNo: data.srNo?.toString() ?? "",
                //         minuteforno: data.minutesofMeetFormNo?.toString() ?? "",
                //         visitDateMOM: visitDateMOM,
                //         toTimeMOM: toTimeMOM,
                //         visitNameMOM: vistNameMOM,
                //       ),
                //     ),
                //   ),
                // );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => MainBloc(webService: WebService()),
                      child: MinutesOfTheMeetingFormScreen(
                        visitSrNo: data.srNo?.toString() ?? "",
                        minuteforno: data.minutesofMeetFormNo?.toString() ?? "",
                      ),
                    ),
                  ),
                ).then((_) {
                  // ✅ Reset flag and loading when user comes back
                  setState(() {
                    _hasNavigated = false;
                    _isLoading = false;
                  });
                });
              } else if (state is GetMinutesOfMeetingFormNoErrorState) {
                setState(() {
                  _isLoading = false;
                });
                print("GetMinutesOfMeetingFormNoErrorState........");
              }
            },
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 10, right: 10, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                        color: MyColors.lightgreyColorCode,
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 10,
                              color: MyColors.shadowGreyColorCode)
                        ]),
                    // width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text("From date",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () async {
                                  // Open date picker for from date
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (selectedDate != null) {
                                    setState(() {
                                      date1 = DateFormat('dd/MM/yyyy')
                                          .format(selectedDate);
                                    });
                                    // After selecting the date, fetch data
                                    getData();
                                  }
                                },
                                child: Text(
                                    date1), // Display selected date or today's date
                              ),
                            ],
                          ),
                        ),
                        Text("-"),
                        Expanded(
                          child: Column(
                            children: [
                              Text("To date",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () async {
                                  // Open date picker for to date
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (selectedDate != null) {
                                    setState(() {
                                      todate1 = DateFormat('dd/MM/yyyy')
                                          .format(selectedDate);
                                    });
                                    // After selecting the date, fetch data
                                    getData();
                                  }
                                },
                                child: Text(
                                    todate1), // Display selected date or today's date
                              ),
                            ],
                          ),
                        ),

                        // Text("10 NOTIFICATIONS",style: TextStyle(fontSize: 18),),
                        // Text("CLEAR ALL",style: TextStyle(decoration: TextDecoration.underline,color: MyColors.appDefaultColorCode,fontSize: 18),),
                      ],
                    ),
                  ),
                  visitList.isEmpty
                      ? Center(
                          child: Column(
                            // crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 100),
                              Image.asset(
                                "assets/icons/no_data.png",
                                // Ensure this image exists in your assets
                                height: 100,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No Data Available",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          margin: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            side:
                                BorderSide(width: 1, color: MyColors.lightBlue),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListView.builder(
                              controller: visitRecordController,
                              shrinkWrap: true,
                              itemCount: visitList.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                    onTap: () {},
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            width: 1,
                                            color: MyColors
                                                .textBoxBorderColorCode),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.only(
                                            top: 15,
                                            left: 14,
                                            right: 14,
                                            bottom: 15),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                    child: visitList[index]
                                                                    .status ==
                                                                "S" &&
                                                            formatter.parse("${visitList[index].selectDate} ${visitList[index].totime}").isBefore(
                                                                DateTime.now())
                                                        ? Icon(Icons.circle,
                                                            size: 10,
                                                            color: MyColors
                                                                .blueColorCode)
                                                        : visitList[index].status ==
                                                                "S"
                                                            ? Icon(Icons.circle,
                                                                size: 10,
                                                                color: MyColors
                                                                    .greenColorCode)
                                                            : visitList[index]
                                                                        .status ==
                                                                    "I"
                                                                ? Icon(Icons.circle,
                                                                    size: 10,
                                                                    color: MyColors
                                                                        .orangeColorCode)
                                                                : Icon(Icons.circle,
                                                                    size: 10,
                                                                    color: MyColors
                                                                        .orangeColorCode)),
                                                Expanded(
                                                  child: visitList[index]
                                                                  .status ==
                                                              "S" &&
                                                          formatter
                                                              .parse(
                                                                  "${visitList[index].selectDate} ${visitList[index].totime}")
                                                              .isBefore(DateTime
                                                                  .now())
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Text(
                                                            "Completed",
                                                            style: TextStyle(
                                                              color: MyColors
                                                                  .blueColorCode,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 18.0,
                                                            ),
                                                          ),
                                                        )
                                                      : visitList[index]
                                                                  .status ==
                                                              "S"
                                                          ? (isVisitRunning!
                                                              ? Text(
                                                                  "Started",
                                                                  style:
                                                                      TextStyle(
                                                                    color: MyColors
                                                                        .greenColorCode,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        18.0,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  "Stopped",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        18.0,
                                                                  ),
                                                                ))
                                                          // Text("Started",style: TextStyle(color: MyColors.greenColorCode,fontWeight: FontWeight.bold,fontSize: 18.0,),)
                                                          /// this will listen the state changes in visit start stop bool
                                                          /*   ValueListenableBuilder<bool>(
                                              valueListenable: VisitState.isVisitRunning,
                                              builder: (context, running, _) {
                                                return Text(
                                                  running ? "Started" : "Stopped",
                                                  style: TextStyle(
                                                    color: running ? MyColors.greenColorCode : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0,
                                                  ),
                                                );
                                              },
                                            )*/
                                                          : visitList[index]
                                                                      .status ==
                                                                  "I"
                                                              ? Text(
                                                                  "Not Started",
                                                                  style:
                                                                      TextStyle(
                                                                    color: MyColors
                                                                        .orangeColorCode,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        18.0,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  "",
                                                                  style:
                                                                      TextStyle(
                                                                    color: MyColors
                                                                        .orangeColorCode,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        18.0,
                                                                  ),
                                                                ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 15.0, bottom: 15),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Visit Destination",
                                                          style: TextStyle(
                                                              color: MyColors
                                                                  .textprofiledetailColorCode,
                                                              fontSize: 18),
                                                        ),
                                                        Text(
                                                          visitList[index]
                                                                      .source
                                                                      .toString() !=
                                                                  null
                                                              ? visitList[index]
                                                                      .source
                                                                      .toString() +
                                                                  " - " +
                                                                  visitList[
                                                                          index]
                                                                      .destination
                                                                      .toString()
                                                              : "NA",
                                                          style: TextStyle(
                                                              color: MyColors
                                                                  .text5ColorCode,
                                                              fontSize: 18),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Visit Date",
                                                        style: TextStyle(
                                                            color: MyColors
                                                                .textprofiledetailColorCode,
                                                            fontSize: 18),
                                                      ),
                                                      Text(
                                                        visitList[index]
                                                                    .selectDate !=
                                                                null
                                                            ? visitList[index]
                                                                .selectDate!
                                                            : "",
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: TextStyle(
                                                            color: MyColors
                                                                .text5ColorCode,
                                                            fontSize: 18),
                                                      ),
                                                    ],
                                                  )),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        visitList[index].status ==
                                                                    "C" ||
                                                                visitList[index]
                                                                        .status ==
                                                                    "S"
                                                            ? MaterialButton(
                                                                onPressed: () {
                                                                  String
                                                                      inputDate =
                                                                      visitList[
                                                                              index]
                                                                          .selectDate!;

                                                                  // Parse the input date into a DateTime object
                                                                  DateTime
                                                                      parsedDate =
                                                                      DateFormat(
                                                                              "dd/MM/yyyy")
                                                                          .parse(
                                                                              inputDate);

                                                                  // Format the date into the desired format "dd-MMM-yyyy"
                                                                  String
                                                                      formattedDate =
                                                                      DateFormat(
                                                                              "dd-MMM-yyyy")
                                                                          .format(
                                                                              parsedDate); //yyyy-MM-dd correct formate

                                                                  // Set values to prefilled in MOM screen
                                                                  visitDateMOM = visitList[
                                                                          index]
                                                                      .visitDate
                                                                      .toString();
                                                                  toTimeMOM = visitList[
                                                                          index]
                                                                      .totime
                                                                      .toString();
                                                                  vistNameMOM =
                                                                      visitList[
                                                                              index]
                                                                          .reason
                                                                          .toString();

                                                                  // mainBloc.add(VisitlatLongListEvents(StaffCode: staffCode!, ActualDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(), token: Auth_Token!));
                                                                  mainBloc.add(GetMinutesOfMeetingFormNoEvents(
                                                                      UserId:
                                                                          staffCode!,
                                                                      SrNo: visitList[
                                                                              index]
                                                                          .srNo!
                                                                          .toString(),
                                                                      token:
                                                                          Auth_Token!));
                                                                },
                                                                shape: const RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(10))),
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .only(
                                                                      left: 2.0,
                                                                      right: 8,
                                                                      top: 8,
                                                                      bottom:
                                                                          8),
                                                                  child: Text(
                                                                    "MOM ",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        color: MyColors
                                                                            .whiteColorCode),
                                                                  ),
                                                                ),
                                                                color: MyColors
                                                                    .fontBlue,
                                                              )
                                                            : SizedBox()
                                                      ],
                                                    ),
                                                    //   child: Column(
                                                    //     mainBloc.add(GetMinutesOfMeetingFormNoEvents(UserId: staffCode,SrNo: visitList[index].srNo!.toString(),token: Auth_Token!));
                                                    //
                                                    //   // mainBloc.add(GetVisitDetailedRecordsEvent( StaffCode: staffCode!, FromDate: formattedDate, ToDate: formattedDate,
                                                    //   //         SrNoVal: visitList[index].srNo!.toString(),token: Auth_Token!));
                                                    //
                                                    // ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(
                                                    child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "FromTime-ToTime",
                                                      style: TextStyle(
                                                          color: MyColors
                                                              .textprofiledetailColorCode,
                                                          fontSize: 18),
                                                    ),
                                                    Text(
                                                      visitList[index]
                                                                  .fromtime !=
                                                              null
                                                          ? visitList[index]
                                                                  .fromtime! +
                                                              " - " +
                                                              visitList[index]
                                                                  .totime!
                                                          : "",
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                          color: MyColors
                                                              .text5ColorCode,
                                                          fontSize: 18),
                                                    ),
                                                  ],
                                                )),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        "Visit Name",
                                                        style: TextStyle(
                                                            color: MyColors
                                                                .textprofiledetailColorCode,
                                                            fontSize: 18),
                                                      ),
                                                      Text(
                                                        visitList[index]
                                                                    .reason !=
                                                                null
                                                            ? visitList[index]
                                                                .reason!
                                                            : "",
                                                        style: TextStyle(
                                                            color: MyColors
                                                                .text5ColorCode,
                                                            fontSize: 18),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      visitList[index].status ==
                                                                  "C" ||
                                                              visitList[index]
                                                                      .status ==
                                                                  "S"
                                                          ? MaterialButton(
                                                              onPressed: () {
                                                                String
                                                                    inputDate =
                                                                    visitList[
                                                                            index]
                                                                        .selectDate!;

                                                                // Parse the input date into a DateTime object
                                                                DateTime
                                                                    parsedDate =
                                                                    DateFormat(
                                                                            "dd/MM/yyyy")
                                                                        .parse(
                                                                            inputDate);

                                                                // Format the date into the desired format "dd-MMM-yyyy"
                                                                String
                                                                    formattedDate =
                                                                    DateFormat(
                                                                            "dd-MMM-yyyy")
                                                                        .format(
                                                                            parsedDate); //yyyy-MM-dd correct formate

                                                                // mainBloc.add(VisitlatLongListEvents(StaffCode: staffCode!, ActualDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(), token: Auth_Token!));
                                                                mainBloc.add(GetVisitDetailedRecordsEvent(
                                                                    StaffCode:
                                                                        staffCode!,
                                                                    FromDate:
                                                                        formattedDate,
                                                                    ToDate:
                                                                        formattedDate,
                                                                    SrNoVal: visitList[
                                                                            index]
                                                                        .srNo!
                                                                        .toString(),
                                                                    token:
                                                                        Auth_Token!));
                                                              },
                                                              shape: const RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.all(
                                                                          Radius.circular(
                                                                              10))),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            2.0,
                                                                        right:
                                                                            8,
                                                                        top: 8,
                                                                        bottom:
                                                                            8),
                                                                child: Text(
                                                                  "Track   ",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                      color: MyColors
                                                                          .whiteColorCode),
                                                                ),
                                                              ),
                                                              color: MyColors
                                                                  .fontBlue,
                                                            )
                                                          : const SizedBox(),
                                                      ValueListenableBuilder<
                                                          int>(
                                                        valueListenable: VisitState
                                                            .countRemainingLatLong,
                                                        builder: (context,
                                                            count, _) {
                                                          return Text(
                                                            count > 0
                                                                ? "Unsetteled records $count"
                                                                : "",
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .black87,
                                                                fontSize: 12),
                                                          );
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ));
                              }),
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
                            enabled: true,
                            // to trigger disabledBorder
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
                            enabled: true,
                            // to trigger disabledBorder
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

        date = DateFormat('dd/MM/yyyy').format(selectedDate);

        print("fromDate---" + date);
        _fromdatecontroller.text = date;
        date1 = _fromdatecontroller.text;
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
        _todatecontroller.text = todate;
        print("toDate---" + todate);
        todate1 = _todatecontroller.text;
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
    } else if (selectedDate.day == selectedToDate.day && fromTime1 == toTime1) {
      Fluttertoast.showToast(
        msg:
            "Please Select From & To Time! FromTime And ToTime Should Not Be Same...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    } else {
      Navigator.pop(context);

      mainBloc.add(GetVisitByFromDateToDate(
          UserId: staffCode!,
          pageNumber: 1,
          pageSize: 50,
          fromDate: _fromdatecontroller.text,
          toDate: _todatecontroller.text,
          token: Auth_Token!));
    }
  }
}

//                /* Expanded(
//                           child: GestureDetector(
//                             onTap: () {
//                               _fromdatecontroller.text=date1;
//                               _fromTimecontroller.text=fromTime1;
//                               _todatecontroller.text=todate1;
//                               _toTimecontroller.text=toTime1;
//                               changeDatepopUp(context);
//                             },
//                             child: Container(
//                               alignment: Alignment.center,
//                               padding: EdgeInsets.only(
//                                   left: 15, right: 15, top: 10, bottom: 10),
//                               decoration: BoxDecoration(
//                                   color: MyColors.greyColorCode,
//                                   borderRadius:
//                                   BorderRadius.all(Radius.circular(20))),
//                               child: Text(
//                                 "Change",
//                                 style: TextStyle(
//                                     color: MyColors.text4ColorCode, fontSize: 18),
//                               ),
//                             ),
//                           ),
//       /*_fromdatecontroller.text = selectedDate.day.toString() +
//             "/" +
//             selectedDate.month.toString() +
//             "/" +
//             selectedDate.year.toString();*/
//         // date=selectedDate.year.toString()+"-"+selectedDate.month.toString()+"-"+selectedDate.day.toString();
//         //    date = Jiffy(selectedDate).format('d-MMMM-yyyy');
//         //  date = Jiffy.now().format('d-MMMM-yyyy');                     )*/

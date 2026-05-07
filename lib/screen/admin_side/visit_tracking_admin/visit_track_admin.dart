import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/admin_side/visit_tracking_admin/visit_track_report.dart';
import 'package:attendance_system_ios/screen/visit_management/visit_history/minutes_of_the_meeting_form.dart';
import 'package:attendance_system_ios/screen/visit_management/visit_history/visit_history_track.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../../model/UsersList/GetAllusersListResponse.dart';
import '../../../model/VisitHistory/VisitLatLongListResponse.dart';
import '../../../model/VisitReport/VisitRecordsResponse.dart';
import '../../../model/VisitReport/VisitDetailedRecordsResponse.dart' as visitlisttt;
import '../minutes_of_meeting_form_admin/minutes_of_meeting_form_admin.dart';


class AdminVisitTrackScreen extends StatefulWidget
{
  Message datum;
  AdminVisitTrackScreen(
      {
        Key? key,
        required this.datum,
      })
      : super(key: key);  @override
  State<AdminVisitTrackScreen> createState() => _AdminVisitTrackScreenState();
}

class _AdminVisitTrackScreenState extends State<AdminVisitTrackScreen>{
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staffCode = "";
  String? Auth_Token = "";
  late List<visitlisttt.Message> latLongList=[];
  //late List<LatLongList> latLongList=[];
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
  List<Data> visitList=[];
  ScrollController visitRecordController=new ScrollController();
  late Message data;
  String startAddress="";
  String stopAddress="";
  final formatter = DateFormat("dd/MM/yyyy hh:mm a");

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    //  data=widget.datum;
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
    data=widget.datum;
    getData();
  }
  Future<void> getData() async {
    staffCode = data.staffCode;
    // staffCode = "CD00490";

    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");
    mainBloc.add(GetVisitByFromDateToDate(UserId: staffCode!,
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
          title: const Text("Visit Track"),
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
              }
              else if (state is GetVisitByFromDateToDateLoadedState) {
                print("GetVisitByFromDateToDateLoadedState called...");
                setState(() {
                  _isLoading = false;
                  visitList.clear();
                });

                print("visitList Size....${visitList.length}");
                if(state.visitRecordsResponse!.data !=null) {
                  setState(() {
                    visitList.addAll(state.visitRecordsResponse!.data!);

                  });
                  print("visitList Size...........${visitList.length}");

                }else
                {
                  print("visitList Size....${visitList.length}");

                }

                if(visitList.length==0)
                {
                  Fluttertoast.showToast(
                    msg: "   Visit records Not Found...!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
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

              // if (state is VisitlatLongListLoadingState) {
              //   setState(() {
              //     _isLoading = true;
              //   });
              // }
              // else if (state is VisitlatLongListLoadedState)
              // {
              //   setState(() {
              //     _isLoading = false;
              //     latLongList.clear();
              //   });
              //   /*  Fluttertoast.showToast(
              //     msg: "   sucessss...!   ",
              //     toastLength: Toast.LENGTH_SHORT,
              //     timeInSecForIosWeb: 1,
              //   );*/
              //   latLongList.addAll(state.visitLatLongListResponse!.message!);
              //
              //   print("latLongList Size...."+latLongList!.length.toString());
              //   //
              //
              // }
              // else if (state is VisitlatLongListErrorState)
              // {
              //   setState(() {
              //     _isLoading = false;
              //   });
              //
              // }

              if (state is GetVisitDetailedRecordsLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              }
              else if (state is GetVisitDetailedRecordsLoadedState)
              {
                setState(() {
                  _isLoading = false;
                  latLongList.clear();
                });
                ///working(05-03)
                latLongList.addAll(state.visitDetailedRecordsResponse!.message!);


                // latLongList.addAll(visitlisttt.Message.fromJson);
                // latLongList.addAll(state.visitLatLongListResponse!.message as List<visitlisttt.Message>);
// latLongList = (responseData['message'] as List)
//                .map((item) => visitValues.Message.fromJson(item))
//                .toList();
//            print("latLong list of opened track visit: $latLongList");
                print("latLong list of opened track visit: $latLongList");
                if (latLongList.isEmpty){
                  Fluttertoast.showToast(msg: 'Expired!! Visit not started.');
                  return;
                }
                // latLongList.addAll(state.visitLatLongListResponse!.message!);
                //latLongList.addAll();

                print("latLongList Size...."+latLongList!.length.toString());
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(
                                  webService:
                                  WebService());
                            },
                            child:
                            VisitHistoryTrackScreen(latLongList: latLongList,)
                        )));
                if(state.visitDetailedRecordsResponse!.message! =="message:Record Not Found..." ){
                  Fluttertoast.showToast(msg: "no data to track");
                }
              }
              /*setState(() {
                    _isLoading = false;
                    latLongList.clear();
                  });

                  var responseMessage = state.visitDetailedRecordsResponse?.message;

                  if (responseMessage == null) {
                    Fluttertoast.showToast(msg: "No response from server.");
                    return;
                  }
                  if (responseMessage is Map<String, dynamic>) {
                    var messageText = responseMessage["message"]; // Extract the message
                    if (messageText is String && messageText == "Record Not Found..." as String) {
                      Fluttertoast.showToast(msg: "No data to track");
                      return;
                    }
                  }
                  if (responseMessage is List) {
                    latLongList.addAll(responseMessage
                        .map((item) => visitlisttt.Message.fromJson(item as Map<String, dynamic>))
                        .toList());
                  }
                  print("latLong list of opened track visit: $latLongList");

                  if (latLongList.isEmpty) {
                    Fluttertoast.showToast(msg: 'Expired!! Visit not started.');
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BlocProvider(
                              create: (context) => MainBloc(webService: WebService()),
                              child: VisitHistoryTrackScreen(latLongList: latLongList)
                          )));
*/

              else if (state is GetVisitDetailedRecordsErrorState)
              {
                setState(() {
                  _isLoading = false;
                });
              }

              if (state is GetMinutesOfMeetingFormNoLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              }
              else if (state is GetMinutesOfMeetingFormNoLoadedState)
              // {
              //   setState(() {
              //     _isLoading = false;
              //   });
              //   print("GetMinutesOfMeetingFormNoLoadedState.........");
              //   //   int formVal=state.getMinutesOfMeetingFormNoResponse.message!.srNo;
              //   // print("GetMinutesOfMeetingFormNoLoadedState........."+formVal.toString());
              //
              //   if(state.getMinutesOfMeetingFormNoResponse.message!.srNo ==null ||
              //       state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo ==null
              //   )
              //   {
              //     Fluttertoast.showToast(
              //       msg: "   Minutes of the Meeting form was not filled out for this visit...!   ",
              //       toastLength: Toast.LENGTH_SHORT,
              //       timeInSecForIosWeb: 1,
              //     );
              //
              //     print("not Filled yet...");
              //
              //   }
              //   else
              //   {
              //     print("Form is Filled ..");
              //
              //
              //     Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(
              //             builder: (_) => BlocProvider(
              //                 create: (context) {
              //                   return MainBloc(
              //                       webService: WebService());
              //                 },
              //                 child: AdminSideMinutesOfTheMeetingFormScreen(SrNo: state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),staffCode: state.getMinutesOfMeetingFormNoResponse.message!.userId.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString()))));
              //   }
              // }
              // {
              //   setState(() {
              //     _isLoading = false;
              //   });
              //   print("GetMinutesOfMeetingFormNoLoadedState.........");
              //   //   int formVal=state.getMinutesOfMeetingFormNoResponse.message!.srNo;
              //   // print("GetMinutesOfMeetingFormNoLoadedState........."+formVal.toString());
              //
              //   if(state.getMinutesOfMeetingFormNoResponse.message!.srNo ==null ||
              //       state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo ==null
              //   )
              //   {
              //     Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(
              //             builder: (_) => BlocProvider(
              //                 create: (context) {
              //                   return MainBloc(
              //                       webService: WebService());
              //                 },
              //                 child: MinutesOfTheMeetingFormScreen(visitSrNo:  state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString(),))));
              //
              //     print("not Filled yet...");
              //
              //   }
              //   else
              //   {
              //     print("Form is Filled ..");
              //
              //     Fluttertoast.showToast(
              //       msg: "   Minutes of the Meeting form has already been filled out for this visit...!   ",
              //       toastLength: Toast.LENGTH_SHORT,
              //       timeInSecForIosWeb: 1,
              //     );
              //     Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(
              //             builder: (_) => BlocProvider(
              //                 create: (context) {
              //                   return MainBloc(
              //                       webService: WebService());
              //                 },
              //                 //child: MinutesOfTheMeetingFormScreen(visitSrNo: state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString(),))));
              //                          child: AdminSideMinutesOfTheMeetingFormScreen(SrNo: state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),staffCode: state.getMinutesOfMeetingFormNoResponse.message!.userId.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString()))));
              //
              //         }
              //
              // }



              //                 child: MinutesOfTheMeetingFormScreen(visitSrNo:  state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString(),))));

                  {
                setState(() {
                  _isLoading = false;
                });
                print("GetMinutesOfMeetingFormNoLoadedState.........");
                //   int formVal=state.getMinutesOfMeetingFormNoResponse.message!.srNo;
                // print("GetMinutesOfMeetingFormNoLoadedState........."+formVal.toString());

                if(state.getMinutesOfMeetingFormNoResponse.message!.srNo ==null ||
                    state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo ==null
                )
                {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BlocProvider(
                              create: (context) {
                                return MainBloc(
                                    webService: WebService());
                              },
                              //child: MinutesOfTheMeetingFormScreen(visitSrNo:  state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString(),))));
                              child: AdminSideMinutesOfTheMeetingFormScreen(SrNo: state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),staffCode: state.getMinutesOfMeetingFormNoResponse.message!.userId.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString()))));

                  print("not Filled yet...");

                }
                // else
                // {
                //   print("Form is Filled ..");
                //
                //   Fluttertoast.showToast(
                //     msg: "   Minutes of the Meeting form has already been filled out for this visit...!   ",
                //     toastLength: Toast.LENGTH_SHORT,
                //     timeInSecForIosWeb: 1,
                //   );
                //   Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(
                //           builder: (_) => BlocProvider(
                //               create: (context) {
                //                 return MainBloc(
                //                     webService: WebService());
                //               },
                //               child: MinutesOfTheMeetingFormScreen(visitSrNo: state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString(),minuteforno: state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString(),))));
                // }

              }
              else if (state is GetMinutesOfMeetingFormNoErrorState)
              {
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
                                    Padding(
                                      padding: const EdgeInsets.only(top: 15.0,bottom: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Container(
                                              child:
                                              visitList[index].status=="S" && formatter.parse("${visitList[index].selectDate} ${visitList[index].totime}").isBefore(DateTime.now()) ?
                                              Icon(Icons.circle,size:10,color: MyColors.blueColorCode):
                                              visitList[index].status=="S"?
                                              Icon(Icons.circle,size:10,color: MyColors.greenColorCode)
                                                  :
                                              visitList[index].status=="I"?

                                              Icon(Icons.circle,size:10,color: MyColors.orangeColorCode)

                                                  :
                                              Icon(Icons.circle,size:10,color: MyColors.orangeColorCode)

                                          ),
                                          Expanded(
                                              child: visitList[index].status=="S" && formatter.parse("${visitList[index].selectDate} ${visitList[index].totime}").isBefore(DateTime.now()) ?
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: Text("Completed",style: TextStyle(color: MyColors.blueColorCode,fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,),
                                                ),
                                              ):
                                              visitList[index].status=="S"?
                                              Text("Started",style: TextStyle(color: MyColors.greenColorCode,fontWeight: FontWeight.bold,
                                                fontSize: 18.0,),)
                                                  :visitList[index].status=="P"
                                                  ? Text("Pending",style: TextStyle(color: MyColors.blueColorCode,fontWeight: FontWeight.bold,
                                                fontSize: 18.0,),):
                                              visitList[index].status=="I"?
                                              Text("Not Started",style: TextStyle(color: MyColors.redColorCode,fontWeight: FontWeight.bold,
                                                fontSize: 18.0,),):
                                              Text("",style: TextStyle(color: MyColors.greenColorCode,fontWeight: FontWeight.bold,
                                                fontSize: 18.0,),)
                                          ),
                                          Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children:
                                                [
                                                  GestureDetector(
                                                    onTap: (){
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
                                                    child:
                                                    Container(
                                                      height: 32,

                                                      margin:
                                                      EdgeInsets.only(top: 7,left: 20),
                                                      padding: const EdgeInsets.only(
                                                          left: 11,
                                                          right: 11,
                                                          top: 3,
                                                          bottom: 3),
                                                      decoration: const BoxDecoration(
                                                          color: MyColors
                                                              .blueColorCode,
                                                          borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  10))),
                                                        child: const FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            "Details", // or "Track", "MeetingData"
                                                            style: TextStyle(
                                                              color: MyColors.whiteColorCode,
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ),
                                                  )

                                                ],

                                              )
                                          ),
                                          Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children:
                                                [
                                                  GestureDetector(
                                                    onTap: (){
                                                      String inputDate = visitList[index].selectDate!;

                                                      // Parse the input date into a DateTime object
                                                      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(inputDate);

                                                      // Format the date into the desired format "dd-MMM-yyyy"
                                                      String formattedDate = DateFormat("dd-MMM-yyyy").format(parsedDate);

                                                      //  mainBloc.add(VisitlatLongListEvents(StaffCode: staffCode!, ActualDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(), token: Auth_Token!));
                                                      mainBloc.add(GetVisitDetailedRecordsEvent( StaffCode: staffCode!, FromDate: formattedDate, ToDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(),token: Auth_Token!));
                                                      print("Track button clicked: StaffCode: $staffCode, SrNo: ${visitList[index].srNo}");

                                                    },
                                                    child: Container(
                                                      height: 32,
                                                      margin: EdgeInsets.only(top: 7,left: 20),
                                                      padding: const EdgeInsets.only(
                                                          left: 14,
                                                          right: 14,
                                                          top: 5,
                                                          bottom: 5),
                                                      decoration: const BoxDecoration(
                                                          color: MyColors
                                                              .blueColorCode,
                                                          borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  10))),
                                                        child: const FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            "Track", // or "Track", "MeetingData"
                                                            style: TextStyle(
                                                              color: MyColors.whiteColorCode,
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ),
                                                  )


                                                ],
                                              )
                                          ),
                                          Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children:
                                                [
                                                  GestureDetector(
                                                    onTap: (){
                                                      String inputDate = visitList[index].selectDate!;

                                                      // Parse the input date into a DateTime object
                                                      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(inputDate);

                                                      // Format the date into the desired format "dd-MMM-yyyy"
                                                      String formattedDate = DateFormat("dd-MMM-yyyy").format(parsedDate);

                                                      //  mainBloc.add(VisitlatLongListEvents(StaffCode: staffCode!, ActualDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(), token: Auth_Token!));
                                                      //mainBloc.add(GetVisitDetailedRecordsEvent( StaffCode: staffCode!, FromDate: formattedDate, ToDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(),token: Auth_Token!));
                                                      mainBloc.add(GetMinutesOfMeetingFormNoEvents(UserId: staffCode!, SrNo: visitList[index].srNo.toString(), token: Auth_Token!));
                                                      print("MOM button clicked: StaffCode: $staffCode, SrNo: ${visitList[index].srNo}");

                                                    },
                                                    child: Container(
                                                      height: 32,
                                                      margin: EdgeInsets.only(top: 7, left: 20),
                                                      padding: const EdgeInsets.only(
                                                          left: 14,
                                                          right: 14,
                                                          top: 5,
                                                          bottom: 5),                                                      decoration: BoxDecoration(
                                                        color: MyColors.blueColorCode,
                                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                                      ),
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          "MOM", // or "Track", "MeetingData"
                                                          style: TextStyle(
                                                            color: MyColors.whiteColorCode,
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                  )
                                                ],
                                              )
                                          )

                                        ],
                                      ),
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
                                                Text("Source - Destination ",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                                Text(visitList[index].source.toString()!=null ? visitList[index].source.toString() +"-"+visitList[index].destination.toString()! : "NA",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
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
                                          ),
                                          /* Expanded(
                                            child:
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                visitList[index].status=="C" ||visitList[index].status=="S"?
                                                MaterialButton(
                                                  onPressed: () {
                                                  },
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.all(Radius.circular(10))),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(
                                                        left: 2.0, right: 8, top: 8, bottom: 8),
                                                    child: Text(
                                                      "Show Details",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color: MyColors.whiteColorCode),
                                                    ),
                                                  ),
                                                  color: MyColors.fontBlue,
                                                ):
                                                SizedBox()
                                              ],),)*/
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
                                              Text("Visit Name",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                              Text(visitList[index].reason!=null ? visitList[index].reason! : "",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                            ],
                                          ),
                                        ),
                                        /*  Expanded(
                                          child:
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              visitList[index].status=="C" ||visitList[index].status=="S"?
                                              MaterialButton(
                                                onPressed: () {
                                                  String inputDate = visitList[index].selectDate!;

                                                  // Parse the input date into a DateTime object
                                                  DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(inputDate);

                                                  // Format the date into the desired format "dd-MMM-yyyy"
                                                  String formattedDate = DateFormat("dd-MMM-yyyy").format(parsedDate);

                                                  mainBloc.add(VisitlatLongListEvents(StaffCode: staffCode!, ActualDate: formattedDate, SrNoVal: visitList[index].srNo!.toString(), token: Auth_Token!));

                                                },
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.all(Radius.circular(10))),
                                                child: Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 2.0, right: 8, top: 8, bottom: 8),
                                                  child: Text(
                                                    "Track",
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        color: MyColors.whiteColorCode),
                                                  ),
                                                ),
                                                color: MyColors.fontBlue,
                                              ):
                                              SizedBox()
                                            ],),)*/
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
                            readOnly: true,
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
                            readOnly: true,
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
        "Invalid Date Selection.",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      Fluttertoast.showToast(
        msg:
        "Please verify the fromdate and to date before Applying",
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
      mainBloc.add(GetVisitByFromDateToDate(UserId: staffCode!,
          pageNumber: 1,
          pageSize: 50,
          fromDate: _fromdatecontroller.text,
          toDate: _todatecontroller.text,
          token: Auth_Token!));
    }
  }
  showDetailsDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0), // Rounded corners
            ),
            child:
            Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.6, // Adjust height dynamically
              width: MediaQuery
                  .of(context)
                  .size
                  .width - 10,
              child:
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: SingleChildScrollView( // Add scrolling capability
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                          child:
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Visit Date   : " +
                                          visitList[index].selectDate!,
                                        style: TextStyle(color: MyColors
                                            .blackColorCode,
                                            fontSize: 18),),

                                    ],
                                  ),
                                ),
                              ])),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [ Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Visit Name   : " + visitList[index].source! +
                                        " - " + visitList[index].destination!,
                                    style: TextStyle(color: MyColors
                                        .blackColorCode,
                                        fontSize: 18),
                                  ),

                                ],
                              ),
                            ),
                            ]
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("From Time : " +
                                          visitList[index].fromtime.toString(),
                                        style: TextStyle(color: MyColors
                                            .blackColorCode,
                                            fontSize: 18
                                        ),
                                      ),
                                    ],
                                  )
                              ),
                            ]
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("To Time : " +
                                          visitList[index].totime.toString(),
                                        style: TextStyle(color: MyColors
                                            .blackColorCode,
                                            fontSize: 18),),
                                    ],
                                  )
                              ),
                            ]
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Reason : " +
                                          visitList[index].reason.toString(),
                                        style: TextStyle(color: MyColors
                                            .blackColorCode,
                                            fontSize: 18),),
                                    ],
                                  )
                              ),
                            ]
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Start Address : " +
                                          startAddress,
                                        style: TextStyle(color: MyColors
                                            .blackColorCode,
                                            fontSize: 18),),
                                    ],
                                  )
                              ),
                            ]
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15,left:10),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Stop Address : " +
                                          stopAddress,
                                        style: TextStyle(color: MyColors
                                            .blackColorCode,
                                            fontSize: 18),),
                                    ],
                                  )
                              ),
                            ]
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15),
                        child:
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [

                                      GestureDetector(child:   Text(" Show Minutes Of The Meeting Form",
                                        style: TextStyle(
                                          color: MyColors.blueColorCode,
                                          decoration: TextDecoration.underline,
                                          fontSize: 20,
                                          decorationColor: MyColors.blueColorCode,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                        onTap: (){
                                          mainBloc.add(GetMinutesOfMeetingFormNoEvents(UserId: staffCode!,SrNo: visitList[index].srNo!.toString(),token: Auth_Token!));

                                        },
                                      )


                                    ],
                                  )
                              ),
                            ]
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }


  Future<void> _getAddressFromLatLong(double latitude, double longitude) async {


    try {
      // Fetch the list of places from the latitude and longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          startAddress = '${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

        });
        // Construct the address string
      } else {
        startAddress = "No address found!";
      }
    } catch (e) {
      // startAddress = "Error: $e"; // In case of an error, return the error message as a string
    }

    //  return address; // Always return a non-null string
  }
  Future<void> _getStopAddressFromLatLong(double latitude, double longitude,int index) async {


    try {
      // Fetch the list of places from the latitude and longitude
      // Fetch the list of places from the latitude and longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Construct the address string
        setState(() {
          stopAddress = '${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';

        });
        showDetailsDialog(context, index);


      } else {

        stopAddress = "No address found!";
        showDetailsDialog(context, index);

      }

    } catch (e) {
      showDetailsDialog(context, index);

      // stopAddress = "Error: $e"; // In case of an error, return the error message as a string
    }

    //  return address; // Always return a non-null string
  }


}





/*"srNo":2119,"userId":"cd00490",
"selectDate":"21/09/2024",
"fromtime":"19:22","totime":"21:22",
"reason":"check","destination":"bbb","latitude":null,
"longitude":null,"startingLat":"18.5834911","startingLong":"73.7354488",
"status":"C","stopLat":"18.5866768","stopLon":"73.8175632","source":"aaa",
"visitDate":"2024-09-21T13:01:01","mettingMom":null,"minutesofMeetFormNo":null*/
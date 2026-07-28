import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:attendance_system_ios/util/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'dart:math';

import '../../../model/VisitReport/VisitDetailedRecordsResponse.dart';
import '../../../model/VisitReport/VisitRecordsResponse.dart';

/*

class VisitReportDetailedScreen extends StatefulWidget {
  String visitsrNo;
  String? selectdate;
  Data record;
  String? StaffCode;

  VisitReportDetailedScreen({
    Key? key,
    required StaffCode,
    required this.visitsrNo,
    required this.selectdate,
    required this.record,
  }) : super(key: key);

  @override
  State<VisitReportDetailedScreen> createState() =>
      _VisitReportDetailedScreenState();
}

class _VisitReportDetailedScreenState extends State<VisitReportDetailedScreen> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;

  final controller = ScrollController();

  late String visitDate;
  DateTime currentdate = DateTime.now();

  DateTime selectedDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TimeOfDay selectedToTime = TimeOfDay.now();
  late String srNo, selectDate;

  List<Message> allRecords = [];
  List<Message> validListt = [];
  List<Message> validList = [];

  ScrollController visitRecordController = new ScrollController();
  late Data selectedRecord;

  double distanceee = 0.0;

  List<LatLng> coordinates = [];
  List<List<double>> coordinatesList = [];
  static int EARTH_RADIUS_METERS = 6371000;

  double totalDistanceee = 0.0;

  String formattedDistance = "";

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    srNo = widget.visitsrNo;
    selectDate = widget.selectdate!;
    selectedRecord = widget.record!;

    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");
    print("srNo-->$srNo");
    print("selectDate-->$selectDate");
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(selectDate);

    // Format the parsed date into 'yyyy-MM-dd' format
    visitDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    mainBloc.add(GetVisitDetailedRecordsEvent(
        StaffCode: selectedRecord.userId!,
        FromDate: visitDate,
        ToDate: visitDate,
        SrNoVal: srNo,
        token: Auth_Token!));
  }

  // double skipRecords(List<List<double>> coordinates) {
  //   double totalDistance = 0.0;
  //   double distance = 0.0;
  //   int val = 0;
  //
  //   // Iterate through the list of coordinates
  //   for (int i = 0; i < coordinates.length - 1; i++) {
  //     if (val == coordinates.length - 1) {
  //       // If val reaches the last coordinate, break the loop
  //       print(
  //           "Skip records: val and list size are the same: $val , ${coordinates.length}");
  //       break;
  //     }
  //
  //     print("Skip records: i ---> $i");
  //     print("Skip records: val ---> $val");
  //     if (i == coordinates.length - 1) {
  //       print("Skip records: i==coordinates.length - 1 true---> ");
  //       break;
  //     }
  //
  //     for (int j = i + 1; j < coordinates.length; j++) {
  //       print("Skip records: inside i ---> $i");
  //       print("Skip records: j ---> $j");
  //
  //       List<double> start = coordinates[i];
  //       List<double> end = coordinates[j];
  //
  //       // Extract latitude and longitude for start and end points
  //       double startLat = start[0];
  //       double startLong = start[1];
  //       double endLat = end[0];
  //       double endLong = end[1];
  //       print("Skip records: startLat,startLong: $startLat,$startLong");
  //       print("Skip records: endLat,endLong: $endLat,$endLong");
  //
  //       distance = calculateDistance(startLat, startLong, endLat, endLong);
  //       print("Skip records: distance: $distance");
  //
  //       if (distance >= 200) {
  //         i = j - 1; // Update val to the index of the valid point
  //         print("Skip records: Valid distance found, updating val to: $i");
  //
  //         totalDistance += distance;
  //         print("Skip records: Total distance: $totalDistance");
  //
  //         break; // Exit inner loop after finding a valid distance
  //       }
  //       if (j == coordinates.length - 1) {
  //         i = j;
  //       }
  //     }
  //   }
  //
  //   // Return the total distance traveled
  //   return totalDistance;
  // }



  // double skipRecords(List<List<double>> coordinates) {
  //   double totalDistance = 0.0;
  //
  //   for (int i = 0; i < coordinates.length - 1; i++) {
  //     List<double> start = coordinates[i];
  //     List<double> end = coordinates[i + 1];
  //
  //     double startLat = start[0];
  //     double startLong = start[1];
  //     double endLat = end[0];
  //     double endLong = end[1];
  //
  //     double distance = calculateDistance(startLat, startLong, endLat, endLong);
  //     totalDistance += distance;
  //
  //     print(
  //         "From [$startLat, $startLong] to [$endLat, $endLong] = $distance meters");
  //     print("Running total: $totalDistance meters");
  //   }
  //
  //   return totalDistance;
  // }

  double skipRecords(List<List<double>> coordinates){
    double totalDistance = 0.0;
    double distance =0.0;
    int val = 0;
    for(int i = 0; i< validList.length; i++){
      double distance = double.tryParse(validList[i].distance!) ?? 0.0;
      totalDistanceee +=  distance;
    }
    formattedDistance = (totalDistanceee/1000).toStringAsFixed(2);
    print("corrected total distance :$formattedDistance KM");

    for(int i = 0; i<coordinates.length -1; i++){
      if(val == coordinates.length -1){
        print("skip records $val, ${coordinates.length}");
        break;
      }
      print("skip record $i");
      print("skip records $val");

      if(i == coordinates.length -1){
        break;
      }

      for(int j = i+1; j<coordinates.length; j++){
        print("skip records i $i");
        print("skip records j $j");

        List<double> start = coordinates[i];
        List<double> end = coordinates[j];

        double startlat = start[0];
        double startlong = start[1];
        double endlat = end[0];
        double endlong = end[1];

        print("skip start records $startlat, $startlong");
        print("skip end records $endlat, $endlong");

        distance = calculateDistance(startlat, startlong, endlat, endlong);
        print("skip disance calculate $distance");

        if(distance >=10){
          i= j - 1;
          print("skip records updating val to i $i");
          totalDistance += distance;
          print("skip records totaldiatnce $totalDistance");
          break;
        }
        if( j == coordinates.length -1){
          i = j;
        }
      }
    }
    return totalDistance;

  }

  double calculateDistance(
      double startLat, double startLong, double endLat, double endLong) {
    // Convert latitude and longitude from degrees to radians
    double startLatRad = startLat * (3.141592653589793 / 180);
    double startLongRad = startLong * (3.141592653589793 / 180);
    double endLatRad = endLat * (3.141592653589793 / 180);
    double endLongRad = endLong * (3.141592653589793 / 180);

    // Compute the differences between coordinates
    double latDiff = endLatRad - startLatRad;
    double longDiff = endLongRad - startLongRad;

    // Compute the distance using Haversine formula
    double a = (sin(latDiff / 2) * sin(latDiff / 2)) +
        (cos(startLatRad) *
            cos(endLatRad) *
            (sin(longDiff / 2) * sin(longDiff / 2)));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Return the distance in meters
    return EARTH_RADIUS_METERS * c;
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
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pop(context); // Go back to the previous screen
              },
            ),
          ],
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
                if (state is GetVisitDetailedRecordsLoadingState) {
                  setState(() {
                    _isLoading = true;
                  });
                } else if (state is GetVisitDetailedRecordsLoadedState) {
                  setState(() {
                    _isLoading = false;
                    allRecords.clear();
                    validList.clear();
                    validListt.clear();
                  });
                  Fluttertoast.showToast(
                    msg: "   Success!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                  print("allRecords Size....${allRecords.length}");
                  if (state.visitDetailedRecordsResponse!.message != null) {
                    setState(() {
                      allRecords.addAll(state.visitDetailedRecordsResponse!.message!);
                    });
                    validListt = allRecords.where((latLong) =>
                    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();
                    List<Message> validList2 = [];

                    validList = validListt.reversed.toList();

                    for (int i = 0; i < allRecords.length; i++) {

                      if (allRecords[i].latitude == "0.0") {
                        print("Skipped .........${i}");
                      } else {
                        validList2.add(allRecords[i]);
                      }
                    }

                    print("allRecords Size...........${allRecords.length}");
                    print("validList Size...........${validList.length}");
                    print("validList2 Size...........${validList2.length}");

                    for (int i = 0; i < validList.length; i++) {
                      double distance = double.parse(validList[i].distance!);
                      distanceee = distanceee + distance;
                      String lat = validList[i].latitude!;
                      String long = validList[i].longitude!;

                      LatLng lat1 =
                      LatLng(double.parse(lat), double.parse(long));
                      coordinates.add(lat1);
                      coordinatesList
                          .add([double.parse(lat), double.parse(lat)]);
                    }

                    totalDistanceee = skipRecords(coordinatesList);

                    formattedDistance = (totalDistanceee / 1000).toStringAsFixed(2);

                    print("distanceee....${distanceee}");
                    print("formattedDistance....${formattedDistance}");

                    print("totalDistanceee....${totalDistanceee}");
                  } else {
                    print("allRecords Size....${allRecords.length}");
                  }
                  double finalDistance = 0;
                  List<double> speedList = [];
                  List<String> distanceList = [];
                  speedList.add(0.0);
                  distanceList.add("0.0");
                  for (int i = 0; i < validList.length; i++) {
                    for (int j = i + 1; j < validList.length; j++) {
                      String prevLat = validList[i].latitude!;
                      String prevLong = validList[i].longitude!;

                      String currentLat = validList[j].latitude!;
                      String currentLong = validList[j].longitude!;

                      double dis = calculateDistance(
                          double.parse(prevLat),
                          double.parse(prevLong),
                          double.parse(currentLat),
                          double.parse(currentLong));
                      print("Taghhhh: dis--->$dis");

                      double exDistanceKm = dis / 1000;
                      print("Taghhhh: ExDistancekm--->$exDistanceKm");
                      setState(() {
                        distanceList.add(exDistanceKm.toStringAsFixed(2));
                      });

                      try {
                        DateTime time1 =
                        parseTimestamp(validList[i].transactionTime!);
                        DateTime time2 =
                        parseTimestamp(validList[j].transactionTime!);
                        int timeElapsedMillis = time2.millisecondsSinceEpoch - time1.millisecondsSinceEpoch;

                        print("Taghhhh: timeElapsedMillis--->$timeElapsedMillis");

                        //double speed = calculateSpeed(dis, timeElapsedMillis);

                       // speedList.add((speed).roundToDouble());

                        //print("Taghhhh: speed--->$speed");
                      } catch (e) {
                        print("Taghhh: Exception-->${e.toString()}");
                      }

                      finalDistance += dis;

                      print("Taghhhh: finalDistance-->$finalDistance");

                      break;
                    }
                  }
                  print("Taghhhh: speedList size---${speedList.length}");
                  try {
                    if (validList.length == speedList.length) {
                      for (int i = 0; i < validList.length; i++) {
                        validList[i].speed = speedList[i].toString();
                        validList[i].distance = distanceList[i];
                        print("Taghhhh: speed values---${validList[i].speed}");
                      }
                    } else {
                      for (int i = 0; i < validList.length; i++) {
                        validList[i].speed = speedList[i].toString();
                        validList[i].distance = distanceList[i];
                      }
                    }
                  } catch (e) {
                    print("Taghhh: Exception Herere-->${e.toString()}");
                  }
                } else if (state is GetVisitDetailedRecordsErrorState) {
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
                  scrollDirection: Axis.vertical,
                  child: Column(children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 2, color: MyColors.lightBlue),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      //  color: MyColors.lighterRedColorCode,
                      child: Container(
                        padding: EdgeInsets.only(
                            top: 15, left: 14, right: 14, bottom: 15),
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
                              children: [],
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 15.0, bottom: 15),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Visit Date",
                                            style: TextStyle(
                                                color: MyColors
                                                    .textprofiledetailColorCode,
                                                fontSize: 18),
                                          ),
                                          Text(
                                            selectedRecord.selectDate != null
                                                ? selectedRecord.selectDate!
                                                : "",
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color: MyColors.text5ColorCode,
                                                fontSize: 18),
                                          ),
                                        ],
                                      )),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Source - Destination ",
                                          style: TextStyle(
                                              color: MyColors
                                                  .textprofiledetailColorCode,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          selectedRecord.source.toString() !=
                                              null
                                              ? selectedRecord.source
                                              .toString() +
                                              " - " +
                                              selectedRecord.destination
                                                  .toString()
                                              : "NA",
                                          style: TextStyle(
                                              color: MyColors.text5ColorCode,
                                              fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                        Text(
                                          "FromTime-ToTime",
                                          style: TextStyle(
                                              color: MyColors
                                                  .textprofiledetailColorCode,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          selectedRecord.fromtime != null
                                              ? selectedRecord.fromtime! +
                                              " - " +
                                              selectedRecord.totime!
                                              : "",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              color: MyColors.text5ColorCode,
                                              fontSize: 18),
                                        ),
                                      ],
                                    )),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Reason",
                                        style: TextStyle(
                                            color: MyColors
                                                .textprofiledetailColorCode,
                                            fontSize: 18),
                                      ),
                                      Text(
                                        selectedRecord.reason != null
                                            ? selectedRecord.reason!
                                            : "",
                                        style: TextStyle(
                                            color: MyColors.text5ColorCode,
                                            fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 15.0, bottom: 15),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Distance Traveled : " +
                                                formattedDistance +
                                                " KM ",
                                            style: TextStyle(
                                                color: MyColors.blueColorCode,
                                                fontSize: 21,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 15, left: 14, right: 14, bottom: 15),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            border: TableBorder.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            columnWidths: {
                              0: FixedColumnWidth(160),  // Date
                              1: FixedColumnWidth(120),  // Speed
                              2: FixedColumnWidth(180),  // Distance
                              3: FixedColumnWidth(200),  // Latitude
                              4: FixedColumnWidth(200),  // Longitude
                              5: FixedColumnWidth(500),  // Address
                              6: FixedColumnWidth(120),  // 🔋 Battery %
                            },
                            children: [
                              // Table header row
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey[300]),
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Date",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Speed In m/s",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Distance In Km",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Latitude",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Longitude",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Address",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Battery %",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),

                              // Data rows
                              for (var i = 0; i < validList.length; i++)
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: i.isEven ? Colors.white : Colors.grey[100],
                                  ),
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          validList[i].transactionTime
                                              .toString()
                                              .replaceAll("T", " "),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          validList[i].speed.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          double.parse(validList[i].distanceInkmMeter ?? "0.0")
                                              .toStringAsFixed(3),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          validList[i].latitude.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          validList[i].longitude.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(18.0),
                                        child: Text(
                                          validList[i].address.toString(),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          validList[i].batteryPercentage != null && validList[i].batteryPercentage!.isNotEmpty
                                              ? "${validList[i].batteryPercentage}%"
                                              : "",
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ]))),
        ),
      ),
    );
  }

  DateTime parseTimestamp(String timestamp) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    // Replace the 'T' with a space to match the format
    String formattedTimestamp = timestamp.replaceAll('T', ' ');
    return formatter.parse(formattedTimestamp);
  }

  double calculateSpeed(double distance, int timeElapsedMillis) {
    // Convert time to seconds
    double timeElapsedSeconds = timeElapsedMillis / 1000.0;
    print("timeElapsedSeconds--->$timeElapsedSeconds");
    // Calculate speed (meters per second)
    if (timeElapsedSeconds > 0) {
      print("calculateSpeed IFF Block--->");
      return distance / timeElapsedSeconds;
    } else {
      print("calculateSpeed Else Block--->");
      return 0.0;
    }
  }
}

*/


class VisitReportDetailedScreen extends StatefulWidget {

  String visitsrNo;
  String? selectdate;
  Data record;
  String? StaffCode;
  VisitReportDetailedScreen(
      {
        Key? key,
        required StaffCode,
        required this.visitsrNo,
        required this.selectdate,
        required this.record,

      })
      : super(key: key);

  @override
  State<VisitReportDetailedScreen> createState() => _VisitReportDetailedScreenState();
}

class _VisitReportDetailedScreenState extends State<VisitReportDetailedScreen> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;

  final controller = ScrollController();

  late String visitDate;
  DateTime currentdate = DateTime.now();

  DateTime selectedDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TimeOfDay selectedToTime = TimeOfDay.now();
  late String srNo,selectDate;

  List<Message> allRecords=[];
  List<Message> validListt=[];
  List<Message> validList=[];

  ScrollController visitRecordController=new ScrollController();
  late Data selectedRecord;

  double distanceee=0.0;

  List<LatLng> coordinates = [];
  List<List<double>> coordinatesList = [];
  static  int EARTH_RADIUS_METERS = 6371000;

  double totalDistanceee=0.0;

  String formattedDistance="";
  @override
  void initState()
  {
    mainBloc = BlocProvider.of<MainBloc>(context);
    srNo=widget.visitsrNo;
    selectDate=widget.selectdate!;
    selectedRecord=widget.record!;
    getData();
  }
  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");
    print("srNo-->$srNo");
    print("selectDate-->$selectDate");
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(selectDate);

    // Format the parsed date into 'yyyy-MM-dd' format
    visitDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    mainBloc.add(GetVisitDetailedRecordsEvent(
        StaffCode: selectedRecord.userId!,
        FromDate: visitDate,
        ToDate: visitDate,
        SrNoVal: srNo,
        token: Auth_Token!));
  }

  double skipRecords(List<List<double>> coordinates) {
    double totalDistance = 0.0;
    double distance = 0.0;
    int val = 0;

    for (int i = 0; i < validList.length; i++) {
      double distance = double.tryParse(validList[i].distance!) ?? 0.0;
      totalDistanceee += distance;
    }
    formattedDistance = (totalDistanceee / 1000).toStringAsFixed(2);

    print("Corrected Total Distance: $formattedDistance KM");

    // Iterate through the list of coordinates
    for (int i = 0; i < coordinates.length - 1; i++) {
      if (val == coordinates.length - 1) {
        // If val reaches the last coordinate, break the loop
        print("Skip records: val and list size are the same: $val , ${coordinates.length}");
        break;
      }

      print("Skip records: i ---> $i");
      print("Skip records: val ---> $val");
      if (i == coordinates.length - 1) {
        print("Skip records: i==coordinates.length - 1 true---> ");
        break;
      }

      for (int j = i + 1; j < coordinates.length; j++) {
        print("Skip records: inside i ---> $i");
        print("Skip records: j ---> $j");

        List<double> start = coordinates[i];
        List<double> end = coordinates[j];

        // Extract latitude and longitude for start and end points
        double startLat = start[0];
        double startLong = start[1];
        double endLat = end[0];
        double endLong = end[1];
        print("Skip records: startLat,startLong: $startLat,$startLong");
        print("Skip records: endLat,endLong: $endLat,$endLong");

        distance = calculateDistance(startLat, startLong, endLat, endLong);
        print("Skip records: distance: $distance");

        if (distance >= 10) {
          i = j - 1; // Update val to the index of the valid point
          print("Skip records: Valid distance found, updating val to: $i");

          totalDistance += distance;
          print("Skip records: Total distance: $totalDistance");

          break; // Exit inner loop after finding a valid distance
        }
        if (j == coordinates.length - 1) {
          i = j;
        }
      }
    }

    // Return the total distance traveled
    return totalDistance;
  }

  double calculateDistance(double startLat, double startLong, double endLat, double endLong) {
    // Convert latitude and longitude from degrees to radians
    double startLatRad = startLat * (3.141592653589793 / 180);
    double startLongRad = startLong * (3.141592653589793 / 180);
    double endLatRad = endLat * (3.141592653589793 / 180);
    double endLongRad = endLong * (3.141592653589793 / 180);

    // Compute the differences between coordinates
    double latDiff = endLatRad - startLatRad;
    double longDiff = endLongRad - startLongRad;

    // Compute the distance using Haversine formula
    double a = (sin(latDiff / 2) * sin(latDiff / 2)) +
        (cos(startLatRad) * cos(endLatRad) * (sin(longDiff / 2) * sin(longDiff / 2)));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Return the distance in meters
    return EARTH_RADIUS_METERS * c;
  }

  @override
  Widget build(BuildContext context)
  {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        // appBar: AppBar(
        //   iconTheme: const IconThemeData(
        //     color: Colors.white,
        //     size: 28,
        //   ),
        //   title: const Text("Visit Report"),
        //   backgroundColor: MyColors.lightBlue,
        //   centerTitle: true,
        //   titleTextStyle: GoogleFonts.roboto(
        //     fontWeight: FontWeight.bold,
        //     fontSize: 20.0,
        //   ).copyWith(
        //     color: Colors.white,
        //   ),
        // ),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Go Back',
              onPressed: () {
                Navigator.pop(context); // Goes to previous screen
              },
            ),
          ],
        ),


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
                if (state is GetVisitDetailedRecordsLoadingState) {
                  setState(() {
                    _isLoading = true;
                  });
                }
                else if (state is GetVisitDetailedRecordsLoadedState) {
                  setState(() {
                    _isLoading = false;
                    allRecords.clear();
                    validList.clear();
                    validListt.clear();

                  });
                  Fluttertoast.showToast(
                    msg: "   Success!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                  print("allRecords Size....${allRecords.length}");
                  if(state.visitDetailedRecordsResponse!.message !=null)
                  {
                    setState(()
                    {
                      allRecords.addAll(state.visitDetailedRecordsResponse!.message!);
                    });
                    validListt = allRecords.where((latLong) =>
                    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();
                    List<Message> validList2=[];

                    validList=validListt.reversed.toList();


                    for(int i=0;i<allRecords.length;i++)
                    {
                      if(allRecords[i].latitude=="0.0")
                      {
                        print("Skipped .........${i}");
                      }
                      else
                      {
                        validList2.add(allRecords[i]);
                      }
                    }

                    print("allRecords Size...........${allRecords.length}");
                    print("validList Size...........${validList.length}");
                    print("validList2 Size...........${validList2.length}");



                    for(int i=0;i<validList.length;i++)
                    {

                      double distance = double.parse(validList[i].distance!);
                      distanceee=distanceee+distance;
                      String lat=validList[i].latitude!;
                      String long=validList[i].longitude!;

                      coordinates.add(LatLng(double.parse(lat), double.parse(long)));
                      coordinatesList.add([double.parse(lat), double.parse(long)]);
                      /* LatLng lat1 = LatLng(double.parse(lat), double.parse(long));
                      coordinates.add(lat1);
                      coordinatesList.add([double.parse(lat), double.parse(lat)]);*/
                    }

                    totalDistanceee = skipRecords(coordinatesList);

                    formattedDistance = (totalDistanceee / 1000).toStringAsFixed(2);
                    print("distanceee....${distanceee}");
                    print("formattedDistance....${formattedDistance}");

                    print("totalDistanceee....${totalDistanceee}");
                  }
                  else
                  {
                    print("allRecords Size....${allRecords.length}");
                  }
                  double finalDistance = 0;
                  List<double> speedList = [];
                  List<String> distanceList = [];
                  //speedList.add(0.0);
                  distanceList.add("0.0");
                  for (int i = 0; i < validList.length; i++) {
                    for (int j = i + 1; j < validList.length; j++) {


                      String prevLat = validList[i].latitude!;
                      String prevLong = validList[i].longitude!;

                      String currentLat = validList[j].latitude!;
                      String currentLong = validList[j].longitude!;

                      double dis = calculateDistance(double.parse(prevLat), double.parse(prevLong),
                          double.parse(currentLat), double.parse(currentLong));
                      print("Taghhhh: dis--->$dis");

                      double exDistanceKm = dis / 1000;
                      print("Taghhhh: ExDistancekm--->$exDistanceKm");
                      setState(() {
                        distanceList.add(exDistanceKm.toStringAsFixed(2));

                      });

                      try {
                        DateTime time1 = parseTimestamp(validList[i].transactionDate!);
                        DateTime time2 = parseTimestamp(validList[j].transactionDate!);
                        int timeElapsedMillis = time2.millisecondsSinceEpoch - time1.millisecondsSinceEpoch;

                        print("Taghhhh: timeElapsedMillis--->$timeElapsedMillis");

                        // double speed = calculateSpeed(dis, timeElapsedMillis);

                        // speedList.add((speed).roundToDouble());

                        //print("Taghhhh: speed--->$speed");
                      } catch (e) {
                        print("Taghhh: Exception-->${e.toString()}");
                      }

                      finalDistance += dis;

                      print("Taghhhh: finalDistance-->$finalDistance");

                      break;
                    }
                  }
                  print("Taghhhh: speedList size---${speedList.length}");
                  try {
                    if (validList.length == speedList.length) {
                      for (int i = 0; i < validList.length; i++) {
                        validList[i].speed=speedList[i].toString();
                        validList[i].distance=distanceList[i];
                        //validList[i].batteryPercentage=ba
                      }
                    } else {
                      for (int i = 0; i < validList.length; i++) {
                        validList[i].speed=speedList[i].toString();
                        validList[i].distance=distanceList[i];
                      }
                    }
                  } catch (e) {
                    print("Taghhh: Exception Herere-->${e.toString()}");
                  }
                }
                else if (state is GetVisitDetailedRecordsErrorState)
                {
                  setState(()
                  {
                    _isLoading = false;
                  });
                  Fluttertoast.showToast
                    (
                    msg: "   Failed To Connect Server!   ",
                    toastLength: Toast.LENGTH_SHORT,
                    timeInSecForIosWeb: 1,
                  );
                }
              },
              child:
              SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child:Column(
                      children: [
                        Card(
                          shape:
                          RoundedRectangleBorder(
                            side: BorderSide(width: 2, color: MyColors.lightBlue),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          //  color: MyColors.lighterRedColorCode,
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
                                              Text("Visit Date",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                              Text(selectedRecord.selectDate!=null ? selectedRecord.selectDate! :  "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                            ],
                                          )
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Source - Destination ",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                            Text(selectedRecord.source.toString()!=null ? selectedRecord.source.toString()+" - "+selectedRecord.destination.toString() : "NA",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                          ],
                                        ),
                                      ),


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
                                            Text(selectedRecord.fromtime!=null ? selectedRecord.fromtime!+" - "+selectedRecord.totime! :  "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                          ],
                                        )
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Visit name",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                          Text(selectedRecord.reason!=null ? selectedRecord.reason! : "",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15.0,bottom: 15),
                                  child:
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Total Distance Traveled : "+formattedDistance +" KM ",style: TextStyle(color: MyColors.blueColorCode,fontSize: 21,fontWeight: FontWeight.bold),),
                                            ],
                                          )
                                      ),

                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),


                        Padding(padding: EdgeInsets.only(top:15,left:14,right:14,bottom: 15),
                          child:SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Table(
                                border: TableBorder.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                                columnWidths: {
                                  // 0: FixedColumnWidth(160), // Sr No column width
                                  0: FixedColumnWidth(120), // Date column width
                                  1: FixedColumnWidth(100),  // Speed column width
                                  2: FixedColumnWidth(200), // Distance column width
                                  3: FixedColumnWidth(100), // Latitude column width
                                  4: FixedColumnWidth(100), // Longitude column width
                                  5: FixedColumnWidth(400),
                                  6: FixedColumnWidth(100)// Increased Address column width
                                },
                                children: [
                                  // Table header row
                                  TableRow(
                                    decoration: BoxDecoration(color: Colors.grey[300]),
                                    children: [
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Date", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Speed In m/s ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Distance In KM ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Latitude", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Longitude", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Address", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                                      TableCell(
                                          child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("Battery", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))))
                                    ],
                                  ),
                                  // Transaction data rows
                                  for (var i = 0; i < validList.length; i++)
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: i.isEven ? Colors.white : Colors.grey[100], // Alternate row colors
                                      ),
                                      children: [
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  validList[i].transactionTime.toString().replaceAll("T", " "),
                                                  textAlign: TextAlign.center,
                                                ))),
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  double.parse(validList[i].speed.toString()).toStringAsFixed(2),
                                                  textAlign: TextAlign.center,
                                                ))),
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text( double.parse(validList[i].distanceInkmMeter.toString()).toStringAsFixed(2),
                                                  textAlign: TextAlign.center,
                                                ))),
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  double.parse(validList[i].latitude.toString()).toStringAsFixed(6),
                                                  textAlign: TextAlign.center,
                                                ))),
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  double.parse(validList[i].longitude.toString()).toStringAsFixed(6),
                                                  textAlign: TextAlign.center,
                                                ))),
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(18.0),
                                                child: Text(
                                                  validList[i].address.toString(),
                                                  textAlign: TextAlign.left,
                                                ))),
                                        TableCell(
                                            child: Padding(
                                                padding: EdgeInsets.all(18.0),
                                                child: Text(
                                                  validList[i].batteryPercentage.toString() + "%",
                                                  textAlign: TextAlign.left,
                                                ))),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )

                      ])

              )

          ),
        ),
      ),
    );

  }



  DateTime parseTimestamp(String timestamp) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    // Replace the 'T' with a space to match the format
    String formattedTimestamp = timestamp.replaceAll('T', ' ');
    return formatter.parse(formattedTimestamp);
  }

// double calculateSpeed(double distance, int timeElapsedMillis) {
//   // Convert time to seconds
//   double timeElapsedSeconds = timeElapsedMillis / 1000.0;
//   print("timeElapsedSeconds--->$timeElapsedSeconds");
//   // Calculate speed (meters per second)
//   if (timeElapsedSeconds > 0) {
//     print("calculateSpeed IFF Block--->");
//     return distance / timeElapsedSeconds;
//   } else {
//     print("calculateSpeed Else Block--->");
//     return 0.0;
//   }
//}
}










/*
import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:attendance_system_ios/util/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'dart:math';
import '../../model/VisitReport/VisitDetailedRecordsResponse.dart';
import '../../model/VisitReport/VisitRecordsResponse.dart';

class VisitReportDetailedScreen extends StatefulWidget {

  String visitsrNo;
  String? selectdate;
  Data record;
  VisitReportDetailedScreen(
      {
        Key? key,
        required this.visitsrNo,
        required this.selectdate,
        required this.record,

      })
      : super(key: key);

  @override
  State<VisitReportDetailedScreen> createState() => _VisitReportDetailedScreenState();
}

class _VisitReportDetailedScreenState extends State<VisitReportDetailedScreen>
{
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";
  String? Auth_Token = "";

  late bool _isLoading = false;

  final controller = ScrollController();

  late String visitDate;
  DateTime currentdate = DateTime.now();

  DateTime selectedDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TimeOfDay selectedToTime = TimeOfDay.now();
  late String srNo,selectDate;

  List<Message> allRecords=[];
  List<Message> validListt=[];
  List<Message> validList=[];

  ScrollController visitRecordController=new ScrollController();
  late Data selectedRecord;

   double distanceee=0.0;

  List<LatLng> coordinates = [];
  List<List<double>> coordinatesList = [];
  static  int EARTH_RADIUS_METERS = 6371000;

  double totalDistanceee=0.0;

  String formattedDistance="";
  @override
  void initState()
  {
    mainBloc = BlocProvider.of<MainBloc>(context);
    srNo=widget.visitsrNo;
    selectDate=widget.selectdate!;
    selectedRecord=widget.record!;


    getData();
  }
  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->$staffCode");
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->$Auth_Token");
    print("srNo-->$srNo");
    print("selectDate-->$selectDate");
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(selectDate);

    // Format the parsed date into 'yyyy-MM-dd' format
     visitDate = DateFormat('yyyy-MM-dd').format(parsedDate);
     mainBloc.add(GetVisitDetailedRecordsEvent(
         StaffCode: "CD03080",
         FromDate: visitDate,
         ToDate: visitDate,
         SrNoVal: srNo,
         token: Auth_Token!));
  }
  double skipRecords(List<List<double>> coordinates) {
    double totalDistance = 0.0;
    double distance = 0.0;
    int val = 0;

    // Iterate through the list of coordinates
    for (int i = 0; i < coordinates.length - 1; i++) {
      if (val == coordinates.length - 1) {
        // If val reaches the last coordinate, break the loop
        print("Skip records: val and list size are the same: $val , ${coordinates.length}");
        break;
      }

      print("Skip records: i ---> $i");
      print("Skip records: val ---> $val");
      if (i == coordinates.length - 1) {
        print("Skip records: i==coordinates.length - 1 true---> ");
        break;
      }

      for (int j = i + 1; j < coordinates.length; j++) {
        print("Skip records: inside i ---> $i");
        print("Skip records: j ---> $j");

        List<double> start = coordinates[i];
        List<double> end = coordinates[j];

        // Extract latitude and longitude for start and end points
        double startLat = start[0];
        double startLong = start[1];
        double endLat = end[0];
        double endLong = end[1];
        print("Skip records: startLat,startLong: $startLat,$startLong");
        print("Skip records: endLat,endLong: $endLat,$endLong");

        distance = calculateDistance(startLat, startLong, endLat, endLong);
        print("Skip records: distance: $distance");

        if (distance >= 200) {
          i = j - 1; // Update val to the index of the valid point
          print("Skip records: Valid distance found, updating val to: $i");

          totalDistance += distance;
          print("Skip records: Total distance: $totalDistance");

          break; // Exit inner loop after finding a valid distance
        }
        if (j == coordinates.length - 1) {
          i = j;
        }
      }
    }

    // Return the total distance traveled
    return totalDistance;
  }

  double calculateDistance(double startLat, double startLong, double endLat, double endLong) {
    // Convert latitude and longitude from degrees to radians
    double startLatRad = startLat * (3.141592653589793 / 180);
    double startLongRad = startLong * (3.141592653589793 / 180);
    double endLatRad = endLat * (3.141592653589793 / 180);
    double endLongRad = endLong * (3.141592653589793 / 180);

    // Compute the differences between coordinates
    double latDiff = endLatRad - startLatRad;
    double longDiff = endLongRad - startLongRad;

    // Compute the distance using Haversine formula
    double a = (sin(latDiff / 2) * sin(latDiff / 2)) +
        (cos(startLatRad) * cos(endLatRad) * (sin(longDiff / 2) * sin(longDiff / 2)));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Return the distance in meters
    return EARTH_RADIUS_METERS * c;
  }

  @override
  Widget build(BuildContext context)
  {
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
              if (state is GetVisitDetailedRecordsLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              }
              else if (state is GetVisitDetailedRecordsLoadedState) {
                setState(() {
                  _isLoading = false;
                  allRecords.clear();
                  validList.clear();
                  validListt.clear();

                });
                Fluttertoast.showToast(
                  msg: "   Success!   ",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                );
                print("allRecords Size....${allRecords.length}");
                if(state.visitDetailedRecordsResponse!.message !=null)
                {
                  setState(()
                  {
                    allRecords.addAll(state.visitDetailedRecordsResponse!.message!);

                  });
                 validListt = allRecords.where((latLong) =>
                  latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();
                  List<Message> validList2=[];

                  validList=validListt.reversed.toList();


                 for(int i=0;i<allRecords.length;i++)
                   {
                     if(allRecords[i].latitude=="0.0")
                       {
                         print("Skipped .........${i}");

                       }
                     else
                       {
                         validList2.add(allRecords[i]);
                       }
                   }

                  print("allRecords Size...........${allRecords.length}");
                  print("validList Size...........${validList.length}");
                  print("validList2 Size...........${validList2.length}");



                  for(int i=0;i<validList.length;i++)
                  {

                    double distance = double.parse(validList[i].distance!);
                    distanceee=distanceee+distance;
                    String lat=validList[i].latitude!;
                    String long=validList[i].longitude!;


                    LatLng lat1 = LatLng(double.parse(lat), double.parse(long));
                    coordinates.add(lat1);
                    coordinatesList.add([double.parse(lat), double.parse(lat)]);


                  }

                   totalDistanceee = skipRecords(coordinatesList);

                   formattedDistance = (totalDistanceee / 1000).toStringAsFixed(2);
                  print("distanceee....${distanceee}");
                  print("formattedDistance....${formattedDistance}");

                  print("totalDistanceee....${totalDistanceee}");

                }
                else
                {
                  print("allRecords Size....${allRecords.length}");

                }
                double finalDistance = 0;
                List<double> speedList = [];
                List<String> distanceList = [];
                speedList.add(0.0);
                distanceList.add("0.0");
                for (int i = 0; i < validList.length; i++) {
                  for (int j = i + 1; j < validList.length; j++) {


                    String prevLat = validList[i].latitude!;
                    String prevLong = validList[i].longitude!;

                    String currentLat = validList[j].latitude!;
                    String currentLong = validList[j].longitude!;

                    double dis = calculateDistance(double.parse(prevLat), double.parse(prevLong),
                        double.parse(currentLat), double.parse(currentLong));
                    print("Taghhhh: dis--->$dis");

                    double exDistanceKm = dis / 1000;
                    print("Taghhhh: ExDistancekm--->$exDistanceKm");
                    setState(() {
                      distanceList.add(exDistanceKm.toStringAsFixed(2));

                    });

                    try {
                      DateTime time1 = parseTimestamp(validList[i].transactionDate!);
                      DateTime time2 = parseTimestamp(validList[j].transactionDate!);
                      int timeElapsedMillis = time2.millisecondsSinceEpoch - time1.millisecondsSinceEpoch;

                      print("Taghhhh: timeElapsedMillis--->$timeElapsedMillis");

                      double speed = calculateSpeed(dis, timeElapsedMillis);

                      speedList.add((speed).roundToDouble());

                      print("Taghhhh: speed--->$speed");
                    } catch (e) {
                      print("Taghhh: Exception-->${e.toString()}");
                    }

                    finalDistance += dis;

                    print("Taghhhh: finalDistance-->$finalDistance");

                    break;
                  }
                }
                print("Taghhhh: speedList size---${speedList.length}");
                try {
                  if (validList.length == speedList.length) {
                    for (int i = 0; i < validList.length; i++) {
                      validList[i].speed=speedList[i].toString();
                      validList[i].distance=distanceList[i];
                    }
                  } else {
                    for (int i = 0; i < validList.length; i++) {
                      validList[i].speed=speedList[i].toString();
                      validList[i].distance=distanceList[i];
                    }
                  }
                } catch (e) {
                  print("Taghhh: Exception Herere-->${e.toString()}");
                }



              }
              else if (state is GetVisitDetailedRecordsErrorState)
              {
                setState(() {
                  _isLoading = false;
                });
                Fluttertoast.showToast
                  (
                  msg: "   Failed To Connect Server!   ",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                );
              }
            },
            child:

            SingleChildScrollView(

            scrollDirection: Axis.vertical,
              child:Column(
                  children: [
                Card(
                  shape:
                  RoundedRectangleBorder(
                    side: BorderSide(width: 2, color: MyColors.lightBlue),
                    borderRadius: BorderRadius.circular(10.0),

                  ),
                //  color: MyColors.lighterRedColorCode,
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
                                      Text("Visit Date",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                      Text(selectedRecord.selectDate!=null ? selectedRecord.selectDate! :  "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                    ],
                                  )
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Source - Destination ",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                    Text(selectedRecord.source.toString()!=null ? selectedRecord.source.toString()+" - "+selectedRecord.destination.toString() : "NA",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                  ],
                                ),
                              ),


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
                                    Text(selectedRecord.fromtime!=null ? selectedRecord.fromtime!+" - "+selectedRecord.totime! :  "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                  ],
                                )
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Reason",style: TextStyle(color: MyColors.textprofiledetailColorCode,fontSize: 18),),
                                  Text(selectedRecord.reason!=null ? selectedRecord.reason! : "",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                                ],
                              ),
                            ),




                          ],
                        ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0,bottom: 15),
                      child:
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total Distance Traveled : "+formattedDistance +" KM ",style: TextStyle(color: MyColors.blueColorCode,fontSize: 21,fontWeight: FontWeight.bold),),
                                  ],
                                )
                            ),





                          ],
                        ),
                    )
                      ],
                    ),
                  ),
                ),


                  Padding(padding: EdgeInsets.only(top:15,left:14,right:14,bottom: 15),
                 child:SingleChildScrollView(
                   child: SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Table(
                       border: TableBorder.all(
                         color: Colors.grey,
                         width: 1,
                       ),
                       columnWidths: {
                         0: FixedColumnWidth(160), // Sr No column width
                         1: FixedColumnWidth(120), // Date column width
                         2: FixedColumnWidth(180),  // Speed column width
                         3: FixedColumnWidth(200), // Distance column width
                         4: FixedColumnWidth(200), // Latitude column width
                         5: FixedColumnWidth(500), // Longitude column width
                         6: FixedColumnWidth(5300), // Increased Address column width
                       },
                       children: [
                         // Table header row
                         TableRow(
                           decoration: BoxDecoration(color: Colors.grey[300]),
                           children: [
                             TableCell(
                                 child: Padding(
                                     padding: EdgeInsets.all(8.0),
                                     child: Text("Date", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                             TableCell(
                                 child: Padding(
                                     padding: EdgeInsets.all(8.0),
                                     child: Text("Speed In m/s ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                             TableCell(
                                 child: Padding(
                                     padding: EdgeInsets.all(8.0),
                                     child: Text("Distance In KM ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                             TableCell(
                                 child: Padding(
                                     padding: EdgeInsets.all(8.0),
                                     child: Text("Latitude", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                             TableCell(
                                 child: Padding(
                                     padding: EdgeInsets.all(8.0),
                                     child: Text("Longitude", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                             TableCell(
                                 child: Padding(
                                     padding: EdgeInsets.all(8.0),
                                     child: Text("Address", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                           ],
                         ),
                         // Transaction data rows
                         for (var i = 0; i < validList.length; i++)
                           TableRow(
                             decoration: BoxDecoration(
                               color: i.isEven ? Colors.white : Colors.grey[100], // Alternate row colors
                             ),
                             children: [
                               TableCell(
                                   child: Padding(
                                       padding: EdgeInsets.all(8.0),
                                       child: Text(
                                         validList[i].transactionDate.toString().replaceAll("T", " "),
                                         textAlign: TextAlign.center,
                                       ))),
                               TableCell(
                                   child: Padding(
                                       padding: EdgeInsets.all(8.0),
                                       child: Text(
                                         validList[i].speed.toString(),
                                         textAlign: TextAlign.center,
                                       ))),
                               TableCell(
                                   child: Padding(
                                       padding: EdgeInsets.all(8.0),
                                       child: Text(
                                         validList[i].distanceInkmMeter.toString(),
                                         textAlign: TextAlign.center,
                                       ))),
                               TableCell(
                                   child: Padding(
                                       padding: EdgeInsets.all(8.0),
                                       child: Text(
                                         validList[i].latitude.toString(),
                                         textAlign: TextAlign.center,
                                       ))),
                               TableCell(
                                   child: Padding(
                                       padding: EdgeInsets.all(8.0),
                                       child: Text(
                                         validList[i].longitude.toString(),
                                         textAlign: TextAlign.center,
                                       ))),
                               TableCell(
                                   child: Padding(
                                       padding: EdgeInsets.all(18.0),
                                       child: Text(
                                         validList[i].address.toString(),
                                         textAlign: TextAlign.left,
                                       ))),
                             ],
                           ),
                       ],
                     ),
                   ),
                 ),
                  )

          ])

            )




          ),
        ),
      ),
    );

  }



  DateTime parseTimestamp(String timestamp) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    // Replace the 'T' with a space to match the format
    String formattedTimestamp = timestamp.replaceAll('T', ' ');
    return formatter.parse(formattedTimestamp);
  }

  double calculateSpeed(double distance, int timeElapsedMillis) {
    // Convert time to seconds
    double timeElapsedSeconds = timeElapsedMillis / 1000.0;
    print("timeElapsedSeconds--->$timeElapsedSeconds");
    // Calculate speed (meters per second)
    if (timeElapsedSeconds > 0) {
      print("calculateSpeed IFF Block--->");
      return distance / timeElapsedSeconds;
    } else {
      print("calculateSpeed Else Block--->");
      return 0.0;
    }
  }


}*/
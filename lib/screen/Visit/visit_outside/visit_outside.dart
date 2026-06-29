import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/model/VisitData/fetch_visit_data.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitDetailedRecordsResponse.dart'
    as visitValues;
import 'package:attendance_system_ios/screen/Splash%20Screen/splash_screen.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../bloc/main_bloc.dart';
import '../../../main.dart';
import '../../../service/WebService.dart';
import '../../../util/MyColor.dart';
import '../../Visit History/VisitHistoryTrack_Screen.dart';
import '../Start Stop Visit/start_stop_visit.dart';
import 'location_picker_screen.dart';

class VisitOutside extends StatefulWidget {
  const VisitOutside({super.key});

  @override
  State<VisitOutside> createState() => _VisitOutsideState();
}

class _VisitOutsideState extends State<VisitOutside> {
  late MainBloc mainBloc;
  late List<visitValues.Message> latLongList = [];
  FlutterSecureStorage storage = FlutterSecureStorage();
  TextEditingController nameController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String location = 'Select Location';
  String nameOfVisit = '';
  String? staffcode =
      ""; // Example EmpCode, replace with dynamic value if needed
  String? token = '';
  bool isEditing = false;
  Data? selectedVisitt;

  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String? _selectedAddress;
  String? _currentAddress;
  bool isLoading = false;
  bool _newVisitCreate = false;

  List<Data> visitList = [];
  bool isVisitStarted = false;

  // late VisitReminderService _reminderService;
  bool isTablet = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 15)),
          // firstDate: DateTime(2020),
          // lastDate: DateTime(2100),
        ) ??
        selectedDate;

    setState(() {
      selectedDate = picked;
    });
  }

  ///time selection
//   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
//     final TimeOfDay picked = await showTimePicker(
//       context: context,
//       initialTime: isStartTime ? startTime : endTime,
//     ) ??
//         TimeOfDay.now();
//
//     setState(() {
//       if (isStartTime) {
//         startTime = picked;
//       } else {
//         endTime = picked;
//       }
//     });
//   }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked; // will include AM/PM
        } else {
          endTime = picked;
        }
      });
    }
  }

  String formatTimeOfDay12Hr(TimeOfDay tod) {
    final int hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final String minute = tod.minute.toString().padLeft(2, '0');
    final String period = tod.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  String formatApiTime(String? apiTime, BuildContext context) {
    if (apiTime == null || apiTime.isEmpty) return "";

    try {
      // Parse the API 24hr string like "16:03"
      final parsed = DateFormat("HH:mm").parse(apiTime);

      // Convert to Flutter’s localised 12hr with AM/PM
      return TimeOfDay.fromDateTime(parsed).format(context);
    } catch (e) {
      debugPrint("Error parsing time: $apiTime -> $e");
      return apiTime; // fallback: show as-is
    }
  }

  void _selectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['pickedLocation'];
        _currentLocation = result['currentLocation'];
        _selectedAddress = result['pickedAddress'];
        _currentAddress = result['currentAddress'];
        location = "$_selectedAddress";
        print(
            "Selected Location: lat - ${_selectedLocation!.latitude} long - ${_selectedLocation!.longitude}");
        print("Picked Location Address: $_selectedAddress");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    // _reminderService = VisitReminderService();
  }

  Future<void> _initialize() async {
    await _fetchStorage(); // Wait for the storage fetching to complete
    await _fetchVisits(); // Call fetchVisits after token is fetched
  }

  Future<void> _fetchStorage() async {
    staffcode = await storage.read(key: 'username');
    token = await storage.read(key: 'Auth_Token');
  }

  void clearFields() {
    setState(() {
      selectedDate = DateTime.now();
      startTime = TimeOfDay.now();
      endTime = TimeOfDay.now();
      location = 'Select Location';
      nameController.clear();
    });
  }

  //abhishek's InsertVisit Api
  Future<void> _createVisit() async {
    // Convert selected TimeOfDay + selected Date to full DateTime
    DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    }

// ✅ Validation
    final DateTime selectedStartDateTime =
        _combineDateAndTime(selectedDate, startTime);
    final DateTime now = DateTime.now();

    DateTime _timeOfDayToDateTime(TimeOfDay time) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    }

    // ✅ Check if visit name is empty
    if (nameOfVisit == null || nameOfVisit!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Visit Name!!")),
      );
      return;
    }
    if (nameOfVisit.length < 3) {
      Fluttertoast.showToast(msg: "please enter valid visit");
    }

    // ✅ Ensure start time should not be less than current time
    if (selectedStartDateTime
        .isBefore(now.subtract(const Duration(minutes: 3)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Start time cannot be earlier than current time!")),
      );
      return;
    }

    // ✅ Ensure start time is not greater than end time
    if (_timeOfDayToDateTime(startTime)
        .isAfter(_timeOfDayToDateTime(endTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("StartTime cannot be greater than EndTime!!")),
      );
      return;
    }

    // ✅ Start and end time should not be the same.
    if (_timeOfDayToDateTime(startTime)
        .isAtSameMomentAs(_timeOfDayToDateTime(endTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Start time and end time cannot be the same!")),
      );
      return;
    }

    // Check for at least 10-minute gap
    Duration difference = _timeOfDayToDateTime(endTime)
        .difference(_timeOfDayToDateTime(startTime));
    if (difference.inMinutes < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "There should be at least a 10-minute gap between start and end time!")),
      );
      return;
    }
    // else if (_timeOfDayToDateTime(startTime).isAfter(
    //     _timeOfDayToDateTime(endTime))) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //         content: Text("StartTime cannot be greater than EndTime!!")),
    //   );
    //   return;
    // }

    if (_currentLocation == null ||
        _selectedLocation == null ||
        location == 'Select Location') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location first!!")),
      );
      return;
    } else {
      final String formatedSelectedDate =
          DateFormat('dd/MM/yyyy').format(selectedDate);
      final String visitDate =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://114.143.140.28:8091/api/Visit/InsertVisit'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: json.encode({
            "userId": staffcode,
            "selectDate": formatedSelectedDate,
            "fromTime": formatTimeOfDay12Hr(startTime),
            "toTime": formatTimeOfDay12Hr(endTime),
            "reason": nameOfVisit,
            "source": _currentAddress,
            "destination": _selectedAddress,
            "status": "I",
            "visitDate": visitDate
          }),
        );

        print('create visit ${response.statusCode}');
        if (response.statusCode == 200) {
          final result = response.body;
          // print('create visit response body: $result');
          if (result == 'Record inserted Successfully.') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Visit details saved successfully")),
            );
            _newVisitCreate = true;
            _fetchVisits();
            clearFields();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $result")),
            );
          }
        } else if (response.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('UnAuthorized. Kindly Login Again!!'),
              action: SnackBarAction(
                label: 'Login Again',
                onPressed: () {
                  isloggedIn = true;
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SplashScreen()));
                },
              ),
              duration: Duration(days: 365), // Make it sticky
            ),
          );
        } else {
          LogFileManager.writeLog(
              "Error in create visit: status code: ${response.statusCode}, response body: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
              "Error in Saving. Retry After Sometime!. If issue continues kindly logout and login again",
              style: TextStyle(fontSize: 16),
            )),
          );
          print(
              'Error in create visit: status code: ${response.statusCode}, response body: ${response.body}');
        }
      } catch (e) {
        print("create visit api call: $e");
        LogFileManager.writeLog("create visit api call: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchVisits() async {
    if (!mounted) return; // prevent running if widget is gone

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://114.143.140.28:8091/api/Visit/GetAllVisit/$staffcode/1/50'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      print('fetch api response code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final VisitDataResoponse visitData =
            VisitDataResoponse.fromJson(json.decode(response.body));

        if (!mounted) return;

        setState(() {
          visitList = visitData.message?.data ?? [];
        });

        if (visitData.message?.data?.isNotEmpty ?? false) {
          if (_newVisitCreate) {
            _UpdateStopLatLong(visitList[0], _selectedLocation!.latitude,
                _selectedLocation!.longitude);
            _newVisitCreate = false;
          }
        }
      } else if (response.statusCode == 400) {
        if (!mounted) return;
        Fluttertoast.showToast(msg: "No Details Available");
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn = true;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(days: 365),
          ),
        );
      } else {
        if (!mounted) return;
        Fluttertoast.showToast(msg: "Error in Visit Schedule");
      }
    } catch (e) {
      print('Fetch visit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _UpdateStopLatLong(
      Data visit, double latitude, double longitude) async {
    try {
      final response = await http.post(
          Uri.parse(
              "http://114.143.140.28:8091/api/Visit/UpdateStatusStopLatLong/${visit.srNo}/${latitude.toString()}/${longitude.toString()}/I"),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // Ensure token is valid
          });

      if (response.statusCode == 200) {
        print('_UpdateStopLatLong Record Updated Successfully');
      } else {
        print('Failed to _UpdateStopLatLong');
      }
    } catch (e) {
      print('Error while calling _UpdateStopLatLong API: $e');
    }
  }

  // Future<void> _startVisit(Data visit) async {
  //   /*   setState(() {
  //     isVisitStarted = true;
  //   });*/
  //   /*  ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Visit started")),
  //   );*/
  //   // if (VisitState.isVisitRunning.value) {
  //   //   Fluttertoast.showToast(
  //   //     msg:
  //   //         "A visit is already running. Please stop it before starting a new one.",
  //   //   );
  //   //   return;
  //   // }
  //
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => VisitStartStopScreen(visit: visit)));
  // }
  /*Future<void> _startVisit(Data visit) async {
    String? runningVisitJson = await storage.read(key: 'SelectedVisit');

    if (VisitState.isVisitRunning.value && runningVisitJson != null) {
      final runningVisit = Data.fromJson(jsonDecode(runningVisitJson));

      // ✅ SAME visit → allow navigation
      if (runningVisit.srNo == visit.srNo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitStartStopScreen(visit: visit),
          ),
        );
        return;
      }

      // ❌ DIFFERENT visit → block
      Fluttertoast.showToast(
        msg:
            "A visit is already running. Please stop it before starting a new one.",
      );
      return;
    }

    // ✅ No visit running → allow
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitStartStopScreen(visit: visit),
      ),
    );
  }*/
  Future<void> _startVisit(Data visit) async {
    // 🔁 Check persisted running visit (after app restart)
    String? storedSrNo = await storage.read(key: 'RunningVisitSrNo');

    if (storedSrNo != null) {
      // If SAME visit → allow
      if (storedSrNo == visit.srNo.toString()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitStartStopScreen(visit: visit),
          ),
        );
        return;
      }

      // If DIFFERENT visit → block
      Fluttertoast.showToast(
        msg:
            "A visit is already running. Please stop it before starting a new one.",
      );
      return;
    }

    // ✅ Normal flow (no visit running)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitStartStopScreen(visit: visit),
      ),
    );
  }

  Future<void> _updateVisit() async {
    //_selectLocation(context);
    if (selectedVisitt == null) return;
    final visitName = nameController.text.trim();

    DateTime _timeOfDayToDateTime(TimeOfDay time) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    }
    //
    // DateTime now = DateTime.now();
    // DateTime selectedStartDateTime = _timeOfDayToDateTime(startTime);
    //
    //

    // ✅ Check if visit name is empty
    if (visitName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Visit Name!!")),
      );
      return;
    }
    // Check if nameOfVisit contains only numbers
    if (RegExp(r'^\d+$').hasMatch(nameOfVisit!.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visit Name must include letters!!")),
      );
      return;
    }

    // ✅ Ensure start time is not greater than end time
    if (_timeOfDayToDateTime(startTime)
        .isAfter(_timeOfDayToDateTime(endTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("StartTime cannot be greater than EndTime!!")),
      );
      return;
    }

    // ✅ Start and end time should not be the same.
    if (_timeOfDayToDateTime(startTime)
        .isAtSameMomentAs(_timeOfDayToDateTime(endTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Start time and end time cannot be the same!")),
      );
      return;
    }

    // Check for at least 10-minute gap
    Duration difference = _timeOfDayToDateTime(endTime)
        .difference(_timeOfDayToDateTime(startTime));
    if (difference.inMinutes < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "There should be at least a 10-minute gap between start and end time!")),
      );
      return;
    }

    // else if (_timeOfDayToDateTime(startTime).isAfter(
    //     _timeOfDayToDateTime(endTime))) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //         content: Text("StartTime cannot be greater than EndTime!!")),
    //   );
    //   return;
    // }

    // if (_currentLocation == null || _selectedLocation == null || location == 'Select Location') {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Please select a location first!!")),
    //   );
    //   return;
    // }

    final String newName = nameController.text.trim();
    final String newDate = DateFormat('dd/MM/yyyy').format(selectedDate);
    final String newFromTime = formatTimeOfDay12Hr(startTime);
    final String newToTime = formatTimeOfDay12Hr(endTime);
    final String newLocation = location;

// Old values
    final oldName = selectedVisitt!.reason ?? "";
    final oldDate = selectedVisitt!.selectDate ?? "";
    final oldFromTime = selectedVisitt!.fromtime ?? "";
    final oldToTime = selectedVisitt!.totime ?? "";
    final oldLocation = selectedVisitt!.destination ?? "";

// 🔥 Compare
    bool isChanged = newName != oldName ||
        newDate != oldDate ||
        newFromTime != oldFromTime ||
        newToTime != oldToTime ||
        newLocation != oldLocation;

    if (!isChanged) {
      Fluttertoast.showToast(msg: "No changes detected");
      return;
    }

    final String formatedSelectedDate =
        DateFormat('dd/MM/yyyy').format(selectedDate);
    // final String visitDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(
    //     DateTime.now());

    String visitDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8091/api/Visit/UpdateVisit"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Ensure token is valid
        },
        body: json.encode({
          "srNo": selectedVisitt!.srNo.toString(),
          "userId": staffcode,
          "selectDate": formatedSelectedDate,
          // "fromTime": startTime.format(context),
          // "toTime": endTime.format(context),
          "fromTime": formatTimeOfDay12Hr(startTime),
          "toTime": formatTimeOfDay12Hr(endTime),

          "reason": nameController.text,
          // "source": _currentAddress,
          // "destination": location,
          "source": _currentAddress ?? selectedVisitt!.source,
          "destination": _selectedAddress ?? selectedVisitt!.destination,
          "status": "I",
          "visitDate": visitDate
        }),
      );
      print(
          "resquest body: ${selectedVisitt!.srNo}, ${staffcode}, ${formatedSelectedDate},"
          "${startTime.format(context)},${endTime.format(context)},${nameController.text}, ${_currentAddress},${location},${visitDate}");
      print("response code: ${response.statusCode}");
      if (response.statusCode == 200) {
        _fetchVisits(); // Refresh visit list
        setState(() {
          isEditing = false;
          selectedVisitt = null;
          clearFields();
        });
        Fluttertoast.showToast(msg: "Visit details updated successfully");
      } else {
        print("response.body ${response.body}");
        Fluttertoast.showToast(msg: "Error updating details");
      }
    } catch (e) {
      print("update visit api call: $e");
      LogFileManager.writeLog("update visit api call: $e");
    }
  }

  Future<void> _edit(Data visit) async {
    setState(() {
      isEditing = true;
      selectedVisitt = visit;

      nameController.text = visit.reason ?? "";
      nameOfVisit = visit.reason ?? "";
      selectedDate = DateFormat('dd/MM/yyyy').parse(visit.selectDate!);
      startTime =
          TimeOfDay.fromDateTime(DateFormat("hh:mm a").parse(visit.fromtime!));
      endTime =
          TimeOfDay.fromDateTime(DateFormat("hh:mm a").parse(visit.totime!));
      location = visit.destination ?? "Select Location";
      _currentAddress = visit.source; // ✅ FIX
      _selectedAddress = visit.destination; // ✅ (safe)

      print("update visit srno ${visit.srNo}");
    });

    //Fluttertoast.showToast(msg: "Under Development!!");
  }

  void _showDeleteConfirmationDialog(BuildContext context, Data visit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this visit?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Close dialog
                onDeleteVisit(visit);
                // _deleteVisit(visit); // Call delete function
              },
              child: Text("OK", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVisit(Data visit) async {
    print("visit ${visit.srNo}");

    try {
      final response = await http.post(
        Uri.parse(
            "http://114.143.140.28:8091/api/Visit/DeleteVisitRecords?UserId=$staffcode&srNo=${visit.srNo}"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Ensure token is valid
        },
      );
      print("response code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final result = response.body;
        Fluttertoast.showToast(msg: result);
        if (selectedVisitt?.srNo == visit.srNo) {
          setState(() {
            isEditing = false;
            selectedVisitt = null;
          });
          clearFields();
        }
        _fetchVisits();
      }
    } catch (e) {
      print("inside deleting visit catch: $e");
    }
  }

  Future<void> getVisitLatLong(Data visit) async {
    setState(() {
      isLoading = true;
    });
    String inputDate = visit.selectDate!;

    DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(inputDate);

    // Format the date into the desired format "dd-MMM-yyyy"
    String formattedDate = DateFormat("dd-MMM-yyyy").format(parsedDate);

    try {
      final response = await http.get(
          Uri.parse(
              "http://114.143.140.28:8091/api/Visit/GetVisitRecords?StaffCode=$staffcode&FromDate=$formattedDate&ToDate=$formattedDate&SrNoVal=${visit.srNo}"),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // Ensure token is valid
          });
      print(response.statusCode);
      print(response.body);
      print("Track visit details: $staffcode, ${visit.srNo}, $formattedDate");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Make sure 'message' is actually a list
        if (responseData['message'] is List) {
          latLongList = (responseData['message'] as List)
              .map((item) => visitValues.Message.fromJson(item))
              .toList();
          print("latLong list of opened track visit: $latLongList");
        }

        if (latLongList.isEmpty) {
          Fluttertoast.showToast(msg: 'Expired!! Visit not started.');
          return;
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BlocProvider(
                    create: (context) {
                      return MainBloc(webService: WebService());
                    },
                    child: VisitHistoryTrackScreen(
                      latLongList: latLongList,
                    ))));
      } else if (response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: "Visit Records Not Found",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        // return VisitDataResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        Fluttertoast.showToast(
          msg: " UnAuthorized! ",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        // return VisitDataResponse.fromJson(jsonDecode(response.body));
      } else {
        Fluttertoast.showToast(
          msg: "Error in Loading",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
      }
    } catch (e) {
      LogFileManager.writeLog("Error in GetVisitRecords: $e");
      print("Error in GetVisitRecords: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    isTablet = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Visit Outside"),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ).copyWith(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      title: const Column(
                        // mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Name of Visit:"),
                          Text(
                            "(Eg: Hinjewadi to wakad)",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: nameController,
                          inputFormatters: [
                            // Ronly letters and spaces
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9\s]')),
                          ],
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'Enter name',
                          ),
                          onChanged: (text) {
                            // Allow only single spaces between words, trim leading/trailing spaces
                            String sanitizedValue = text
                                .replaceAll(RegExp(r'\s{2,}'),
                                    ' ') // Replace multiple spaces with a single space
                                .trimLeft(); // Only trim leading spaces, not trailing

                            // Update the field only if the value changes
                            if (sanitizedValue != nameController.text) {
                              nameController.value = TextEditingValue(
                                text: sanitizedValue,
                                selection: TextSelection.collapsed(
                                    offset: sanitizedValue.length),
                              );
                            }

                            nameOfVisit =
                                sanitizedValue; // Store the sanitized value
                          },
                        ),
                      ),
                    ),
                  ),
                  // Select Date
                  Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      title: Text(
                          "Select Date: ${DateFormat.yMMMd().format(selectedDate)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                  ),

                  // Start Time
                  Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      //title: Text("Start Time: ${startTime.format(context)}"),
                      title:
                          Text("Start Time: ${formatTimeOfDay12Hr(startTime)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),

                  // End Time
                  Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      // title: Text("End Time: ${endTime.format(context)}"),
                      title: Text("End Time: ${formatTimeOfDay12Hr(endTime)}"),

                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),

                  // Location
                  Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      title: Row(
                        children: [
                          const Text("Location: "),
                          Expanded(
                            child: Text(
                              location == "Select Location"
                                  ? location
                                  : location,
                              style: TextStyle(color: MyColors.fontBlue),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.location_on),
                      onTap: () => _selectLocation(context),
                    ),
                  ),

                  // Create Visit Button
                  /*  ElevatedButton(
                    onPressed: _createVisit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), backgroundColor: MyColors.lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Create Visit",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),*/
                  ElevatedButton(
                    onPressed: isEditing ? _updateVisit : _createVisit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: MyColors.lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isEditing ? "Update Visit" : "Create Visit",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Previous Visits",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // List of Previous Visits
                  Container(
                    height: isTablet ? 700 : 300, // Adjust based on content
                    child: visitList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/icons/no_data.png",
                                  // Ensure this image is in assets
                                  height: 100,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "No Data Available",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: visitList.length,
                            itemBuilder: (context, index) {
                              final visit = visitList[index];

                              try {
                                // Parse the date
                                final visitDate = DateFormat('dd/MM/yyyy')
                                    .parse(visit.selectDate!);

                                // Parse the time in 12-hour format with AM/PM
                                final visitFromDateTime = DateFormat("hh:mm a")
                                    .parse(visit.fromtime!);
                                final visitToDateTime =
                                    DateFormat("hh:mm a").parse(visit.totime!);

                                // Combine parsed times with the visit date to create DateTime objects
                                final visitStartDateTime = DateTime(
                                  visitDate.year,
                                  visitDate.month,
                                  visitDate.day,
                                  visitFromDateTime.hour,
                                  visitFromDateTime.minute,
                                );

                                final visitEndDateTime = DateTime(
                                  visitDate.year,
                                  visitDate.month,
                                  visitDate.day,
                                  visitToDateTime.hour,
                                  visitToDateTime.minute,
                                );

                                final currentDate = DateTime.now();

                                /*        return Card(
                            elevation: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              title: Text("Visit Name: ${visit.reason}"),
                              subtitle: Text(
                                "Date: ${visit.selectDate}\nStart/End Time: ${visit.fromtime} - ${visit.totime}\nAddress: ${visit.destination}",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (currentDate.isBefore(visitStartDateTime))
                                    ElevatedButton.icon(
                                      onPressed: null, // Disabled button for upcoming visits
                                      icon: Icon(Icons.access_time, color: Colors.white),
                                      label: const Text(
                                        "Upcoming",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey, // Disabled state
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                  if (currentDate.isAfter(visitStartDateTime) &&
                                      currentDate.isBefore(visitEndDateTime))
                                    ElevatedButton.icon(
                                      onPressed: () => { _startVisit(visit)},
                                      icon: Icon(Icons.play_arrow, color: Colors.white),
                                      label: const Text(
                                        "Start Visit",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green, // Start Visit Button color
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                  if (currentDate.isAfter(visitEndDateTime))
                                    ElevatedButton.icon(
                                      onPressed: ()=>  getVisitLatLong(visit),
                                      icon: Icon(Icons.location_on, color: Colors.white),
                                      label: const Text(
                                        "Track Visit",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MyColors.lightBlue, // Track Visit Button color
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );*/
                                return Card(
                                  elevation: 5,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Left side - Visit Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Visit Name: ${visit.reason}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                // "Date: ${visit.selectDate}\nStart/End Time: ${visit.fromtime} - ${visit.totime}\nAddress: ${visit.destination}",
                                                "Date: ${visit.selectDate}\nStart/End Time: ${visit.fromtime} - ${visit.totime}\nAddress: ${visit.destination}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Right side - Actions
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // Edit & Delete Icons (small size, top-right)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (currentDate.isBefore(
                                                    visitStartDateTime))
                                                  IconButton(
                                                    onPressed: () =>
                                                        _edit(visit),
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blue,
                                                        size: 20),
                                                  ),
                                                if (currentDate
                                                    .isBefore(visitEndDateTime))
                                                  IconButton(
                                                    onPressed: () =>
                                                        _showDeleteConfirmationDialog(
                                                            context, visit),
                                                    icon: Icon(Icons.delete,
                                                        color: Colors.red[300],
                                                        size: 20),
                                                  ),
                                              ],
                                            ),

                                            // Status/Action Button (centered, below icons)
                                            Center(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  SizedBox(
                                                    width: 130,
                                                    child: currentDate.isBefore(
                                                            visitStartDateTime)
                                                        ? Builder(
                                                            builder: (context) {
                                                              final reminderId =
                                                                  visitStartDateTime
                                                                          .millisecondsSinceEpoch %
                                                                      2147483647;

                                                              // Schedule notification reminder (2 min before)
                                                              /* VisitReminderService.scheduleVisitReminder(
                                                    visitStartDateTime,
                                                    reminderId,
                                                  );*/

                                                              return Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  // Upcoming button
                                                                  ElevatedButton
                                                                      .icon(
                                                                    onPressed:
                                                                        null,
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .access_time,
                                                                        color: Colors
                                                                            .white),
                                                                    label:
                                                                        const Text(
                                                                      "Upcoming",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              13),
                                                                    ),
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .grey,
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              10),
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(20),
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  const SizedBox(
                                                                      height:
                                                                          4),

                                                                  // Auto Start Switch
/*
                                                      ValueListenableBuilder<bool>(
                                                        valueListenable: VisitState.isVisitStarted,
                                                        builder: (context, autoStartEnabled, _) {
                                                          return SwitchListTile(
                                                            dense: true,
                                                            contentPadding: EdgeInsets.zero,
                                                            title: const Text(
                                                              "Auto Start",
                                                              style: TextStyle(fontSize: 12),
                                                            ),
                                                            value: autoStartEnabled,
                                                            onChanged: (value) async {
                                                              if (value) {
                                                                // 1️⃣ Check Location "Always Allow" permission
                                                                bool locationGranted = await enableGPSWithPermission();
                                                                if (!locationGranted) {
                                                                  Fluttertoast.showToast(
                                                                    msg: "Please allow 'Always Allow' location access to enable Auto Start.",
                                                                    toastLength: Toast.LENGTH_LONG,
                                                                  );
                                                                  VisitState.isVisitStarted.value = false; // reset toggle
                                                                  return;
                                                                }

                                                                // 2️⃣ Check Notification permission
                                                                PermissionStatus notifStatus = await checkAndRequestNotificationPermission(context);
                                                                if (!notifStatus.isGranted) {
                                                                  Fluttertoast.showToast(
                                                                    msg: "Please allow notification permission for Auto Start reminders.",
                                                                    toastLength: Toast.LENGTH_LONG,
                                                                  );
                                                                  VisitState.isVisitStarted.value = false;
                                                                  return;
                                                                }

                                                                // 3️⃣ Check Battery Optimization (Android only)
                                                                if (Platform.isAndroid) {
                                                                  final ignoring = await BatteryOptimizationHelper.isIgnoring();
                                                                  if (!ignoring) {
                                                                    Fluttertoast.showToast(
                                                                      msg: "Battery optimization is ON. Please disable it for reliable Auto Start.",
                                                                      toastLength: Toast.LENGTH_LONG,
                                                                    );

                                                                    // Optionally open the settings page for the user
                                                                    await BatteryOptimizationHelper.requestIgnore();

                                                                    VisitState.isVisitStarted.value = false;
                                                                    return;
                                                                  }
                                                                }

                                                                // 4️⃣ If everything is okay → enable auto start
                                                                VisitState.isVisitStarted.value = true;

                                                                VisitReminderService.scheduleAutoStartVisit(
                                                                  visitStartDateTime,
                                                                  reminderId,
                                                                  visit,
                                                                );

                                                                Fluttertoast.showToast(
                                                                  msg: "✅ Auto Start enabled for ${visit.reason}",
                                                                  toastLength: Toast.LENGTH_SHORT,
                                                                );

                                                                LogFileManager.writeLog("✅ AutoStart enabled for ${visit.reason} at $visitStartDateTime");
                                                              } else {
                                                                // 5️⃣ When turned OFF → cancel auto start
                                                                VisitState.isVisitStarted.value = false;

                                                                // Cancel scheduled alarms & reminders
                                                                if (Platform.isAndroid) {
                                                                await AndroidAlarmManager.cancel(reminderId);          // cancel reminder
                                                                await AndroidAlarmManager.cancel(reminderId + 100000); // cancel auto-start alarm
                                                                }

                                                                // Remove stored auto-start data
                                                                final prefs = await SharedPreferences.getInstance();
                                                                await prefs.remove("autoStart_${reminderId + 100000}");
                                                                await storage.delete(key: 'AutoStartVisit');

                                                                Fluttertoast.showToast(
                                                                msg: "❌ Auto Start disabled for ${visit.reason}",
                                                                toastLength: Toast.LENGTH_SHORT,
                                                                );
                                                                LogFileManager.writeLog("❌ AutoStart disabled for ${visit.reason}");
                                                                }
                                                            },
                                                          );
                                                        },
                                                      ),
*/
                                                                ],
                                                              );
                                                            },
                                                          )

                                                        // Start Visit button (Active)
                                                        : currentDate.isAfter(
                                                                    visitStartDateTime) &&
                                                                currentDate
                                                                    .isBefore(
                                                                        visitEndDateTime)
                                                            ? ElevatedButton
                                                                .icon(
                                                                onPressed: () =>
                                                                    _startVisit(
                                                                        visit),
                                                                icon: const Icon(
                                                                    Icons
                                                                        .play_arrow,
                                                                    color: Colors
                                                                        .white),
                                                                label:
                                                                    const Text(
                                                                  "Start Visit",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          13),
                                                                ),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      Colors.green[
                                                                          400],
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            40),
                                                                  ),
                                                                ),
                                                              )

                                                            // Track Visit button (after visit)
                                                            : ElevatedButton
                                                                .icon(
                                                                onPressed: () =>
                                                                    getVisitLatLong(
                                                                        visit),
                                                                icon: const Icon(
                                                                    Icons
                                                                        .location_on,
                                                                    color: Colors
                                                                        .white),
                                                                label:
                                                                    const Text(
                                                                  "Track Visit",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          13),
                                                                ),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      MyColors
                                                                          .lightBlue,
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                  ),
                                                                ),
                                                              ),
                                                  )
                                                  /*SizedBox(
                                              width: 110, // Fixed width for button
                                              child: currentDate.isBefore(visitStartDateTime)
                                                  ? Builder(
                                              builder: (context) {
                                                // Generate safe 32-bit ID
                                                final reminderId =
                                                    visitStartDateTime
                                                        .millisecondsSinceEpoch %
                                                        2147483647;

                                                VisitReminderService.scheduleVisitReminder(
                                                  visitStartDateTime,
                                                  reminderId, // Safe ID
                                                );

                                                // 👇 Schedule auto-start  at visitStartDateTime
                                                 VisitReminderService.scheduleAutoStartVisit(
                                                  visitStartDateTime,
                                                  reminderId,
                                                );

                                                return ElevatedButton.icon(
                                                  onPressed: null,
                                                  icon: const Icon(Icons
                                                      .access_time,
                                                      color: Colors.white),
                                                  label: const Text("Upcoming",
                                                      style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 13)),
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor: Colors
                                                        .grey,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(20)),
                                                  ),
                                                );
                                              }
                                              )
                                                  : currentDate.isAfter(visitStartDateTime) && currentDate.isBefore(visitEndDateTime)
                                                  ? ElevatedButton.icon(
                                                onPressed: () => _startVisit(visit),
                                                icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                label: const Text("Start Visit", style: TextStyle(color: Colors.white, fontSize: 13)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green[400],
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                                ),
                                              )
                                                  : Padding(padding: EdgeInsets.symmetric(vertical: 28),
                                              child: ElevatedButton.icon(
                                                onPressed: () => getVisitLatLong(visit),
                                                icon: const Icon(Icons.location_on, color: Colors.white),
                                                label: const Text("Track Visit", style: TextStyle(color: Colors.white, fontSize: 13)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: MyColors.lightBlue,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                ),
                                              ),
                                              ),
                                            ),*/
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } catch (e) {
                                LogFileManager.writeLog(
                                    "Error parsing visit details: $e");
                                print("Error parsing visit details: $e");
                                return SizedBox(); // Return an empty widget on error
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: MyColors.lightBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> enableGPSWithPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    if (permission != LocationPermission.always) {
      if (Platform.isAndroid) {
        PermissionStatus bgStatus = await Permission.locationAlways.request();
        if (!bgStatus.isGranted) {
          await openAppSettings();
          return false;
        }
      } else if (Platform.isIOS) {
        Fluttertoast.showToast(
          msg: "Enable 'Always Allow' location access in Settings.",
        );
        await openAppSettings();
        return false;
      }
    }
    return true;
  }

  Future<PermissionStatus> checkAndRequestNotificationPermission(
      BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return status;

    final newStatus = await Permission.notification.request();
    return newStatus;
  }

  // void onDeleteVisit(Data visit) async {
  //   //String? runningVisitJson = await storage.read(key: 'SelectedVisit');
  //   // if (VisitState.isVisitRunning.value) {
  //   //   bool result = await showstopvisitdialogue(context);
  //   //   if (!result) {
  //   //     return;
  //   //   }
  //   // }
  //   if (VisitState.isVisitRunning.value &&
  //       VisitState.runningVisitSrNo == visit.srNo) {
  //     bool result = await showstopvisitdialogue(context);
  //     if (!result) return;
  //   }
  //
  //   await _deleteVisit(visit);
  // }
  void onDeleteVisit(Data visit) async {
    // 🔁 First check in-memory (fast path)
    if (VisitState.isVisitRunning.value &&
        VisitState.runningVisitSrNo == visit.srNo) {
      bool result = await showstopvisitdialogue(context);
      if (!result) return;
    }

    // 🔁 Fallback: check persisted state (after app restart)
    String? storedSrNo = await storage.read(key: 'RunningVisitSrNo');

    if (storedSrNo != null && storedSrNo == visit.srNo.toString()) {
      bool result = await showstopvisitdialogue(context);
      if (!result) return;
    }

    await _deleteVisit(visit);
  }

  Future<bool> showstopvisitdialogue(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Visit!!"),
          content: const Text("!! STARTED VISIT CANNOT BE DELETED !!"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("Ok"))
          ],
        );
      },
    );
    return result ?? false;
  }
}

class BatteryOptimizationHelper {
  static const platform = MethodChannel('battery_optimization');

  static Future<bool> isIgnoring() async {
    if (Platform.isAndroid) {
      try {
        final result =
            await platform.invokeMethod('isIgnoringBatteryOptimizations');
        return result == true;
      } catch (_) {}
    }
    return true;
  }

  static Future<void> requestIgnore() async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      } catch (_) {}
    }
  }
}

//fetchvisit abhishek's api
// Future<void> _fetchVisits() async {
//   setState(() {
//     isLoading= true;
//   });
//   try{
//     final response = await http.get(
//       Uri.parse('http://114.143.140.28:8091/api/Visit/GetAllVisit/$staffcode/1/50'),
//       headers: <String, String>{
//         // 'accept': '*/*', // Matches the cURL command
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token', // Ensure token is valid
//       },
//     );
//
//     print('fetch api response code: ${response.statusCode}');
//     print('Response body: ${response.body}');
//     if(response.statusCode == 200){
//       // final request = json.decode(response.body);
//       // VisitDataResoponse.fromJson(json.decode(response.body))
//       final VisitDataResoponse visitData = VisitDataResoponse.fromJson(json.decode(response.body));
//       /*if(response.body.isEmpty){   // for new user showing the empty list
//         return;
//       }*/
//       setState(() {
//         visitList = visitData.message!.data!;
//       });
//       if(visitData != null){
//         List<Data> visit = visitData.message!.data!;
//         print('_UpdateStopLatLong visitList: ${visit[0].srNo}');
//         if(_newVisitCreate){
//           _UpdateStopLatLong(visitList[0], _selectedLocation!.latitude, _selectedLocation!.longitude);
//           _newVisitCreate = false;
//         }
//       }
//     }else if(response.statusCode == 400) {
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   const SnackBar(content: Text("Failed to fetch visit details!. Session expired login again", style: TextStyle(fontSize: 16),)),
//       // );
//       Fluttertoast.showToast(
//         msg: "No Details Available",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.CENTER,
//         // timeInSecForIosWeb: 5,
//       );
//     }
//     else if(response.statusCode == 401){
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('UnAuthorized. Kindly Login Again!!'),
//           action: SnackBarAction(
//             label: 'Login Again',
//             onPressed: () {
//               isloggedIn=true;
//               Navigator.push(context,
//                   MaterialPageRoute(builder: (context) => SplashScreen()));
//             },
//           ),
//           duration: Duration(days: 365), // Make it sticky
//         ),
//       );
//      //
//      //  Fluttertoast.showToast(
//      //    msg: "Unauthorized!!",
//      //    toastLength: Toast.LENGTH_SHORT,
//      //    gravity: ToastGravity.CENTER,
//      //  );
//      // ///...
//     }
//     else{
//       Fluttertoast.showToast(
//         msg: "Error in Visit Schedule",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.CENTER,
//         // timeInSecForIosWeb: 5,
//       );
//     }
//   }catch(e){
//     print('Fetch visit error: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")));
//   }
//
//   setState(() {
//     isLoading= false;
//   });
// }

//Dhiraj sir savevisitdetails api
/*Future<void> _createVisit() async {
    if (_currentLocation == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location first")),
      );
      return;
    }

    print("Created visit: $nameOfVisit , start time: $startTime , end time: $endTime , "
        "picked lat - ${_selectedLocation!.latitude} , picked long - ${_selectedLocation!.longitude} , picked address: $_selectedAddress");

    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final String visitDate = dateFormat.format(selectedDate);
    try{
      final response = await http.post(
        Uri.parse("https://m-techinnovations.co.in/PersonTrackingAPI/API/SaveVisitDetails"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "EmpCode": staffcode,
          "VisitName": nameOfVisit,
          "VisitDate": visitDate,
          "StartTime": startTime.format(context),
          "EndTime": endTime.format(context),
          "CurrentLatitude": _currentLocation!.latitude.toString(),
          "CurrentLongitude": _currentLocation!.longitude.toString(),
          "CurrentAddress": _selectedAddress,   //change to destination address
          "SelectedLatitude": _selectedLocation!.latitude.toString(),
          "SelectedLongitude": _selectedLocation!.longitude.toString().substring(0, 7),
        }),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print("create visit response: $result");
        if (result[0]["OutPutResult"] == "Details Save Successfully") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Visit details saved successfully")),
          );
          _fetchVisits(); // Fetch updated visit list after saving
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${result['OutPutResult']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save visit details")),
        );
      }
    }catch(e){
      print("create visit api call: $e");
    }
  }*/

//Dhiraj sir fetchVisit API
/*Future<void> _fetchVisits() async {
    setState(() {
      isLoading= true;
    });
    final response = await http.post(
      Uri.parse("https://m-techinnovations.co.in/PersonTrackingAPI/API/GetVisitDetails"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"EmpCode": staffcode}),
    );

    if (response.statusCode == 201) {
      setState(() {
        visitList = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch visit details")),
      );
    }
    setState(() {
      isLoading= false;
    });
  }*/

/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../util/MyColor.dart';
import 'location_picker_screen.dart';

class VisitOutside extends StatefulWidget {
  const VisitOutside({super.key});

  @override
  State<VisitOutside> createState() => _VisitOutsideState();
}

class _VisitOutsideState extends State<VisitOutside> {

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String location = 'Select Location';
  String nameOfVisit = '';

  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String? _selectedAddress;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    ) ?? selectedDate;

    setState(() {
      selectedDate = picked;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime : endTime,
    ) ?? TimeOfDay.now();

    setState(() {
      if (isStartTime) {
        startTime = picked;
      } else {
        endTime = picked;
      }
    });
  }

  void _selectLocation(BuildContext context) async {
    final result = await Navigator.push( context, MaterialPageRoute( builder: (context) => LocationPickerScreen(),),);

    if (result != null) {
      setState(() {
        _selectedLocation = result['pickedLocation'];
        _currentLocation = result['currentLocation'];
        _selectedAddress = result['pickedAddress'];
        location = "$_selectedAddress";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),

          title: const Text("Visit OutSide"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(
            color: Colors.white,
          )
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text("Name of Visit: "),
              trailing: Container(
                height: 30,
                width: 150,
                child: Expanded( child:
                TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'Enter name',
                  ),
                  onChanged: (text) {
                    nameOfVisit = text;
                  },
                ),
                ),
              ),
            ),
            ListTile(
              title: Text("Select Date: ${DateFormat.yMMMd().format(selectedDate)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              title: Text("Start Time: ${startTime.format(context)}"),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(context, true),
            ),
            ListTile(
              title: Text("End Time: ${endTime.format(context)}"),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(context, false),
            ),
            ListTile(
              title: Row( children: [
                Text("Location: "),
                location == "Select Location" ? Text(location) : Text(location, style: TextStyle(color: MyColors.fontBlue),),
              ],),
              trailing: Icon(Icons.location_on),
              onTap: () => _selectLocation(context),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Create Visit"),
              onPressed: () {
                // Handle visit creation
                print("Visit Created");
              },
            ),

          ],
        ),
      ),
    );
  }
}
*/

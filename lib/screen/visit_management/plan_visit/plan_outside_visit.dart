import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/model/VisitData/fetch_visit_data.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitDetailedRecordsResponse.dart' as visitValues;
import 'package:attendance_system_ios/screen/Splash Screen/splash_screen.dart';
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
import 'package:shimmer/shimmer.dart';

import '../../../bloc/main_bloc.dart';
import '../../../main.dart';
import '../../../service/WebService.dart';
import '../../../util/MyColor.dart';
import '../visit_history/visit_history_track.dart';
import '../start_stop_visit/start_stop_visit.dart';
import 'location_picker_screen.dart';

class VisitOutside extends StatefulWidget {
  const VisitOutside({super.key});

  @override
  State<VisitOutside> createState() => _VisitOutsideState();
}

class _VisitOutsideState extends State<VisitOutside> {
  late MainBloc mainBloc;
  late List<visitValues.Message> latLongList = [];
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final TextEditingController nameController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

  String location = 'Select Location';
  String nameOfVisit = '';
  String? staffcode = "";
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
  bool isTablet = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _fetchStorage();
    await _fetchVisits();
  }

  Future<void> _fetchStorage() async {
    staffcode = await storage.read(key: 'username');
    token = await storage.read(key: 'Auth_Token');
  }

  void clearFields() {
    setState(() {
      selectedDate = DateTime.now();
      startTime = TimeOfDay.now();
      endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
      location = 'Select Location';
      _selectedAddress = null;
      _selectedLocation = null;
      nameController.clear();
      nameOfVisit = '';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 15)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MyColors.lightBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MyColors.lightBlue,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
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

  void _selectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  LocationPickerScreen(
        initialLocation: _selectedLocation,
        initialAddress: location == 'Select Location' ? null : location,
      )),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['pickedLocation'];
        _currentLocation = result['currentLocation'];
        _selectedAddress = result['pickedAddress'];
        _currentAddress = result['currentAddress'];
        location = "$_selectedAddress";
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createVisit() async {
    final DateTime selectedStartDateTime = _combineDateAndTime(selectedDate, startTime);
    final DateTime now = DateTime.now();

    if (nameOfVisit.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Enter Visit Name!!");
      return;
    }
    if (nameOfVisit.trim().length < 3) {
      Fluttertoast.showToast(msg: "Please enter valid visit name");
      return;
    }

    if (selectedStartDateTime.isBefore(now.subtract(const Duration(minutes: 5)))) {
      Fluttertoast.showToast(msg: "Start time cannot be earlier than current time!");
      return;
    }

    final DateTime startDT = _combineDateAndTime(DateTime.now(), startTime);
    final DateTime endDT = _combineDateAndTime(DateTime.now(), endTime);

    if (startDT.isAfter(endDT)) {
      Fluttertoast.showToast(msg: "Start time cannot be greater than End time!!");
      return;
    }

    if (startDT.isAtSameMomentAs(endDT)) {
      Fluttertoast.showToast(msg: "Start time and end time cannot be the same!");
      return;
    }

    Duration difference = endDT.difference(startDT);
    if (difference.inMinutes < 10) {
      Fluttertoast.showToast(msg: "There should be at least a 10-minute gap between start and end time!");
      return;
    }

    if (_selectedLocation == null || location == 'Select Location') {
      Fluttertoast.showToast(msg: "Please select a location first!!");
      return;
    }

    final String formatedSelectedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
    final String visitDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/Visit/InsertVisit'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          "userId": staffcode,
          "selectDate": formatedSelectedDate,
          "fromTime": formatTimeOfDay12Hr(startTime),
          "toTime": formatTimeOfDay12Hr(endTime),
          "reason": nameOfVisit,
          "source": _currentAddress ?? "Unknown",
          "destination": _selectedAddress,
          "status": "I",
          "visitDate": visitDate
        }),
      );

      if (response.statusCode == 200) {
        if (response.body == 'Record inserted Successfully.') {
          Fluttertoast.showToast(msg: "Visit details saved successfully");
          _newVisitCreate = true;
          _fetchVisits();
          clearFields();
        } else {
          Fluttertoast.showToast(msg: "Error: ${response.body}");
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        Fluttertoast.showToast(msg: "Failed to save visit. Please try again.");
      }
    } catch (e) {
      LogFileManager.writeLog("create visit api call error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleUnauthorized() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session expired. Kindly Login Again!!'),
        action: SnackBarAction(
          label: 'Login',
          onPressed: () {
            isloggedIn = true;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen()));
          },
        ),
        duration: const Duration(days: 365),
      ),
    );
  }

  Future<void> _fetchVisits() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://114.143.140.28:8020/api/Visit/GetAllVisit/$staffcode/1/50'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final VisitDataResoponse visitData = VisitDataResoponse.fromJson(json.decode(response.body));
        setState(() {
          visitList = visitData.message?.data ?? [];
        });

        if (visitList.isNotEmpty && _newVisitCreate && _selectedLocation != null) {
          _UpdateStopLatLong(visitList[0], _selectedLocation!.latitude, _selectedLocation!.longitude);
          _newVisitCreate = false;
        }
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      }
    } catch (e) {
      debugPrint('Fetch visit error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _UpdateStopLatLong(Data visit, double latitude, double longitude) async {
    try {
      await http.post(
        Uri.parse("http://114.143.140.28:8020/api/Visit/UpdateStatusStopLatLong/${visit.srNo}/$latitude/$longitude/I"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('UpdateStopLatLong error: $e');
    }
  }

  Future<void> _startVisit(Data visit) async {
    String? storedSrNo = await storage.read(key: 'RunningVisitSrNo');

    if (storedSrNo != null && storedSrNo != visit.srNo.toString()) {
      Fluttertoast.showToast(msg: "A visit is already running. Please stop it first.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VisitStartStopScreen(visit: visit)),
    );
  }

  Future<void> _updateVisit() async {
    if (selectedVisitt == null) return;
    final visitName = nameController.text.trim();

    if (visitName.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Visit Name!!");
      return;
    }

    final DateTime startDT = _combineDateAndTime(DateTime.now(), startTime);
    final DateTime endDT = _combineDateAndTime(DateTime.now(), endTime);

    if (startDT.isAfter(endDT)) {
      Fluttertoast.showToast(msg: "Start time cannot be greater than End time!!");
      return;
    }

    if (startDT.isAtSameMomentAs(endDT)) {
      Fluttertoast.showToast(msg: "Start time and end time cannot be the same!");
      return;
    }

    Duration difference = endDT.difference(startDT);
    if (difference.inMinutes < 10) {
      Fluttertoast.showToast(msg: "There should be at least a 10-minute gap!");
      return;
    }

    setState(() => isLoading = true);

    try {
      final String formatedSelectedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
      final String visitDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/Visit/UpdateVisit"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          "srNo": selectedVisitt!.srNo.toString(),
          "userId": staffcode,
          "selectDate": formatedSelectedDate,
          "fromTime": formatTimeOfDay12Hr(startTime),
          "toTime": formatTimeOfDay12Hr(endTime),
          "reason": nameController.text,
          "source": _currentAddress ?? selectedVisitt!.source,
          "destination": _selectedAddress ?? selectedVisitt!.destination,
          "status": "I",
          "visitDate": visitDate
        }),
      );

      if (response.statusCode == 200) {
        _fetchVisits();
        setState(() {
          isEditing = false;
          selectedVisitt = null;
          clearFields();
        });
        Fluttertoast.showToast(msg: "Visit details updated successfully");
      } else {
        Fluttertoast.showToast(msg: "Error updating details");
      }
    } catch (e) {
      LogFileManager.writeLog("update visit error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _edit(Data visit) {
    setState(() {
      isEditing = true;
      selectedVisitt = visit;
      nameController.text = visit.reason ?? "";
      nameOfVisit = visit.reason ?? "";
      selectedDate = DateFormat('dd/MM/yyyy').parse(visit.selectDate!);
      startTime = TimeOfDay.fromDateTime(DateFormat("hh:mm a").parse(visit.fromtime!));
      endTime = TimeOfDay.fromDateTime(DateFormat("hh:mm a").parse(visit.totime!));
      location = visit.destination ?? "Select Location";
      _selectedAddress = visit.destination;
      _currentAddress = visit.source;
    });
  }

  void _showDeleteConfirmation(Data visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Visit"),
        content: const Text("Are you sure you want to delete this visit schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVisit(visit);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVisit(Data visit) async {
    if (VisitState.isVisitRunning.value && VisitState.runningVisitSrNo == visit.srNo) {
      Fluttertoast.showToast(msg: "Started visit cannot be deleted!");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/Visit/DeleteVisitRecords?UserId=$staffcode&srNo=${visit.srNo}"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: response.body);
        if (selectedVisitt?.srNo == visit.srNo) {
          setState(() {
            isEditing = false;
            selectedVisitt = null;
            clearFields();
          });
        }
        _fetchVisits();
      }
    } catch (e) {
      debugPrint("Delete visit error: $e");
    }
  }

  Future<void> _getVisitLatLong(Data visit) async {
    setState(() => isLoading = true);
    try {
      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(visit.selectDate!);
      String formattedDate = DateFormat("dd-MMM-yyyy").format(parsedDate);

      final response = await http.get(
        Uri.parse("http://114.143.140.28:8020/api/Visit/GetVisitRecords?StaffCode=$staffcode&FromDate=$formattedDate&ToDate=$formattedDate&SrNoVal=${visit.srNo}"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] is List) {
          latLongList = (responseData['message'] as List).map((item) => visitValues.Message.fromJson(item)).toList();
        }

        if (latLongList.isEmpty) {
          Fluttertoast.showToast(msg: 'Visit not started or no records found.');
          return;
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => MainBloc(webService: WebService()),
              child: VisitHistoryTrackScreen(latLongList: latLongList),
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "Visit records not found.");
      }
    } catch (e) {
      LogFileManager.writeLog("GetVisitRecords error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      // backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? "Edit Visit" : "Plan Outside Visit",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildInputSection(),
                _buildPreviousVisitsHeader(),
                _buildVisitList(),
                const SizedBox(height: 30),
              ],
            ),
          ),
          // if (isLoading)
          //   Container(
          //     color: Colors.black26,
          //     child: const Center(
          //       child: CircularProgressIndicator(color: MyColors.lightBlue),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      // decoration: const BoxDecoration(
      //   color: MyColors.lightBlue,
      //   borderRadius: BorderRadius.only(
      //     bottomLeft: Radius.circular(30),
      //     bottomRight: Radius.circular(30),
      //   ),
      // ),
      child: Card(
        elevation: 0,
        color: Colors.blue[100]?.withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Visit Purpose / Route"),
              TextField(
                controller: nameController,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))],
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.edit_note_rounded, color: MyColors.lightBlue, size: 20),
                  hintText: "e.g. Office to Client Site",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: MyColors.lightBlue)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: Colors.grey.shade50,
                  filled: true,
                ),
                onChanged: (val) => nameOfVisit = val,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: "Date",
                      value: DateFormat('dd MMM yyyy').format(selectedDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: "Start Time",
                      value: formatTimeOfDay12Hr(startTime),
                      icon: Icons.access_time_rounded,
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      label: "End Time",
                      value: formatTimeOfDay12Hr(endTime),
                      icon: Icons.access_time_filled_rounded,
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPickerTile(
                label: "Destination Location",
                value: location,
                icon: Icons.location_on_rounded,
                onTap: () => _selectLocation(context),
                isHighlight: location != 'Select Location',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isEditing ? _updateVisit : _createVisit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: MyColors.lightBlue.withOpacity(0.4),
                  ),
                  child: Text(
                    isEditing ? "Update Visit" : "Plan Visit",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
              if (isEditing)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                          selectedVisitt = null;
                          clearFields();
                        });
                      },
                      label: const Text("Cancel Editing", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: isHighlight ? MyColors.lightBlue.withOpacity(0.5) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isHighlight ? [BoxShadow(color: MyColors.lightBlue.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: MyColors.lightBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                      color: isHighlight ? MyColors.lightBlue : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousVisitsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: MyColors.lightBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Scheduled Visits",
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          if (visitList.isNotEmpty)
            Text(
              "${visitList.length} Records",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildVisitList() {

    /// 🔥 SHOW SHIMMER WHILE LOADING
    if (isLoading) {
      return _buildVisitListShimmer();
    }

    if (visitList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/icons/no_data.png", height: 100, opacity: const AlwaysStoppedAnimation(0.5)),
              const SizedBox(height: 16),
              Text("No visits planned yet", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: visitList.length,
      itemBuilder: (context, index) => _buildVisitCard(visitList[index]),
    );
  }

  Widget _buildVisitCard(Data visit) {
    DateTime visitDate;
    DateTime visitStartDT;
    DateTime visitEndDT;
    final now = DateTime.now();

    try {
      visitDate = DateFormat('dd/MM/yyyy').parse(visit.selectDate!);
      final start = DateFormat("hh:mm a").parse(visit.fromtime!);
      final end = DateFormat("hh:mm a").parse(visit.totime!);

      visitStartDT = DateTime(visitDate.year, visitDate.month, visitDate.day, start.hour, start.minute);
      visitEndDT = DateTime(visitDate.year, visitDate.month, visitDate.day, end.hour, end.minute);
    } catch (e) {
      return const SizedBox();
    }

    bool isUpcoming = now.isBefore(visitStartDT.subtract(const Duration(minutes: 0)));
    bool isOngoing = now.isAfter(visitStartDT.subtract(const Duration(minutes: 0))) && now.isBefore(visitEndDT);
    bool isCompleted = now.isAfter(visitEndDT);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        children: [
          Divider(thickness: 3, color: isCompleted ? Colors.grey : Colors.green,),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildStatusIndicator(isUpcoming, isOngoing, isCompleted),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          visit.reason ?? "Unnamed Visit",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.calendar_today_outlined, visit.selectDate!, size: 13),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.access_time_outlined, "${visit.fromtime} - ${visit.totime}", size: 13),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.location_on_outlined, visit.destination ?? "No destination address", size: 13),
                    ],
                  ),
                ),
                if(isUpcoming)
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _showDeleteConfirmation(visit),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _edit(visit),
                          icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                if (isOngoing)
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _showDeleteConfirmation(visit),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: _buildActionButton(visit, isUpcoming, isOngoing, isCompleted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {double size = 13}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: size + 2, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: size, color: Colors.grey.shade600, fontWeight: FontWeight.w400),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Data visit, bool isUpcoming, bool isOngoing, bool isCompleted) {
    if (isUpcoming) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
                "Scheduled",
                style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 14)
            ),
          ],
        ),
      );
    } else if (isOngoing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startVisit(visit),
          icon: const Icon(Icons.play_circle_fill, size: 18),
          label: Text("START TRACKING", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      );

    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _getVisitLatLong(visit),
          icon: const Icon(Icons.map_rounded, size: 18),
          label: Text("VIEW TRACKING HISTORY", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: MyColors.lightBlue,
            side: const BorderSide(color: MyColors.lightBlue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
  }

  // Shimmer loading logic for visit list

  Widget _buildVisitListShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4, // skeleton count
      itemBuilder: (context, index) => _buildVisitCardShimmer(),
    );
  }
  Widget _buildVisitCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [

            /// Top divider
            Container(
              height: 3,
              width: double.infinity,
              color: Colors.white,
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(width: 16),

                  /// LEFT CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// Title
                        Container(
                          height: 16,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Date
                        _shimmerLine(120),

                        const SizedBox(height: 6),

                        /// Time
                        _shimmerLine(160),

                        const SizedBox(height: 6),

                        /// Location
                        _shimmerLine(180),
                      ],
                    ),
                  ),

                  /// RIGHT ICON PLACEHOLDER
                  Column(
                    children: [
                      _shimmerCircle(),
                      const SizedBox(height: 20),
                      _shimmerCircle(),
                    ],
                  ),
                ],
              ),
            ),

            /// Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _shimmerLine(double width) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  Widget _shimmerCircle() {
    return Container(
      height: 36,
      width: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

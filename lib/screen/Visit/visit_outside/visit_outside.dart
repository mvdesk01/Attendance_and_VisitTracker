import 'dart:convert';
import 'dart:io';
import 'package:attendance_system_ios/model/VisitData/fetch_visit_data.dart';
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
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../../../bloc/main_bloc.dart';
import '../../../main.dart';
import '../../../service/WebService.dart';
import '../../../util/MyColor.dart';
import '../Start Stop Visit/start_stop_visit.dart';
import 'location_picker_screen.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitDetailedRecordsResponse.dart' as visitValues;
import '../../Visit History/VisitHistoryTrack_Screen.dart';

class VisitOutside extends StatefulWidget {
  const VisitOutside({super.key});

  @override
  State<VisitOutside> createState() => _VisitOutsideState();
}

class _VisitOutsideState extends State<VisitOutside> {
  late MainBloc mainBloc;
  late List<visitValues.Message> latLongList = [];
  final storage = const FlutterSecureStorage();
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
  bool isTablet = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchStorage();
    await _fetchVisits();
  }

  Future<void> _fetchStorage() async {
    staffcode = await storage.read(key: 'username');
    token = await storage.read(key: 'Auth_Token');
  }

  Future<void> _fetchVisits() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://114.143.140.28:8020/api/Visit/GetAllVisit/$staffcode/1/50'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final VisitDataResoponse visitData = VisitDataResoponse.fromJson(json.decode(response.body));
        if (mounted) {
          setState(() {
            visitList = visitData.message?.data ?? [];
          });
          if (visitList.isNotEmpty && _newVisitCreate) {
            _UpdateStopLatLong(visitList[0], _selectedLocation!.latitude, _selectedLocation!.longitude);
            _newVisitCreate = false;
          }
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          isloggedIn = true;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen()));
        }
      }
    } catch (e) {
      LogFileManager.writeLog("Fetch visit error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _UpdateStopLatLong(Data visit, double latitude, double longitude) async {
    try {
      await http.post(
        Uri.parse("http://114.143.140.28:8020/api/Visit/UpdateStatusStopLatLong/${visit.srNo}/${latitude.toString()}/${longitude.toString()}/I"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      LogFileManager.writeLog('UpdateStopLatLong Error: $e');
    }
  }

  void _selectLocation(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPickerScreen()));
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
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

  void clearFields() {
    setState(() {
      selectedDate = DateTime.now();
      startTime = TimeOfDay.now();
      endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
      location = 'Select Location';
      nameController.clear();
      nameOfVisit = '';
      _selectedLocation = null;
      _selectedAddress = null;
    });
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool _validateTimes() {
    final startDateTime = _combineDateTime(selectedDate, startTime);
    final endDateTime = _combineDateTime(selectedDate, endTime);
    final now = DateTime.now();

    if (startDateTime.isBefore(now.subtract(const Duration(minutes: 10)))) {
      Fluttertoast.showToast(msg: "Start time cannot be more than 10 minutes in the past");
      return false;
    }

    final duration = endDateTime.difference(startDateTime);
    if (duration.inMinutes < 10) {
      if (endDateTime.isBefore(startDateTime)) {
        Fluttertoast.showToast(msg: "End time must be after start time");
      } else {
        Fluttertoast.showToast(msg: "Minimum 10 minutes gap required between start and end time");
      }
      return false;
    }

    return true;
  }

  Future<void> _createVisit() async {
    if (nameOfVisit.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Enter Visit Purpose");
      return;
    }
    if (location == 'Select Location' || _selectedLocation == null) {
      Fluttertoast.showToast(msg: "Select Destination Location");
      return;
    }

    if (!_validateTimes()) return;

    setState(() => isLoading = true);
    final String formattedSelectedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
    final String visitDateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    try {
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/Visit/InsertVisit'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          "userId": staffcode,
          "selectDate": formattedSelectedDate,
          "fromTime": formatTimeOfDay12Hr(startTime),
          "toTime": formatTimeOfDay12Hr(endTime),
          "reason": nameOfVisit,
          "source": _currentAddress ?? "Current Location",
          "destination": _selectedAddress,
          "status": "I",
          "visitDate": visitDateStr
        }),
      );

      if (response.statusCode == 200) {
        if (response.body.contains('Successfully')) {
          _newVisitCreate = true;
          await _fetchVisits();
          clearFields();
          Fluttertoast.showToast(msg: "Visit scheduled successfully");
        }
      }
    } catch (e) {
      LogFileManager.writeLog("Create visit error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateVisit() async {
    if (selectedVisitt == null) return;
    if (!_validateTimes()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/Visit/UpdateVisit"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          "srNo": selectedVisitt!.srNo.toString(),
          "userId": staffcode,
          "selectDate": DateFormat('dd/MM/yyyy').format(selectedDate),
          "fromTime": formatTimeOfDay12Hr(startTime),
          "toTime": formatTimeOfDay12Hr(endTime),
          "reason": nameController.text,
          "source": _currentAddress ?? selectedVisitt!.source,
          "destination": location,
          "status": "I",
          "visitDate": DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())
        }),
      );

      if (response.statusCode == 200) {
        await _fetchVisits();
        setState(() {
          isEditing = false;
          selectedVisitt = null;
          clearFields();
        });
        Fluttertoast.showToast(msg: "Visit updated successfully");
      }
    } catch (e) {
      LogFileManager.writeLog("Update visit error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDeleteConfirmation(Data visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Delete Visit", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete this scheduled visit?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVisit(visit);
            },
            child: Text("DELETE", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVisit(Data visit) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://114.143.140.28:8020/api/Visit/DeleteVisitRecords?UserId=$staffcode&srNo=${visit.srNo}"),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Visit deleted");
        _fetchVisits();
      }
    } catch (e) {
      LogFileManager.writeLog("Delete visit error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> getVisitLatLong(Data visit) async {
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
          Fluttertoast.showToast(msg: 'No tracking data available for this visit');
          return;
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: VisitHistoryTrackScreen(latLongList: latLongList),
            ),
          ),
        );
      }
    } catch (e) {
      LogFileManager.writeLog("GetVisitRecords Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      // backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp, color: Colors.white, fontWeight: FontWeight.bold,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Plan Outside Visit", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Form Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 30),
                      Text("Scheduled Visits", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Visit List Section
              visitList.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
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
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildVisitItem(visitList[index]),
                          childCount: visitList.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: MyColors.lightBlue)),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100),),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInputField(
              controller: nameController,
              label: "Purpose of Visit",
              hint: "e.g. Client Meeting at Hinjewadi",
              icon: Icons.edit_note_rounded,
              onChanged: (v) => nameOfVisit = v,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSelectorField(
                    label: "Date",
                    value: DateFormat('dd/MM/yyyy').format(selectedDate),
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
                  child: _buildSelectorField(
                    label: "Start Time",
                    value: formatTimeOfDay12Hr(startTime),
                    icon: Icons.access_time_rounded,
                    onTap: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectorField(
                    label: "End Time",
                    value: formatTimeOfDay12Hr(endTime),
                    icon: Icons.access_time_filled_rounded,
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSelectorField(
              label: "Destination Location",
              value: location,
              icon: Icons.location_on_rounded,
              isHighlight: location != 'Select Location',
              onTap: () => _selectLocation(context),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.lightBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: isEditing ? _updateVisit : _createVisit,
                child: Text(
                  isEditing ? "UPDATE SCHEDULE" : "PLAN VISIT",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            if (isEditing)
              TextButton(
                onPressed: clearFields,
                child: Text("Cancel Edit", style: GoogleFonts.poppins(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, required IconData icon, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: MyColors.lightBlue, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: MyColors.lightBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorField({required String label, required String value, required IconData icon, required VoidCallback onTap, bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: MyColors.lightBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isHighlight ? MyColors.fontBlue : Colors.black87,
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

  Widget _buildVisitItem(Data visit) {
    final visitDate = DateFormat('dd/MM/yyyy').parse(visit.selectDate!);
    final visitFromTime = DateFormat("hh:mm a").parse(visit.fromtime!);
    final visitToTime = DateFormat("hh:mm a").parse(visit.totime!);

    final startDateTime = DateTime(visitDate.year, visitDate.month, visitDate.day, visitFromTime.hour, visitFromTime.minute);
    final endDateTime = DateTime(visitDate.year, visitDate.month, visitDate.day, visitToTime.hour, visitToTime.minute);
    final now = DateTime.now();

    bool isUpcoming = now.isBefore(startDateTime);
    bool isActive = now.isAfter(startDateTime) && now.isBefore(endDateTime);
    bool isCompleted = now.isAfter(endDateTime);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: Column(
        children: [
          // Header Color Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isUpcoming ? Colors.orange : (isActive ? Colors.green : Colors.grey),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        visit.reason ?? "Unnamed Visit",
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    if (isUpcoming)
                      Row(
                        children: [
                          IconButton(onPressed: () => _edit(visit), icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue)),
                          IconButton(onPressed: () => _showDeleteConfirmation(visit), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildVisitInfoRow(Icons.calendar_today_rounded, visit.selectDate ?? ""),
                const SizedBox(height: 4),
                _buildVisitInfoRow(Icons.access_time_rounded, "${visit.fromtime} - ${visit.totime}"),
                const SizedBox(height: 4),
                _buildVisitInfoRow(Icons.place_outlined, visit.destination ?? "No destination"),
                const SizedBox(height: 16),
                _buildVisitActionButton(visit, isUpcoming, isActive, isCompleted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }

  Widget _buildVisitActionButton(Data visit, bool isUpcoming, bool isActive, bool isCompleted) {
    if (isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VisitStartStopScreen(visit: visit))),
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
    } else if (isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => getVisitLatLong(visit),
          icon: const Icon(Icons.map_rounded, size: 18),
          label: Text("VIEW TRACKING HISTORY", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: MyColors.lightBlue,
            side: const BorderSide(color: MyColors.lightBlue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(
            "UPCOMING VISIT",
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
          ),
        ),
      );
    }
  }

  Future<void> _edit(Data visit) async {
    setState(() {
      isEditing = true;
      selectedVisitt = visit;
      nameController.text = visit.reason ?? "";
      nameOfVisit = visit.reason ?? "";
      selectedDate = DateFormat('dd/MM/yyyy').parse(visit.selectDate!);
      startTime = TimeOfDay.fromDateTime(DateFormat("hh:mm a").parse(visit.fromtime!));
      endTime = TimeOfDay.fromDateTime(DateFormat("hh:mm a").parse(visit.totime!));
      location = visit.destination ?? "Select Location";
    });
    // Scroll to top to see the edit form
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import '../../bloc/main_bloc.dart';
import '../../model/in_out_details.dart';
import '../../service/WebService.dart';

class AttendanceReport extends StatefulWidget {
  const AttendanceReport({super.key});

  @override
  State<AttendanceReport> createState() => _AttendanceReportState();
}

class _AttendanceReportState extends State<AttendanceReport> {
  final storage = const FlutterSecureStorage();
  String? staffCode;
  String? token;
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool isGridView = false;
  bool isMonthlyReport = false;
  Map<String, List<InOutDetail>> groupedInOutDetails = {};
  List<InOutDetail> selectedDayDetails = [];

  DateTime today = DateTime.now();
  DateTime? focusedDay;
  DateTime? selectedDay;
  Map<DateTime, List<InOutDetail>> attendanceData = {};
  Set<DateTime> presentDays = {};
  Set<DateTime> absentDays = {};

  @override
  void initState() {
    super.initState();
    focusedDay = DateTime.now();
    selectedDay = focusedDay;
    initialize();
  }

  Future<void> initialize() async {
    await fetchData();
    await _fetchTodayData();
    await fetchAttendanceDataMonthlyReport();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    if (attendanceData.containsKey(normalizedToday)) {
      setState(() {
        selectedDayDetails = attendanceData[normalizedToday]!;
      });
    }
  }

  Future<void> fetchData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    token = await storage.read(key: 'Auth_Token');
  }

  Future<void> _fetchTodayData() async {
    setState(() {
      fromDate = today;
      toDate = today;
    });
    await fetchInOutDetails();
  }

  Future<void> fetchAttendanceDataMonthlyReport() async {
    try {
      setState(() => isLoading = true);
      DateTime now = DateTime.now();
      DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/InOut/InOutDetails'),
        headers: {"Content-Type": "application/json", 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          "staffCode": staffCode,
          "fromDate": DateFormat('dd/MM/yyyy').format(sixMonthsAgo),
          "toDate": DateFormat('dd/MM/yyyy').format(now),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        List<dynamic> data = decoded['data'] ?? [];
        List<InOutDetail> details = data.map((item) => InOutDetail.fromJson(item)).toList();

        attendanceData.clear();
        presentDays.clear();
        absentDays.clear();

        for (var detail in details) {
          DateTime date = DateFormat('dd/MM/yyyy HH:mm:ss').parse(detail.transactionTime!).toLocal();
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);
          presentDays.add(normalizedDate);
          if (!attendanceData.containsKey(normalizedDate)) attendanceData[normalizedDate] = [];
          attendanceData[normalizedDate]!.add(detail);
        }

        for (int i = 0; i < 180; i++) {
          DateTime day = sixMonthsAgo.add(Duration(days: i));
          if (!presentDays.contains(day) && day.isBefore(now)) absentDays.add(day);
        }
      }
    } catch (e) {
      LogFileManager.writeLog("Monthly Report Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchInOutDetails() async {
    if (fromDate == null || toDate == null) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://114.143.140.28:8020/api/InOut/InOutDetails'),
        headers: {"Content-Type": "application/json", 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          "staffCode": staffCode,
          "fromDate": DateFormat('dd/MM/yyyy').format(fromDate!),
          "toDate": DateFormat('dd/MM/yyyy').format(toDate!),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        List<dynamic> data = decoded['data'] ?? [];
        List<InOutDetail> details = data.map((item) => InOutDetail.fromJson(item)).toList();
        groupedInOutDetails = _groupByDate(details);
      }
    } catch (e) {
      LogFileManager.writeLog("InOutDetails Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<String, List<InOutDetail>> _groupByDate(List<InOutDetail> details) {
    Map<String, List<InOutDetail>> groupedData = {};
    for (var detail in details) {
      String date = detail.transactionTime!.substring(0, 10);
      if (!groupedData.containsKey(date)) groupedData[date] = [];
      groupedData[date]!.add(detail);
    }
    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => MainBloc(webService: WebService()), child: const HomeScreen()))),
        ),
        title: Text("Attendance Report", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildToggleHeader(),
          Expanded(child: isMonthlyReport ? _buildCalendarView() : _buildDailyListView()),
        ],
      ),
    );
  }

  Widget _buildToggleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton("Daily", !isMonthlyReport, () => setState(() => isMonthlyReport = false)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildToggleButton("Monthly", isMonthlyReport, () => setState(() => isMonthlyReport = true)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? MyColors.lightBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(color: active ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: MyColors.lightBlue));
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: focusedDay ?? DateTime.now(),
            selectedDayPredicate: (day) => isSameDay(selectedDay!, day),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: MyColors.appDefaultColorCode, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: MyColors.appDefaultColorCode.withOpacity(0.3), shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final normalized = DateTime(day.year, day.month, day.day);
                if (presentDays.any((d) => isSameDay(d, normalized))) return _buildCalendarCell(day, Colors.green);
                if (absentDays.any((d) => isSameDay(d, normalized))) return _buildCalendarCell(day, Colors.red);
                return null;
              },
            ),
            onDaySelected: (sel, foc) {
              setState(() {
                selectedDay = DateTime(sel.year, sel.month, sel.day);
                focusedDay = foc;
                selectedDayDetails = attendanceData[selectedDay] ?? [];
              });
            },
          ),
          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 20),
          // if (selectedDay != null)
          _buildSelectedDayDetails()
        ],
      ),
    );
  }


  Widget _buildCalendarCell(DateTime day, Color color) {
    return Center(
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
        child: Center(child: Text('${day.day}', style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
      ),
    );
  }

  Widget _buildLegend() {
    int count = _getPresentDaysCount(selectedDay ?? DateTime.now());
    // int count = presentDays.where((d) => d.year == focusedDay!.year && d.month == focusedDay!.month).length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem("Present", Colors.green, "($count)"),
          _legendItem("Absent", Colors.red, ""),
        ],
      ),
    );
  }


  int _getPresentDaysCount(DateTime day) {
    return presentDays
        .where((date) => date.year == day.year && date.month == day.month)
        .toSet()
        .length;
  }

  Widget _legendItem(String label, Color color, String count) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text("$label $count", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))]);
  }

  Widget _buildSelectedDayDetails() {
    Duration totalDuration = Duration.zero;
    if (selectedDayDetails.isNotEmpty) {
      try {
        List<InOutDetail> sorted = List.from(selectedDayDetails);
        sorted.sort((a, b) => a.transactionTime!.compareTo(b.transactionTime!));

        DateTime start = DateFormat('dd/MM/yyyy HH:mm:ss').parse(sorted.first.transactionTime!).toLocal();
        DateTime end = DateFormat('dd/MM/yyyy HH:mm:ss').parse(sorted.last.transactionTime!).toLocal();
        totalDuration = end.difference(start);
      } catch (e) {
        print("Error calculating duration: $e");
      }
    }

    String durationStr = "${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m";

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Logs for ${DateFormat('dd MMM yyyy').format(selectedDay!)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              if (selectedDayDetails.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: MyColors.appDefaultColorCode.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(durationStr, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: MyColors.appDefaultColorCode)),
                ),
            ],
          ),
          const Divider(height: 30),
          if (selectedDayDetails.isEmpty)
            Center(child: Text("No records found", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)))
          else
            ...selectedDayDetails.map((d) => _buildDetailTile(d)),
        ],
      ),
    );
  }

  Widget _buildDetailTile(InOutDetail detail) {
    bool isIn = detail.inOut == "IN";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (isIn ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded, color: isIn ? Colors.green : Colors.red, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isIn ? "PUNCH IN" : "PUNCH OUT", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)), Text(detail.transactionTime!.substring(11), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey))])),
        ],
      ),
    );
  }

  Widget _buildDailyListView() {
    return Column(
      children: [
        _buildDateRangePicker(),
        Expanded(
          child: isLoading ? const Center(child: CircularProgressIndicator(color: MyColors.lightBlue)) : groupedInOutDetails.isEmpty ? _buildEmptyState() : _buildGroupedList(),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: InkWell(
        onTap: () async {
          final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
          if (range != null) {
            setState(() { fromDate = range.start; toDate = range.end; });
            fetchInOutDetails();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: MyColors.appDefaultColorCode.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: MyColors.appDefaultColorCode.withOpacity(0.1))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.date_range_rounded, color: MyColors.appDefaultColorCode, size: 20), const SizedBox(width: 12), Text("${fromDate != null ? DateFormat('dd MMM').format(fromDate!) : 'Select'} - ${toDate != null ? DateFormat('dd MMM').format(toDate!) : 'Range'}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: MyColors.appDefaultColorCode))]),
              const Icon(Icons.keyboard_arrow_down_rounded, color: MyColors.appDefaultColorCode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: groupedInOutDetails.keys.length,
      itemBuilder: (context, index) {
        String date = groupedInOutDetails.keys.elementAt(index);
        List<InOutDetail> details = groupedInOutDetails[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(date, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13))),
            ...details.map((d) => _buildLogCard(d)),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildLogCard(InOutDetail detail) {
    bool isIn = detail.inOut == "IN";
    Color color = isIn ? Colors.green : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isIn ? "PUNCH IN" : "PUNCH OUT", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(detail.transactionTime!.substring(11), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))]),
                const SizedBox(height: 4),
                Text(detail.address ?? "Location not available", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.asset(
              "assets/icons/no_data.png",
              height: 120,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No records found",
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );  }

  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

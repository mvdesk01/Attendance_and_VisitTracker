import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

import '../../model/in_out_details.dart';
import '../../service/background_service.dart';
import '../../util/MyColor.dart';

class MonthlyInOutReport extends StatefulWidget {
  const MonthlyInOutReport({super.key});

  @override
  State<MonthlyInOutReport> createState() => _MonthlyInOutReportState();
}

class _MonthlyInOutReportState extends State<MonthlyInOutReport> {
  String? staffCode;
  bool isLoading = false;
  DateTime today = DateTime.now();
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<DateTime, List<InOutDetail>> attendanceData = {};
  Set<DateTime> presentDays = {};
  Set<DateTime> absentDays = {};

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await fetchData();
    await fetchAttendanceDataMonthlyReport();
  }

  Future<void> fetchData() async {
    staffCode = await storage.read(key: 'Staff_Code');
  }

  Future<void> fetchAttendanceDataMonthlyReport() async {
    try {
      setState(() => isLoading = true);

      DateTime now = DateTime.now();
      DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      String formattedFromDate = DateFormat('dd/MM/yyyy').format(sixMonthsAgo);
      String formattedToDate = DateFormat('dd/MM/yyyy').format(now);

      final response = await http.post(
        Uri.parse('https://m-techinnovations.co.in/PersonTrackingAPI/API/InOutDetails'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "FromDate": formattedFromDate,
          "ToDate": formattedToDate,
          "StaffCode": staffCode
        }),
      );

      if (response.statusCode == 201) {
        List<dynamic> data = jsonDecode(response.body);
        List<InOutDetail> details = data.map((item) => InOutDetail.fromJson(item)).toList();

        attendanceData.clear();
        presentDays.clear();
        absentDays.clear();

        for (var detail in details) {
          DateTime date = DateFormat('dd/MM/yyyy HH:mm:ss').parse(detail.transactionTime!).toLocal();
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);

          presentDays.add(normalizedDate);

          attendanceData.putIfAbsent(normalizedDate, () => []).add(detail);
        }

        for (int i = 0; i < 180; i++) {
          DateTime day = sixMonthsAgo.add(Duration(days: i));
          if (!presentDays.contains(day) && day.isBefore(now)) {
            absentDays.add(day);
          }
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error fetching attendance data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Attendance Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: MyColors.darkBlue),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Monthly Attendance Report',
                      style: TextStyle(
                        color: MyColors.darkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) => attendanceData[day] ?? [],
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
              holidayDecoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                DateTime normalizedDay = DateTime(day.year, day.month, day.day);

                if (presentDays.contains(normalizedDay)) {
                  return _buildCalendarCell(day, Colors.green);
                } else if (absentDays.contains(normalizedDay)) {
                  return _buildCalendarCell(day, Colors.red);
                }
                return null;
              },
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = DateTime(selected.year, selected.month, selected.day);
                focusedDay = DateTime(focused.year, focused.month, focused.day);
              });
            },
          ),
          const SizedBox(height: 20),
          _buildLegend(),
          if (selectedDay != null && attendanceData.containsKey(selectedDay))
            _buildAttendanceDetails(selectedDay!),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, Color color) {
    return Center(
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            '${day.day}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceDetails(DateTime day) {
    List<InOutDetail> details = attendanceData[day] ?? [];

    if (details.isEmpty) return const SizedBox();

    DateTime? firstPunch = DateFormat('dd/MM/yyyy HH:mm:ss').parse(details.first.transactionTime!).toLocal();
    DateTime? lastPunch = DateFormat('dd/MM/yyyy HH:mm:ss').parse(details.last.transactionTime!).toLocal();

    Duration totalDuration = lastPunch.difference(firstPunch);

    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Attendance Details - ${DateFormat('dd MMM yyyy').format(day)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: details.length,
                itemBuilder: (context, index) {
                  final detail = details[index];
                  return ListTile(
                    title: Text("${detail.inOut} at ${detail.transactionTime}"),
                    subtitle: Text("Address: ${detail.address}"),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              "Total Hours: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    int presentCount = _getPresentDaysCount(selectedDay ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.green, radius: 8),
              const SizedBox(width: 8),
              Text("Present ($presentCount)", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            children: const [
              CircleAvatar(backgroundColor: Colors.red, radius: 8),
              SizedBox(width: 8),
              Text("Absent"),
            ],
          ),
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
}

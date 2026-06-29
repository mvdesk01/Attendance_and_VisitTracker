import 'dart:async';
import 'dart:convert';

import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../bloc/main_bloc.dart';
import '../../model/in_out_details.dart';
import '../../service/WebService.dart';

class AttendanceReport extends StatefulWidget {
  const AttendanceReport({super.key});

  @override
  State<AttendanceReport> createState() => _AttendanceReportState();
}

///in use
class _AttendanceReportState extends State<AttendanceReport> {
  FlutterSecureStorage storage = FlutterSecureStorage();
  String? staffCode;
  String? token;
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool isGridView = false; // State variable for toggle
  bool isMonthlyReport = false;

  // late List<InOutDetail> inOutDetails;
  Map<String, List<InOutDetail>> groupedInOutDetails = {};
  List<InOutDetail> selectedDayDetails = [];

  DateTime today = DateTime.now();
  Map<DateTime, String> attendanceStatus =
      {}; // Maps date to "PUNCH_IN", "PUNCH_OUT", or "ABSENT"

  DateTime? focusedDay;
  DateTime? selectedDay;
  Map<DateTime, List<InOutDetail>> attendanceData = {};
  Set<DateTime> presentDays = {};
  Set<DateTime> absentDays = {};

  // int countOfPresentDayinMonth = countOfPresent();

  @override
  void initState() {
    super.initState();
    focusedDay = DateTime.now(); // Set initial focused day
    selectedDay = focusedDay;
    initialize();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  // void _loadAttendanceData() {
  //   setState(() {
  //     attendanceStatus[DateTime.utc(2024, 2, 10)] = "PUNCH_IN";
  //     attendanceStatus[DateTime.utc(2024, 2, 11)] = "PUNCH_OUT";
  //     attendanceStatus[DateTime.utc(2024, 2, 12)] = "ABSENT";
  //   });
  // }

  Future<void> initialize() async {
    await fetchData(); // Wait for fetchData to complete
    await _fetchTodayData(); // Then call _fetchTodayData
    await fetchAttendanceDataMonthlyReport();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    if (attendanceData.containsKey(normalizedToday)) {
      setState(() {
        selectedDayDetails = attendanceData[normalizedToday]!;
      });
    }
  }

  Future<void> fetchAttendanceDataMonthlyReport() async {
    try {
      setState(() => isLoading = true);

      DateTime now = DateTime.now();
      DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      String formattedFromDate = DateFormat('dd/MM/yyyy').format(sixMonthsAgo);
      String formattedToDate = DateFormat('dd/MM/yyyy').format(now);

      final response = await http
          .post(
            Uri.parse('http://114.143.140.28:8091/api/InOut/InOutDetails'),
            headers: {
              "Content-Type": "application/json",
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({
              "staffCode": staffCode,
              "fromDate": formattedFromDate,
              "toDate": formattedToDate,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print("inout details statuscode: ${response.statusCode}");
      print("inout details body: ${response.body}");
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);

        List<dynamic> data = decoded['data'] ?? [];

        List<InOutDetail> details =
            data.map((item) => InOutDetail.fromJson(item)).toList();

        attendanceData.clear();
        presentDays.clear();
        absentDays.clear();

        for (var detail in details) {
          DateTime date = DateFormat('dd/MM/yyyy HH:mm:ss')
              .parse(detail.transactionTime!)
              .toLocal();
          DateTime normalizedDate =
              DateTime(date.year, date.month, date.day); // Remove time

          presentDays.add(normalizedDate);

          if (!attendanceData.containsKey(normalizedDate)) {
            attendanceData[normalizedDate] = [];
          }
          attendanceData[normalizedDate]!.add(detail);
        }

        // Identify absent days for the last 6 months
        for (int i = 0; i < 180; i++) {
          // 6 months = ~180 days
          DateTime day = sixMonthsAgo.add(Duration(days: i));
          if (!presentDays.contains(day) && day.isBefore(now)) {
            absentDays.add(day);
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } on TimeoutException {
      const SnackBar(
        content: Text(
          "Request timed out. Please try again later.",
        ),
        behavior: SnackBarBehavior.floating,
      );
    } catch (e) {
      const SnackBar(
        content: Text(
          "Something went wrong. Please try again later.",
        ),
        behavior: SnackBarBehavior.floating,
      );
      print('Error fetching attendance data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print('staffcode --> $staffCode');
    token = await storage.read(key: 'Auth_Token');
    print('token --> $token');
  }

  // Fetch data for today by default
  Future<void> _fetchTodayData() async {
    print('first');
    DateTime today = DateTime.now();
    setState(() {
      fromDate = today;
      toDate = today;
    });
    await fetchInOutDetails();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        fromDate = pickedRange.start;
        toDate = pickedRange.end;
      });

      await fetchInOutDetails();
    }
  }

  Future<void> fetchInOutDetails() async {
    if (fromDate == null || toDate == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Format the date to 'dd/MM/yyyy' format as required by the API
      String formattedFromDate = DateFormat('dd/MM/yyyy').format(fromDate!);
      String formattedToDate = DateFormat('dd/MM/yyyy').format(toDate!);

      final response = await http
          .post(
            Uri.parse('http://114.143.140.28:8091/api/InOut/InOutDetails'),
            headers: {
              "Content-Type": "application/json",
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({
              "staffCode": staffCode,
              "fromDate": formattedFromDate,
              "toDate": formattedToDate,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print("inout details statuscode: ${response.statusCode}");
      print("inout details body: ${response.body}");
      final Map<String, dynamic> decoded = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        List<dynamic> data = decoded['data'] ?? [];

        List<InOutDetail> details =
            data.map((item) => InOutDetail.fromJson(item)).toList();

        // Group data by date
        groupedInOutDetails = _groupByDate(details);

        setState(() {
          isLoading = false;
        });
      } else if (response.statusCode == 400) {
        if (decoded['message'] == "No Records Found.") {
          setState(() {
            isLoading = false;
          });
        } else {
          // Handle error
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to fetch data")));
        }
      } else {
        // Handle error
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to fetch data")));
      }
    } on TimeoutException {
      const SnackBar(
        content: Text(
          "Request timed out. Please try again later.",
        ),
        behavior: SnackBarBehavior.floating,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again later."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileManager.writeLog("Error in InOutDetails: $e");
      print("Error in InOutDetails: $e");
    }
  }

  Map<String, List<InOutDetail>> _groupByDate(List<InOutDetail> details) {
    Map<String, List<InOutDetail>> groupedData = {};
    for (var detail in details) {
      String date =
          detail.transactionTime!.substring(0, 10); // Extract the date part
      if (!groupedData.containsKey(date)) {
        groupedData[date] = [];
      }
      groupedData[date]!.add(detail);
    }
    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: const HomeScreen(),
              ),
            ),
          ),
        ),
        title: const Text(
          "In/Out Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: MyColors.lightBlue,
        actions: [
          if (!isMonthlyReport)
            IconButton(
              icon: Icon(
                isGridView ? Icons.list : Icons.grid_view,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isGridView = !isGridView; // Toggle between views
                });
              },
            ),
        ],
      ),
      body: isMonthlyReport ? _buildMonthlyReportNew() : _buildDailyReport(),
    );
  }

  Widget _buildMonthlyReportNew() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            setState(() => isMonthlyReport = false),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: MyColors.darkBlue),
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

                // Calendar Widget
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: focusedDay ?? DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(selectedDay!, day),
                  calendarFormat: CalendarFormat.month,
                  eventLoader: (day) => attendanceData[day] ?? [],
                  calendarStyle: CalendarStyle(
                      // ... (keep your existing calendar styles) ...
                      ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      final normalizedDay =
                          DateTime(day.year, day.month, day.day);
                      if (presentDays.any((d) => isSameDay(d, normalizedDay))) {
                        return _buildCalendarCell(day, Colors.green);
                      } else if (absentDays
                          .any((d) => isSameDay(d, normalizedDay))) {
                        return _buildCalendarCell(day, Colors.red);
                      }
                      return null;
                    },
                  ),
                  onPageChanged: (focusedDay) async {
                    final now = DateTime.now();
                    DateTime targetDay = focusedDay.month == now.month &&
                            focusedDay.year == now.year
                        ? now
                        : DateTime(focusedDay.year, focusedDay.month, 1);

                    setState(() {
                      this.focusedDay = targetDay;
                      selectedDay = targetDay;
                    });

                    // NEW: Safe way to find matching data
                    List<InOutDetail>? detailsForDay;
                    for (final entry in attendanceData.entries) {
                      if (isSameDay(entry.key, targetDay)) {
                        detailsForDay = entry.value;
                        break;
                      }
                    }

                    setState(() {
                      selectedDayDetails = detailsForDay ?? [];
                    });
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    final normalizedDay = DateTime(
                        selectedDay.year, selectedDay.month, selectedDay.day);

                    // Alternative lookup method that handles nulls properly
                    List<InOutDetail>? detailsForDay;
                    for (final entry in attendanceData.entries) {
                      if (isSameDay(entry.key, normalizedDay)) {
                        detailsForDay = entry.value;
                        break;
                      }
                    }

                    setState(() {
                      this.selectedDay = normalizedDay;
                      this.focusedDay = focusedDay;
                      selectedDayDetails = detailsForDay ?? [];
                    });

                    if (detailsForDay == null) {
                      Fluttertoast.showToast(
                        msg:
                            "No records for ${DateFormat('dd MMM yyyy').format(normalizedDay)}",
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),
                _buildLegend(),

                // Attendance Details Section
                if (selectedDay != null)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      if (selectedDayDetails.isNotEmpty)
                        _buildSelectedAttendanceList(),
                      if (selectedDayDetails.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            "No attendance records for ${DateFormat('dd MMM yyyy').format(selectedDay!)}",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
  }

// Helper method for date comparison
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getPresentDaysCount(DateTime month) {
    return presentDays
        .where((date) => date.year == month.year && date.month == month.month)
        .length;
  }

  Widget _buildSelectedAttendanceList() {
    DateTime day = selectedDay!;
    DateTime? firstPunch = selectedDayDetails.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(selectedDayDetails.first.transactionTime!)
            .toLocal()
        : null;
    DateTime? lastPunch = selectedDayDetails.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(selectedDayDetails.last.transactionTime!)
            .toLocal()
        : null;

    Duration totalDuration = Duration();
    if (firstPunch != null && lastPunch != null) {
      totalDuration = lastPunch.difference(firstPunch);
    }

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attendance Details - ${DateFormat('dd MMM yyyy').format(day)}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Divider(),
          //Scroll
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: selectedDayDetails.length,
            itemBuilder: (context, index) {
              final detail = selectedDayDetails[index];
              return ListTile(
                title: Text("${detail.inOut} at ${detail.transactionTime}"),
                subtitle: Text("Address: ${detail.address}"),
                leading: Icon(
                  detail.inOut == "IN" ? Icons.login : Icons.logout,
                  color: detail.inOut == "IN" ? Colors.green : Colors.red,
                ),
              );
            },
          ),
          Divider(),
          Text(
            "Total Hours: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceDetails(DateTime day) {
    List<InOutDetail> details = attendanceData[day] ?? [];

    if (details.isEmpty) return SizedBox();

    DateTime? firstPunch = details.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(details.first.transactionTime!)
            .toLocal()
        : null;

    DateTime? lastPunch = details.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(details.last.transactionTime!)
            .toLocal()
        : null;

    Duration totalDuration = Duration();
    if (firstPunch != null && lastPunch != null) {
      totalDuration = lastPunch.difference(firstPunch);
    }

    return Flexible(
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Attendance Details - ${DateFormat('dd MMM yyyy').format(day)}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
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
            Divider(),
            Text(
              "Total Hours: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    int presentCount =
        _getPresentDaysCount(focusedDay ?? DateTime.now()); // Use focusedDay

    return Center(
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.green, radius: 8),
                SizedBox(width: 8),
                Text(
                  "Present ($presentCount)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(width: 8), // Space between rows
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.red, radius: 8),
                SizedBox(width: 8),
                Text("Absent"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _selectDateRange(context),
                label: const Row(
                  children: [
                    Text(
                      "Select Date Range",
                      style: TextStyle(
                          color: MyColors.darkBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.edit)
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  isMonthlyReport = true; // Switch to calendar view
                }),
                label: const Row(
                  children: [
                    Text("Monthly Report",
                        style: TextStyle(
                            color: MyColors.darkBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Icon(Icons.calendar_month)
                  ],
                ),
              ),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: MyColors.fontBlue
              //   ),
              //   onPressed: () => _selectDateRange(context),
              //   child: const Text("Select Date Range", style: TextStyle(color: Colors.white),),
              // ),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //       backgroundColor: MyColors.fontBlue
              //   ),
              //   onPressed: () => setState(() {
              //     isMonthlyReport = true; // Switch to calendar view
              //   }),
              //   child: const Text("Monthly Report", style: TextStyle(color: Colors.white)),
              // ),
            ],
          ),
        ),
        if (fromDate != null && toDate != null)
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'From: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(fromDate!)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '  To: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(toDate!)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : groupedInOutDetails.isEmpty
                  ? Center(child: Text("No Data Available"))
                  : isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: groupedInOutDetails.keys.length,
                          itemBuilder: (context, index) {
                            String date =
                                groupedInOutDetails.keys.elementAt(index);
                            List<InOutDetail> details =
                                groupedInOutDetails[date]!;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.white,
                              child: SingleChildScrollView(
                                // Add scrolling capability
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date: $date",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: MyColors.fontBlue,
                                      ),
                                    ),
                                    ...details.map((detail) {
                                      return Container(
                                        margin: EdgeInsets.only(top: 10),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: detail.inOut == "IN"
                                              ? Colors.green.shade100
                                              : Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Staff Code: ${detail.staffCode}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                                "Transaction Time: ${detail.transactionTime}"),
                                            Row(
                                              children: [
                                                const Text("In/Out: "),
                                                Text(
                                                  "${detail.inOut}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "Address: ${detail.address}",
                                              overflow: TextOverflow.ellipsis,
                                              // Truncate if too long
                                              maxLines: 1, // Limit to 1 line
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: groupedInOutDetails.keys.length,
                          itemBuilder: (context, index) {
                            String date =
                                groupedInOutDetails.keys.elementAt(index);
                            List<InOutDetail> details =
                                groupedInOutDetails[date]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Text(
                                    "Date: $date",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: MyColors.fontBlue,
                                    ),
                                  ),
                                ),
                                ...details.map((detail) {
                                  return Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: detail.inOut == "IN"
                                        ? Colors.green
                                            .shade100 // Highlight for Punch In
                                        : Colors.red
                                            .shade100, // Highlight for Punch Out
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                detail.inOut == "IN"
                                                    ? Icons.login
                                                    : Icons.logout,
                                                color: detail.inOut == "IN"
                                                    ? Colors.green
                                                    : Colors.red,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                detail.inOut == "IN"
                                                    ? "Punch In"
                                                    : "Punch Out",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: detail.inOut == "IN"
                                                      ? Colors.green[700]
                                                      : Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Divider(
                                              height: 1,
                                              color: Colors.grey.shade400),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Text(
                                                "Staff Code: ",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  "${detail.staffCode}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time,
                                                  size: 18,
                                                  color: Colors.grey.shade600),
                                              SizedBox(width: 5),
                                              Text(
                                                "Transaction Time: ${detail.transactionTime}",
                                                style: TextStyle(
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.location_on,
                                                  size: 18,
                                                  color: Colors.grey.shade600),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  "Address: ${detail.address}",
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }

  _showAttendanceDetails(DateTime day) {
    List<InOutDetail> details = attendanceData[day] ?? [];

    if (details.isEmpty) return;

    DateTime? firstPunch = details.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(details.first.transactionTime!)
            .toLocal()
        : null;

    DateTime? lastPunch = details.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(details.last.transactionTime!)
            .toLocal()
        : null;

    Duration totalDuration = Duration();
    if (firstPunch != null && lastPunch != null) {
      totalDuration = lastPunch.difference(firstPunch);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Padding(
          padding: EdgeInsets.all(15),
          child: Text(
              "Attendance Details - ${DateFormat('dd MMM yyyy').format(day)}"),
        ),
        content: Padding(
            padding: EdgeInsets.all(10),
            child: Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...details.map((detail) => ListTile(
                        title: Text(
                            "${detail.inOut} at ${detail.transactionTime}"),
                        subtitle: Text("Address: ${detail.address}"),
                      )),
                  Divider(),
                  Text(
                    "Total Hours: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ],
              ),
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}

/*Future<void> fetchAttendanceDataMonthlyReport() async {
    try{
      setState(() => isLoading = true);

      String formattedFromDate = DateFormat('dd/MM/yyyy').format(DateTime(focusedDay.year, focusedDay.month, 1));
      String formattedToDate = DateFormat('dd/MM/yyyy').format(DateTime(focusedDay.year, focusedDay.month + 1, 0));

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

        print('response body of fetchAttendanceDataMonthlyReport: $details');

        attendanceData.clear();
        presentDays.clear();
        absentDays.clear();

        for (var detail in details) {
          DateTime date = DateFormat('dd/MM/yyyy').parse(detail.transactionTime!).toLocal();
          presentDays.add(date);
          if (!attendanceData.containsKey(date)) {
            attendanceData[date] = [];
          }
          attendanceData[date]!.add(detail);
        }

        // Calculate absent days
        for (int i = 1; i <= DateTime(focusedDay.year, focusedDay.month + 1, 0).day; i++) {
          DateTime day = DateTime(focusedDay.year, focusedDay.month, i);
          if (!presentDays.contains(day)) {
            absentDays.add(day);
          }
        }
      }
      setState(() => isLoading = false);
    } catch(e){
      print('fetchAttendanceDataMonthlyReport: Error:  $e');
    }

  }*/

// Future<void> _selectDateRange(BuildContext context) async {
//   final DateTime? pickedFromDate = await showDatePicker(
//     context: context,
//     initialDate: DateTime.now(),
//     firstDate: DateTime(2000),
//     lastDate: DateTime.now(),
//   );
//   if (pickedFromDate != null) {
//     final DateTime? pickedToDate = await showDatePicker(
//       context: context,
//       initialDate: pickedFromDate,
//       firstDate: pickedFromDate,
//       lastDate: DateTime.now(),
//     );
//
//     if (pickedToDate != null) {
//       setState(() {
//         fromDate = pickedFromDate;
//         toDate = pickedToDate;
//       });
//
//       // Fetch data after dates are selected
//       await fetchInOutDetails();
//     }
//   }
// }

// Widget _buildMonthlyReport(){
//   _loadAttendanceData();
//   return Column(
//     children: [
//       Padding(
//         padding: const EdgeInsets.all(6.0),
//         child: Row(
//           children: [
//             IconButton(
//               onPressed: () {
//                 setState(() {
//                   isMonthlyReport = false;
//                 });
//               },
//               icon: const Icon(Icons.arrow_back_rounded, color: MyColors.darkBlue),
//             ),
//             const Expanded(
//               child: Center(
//                 child: Text(
//                   'Monthly Attendance Report',
//                   style: TextStyle(
//                     color: MyColors.darkBlue,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 20,)
//           ],
//         ),
//       ),
//
//       _buildCalendar(),
//       const SizedBox(height: 12,),
//       _buildLegend(),
//       /*TableCalendar(
//         firstDay: DateTime.utc(2024, 1, 1),
//         lastDay: DateTime.now(),
//         focusedDay: DateTime.now(),
//         calendarFormat: CalendarFormat.month,
//         headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true),
//         calendarStyle: CalendarStyle(
//           todayDecoration: BoxDecoration(
//               color: Colors.blue.shade200, shape: BoxShape.circle),
//         ),
//         availableGestures: AvailableGestures.all,
//         calendarBuilders: CalendarBuilders(
//           defaultBuilder: (context, date, _) {
//             bool isPresent = groupedInOutDetails.keys.contains(DateFormat('yyyy-MM-dd').format(date));
//             return Center(
//               child: Container(
//                 width: 35,
//                 height: 35,
//                 decoration: BoxDecoration(
//                   color: isPresent ? Colors.green.shade400 : Colors.red.shade400,
//                   shape: BoxShape.circle,
//                 ),
//                 alignment: Alignment.center,
//                 child: Text(
//                   date.day.toString(),
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             );
//           },
//         ),
//       )*/
//     ],
//   );
// }

/*
Widget _buildLegendItem(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 5),
      Text(label),
    ],
  );
}
*/

/*void _showAttendanceDetails(DateTime day) {
  List<InOutDetail> details = attendanceData[day] ?? [];

  if (details.isEmpty) return;

  DateTime? firstPunch = details.isNotEmpty
      ? DateFormat('dd/MM/yyyy HH:mm:ss').parse(details.first.transactionTime!).toLocal()
      : null;

  DateTime? lastPunch = details.isNotEmpty
      ? DateFormat('dd/MM/yyyy HH:mm:ss').parse(details.last.transactionTime!).toLocal()
      : null;


  Duration totalDuration = Duration();
  if (firstPunch != null && lastPunch != null) {
    totalDuration = lastPunch.difference(firstPunch);
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Padding(padding: EdgeInsets.all(15),
        child: Text("Attendance Details - ${DateFormat('dd MMM yyyy').format(day)}"),),
      content: Padding(padding: EdgeInsets.all(10),
          child: Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...details.map((detail) => ListTile(
                  title: Text("${detail.inOut} at ${detail.transactionTime}"),
                  subtitle: Text("Address: ${detail.address}"),
                )),
                Divider(),
                Text(
                  "Total Hours: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),)),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    ),
  );
}*/

/// old list view
/*return Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
color: detail.inOut == "IN"
? Colors.green.shade100 // Highlight for IN
    : Colors.red.shade100, // Highlight for OUT
child: Padding(
padding: const EdgeInsets.all(12.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Staff Code: ${detail.staffCode}",
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
SizedBox(height: 6),
Text("Transaction Time: ${detail.transactionTime}"),
Row(
children: [
const Text("In/Out: "),
Text("${detail.inOut}",
style: TextStyle(fontWeight: FontWeight.bold,
color: detail.inOut == "IN"
? Colors.green[600]// Highlight for IN
    : Colors.red.shade900, // Highlight for OUT
)),
],
),
Text(
"Address: ${detail.address}",
overflow: TextOverflow.ellipsis, // Truncate if too long
maxLines: 1, // Limit to 1 line
),
],
),
),
);*/

//    Grid view of data
/*body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _selectDateRange(context),
              child: Text("Select Date Range"),
            ),
          ),
          if (fromDate != null && toDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'From: ${DateFormat('dd/MM/yyyy').format(fromDate!)} To: ${DateFormat('dd/MM/yyyy').format(toDate!)}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : inOutDetails.isEmpty
                ? Center(child: Text("No Data Available"))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display 2 columns
                childAspectRatio: 3 / 2, // Adjust aspect ratio for each item
              ),
              itemCount: inOutDetails.length,
              itemBuilder: (context, index) {
                final item = inOutDetails[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Staff Code: ${item.staffCode}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Time: ${item.transactionTime}"),
                        Text("In/Out: ${item.inOut}"),
                        Text("Address: ${item.address}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),*/

//    Simple List view of In/Out Data
/*body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _selectDateRange(context),
              child: Text("Select Date Range"),
            ),
          ),
          if (fromDate != null && toDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'From: ${DateFormat('dd/MM/yyyy').format(fromDate!)} To: ${DateFormat('dd/MM/yyyy').format(toDate!)}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : inOutDetails.isEmpty
                ? Center(child: Text("No Data Available"))
                : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: inOutDetails.length,
              separatorBuilder: (context, index) => SizedBox(height: 10), // Add space between items
              itemBuilder: (context, index) {
                final item = inOutDetails[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Staff Code: ${item.staffCode}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blueAccent),
                        ),
                        SizedBox(height: 6),
                        Text("Transaction Time: ${item.transactionTime}"),
                        Text("In/Out: ${item.inOut}"),
                        Text("Address: ${item.address}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),*/

// list view with green and red In/Out indication, with grouped by date but date is not in sequence because of backend
/*body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _selectDateRange(context),
              child: Text("Select Date Range", style: TextStyle( color: MyColors.fontBlue),),
            ),
          ),
          if (fromDate != null && toDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'From: ${DateFormat('dd/MM/yyyy').format(fromDate!)} To: ${DateFormat('dd/MM/yyyy').format(toDate!)}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : groupedInOutDetails.isEmpty
                ? Center(child: Text("No Data Available"))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groupedInOutDetails.keys.length,
              itemBuilder: (context, index) {
                String date = groupedInOutDetails.keys.elementAt(index);
                List<InOutDetail> details = groupedInOutDetails[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        "Date: $date",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MyColors.fontBlue,
                        ),
                      ),
                    ),
                    ...details.map((detail) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: detail.inOut == "IN"
                            ? Colors.green.shade100 // Highlight for IN
                            : Colors.red.shade100, // Highlight for OUT
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Staff Code: ${detail.staffCode}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text("Transaction Time: ${detail.transactionTime}"),
                              Row(
                                children: [
                                  const Text("In/Out: "),
                                  Text("${detail.inOut}", style: TextStyle( fontWeight: FontWeight.bold),)
                                ],
                              ),
                              // Text("In/Out: ${detail.inOut}"),
                              Text("Address: ${detail.address}"),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),*/

/*body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text("From Date: ${fromDate != null ? dateFormat.format(fromDate!) : 'Pick a date'}"),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text('Select From Date'),
                  ),
                ],
              ),
              Column(
                children: [
                  Text("To Date: ${toDate != null ? dateFormat.format(toDate!) : 'Pick a date'}"),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text('Select To Date'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchInOutDetails,
            child: Text('Fetch Data'),
          ),
          SizedBox(height: 20),
          isLoading
              ? CircularProgressIndicator()
              : groupedInOutDetails.isEmpty
              ? Text("No Data")
              : Expanded(
            child: ListView.builder(
              itemCount: groupedInOutDetails.length,
              itemBuilder: (context, index) {
                String date = groupedInOutDetails.keys.elementAt(index);
                List<InOutDetail> entries = groupedInOutDetails[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Column(
                      children: entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Card(
                            color: entry.inOut == 'IN' ? Colors.green[50] : Colors.red[50],
                            elevation: 2,
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Staff Code: ${entry.staffCode}"),
                                  Text("Time: ${entry.transactionTime}"),
                                  Text(
                                    "In/Out: ${entry.inOut}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: entry.inOut == 'IN' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text("Address: ${entry.address}"),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),


        ],
      ),
    ),*/

// Same list in grid view style in that one grid is holding one date's data in proper manner where grid is scrolable and showing one day's all punch in punch out list
/*Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const HomeScreen())),
      ),
      title: const Text("In/Out Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: MyColors.lightBlue,
      actions: [
        IconButton(
          icon: Icon(
            isGridView ? Icons.list : Icons.grid_view,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              isGridView = !isGridView; // Toggle between views
            });
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => _selectDateRange(context),
            child: Text(
              "Select Date Range",
              style: TextStyle(color: MyColors.fontBlue),
            ),
          ),
        ),
        if (fromDate != null && toDate != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'From: ${DateFormat('dd/MM/yyyy').format(fromDate!)} To: ${DateFormat('dd/MM/yyyy').format(toDate!)}',
              style: TextStyle(fontSize: 16),
            ),
          ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : groupedInOutDetails.isEmpty
              ? Center(child: Text("No Data Available"))
              : isGridView
              ? GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: groupedInOutDetails.keys.length,
            itemBuilder: (context, index) {
              String date = groupedInOutDetails.keys.elementAt(index);
              List<InOutDetail> details = groupedInOutDetails[date]!;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.white,
                child: SingleChildScrollView( // Add scrolling capability
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date: $date",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MyColors.fontBlue,
                        ),
                      ),
                      ...details.map((detail) {
                        return Container(
                          margin: EdgeInsets.only(top: 10),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: detail.inOut == "IN"
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Staff Code: ${detail.staffCode}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text("Transaction Time: ${detail.transactionTime}"),
                              Row(
                                children: [
                                  const Text("In/Out: "),
                                  Text(
                                    "${detail.inOut}",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                "Address: ${detail.address}",
                                overflow: TextOverflow.ellipsis, // Truncate if too long
                                maxLines: 1, // Limit to 1 line
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          )
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: groupedInOutDetails.keys.length,
            itemBuilder: (context, index) {
              String date = groupedInOutDetails.keys.elementAt(index);
              List<InOutDetail> details = groupedInOutDetails[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      "Date: $date",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MyColors.fontBlue,
                      ),
                    ),
                  ),
                  ...details.map((detail) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: detail.inOut == "IN"
                          ? Colors.green.shade100 // Highlight for IN
                          : Colors.red.shade100, // Highlight for OUT
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Staff Code: ${detail.staffCode}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text("Transaction Time: ${detail.transactionTime}"),
                            Row(
                              children: [
                                const Text("In/Out: "),
                                Text("${detail.inOut}",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              "Address: ${detail.address}",
                              overflow: TextOverflow.ellipsis, // Truncate if too long
                              maxLines: 1, // Limit to 1 line
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}*/

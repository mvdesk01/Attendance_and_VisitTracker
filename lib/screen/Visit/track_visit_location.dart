import 'package:attendance_system_ios/screen/Visit/Start%20Stop%20Visit/start_stop_visit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date and time formatting
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;

class VisitScreen extends StatefulWidget {
  const VisitScreen({Key? key}) : super(key: key);

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  // List<VisitDetails> visits = [];
  List<Map<String, dynamic>> visits = [];
  String empCode = "CD02714"; // Replace with dynamic employee code if needed
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchVisits();
  }

  Future<void> fetchVisits() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(
            'https://m-techinnovations.co.in/PersonTrackingAPI/API/GetVisitDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"EmpCode": empCode}),
      );

      if (response.statusCode == 201) {
        List<dynamic> result = jsonDecode(response.body);
        List<Map<String, dynamic>> allVisits = List<Map<String, dynamic>>.from(result);
        // final List<dynamic> jsonData = jsonDecode(response.body);
        // List<VisitDetails> allVisits = jsonData.map((item) => VisitDetails.fromJson(item)).toList();
        final DateTime now = DateTime.now();
        final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
        final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        final DateFormat timeFormat = DateFormat('HH:mm');
        final String _currentDate = dateFormat.format(now);
        final String _currentTime = timeFormat.format(now);
        final DateTime _nowDateTime = DateFormat('dd/MM/yyyy HH:mm').parse('$_currentDate $_currentTime');


        // Current date and time
        // final DateTime now = DateTime.now();

        // Date and time formatter
        final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
        final DateFormat timeFormatter12 = DateFormat('hh:mm a'); // For 12-hour format
        final DateFormat timeFormatter24 = DateFormat('HH:mm');   // For 24-hour format

        // Filter visits
        setState(() {
          List<Map<String, dynamic>> visits = allVisits.where((visit) {
          try {
            // Extract date and time strings
            String? visitDate = visit['VisitDate'];
            String? visitEndTime = visit['EndTime'];

            if (visitDate == null || visitEndTime == null) {
              return false; // Skip invalid entries
            }

            // Parse the date
            DateTime parsedDate = dateFormatter.parse(visitDate);

            // Parse the time (try 12-hour format first, then fallback to 24-hour format)
            DateTime parsedEndTime;
            try {
              parsedEndTime = timeFormatter12.parse(visitEndTime);
            } catch (_) {
              parsedEndTime = timeFormatter24.parse(visitEndTime);
            }

            // Combine date and time
            DateTime visitDateTime = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              parsedEndTime.hour,
              parsedEndTime.minute,
            );

            // Filter condition: visitDateTime >= now
            return visitDateTime.isAfter(now) || visitDateTime.isAtSameMomentAs(now);
          } catch (e) {
            print("Error parsing visit: $e");
            return false; // Skip invalid entries
          }
        }).toList();
        });

        // Output the filtered visits
        print(visits);

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Handle error
        print('Failed to fetch visits: ${response.statusCode}');
      }
    } catch (e){
      setState(() {
        isLoading = false;
      });
      print("Error fetching visit list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scheduled Visits"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : visits.isEmpty
          ? Center(child: Text("No Active Visits"),)
          : ListView.builder(
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return ListTile(
            title: Text(visit["VisitName"]!),
            subtitle: Text("Date: ${visit["VisitDate"]}, Time: ${visit["StartTime"]}"),
            trailing: ElevatedButton(
              onPressed: () {
                // startVisit(visit);
              },
              child: const Text("Start Visit"),
            ),
          );
        },
      ),
    );
  }

/*  Future<void> startVisit(Map<String, dynamic> visit) async {
    // Navigate to visit tracking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitTrackingScreen(visit: visit, empCode: empCode),
      ),
    );
  }*/
}



/*
import 'package:attendance_system_ios/model/visit_details.dart';
import 'package:attendance_system_ios/screen/Visit/start_stop_visit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date and time formatting
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;

class VisitScreen extends StatefulWidget {
  const VisitScreen({Key? key}) : super(key: key);

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  // List<VisitDetails> visits = [];
  List<Map<String, dynamic>> visits = [];
  String empCode = "CD02714"; // Replace with dynamic employee code if needed

  @override
  void initState() {
    super.initState();
    fetchVisits();
  }

  Future<void> fetchVisits() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://m-techinnovations.co.in/PersonTrackingAPI/API/GetVisitDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"EmpCode": empCode}),
      );

      if (response.statusCode == 201) {
        // List<VisitDetails> allVisits = jsonDecode(response.body);
        final List<dynamic> jsonData = jsonDecode(response.body);
        List<VisitDetails> allVisits = jsonData.map((item) => VisitDetails.fromJson(item)).toList();
        final DateTime now = DateTime.now();
        final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        final DateFormat timeFormat = DateFormat('HH:mm');
        final String _currentDate = dateFormat.format(now);
        final String _currentTime = timeFormat.format(now);

        // setState(() {
        visits = allVisits.where((visit) {
          // Parse visit date and time
          String? vDate = visit.visitDate;
          String? vTime = visit.endTime;

          if (vDate != null && vTime != null) {
            */
/*   DateTime visitDate = DateFormat('dd/MM/yyyy').parse('$vDate');
              DateTime visitTime = DateFormat('HH:mm').parse('$vTime');
              if(visitDate >= _currentDate && visitTime >= _currentTime){
                return true;
              }*//*

            DateTime visitDateTime = DateFormat('dd/MM/yyyy HH:mm').parse('$vDate $vTime');
            return visitDateTime.isAfter(now) || visitDateTime.isAtSameMomentAs(now);
          }
          return false; // Exclude visits with invalid date or time
        }).toList();
        // visits = allVisits
        // });
      } else {
        // Handle error
        print('Failed to fetch visits: ${response.statusCode}');
      }
    } catch (e){
      print("Error fetching visit list: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scheduled Visits"),
        centerTitle: true,
      ),
      body: visits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return ListTile(
            title: Text(visit.visitName!),
            subtitle: Text("Date: ${visit.visitDate}, Time: ${visit.startTime}"),
            trailing: ElevatedButton(
              onPressed: () {
                startVisit(visit);
              },
              child: const Text("Start Visit"),
            ),
          );
        },
      ),
    );
  }

  Future<void> startVisit(VisitDetails visit) async {
    // Navigate to visit tracking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitTrackingScreen(visit: visit, empCode: empCode),
      ),
    );
  }
}
*/

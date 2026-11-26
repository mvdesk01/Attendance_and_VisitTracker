import 'package:attendance_system_ios/screen/TimeLogSheet/timelog_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => TaskManagementScreenState();
}

class TaskManagementScreenState extends State<TaskManagementScreen> {
  TextEditingController datecontroller = TextEditingController();

  final accentColor = const Color(0xFF4F46E5);
  final backgroundColor = const Color(0xFFF8FAFC);

  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color borderColor = Color(0xFFE2E8F0);
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late MainBloc mainBloc;
  String? Auth_Token = "";
  String? deptName;

  bool showTable = false;

  @override
  void initState() {
    super.initState();
    datecontroller.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    mainBloc = context.read<MainBloc>();
    getData();
  }

  Future<void> getData() async {
    final staffCode = await storage.read(key: 'Staff_Code');

    print("staffCodee---->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Tokenn---->" + Auth_Token!);

    mainBloc
        .add(GetStaffDetailsEvents(StaffCode: staffCode, token: Auth_Token!));
  }

  @override
  void dispose() {
    datecontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if (state is GetStaffDetailsLoadedState) {
          // Get DeptName from your staff-details success state here.
          setState(() {
            deptName =
                state.staffDetailsResponse!.message!.departmentName.toString();
          });
        }
        print(deptName);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            "TimeLog Sheet",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          backgroundColor: primaryColor,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_outlined,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Select Date:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 15),
                      SizedBox(
                        width: 190,
                        child: TextFormField(
                          controller: datecontroller,
                          readOnly: true,
                          textAlign: TextAlign.center,
                          onTap: datepicker,
                          decoration: InputDecoration(
                            suffixIcon: const Icon(
                              Icons.calendar_month_rounded,
                              color: primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (datecontroller.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select date"),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            showTable = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Submit"),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (showTable)
                    TimeLogTable(
                      key: ValueKey(datecontroller.text),
                      primaryColor: primaryColor,
                      logdate: datecontroller.text,
                      deptname: deptName,
                      onClose: () {
                        if (mounted) {
                          setState(() {
                            showTable = false;
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> datepicker() async {
  //   DateTime now = DateTime.now();
  //
  //   DateTime today = DateTime(now.year, now.month, now.day);
  //
  //   // View TLS: allow any past or future date.
  //   // TimeLog Sheet: allow only today and previous two days.
  //   DateTime firstDate = isViewTLS
  //       ? DateTime(2000, 1, 1)
  //       : today.subtract(const Duration(days: 2));
  //
  //   DateTime lastDate = isViewTLS ? DateTime(2100, 12, 31) : today;
  //
  //   DateTime initialDate = today;
  //
  //   DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: initialDate,
  //     firstDate: firstDate,
  //     lastDate: lastDate,
  //   );
  //
  //   if (pickedDate != null) {
  //     setState(() {
  //       datecontroller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
  //     });
  //   }
  // }
  Future<void> datepicker() async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today.subtract(const Duration(days: 2)),
      lastDate: today,
    );

    if (pickedDate != null) {
      setState(() {
        datecontroller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        showTable = false;
      });
    }
  }
}

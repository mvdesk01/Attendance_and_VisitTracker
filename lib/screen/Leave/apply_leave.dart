import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/Leave/SubmitLeaveResponse.dart';

class LeaveDetailsPage extends StatefulWidget {
  String tokennn;
  int flag;
  Message  leaveData; // Parameter for leaveData

  LeaveDetailsPage({
    Key? key,
    required this.flag,
    required this.tokennn,
    required this.leaveData

  }) : super(key: key);

  @override
  State<LeaveDetailsPage> createState() => _LeaveDetailsPageState();
}
class _LeaveDetailsPageState extends State<LeaveDetailsPage> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staff_code="";
  String? staff_name="";
  String? plant_name="";
  String? departmet="";
  String? joining_date="";
  String? token="";
  String? year ="";
  bool isLoading=false;
  String transactionID = "";
  Map<String, String> leaveBalances = {};
  String staffcode="";

  final leaveTypes = ['Please Select', 'CL', 'PL', 'SL', 'LWP'];
  String selectedLeaveType = 'Please Select';
  final TextEditingController leaveBalanceController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController totalDaysController = TextEditingController();
  final TextEditingController fromTimeController = TextEditingController();
  final TextEditingController toTimeController = TextEditingController();
  final TextEditingController totalTimeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  // final TextEditingController staffcodede = TextEditingController();
  bool Fromtimefirsthalf = true;
  bool Fromtimesecondhalf = false;
  bool Totimefirsthalf = false;
  bool Totimesecondhalf = true;
  bool leaveInFraction = false;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  //ring tokens='';

  void initState() {
    mainBloc=BlocProvider.of(context);
    //getData();
    getLeaveBalances();
    if(widget.flag == 2){
      //tokens = widget.tokennn;
      staff_code = widget.leaveData.staffCode?? '';
      fromDateController.text = formatDate(widget.leaveData.startingDate ?? '');
      toDateController.text = formatDate(widget.leaveData.endingDate ?? '');

      totalDaysController.text = widget.leaveData.noOfDays.toString();
      fromTimeController.text = widget.leaveData.fromTime.toString();
      toTimeController.text = widget.leaveData.toTime.toString();
        if(fromTimeController.text != null){
          _calculateTotalTime();
        }
      //totalTimeController.text = widget.leaveData.totalTime.toString();
      addressController.text = widget.leaveData.addrOnLeave.toString();
      reasonController.text = widget.leaveData.reason.toString();
      mobileController.text = widget.leaveData.mobileNo.toString();
      transactionID = widget.leaveData.transactionId.toString();
      //leaveBalanceController = widget.leaveData.
    }
    else{
      print(widget.flag);
      print("widget flag=1");
      getData();
    }
    print("staffcode"+staffcode);
    print("Flag: ${widget.flag}");
    print("Leave Data: ${widget.leaveData.staffCode}");
    print("Leave Data: ${widget.leaveData.fromTime}");
  }

  Future<void> getLeaveBalances() async {
    token = await storage.read(key: 'authtokenn');
    year = await storage.read(key: "selectedYear");
    staff_code = await storage.read(key: 'stafcodeee');

    if (staff_code != null && token != null && year != null) {
      mainBloc.add(GetLeavetypeEvents(
          StaffCode: staff_code!,
          token: token!,
          Year: year!
      ));
    }
  }
  Future<void> getData() async {
    staff_code = await storage.read(key: 'stafcodeee');
    print("staffCodeeeee-->"+staff_code!);
    token = await storage.read(key: 'authtokenn');
    print("tokennn->"+token!);
    year = await storage.read(key: "selectedYear");
    print("year"+year!);
    staff_name = await storage.read(key: 'staffname');
    plant_name = await storage.read(key: 'plantname');
    departmet = await storage.read(key: 'department');
    joining_date = await storage.read(key: 'doj');
    // staffcodede.text = staff_code!;
    mainBloc.add(GetLeavetypeEvents(StaffCode: staff_code!, token: token!, Year: year!));

  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = '${pickedDate.day.toString().padLeft(2, '0')}/'
            '${pickedDate.month.toString().padLeft(2, '0')}/'
            '${pickedDate.year}';
      });
    }
  }


  Future<void> _pickTime(TimeOfDay? time, TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        time = pickedTime;
        controller.text = time!.format(context);
      });
    }
  }

  // void _calculateDays() {
  //   if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
  //     try {
  //       // Normalize and parse dates
  //       String normalizedFromDate = _normalizeDate(fromDateController.text.trim());
  //       String normalizedToDate = _normalizeDate(toDateController.text.trim());
  //
  //       DateTime fromDate = DateTime.parse(normalizedFromDate);
  //       DateTime toDate = DateTime.parse(normalizedToDate);
  //
  //       // Validate date selection
  //       if (fromDate.isAfter(toDate) ||
  //           (fromDate.isAtSameMomentAs(toDate) && !Fromtimefirsthalf && Totimefirsthalf)) {
  //         setState(() {
  //           totalDaysController.text = 'Select valid dates';
  //         });
  //         return;
  //       }
  //
  //       // Calculate total days
  //       double totalDays = 0.0;
  //
  //       if (fromDate.isAtSameMomentAs(toDate)) {
  //         // Same day leave
  //         totalDays = Fromtimefirsthalf != Totimefirsthalf ? 1 : 0.5;
  //       } else {
  //         int daysDifference = toDate.difference(fromDate).inDays;
  //
  //         // Correct calculation for different days
  //         if (!Fromtimefirsthalf && Totimefirsthalf && daysDifference == 1) {
  //           totalDays = 1.0; // Case: Second half to first half of next day
  //         } else {
  //           totalDays = daysDifference.toDouble();
  //           if (!Fromtimefirsthalf) totalDays += 0.5; // Second half of fromDate adds 0.5
  //           if (Totimefirsthalf) totalDays += 0.5;   // First half of toDate adds 0.5
  //         }
  //       }
  //
  //       // Log and update UI
  //       print("Database Entry: '$normalizedFromDate', '$normalizedToDate', $totalDays");
  //       setState(() {
  //         totalDaysController.text = totalDays.toString();
  //       });
  //       Fluttertoast.showToast(msg: "Calculation Completed!!");
  //
  //     } catch (e) {
  //       print("Error in _calculateDays: $e");
  //       setState(() {
  //         totalDaysController.text = 'Invalid date';
  //       });
  //     }
  //   } else {
  //     setState(() {
  //       totalDaysController.text = 'Please select both dates';
  //     });
  //   }
  // }

/*  void _calculateDays() {
    if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
      try {
        String normalizedFromDate = _normalizeDate(fromDateController.text.trim());
        String normalizedToDate = _normalizeDate(toDateController.text.trim());

        DateTime fromDate = DateTime.parse(normalizedFromDate);
        DateTime toDate = DateTime.parse(normalizedToDate);

        if (fromDate.isAfter(toDate)) {
          setState(() {
            totalDaysController.text = 'Select valid dates';
          });
          return;
        }

        double totalDays = 0.0;

        if (fromDate.isAtSameMomentAs(toDate)) {
          // Same day leave
          if (Fromtimefirsthalf == Totimefirsthalf) {
            totalDays = 0.5;
          } else {
            totalDays = 1.0;
          }
        } else {
          int fullDaysInBetween = toDate.difference(fromDate).inDays - 1;

          double fromDay = (Fromtimefirsthalf) ? 1.0 : 0.5;
          double toDay = (!Totimefirsthalf) ? 1.0 : 0.5;

          totalDays = fromDay + toDay + (fullDaysInBetween > 0 ? fullDaysInBetween.toDouble() : 0);
        }

        setState(() {
          totalDaysController.text = totalDays.toStringAsFixed(1);
        });

        print("Calculated from $normalizedFromDate to $normalizedToDate = $totalDays days");
        Fluttertoast.showToast(msg: "Calculation Completed!!");

      } catch (e) {
        print("Error in _calculateDays: $e");
        setState(() {
          totalDaysController.text = 'Invalid date';
        });
      }
    } else {
      setState(() {
        totalDaysController.text = 'Please select both dates';
      });
    }
  }*/
  void _calculateDays() {
    if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
      try {
        String normalizedFromDate = _normalizeDate(fromDateController.text.trim());
        String normalizedToDate = _normalizeDate(toDateController.text.trim());

        DateTime fromDate = DateTime.parse(normalizedFromDate);
        DateTime toDate = DateTime.parse(normalizedToDate);

        if (fromDate.isAfter(toDate)) {
          setState(() {
            totalDaysController.text = 'Select valid dates';
          });
          return;
        }

        double totalDays = 0.0;

        if (fromDate.isAtSameMomentAs(toDate)) {
          // Same day leave
          if (Fromtimefirsthalf && !Totimefirsthalf) {
            // First half to second half of same day
            totalDays = 1.0;
          } else if (!Fromtimefirsthalf && Totimefirsthalf) {
            // Invalid case - second half to first half of same day
            setState(() {
              totalDaysController.text = 'Invalid selection';
            });
            Fluttertoast.showToast(msg: "Cannot select second half to first half on same day");
            return;
          } else {
            // Either both first half or both second half
            totalDays = 0.5;
          }
        } else {
          // Different days
          int fullDaysInBetween = toDate.difference(fromDate).inDays - 1;

          // First day calculation
          double fromDay = Fromtimefirsthalf ? 1.0 : 0.5;

          // Last day calculation
          double toDay = Totimefirsthalf ? 0.5 : 1.0;

          totalDays = fromDay + toDay + (fullDaysInBetween > 0 ? fullDaysInBetween.toDouble() : 0);
        }

        setState(() {
          totalDaysController.text = totalDays.toStringAsFixed(1);
        });

        print("Calculated from $normalizedFromDate to $normalizedToDate = $totalDays days");
        Fluttertoast.showToast(msg: "Calculation Completed!!");

      } catch (e) {
        print("Error in _calculateDays: $e");
        setState(() {
          totalDaysController.text = 'Invalid date';
        });
      }
    } else {
      setState(() {
        totalDaysController.text = 'Please select both dates';
      });
    }
  }

  String _normalizeDate(String date) {
    try {
      // Split the date string by '-' or '/'
      List<String> parts = date.contains('/') ? date.split('/') : date.split('/');
      if (parts.length != 3) {
        throw FormatException("Invalid date format: $date");
      }

      // Normalize day, month, and year
      String day = parts[0].padLeft(2, '0');   // Ensure two digits for day
      String month = parts[1].padLeft(2, '0'); // Ensure two digits for month
      String year = parts[2];

      return '$year-$month-$day'; // Return normalized format for DateTime.parse
    } catch (e) {
      throw FormatException("Error normalizing date: $date. $e");
    }
  }

  void _calculateTotalTime() {
    if (fromTimeController.text.isEmpty || toTimeController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please select both From Time and To Time");
      return;
    }

    try {
      // Parse the selected time
      DateTime fromDateTime = DateFormat("hh:mm a").parse(fromTimeController.text);
      DateTime toDateTime = DateFormat("hh:mm a").parse(toTimeController.text);

      // Convert to Duration for validation and calculation
      Duration fromDuration = Duration(hours: fromDateTime.hour, minutes: fromDateTime.minute);
      Duration toDuration = Duration(hours: toDateTime.hour, minutes: toDateTime.minute);

      // **Validation 1: From Time should not be before 08:30 AM**
      Duration minAllowedTime = const Duration(hours: 8, minutes: 30);
      if (fromDuration < minAllowedTime) {
        Fluttertoast.showToast(msg: "From Time should not be before 08:30 AM");
        totalTimeController.text = '';
        return;
      }

      // **Validation 2: To Time should not be after 18:00 PM**
      Duration maxAllowedTime = const Duration(hours: 18, minutes: 0);
      if (toDuration > maxAllowedTime) {
        Fluttertoast.showToast(msg: "To Time should not be after 18:00 PM");
        totalTimeController.text = '';
        return;
      }

      // **Validation 3: From Time and To Time cannot be the same**
      if (fromDuration == toDuration) {
        Fluttertoast.showToast(msg: "From Time and To Time cannot be the same");
        totalTimeController.text = '';
        return;
      }

      // **Validation 4: To Time cannot be before From Time**
      if (toDuration < fromDuration) {
        Fluttertoast.showToast(msg: "To Time cannot be before From Time");
        totalTimeController.text = '';
        return;
      }

      // Calculate the total difference in minutes
      int totalMinutes = toDuration.inMinutes - fromDuration.inMinutes;

      // **Validation 5: Ensure time does not exceed 480 minutes (8 hours)**
      if (totalMinutes > 480) {
        Fluttertoast.showToast(msg: "Time should not exceed 8 hours (480 minutes)");
        totalTimeController.text = '';
        return;
      }

      // Update UI
      setState(() {
        totalTimeController.text = '$totalMinutes min';
      });

    } catch (e) {
      setState(() {
        totalTimeController.text = 'Invalid Time Selection';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if(state is GetLeaveTypeLoadingState ){
          setState(() {
            isLoading=true;
          });
        }
        else if (state is GetLeaveTypeLoadedState) {
          // setState(() {
          //   isLoading = false;
          //   // Properly populate leaveBalances with fetched data
          //   leaveBalances = {};
          //   for (var type in state.leavedetails.leaveTypes!) {
          //     if (type.leaveTypeName != null && type.daysRemaining != null) {
          //       leaveBalances[type.leaveTypeName!] = type.daysRemaining!;
          //     }
          //   }
          //   // Update balance when leave type changes
          //   if (selectedLeaveType != 'Please Select' && selectedLeaveType != 'LWP') {
          //     leaveBalanceController.text =
          //         leaveBalances[selectedLeaveType]?.toString() ?? '0';
          //   }
          // });

          setState(() {
            isLoading = false;
            leaveBalances = {};
            for (var type in state.leavedetails.leaveTypes!) {
              if (type.leaveTypeName != null && type.daysRemaining != null) {
                leaveBalances[type.leaveTypeName!] = type.daysRemaining!;
              }
            }
            // Update balance for current leave type if not LWP
            if (selectedLeaveType != 'Please Select' && selectedLeaveType != 'LWP') {
              leaveBalanceController.text = leaveBalances[selectedLeaveType] ?? '0';
            }
          });
        }
        // else if (state is GetLeaveTypeLoadedState) {
        //   setState(() {
        //     isLoading = false;
        //     // Populate leaveBalances with fetched data.
        //     leaveBalances = {
        //       for (var type in state.leavedetails.leaveTypes!)
        //         type.leaveTypeName as String: type.daysRemaining as int, // Assuming response structure
        //     };
        //   });
        // }
        else if(state is GetLeaveTypeErrorState){
          setState(() {
            isLoading=false;
          });
        }
        if(state is GetSubmitLeaveLoadingState){
          setState(() {
            isLoading=true;
          });
        }
        else if(state is GetSubmitLeaveLoadedState){
          // setState(() {
          //   isLoading=false;
          //  reasonController.clear();
          // });
          setState(() {
            isLoading = false;
          });

          // Clear all fields
          _clearFields();

          // Show success message
          Fluttertoast.showToast(msg: widget.flag == 1 ? 'Leave submitted!' : 'Leave updated!');

          // Navigate back if editing (flag == 2)
          if (widget.flag == 2) {
            Navigator.pop(context); // Return to previous page
          }
        }
        else if(state is GetSubmitLeaveErrorState){
          setState(() {
            isLoading=false;
          });
          // Fluttertoast.showToast(msg: 'leave submitted');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Enter Details')),


        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLeaveType,
                  decoration: const InputDecoration(
                    labelText: 'Leave Type',
                    border: OutlineInputBorder(),
                  ),
                  // onChanged: (value) {
                  //   setState(() {
                  //     selectedLeaveType = value!;
                  //     if (selectedLeaveType == 'LWP') {
                  //       leaveBalanceController.text = '0';
                  //     } else {
                  //       leaveBalanceController.text =
                  //           leaveBalances[selectedLeaveType]?.toString() ?? '0';
                  //     }
                  //   });
                  // },
                  onChanged: (value) {
                    setState(() {
                      selectedLeaveType = value!;
                      if (selectedLeaveType == 'LWP') {
                        leaveBalanceController.text = '0';
                      } else {
                        // Get balance from the pre-fetched data
                        leaveBalanceController.text =
                            leaveBalances[selectedLeaveType]?.toString() ?? '0';
                      }
                    });
                  },
                  items: leaveTypes.map((leaveType) {
                    return DropdownMenuItem(
                      value: leaveType,
                      child: Text(leaveType),
                    );
                  }).toList(),
                ),
                // Leave Balance
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Leave Balance:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: leaveBalanceController,
                        decoration: const InputDecoration(
                          hintText: 'Leave Balance',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // From Date and Time
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: fromDateController,
                        readOnly: true,
                        onTap: () => _pickDate(fromDateController),
                        decoration: const InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Radio<bool>(
                              value: true, // First Half selected
                              groupValue: Fromtimefirsthalf,
                              onChanged: (value) {
                                setState(() {
                                  Fromtimefirsthalf = value!; // Set first half to true
                                  Fromtimesecondhalf = !value; // Set second half to false
                                });
                              },
                            ),
                          ),
                          const Text('1st Half'),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Radio<bool>(
                              value: false, // Second Half selected
                              groupValue: Fromtimefirsthalf,
                              onChanged: (value) {
                                setState(() {
                                  Fromtimefirsthalf = value!; // Set first half to false
                                  Fromtimesecondhalf = !value; // Set second half to true
                                });
                              },
                            ),
                          ),
                          const Text('2nd Half'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
// To Date and Time
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: toDateController,
                        readOnly: true,
                        onTap: () => _pickDate(toDateController),
                        decoration: const InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Radio<bool>(
                              value: true, // First Half selected
                              groupValue: Totimefirsthalf,
                              onChanged: (value) {
                                setState(() {
                                  Totimefirsthalf = value!; // Set first half to true
                                  Totimesecondhalf = !value; // Set second half to false
                                });
                              },
                            ),
                          ),
                          const Text('1st Half'),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Radio<bool>(
                              value: false, // Second Half selected
                              groupValue: Totimefirsthalf,
                              onChanged: (value) {
                                setState(() {
                                  Totimefirsthalf = value!; // Set first half to false
                                  Totimesecondhalf = !value; // Set second half to true
                                });
                              },
                            ),
                          ),
                          const Text('2nd Half'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Total Days:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: totalDaysController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Total Days',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                // Leave in Fraction Checkbox
                CheckboxListTile(
                  title: const Text('Leave in Fraction'),
                  value: leaveInFraction,
                  onChanged: (value) {
                    setState(() {
                      leaveInFraction = value!;
                    });
                  },
                ),
                if (leaveInFraction) ...[
                  // From Time
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'From Time:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: fromTimeController,
                          readOnly: true,
                          onTap: () => _pickTime(fromTime, fromTimeController),
                          decoration: const InputDecoration(
                            hintText: 'Select Time',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // To Time
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'To Time:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: toTimeController,
                          readOnly: true,
                          onTap: () => _pickTime(toTime, toTimeController),
                          decoration: const InputDecoration(
                            hintText: 'Select Time',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Total Time
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Total Time(in minutes):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: totalTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Total Time',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (leaveInFraction) {
                      _calculateTotalTime(); // Calculate total time when "Leave in Fraction" is checked
                    }
                    _calculateDays(); // Calculate total days in all cases

                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('Calculation complete!')),
                    // );
                  },
                  child: const Text('Calculate'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                // Ensure you have imported the intl package
                ElevatedButton(
                  onPressed: () {
                    _validation(); // Calculate total days in all cases
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('Leave Submitted')),
                    // );
                  },
                  child: isLoading
                      ? CircularProgressIndicator() // Show loader when submitting
                      :const Text('Submit Leave'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day.toString().padLeft(2, '0')}/"
        "${parsedDate.month.toString().padLeft(2, '0')}/"
        "${parsedDate.year}";
  }
  _validation() {
    if (leaveTypes=="Select") {
      Fluttertoast.showToast(
        msg: "  Please Select Leave Type...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    } else if (fromDateController.text=="") {
      Fluttertoast.showToast(
        msg: "  Please Select Leave FromDate...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }
    else if (toDateController.text=="") {
      Fluttertoast.showToast(
        msg: "  Please Select Leave ToDate...!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }
    else if (leaveInFraction==true) {

      if(fromTimeController.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "  Please from time...!  ",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
      }
      else if(toTimeController.text.isEmpty) {
        Fluttertoast.showToast(
          msg: "  Please to time...!  ",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
      }
      else {
        print(" ifffffff_else..............");
        _addLeavedata();
      }
    }
    if (addressController.text=="") {
      Fluttertoast.showToast(
        msg: "  Please enter adress on leave!  ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }
    if (reasonController.text=="") {
      Fluttertoast.showToast(
        msg: "  Please enter reason of leave! ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }
    if (mobileController.text=="") {
      Fluttertoast.showToast(
        msg: "  Please enter mobile number! ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }
    if (mobileController.text.length != 10) {
      Fluttertoast.showToast(
        msg: "  number must be 10 digit ",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    else
    {
      print(" _else..............");
      _addLeavedata();
    }
  }

  _addLeavedata() {
    String checkFlag = leaveInFraction ? "Y" : "N";

    // Debug prints to verify values
    print("Flag: ${widget.flag}");
    print("Transaction ID: $transactionID");
    print("Staff Code: $staff_code");

    SubmitLeaveDetails leaveDetails = SubmitLeaveDetails(
      flag: widget.flag == 1 ? "INSERT" : "UPDATE",
      transactionId: widget.flag == 1 ? "" : transactionID,
      staffCode: staff_code,
      name: staff_name,
      plant: plant_name,
      doj: joining_date,
      dept: departmet,
      weeklyOff: "",
      leaveType: selectedLeaveType,
      leaveBalance: leaveBalanceController.text,
      fromDate: fromDateController.text,
      toDate: toDateController.text,
      rdoFfirstHalf: Fromtimefirsthalf,
      rdoFSecondHalf: Fromtimesecondhalf,
      rdoTfirstHalf: Totimefirsthalf,
      rdoTsecondHalf: Totimesecondhalf,
      fromTime: leaveInFraction ? fromTimeController.text : '',
      toTime: leaveInFraction ? toTimeController.text : '',
      checkInFraction: checkFlag,
      year: year,
      totalDays: totalDaysController.text,
      reason: reasonController.text,
      address: addressController.text,
      mobileNo: mobileController.text,
    );
    print("Submitting leave: ${leaveDetails.toJson()}");
    mainBloc.add(SubmitLeaveEvents(
        submitleavedetails: leaveDetails,
        token: token!
    ));
  }
  _clearFields() {

    setState(() {
      selectedLeaveType = 'Please Select';
      leaveBalanceController.clear();
      fromDateController.clear();
      toDateController.clear();
      totalDaysController.clear();
      fromTimeController.clear();
      toTimeController.clear();
      totalTimeController.clear();
      addressController.clear();
      reasonController.clear();
      mobileController.clear();
      Fromtimefirsthalf = true;
      Fromtimesecondhalf = false;
      Totimefirsthalf = false;
      Totimesecondhalf = true;
      leaveInFraction = false;
    });

  }

}

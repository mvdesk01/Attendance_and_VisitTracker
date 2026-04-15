import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
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
  Message leaveData; // Parameter for leaveData

  LeaveDetailsPage(
      {Key? key,
      required this.flag,
      required this.tokennn,
      required this.leaveData})
      : super(key: key);

  @override
  State<LeaveDetailsPage> createState() => _LeaveDetailsPageState();
}

// class _LeaveDetailsPageState extends State<LeaveDetailsPage> {
//   late MainBloc mainBloc;
//   final storage = FlutterSecureStorage();
//   String? staff_code = "";
//   String? staff_name = "";
//   String? plant_name = "";
//   String? departmet = "";
//   String? joining_date = "";
//   String? token = "";
//   String? year = "";
//   bool isLoading = false;
//   String transactionID = "";
//   Map<String, String> leaveBalances = {};
//   String staffcode = "";
//
//   final leaveTypes = ['Please Select', 'CL', 'PL', 'SL', 'LWP'];
//   String selectedLeaveType = 'Please Select';
//   final TextEditingController leaveBalanceController = TextEditingController();
//   final TextEditingController fromDateController = TextEditingController();
//   final TextEditingController toDateController = TextEditingController();
//   final TextEditingController totalDaysController = TextEditingController();
//   final TextEditingController fromTimeController = TextEditingController();
//   final TextEditingController toTimeController = TextEditingController();
//
//   //final TextEditingController totalTimeController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController reasonController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//
//   // final TextEditingController staffcodede = TextEditingController();
//   bool Fromtimefirsthalf = true;
//   bool Fromtimesecondhalf = false;
//   bool Totimefirsthalf = false;
//   bool Totimesecondhalf = true;
//   bool leaveInFraction = false;
//   TimeOfDay? fromTime;
//   TimeOfDay? toTime;
//
//   void initState() {
//     mainBloc = BlocProvider.of(context);
//     //getData();
//     getLeaveBalances();
//     if (widget.flag == 2) {
//       //tokens = widget.tokennn;
//       staff_code = widget.leaveData.staffCode ?? '';
//       fromDateController.text = formatDate(widget.leaveData.startingDate ?? '');
//       toDateController.text = formatDate(widget.leaveData.endingDate ?? '');
//
//       totalDaysController.text = widget.leaveData.noOfDays.toString();
//       String? fractionFlag = widget.leaveData.fractionOfLeave;
//
//       // Leave in fraction is true ONLY if we have valid time values AND fractional days
//       if (fractionFlag != null &&
//           (fractionFlag.toUpperCase() == "Y" ||
//               fractionFlag.toLowerCase() == "checked")) {
//         leaveInFraction = true;
//
//         // ✅ Set time fields
//         // if (_isValidTimeValue(widget.leaveData.fromTime)) {
//         //   fromTimeController.text =
//         //       _formatTimeTo12Hour(widget.leaveData.fromTime!);
//         // }
//         String fromtime = _formatTimeTo12Hour(widget.leaveData.fromTime!);
//         print("fromtime $fromtime");
//         fromTimeController.text = fromtime.toString();
//
//         // if (_isValidTimeValue(widget.leaveData.toTime)) {
//         //   toTimeController.text = _formatTimeTo12Hour(widget.leaveData.toTime!);
//         // }
//         String totime = _formatTimeTo12Hour(widget.leaveData.toTime!);
//         print("fromtime $totime");
//         toTimeController.text = totime.toString();
//
//         // Optional calculation
//         if (fromTimeController.text.isNotEmpty &&
//             toTimeController.text.isNotEmpty) {
//           _calculateTotalTime();
//         }
//       } else {
//         leaveInFraction = false;
//         fromTimeController.clear();
//         toTimeController.clear();
//       }
//
//       // Set selected leave type
//       // if (widget.leaveData.leaveType != null && widget.leaveData.leaveType!.isNotEmpty) {
//       //   selectedLeaveType = widget.leaveData.leaveType!;
//       // }
//
//       addressController.text = widget.leaveData.addrOnLeave.toString();
//       reasonController.text = widget.leaveData.reason.toString();
//       mobileController.text = widget.leaveData.mobileNo.toString();
//       transactionID = widget.leaveData.transactionId.toString();
//     } else {
//       print(widget.flag);
//       print("widget flag=1");
//       getData();
//     }
//     print("staffcode" + staffcode);
//     print("Flag: ${widget.flag}");
//     print("Leave Data: ${widget.leaveData.staffCode}");
//     print("Leave Data: ${widget.leaveData.fromTime}");
//   }
//
// // Add this helper method to check if time value is valid
//   bool _isValidTimeValue(String? timeValue) {
//     if (timeValue == null || timeValue.isEmpty) return false;
//
//     // Check for default/empty time values
//     if (timeValue == "00:00" || timeValue == "00:00:00") return false;
//
//     // Check if it's a valid time format (HH:MM or HH:MM:SS)
//     RegExp timeRegex =
//         RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');
//     if (!timeRegex.hasMatch(timeValue)) return false;
//
//     // Parse the time and check if it's within working hours (optional)
//     try {
//       List<String> parts = timeValue.split(':');
//       int hour = int.parse(parts[0]);
//       int minute = int.parse(parts[1]);
//
//       // Check if time is within reasonable range (optional)
//       // This ensures we don't treat midnight (00:00) as valid
//       if (hour == 0 && minute == 0) return false;
//
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   String _formatTimeTo12Hour(String timeString) {
//     try {
//       DateTime parsedTime = DateTime.parse(timeString);
//       return DateFormat('hh:mm a').format(parsedTime);
//     } catch (e) {
//       print("Error formatting time: $e");
//       return "";
//     }
//   }
//
//   Future<void> getLeaveBalances() async {
//     token = await storage.read(key: 'authtokenn');
//     year = await storage.read(key: "selectedYear");
//     staff_code = await storage.read(key: 'stafcodeee');
//
//     if (staff_code != null && token != null && year != null) {
//       mainBloc.add(GetLeavetypeEvents(
//           StaffCode: staff_code!, token: token!, Year: year!));
//     }
//   }
//
//   Future<void> getData() async {
//     staff_code = await storage.read(key: 'stafcodeee');
//     print("staffCodeeeee-->" + staff_code!);
//     token = await storage.read(key: 'authtokenn');
//     print("tokennn->" + token!);
//     year = await storage.read(key: "selectedYear");
//     print("year" + year!);
//     staff_name = await storage.read(key: 'staffname');
//     plant_name = await storage.read(key: 'plantname');
//     departmet = await storage.read(key: 'department');
//     joining_date = await storage.read(key: 'doj');
//     // staffcodede.text = staff_code!;
//     mainBloc.add(
//         GetLeavetypeEvents(StaffCode: staff_code!, token: token!, Year: year!));
//   }
//
//   Future<void> _pickDate(TextEditingController controller) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//
//     if (pickedDate != null) {
//       setState(() {
//         controller.text = '${pickedDate.day.toString().padLeft(2, '0')}/'
//             '${pickedDate.month.toString().padLeft(2, '0')}/'
//             '${pickedDate.year}';
//       });
//
//       _calculateDays(); // ✅ AUTO CALL
//     }
//   }
//
//   Future<void> _pickTime(
//       TimeOfDay? time, TextEditingController controller) async {
//     TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//
//     if (pickedTime != null) {
//       setState(() {
//         time = pickedTime;
//         controller.text = time!.format(context);
//       });
//
//       if (leaveInFraction) {
//         _calculateTotalTime(); // ✅ AUTO
//       }
//     }
//   }
//
//   void _calculateDays() {
//     if (fromDateController.text.isNotEmpty &&
//         toDateController.text.isNotEmpty) {
//       try {
//         String normalizedFromDate =
//             _normalizeDate(fromDateController.text.trim());
//         String normalizedToDate = _normalizeDate(toDateController.text.trim());
//
//         DateTime fromDate = DateTime.parse(normalizedFromDate);
//         DateTime toDate = DateTime.parse(normalizedToDate);
//
//         if (fromDate.isAfter(toDate)) {
//           setState(() {
//             totalDaysController.text = 'Select valid dates';
//           });
//           return;
//         }
//
//         double totalDays = 0.0;
//
//         if (fromDate.isAtSameMomentAs(toDate)) {
//           // Same day leave
//           if (Fromtimefirsthalf && !Totimefirsthalf) {
//             // First half to second half of same day
//             totalDays = 1.0;
//           } else if (!Fromtimefirsthalf && Totimefirsthalf) {
//             // Invalid case - second half to first half of same day
//             setState(() {
//               totalDaysController.text = 'Invalid selection';
//             });
//             Fluttertoast.showToast(
//                 msg: "Cannot select second half to first half on same day");
//             return;
//           } else {
//             // Either both first half or both second half
//             totalDays = 0.5;
//           }
//         } else {
//           // Different days
//           int fullDaysInBetween = toDate.difference(fromDate).inDays - 1;
//
//           // First day calculation
//           double fromDay = Fromtimefirsthalf ? 1.0 : 0.5;
//
//           // Last day calculation
//           double toDay = Totimefirsthalf ? 0.5 : 1.0;
//
//           totalDays = fromDay +
//               toDay +
//               (fullDaysInBetween > 0 ? fullDaysInBetween.toDouble() : 0);
//         }
//
//         setState(() {
//           totalDaysController.text = totalDays.toStringAsFixed(1);
//         });
//
//         print(
//             "Calculated from $normalizedFromDate to $normalizedToDate = $totalDays days");
//         Fluttertoast.showToast(msg: "Calculation Completed!!");
//       } catch (e) {
//         print("Error in _calculateDays: $e");
//         setState(() {
//           totalDaysController.text = 'Invalid date';
//         });
//       }
//     } else {
//       setState(() {
//         totalDaysController.text = 'Please select both dates';
//       });
//     }
//   }
//
//   String _normalizeDate(String date) {
//     try {
//       // Split the date string by '-' or '/'
//       List<String> parts =
//           date.contains('/') ? date.split('/') : date.split('/');
//       if (parts.length != 3) {
//         throw FormatException("Invalid date format: $date");
//       }
//
//       // Normalize day, month, and year
//       String day = parts[0].padLeft(2, '0'); // Ensure two digits for day
//       String month = parts[1].padLeft(2, '0'); // Ensure two digits for month
//       String year = parts[2];
//
//       return '$year-$month-$day'; // Return normalized format for DateTime.parse
//     } catch (e) {
//       throw FormatException("Error normalizing date: $date. $e");
//     }
//   }
//
//   void _calculateTotalTime() {
//     if (fromTimeController.text.isEmpty || toTimeController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Please select both From Time and To Time");
//       return;
//     }
//
//     try {
//       // Parse the selected time
//       DateTime fromDateTime =
//           DateFormat("hh:mm a").parse(fromTimeController.text);
//       DateTime toDateTime = DateFormat("hh:mm a").parse(toTimeController.text);
//
//       // Convert to Duration for validation and calculation
//       Duration fromDuration =
//           Duration(hours: fromDateTime.hour, minutes: fromDateTime.minute);
//       Duration toDuration =
//           Duration(hours: toDateTime.hour, minutes: toDateTime.minute);
//
//       // **Validation 1: From Time should not be before 08:30 AM**
//       Duration minAllowedTime = const Duration(hours: 8, minutes: 30);
//       if (fromDuration < minAllowedTime) {
//         Fluttertoast.showToast(msg: "From Time should not be before 08:30 AM");
//         totalDaysController.text = '';
//         return;
//       }
//
//       // **Validation 2: To Time should not be after 18:00 PM**
//       Duration maxAllowedTime = const Duration(hours: 18, minutes: 0);
//       if (toDuration > maxAllowedTime) {
//         Fluttertoast.showToast(msg: "To Time should not be after 18:00 PM");
//         totalDaysController.text = '';
//         return;
//       }
//
//       // **Validation 3: From Time and To Time cannot be the same**
//       if (fromDuration == toDuration) {
//         Fluttertoast.showToast(msg: "From Time and To Time cannot be the same");
//         totalDaysController.text = '';
//         return;
//       }
//
//       // **Validation 4: To Time cannot be before From Time**
//       if (toDuration < fromDuration) {
//         Fluttertoast.showToast(msg: "To Time cannot be before From Time");
//         totalDaysController.text = '';
//         return;
//       }
//
//       // Calculate the total difference in minutes
//       int totalMinutes = toDuration.inMinutes - fromDuration.inMinutes;
//
//       // **Validation 5: Ensure time does not exceed 480 minutes (8 hours)**
//       if (totalMinutes > 480) {
//         Fluttertoast.showToast(
//             msg: "Time should not exceed 8 hours (480 minutes)");
//         totalDaysController.text = '';
//         return;
//       }
//
//       // Update UI
//       setState(() {
//         totalDaysController.text = '$totalMinutes min';
//
//         // ✅ Convert minutes → days (480 min = 1 day)
//         double daysFromTime = totalMinutes / 510;
//
//         totalDaysController.text = daysFromTime.toStringAsFixed(2);
//       });
//     } catch (e) {
//       setState(() {
//         totalDaysController.text = 'Invalid Time Selection';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<MainBloc, MainState>(
//       listener: (context, state) {
//         if (state is GetLeaveTypeLoadingState) {
//           setState(() {
//             isLoading = true;
//           });
//         } else if (state is GetLeaveTypeLoadedState) {
//           setState(() {
//             isLoading = false;
//             leaveBalances = {};
//             for (var type in state.leavedetails.leaveTypes!) {
//               if (type.leaveTypeName != null && type.daysRemaining != null) {
//                 leaveBalances[type.leaveTypeName!] = type.daysRemaining!;
//               }
//             }
//             // Update balance for current leave type if not LWP
//             if (selectedLeaveType != 'Please Select' &&
//                 selectedLeaveType != 'LWP') {
//               leaveBalanceController.text =
//                   leaveBalances[selectedLeaveType] ?? '0';
//             }
//           });
//         } else if (state is GetLeaveTypeErrorState) {
//           setState(() {
//             isLoading = false;
//           });
//         }
//         if (state is GetSubmitLeaveLoadingState) {
//           setState(() {
//             isLoading = true;
//           });
//         } else if (state is GetSubmitLeaveLoadedState) {
//           setState(() {
//             isLoading = false;
//           });
//
//           Fluttertoast.showToast(
//               msg: widget.flag == 1 ? 'Leave submitted!' : 'Leave updated!');
//
//           // Navigate back with success flag
//           if (mounted) {
//             Navigator.of(context).pop(true); // Pass true to indicate success
//           }
//         } else if (state is GetSubmitLeaveErrorState) {
//           setState(() {
//             isLoading = false;
//           });
//           // Fluttertoast.showToast(msg: 'leave submitted');
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//             title: Text(widget.flag == 2 ? 'Update Details' : 'Enter Details')),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 10),
//                 DropdownButtonFormField<String>(
//                   value: selectedLeaveType,
//                   decoration: const InputDecoration(
//                     labelText: 'Leave Type',
//                     border: OutlineInputBorder(),
//                   ),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedLeaveType = value!;
//                       if (selectedLeaveType == 'LWP') {
//                         leaveBalanceController.text = '0';
//                       } else {
//                         // Get balance from the pre-fetched data
//                         leaveBalanceController.text =
//                             leaveBalances[selectedLeaveType]?.toString() ?? '0';
//                       }
//                     });
//                   },
//                   items: leaveTypes.map((leaveType) {
//                     return DropdownMenuItem(
//                       value: leaveType,
//                       child: Text(leaveType),
//                     );
//                   }).toList(),
//                 ),
//                 // Leave Balance
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     const Expanded(
//                       flex: 2,
//                       child: Text(
//                         'Leave Balance:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 3,
//                       child: TextField(
//                         controller: leaveBalanceController,
//                         decoration: const InputDecoration(
//                           hintText: 'Leave Balance',
//                           border: OutlineInputBorder(),
//                         ),
//                         readOnly: true,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 // From Date and Time
//                 Row(
//                   children: [
//                     Expanded(
//                       flex: 3,
//                       child: TextField(
//                         controller: fromDateController,
//                         readOnly: true,
//                         onTap: () => _pickDate(fromDateController),
//                         decoration: const InputDecoration(
//                           labelText: 'From Date',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     Expanded(
//                       flex: 2,
//                       child: Row(
//                         children: [
//                           Flexible(
//                             child: Radio<bool>(
//                               value: true, // First Half selected
//                               groupValue: Fromtimefirsthalf,
//                               onChanged: (value) {
//                                 setState(() {
//                                   Fromtimefirsthalf = value!;
//                                   Fromtimesecondhalf = !value;
//                                 });
//                                 _calculateDays(); // ✅ AUTO
//                               },
//                             ),
//                           ),
//                           const Text('1st Half'),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: Row(
//                         children: [
//                           Flexible(
//                             child: Radio<bool>(
//                               value: false, // Second Half selected
//                               groupValue: Fromtimefirsthalf,
//                               onChanged: (value) {
//                                 setState(() {
//                                   Fromtimefirsthalf = value!;
//                                   Fromtimesecondhalf = !value;
//                                 });
//                                 _calculateDays(); // ✅ AUTO
//                               },
//                             ),
//                           ),
//                           const Text('2nd Half'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
// // To Date and Time
//                 Row(
//                   children: [
//                     Expanded(
//                       flex: 3,
//                       child: TextField(
//                         controller: toDateController,
//                         readOnly: true,
//                         onTap: () => _pickDate(toDateController),
//                         decoration: const InputDecoration(
//                           labelText: 'To Date',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     Expanded(
//                       flex: 2,
//                       child: Row(
//                         children: [
//                           Flexible(
//                             child: Radio<bool>(
//                               value: true, // First Half selected
//                               groupValue: Totimefirsthalf,
//                               onChanged: (value) {
//                                 setState(() {
//                                   Totimefirsthalf = value!;
//                                   Totimesecondhalf = !value;
//                                 });
//                                 _calculateDays(); // ✅ AUTO
//                               },
//                             ),
//                           ),
//                           const Text('1st Half'),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: Row(
//                         children: [
//                           Flexible(
//                             child: Radio<bool>(
//                               value: false, // Second Half selected
//                               groupValue: Totimefirsthalf,
//                               onChanged: (value) {
//                                 setState(() {
//                                   Totimefirsthalf = value!;
//                                   Totimesecondhalf = !value;
//                                 });
//                                 _calculateDays(); // ✅ AUTO
//                               },
//                             ),
//                           ),
//                           const Text('2nd Half'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 //
//                 // Leave in Fraction Checkbox
//                 CheckboxListTile(
//                     title: const Text('Leave in Fraction'),
//                     value: leaveInFraction,
//                     onChanged: (value) {
//                       setState(() {
//                         leaveInFraction = value!;
//                       });
//
//                       if (leaveInFraction) {
//                         _calculateTotalTime(); // if already selected
//                       } else {
//                         _calculateDays(); // fallback to normal leave
//                       }
//                     }),
//                 if (leaveInFraction) ...[
//                   // From Time
//                   Row(
//                     children: [
//                       const Expanded(
//                         flex: 2,
//                         child: Text(
//                           'From Time:',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         flex: 3,
//                         child: TextField(
//                           controller: fromTimeController,
//                           readOnly: true,
//                           onTap: () => _pickTime(fromTime, fromTimeController),
//                           decoration: const InputDecoration(
//                             hintText: 'Select Time',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   // To Time
//                   Row(
//                     children: [
//                       const Expanded(
//                         flex: 2,
//                         child: Text(
//                           'To Time:',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Expanded(
//                         flex: 3,
//                         child: TextField(
//                           controller: toTimeController,
//                           readOnly: true,
//                           onTap: () => _pickTime(toTime, toTimeController),
//                           decoration: const InputDecoration(
//                             hintText: 'Select Time',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   // Total Time
//                 ],
//                 Row(
//                   children: [
//                     const Expanded(
//                       flex: 2,
//                       child: Text(
//                         'Total days:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 3,
//                       child: TextField(
//                         controller: totalDaysController,
//                         readOnly: true,
//                         decoration: const InputDecoration(
//                           hintText: 'Total Time',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: addressController,
//                   decoration: const InputDecoration(
//                     labelText: 'Address',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: reasonController,
//                   decoration: const InputDecoration(
//                     labelText: 'Reason',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: mobileController,
//                   keyboardType: TextInputType.phone,
//                   maxLength: 10,
//                   decoration: const InputDecoration(
//                     labelText: 'Mobile Number',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 // Center the submit button
//                 Center(
//                   child: SizedBox(
//                     width: 200, // Fixed width for the button
//                     child: ElevatedButton(
//                       onPressed: () {
//                         _validation(); // Calculate total days in all cases
//                       },
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: isLoading
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                               ),
//                             ) // Show loader when submitting
//                           : Text(
//                               widget.flag == 2
//                                   ? 'Update Details'
//                                   : 'Submit Leave',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20), // Add some bottom padding
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String formatDate(String date) {
//     DateTime parsedDate = DateTime.parse(date);
//     return "${parsedDate.day.toString().padLeft(2, '0')}/"
//         "${parsedDate.month.toString().padLeft(2, '0')}/"
//         "${parsedDate.year}";
//   }
//
//   void _validation() {
//     if (selectedLeaveType == "Please Select") {
//       Fluttertoast.showToast(msg: "Please Select Leave Type");
//       return;
//     }
//
//     if (fromDateController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Please Select From Date");
//       return;
//     }
//
//     if (toDateController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Please Select To Date");
//       return;
//     }
//
//     if (leaveInFraction) {
//       if (fromTimeController.text.isEmpty) {
//         Fluttertoast.showToast(msg: "Please select from time");
//         return;
//       }
//
//       if (toTimeController.text.isEmpty) {
//         Fluttertoast.showToast(msg: "Please select to time");
//         return;
//       }
//     }
//
//     if (addressController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Enter address");
//       return;
//     }
//
//     if (reasonController.text.isEmpty) {
//       Fluttertoast.showToast(msg: "Enter reason");
//       return;
//     }
//
//     if (mobileController.text.length != 10) {
//       Fluttertoast.showToast(msg: "Enter valid mobile number");
//       return;
//     }
//
//     // ✅ ONLY ONE CALL HERE
//     _addLeavedata();
//   }
//
//   _addLeavedata() {
//     String checkFlag = leaveInFraction ? "checked" : "";
//     double totalDays = double.tryParse(totalDaysController.text) ?? 0.0;
//
//     String formattedDays = totalDays.toStringAsFixed(2);
//
//     // Debug prints to verify values
//     print("Flag: ${widget.flag}");
//     print("Transaction ID: $transactionID");
//     print("Staff Code: $staff_code");
//
//     SubmitLeaveDetails leaveDetails = SubmitLeaveDetails(
//       flag: widget.flag == 1 ? "INSERT" : "UPDATE",
//       transactionId: widget.flag == 1 ? "" : transactionID,
//       staffCode: staff_code,
//       name: staff_name,
//       plant: plant_name,
//       doj: joining_date,
//       dept: departmet,
//       weeklyOff: "",
//       leaveType: selectedLeaveType,
//       leaveBalance: leaveBalanceController.text,
//       fromDate: fromDateController.text,
//       toDate: toDateController.text,
//       rdoFfirstHalf: leaveInFraction ? false : Fromtimefirsthalf,
//       rdoFSecondHalf: leaveInFraction ? false : Fromtimesecondhalf,
//       rdoTfirstHalf: leaveInFraction ? false : Totimefirsthalf,
//       rdoTsecondHalf: leaveInFraction ? false : Totimesecondhalf,
//       fromTime: leaveInFraction ? formatTo24Hour(fromTimeController.text) : '',
//       toTime: leaveInFraction ? formatTo24Hour(toTimeController.text) : '',
//       checkInFraction: checkFlag,
//       year: year,
//       totalDays: formattedDays,
//       reason: reasonController.text,
//       address: addressController.text,
//       mobileNo: mobileController.text,
//     );
//     print("Submitting leave: ${leaveDetails.toJson()}");
//     mainBloc.add(
//         SubmitLeaveEvents(submitleavedetails: leaveDetails, token: token!));
//   }
//
//   _clearFields() {
//     setState(() {
//       selectedLeaveType = 'Please Select';
//       leaveBalanceController.clear();
//       fromDateController.clear();
//       toDateController.clear();
//       totalDaysController.clear();
//       fromTimeController.clear();
//       toTimeController.clear();
//       addressController.clear();
//       reasonController.clear();
//       mobileController.clear();
//
//       // Reset all state variables
//       Fromtimefirsthalf = true;
//       Fromtimesecondhalf = false;
//       Totimefirsthalf = false;
//       Totimesecondhalf = true;
//       leaveInFraction = false;
//
//       // Clear any error states
//       transactionID = "";
//     });
//   }
//
//   String formatTo24Hour(String time) {
//     DateTime parsed = DateFormat("hh:mm a").parse(time);
//     return DateFormat("HH:mm").format(parsed);
//   }
// }

class _LeaveDetailsPageState extends State<LeaveDetailsPage> {
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staff_code = "";
  String? staff_name = "";
  String? plant_name = "";
  String? departmet = "";
  String? joining_date = "";
  String? token = "";
  String? year = "";
  bool isLoading = false;
  String transactionID = "";
  Map<String, String> leaveBalances = {};
  String staffcode = "";

  final leaveTypes = ['Please Select', 'CL', 'PL', 'SL', 'LWP'];
  String selectedLeaveType = 'Please Select';
  final TextEditingController leaveBalanceController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController totalDaysController = TextEditingController();
  final TextEditingController fromTimeController = TextEditingController();
  final TextEditingController toTimeController = TextEditingController();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  bool Fromtimefirsthalf = true;
  bool Fromtimesecondhalf = false;
  bool Totimefirsthalf = false;
  bool Totimesecondhalf = true;
  bool leaveInFraction = false;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;

  void initState() {
    mainBloc = BlocProvider.of(context);
    getLeaveBalances();
    if (widget.flag == 2) {
      staff_code = widget.leaveData.staffCode ?? '';
      fromDateController.text = formatDate(widget.leaveData.startingDate ?? '');
      toDateController.text = formatDate(widget.leaveData.endingDate ?? '');

      totalDaysController.text = widget.leaveData.noOfDays.toString();
      String? fractionFlag = widget.leaveData.fractionOfLeave;

      // Leave in fraction is true ONLY if we have valid time values AND fractional days
      if (fractionFlag != null &&
          (fractionFlag.toUpperCase() == "Y" ||
              fractionFlag.toLowerCase() == "checked")) {
        leaveInFraction = true;

        // ✅ Set time fields
        String fromtime = _formatTimeTo12Hour(widget.leaveData.fromTime!);
        print("fromtime $fromtime");
        fromTimeController.text = fromtime.toString();

        String totime = _formatTimeTo12Hour(widget.leaveData.toTime!);
        print("totime $totime");
        toTimeController.text = totime.toString();

        // Set the TimeOfDay objects for proper time picker display
        if (fromTimeController.text.isNotEmpty) {
          fromTime = _parseTimeOfDay(fromTimeController.text);
        }
        if (toTimeController.text.isNotEmpty) {
          toTime = _parseTimeOfDay(toTimeController.text);
        }

        // Optional calculation
        if (fromTimeController.text.isNotEmpty &&
            toTimeController.text.isNotEmpty) {
          _calculateTotalTime();
        }
      } else {
        leaveInFraction = false;
        fromTimeController.clear();
        toTimeController.clear();
      }

      addressController.text = widget.leaveData.addrOnLeave.toString();
      reasonController.text = widget.leaveData.reason.toString();
      mobileController.text = widget.leaveData.mobileNo.toString();
      transactionID = widget.leaveData.transactionId.toString();
    } else {
      print(widget.flag);
      print("widget flag=1");
      getData();
    }
    print("staffcode" + staffcode);
    print("Flag: ${widget.flag}");
    print("Leave Data: ${widget.leaveData.staffCode}");
    print("Leave Data: ${widget.leaveData.fromTime}");
  }

  // Helper method to parse time string to TimeOfDay
  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      DateTime parsed = DateFormat("hh:mm a").parse(timeString);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

// Add this helper method to check if time value is valid
  bool _isValidTimeValue(String? timeValue) {
    if (timeValue == null || timeValue.isEmpty) return false;

    // Check for default/empty time values
    if (timeValue == "00:00" || timeValue == "00:00:00") return false;

    // Check if it's a valid time format (HH:MM or HH:MM:SS)
    RegExp timeRegex =
        RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');
    if (!timeRegex.hasMatch(timeValue)) return false;

    // Parse the time and check if it's within working hours (optional)
    try {
      List<String> parts = timeValue.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Check if time is within reasonable range (optional)
      // This ensures we don't treat midnight (00:00) as valid
      if (hour == 0 && minute == 0) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatTimeTo12Hour(String timeString) {
    try {
      DateTime parsedTime = DateTime.parse(timeString);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      print("Error formatting time: $e");
      return "";
    }
  }

  Future<void> getLeaveBalances() async {
    token = await storage.read(key: 'authtokenn');
    year = await storage.read(key: "selectedYear");
    staff_code = await storage.read(key: 'stafcodeee');

    if (staff_code != null && token != null && year != null) {
      mainBloc.add(GetLeavetypeEvents(
          StaffCode: staff_code!, token: token!, Year: year!));
    }
  }

  Future<void> getData() async {
    staff_code = await storage.read(key: 'stafcodeee');
    print("staffCodeeeee-->" + staff_code!);
    token = await storage.read(key: 'authtokenn');
    print("tokennn->" + token!);
    year = await storage.read(key: "selectedYear");
    print("year" + year!);
    staff_name = await storage.read(key: 'staffname');
    plant_name = await storage.read(key: 'plantname');
    departmet = await storage.read(key: 'department');
    joining_date = await storage.read(key: 'doj');
    mainBloc.add(
        GetLeavetypeEvents(StaffCode: staff_code!, token: token!, Year: year!));
  }

  /*Future<void> _pickDate(TextEditingController controller) async {
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

      _calculateDays(); // ✅ AUTO CALL
    }
  }*/
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

      // Call appropriate calculation based on leaveInFraction flag
      if (leaveInFraction) {
        if (fromTimeController.text.isNotEmpty &&
            toTimeController.text.isNotEmpty) {
          _calculateTotalTime();
        }
      } else {
        _calculateDays();
      }
    }
  }

  /*Future<void> _pickTime(
      TimeOfDay? time, TextEditingController controller) async {
    // Use the existing time if available, otherwise use current time
    TimeOfDay initialTime = time ?? TimeOfDay.now();

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (controller == fromTimeController) {
          fromTime = pickedTime;
        } else if (controller == toTimeController) {
          toTime = pickedTime;
        }
        controller.text = pickedTime.format(context);
      });

      if (leaveInFraction) {
        _calculateTotalTime(); // ✅ AUTO
      }
    }
  }*/

  Future<void> _pickTime(
      TimeOfDay? time, TextEditingController controller) async {
    // Use the existing time if available, otherwise use current time
    TimeOfDay initialTime = time ?? TimeOfDay.now();

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (controller == fromTimeController) {
          fromTime = pickedTime;
        } else if (controller == toTimeController) {
          toTime = pickedTime;
        }
        controller.text = pickedTime.format(context);
      });

      if (leaveInFraction) {
        _calculateTotalTime(); // This will recalculate based on dates and times
      }
    }
  }

/*  void _calculateDays() {
    if (fromDateController.text.isNotEmpty &&
        toDateController.text.isNotEmpty) {
      try {
        String normalizedFromDate =
            _normalizeDate(fromDateController.text.trim());
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
            Fluttertoast.showToast(
                msg: "Cannot select second half to first half on same day");
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

          totalDays = fromDay +
              toDay +
              (fullDaysInBetween > 0 ? fullDaysInBetween.toDouble() : 0);
        }

        setState(() {
          totalDaysController.text = totalDays.toStringAsFixed(1);
        });

        print(
            "Calculated from $normalizedFromDate to $normalizedToDate = $totalDays days");
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
    // If leave in fraction is enabled, use time-based calculation instead
    if (leaveInFraction) {
      if (fromTimeController.text.isNotEmpty &&
          toTimeController.text.isNotEmpty) {
        _calculateTotalTime();
      } else {
        Fluttertoast.showToast(
            msg: "Please select both From Time and To Time for fraction leave");
      }
      return;
    }

    // Original half-day calculation for non-fraction leaves
    if (fromDateController.text.isNotEmpty &&
        toDateController.text.isNotEmpty) {
      try {
        String normalizedFromDate =
            _normalizeDate(fromDateController.text.trim());
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
            Fluttertoast.showToast(
                msg: "Cannot select second half to first half on same day");
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

          totalDays = fromDay +
              toDay +
              (fullDaysInBetween > 0 ? fullDaysInBetween.toDouble() : 0);
        }

        setState(() {
          totalDaysController.text = totalDays.toStringAsFixed(1);
        });

        print(
            "Calculated from $normalizedFromDate to $normalizedToDate = $totalDays days");
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
      List<String> parts =
          date.contains('/') ? date.split('/') : date.split('/');
      if (parts.length != 3) {
        throw FormatException("Invalid date format: $date");
      }

      // Normalize day, month, and year
      String day = parts[0].padLeft(2, '0'); // Ensure two digits for day
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
      DateTime fromDateTime =
          DateFormat("hh:mm a").parse(fromTimeController.text);
      DateTime toDateTime = DateFormat("hh:mm a").parse(toTimeController.text);

      // Convert to Duration for validation and calculation
      Duration fromDuration =
          Duration(hours: fromDateTime.hour, minutes: fromDateTime.minute);
      Duration toDuration =
          Duration(hours: toDateTime.hour, minutes: toDateTime.minute);

      // **Validation 1: From Time should not be before 08:30 AM**
      Duration minAllowedTime = const Duration(hours: 8, minutes: 30);
      if (fromDuration < minAllowedTime) {
        Fluttertoast.showToast(msg: "From Time should not be before 08:30 AM");
        totalDaysController.text = '';
        return;
      }

      // **Validation 2: To Time should not be after 18:00 PM**
      Duration maxAllowedTime = const Duration(hours: 18, minutes: 0);
      if (toDuration > maxAllowedTime) {
        Fluttertoast.showToast(msg: "To Time should not be after 18:00 PM");
        totalDaysController.text = '';
        return;
      }

      // **Validation 3: From Time and To Time cannot be the same**
      if (fromDuration == toDuration) {
        Fluttertoast.showToast(msg: "From Time and To Time cannot be the same");
        totalDaysController.text = '';
        return;
      }

      // **Validation 4: To Time cannot be before From Time**
      if (toDuration < fromDuration) {
        Fluttertoast.showToast(msg: "To Time cannot be before From Time");
        totalDaysController.text = '';
        return;
      }

      // Calculate the total difference in minutes
      int totalMinutes = toDuration.inMinutes - fromDuration.inMinutes;

      // **Validation 5: Ensure time does not exceed 480 minutes (8 hours)**
      if (totalMinutes > 480) {
        Fluttertoast.showToast(
            msg: "Time should not exceed 8 hours (480 minutes)");
        totalDaysController.text = '';
        return;
      }

      // Update UI
      setState(() {
        totalDaysController.text = '$totalMinutes min';

        // ✅ Convert minutes → days (480 min = 1 day)
        double daysFromTime = totalMinutes / 510;

        totalDaysController.text = daysFromTime.toStringAsFixed(2);
      });
    } catch (e) {
      setState(() {
        totalDaysController.text = 'Invalid Time Selection';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if (state is GetLeaveTypeLoadingState) {
          setState(() {
            isLoading = true;
          });
        } else if (state is GetLeaveTypeLoadedState) {
          setState(() {
            isLoading = false;
            leaveBalances = {};
            for (var type in state.leavedetails.leaveTypes!) {
              if (type.leaveTypeName != null && type.daysRemaining != null) {
                leaveBalances[type.leaveTypeName!] = type.daysRemaining!;
              }
            }
            // Update balance for current leave type if not LWP
            if (selectedLeaveType != 'Please Select' &&
                selectedLeaveType != 'LWP') {
              leaveBalanceController.text =
                  leaveBalances[selectedLeaveType] ?? '0';
            }
          });
        } else if (state is GetLeaveTypeErrorState) {
          setState(() {
            isLoading = false;
          });
        }
        if (state is GetSubmitLeaveLoadingState) {
          setState(() {
            isLoading = true;
          });
        } else if (state is GetSubmitLeaveLoadedState) {
          setState(() {
            isLoading = false;
          });

          Fluttertoast.showToast(
              msg: widget.flag == 1 ? 'Leave submitted!' : 'Leave updated!');

          // Navigate back with success flag
          if (mounted) {
            Navigator.of(context).pop(true); // Pass true to indicate success
          }
        } else if (state is GetSubmitLeaveErrorState) {
          setState(() {
            isLoading = false;
          });
          // Fluttertoast.showToast(msg: 'leave submitted');
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(widget.flag == 2 ? 'Update Details' : 'Enter Details')),
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
                    // Disable radio buttons when leaveInFraction is true
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Radio<bool>(
                              value: true, // First Half selected
                              groupValue: Fromtimefirsthalf,
                              onChanged: leaveInFraction
                                  ? null // Disable when leaveInFraction is true
                                  : (value) {
                                      setState(() {
                                        Fromtimefirsthalf = value!;
                                        Fromtimesecondhalf = !value;
                                      });
                                      _calculateDays(); // ✅ AUTO
                                    },
                            ),
                          ),
                          Text('1st Half',
                              style: TextStyle(
                                  color: leaveInFraction
                                      ? Colors.grey
                                      : Colors.black)),
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
                              onChanged: leaveInFraction
                                  ? null // Disable when leaveInFraction is true
                                  : (value) {
                                      setState(() {
                                        Fromtimefirsthalf = value!;
                                        Fromtimesecondhalf = !value;
                                      });
                                      _calculateDays(); // ✅ AUTO
                                    },
                            ),
                          ),
                          Text('2nd Half',
                              style: TextStyle(
                                  color: leaveInFraction
                                      ? Colors.grey
                                      : Colors.black)),
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
                    // Disable radio buttons when leaveInFraction is true
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Radio<bool>(
                              value: true, // First Half selected
                              groupValue: Totimefirsthalf,
                              onChanged: leaveInFraction
                                  ? null // Disable when leaveInFraction is true
                                  : (value) {
                                      setState(() {
                                        Totimefirsthalf = value!;
                                        Totimesecondhalf = !value;
                                      });
                                      _calculateDays(); // ✅ AUTO
                                    },
                            ),
                          ),
                          Text('1st Half',
                              style: TextStyle(
                                  color: leaveInFraction
                                      ? Colors.grey
                                      : Colors.black)),
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
                              onChanged: leaveInFraction
                                  ? null // Disable when leaveInFraction is true
                                  : (value) {
                                      setState(() {
                                        Totimefirsthalf = value!;
                                        Totimesecondhalf = !value;
                                      });
                                      _calculateDays(); // ✅ AUTO
                                    },
                            ),
                          ),
                          Text('2nd Half',
                              style: TextStyle(
                                  color: leaveInFraction
                                      ? Colors.grey
                                      : Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                //
                // Leave in Fraction Checkbox
                // CheckboxListTile(
                //     title: const Text('Leave in Fraction'),
                //     value: leaveInFraction,
                //     onChanged: (value) {
                //       setState(() {
                //         leaveInFraction = value!;
                //
                //         // Reset time-related states when unchecking
                //         if (!leaveInFraction) {
                //           fromTimeController.clear();
                //           toTimeController.clear();
                //           fromTime = null;
                //           toTime = null;
                //           _calculateDays(); // Recalculate days without fraction
                //         }
                //       });
                //     }),
                CheckboxListTile(
                    title: const Text('Leave in Fraction'),
                    value: leaveInFraction,
                    onChanged: (value) {
                      setState(() {
                        leaveInFraction = value!;

                        if (leaveInFraction) {
                          // When enabling fraction, check if we have both dates and times
                          if (fromDateController.text.isNotEmpty &&
                              toDateController.text.isNotEmpty &&
                              fromTimeController.text.isNotEmpty &&
                              toTimeController.text.isNotEmpty) {
                            _calculateTotalTime();
                          }
                        } else {
                          // When disabling fraction, clear time fields and recalculate with half-day logic
                          fromTimeController.clear();
                          toTimeController.clear();
                          fromTime = null;
                          toTime = null;
                          if (fromDateController.text.isNotEmpty &&
                              toDateController.text.isNotEmpty) {
                            _calculateDays();
                          }
                        }
                      });
                    }),
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
                ],
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Total days:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: totalDaysController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Total Time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
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
                const SizedBox(height: 30),
                // Center the submit button
                Center(
                  child: SizedBox(
                    width: 200, // Fixed width for the button
                    child: ElevatedButton(
                      onPressed: () {
                        _validation(); // Calculate total days in all cases
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ) // Show loader when submitting
                          : Text(
                              widget.flag == 2
                                  ? 'Update Details'
                                  : 'Submit Leave',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Add some bottom padding
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

  void _validation() {
    if (selectedLeaveType == "Please Select") {
      Fluttertoast.showToast(msg: "Please Select Leave Type");
      return;
    }

    if (fromDateController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please Select From Date");
      return;
    }

    if (toDateController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please Select To Date");
      return;
    }

    if (leaveInFraction) {
      if (fromTimeController.text.isEmpty) {
        Fluttertoast.showToast(msg: "Please select from time");
        return;
      }

      if (toTimeController.text.isEmpty) {
        Fluttertoast.showToast(msg: "Please select to time");
        return;
      }
    }

    if (addressController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter address");
      return;
    }

    if (reasonController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter reason");
      return;
    }

    if (mobileController.text.length != 10) {
      Fluttertoast.showToast(msg: "Enter valid mobile number");
      return;
    }

    // ✅ ONLY ONE CALL HERE
    _addLeavedata();
  }

  _addLeavedata() {
    String checkFlag = leaveInFraction ? "checked" : "";
    double totalDays = double.tryParse(totalDaysController.text) ?? 0.0;

    String formattedDays = totalDays.toStringAsFixed(2);

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
      // When leaveInFraction is true, send "N" for all half-day flags
      rdoFfirstHalf: leaveInFraction ? false : Fromtimefirsthalf,
      rdoFSecondHalf: leaveInFraction ? false : Fromtimesecondhalf,
      rdoTfirstHalf: leaveInFraction ? false : Totimefirsthalf,
      rdoTsecondHalf: leaveInFraction ? false : Totimesecondhalf,
      fromTime: leaveInFraction ? formatTo24Hour(fromTimeController.text) : '',
      toTime: leaveInFraction ? formatTo24Hour(toTimeController.text) : '',
      checkInFraction: checkFlag,
      year: year,
      totalDays: formattedDays,
      reason: reasonController.text,
      address: addressController.text,
      mobileNo: mobileController.text,
    );
    print("Submitting leave: ${leaveDetails.toJson()}");
    mainBloc.add(
        SubmitLeaveEvents(submitleavedetails: leaveDetails, token: token!));
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
      addressController.clear();
      reasonController.clear();
      mobileController.clear();

      // Reset all state variables
      Fromtimefirsthalf = true;
      Fromtimesecondhalf = false;
      Totimefirsthalf = false;
      Totimesecondhalf = true;
      leaveInFraction = false;

      // Clear any error states
      transactionID = "";
    });
  }

  String formatTo24Hour(String time) {
    DateTime parsed = DateFormat("hh:mm a").parse(time);
    return DateFormat("HH:mm").format(parsed);
  }
}

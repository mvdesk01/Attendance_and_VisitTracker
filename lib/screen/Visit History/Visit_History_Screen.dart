import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/Visit%20History/VisitHistoryTrack_Screen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../../database/database_helper.dart';
import '../../main.dart';
import '../../model/VisitReport/VisitRecordsResponse.dart';
import '../../model/VisitReport/VisitDetailedRecordsResponse.dart';
import '../MinutesOfTheMeetingForm.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});
  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late MainBloc mainBloc;
  final storage = const FlutterSecureStorage();
  String? staffCode = "";
  String? Auth_Token = "";
  List<Message> latLongList = [];
  bool _isLoading = false;
  
  late String date1 = '', todate1 = '';
  DateTime selectedDate = DateTime.now();
  DateTime selectedToDate = DateTime.now();
  
  List<Data> visitList = [];
  final formatter = DateFormat("dd/MM/yyyy hh:mm a");

  bool isVisitRunning = false;
  String visitDateMOM = '';
  String toTimeMOM = '';
  String vistNameMOM = '';
  late var activeVisit = '';

  @override
  void initState() {
    super.initState();
    date1 = Jiffy.now().format(pattern: 'dd/MM/yyyy');
    todate1 = Jiffy.now().format(pattern: 'dd/MM/yyyy');
    getData();
    remaningCountOfTrackingData();
  }

  Future<void> remaningCountOfTrackingData() async {
    final remaining = (await DatabaseHelper().getStoredLocations()).length;
    VisitState.countRemainingLatLong.value = remaining;
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    final value = await storage.read(key: 'isVisitRunning');
    activeVisit = (await storage.read(key: 'activeVisit'))?? '';
    Auth_Token = await storage.read(key: 'Auth_Token');

    setState(() {
      isVisitRunning = value == "true";
    });

    if (staffCode != null && Auth_Token != null) {
      mainBloc.add(GetVisitByFromDateToDate(
        UserId: staffCode!,
        pageNumber: 1,
        pageSize: 50,
        fromDate: date1,
        toDate: todate1,
        token: Auth_Token!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp, color: Colors.white, fontWeight: FontWeight.bold,),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Visit History", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        opacity: 0.3,
        color: Colors.black,
        progressIndicator: const CircularProgressIndicator(color: Colors.white),
        child: BlocListener<MainBloc, MainState>(
          listener: _handleBlocState,
          child: Column(
            children: [
              _buildDateFilterHeader(),
              Expanded(
                child: visitList.isEmpty ? _buildEmptyState() : _buildVisitList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBlocState(BuildContext context, MainState state) {
    if (state is GetVisitByFromDateToDateLoadingState || 
        state is GetVisitDetailedRecordsLoadingState || 
        state is GetMinutesOfMeetingFormNoLoadingState) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoading = false);
    }

    if (state is GetVisitByFromDateToDateLoadedState) {
      setState(() {
        visitList.clear();
        if (state.visitRecordsResponse!.data != null) {
          visitList.addAll(state.visitRecordsResponse!.data!);
        }
      });
    } else if (state is GetVisitByFromDateToDateErrorState) {
      Fluttertoast.showToast(msg: "Failed to load visit history");
    }

    if (state is GetVisitDetailedRecordsLoadedState) {
      if (state.visitDetailedRecordsResponse?.message is List<Message>) {
        latLongList = state.visitDetailedRecordsResponse!.message as List<Message>;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => MainBloc(webService: WebService()),
              child: VisitHistoryTrackScreen(latLongList: latLongList),
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "No tracking data available");
      }
    }

    if (state is GetMinutesOfMeetingFormNoLoadedState) {
      final srNo = state.getMinutesOfMeetingFormNoResponse.message!.srNo.toString();
      final formNo = state.getMinutesOfMeetingFormNoResponse.message!.minutesofMeetFormNo.toString();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => MainBloc(webService: WebService()),
            child: MinutesOfTheMeetingFormScreen(
              visitSrNo: srNo,
              minuteforno: formNo,
              visitDateMOM: visitDateMOM,
              toTimeMOM: toTimeMOM,
              visitNameMOM: vistNameMOM,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDateFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildDatePickerBox("From Date", date1, true)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 16),
          ),
          Expanded(child: _buildDatePickerBox("To Date", todate1, false)),
        ],
      ),
    );
  }

  Widget _buildDatePickerBox(String label, String value, bool isFromDate) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: isFromDate ? selectedDate : selectedToDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: MyColors.appDefaultColorCode),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            if (isFromDate) {
              selectedDate = picked;
              date1 = DateFormat('dd/MM/yyyy').format(picked);
            } else {
              selectedToDate = picked;
              todate1 = DateFormat('dd/MM/yyyy').format(picked);
            }
          });
          getData();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                const Icon(Icons.calendar_today_rounded, size: 14, color: MyColors.appDefaultColorCode),
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
          Image.asset("assets/icons/no_data.png", height: 120, opacity: const AlwaysStoppedAnimation(0.5)),
          const SizedBox(height: 20),
          Text("No visit records found", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text("Try changing the date range", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildVisitList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visitList.length,
      itemBuilder: (context, index) {
        final visit = visitList[index];
        final statusColor = _getStatusColor(visit);
        final statusText = _getStatusText(visit);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Status Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 8),
                    Text(statusText, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                    const Spacer(),
                    Text(visit.selectDate ?? "", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visit.reason ?? "Unnamed Visit", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.place_outlined, "Destination", visit.destination ?? "N/A"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time_rounded, "Time Range", "${visit.fromtime} - ${visit.totime}"),
                    
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (visit.status == "C" || visit.status == "S") ...[
                          Expanded(
                            child: _buildActionButton(
                              "TRACK",
                              Icons.map_outlined,
                              MyColors.fontBlue,
                              () {
                                String inputDate = visit.selectDate!;
                                DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(inputDate);
                                String formattedDate = DateFormat("dd-MMM-yyyy").format(parsedDate);
                                mainBloc.add(GetVisitDetailedRecordsEvent(
                                  StaffCode: staffCode!,
                                  FromDate: formattedDate,
                                  ToDate: formattedDate,
                                  SrNoVal: visit.srNo!.toString(),
                                  token: Auth_Token!,
                                ));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              "MOM",
                              Icons.assignment_outlined,
                              Colors.orange.shade700,
                              () {
                                visitDateMOM = visit.visitDate.toString();
                                toTimeMOM = visit.totime.toString();
                                vistNameMOM = visit.reason.toString();
                                mainBloc.add(GetMinutesOfMeetingFormNoEvents(
                                  UserId: staffCode!,
                                  SrNo: visit.srNo!.toString(),
                                  token: Auth_Token!,
                                ));
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: VisitState.countRemainingLatLong,
                      builder: (context, count, _) {
                        if (count > 0 && visit.status == "S") {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text("Pending sync: $count records", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "$label: ", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                TextSpan(text: value, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Color _getStatusColor(Data visit) {
    try {
      if (visit.status == "S") {
        DateTime endDateTime = formatter.parse("${visit.selectDate} ${visit.totime}");
        if (endDateTime.isBefore(DateTime.now())) return MyColors.blueColorCode; // Completed
        return isVisitRunning && activeVisit == visit.srNo.toString() ? MyColors.greenColorCode : Colors.red; // Started/Stopped
      }
      return MyColors.orangeColorCode; // Not Started
    } catch (_) {
      return MyColors.orangeColorCode;
    }
  }

  String _getStatusText(Data visit) {
    try {
      if (visit.status == "S") {
        DateTime endDateTime = formatter.parse("${visit.selectDate} ${visit.totime}");
        if (endDateTime.isBefore(DateTime.now())) return "COMPLETED";
        return isVisitRunning && activeVisit == visit.srNo.toString() ? "TRACKING ACTIVE" : "TRACKING STOPPED";
      }
      return "NOT STARTED";
    } catch (_) {
      return "PENDING";
    }
  }
}

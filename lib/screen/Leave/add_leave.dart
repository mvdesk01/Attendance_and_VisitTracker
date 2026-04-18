import 'package:attendance_system_ios/screen/Leave/apply_leave.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/Leave/LeavePendingResponse.dart';
import 'leave.dart';

class AddLeavePage extends StatefulWidget {
  final int flag;
  final dynamic leaveData;

  const AddLeavePage({super.key, required this.flag, required this.leaveData});
  @override
  _AddLeavePageState createState() => _AddLeavePageState();
}

class _AddLeavePageState extends State<AddLeavePage> {
  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _plantNameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _dojController = TextEditingController();
  
  late Message leaveDetailss;
  bool showTable = false;
  List<Map<String, String>> leaveDetailsList = [];
  String year = "2025";
  String? staffCode = "";
  String? authToken = "";

  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    authToken = await storage.read(key: 'Auth_Token');

    if (widget.leaveData != null) {
      leaveDetailss = widget.leaveData;
    } else {
      leaveDetailss = Message();
    }

    if (staffCode != null && authToken != null) {
      mainBloc.add(GetLeaveStaffDetails(StaffCode: staffCode!, token: authToken!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.3,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(color: Colors.white),
      child: Scaffold(
        // backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => MainBloc(webService: WebService()),
                  child: const PendingLeave(),
                ),
              ),
            ),
          ),
          title: Text(
            "Apply For Leave",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
          ),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
        ),
        body: BlocListener<MainBloc, MainState>(
          listener: (context, state) {
            if (state is GetLeaveStaffDetailsLoadingtstate) {
              setState(() => _isLoading = true);
            } else if (state is GetLeaveStaffDetailsLoadedtstate) {
              setState(() => _isLoading = false);
              _staffCodeController.text = state.staffdetails.message?.staffCode ?? "";
              _staffNameController.text = state.staffdetails.message?.fullName ?? "";
              _plantNameController.text = state.staffdetails.message?.plantName ?? "";
              _departmentController.text = state.staffdetails.message?.department ?? "";
              _dojController.text = "05/02/2025"; 
            } else if (state is GetLeaveStaffDetailsErrorState) {
              setState(() => _isLoading = false);
              Fluttertoast.showToast(msg: "Failed to fetch staff details");
            }

            if (state is GetLeaveTypeLoadingState) {
              setState(() => _isLoading = true);
            } else if (state is GetLeaveTypeLoadedState) {
              setState(() {
                _isLoading = false;
                leaveDetailsList = state.leavedetails.leaveTypes!.map((detail) {
                  return {
                    'Code': detail.leaveTypeCode.toString(),
                    'Leave Type': detail.leaveTypeName.toString(),
                    'Days Remaining': detail.daysRemaining.toString(),
                    'Total Days': detail.totalDays.toString(),
                    'Min Days Allowed': detail.minDaysAllowed.toString(),
                    'Max Days Allowed': detail.maxDaysAllowed.toString(),
                  };
                }).toList();
              });
            } else if (state is GetLeaveTypeErrorState) {
              setState(() => _isLoading = false);
              Fluttertoast.showToast(msg: "No Leave Details Found");
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Staff Information"),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildReadOnlyField('Staff Code', _staffCodeController, Icons.badge_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Year", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: year,
                                isExpanded: true,
                                items: ['2024', '2025', '2026']
                                    .map((y) => DropdownMenuItem(value: y, child: Text(y, style: GoogleFonts.poppins(fontSize: 14))))
                                    .toList(),
                                onChanged: (value) => setState(() => year = value!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: MyColors.lightBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          fixedSize: const Size(52, 52),
                        ),
                        onPressed: () {
                          setState(() => showTable = true);
                          if (staffCode != null && authToken != null) {
                            mainBloc.add(GetLeavetypeEvents(StaffCode: staffCode!, token: authToken!, Year: year));
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                
                _buildReadOnlyField('Staff Name', _staffNameController, Icons.person_outline_rounded),
                
                Row(
                  children: [
                    Expanded(child: _buildReadOnlyField('Plant Name', _plantNameController, Icons.factory_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildReadOnlyField('Department', _departmentController, Icons.account_tree_outlined)),
                  ],
                ),

                if (showTable) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle("Leave Balances"),
                  _buildLeaveTable(),
                ],

                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await storage.write(key: 'selectedYear', value: year);
                      await storage.write(key: 'stafcodeee', value: staffCode);
                      await storage.write(key: 'authtokenn', value: authToken);
                      await storage.write(key: 'staffname', value: _staffNameController.text);
                      await storage.write(key: 'doj', value: _dojController.text);
                      await storage.write(key: 'plantname', value: _plantNameController.text);
                      await storage.write(key: 'department', value: _departmentController.text);
                      
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider<MainBloc>(
                            create: (context) => MainBloc(webService: WebService()),
                            child: LeaveDetailsPage(
                              flag: 1,
                              tokennn: authToken!,
                              leaveData: leaveDetailss,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'PROCEED TO APPLY',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 6),
          TextFormField(
            readOnly: true,
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: MyColors.appDefaultColorCode, size: 20),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTable() {
    if (leaveDetailsList.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text("Click refresh to load balances", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13))),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 15,
            columnSpacing: 20,
            headingRowHeight: 45,
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            columns: [
              DataColumn(label: Text('Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Rem.', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Min', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text('Max', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13))),
            ],
            rows: leaveDetailsList.map((row) {
              return DataRow(cells: [
                DataCell(Text(row['Leave Type'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
                DataCell(Text(row['Days Remaining'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[700]))),
                DataCell(Text(row['Total Days'] ?? '', style: GoogleFonts.poppins(fontSize: 13))),
                DataCell(Text(row['Min Days Allowed'] ?? '', style: GoogleFonts.poppins(fontSize: 13))),
                DataCell(Text(row['Max Days Allowed'] ?? '', style: GoogleFonts.poppins(fontSize: 13))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  void parseAndSetDate(String? originalDOJ) {
    if (originalDOJ != null && originalDOJ.trim().isNotEmpty) {
      try {
        String formattedDate = _formatDate(originalDOJ);
        _dojController.text = formattedDate;
      } catch (e) {
        _dojController.text = "N/A";
      }
    } else {
      _dojController.text = "N/A";
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    try {
      String cleanedDate = date.replaceAll(RegExp(r'\s+'), ' ').trim();
      DateFormat inputFormat = DateFormat("MMM d yyyy h:mma");
      DateFormat outputFormat = DateFormat("dd/MM/yyyy");
      DateTime parsedDate = inputFormat.parse(cleanedDate);
      return outputFormat.format(parsedDate);
    } catch (e) {
      return "N/A";
    }
  }
}

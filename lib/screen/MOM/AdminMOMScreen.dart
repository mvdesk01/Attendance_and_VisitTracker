import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../cleanarchitecture/feature/MOM/domain/enteties/customer.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/meetinghistory_group.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/customerprovider.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/meetingHistory/meetinghistoryprovider.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';
import 'AdminMOMDetails.dart';

class AdminMomHistoryScreen extends ConsumerStatefulWidget {
  final Message datum;

  const AdminMomHistoryScreen({
    super.key,
    required this.datum,
  });

  @override
  ConsumerState<AdminMomHistoryScreen> createState() =>
      _AdminMomHistoryScreenState();
}

class _AdminMomHistoryScreenState extends ConsumerState<AdminMomHistoryScreen> {
  Customer? selectedCustomer;

  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();

    dateController = TextEditingController(
      text: DateFormat("dd/MM/yyyy").format(DateTime.now()),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerNotifierProvider.notifier).loadCustomersForStaff(
            widget.datum.staffCode.toString(),
          );
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateFormat("dd/MM/yyyy").parse(dateController.text),
      firstDate: DateTime(2024),
      lastDate: DateTime(2050),
    );

    if (picked == null) return;

    dateController.text = DateFormat("dd/MM/yyyy").format(picked);

    if (selectedCustomer != null) {
      loadHistory();
    }

    setState(() {});
  }

  Future<void> loadHistory() async {
    if (selectedCustomer == null) return;

    await ref.read(meetingHistoryNotifierProvider.notifier).loadMeetingHistory(
          customerCode: selectedCustomer!.customerCode,
          meetingDate: dateController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerNotifierProvider);
    final historyState = ref.watch(meetingHistoryNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        // scaffoldLineWidth: 0, <-- REMOVE THIS LINE
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Admin MOM History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: customerState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF2563EB),
              ),
            )
          : Column(
              children: [
                // Top Filter Section Container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    children: [
                      // Customer Dropdown
                      DropdownButtonFormField<Customer>(
                        value: selectedCustomer,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: "Select Customer",
                          prefixIcon: const Icon(
                            Icons.business_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: customerState.customers
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.customerName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          if (value == null) return;

                          setState(() {
                            selectedCustomer = value;
                          });

                          await loadHistory();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Meeting Date Picker Field
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: "Meeting Date",
                          prefixIcon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.edit_calendar_rounded,
                              size: 20,
                              color: Color(0xFF2563EB),
                            ),
                            onPressed: pickDate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // History List / Empty / Loading State
                Expanded(
                  child: historyState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF2563EB),
                          ),
                        )
                      : historyState.meetingHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.event_busy_rounded,
                                      size: 48,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No Meetings Found",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Select a customer or change date to view logs",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: historyState.meetingHistory.length,
                              itemBuilder: (_, index) {
                                final MeetingHistoryGroup meeting =
                                    historyState.meetingHistory[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Customer Title Header
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.assignment_rounded,
                                                color: Color(0xFF2563EB),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                meeting.customer,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                        const SizedBox(height: 14),

                                        // Meeting Timing Information
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInfoTile(
                                                icon: Icons
                                                    .calendar_today_rounded,
                                                label: "Meeting Date",
                                                value: meeting.meetingDate,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildInfoTile(
                                                icon: Icons.access_time_rounded,
                                                label: "Meeting Time",
                                                value: meeting.meetingTime,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Attendance Stats Row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildBadgeTile(
                                                icon: Icons
                                                    .check_circle_outline_rounded,
                                                label: "Present",
                                                value: meeting.memberPresent,
                                                color: const Color(0xFF16A34A),
                                                bgColor:
                                                    const Color(0xFFDCFCE7),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildBadgeTile(
                                                icon:
                                                    Icons.highlight_off_rounded,
                                                label: "Absent",
                                                value: meeting.memberAbsent,
                                                color: const Color(0xFFDC2626),
                                                bgColor:
                                                    const Color(0xFFFEE2E2),
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (meeting
                                            .nextMeetingDate.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          _buildInfoTile(
                                            icon: Icons.event_repeat_rounded,
                                            label: "Next Meeting",
                                            value: meeting.nextMeetingDate,
                                            accentColor:
                                                const Color(0xFFD97706),
                                          ),
                                        ],

                                        const SizedBox(height: 16),

                                        // View Summary Button
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF2563EB),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: const Text(
                                              "View Summary",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            label: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AdminMomDetailsScreen(
                                                    meeting: meeting,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                )
              ],
            ),
    );
  }

  // Helper widget for rendering metadata fields neatly
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color accentColor = const Color(0xFF64748B),
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for colored pill badges (Attendance stats)
  Widget _buildBadgeTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

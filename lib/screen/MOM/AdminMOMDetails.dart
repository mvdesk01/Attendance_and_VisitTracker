import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../cleanarchitecture/feature/MOM/domain/enteties/meetinghistory_group.dart';

class AdminMomDetailsScreen extends StatelessWidget {
  final MeetingHistoryGroup meeting;

  const AdminMomDetailsScreen({
    super.key,
    required this.meeting,
  });

  Widget field({
    required String title,
    required String value,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value.isEmpty ? "-" : value,
                  maxLines: maxLines,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget headerCell(
    String text,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      color: const Color(0xFF1E293B),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget bodyCell(String text, double width, {bool isOdd = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isOdd ? const Color(0xFFF8FAFC) : Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          right: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SelectableText(
        text.isEmpty ? "-" : text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF334155),
          height: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          "Meeting Summary",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata Overview Card
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Meeting Info",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  field(
                    title: "Customer",
                    value: meeting.customer,
                    icon: Icons.business_rounded,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          title: "Meeting Date",
                          value: meeting.meetingDate,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: field(
                          title: "Meeting Time",
                          value: meeting.meetingTime,
                          icon: Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: field(
                          title: "Member Present",
                          value: meeting.memberPresent,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: field(
                          title: "Member Absent",
                          value: meeting.memberAbsent,
                          icon: Icons.highlight_off_rounded,
                        ),
                      ),
                    ],
                  ),
                  field(
                    title: "Next Meeting Date",
                    value: meeting.nextMeetingDate,
                    icon: Icons.event_repeat_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Discussion Points Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.question_answer_outlined,
                    color: Color(0xFF0D9488),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Discussion Points",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  "${meeting.discussionPoints.length} Items",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Modern Styled Data Table Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          headerCell("Sr", 50),
                          headerCell("Discussion Point", 260),
                          headerCell("Discussed With", 180),
                          headerCell("Decision", 220),
                          headerCell("Responsibility", 200),
                          headerCell("Target Date", 130),
                        ],
                      ),
                      if (meeting.discussionPoints.isEmpty)
                        Container(
                          width: 1040,
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Text(
                            "No discussion points recorded",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ...List.generate(
                          meeting.discussionPoints.length,
                          (index) {
                            final point = meeting.discussionPoints[index];
                            final isOdd = index % 2 != 0;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bodyCell("${index + 1}", 50, isOdd: isOdd),
                                bodyCell(point.point, 260, isOdd: isOdd),
                                bodyCell(point.discussedWith, 180,
                                    isOdd: isOdd),
                                bodyCell(point.decision, 220, isOdd: isOdd),
                                bodyCell(point.responsibility, 200,
                                    isOdd: isOdd),
                                bodyCell(point.targetDate, 130, isOdd: isOdd),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

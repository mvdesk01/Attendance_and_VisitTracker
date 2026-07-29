/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen 1 – Minutes of the Meeting: List / landing screen.
/// Lets the user pick a customer, shows the previous meeting (if any)
/// for that customer, and lets them start a new meeting.
class MinutesOfTheMeetingFormScreen extends StatefulWidget {
  const MinutesOfTheMeetingFormScreen({Key? key}) : super(key: key);

  @override
  State<MinutesOfTheMeetingFormScreen> createState() =>
      MinutesOfTheMeetingFormScreenState();
}

class MinutesOfTheMeetingFormScreenState
    extends State<MinutesOfTheMeetingFormScreen> {
  final List<String> customerNames = const [
    'MTech Hinjewadi',
    'MTech KD',
  ];

  String? selectedCustomer = 'MTech Hinjewadi';

  final Map<String, Map<String, String>> previousMeetings = const {
    'MTech Hinjewadi': {
      'date': '26/07/2026',
      'time': '02:00 PM',
      'membersPresent': 'Shreya, Rahul, Aniket',
    },
  };

  // Color Palette Constants
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Slate Blue
  static const Color accentColor = Color(0xFF2563EB); // Modern Blue
  static const Color backgroundColor =
      Color(0xFFF8FAFC); // Very Soft Neutral Slate
  static const Color cardBorderColor = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final previousMeeting =
        selectedCustomer != null ? previousMeetings[selectedCustomer] : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        //co: Scaffold.of(context).widget.backgroundColor,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Minutes of the Meeting",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18.0,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: cardBorderColor, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerSelectorCard(),
              const SizedBox(height: 20),
              if (previousMeeting != null)
                _buildPreviousMeetingCard(previousMeeting)
              else
                _buildEmptyMeetingCard(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cardBorderColor, width: 1)),
        ),
        child: _buildAddNewMeetingButton(),
      ),
    );
  }

  Widget _buildCustomerSelectorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.business_rounded,
            title: "Select Customer",
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCustomer,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: textSecondary),
            style: GoogleFonts.inter(
                fontSize: 15, color: textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: "Customer Name *",
              labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.apartment_rounded,
                  color: accentColor, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor, width: 1.5),
              ),
            ),
            items: customerNames
                .map((name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCustomer = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousMeetingCard(Map<String, String> meeting) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(
                icon: Icons.history_rounded,
                title: "Previous Meeting",
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Recorded",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: cardBorderColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: "Date",
                  value: meeting['date'] ?? '-',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  icon: Icons.access_time_rounded,
                  label: "Time",
                  value: meeting['time'] ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.groups_outlined,
            label: "Members Present",
            value: meeting['membersPresent'] ?? '-',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Opening previous meeting details...",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(
                "View Meeting Summary",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded,
                color: textSecondary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            "No Previous Meetings",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "No recorded minutes found for $selectedCustomer.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewMeetingButton() {
    return ElevatedButton.icon(
      onPressed: selectedCustomer == null
          ? null
          : () {
              // Navigation logic here
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        "Create New Minutes of Meeting",
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({Key? key, required this.icon, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
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
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'addmeeting.dart';

// Dummy placeholder for destination screen
// class AddMeetingScreen extends StatelessWidget {
//   final String customerName;
//
//   const AddMeetingScreen({super.key, required this.customerName});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Add Meeting - $customerName')),
//       body: Center(child: Text('Add Meeting Form for $customerName')),
//     );
//   }
// }

class MinutesOfTheMeetingFormScreen extends StatefulWidget {
  const MinutesOfTheMeetingFormScreen({super.key});

  @override
  State<MinutesOfTheMeetingFormScreen> createState() =>
      _MinutesOfTheMeetingFormScreenState();
}

class _MinutesOfTheMeetingFormScreenState
    extends State<MinutesOfTheMeetingFormScreen> {
  // Hardcoded customer list
  final List<String> customerNames = const [
    'MTech Hinjewadi',
    'MTech KD',
  ];

  String? selectedCustomer = 'MTech Hinjewadi';

  // Hardcoded "previous meeting" records
  final Map<String, Map<String, String>> previousMeetings = const {
    'MTech Hinjewadi': {
      'date': '26/07/2026',
      'time': '2:00 PM',
      'membersPresent': 'Shreya, Rahul, Aniket',
      'membersAbsent': 'Sushmita'
    },
  };

  @override
  Widget build(BuildContext context) {
    final previousMeeting =
        selectedCustomer != null ? previousMeetings[selectedCustomer] : null;

    // Theme tokens
    final primaryColor = const Color(0xFF0F172A); // Slate 900
    final accentColor = const Color(0xFF4F46E5); // Indigo 600
    final backgroundColor = const Color(0xFFF8FAFC); // Slate 50

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Minutes of Meeting",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18.0,
              color: primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("CUSTOMER SELECTION"),
                const SizedBox(height: 10),
                _buildCustomerCard(primaryColor, accentColor),
                const SizedBox(height: 28),
                _buildSectionHeader("LAST RECORDED MEETING"),
                const SizedBox(height: 10),
                if (previousMeeting != null)
                  _buildPreviousMeetingCard(previousMeeting, accentColor)
                else
                  _buildNoMeetingCard(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: selectedCustomer == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMeetingScreen(
                              customerName: selectedCustomer!,
                            ),
                          ),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  "Create New Minutes",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCustomerCard(Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Customer Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                " *",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedCustomer,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B)),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              prefixIcon: const Icon(
                Icons.business_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: customerNames
                .map((name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCustomer = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousMeetingCard(
      Map<String, String> meeting, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history_rounded,
                        color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Meeting Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: "Date",
                  value: meeting['date'] ?? '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaChip(
                  icon: Icons.access_time_rounded,
                  label: "Time",
                  value: meeting['time'] ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaChip(
            icon: Icons.people_outline_rounded,
            label: "Members Present",
            value: meeting['membersPresent'] ?? '-',
          ),
          const SizedBox(height: 12),
          _buildMetaChip(
            icon: Icons.people_outline_rounded,
            label: "Members Present",
            value: meeting['membersAbsent'] ?? '-',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Opening previous meeting record...",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text(
                "View Meeting Summary",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMeetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.event_note_rounded, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            "No Previous Meetings",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4),
          Text(
            "There are no past meeting records for this customer.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

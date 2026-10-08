import 'dart:async';

import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/presentation/provider/responsibility/responsibilityprovider.dart';
import 'package:attendance_system_ios/screen/MOM/textinputformatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../cleanarchitecture/core/storage/mom_draft_service.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/customer.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/meeting.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/meetinghistory_group.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/meetingpoints.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/submitmeeting_request.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/customerprovider.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/decision/decisionprovider.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/submeeting/submitmeetingprovider.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/submeeting/submitmeetingstate.dart';
import 'discusspointrow.dart';
import 'discusspointtable.dart';

class AddMeetingScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final MeetingHistoryGroup? meetingHistory; // Add this parameter
  final bool isEditing;
  final String? meetingId;

  final DateTime? selectedMeetingDate;

  const AddMeetingScreen(
      {Key? key,
      required this.customer,
      this.meetingHistory,
      this.meetingId,
      this.selectedMeetingDate,
      this.isEditing = false})
      : super(key: key);

  @override
  ConsumerState<AddMeetingScreen> createState() => _AddMeetingScreenState();
}
//test

///test
class _AddMeetingScreenState extends ConsumerState<AddMeetingScreen> {
  // Initialize Secure Storage
  final storage = const FlutterSecureStorage();

  String? _staffName;
  bool _isLoadingStaff = true;
  Timer? _draftTimer;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  final TextEditingController presentInputController = TextEditingController();
  final TextEditingController absentInputController = TextEditingController();

  List<String> dynamicPresentMembers = [];
  List<String> dynamicAbsentMembers = [];

  // Discussion point tracking
  List<GlobalKey<DiscussionPointRowState>> rowKeys = [];
  List<Widget> discussionRows = [];
  List<Map<String, String>> initialDiscussionPoints = [];

  bool _timeInitialized = false;
  List<bool> rowIsExisting = [];

  // Design Tokens
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Slate Blue
  static const Color accentColor = Color(0xFF2563EB); // Modern Blue
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBorderColor = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadStaffName();
    Future.microtask(() async {
      print("Calling Decision");
      await ref
          .read(decisionNotifierProvider.notifier)
          .loadDecisions(forceRefresh: true);

      print("Calling Responsibility");
      await ref
          .read(responsibilityNotifierProvider.notifier)
          .loadResponsibility(forceRefresh: true);

      if (!widget.isEditing) {
        await _checkForDraft();
      }
    });

    selectedDate = widget.selectedMeetingDate ?? DateTime.now();
    selectedTime = TimeOfDay.now();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    timeController.text =
        "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    addDiscussionRow();
  }

  @override
  void onBackpressed() {}

  void _initializeFromMeeting() {
    final meeting = widget.meetingHistory!;

    dateController.text = meeting.meetingDate;

    timeController.text = meeting.meetingTime;

    selectedDate = DateFormat("dd/MM/yyyy").parse(meeting.meetingDate);

    final parsedTime = DateFormat("HH:mm").parse(meeting.meetingTime);

    selectedTime = TimeOfDay(
      hour: parsedTime.hour,
      minute: parsedTime.minute,
    );

    dynamicPresentMembers = meeting.memberPresent
        .split(",")
        .map((e) => e.trim())
        .where((e) =>
            e.isNotEmpty && e.toLowerCase() != (_staffName ?? "").toLowerCase())
        .toList();

    dynamicAbsentMembers =
        meeting.memberAbsent.split(",").map((e) => e.trim()).toList();

    presentInputController.text = dynamicPresentMembers.join(",");

    absentInputController.text = dynamicAbsentMembers.join(",");

    initialDiscussionPoints = meeting.discussionPoints
        .map((e) => {
              "point": e.point,
              "discussedWith": e.discussedWith,
              "decisionTaken": e.decision,
              "responsibility": e.responsibility,
              "targetDate": e.targetDate,
            })
        .toList();
    rowKeys.clear();
    rowIsExisting.clear();

    for (int i = 0; i < initialDiscussionPoints.length; i++) {
      rowKeys.add(GlobalKey<DiscussionPointRowState>());
      rowIsExisting.add(true);
    }

    _rebuildDiscussionRows();

    /// VERY IMPORTANT
    /// Existing data should be used only once.
    //  initialDiscussionPoints.clear();
  }

  Future<void> _checkForDraft() async {
    if (widget.isEditing) return;

    final draft = await MomDraftService.getDraft(
      customerCode: widget.customer.customerCode,
    );

    if (draft == null || !mounted) return;

    final draftData = draft['draftData'] as Map<String, dynamic>;

    final continueDraft = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Draft Found"),
          content: const Text(
            "A previous unfinished MOM was found for this customer. "
            "Do you want to continue it?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Start New"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Continue Draft"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (continueDraft == true) {
      await _restoreDraft(draftData);
    } else if (continueDraft == false) {
      await MomDraftService.deleteDraft(
        customerCode: widget.customer.customerCode,
      );
    }
  }

  Map<String, dynamic> _buildDraftData() {
    final discussionPoints = <Map<String, dynamic>>[];

    for (final key in rowKeys) {
      final rowState = key.currentState;

      if (rowState != null) {
        discussionPoints.add(
          rowState.getDraftData(),
        );
      }
    }

    return {
      "meetingDate": dateController.text,
      "meetingTime": timeController.text,
      "presentMembers": List<String>.from(
        dynamicPresentMembers,
      ),
      "absentMembers": List<String>.from(
        dynamicAbsentMembers,
      ),
      "discussionPoints": discussionPoints,
    };
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;

    final customerState = ref.read(customerNotifierProvider);

    final customer = customerState.selectedCustomer;

    if (customer == null) {
      return;
    }

    final draftData = _buildDraftData();

    await MomDraftService.saveDraft(
      customerCode: customer.customerCode,
      customerName: customer.customerName,
      draftData: draftData,
    );

    print(
      "MOM DRAFT SAVED: ${customer.customerCode}",
    );
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();

    _draftTimer = Timer(
      const Duration(milliseconds: 800),
      () async {
        await _saveDraft();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_timeInitialized) {
      if (widget.meetingHistory == null) {
        timeController.text =
            "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
      }

      _timeInitialized = true;
    }
  }

  Future<Map<String, dynamic>?> _loadDraft() async {
    final draft = await MomDraftService.getDraft(
      customerCode: widget.customer.customerCode,
    );

    return draft?['draftData'] as Map<String, dynamic>?;
  }

  Future<void> _restoreDraft(Map<String, dynamic> draftData) async {
    if (!mounted) return;

    setState(() {
      dateController.text = draftData['meetingDate']?.toString() ?? '';

      timeController.text = draftData['meetingTime']?.toString() ?? '';

      dynamicPresentMembers =
          List<String>.from(draftData['presentMembers'] ?? []);

      dynamicAbsentMembers =
          List<String>.from(draftData['absentMembers'] ?? []);

      presentInputController.text = dynamicPresentMembers.join(",");

      absentInputController.text = dynamicAbsentMembers.join(",");

      final discussionPoints = List<Map<String, dynamic>>.from(
        (draftData['discussionPoints'] ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );

      rowKeys.clear();
      rowIsExisting.clear();
      initialDiscussionPoints.clear();

      for (final point in discussionPoints) {
        rowKeys.add(
          GlobalKey<DiscussionPointRowState>(),
        );

        rowIsExisting.add(false);

        initialDiscussionPoints.add({
          "point": point['point']?.toString() ?? '',
          "discussedWith": point['discussedWith']?.toString() ?? '',
          "decisionTaken": point['decision']?.toString() ?? '',
          "decisionCode": point['decisionCode']?.toString() ?? '',
          "otherDecisionText": point['otherDecisionText']?.toString() ?? '',
          "responsibility": point['responsibilityNames']?.toString() ?? '',
          "responsibilityCodes": point['responsibilityCodes']?.toString() ?? '',
          "targetDate": point['targetDate']?.toString() ?? '',
        });
      }

      if (rowKeys.isEmpty) {
        rowKeys.add(
          GlobalKey<DiscussionPointRowState>(),
        );

        rowIsExisting.add(false);
        initialDiscussionPoints.add({});
      }

      _rebuildDiscussionRows();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final key in rowKeys) {
          key.currentState?.restoreResponsibilities();
        }
      });
    });

    print("MOM DRAFT RESTORED");
  }

  /// Fetches staff name from FlutterSecureStorage
  Future<void> _loadStaffName() async {
    final fetchedName = await storage.read(key: 'Staff_Name');

    setState(() {
      _staffName = fetchedName ?? "";
      _isLoadingStaff = false;
    });

    if (widget.isEditing && widget.meetingHistory != null) {
      _initializeFromMeeting();
    }
  }

  /// Parses comma-separated string into a list of cleaned member names
  void _updateMembersFromInput(String text, bool isPresent) {
    List<String> parsed = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      if (isPresent) {
        dynamicPresentMembers = parsed;
      } else {
        dynamicAbsentMembers = parsed;
      }
    });
    _scheduleDraftSave();
  }

  Future<bool> _confirmBack() async {
    final shouldGoBack = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Go Back?"),
          content: const Text(
            "Do you want to go back? Any unsaved data will be lost.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    return shouldGoBack ?? false;
  }

  bool validateForm() {
    // Meeting Date
    if (dateController.text.trim().isEmpty) {
      showError("Please select meeting date.");
      return false;
    }

    // Meeting Time
    if (timeController.text.trim().isEmpty) {
      showError("Please select meeting time.");
      return false;
    }

    // Members Present
    final presentMembers = <String>[
      if (_staffName != null && _staffName!.trim().isNotEmpty) _staffName!,
      ...dynamicPresentMembers,
    ];

    if (presentMembers.isEmpty) {
      showError("Please enter at least one member present.");
      return false;
    }

    // Discussion Point
    if (rowKeys.isEmpty) {
      showError("Please add at least one discussion point.");
      return false;
    }

    for (int i = 0; i < rowKeys.length; i++) {
      final row = rowKeys[i].currentState;

      if (row == null) continue;

      if (!row.validate()) {
        showError("Please complete Discussion Point ${i + 1}.");
        return false;
      }
    }

    return true;
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void addDiscussionRow() {
    setState(() {
      rowKeys.add(
        GlobalKey<DiscussionPointRowState>(),
      );

      initialDiscussionPoints.add({});

      rowIsExisting.add(false);

      _rebuildDiscussionRows();
    });
    // _scheduleDraftSave();
  }

  void _rebuildDiscussionRows([Map<String, String>? initialData]) {
    discussionRows = List.generate(
      rowKeys.length,
      (index) {
        Map<String, String>? data;

        if (index < initialDiscussionPoints.length &&
            rowKeys[index].currentState == null) {
          data = initialDiscussionPoints[index];
        }

        return DiscussionPointRow(
          key: rowKeys[index],
          serialNumber: index + 1,
          customerCode: widget.customer.customerCode,
          initialData: data,
          isExisting: rowIsExisting[index],
          onDelete: () {
            deleteDiscussionRow(index);
          },
          onDraftChanged: () {
            _scheduleDraftSave();
          },
        );
      },
    );
  }

  void deleteDiscussionRow(int deleteIndex) {
    if (rowKeys.length <= 1) return;

    setState(() {
      rowKeys.removeAt(deleteIndex);

      if (deleteIndex < initialDiscussionPoints.length) {
        initialDiscussionPoints.removeAt(deleteIndex);
      }

      rowIsExisting.removeAt(deleteIndex);

      _rebuildDiscussionRows();
    });
    _scheduleDraftSave();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
    _scheduleDraftSave();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
        timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
    _scheduleDraftSave();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(meetingSubmitNotifierProvider);

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final shouldGoBack = await _confirmBack();

          if (shouldGoBack && mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: textPrimary, size: 20),
              onPressed: () async {
                final shouldGoBack = await _confirmBack();

                if (shouldGoBack && mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              widget.isEditing ? "Update Meeting Details" : "Add New Meeting",
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
              padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 100, // important
              ),
              // padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeetingDetailsCard(),
                  const SizedBox(height: 24),
                  DiscussionPointTable(
                    rows: discussionRows,
                    onAdd: addDiscussionRow,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomActionBar(submitState),
        ));
  }

  Widget _buildMeetingDetailsCard() {
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
            children: [
              const Icon(Icons.description_outlined,
                  color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                "Meeting Overview",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: cardBorderColor),
          const SizedBox(height: 16),

          // Customer Name Field
          _fieldLabel("Customer Name"),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            controller: TextEditingController(
              text: widget.customer.customerName,
            ),
            onChanged: (_) {
              _scheduleDraftSave();
            },
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              prefixIcon: const Icon(Icons.business_rounded,
                  color: textSecondary, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time Fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel("Date"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      onChanged: (_) {
                        _scheduleDraftSave();
                      },
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      style:
                          GoogleFonts.inter(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: cardBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: accentColor, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_outlined,
                            color: accentColor, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel("Time"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      onTap: () => _selectTime(context),
                      style:
                          GoogleFonts.inter(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: cardBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: accentColor, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.access_time_rounded,
                            color: accentColor, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Members Present Section
          _fieldLabel("Members Present"),
          const SizedBox(height: 8),
          _isLoadingStaff
              ? const SizedBox(
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: accentColor),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      inputFormatters: [
                        TitleCaseTextFormatter(),
                      ],
                      controller: presentInputController,
                      style: GoogleFonts.inter(fontSize: 14),
                      onChanged: (val) => _updateMembersFromInput(val, true),
                      decoration: InputDecoration(
                        hintText:
                            "Add members separated by comma (e.g. John, Sarah)",
                        hintStyle: GoogleFonts.inter(
                            color: textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: cardBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: accentColor, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.group_add_outlined,
                            color: textSecondary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Ineditable Fetched Staff Chip (Clean & Simple, No Lock Icon)
                        if (_staffName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Text(
                              _staffName!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ...dynamicPresentMembers.map(
                          (name) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 16),

          // Members Absent Section
          _fieldLabel("Members Absent", required: false),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                inputFormatters: [
                  TitleCaseTextFormatter(),
                ],
                controller: absentInputController,
                style: GoogleFonts.inter(fontSize: 14),
                onChanged: (val) => _updateMembersFromInput(val, false),
                decoration: InputDecoration(
                  hintText: "Add absent members separated by comma",
                  hintStyle:
                      GoogleFonts.inter(color: textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: accentColor, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.person_off_outlined,
                      color: textSecondary, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              if (dynamicAbsentMembers.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dynamicAbsentMembers
                      .map(
                        (name) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = true}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        if (required)
          const Text(
            " *",
            style: TextStyle(
                fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildDiscussionSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.format_list_bulleted_rounded,
                color: primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              "Discussion Points",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: addDiscussionRow,
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            "Add Point",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(
    MeetingSubmitState submitState,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: cardBorderColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textSecondary,
                  side: const BorderSide(
                    color: cardBorderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: submitState.isLoading
                    ? null
                    : () async {
                        if (!validateForm()) {
                          return;
                        }

                        final staffCode = await storage.read(
                          key: "Staff_Code",
                        );

                        /// Present Members
                        final allPresent = <String>[
                          if (_staffName != null) _staffName!,
                          ...dynamicPresentMembers,
                        ].toSet().toList();

                        /// Meeting Entity
                        final meeting = Meeting(
                          meetingId: widget.isEditing
                              ? widget.meetingHistory!.meetingId
                              : "",
                          customerCode: widget.customer.customerCode,
                          memberPresent: allPresent.join(","),
                          memberAbsent: dynamicAbsentMembers.join(","),
                          meetingDateTime:
                              "${dateController.text} ${timeController.text}",
                          nextMeetingDate: dateController.text,
                          entryBy: staffCode!,
                          flag: widget.isEditing ? "U" : "I",
                        );

                        /// Discussion Points
                        final List<DiscussionPoint> points = [];

                        // for (final key in rowKeys) {
                        //   print("Rows = ${rowKeys.length}");
                        //   print("Points = ${points.length}");
                        //   final row = key.currentState;
                        //
                        //   if (row != null) {
                        //     points.add(
                        //       row.getDiscussionPoint(
                        //         entryBy: staffCode,
                        //       ),
                        //     );
                        //   }
                        // }
                        for (int i = 0; i < rowKeys.length; i++) {
                          print("Rows = ${rowKeys.length}");
                          print("Points = ${points.length}");

                          final row = rowKeys[i].currentState;

                          if (row != null) {
                            final isLast = i == rowKeys.length - 1;

                            points.add(
                              row.getDiscussionPoint(
                                entryBy: staffCode,
                                last: isLast ? "Y" : "N",
                              ),
                            );
                          }
                        }
                        print("result$points");

                        final request = SubmitMeetingRequest(
                          meeting: meeting,
                          discussionPoints: points,
                        );
                        print("result$request");

                        await ref
                            .read(meetingSubmitNotifierProvider.notifier)
                            .submitMeeting(request);

                        if (!mounted) return;

                        final state = ref.read(meetingSubmitNotifierProvider);

                        if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final result = state.result;

                        if (result == null) return;

                        // if (result.meetingSaved && result.pointsSaved) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     SnackBar(
                        //       content: Text(result.meetingMessage),
                        //       backgroundColor: Colors.green,
                        //     ),
                        //   );
                        //
                        //   Navigator.pop(context, true);
                        // }
                        if (result.meetingSaved && result.pointsSaved) {
                          final customerState =
                              ref.read(customerNotifierProvider);

                          final customer = customerState.selectedCustomer;

                          if (customer != null) {
                            await MomDraftService.deleteDraft(
                              customerCode: customer.customerCode,
                            );
                          }

                          // Existing success code
                          if (mounted) {
                            Navigator.pop(context, true);
                          }
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Submission Result"),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(result.meetingMessage),
                                    const SizedBox(height: 12),
                                    ...result.pointMessages.map(
                                      (e) => Text("• $e"),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                )
                              ],
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                icon: submitState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                label: Text(
                  submitState.isLoading
                      ? "Submitting..."
                      : widget.isEditing
                          ? "Update Meeting"
                          : "Save Meeting",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

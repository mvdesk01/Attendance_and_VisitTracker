/// Screen 2 – Add New Meeting.
/// Meeting header fields (customer, date, time, members present/absent)
/// plus a dynamic list of Discussion Point cards.
/*class AddMeetingScreen extends StatefulWidget {
  final String customerName;

  const AddMeetingScreen({Key? key, required this.customerName})
      : super(key: key);

  @override
  State<AddMeetingScreen> createState() => _AddMeetingScreenState();
}

class _AddMeetingScreenState extends State<AddMeetingScreen> {
  // Hardcoded logged-in staff name
  static const String loggedInStaffName = "Rahul Sharma";

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  List<String> membersPresent = [loggedInStaffName];
  List<String> membersAbsent = [];

  // Discussion point cards
  List<GlobalKey<_DiscussionPointCardState>> rowKeys = [];
  List<Widget> discussionRows = [];

  bool _timeInitialized = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    // Note: TimeOfDay.format() needs MaterialLocalizations via context,
    // which isn't available yet in initState() — set it below instead.
    // Start with one discussion point card by default
    addDiscussionRow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timeInitialized) {
      timeController.text = selectedTime.format(context);
      _timeInitialized = true;
    }
  }

  void addDiscussionRow() {
    final key = GlobalKey<_DiscussionPointCardState>();
    setState(() {
      rowKeys.add(key);
      discussionRows.add(
        DiscussionPointCard(
          key: key,
          serialNumber: discussionRows.length + 1,
          onDelete: () => deleteDiscussionRow(rowKeys.indexOf(key)),
        ),
      );
    });
  }

  void deleteDiscussionRow(int deleteIndex) {
    setState(() {
      discussionRows.removeAt(deleteIndex);
      rowKeys.removeAt(deleteIndex);

      // Rebuild remaining cards so serial numbers stay in sync
      for (int i = 0; i < discussionRows.length; i++) {
        final key = rowKeys[i];
        discussionRows[i] = DiscussionPointCard(
          key: key,
          serialNumber: i + 1,
          onDelete: () => deleteDiscussionRow(rowKeys.indexOf(key)),
        );
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 15)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _addMemberDialog({required bool isPresentList}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isPresentList ? "Add Present Member" : "Add Absent Member",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter member name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (isPresentList) {
          membersPresent.add(result);
        } else {
          membersAbsent.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Meeting",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildDiscussionSectionHeader(),
              const SizedBox(height: 14),
              Column(children: discussionRows),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined,
                    color: Colors.blue.shade800, size: 26),
                const SizedBox(width: 10),
                Text(
                  "Meeting Details",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Customer Name (pre-filled, read-only)
            _fieldLabel("Customer Name"),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: widget.customerName),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.business_rounded,
                    color: Colors.blue.shade700, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time
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
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.blue.shade700, width: 2),
                          ),
                          prefixIcon: Icon(Icons.calendar_today_rounded,
                              color: Colors.blue.shade700, size: 20),
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
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.blue.shade700, width: 2),
                          ),
                          prefixIcon: Icon(Icons.access_time_rounded,
                              color: Colors.blue.shade700, size: 20),
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

            // Members Present
            _fieldLabel("Members Present"),
            const SizedBox(height: 8),
            _buildChipInput(
              members: membersPresent,
              chipColor: Colors.green.shade50,
              chipTextColor: Colors.green.shade800,
              chipBorderColor: Colors.green.shade200,
              onAdd: () => _addMemberDialog(isPresentList: true),
              onRemove: (name) {
                setState(() => membersPresent.remove(name));
              },
            ),
            const SizedBox(height: 16),

            // Members Absent
            _fieldLabel("Members Absent", required: false),
            const SizedBox(height: 8),
            _buildChipInput(
              members: membersAbsent,
              chipColor: Colors.red.shade50,
              chipTextColor: Colors.red.shade800,
              chipBorderColor: Colors.red.shade200,
              onAdd: () => _addMemberDialog(isPresentList: false),
              onRemove: (name) {
                setState(() => membersAbsent.remove(name));
              },
              emptyHint: "No absent members added",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipInput({
    required List<String> members,
    required Color chipColor,
    required Color chipTextColor,
    required Color chipBorderColor,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    String? emptyHint,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (members.isEmpty && emptyHint != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              emptyHint,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ...members.map(
          (name) => Chip(
            label: Text(
              name,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: chipTextColor,
              ),
            ),
            backgroundColor: chipColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: chipBorderColor),
            ),
            deleteIcon:
                Icon(Icons.close_rounded, size: 16, color: chipTextColor),
            onDeleted: () => onRemove(name),
          ),
        ),
        ActionChip(
          avatar:
              Icon(Icons.add_rounded, size: 16, color: Colors.blue.shade700),
          label: Text(
            "Add",
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          backgroundColor: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue.shade200),
          ),
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, {bool required = true}) {
    return Row(
      children: [
        Text(label,
            style:
                GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600)),
        if (required)
          const Padding(
            padding: EdgeInsets.only(left: 3.0),
            child: Text("*", style: TextStyle(fontSize: 16, color: Colors.red)),
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
            Icon(Icons.format_list_bulleted_rounded,
                color: Colors.indigo.shade700, size: 26),
            const SizedBox(width: 8),
            Text(
              "Discussion Points",
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: addDiscussionRow,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            "Add Row",
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 75,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBottomButton(
                icon: Icons.close_rounded,
                label: "Cancel",
                color: Colors.red.shade700,
                onTap: () => Navigator.pop(context),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Meeting saved successfully",
              style: GoogleFonts.roboto(fontSize: 15),
            ),
            backgroundColor: Colors.indigo.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              "Save",
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single "Discussion Point" card shown in the dynamic list.
class DiscussionPointCard extends StatefulWidget {
  final int serialNumber;
  final VoidCallback onDelete;

  const DiscussionPointCard({
    Key? key,
    required this.serialNumber,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DiscussionPointCard> createState() => _DiscussionPointCardState();
}

class _DiscussionPointCardState extends State<DiscussionPointCard> {
  final TextEditingController pointController = TextEditingController();
  final TextEditingController discussedWithController = TextEditingController();
  final TextEditingController targetDateController = TextEditingController();

  String? decisionTaken;
  List<String> selectedResponsibility = [];

  // Hardcoded "Decision Taken" options
  final List<String> decisionOptions = const [
    'Approved',
    'Pending',
    'Rejected',
    'In Progress',
    'On Hold',
  ];

  // Hardcoded "Responsibility" options
  final List<String> responsibilityOptions = const [
    'Shreya',
    'Manish',
    'Sushmita',
    'Abhishek',
  ];

  Map<String, String> getRowData() {
    return {
      'point': pointController.text,
      'discussedWith': discussedWithController.text,
      'decisionTaken': decisionTaken ?? '',
      'responsibility': selectedResponsibility.join(', '),
      'targetDate': targetDateController.text,
    };
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        targetDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _openResponsibilityPicker(BuildContext context) async {
    List<String> tempSelection = List.from(selectedResponsibility);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Responsibility",
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...responsibilityOptions.map((name) {
                    final isChecked = tempSelection.contains(name);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(name, style: const TextStyle(fontSize: 15)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.indigo.shade700,
                      onChanged: (checked) {
                        setModalState(() {
                          if (checked == true) {
                            tempSelection.add(name);
                          } else {
                            tempSelection.remove(name);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context, tempSelection),
                      child: Text(
                        "Done",
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedResponsibility = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Serial number badge + delete icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.indigo.shade700,
                        child: Text(
                          '${widget.serialNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Discussion Point ${widget.serialNumber}",
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade600, size: 22),
                  tooltip: "Delete Item",
                ),
              ],
            ),
            const Divider(height: 24),

            _buildFormField(
              controller: pointController,
              label: "Point",
              hint: "Enter discussion point",
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            _buildFormField(
              controller: discussedWithController,
              label: "Discussed With",
              hint: "Enter person or team name",
            ),
            const SizedBox(height: 14),

            // Decision Taken dropdown
            _cardFieldLabel("Decision Taken"),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: decisionTaken,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.indigo.shade700),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.indigo.shade600, width: 2),
                ),
                hintText: "Select decision",
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
              items: decisionOptions
                  .map((d) => DropdownMenuItem<String>(
                        value: d,
                        child: Text(d),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => decisionTaken = value);
              },
            ),
            const SizedBox(height: 14),

            // Responsibility multi-select
            _cardFieldLabel("Responsibility"),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openResponsibilityPicker(context),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded,
                        size: 18, color: Colors.indigo.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: selectedResponsibility.isEmpty
                          ? Text(
                              "Select responsible person(s)",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade400),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: selectedResponsibility
                                  .map(
                                    (name) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.indigo.shade100),
                                      ),
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded,
                        color: Colors.indigo.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Target Date
            _cardFieldLabel("Target Date"),
            const SizedBox(height: 6),
            TextField(
              controller: targetDateController,
              readOnly: true,
              style: const TextStyle(fontSize: 14),
              onTap: () => _selectTargetDate(context),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Colors.indigo.shade600, width: 2),
                ),
                hintText: "DD/MM/YYYY",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                suffixIcon: Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.indigo.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
            ),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddMeetingScreen extends StatefulWidget {
  final String customerName;

  const AddMeetingScreen({Key? key, required this.customerName})
      : super(key: key);

  @override
  State<AddMeetingScreen> createState() => _AddMeetingScreenState();
}

class _AddMeetingScreenState extends State<AddMeetingScreen> {
  // Initialize Secure Storage
  final storage = const FlutterSecureStorage();

  String? _staffName;
  bool _isLoadingStaff = true;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  final TextEditingController presentInputController = TextEditingController();
  final TextEditingController absentInputController = TextEditingController();

  List<String> dynamicPresentMembers = [];
  List<String> dynamicAbsentMembers = [];

  // Discussion point tracking
  List<GlobalKey<_DiscussionPointCardState>> rowKeys = [];
  List<Widget> discussionRows = [];

  bool _timeInitialized = false;

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
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);

    _loadStaffName();
    addDiscussionRow();
  }

  /// Fetches staff name from FlutterSecureStorage
  Future<void> _loadStaffName() async {
    final String? fetchedName = await storage.read(key: 'Staff_Name');

    setState(() {
      _staffName = fetchedName ?? "Staff Member";
      _isLoadingStaff = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timeInitialized) {
      timeController.text = selectedTime.format(context);
      _timeInitialized = true;
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
  }

  // void addDiscussionRow() {
  //   final key = GlobalKey<_DiscussionPointCardState>();
  //   setState(() {
  //     rowKeys.add(key);
  //     discussionRows.add(
  //       DiscussionPointCard(
  //         key: key,
  //         serialNumber: discussionRows.length + 1,
  //         onDelete: () => deleteDiscussionRow(rowKeys.indexOf(key)),
  //       ),
  //     );
  //   });
  // }
  void addDiscussionRow() {
    final key = GlobalKey<_DiscussionPointCardState>();
    setState(() {
      rowKeys.insert(0, key);

      // Rebuild rows list to assign updated serial numbers
      _rebuildDiscussionRows();
    });
  }

  void _rebuildDiscussionRows() {
    discussionRows = List.generate(rowKeys.length, (index) {
      final key = rowKeys[index];

      // Total count - current index gives reverse display numbering,
      // OR use (rowKeys.length - index) so the newest card gets the highest number at top.
      final pointNumber = rowKeys.length - index;

      return DiscussionPointCard(
        key: key,
        serialNumber: pointNumber,
        onDelete: () => deleteDiscussionRow(index),
      );
    });
  }

  // void deleteDiscussionRow(int deleteIndex) {
  //   if (discussionRows.length <= 1) return;
  //   setState(() {
  //     discussionRows.removeAt(deleteIndex);
  //     rowKeys.removeAt(deleteIndex);
  //
  //     for (int i = 0; i < discussionRows.length; i++) {
  //       final key = rowKeys[i];
  //       discussionRows[i] = DiscussionPointCard(
  //         key: key,
  //         serialNumber: i + 1,
  //         onDelete: () => deleteDiscussionRow(rowKeys.indexOf(key)),
  //       );
  //     }
  //   });
  // }
  void deleteDiscussionRow(int deleteIndex) {
    if (rowKeys.length <= 1) return;

    setState(() {
      rowKeys.removeAt(deleteIndex);
      _rebuildDiscussionRows();
    });
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
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Meeting",
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
              _buildMeetingDetailsCard(),
              const SizedBox(height: 24),
              _buildDiscussionSectionHeader(),
              const SizedBox(height: 16),
              Column(children: discussionRows),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
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
            controller: TextEditingController(text: widget.customerName),
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cardBorderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: textSecondary,
                side: const BorderSide(color: cardBorderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
              onPressed: () {
                // Collect total present members
                List<String> allPresent = [];
                if (_staffName != null) allPresent.add(_staffName!);
                allPresent.addAll(dynamicPresentMembers);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Saved with ${allPresent.length} members present.",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                "Save Meeting",
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
}

class DiscussionPointCard extends StatefulWidget {
  final int serialNumber;
  final VoidCallback onDelete;

  const DiscussionPointCard({
    Key? key,
    required this.serialNumber,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DiscussionPointCard> createState() => _DiscussionPointCardState();
}

class _DiscussionPointCardState extends State<DiscussionPointCard> {
  final TextEditingController pointController = TextEditingController();
  final TextEditingController discussedWithController = TextEditingController();
  final TextEditingController targetDateController = TextEditingController();

  String? decisionTaken;
  List<String> selectedResponsibility = [];

  // Options
  final List<String> decisionOptions = const [
    'Approved',
    'In Progress',
    'Pending',
    'On Hold',
    'Rejected',
  ];

  final List<String> responsibilityOptions = const [
    'Shreya',
    'Manish',
    'Sushmita',
    'Abhishek',
  ];

  // Modern Palette Constants
  static const Color primaryColor = Color(0xFF1E3A8A); // Slate Blue
  static const Color accentColor = Color(0xFF2563EB); // Modern Blue
  static const Color cardBorderColor = Color(0xFFE2E8F0);
  static const Color inputBgColor = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  Map<String, String> getRowData() {
    return {
      'point': pointController.text,
      'discussedWith': discussedWithController.text,
      'decisionTaken': decisionTaken ?? '',
      'responsibility': selectedResponsibility.join(', '),
      'targetDate': targetDateController.text,
    };
  }

  /// Returns contextual color palette for decision status tags
  Map<String, Color> _getDecisionColors(String? decision) {
    switch (decision) {
      case 'Approved':
        return {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF15803D)};
      case 'In Progress':
        return {'bg': const Color(0xFFEFF6FF), 'text': const Color(0xFF1D4ED8)};
      case 'Pending':
        return {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFFB45309)};
      case 'On Hold':
        return {'bg': const Color(0xFFF1F5F9), 'text': const Color(0xFF475569)};
      case 'Rejected':
        return {'bg': const Color(0xFFFEE2E2), 'text': const Color(0xFFB91C1C)};
      default:
        return {'bg': inputBgColor, 'text': textSecondary};
    }
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        targetDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _openResponsibilityPicker(BuildContext context) async {
    List<String> tempSelection = List.from(selectedResponsibility);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Assign Responsibility",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select members accountable for this discussion point",
                    style:
                        GoogleFonts.inter(fontSize: 13, color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: cardBorderColor),
                  const SizedBox(height: 8),
                  ...responsibilityOptions.map((name) {
                    final isChecked = tempSelection.contains(name);
                    return CheckboxListTile(
                      value: isChecked,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: accentColor,
                      onChanged: (checked) {
                        setModalState(() {
                          if (checked == true) {
                            tempSelection.add(name);
                          } else {
                            tempSelection.remove(name);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context, tempSelection),
                      child: Text(
                        "Confirm Selection (${tempSelection.length})",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedResponsibility = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final decisionColorMap = _getDecisionColors(decisionTaken);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badge + Delete Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.serialNumber}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Point #${widget.serialNumber}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 20),
                tooltip: "Delete Discussion Point",
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: cardBorderColor),
          const SizedBox(height: 16),

          // Point / Discussion Summary
          _buildFormField(
            controller: pointController,
            label: "Point",
            hint: "Enter what was discussed or proposed...",
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          // Discussed With Field
          _buildFormField(
            controller: discussedWithController,
            label: "Discussed With",
            hint: "e.g. Client Team, Product Manager",
            prefixIcon: Icons.forum_outlined,
          ),
          const SizedBox(height: 14),

          // Decision Taken Dropdown
          _cardFieldLabel("Decision Taken"),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: decisionTaken,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: textSecondary),
            style: GoogleFonts.inter(
                fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: decisionColorMap['bg'],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentColor, width: 1.5),
              ),
              hintText: "Select decision status",
              hintStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
            ),
            items: decisionOptions
                .map((d) => DropdownMenuItem<String>(
                      value: d,
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: _getDecisionColors(d)['text'],
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => decisionTaken = value);
            },
          ),
          const SizedBox(height: 14),

          // Responsibility Multi-Select Field
          _cardFieldLabel("Responsibility"),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openResponsibilityPicker(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 18, color: textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: selectedResponsibility.isEmpty
                        ? Text(
                            "Tap to assign person(s)",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: textSecondary),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: selectedResponsibility
                                .map(
                                  (name) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Target Date Field
          _cardFieldLabel("Target Date"),
          const SizedBox(height: 6),
          TextField(
            controller: targetDateController,
            readOnly: true,
            style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
            onTap: () => _selectTargetDate(context),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBgColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentColor, width: 1.5),
              ),
              hintText: "DD/MM/YYYY",
              hintStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: accentColor, width: 1.5),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: textSecondary, size: 18)
                : null,
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
          ),
        ),
      ],
    );
  }
}

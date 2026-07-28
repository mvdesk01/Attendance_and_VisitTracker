import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingDataByVisitSrNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMALLDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMRowDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/UpdateMMAllData.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/UpdateMMData.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../../model/MinutesOfTheMettingForm/CustomerList.dart';
import '../../../util/DialogForUpdate.dart';
import '../../../util/MyColor.dart';
import '../Visit History/Visit_History_Screen.dart';

class MOMSFormScreen extends StatefulWidget {
  final String visitSrNo;
  final String minuteforno;
  final String visitDateMOM;
  final String toTimeMOM;
  final String visitNameMOM;

  const MOMSFormScreen({
    Key? key,
    required this.visitSrNo,
    required this.minuteforno,
    required this.visitDateMOM,
    required this.toTimeMOM,
    required this.visitNameMOM,
  }) : super(key: key);

  @override
  State<MOMSFormScreen> createState() =>
      _MinutesOfTheMeetingFormScreenState();
}

class _MinutesOfTheMeetingFormScreenState extends State<MOMSFormScreen> {
  final TextEditingController _gatepassdatecontroller = TextEditingController();
  final TextEditingController _memberAbsentController = TextEditingController();
  final TextEditingController _memberPresentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController fromTimeInput = TextEditingController();
  final TextEditingController customerSearchController = TextEditingController();

  bool isUpdateMode = false;
  bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = const FlutterSecureStorage();

  List<String> srNoTable = [];
  String? authToken = "";
  String? staffCode = "";
  String mainSrNo = "";

  List<Widget> dynamicRows = [];
  bool _isFormEdited = false;
  final List<GlobalKey<_DynamicRowState>> rowKeys = [];

  List<Message> listofRows = [];
  bool _isSubmitting = false;

  List<CustomerData> customerList = [];
  CustomerData? selectedCustomer;
  String? selectedCustCodeFromAPI;

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of<MainBloc>(context);
    _initializeData();
  }

  @override
  void dispose() {
    _gatepassdatecontroller.dispose();
    _memberAbsentController.dispose();
    _memberPresentController.dispose();
    _subjectController.dispose();
    fromTimeInput.dispose();
    customerSearchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _gatepassdatecontroller.text = DateFormat('dd/MM/yyyy')
        .format(Jiffy.parse(widget.visitDateMOM).dateTime);
    fromTimeInput.text = widget.toTimeMOM;
    _subjectController.text = widget.visitNameMOM;
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    authToken = await storage.read(key: 'Auth_Token');

    if (authToken != null) {
      mainBloc.add(GetMinutesOfTheMeetingAllDataByVisitSrNoEvents(
          token: authToken!, SrNo: widget.visitSrNo));

      mainBloc.add(GetMinutesOfTheMeetingDataByVisitSrNoEvents(
          token: authToken!, VisitSrNo: widget.visitSrNo));
    }

    mainBloc.add(GetVisitClientListEvent(pagenumber: 1, pagesize: 50));
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(msg: msg, toastLength: Toast.LENGTH_SHORT);
  }

  void handleSaveOrUpdate() {
    if (!_validateMainForm()) return;

    final allRowsData = _getAndValidateAllRowsData();
    if (allRowsData == null) return;

    if (isUpdateMode) {
      _updateMinutesOfTheMeetingForm(allRowsData);
    } else {
      if (_isSubmitting) return;
      _addMinutesOfTheMeetingForm(allRowsData);
    }
  }

  bool _validateMainForm() {
    if (_gatepassdatecontroller.text.isEmpty) return _errorToast("Please Select Date");
    if (fromTimeInput.text.isEmpty) return _errorToast("Please Select Time");
    if (_subjectController.text.isEmpty) return _errorToast("Please Enter Subject");
    if (selectedCustomer == null) return _errorToast("Please Select Client");
    if (_memberPresentController.text.isEmpty) return _errorToast("Please Enter Member Present");
    if (_memberAbsentController.text.isEmpty) return _errorToast("Please Enter Member Absent");
    return true;
  }

  bool _errorToast(String msg) {
    _showToast(msg);
    return false;
  }

  List<Map<String, String>>? _getAndValidateAllRowsData() {
    List<Map<String, String>> allRowsData = [];
    for (int i = 0; i < rowKeys.length; i++) {
      final state = rowKeys[i].currentState;
      if (state == null) continue;

      Map<String, String> rowData = state.getRowData();

      if (rowData['pointsOrIssues']!.isEmpty) return _errorListToast("Points/Issues", i);
      if (rowData['discussedWith']!.isEmpty) return _errorListToast("Discussed With", i);
      if (rowData['decisionTaken']!.isEmpty) return _errorListToast("Decision Taken", i);
      if (rowData['responsibility']!.isEmpty) return _errorListToast("Responsibility", i);
      if (rowData['statusOrRemark']!.isEmpty) return _errorListToast("Status/Remark", i);
      if (rowData['targetDate']!.isEmpty) return _errorListToast("Target Date", i);

      allRowsData.add(rowData);
    }

    if (allRowsData.isEmpty) {
      _showToast("Please add at least one row");
      return null;
    }
    return allRowsData;
  }

  Null _errorListToast(String field, int index) {
    _showToast("Please Enter $field for row ${index + 1}");
    return null;
  }

  void addRow() {
    final key = GlobalKey<_DynamicRowState>();

    setState(() {
      rowKeys.add(key);
      dynamicRows.add(
        DynamicRow(
          key: key,
          index: dynamicRows.length,
          onDelete: deleteRow,
        ),
      );
    });
  }
  void deleteRow(int deleteIndex) {
    if (deleteIndex < 0 || deleteIndex >= dynamicRows.length) return;

    setState(() {
      dynamicRows.removeAt(deleteIndex);
      rowKeys.removeAt(deleteIndex);

      // Re-index remaining rows
      for (int i = 0; i < dynamicRows.length; i++) {
        dynamicRows[i] = DynamicRow(
          key: rowKeys[i],
          index: i,
          onDelete: deleteRow,
        );
      }
    });
    _checkForFormEdits();
  }

  void addRowFromData(Message row) {
    final key = GlobalKey<_DynamicRowState>();

    setState(() {
      rowKeys.add(key);
      dynamicRows.add(
        DynamicRow(
          key: key,
          index: dynamicRows.length,
          onDelete: deleteRow,
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      key.currentState?.setData(row);

      // Existing row already saved in database
      if (row.srNo != null) {
        key.currentState?.enableNextDate();
      }
    });
  }

  void _checkForFormEdits() {
    bool hasEdits = _memberPresentController.text.isNotEmpty ||
        _memberAbsentController.text.isNotEmpty;

    if (!hasEdits) {
      for (var key in rowKeys) {
        final rowData = key.currentState?.getRowData() ?? {};
        if (rowData.values.any((v) => v.isNotEmpty && v != "Not provided")) {
          hasEdits = true;
          break;
        }
      }
    }

    if (hasEdits != _isFormEdited) {
      setState(() => _isFormEdited = hasEdits);
    }
  }

  void _clearForm() {
    setState(() {
      _memberAbsentController.clear();
      _memberPresentController.clear();
      selectedCustomer = null;
      dynamicRows.clear();
      rowKeys.clear();
      _isFormEdited = false;
      _initializeData(); // Restore mandatory header fields
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _navigateBack,
        ),
        title: const Text("Minutes Of The Meeting Form"),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
          color: Colors.white,
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _navigateBack();
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => MainBloc(webService: WebService()),
            child: const VisitHistoryScreen(),
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: const CircularProgressIndicator(
        backgroundColor: Color(0xFFCE4A6F),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
      child: BlocListener<MainBloc, MainState>(
        listener: _blocListener,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _buildFieldLabel("Visit Date", isRequired: true),
              _buildMainTextField(_gatepassdatecontroller, readOnly: true, suffixIcon: Icons.calendar_month),
              _buildFieldLabel("To Time", isRequired: true),
              _buildMainTextField(fromTimeInput, readOnly: true, suffixIcon: Icons.watch_later_outlined),
              _buildFieldLabel("Visit Name", isRequired: true),
              _buildMainTextField(_subjectController, readOnly: true),
              _buildFieldLabel("Client Name", isRequired: true),
              _buildClientSelector(),
              _buildFieldLabel("Member Present", isRequired: true),
              _buildMainTextField(_memberPresentController, onChanged: (v) => _checkForFormEdits()),
              _buildFieldLabel("Member Absent", isRequired: true),
              _buildMainTextField(_memberAbsentController, onChanged: (v) => _checkForFormEdits()),
              const SizedBox(height: 10),
              _buildTableSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 10),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 18)),
            if (isRequired)
              const Text(" *", style: TextStyle(fontSize: 18, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTextField(TextEditingController controller, {bool readOnly = false, IconData? suffixIcon, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: _inputDecoration(
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: MyColors.dateIconColorCode) : null,
        hintText: suffixIcon == Icons.calendar_month ? "DD/MM/YYYY" : null,
      ),
    );
  }

  Widget _buildClientSelector() {
    return GestureDetector(
      onTap: _openCustomerSearchDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: MyColors.textBoxBorderColorCode),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Text(
          selectedCustomer?.custName ?? "Select Client",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: addRow,
            child: const Text("Add Row", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                ...dynamicRows,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const headers = ["POINT/ISSUE", "DISCUSSED WITH", "DECISION TAKEN / ACTION PLAN", "RESPONSIBILITY", "STATUS / REMARK", "TARGET DATE", "NEXT TARGET DATE"];
    const widths = [180.0, 200.0, 300.0, 200.0, 200.0, 150.0, 200.0];

    return Row(
      children: [
        ...List.generate(headers.length, (i) => Container(
          width: widths[i],
          height: 50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8),
          color: MyColors.textFieldBackgroundColorCode,
          child: Text(headers[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        )),
        const SizedBox(width: 50),
      ],
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon, String? hintText, Color? fillColor}) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor ?? Colors.white,
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: MyColors.buttonColorCode)),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: MyColors.textBoxBorderColorCode)),
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    );
  }

  void _blocListener(BuildContext context, MainState state) {
    if (state is InsertMMRowsDataLoadingState ||
        state is InsertMMAllDataLoadingState ||
        state is GetMinutesOfTheMeetingAllDataByVisitSrNoLoadingState ||
        state is UpdateMMALlDataLoadingState) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoading = false);
    }

    if (state is InsertMMRowsDataLoadedState) {
      _isSubmitting = false;
      if (!isUpdateMode) {
        _clearForm();
        _showToast("Record Inserted Successfully!");
        DialogForUpdate().popUp(context, "Submitted Successfully!", "4");
        Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
      }
    }

    if (state is InsertMMAllDataLoadedState) {
      _isSubmitting = false;
      _clearForm();
      _showToast("Main Record Inserted Successfully");
    }

    if (state is GetAllClientLoadedState) {
      setState(() {
        customerList = state.response.data;
        if (selectedCustCodeFromAPI != null) {
          selectedCustomer = customerList.firstWhere(
                (c) => c.custCode.toString() == selectedCustCodeFromAPI,
            orElse: () => CustomerData(custCode: int.tryParse(selectedCustCodeFromAPI!) ?? 0, custName: "Unknown", status: ""),
          );
        }
      });
    }

    if (state is GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState) {
      final data = state.getMinutesOfTheMeetingAllDataByVisitSrNoResponse.data?.first.meetingData;
      if (data != null) {
        setState(() {
          mainSrNo = data.srNo.toString();
          _gatepassdatecontroller.text = data.date ?? "";
          _memberAbsentController.text = data.memberAbsent ?? "";
          _memberPresentController.text = data.memberPresent ?? "";
          _subjectController.text = data.subject ?? "";
          fromTimeInput.text = data.time ?? "";
          selectedCustCodeFromAPI = data.custCode;
        });
      }
    }

    if (state is GetMinutesOfTheMeetingDataByVisitSrNoLoadedState) {
      listofRows = state.getMinutesOfTheMeetingDataByVisitSrNoResponse.message ?? [];
      if (listofRows.isNotEmpty) {
        setState(() => isUpdateMode = true);
        srNoTable.clear();
        dynamicRows.clear();
        rowKeys.clear();
        for (var row in listofRows) {
          srNoTable.add(row.srNo.toString());
          addRowFromData(row);
        }
      }
    }

    if (state is UpdateMMAllDataLoadedState) {
      _showToast("Records updated successfully");
      Navigator.pop(context);
    }

    // if (state is MainErrorState) {
    //   _showToast("Error: ${state.error}");
    // }
    // if (state is InsertMMRowsDataErrorState ||
    //     state is InsertMMAllDataErrorState ||
    //     state is GetMinutesOfTheMeetingAllDataByVisitSrNoErrorState ||
    //     state is UpdateMMALlDataErrorState){
    //   _showToast("Error: ${state}");
    // }
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomAction(Icons.phonelink_erase_rounded, "Clear", _clearForm),
          _buildBottomAction(Icons.close, "Cancel", _navigateBack),
          _buildSaveUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MyColors.text4ColorCode),
          Text(label, style: TextStyle(color: MyColors.text4ColorCode, decoration: TextDecoration.underline, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSaveUpdateButton() {
    final bool isEnabled = isUpdateMode ? (_isFormEdited && !_isLoading) : !_isSubmitting;
    final String label = isUpdateMode ? "Update" : "Save";
    final Color color = isUpdateMode ? (isEnabled ? Colors.green : Colors.grey) : MyColors.blueColorCode;

    return GestureDetector(
      onTap: isEnabled ? handleSaveOrUpdate : null,
      child: Container(
        width: 140,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MyColors.textBoxBorderColorCode),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }

  void _openCustomerSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<CustomerData> filteredList = List.from(customerList);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Client"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: customerSearchController,
                    decoration: const InputDecoration(hintText: "Search client...", prefixIcon: Icon(Icons.search)),
                    onChanged: (value) {
                      setStateDialog(() {
                        filteredList = customerList.where((e) => e.custName.toLowerCase().contains(value.toLowerCase())).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final customer = filteredList[index];
                        return ListTile(
                          title: Text(customer.custName),
                          onTap: () {
                            setState(() => selectedCustomer = customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addMinutesOfTheMeetingForm(List<Map<String, String>> allRowsData) {
    setState(() => _isSubmitting = true);
    mainBloc.add(InsertMMAllDataEvents(
      insertMMALLDataRequest: InsertMMALLDataRequest(
        date: _gatepassdatecontroller.text,
        time: fromTimeInput.text,
        subject: _subjectController.text,
        memberPresent: _memberPresentController.text,
        memberAbsent: _memberAbsentController.text,
        allRecordsIds: " ",
        custcode: selectedCustomer?.custCode.toString(),
        visitSrNo: widget.visitSrNo,
      ),
      token: authToken!,
    ));

    for (var rowData in allRowsData) {
      mainBloc.add(InsertMMRowsDataEvents(
        insertMMRowDataRequest: InsertMMRowDataRequest(
          pointsOrIssues: rowData['pointsOrIssues'] ?? 'Not provided',
          discussedWith: rowData['discussedWith'] ?? 'Not provided',
          decisionTaken: rowData['decisionTaken'] ?? 'Not provided',
          responsibility: rowData['responsibility'] ?? 'Not provided',
          targetDate: rowData['targetDate'] ?? 'Not provided',
          statusOrRemark: rowData['statusOrRemark'] ?? 'Not provided',
          nextDate: rowData['nextDate']!.isEmpty ? 'Not provided' : rowData['nextDate'],
          visitSrNo: widget.visitSrNo,
        ),
        token: authToken!,
      ));
    }
  }

  void _updateMinutesOfTheMeetingForm(List<Map<String, String>> allRowsData) {
    mainBloc.add(UpdateMMALLDataEvents(
      updateMMAllData: UpdateMMAllData(
        srNo: mainSrNo,
        date: _gatepassdatecontroller.text,
        time: fromTimeInput.text,
        subject: _subjectController.text,
        memberPresent: _memberPresentController.text,
        memberAbsent: _memberAbsentController.text,
        allRecordsIds: srNoTable.join(","),
        custCode: selectedCustomer!.custCode.toString(),
        visitSrNo: widget.visitSrNo,
      ),
      token: authToken!,
    ));

    for (int i = 0; i < allRowsData.length; i++) {
      final rowData = allRowsData[i];
      if (i < srNoTable.length) {
        mainBloc.add(UpdateMMDataEvents(
          updateMMData: UpdateMMData(
            srNo: srNoTable[i],
            pointsOrIssues: rowData['pointsOrIssues'] ?? 'Not provided',
            discussedWith: rowData['discussedWith'] ?? 'Not provided',
            decisionTaken: rowData['decisionTaken'] ?? 'Not provided',
            responsibility: rowData['responsibility'] ?? 'Not provided',
            targetDate: rowData['targetDate'] ?? 'Not provided',
            statusOrRemark: rowData['statusOrRemark'] ?? 'Not provided',
            nextDate: rowData['nextDate']!.isEmpty ? 'Not provided' : rowData['nextDate'],
            visitSrNo: widget.visitSrNo,
          ),
          token: authToken!,
        ));
      } else {
        mainBloc.add(InsertMMRowsDataEvents(
          insertMMRowDataRequest: InsertMMRowDataRequest(
            pointsOrIssues: rowData['pointsOrIssues'] ?? 'Not provided',
            discussedWith: rowData['discussedWith'] ?? 'Not provided',
            decisionTaken: rowData['decisionTaken'] ?? 'Not provided',
            responsibility: rowData['responsibility'] ?? 'Not provided',
            targetDate: rowData['targetDate'] ?? 'Not provided',
            statusOrRemark: rowData['statusOrRemark'] ?? 'Not provided',
            nextDate: rowData['nextDate']!.isEmpty ? 'Not provided' : rowData['nextDate'],
            visitSrNo: widget.visitSrNo,
          ),
          token: authToken!,
        ));
      }
    }
  }
}

class DynamicRow extends StatefulWidget {
  final Function(int) onDelete;
  final int index;

  const DynamicRow({Key? key, required this.index, required this.onDelete}) : super(key: key);

  @override
  _DynamicRowState createState() => _DynamicRowState();
}

class _DynamicRowState extends State<DynamicRow> {
  final dateController1 = TextEditingController();
  final dateController2 = TextEditingController();
  final textFieldController1 = TextEditingController();
  final textFieldController2 = TextEditingController();
  final textFieldController3 = TextEditingController();
  final textFieldController4 = TextEditingController();
  final textFieldController5 = TextEditingController();

  bool isNextDateEnabled = false;

  @override
  void dispose() {
    dateController1.dispose();
    dateController2.dispose();
    textFieldController1.dispose();
    textFieldController2.dispose();
    textFieldController3.dispose();
    textFieldController4.dispose();
    textFieldController5.dispose();
    super.dispose();
  }

  void enableNextDate() => setState(() => isNextDateEnabled = true);

  void setData(Message row) {
    textFieldController1.text = row.pointsOrIssues ?? "";
    textFieldController2.text = row.disccussedwith ?? "";
    textFieldController3.text = row.decisionTaken ?? "";
    textFieldController4.text = row.responsibility ?? "";
    textFieldController5.text = row.statusOrRemark ?? "";
    dateController1.text = row.targateDate ?? "";
    dateController2.text = row.nextDate ?? "";
  }

  Map<String, String> getRowData() {
    return {
      'pointsOrIssues': textFieldController1.text,
      'discussedWith': textFieldController2.text,
      'decisionTaken': textFieldController3.text,
      'responsibility': textFieldController4.text,
      'statusOrRemark': textFieldController5.text,
      'targetDate': dateController1.text,
      'nextDate': dateController2.text,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          _buildCell(180, textFieldController1),
          _buildCell(200, textFieldController2),
          _buildCell(300, textFieldController3),
          _buildCell(200, textFieldController4),
          _buildCell(200, textFieldController5),
          _buildDateCell(150, dateController1, false),
          _buildDateCell(200, dateController2, true),
          _buildDeleteButton(),
        ],
      ),
    );
  }

  Widget _buildCell(double width, TextEditingController controller) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: (_) => context.findAncestorStateOfType<_MinutesOfTheMeetingFormScreenState>()?._checkForFormEdits(),
        decoration: _cellDecoration(),
      ),
    );
  }

  Widget _buildDateCell(double width, TextEditingController controller, bool isNextDate) {
    final bool isDisabled = isNextDate && !isNextDateEnabled;
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () {
          if (isDisabled) {
            Fluttertoast.showToast(msg: "Please select Target Date first and Save/Update");
            return;
          }
          _selectDate(context, controller, isNextDate);
        },
        decoration: _cellDecoration(
          hintText: "DD/MM/YYYY",
          suffixIcon: Icon(Icons.calendar_month, size: 20, color: isDisabled ? Colors.grey : MyColors.dateIconColorCode),
          fillColor: isDisabled ? Colors.grey.shade400 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final parentState = context.findAncestorStateOfType<_MinutesOfTheMeetingFormScreenState>();
    bool isExistingRow = parentState != null && widget.index < parentState.srNoTable.length;
    if (isExistingRow) return const SizedBox(width: 50);

    return SizedBox(
      width: 50,
      child: IconButton(
        icon: const Icon(Icons.delete_rounded, color: MyColors.redColorCode),
        onPressed: () => widget.onDelete(widget.index),
      ),
    );
  }

  InputDecoration _cellDecoration({String? hintText, Widget? suffixIcon, Color? fillColor}) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: MyColors.textBoxBorderColorCode)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: MyColors.buttonColorCode)),
      hintText: hintText,
      suffixIcon: suffixIcon,
    );
  }

  void _selectDate(BuildContext context, TextEditingController controller, bool isNextDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 15)),
    );

    if (pickedDate != null) {
      if (isNextDate && dateController1.text.isNotEmpty) {
        final targetDate = DateFormat('dd/MM/yyyy').parse(dateController1.text);
        if (!pickedDate.isAfter(targetDate)) {
          Fluttertoast.showToast(msg: "Next Target Date must be greater than Target Date");
          return;
        }
      }
      setState(() => controller.text = DateFormat('dd/MM/yyyy').format(pickedDate));
      context.findAncestorStateOfType<_MinutesOfTheMeetingFormScreenState>()?._checkForFormEdits();
    }
  }
}

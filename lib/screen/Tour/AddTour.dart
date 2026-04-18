import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_state.dart';
import '../../model/Tour/Submittourdetails.dart';
import '../../service/WebService.dart';
import '../../util/MyColor.dart';
import 'TourmainScreen.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() =>
      _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  late MainBloc mainbloc;
  bool _isLoading = false;
  String? staffcode = "";
  String? auth_token = "";
  String? selectedOption = "Please Select"; // Dropdown initial value
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    mainbloc = BlocProvider.of(context);
    getdata();
  }

  void getdata() async {
    staffcode = await storage.read(key: 'Staff_Code');
    print("staffCode--> $staffcode");
    auth_token = await storage.read(key: 'Auth_Token');
    print("Auth_Token--> $auth_token");
    // mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode, token: Auth_Token));
    mainbloc.add(Fetchstafftourdetails(Staffcode: staffcode!, token: auth_token!));

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _FromDateController.text = today;
    _ToDateController.text = today;
  }

  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _DepartmetController = TextEditingController();
  final TextEditingController _DesignationController = TextEditingController();
  final TextEditingController _FromDateController = TextEditingController();
  final TextEditingController _ToDateController = TextEditingController();
  final TextEditingController _AddressController = TextEditingController();
  final TextEditingController _PurposeController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainBloc, MainState>(
      listener: (context, state) {
        if(state is GetTourstaffdetailLoadingState){
          setState(() {
            _isLoading=true;
          });
        }
        else if(state is GetTourstaffdetailsLoadedState){
          setState(() {
            _isLoading=false;
          });
          Fluttertoast.showToast(msg: 'success');
          _staffCodeController.text = state.staffdetails.message!.message!.staffCode.toString();
          _staffNameController.text = state.staffdetails.message!.message!.fullName.toString();
          _DepartmetController.text = state.staffdetails.message!.message!.department.toString();
          _DesignationController.text = state.staffdetails.message!.message!.designation.toString();

        }
        else if(state is GetTourstaffdetailsErrorState){
          setState(() {
            _isLoading=false;
          });
          Fluttertoast.showToast(msg: 'Error is data');
        }
        else if (state is SubmittourdetailsLoadingState) {
          setState(() {
            _isLoading = true;
          });
        }
        else if(state is SubmitTourdetailsLoadedState){
          setState(() {
            _isLoading = false;
          });
          print("submitted succesfully");
          //Fluttertoast.showToast(msg: 'submitted succesfully');

          _cleardata();
        }

        else if(state is SubmitTourdetailsErrorState){
          setState(() {
            _isLoading = false;
          });
          if(state.msg=={"{message":"Tour is not allowed on leave in the given date range}"})
          print("no tour submitted"+state.msg);
          LogFileManager.writeLog("no tour submitted"+state.msg);
          Fluttertoast.showToast(msg: 'Tour is not allowed on applied leave dates');
        }

      },
      child: Scaffold(
        appBar:
        AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () =>
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BlocProvider(
                                create: (context) {
                                  return MainBloc(
                                      webService: WebService());
                                },
                                child: TourPendingScreen())))
            ),

            title: const Text("Apply for Tour")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildTextField('Staff Code', _staffCodeController, readOnly: true,isRequired: true),
                _buildTextField('Staff Name', _staffNameController, readOnly: true,isRequired: true),
                _buildTextField('Designation', _DesignationController, readOnly: true,isRequired: true),
                _buildTextField('Department', _DepartmetController, readOnly: true,isRequired: true),
                _buildTextField(
                    'From Date',
                    _FromDateController,
                    readOnly: true,
                    showIcon: true,
                    onTap: () => _selectDate(context, _FromDateController),
                    isRequired: true
                ),
                _buildTextField(
                  'To Date',
                  _ToDateController,
                  readOnly: true,
                  showIcon: true,
                  isRequired: true,
                  onTap: () => _selectDate(context, _ToDateController),
                ),
                const SizedBox(height: 10),
                const Text("Select Visit Type"),
                DropdownButtonFormField<String>(
                  value: selectedOption,
                  onChanged: (value) {
                    setState(() {
                      selectedOption = value;
                    });
                  },
                  items: ['Please Select','Customer Visit', 'For Purchase', 'Outside Visit', 'Suplier Visit','Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField('Address on Tour', _AddressController, readOnly: false,isRequired: true),
                _buildTextField('Purpose of Tour', _PurposeController, readOnly: false,isRequired: true),
                ElevatedButton(
                  onPressed: _submitTour,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

/*  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, bool showIcon = false, Color? textColor, VoidCallback? onTap,bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),

        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),

            suffixIcon: showIcon ? const Icon(Icons.calendar_today) : null,
          ),
          style: TextStyle(color: textColor),

        ),

        const SizedBox(height: 10),

      ],
    );
  }*/

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        bool showIcon = false,
        Color? textColor,
        bool isRequired = false,
        VoidCallback? onTap
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            if (isRequired) // ✅ Conditionally add * mark
              Text(
                " *",
                style: TextStyle(fontSize: 18, color: MyColors.redColorCode),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTap: onTap,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: showIcon ? const Icon(Icons.calendar_today) : null,
          ),
          style: TextStyle(color: textColor),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }


  void _submitTour() {
    if (_staffCodeController.text.isEmpty ||
        _staffNameController.text.isEmpty ||
        _DepartmetController.text.isEmpty ||
        _DesignationController.text.isEmpty ||
        _FromDateController.text.isEmpty ||
        _ToDateController.text.isEmpty ||
        _AddressController.text.isEmpty ||
        _PurposeController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill in all required fields.');
      return;
    }

    final tourDetails = SubmitTourDetails(
      slipId: "", // Replace with actual slip ID if applicable
      staffCode: _staffCodeController.text,
      name: _staffNameController.text,
      department: _DepartmetController.text,
      designation: _DesignationController.text,
      fromDate: _FromDateController.text,
      toDate: _ToDateController.text,
      addressOnTour: _AddressController.text,
      reason: selectedOption,
      purpose: _PurposeController.text,
      add: true, // Adjust as per requirements
    );

    if (auth_token != null && auth_token!.isNotEmpty) {
      mainbloc.add(Submittourdetailsevent(submittour: tourDetails, token: auth_token!));
    } else {
      Fluttertoast.showToast(msg: 'Authorization token is missing.');
    }
  }

  void _cleardata() {

    _PurposeController.text="";
    _AddressController.text="";
    reasonController.text = "";  // Clear reasonController
    setState(() {
      selectedOption = "Please Select";  // Reset dropdown value
    });

  }

}





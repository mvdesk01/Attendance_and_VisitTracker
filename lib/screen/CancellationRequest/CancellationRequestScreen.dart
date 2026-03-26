import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/CancellationRequestData/CancellationRequestResponse.dart';
import '../../model/CancellationRequestData/GatepassCancellationRequest.dart';
import '../../model/CancellationRequestData/LeaveCancellationRequest.dart';
import '../../model/CancellationRequestData/TourCancellationRequest.dart';

class CancellationRequestScreen extends StatefulWidget {
  const CancellationRequestScreen({super.key});

  @override
  State<CancellationRequestScreen> createState() =>
      _CancellationRequestScreenState();
}

class _CancellationRequestScreenState
    extends State<CancellationRequestScreen> {
  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  String? staffcode = "cd02851";
  String? authToken = "";
  late MainBloc mainBloc;
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _selectedOption;

  final List<String> _options = [
    'Select',
    'Leave',
    'Gatepass',
    'COFF',
    'CDebit',
    'OT',
    'Tour',
  ];

  List<dynamic> _data = []; // Data fetched from the API
  List<CancellationstaffDetails> _selectedData = [];

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    initializeData();
  }

  Future<void> initializeData() async {
    authToken = await storage.read(key: 'Auth_Token');
    _staffCodeController.text = staffcode ?? "";
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fromDateController.text = today;
    _toDateController.text = today;

    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submitSelectedData() {
    // Perform API call to submit the selected data
    if (_selectedData.isNotEmpty) {
      switch (_selectedOption) {
        case 'Leave':
          mainBloc.add(SubmitLeaveCancellationRequest(leavecancellationsubmit: [], token: authToken!));
          break;
        case 'Gatepass':
          mainBloc.add(SubmitGatepassCancellationrequest(gatepasscancellationsubmit: [], token: authToken!));
          break;
        case 'Coff':
          mainBloc.add(SubmitCoffCancellationrequest(coffcancellationsubmit: [], token: authToken!));
          break;
        case 'CDebit':
          mainBloc.add(SubmitCdebitCancellationrequest(cdebitcancellationsubmit: [], token: authToken!));
          break;
        case 'OT':
          mainBloc.add(SubmitOTcancelRequest(otcancellationsubmit: [], token: authToken!));
          break;
        case 'Tour':
          mainBloc.add(SubmitTourCancellationrequest(tourcancellationsubmit: [], token: authToken!));
          break;
      }
    }else {
      Fluttertoast.showToast(msg: "No rows selected");
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancellation Request')),
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          switch (_selectedOption) {
            case 'Leave':
              if(state is FetchLeaveCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });
              }
              else if(state is FetchLeaveCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                  _data = state.cancelleaverequest ?? [];
                });
                if (_data.isEmpty) {
                  Fluttertoast.showToast(msg: "No data found");
                }
              }
              else if(state is FetchLeaveCancellationErrorState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(msg: "Error fetching data");
              }

              if(state is SubmitLeaveCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });

              }
              else if(state is SubmitLeaveCancellationLoadedState){
                setState(() {
                  _isLoading = false;
                });

                Fluttertoast.showToast(
                  msg: "DOT cancellation request submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );

              }
              else if(state is SubmitLeaveCancellationErrorState){
                setState(() {
                  _isLoading = false;
                });

              }

              break;
            case 'Gatepass':
              if(state is FetchGatepassCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });
              }
              else if(state is FetchGatepassCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                  _data = state.cancelgatepassrequest ?? [];
                });
                if (_data.isEmpty) {
                  Fluttertoast.showToast(msg: "No data found");
                }
              }
              else if(state is FetchGatePassCancellationErrorstate){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(msg: "Error is loading data");

              }

              if(state is SubmitgatepassCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });

              }
              else if(state is SubmitgatepassCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(
                  msg: "DOT cancellation request submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
              else if(state is SubmitGatepassCancellationErrorState){
                setState(() {
                  _isLoading=false;
                });

                Fluttertoast .showToast(msg: "error");
              }
              break;
            case 'COFF':
              if(state is FetchCoffCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });

              }
              else if(state is FetchCoffCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                  _data = state.cancelcoffrequest ?? [];
                });
                if (_data.isEmpty) {
                  Fluttertoast.showToast(msg: "No data found");
                }
              }
              else if(state is FetchCoffCancellationErrorState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(msg: "Error fetching data");
              }

              if(state is SubmitCoffCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });

              }
              else if(state is SubmitCoffCancellationLoadedState){
                setState(() {
                  _isLoading = false;
                });

                Fluttertoast.showToast(
                  msg: "DOT cancellation request submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
              else if(state is SubmitCoffCancellationerrorState){
                setState(() {
                  _isLoading=false;
                });

              }
              break;

            case 'CDebit':
              if(state is FetchCDebitCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });
              }
              else if(state is FetchCDebitCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                  _data = state.cancelcdebitrequest ?? [];
                });
                if (_data.isEmpty) {
                  Fluttertoast.showToast(msg: "No data found");
                }
              }
              else if(state is FetchCDebitCancellationErrorState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(msg: "No data found");
              }

              if(state is SubmitCdebitCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });

              }
              else if(state is SubmitCdebitCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                });

                Fluttertoast.showToast(
                  msg: "DOT cancellation request submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
              else if(state is SubmitCdebitCancellationErrorState){
                setState(() {
                  _isLoading=false;
                });

              }

              break;
            case 'OT':
              if (state is FetchCancellationDetailsLoadingState) {
                setState(() {
                  _isLoading = true;
                });
              }
              else if (state is FetchCancellationDetailsLoadedState) {
                setState(() {
                  _isLoading = false;
                  _data = state.cancellationRequest ?? [];
                });
                if (_data.isEmpty) {
                  Fluttertoast.showToast(msg: "No data found");
                }
              }
              else if (state is FetCancellationDetailsErrorState) {
                setState(() {
                  _isLoading = false;
                });
                Fluttertoast.showToast(msg: "Error fetching data");
              }

              if(state is submitOTLoadingState){
                setState(() {
                  _isLoading= true;
                });

              }
              else if(state is submitOTLoadedState){
                setState(() {
                  _isLoading= false;
                });
                Fluttertoast.showToast(
                  msg: "DOT cancellation request submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
              else  if(state is submitOTErrorState){
                setState(() {
                  _isLoading = false;
                });

                Fluttertoast.showToast(
                  msg: "not submitted, error",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }

              break;
            case 'Tour':
              if(state is FetchTourLoadingState){
                setState(() {
                  _isLoading=true;
                });
              }
              else if(state is FetchTourLoadedState){
                setState(() {
                  _isLoading=false;
                  _data = state.canceltourrequest ?? [];
                });
                if (_data.isEmpty) {
                  Fluttertoast.showToast(msg: "No data found");
                }
              }
              else if(state is FetchTourErrorState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(msg: "errro in data");
              }

              if(state is SubmitTourCancellationLoadingState){
                setState(() {
                  _isLoading=true;
                });

              }
              else if(state is SubmitTourCancellationLoadedState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(
                  msg: "DOT cancellation request submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
              else if(state is SubmitTourCancellationErrorState){
                setState(() {
                  _isLoading=false;
                });
                Fluttertoast.showToast(msg: "error");
              }
              break;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text("Staff Code"),
              const SizedBox(height: 8),
              TextField(
                controller: _staffCodeController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text("From Date - To Date"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _fromDateController),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _toDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _toDateController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Select Option"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                hint: const Text("Select an option"),
                value: _selectedOption,
                items: _options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOption = newValue;
                  });
                  if (newValue != null && newValue != 'Select') {
                    mainBloc.add(FetchCancellationDetails(
                      staffCode: _staffCodeController.text,
                      fromDate: _fromDateController.text,
                      toDate: _toDateController.text,
                      requestType: _selectedOption!,
                      token: authToken!,
                    ));
                  }
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _data.isEmpty
                    ? const Center(child: Text("No data found"))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _getColumns(),
                    rows: _getRows(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitSelectedData,
                child: const Text("Submit Selected Data"),
              ),
            ],
          ),
        ),
      ),
    );
  }
  List<DataColumn> _getColumns() {
    List<String> columns = [];
    switch (_selectedOption) {
      case 'Leave':
        columns = [
          'Status',
          'Staff Code',
          'Name',
          'Start Date',
          'End Date',
          'Leave Type',
          'Days',
          'Reason',
        ];
        break;
      case 'Gatepass':
        columns = [
          'Status',
          'Staff Code',
          'Name',
          'Date',
          'From Time',
          'To Time',
          'Type',
          'Reason',
        ];
        break;
      case 'COFF':
        columns = [
          'Status',
          'Staff Code',
          'Name',
          'Date',
          'Hours',
          'Type',
          'Reason',
        ];
        break;
      case 'CDebit':
        columns = [
          'Status',
          'Staff Code',
          'Name',
          'Date',
          'From Time',
          'To Time',
          'Reason',
        ];
        break;
      case 'OT':
        columns = [
          'Select',
          'Staff Code',
          'Name',
          'Date',
          'Hours',
          'Reason',
        ];
        break;
      case 'Tour':
        columns = [
          'Status',
          'Staff Code',
          'Name',
          'Start Date',
          'End Date',
          'Tour Address',
          'Reason',
        ];
        break;
      default:
        break;
    }
    return columns.map((col) => DataColumn(label: Text(col))).toList();
  }

  List<DataRow> _getRows() {
    return _data.map((item) {
      switch (_selectedOption) {
        case 'Leave':
          final leaveDetail = item as LeaveCancelRequest; // Replace with the actual model class for Leave.
          return DataRow(
            cells: [
              DataCell(Text(leaveDetail.status ?? '')),
              DataCell(Text(leaveDetail.staffcode)),
              DataCell(Text(leaveDetail.name)),
              DataCell(Text(leaveDetail.startDate ?? '')),
              DataCell(Text(leaveDetail.endDate ?? '')),
              DataCell(Text(leaveDetail.leaveType ?? '')),
              DataCell(Text(leaveDetail.days.toString())),
              DataCell(
                TextField(
                  onChanged: (value) {
                    leaveDetail.reason = value;
                  },
                  decoration: const InputDecoration(hintText: 'Enter reason'),
                ),
              ),
            ],
          );
        case 'Gatepass':
          final gatepassDetail = item as GatepassCancelRequest; // Replace with the actual model class for Gatepass.
          return DataRow(
            cells: [
              DataCell(Text(gatepassDetail.status ?? '')),
              DataCell(Text(gatepassDetail.staffcode)),
              DataCell(Text(gatepassDetail.name)),
              DataCell(Text(gatepassDetail.date ?? '')),
              DataCell(Text(gatepassDetail.fromtime ?? '')),
              DataCell(Text(gatepassDetail.totime ?? '')),
              DataCell(Text(gatepassDetail.type ?? '')),
              DataCell(
                TextField(
                  onChanged: (value) {
                    gatepassDetail.reason = value;
                  },
                  decoration: const InputDecoration(hintText: 'Enter reason'),
                ),
              ),
            ],
          );
        case 'Tour':
          final tourDetail = item as TourCanceelationRequest; // Replace with the actual model class for Tour.
          return DataRow(
            cells: [
              DataCell(Text(tourDetail.status ?? '')),
              DataCell(Text(tourDetail.staffcode)),
              DataCell(Text(tourDetail.name)),
              DataCell(Text(tourDetail.startdate ?? '')),
              DataCell(Text(tourDetail.enddate ?? '')),
              DataCell(Text(tourDetail.touraddress?? '')),
              DataCell(
                TextField(
                  onChanged: (value) {
                    tourDetail.reason = value;
                  },
                  decoration: const InputDecoration(hintText: 'Enter reason'),
                ),
              ),
            ],
          );
        default:
          return DataRow(cells: []);
      }
    }).toList();
  }

}

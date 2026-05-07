import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../bloc/main_state.dart';

class DataDeletionRequestScreen extends StatefulWidget {
  const DataDeletionRequestScreen({super.key});

  @override
  State<DataDeletionRequestScreen> createState() =>
      _DataDeletionRequestScreenState();
}

class _DataDeletionRequestScreenState extends State<DataDeletionRequestScreen> {

  late MainBloc _mainBloc;
  FlutterSecureStorage storage = FlutterSecureStorage();
  bool _isSubmitting = false;
  late String Staffcode;
  late String Token;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    Staffcode = (await storage.read(key: 'Staff_Code'))!;
    print("staffCode-->$Staffcode");
    Token = (await storage.read(key: 'Auth_Token'))!;
    print("Auth_Token-->$Token");
  }

    @override
    Widget build(BuildContext context) {
      _mainBloc = BlocProvider.of(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Request Data Deletion",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<MainBloc, MainState> (listener: (context, state) async {
            if(state is RequestDataDeletionLoadingState){
              setState(() => _isSubmitting = true);
            }
            if(state is RequestDataDeletionLoadedState){
              if(state.result){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Your data deletion request has been submitted successfully.",
                    ),
                  ),
                );
                setState(() => _isSubmitting = false);

                Navigator.pop(context); // Go back to Settings
              }
            }
            if(state is RequestDataDeletionErrorState){
              setState(() => _isSubmitting = false);

              Fluttertoast.showToast(
                msg: "   Failed To Connect Server!   ",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
            }
          },
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "What happens when you request deletion?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "• Your account will be permanently deleted.\n"
                            "• All attendance, visit, and location data will be removed.\n"
                            "• This action cannot be undone.\n"
                            "• Data deletion may take up to 7 working days.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ⚠️ Warning Section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade600),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "This request will permanently delete your account "
                            "and all associated data. You will not be able to recover it.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// 🗑 Delete Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _showConfirmationDialog(context),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Request Data Deletion",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),


          ),
        ),
      );
    }

    /// 🔐 Confirmation Dialog
    void _showConfirmationDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            AlertDialog(
              title: const Text("Confirm Data Deletion"),
              content: const Text(
                "Are you sure you want to request deletion of your account and data?\n\n"
                    "This action is irreversible.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _submitDeletionRequest();
                  },
                  child: const Text("Confirm"),
                ),
              ],
            ),
      );
    }


  /// 📡 Submit Request (API / Logic)
  Future<void> _submitDeletionRequest() async {
    setState(() => _isSubmitting = true);

    // // TODO: Call your deletion request API here
    // await Future.delayed(const Duration(seconds: 2));

    _mainBloc.add(RequestDataDeletionEvents(StaffCode: Staffcode, token: Token));

    // setState(() => _isSubmitting = false);
  }

  }
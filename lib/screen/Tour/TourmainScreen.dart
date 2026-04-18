import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_state.dart';
import '../../model/Tour/AppliedTour.dart';
import '../../service/WebService.dart';

import '../../util/MyColor.dart';
import '../Home/home.dart';
import 'AddTour.dart';

class TourPendingScreen extends StatefulWidget {
  const TourPendingScreen({super.key});

  @override
  State<TourPendingScreen> createState() =>
      _TourPendingScreenState ();
}

class _TourPendingScreenState extends   State<TourPendingScreen>  {
  late bool _isLoading = false;
  bool showtable = false;
  bool isUpdate = true;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staffCode="";
  String? Auth_Token="";
  String? slipid="";
  late List<TourDetail> pendingTourlist=[];
  ScrollController vendorRecordController = new ScrollController();

  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {

    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');
    mainBloc.add(FetchappliedTourevent(Staffcode: staffCode!, token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Applied Tour"),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ).copyWith(
          color: Colors.white,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(webService: WebService());
                        },
                        child: HomeScreen())));
            return false;
          }
          return true;
        },
        child: _appliedscreen(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.lightBlue,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: TourScreen(),
              ),
            ),
          );

        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  _appliedscreen() {
    return LoadingOverlay(
        isLoading: _isLoading,
        opacity: 0.5,
        color: Colors.white,
        progressIndicator: CircularProgressIndicator(
          backgroundColor: Color(0xFFCE4A6F),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
        child: BlocListener<MainBloc,MainState>(
          listener:  (context, state){
            if (state is FetchappliedTourLoadingState) {
              setState(() {
                _isLoading = true;
              });
            }
            else if (state is FetchappliedTourLoadedState) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(
                msg: "   Success!   ",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
              pendingTourlist.clear(); // ✅ Clear previous data
              pendingTourlist.addAll(state.appliedtourdetails.message ?? []);
              //pendingLeaveList.addAll(state.appliedtourdetails.message ?? []);
            }
            else if (state is FetchappliedTourErrorstate) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(
                msg: "Currently no data available. Please apply for Tour first.",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
            }

            if(state is CancelappliedtourLoadingState){
              setState(() {
                _isLoading=true;
              });
            }
            else if(state is CancelappliedtourLoadedState){
              setState(() {
                _isLoading=false;
              });
              Fluttertoast.showToast(msg: 'Record deleted Successfully');
            }

            else if(state is CancelappliedtourErrorState){
              setState(() {
                _isLoading=false;
              });
              Fluttertoast.showToast(msg: 'error is deleting');
            }
          },
          child: pendingTourlist.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icons/no_data.png", // Ensure this image exists in your assets folder
                  height: 150,
                ),
                SizedBox(height: 20),
                Text(
                  "No Data Available",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: vendorRecordController,
            shrinkWrap: true,
            itemCount: pendingTourlist.length,
            itemBuilder: (context, index) {
              TourDetail tourdetails = pendingTourlist[index];
              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: MyColors.textBoxBorderColorCode),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Status: Pending", style: TextStyle(color: MyColors.greenColorCode,fontWeight: FontWeight.bold,fontSize: 20)),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _showDeleteDialog(context, tourdetails);
                                },
                                child: Container(
                                  height: 32,
                                  margin: EdgeInsets.only(left: 20),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: MyColors.pinkBackgroundColorCode,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.redColorCode, fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildRow("Staff Code",tourdetails.staffCode),
                      _buildRow("Start Date",tourdetails.startDate),
                      _buildRow("End Date",tourdetails.endDate),
                      _buildRow("Purpose",tourdetails.purpose),
                      // _buildRow("From Date", _formatDate(tourdetails.startingDate)),
                      // _buildRow("To Date", _formatDate(tourdetails.endingDate)),
                      // _buildRow("Reason", tourdetails.reason ?? "N/A"),
                    ],
                  ),
                ),
              );
            },
          ),
        )
    );
  }
  void _showDeleteDialog(BuildContext context, TourDetail tourdetails) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Tour"),
          content: Text("Are you sure you want to delete this Tour record?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("No",style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteappliedtour(context, tourdetails);
              },
              child: Text("Yes",style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteappliedtour(BuildContext context, TourDetail tourdetails) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      print(tourdetails.slipId);
      print(staffCode);
      print(tourdetails.slipId.toString());
      // Dispatch the cancel leave event
      mainBloc.add(CancelTourevents(staffCode: staffCode!, slipId: tourdetails.slipId.toString(), token: Auth_Token!));
      await Future.delayed(Duration(seconds: 1));
      print(staffCode);
      print(tourdetails.slipId.toString());// Optional: Ensure state updates correctly
      setState(() {
        pendingTourlist.clear(); // ✅ Clear previous data
      });
      getData();

      Fluttertoast.showToast(msg: "Tour record deleted successfully!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to delete leave: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: MyColors.black, fontSize: 18)),
          Text(value, style: TextStyle(color: MyColors.black, fontSize: 18)),
        ],
      ),
    );
  }
}









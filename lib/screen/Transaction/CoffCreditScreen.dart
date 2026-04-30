import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Transaction/AddCoffScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../model/CoffCredit/FetchCoffTransactionsResponse.dart';
import '../../util/MyColor.dart';
import '../../util/custome_dialog.dart';

class Coffcreditscreen extends StatefulWidget {
  const Coffcreditscreen({super.key});

  @override
  State<Coffcreditscreen> createState() => _CoffcreditscreenState();
}

class _CoffcreditscreenState extends State<Coffcreditscreen> {
  late bool _isLoading = false;
  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();
  String? staffCode = "";
  String? Auth_Token = "";
  late List<Message> CoffList = [];
  ScrollController gatepassRecordController = ScrollController();
  int deleteposition = 0;

  @override
  void initState() {
    super.initState();
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');
    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');
    print("Auth_Token-->" + Auth_Token!);
    mainBloc.add(
        FetchCoffTransactionsEvents(satffCode: staffCode!, token: Auth_Token!));
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
      CoffList.clear(); // Clear existing data
    });

    // Fetch fresh data
    staffCode = await storage.read(key: 'Staff_Code');
    Auth_Token = await storage.read(key: 'Auth_Token');

    mainBloc.add(
        FetchCoffTransactionsEvents(satffCode: staffCode!, token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: HomeScreen(),
              ),
            ),
            (route) => false,
          ),
        ),
        title: const Text("C-Off Credit"),
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
            print("Else Navigatorrrrrrrrrrrrr");
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
          // 🔥 VERY IMPORTANT
        },
        child: _addGatePassScreen(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.lightBlue,
        onPressed: () async {
          // ✅ Wait for the result from AddCoffScreen
          bool? result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) {
                  return MainBloc(webService: WebService());
                },
                child: AddCoffScreen(
                    flag: 1, datum: CoffList.isEmpty ? Message() : CoffList[0]),
              ),
            ),
          );

          // ✅ If data was saved, refresh the list
          if (result == true) {
            refreshData();
          }
        },
        child: Icon(Icons.add, color: MyColors.whiteColorCode),
      ),
    );
  }

  _addGatePassScreen() {
    return LoadingOverlay(
      isLoading: _isLoading,
      opacity: 0.5,
      color: Colors.white,
      progressIndicator: CircularProgressIndicator(
        backgroundColor: Color(0xFFCE4A6F),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
      child: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          //-----------Fetch COff List-------------------
          if (state is FetchCoffTransactionsLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is FetchCoffTransactionsLoadedState) {
            print("FetchCoffTransactionsLoadedState....");
            setState(() {
              _isLoading = false;
              CoffList =
                  List.from(state.fetchCoffTransactionsResponse.message ?? []);
            });
            print("Pending CoffList Size: ${CoffList.length}");
            if (CoffList.isNotEmpty) {
              print("First record otDate: ${CoffList.first.otDate}");
            }
          } else if (state is FetchCoffTransactionsErrorState) {
            print("FetchCoffTransactionsErrorState....");
            setState(() {
              _isLoading = false;
              CoffList = []; // Clear list on error
            });
            //Fluttertoast.showToast(msg: "Failed to load data");
          }

          //-----------Cancel COff-------------------
          if (state is CancelCoffOTHWOFFLoadingState) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is CancelCoffOTHWOFFLoadedState) {
            setState(() {
              _isLoading = false;
            });

            Fluttertoast.showToast(
              msg: state.cancelGatepassResponse.message!,
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );

            if (state.cancelGatepassResponse.message ==
                "Record Cancelled Successfully.") {
              // ✅ Clear and refresh the list
              setState(() {
                CoffList.clear();
              });
              CustomDialog()
                  .popUp(context, "Well done! Your DOff is Canceled....!!");
              // ✅ Fetch fresh data
              mainBloc.add(FetchCoffTransactionsEvents(
                  satffCode: staffCode!, token: Auth_Token!));
            }
          } else if (state is CancelCoffOTHWOFFErrorState) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(
              msg: "Failed to cancel COff. Please try again.",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );
          }
        },
        child: CoffList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/icons/no_data.png",
                      // Ensure this image exists in your assets folder
                      height: 150,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No Data Available",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: gatepassRecordController,
                shrinkWrap: true,
                itemCount: CoffList.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          width: 1, color: MyColors.textBoxBorderColorCode),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      padding: EdgeInsets.only(
                          top: 15, left: 14, right: 14, bottom: 15),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text("STATUS: PENDING",
                                    style: TextStyle(
                                        color: MyColors.greenColorCode)),
                              )),
                              GestureDetector(
                                onTap: () async {
                                  // ✅ Wait for the result from edit screen
                                  bool? result =
                                      await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (context) {
                                          return MainBloc(
                                              webService: WebService());
                                        },
                                        child: AddCoffScreen(
                                            flag: 2, datum: CoffList[index]),
                                      ),
                                    ),
                                  );

                                  // ✅ If data was updated, refresh the list
                                  if (result == true) {
                                    refreshData();
                                  }
                                },
                                child: Container(
                                  height: 32,
                                  margin: EdgeInsets.only(top: 7, left: 20),
                                  padding: EdgeInsets.only(
                                      left: 20, right: 20, top: 5, bottom: 6),
                                  decoration: BoxDecoration(
                                      color: MyColors.blueColorCode,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Text(
                                    "EDIT",
                                    style: TextStyle(
                                        color: MyColors.whiteColorCode,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  deleteposition = index;
                                  setState(() {});
                                  //! --Delete Alert Box--------------------------------
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20.0)), //this right here
                                          child: Container(
                                            height: 200,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(" Cancel Coff ",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20)),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10.0,
                                                            bottom: 10),
                                                    child: Text(
                                                      "Are you sure want to Cancel This COff...??",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 18),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      MaterialButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        shape: const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            10))),
                                                        child: const Text(
                                                          "No",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              color: MyColors
                                                                  .whiteColorCode),
                                                        ),
                                                        color: MyColors
                                                            .text3greyColorCode,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 15.0),
                                                        child: MaterialButton(
                                                          // padding: const EdgeInsets.only(left:15.0,right: 15,top: 4,bottom: 4),
                                                          onPressed: () {
                                                            // ✅ Close the dialog first
                                                            // Navigator.of(
                                                            //         context)
                                                            //     .pop();

                                                            // ✅ Call delete API
                                                            mainBloc.add(
                                                              CancelCoffOTHWOFFEvents(
                                                                staffCode:
                                                                    staffCode!,
                                                                transactionId:
                                                                    CoffList[
                                                                            index]
                                                                        .otwofFid
                                                                        .toString(),
                                                                token:
                                                                    Auth_Token!,
                                                              ),
                                                            );
                                                          },
                                                          shape: const RoundedRectangleBorder(
                                                              borderRadius: BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          10))),
                                                          child: const Text(
                                                            "Yes",
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: MyColors
                                                                    .whiteColorCode),
                                                          ),
                                                          color: MyColors
                                                              .redColorCode,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child: Container(
                                  height: 32,
                                  margin: EdgeInsets.only(top: 7, left: 20),
                                  padding: EdgeInsets.only(
                                      left: 20, right: 20, top: 5, bottom: 6),
                                  decoration: BoxDecoration(
                                      color: MyColors.redColorCode,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: MyColors.whiteColorCode,
                                        fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 15.0, bottom: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Staff",
                                          style: TextStyle(
                                              color: MyColors
                                                  .textprofiledetailColorCode,
                                              fontSize: 18)),
                                      Text(
                                          CoffList[index].staff.toString() !=
                                                  null
                                              ? CoffList[index].staff.toString()
                                              : "0",
                                          style: TextStyle(
                                              color: MyColors.text5ColorCode,
                                              fontSize: 18)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("COff Date",
                                        style: TextStyle(
                                            color: MyColors
                                                .textprofiledetailColorCode,
                                            fontSize: 18)),
                                    Text(
                                        CoffList[index].otDate != null
                                            ? CoffList[index].otDate!
                                            : "",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color: MyColors.text5ColorCode,
                                            fontSize: 18)),
                                  ],
                                ))
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Coff Type",
                                    style: TextStyle(
                                      color:
                                          MyColors.textprofiledetailColorCode,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    CoffList[index].type != null
                                        ? (CoffList[index].type == "HW "
                                            ? "H/WOFF"
                                            : CoffList[index].type!)
                                        : "",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: MyColors.text5ColorCode,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              )),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total Hours",
                                        style: TextStyle(
                                            color: MyColors
                                                .textprofiledetailColorCode,
                                            fontSize: 18)),
                                    Text(
                                        CoffList[index].ttlHrs != null
                                            ? CoffList[index].ttlHrs!
                                            : "",
                                        style: TextStyle(
                                            color: MyColors.text5ColorCode,
                                            fontSize: 18)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
      ),
    );
  }
}

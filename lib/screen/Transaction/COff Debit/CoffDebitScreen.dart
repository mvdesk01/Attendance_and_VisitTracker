import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Transaction/COff%20Debit/DebitCoffScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../../model/CoffDebit/GetCoffsTransactionsResponse.dart';
import '../../../util/custome_dialog.dart';

class CoffDebitscreen extends StatefulWidget {
  const CoffDebitscreen({super.key});

  @override
  State<CoffDebitscreen> createState() => _CoffDebitscreenState();
}

class _CoffDebitscreenState extends State<CoffDebitscreen> {
  late bool _isLoading = false;

  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";

  String? Auth_Token = "";

  late List<Message> CoffList = [];

  ScrollController gatepassRecordController = new ScrollController();

  int deleteposition = 0;

  @override
  void initState() {
    mainBloc = BlocProvider.of(context);
    super.initState();
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCode-->" + staffCode!);
    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->" + Auth_Token!);

    mainBloc.add(
        GetCoffsTransactionsEvents(staffCode: staffCode!, token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlocProvider(
                          create: (context) {
                            return MainBloc(webService: WebService());
                          },
                          child: HomeScreen())))),
          title: const Text("C-Off Debit"),
          backgroundColor: MyColors.lightBlue,
          centerTitle: true,
          titleTextStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ).copyWith(
            color: Colors.white,
          )),
      body: /*const Center(
        child: Text("Gate Pass Screen", style: TextStyle(fontFamily: 'Dubai'),),
      )*/
          WillPopScope(
        onWillPop: () async {
          /*   Navigator.pop(context, {"FilterAlert":false});
            return false;*/
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // You can also handle custom back button logic here
            // For example, exit the app, show a confirmation dialog, etc.

            print("Else Navigatorrrrrrrrrrrrr");

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider(
                        create: (context) {
                          return MainBloc(webService: WebService());
                        },
                        child: HomeScreen())));
            return false; // Prevent the app from closing
          }
          return true;
        },
        child: _addGatePassScreen(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.lightBlue,
        onPressed: () async {
          await Navigator.of(context).push(
            new MaterialPageRoute(
                builder: (_) => BlocProvider(
                    create: (context) {
                      return MainBloc(webService: WebService());
                    },
                    child: Debitcoffscreen(
                        flag: 1,
                        datum:
                            CoffList!.length == 0 ? Message() : CoffList[0]))),
          );

          //     mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));

          //   Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCoffScreen()));
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
      child: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic - you'll need to implement getData() method
          await getData();
        },
        child: BlocListener<MainBloc, MainState>(
          listener: (context, state) {
            //-----------ADD GatePass Entry-------------------
            if (state is GetCoffsTransactionsLoadingState) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is GetCoffsTransactionsLoadedState) {
              print("FetchCoffTransactionsLoadedState....");
              setState(() {
                _isLoading = false;
                CoffList =
                    List.from(state.getCoffsTransactionsResponse.message ?? []);
              });
              print("Pending CoffList Size: ${CoffList.length.toString()}");

              if (CoffList.isNotEmpty) {
                print("FetchCoffTransactionsErrorState otDate...." +
                    CoffList.first.cOffDate!.toString());
              }
            } else if (state is GetCoffsTransactionsErrorState) {
              print("FetchCoffTransactionsErrorState....");
              setState(() {
                _isLoading = false;
                CoffList = []; // Clear list on error
              });
              // Fluttertoast.showToast(msg: "Failed to load data");
            }

            //--------Cancel GatePass---------------------------
            if (state is CancelCoffLoadingState) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is CancelCoffLoadedState) {
              setState(() {
                _isLoading = false;
              });

              Fluttertoast.showToast(
                msg: state.cancelGatepassResponse.message!,
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );

              if (state.cancelGatepassResponse.message ==
                  "Canceled Successfully.") {
                print("deleteposition: " + deleteposition.toString());
                setState(() {
                  CoffList.removeAt(deleteposition);
                });
                print("CoffList Size : " + CoffList.length.toString());
                CustomDialog().popUp(
                    context, "Well done! Your C-OOff Debit is Canceled....!!");
              }
            } else if (state is CancelCoffErrorState) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(
                msg: "Failed To Connect Server...!",
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
                        height: 150,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Data Available",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
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
                          width: 1,
                          color: MyColors.textBoxBorderColorCode,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 15,
                          left: 14,
                          right: 14,
                          bottom: 15,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
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
                                    child: Text(
                                      "STATUS : PENDING",
                                      style: TextStyle(
                                          color: MyColors.greenColorCode),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider(
                                          create: (context) {
                                            return MainBloc(
                                                webService: WebService());
                                          },
                                          child: Debitcoffscreen(
                                            flag: 2,
                                            datum: CoffList[index],
                                          ),
                                        ),
                                      ),
                                    );
                                    // Refresh after returning from edit
                                    await getData();
                                  },
                                  child: Container(
                                    height: 32,
                                    margin:
                                        const EdgeInsets.only(top: 7, left: 20),
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 5,
                                      bottom: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MyColors.blueColorCode,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "EDIT",
                                      style: TextStyle(
                                        color: MyColors.whiteColorCode,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    deleteposition = index;
                                    setState(() {});
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
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
                                                  const Text(
                                                    "Cancel C-off Debit",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 10.0,
                                                      bottom: 10,
                                                    ),
                                                    child: Text(
                                                      "Are you sure want to Cancel This C-Off Debit...??",
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
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(10),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          "No",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color: MyColors
                                                                .whiteColorCode,
                                                          ),
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
                                                          onPressed: () {
                                                            mainBloc.add(
                                                              CancelCoffEvents(
                                                                staffCode:
                                                                    staffCode!,
                                                                CoffId: CoffList[
                                                                        index]
                                                                    .cOffId
                                                                    .toString(),
                                                                token:
                                                                    Auth_Token!,
                                                              ),
                                                            );
                                                          },
                                                          shape:
                                                              const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            "Yes",
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              color: MyColors
                                                                  .whiteColorCode,
                                                            ),
                                                          ),
                                                          color: MyColors
                                                              .redColorCode,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    height: 32,
                                    margin:
                                        const EdgeInsets.only(top: 7, left: 20),
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 5,
                                      bottom: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MyColors.redColorCode,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: MyColors.whiteColorCode,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 15.0, bottom: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Staff",
                                          style: TextStyle(
                                            color: MyColors
                                                .textprofiledetailColorCode,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          CoffList[index]
                                                      .staffCode
                                                      .toString() !=
                                                  null
                                              ? "${CoffList[index].staffCode.toString()} ${CoffList[index].name.toString()}"
                                              : "0",
                                          style: TextStyle(
                                            color: MyColors.text5ColorCode,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "COff Date",
                                          style: TextStyle(
                                            color: MyColors
                                                .textprofiledetailColorCode,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          CoffList[index].cOffDate ?? "",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            color: MyColors.text5ColorCode,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "From Time",
                                        style: TextStyle(
                                          color: MyColors
                                              .textprofiledetailColorCode,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        CoffList[index].fromTime ?? "",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: MyColors.text5ColorCode,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "To time",
                                        style: TextStyle(
                                          color: MyColors
                                              .textprofiledetailColorCode,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        CoffList[index].toTime ?? "",
                                        style: TextStyle(
                                          color: MyColors.text5ColorCode,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

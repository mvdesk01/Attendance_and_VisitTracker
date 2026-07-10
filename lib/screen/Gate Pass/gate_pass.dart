import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/GatePass/CancelGatePass.dart';
import 'package:attendance_system_ios/model/GatePass/GatePassResponse.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/AddGatePass.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/custome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../util/MyColor.dart';

class GatePass extends StatefulWidget {
  const GatePass({super.key});

  @override
  State<GatePass> createState() => _GatePassState();
}

class _GatePassState extends State<GatePass> {
  late bool _isLoading = false;

  late MainBloc mainBloc;
  final storage = FlutterSecureStorage();

  String? staffCode = "";

  String? Auth_Token = "";

  late List<Message> gatePasslist = [];

  ScrollController gatepassRecordController = new ScrollController();

  int deleteposition = 0;

  @override
  void initState() {
    mainBloc = BlocProvider.of(context);
    getData();
  }

  Future<void> getData() async {
    staffCode = await storage.read(key: 'Staff_Code');

    print("staffCodeeee-->" + staffCode!);

    Auth_Token = await storage.read(key: 'Auth_Token');

    print("Auth_Token-->" + Auth_Token!);

    mainBloc.add(
        GetPendingGatePassEvents(StaffCode: staffCode!, token: Auth_Token!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //     leading: IconButton(
      //         icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      //         onPressed: () =>
      //             Navigator.pushReplacement(
      //                 context,
      //                 MaterialPageRoute(
      //                     builder: (_) => BlocProvider(
      //                         create: (context) {
      //                           return MainBloc(
      //                               webService: WebService());
      //                         },
      //                         child: HomeScreen())))
      //     ),
      //
      //     title: const Text("Gate Pass"),
      //     backgroundColor: MyColors.lightBlue,
      //     centerTitle: true,
      //     titleTextStyle: GoogleFonts.roboto(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 18.0,
      //     ).copyWith(
      //       color: Colors.white,
      //     )
      // ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: HomeScreen(),
              ),
            ),
          ),
        ),
        title: Text(
          "Gate Pass",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),

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

      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: MyColors.lightBlue,
      //   onPressed: () async {
      //     await Navigator.of(context).push(
      //       new MaterialPageRoute(
      //           builder: (_) => BlocProvider(
      //               create: (context) {
      //                 return MainBloc(webService: WebService());
      //               },
      //               child: AddGatePass(
      //                   flag: 1,
      //                   datum: gatePasslist!.length == 0
      //                       ? Message()
      //                       : gatePasslist![0]))),
      //     );
      //
      //     //     mainBloc.add(GetStaffDetailsEvents(StaffCode: staffCode!, token: Auth_Token!));
      //
      //     //   Navigator.push(context, MaterialPageRoute(builder: (context) => const AddGatePass()));
      //   },
      //   child: Icon(Icons.add, color: MyColors.whiteColorCode),
      // ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyColors.lightBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: AddGatePass(
                  flag: 1,
                  datum: gatePasslist.isEmpty ? Message() : gatePasslist[0],
                ),
              ),
            ),
          );
        },
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
            //-----------ADD GatePass Entry-------------------

            if (state is GetPendingGatePassLoadingState) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is GetPendingGatePassLoadedState) {
              setState(() {
                _isLoading = false;
              });

              gatePasslist.addAll(state.gatePassResponse!.message ?? []);

              print("Pending GatePass List Size: " +
                  gatePasslist.length.toString());
            } else if (state is GetPendingGatePassErrorState) {
              setState(() {
                _isLoading = false;
              });
              /* Fluttertoast.showToast(
              msg: "   Failed To Connect Server...!   ",
              toastLength: Toast.LENGTH_SHORT,
              timeInSecForIosWeb: 1,
            );*/
            }
            //-----------Cancel GatePass----------------------

            if (state is CancelGatePassLoadingState) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is CancelGatePassLoadedState) {
              setState(() {
                _isLoading = false;
              });

              //if(state.gatePassResponse.message)
              Fluttertoast.showToast(
                msg: state.cancelGatePassResponse!.message!,
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
              //gatePasslist.addAll(state.gatePassResponse.message!);

              if (state.cancelGatePassResponse!.message ==
                  "GatePass Canceled Successfully..") {
                print("deleteposition: " + deleteposition.toString());
                gatePasslist.removeAt(deleteposition);

                print("gatePasslist Size : " + gatePasslist.length.toString());
                CustomDialog().popUp(
                    context, "Well done! Your GatePass is Canceled....!!");
              }
            } else if (state is CancelGatePassErrorState) {
              setState(() {
                _isLoading = false;
              });
              Fluttertoast.showToast(
                msg: "   Failed To Connect Server...!   ",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
              );
            }
          },
          child: gatePasslist.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/icons/no_data.png",
                          height: 170,
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "No Pending Gate Pass",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tap the Add button below to create a new Gate Pass.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: gatepassRecordController,
                  shrinkWrap: true,
                  itemCount: gatePasslist.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.circle,
                                        color: Colors.green,
                                        size: 9,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Pending",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text("Edit"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: MyColors.blueColorCode,
                                    side: BorderSide(
                                      color: MyColors.blueColorCode,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider(
                                          create: (context) => MainBloc(
                                              webService: WebService()),
                                          child: AddGatePass(
                                            flag: 2,
                                            datum: gatePasslist[index],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  label: const Text("Cancel"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(
                                      color: Colors.red,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
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
                                                    const Text(
                                                        " Cancel GatePass ",
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
                                                        "Are you sure want to Cancel This GatePass...??",
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          shape: const RoundedRectangleBorder(
                                                              borderRadius: BorderRadius
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
                                                              //! MainBloc Delete data---------

                                                              mainBloc.add(CancelGatePassEvents(
                                                                  cancelGatepassRequest: CancelGatepassRequest(
                                                                      staffCode:
                                                                          staffCode,
                                                                      appFlag:
                                                                          "PC",
                                                                      transactionId: gatePasslist[
                                                                              index]
                                                                          .transactionId
                                                                          .toString()),
                                                                  token:
                                                                      Auth_Token!));
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
                                    // KEEP YOUR EXISTING DIALOG CODE HER
                                  },
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 15.0, bottom: 15),
                              // child: Row(
                              //   mainAxisAlignment:
                              //       MainAxisAlignment.spaceAround,
                              //   children: [
                              //     Expanded(
                              //       child: Column(
                              //         mainAxisAlignment:
                              //             MainAxisAlignment.start,
                              //         crossAxisAlignment:
                              //             CrossAxisAlignment.start,
                              //         children: [
                              //           Text(
                              //             "GatePass date",
                              //             style: TextStyle(
                              //                 color: MyColors
                              //                     .textprofiledetailColorCode,
                              //                 fontSize: 18),
                              //           ),
                              //           // Text(gatePasslist[index].gatePassDate.toString()!=null ? gatePasslist[index].gatePassDate.toString() : "0",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                              //
                              //           Text(
                              //             gatePasslist[index].gatePassDate !=
                              //                     null
                              //                 ? DateFormat("dd-MM-yyyy").format(
                              //                     DateTime.parse(
                              //                         gatePasslist[index]
                              //                             .gatePassDate
                              //                             .toString()))
                              //                 : "N/A",
                              //             style: TextStyle(
                              //               color: MyColors.text5ColorCode,
                              //               fontSize: 18,
                              //             ),
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //     Expanded(
                              //         child: Column(
                              //       mainAxisAlignment: MainAxisAlignment.start,
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: [
                              //         Text(
                              //           "GatePass Type",
                              //           style: TextStyle(
                              //               color: MyColors
                              //                   .textprofiledetailColorCode,
                              //               fontSize: 18),
                              //         ),
                              //         Text(
                              //           gatePasslist[index].type != null
                              //               ? gatePasslist[index].type!
                              //               : "",
                              //           textAlign: TextAlign.left,
                              //           style: TextStyle(
                              //               color: MyColors.text5ColorCode,
                              //               fontSize: 18),
                              //         ),
                              //       ],
                              //     ))
                              //   ],
                              // ),

                              child: Row(
                                children: [
                                  Expanded(
                                    child: _infoTile(
                                      Icons.calendar_today,
                                      "GatePass Date",
                                      gatePasslist[index].gatePassDate != null
                                          ? DateFormat("dd MMM yyyy").format(
                                              DateTime.parse(
                                                gatePasslist[index]
                                                    .gatePassDate!,
                                              ),
                                            )
                                          : "N/A",
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _infoTile(
                                      Icons.badge_outlined,
                                      "GatePass Type",
                                      gatePasslist[index].type ?? "",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                            //   children: [
                            //     Expanded(
                            //         child: Column(
                            //       mainAxisAlignment: MainAxisAlignment.start,
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Text(
                            //           "From Time",
                            //           style: TextStyle(
                            //               color: MyColors
                            //                   .textprofiledetailColorCode,
                            //               fontSize: 18),
                            //         ),
                            //         // Text(gatePasslist[index].fromTime!=null ? gatePasslist[index].fromTime! : "",textAlign:TextAlign.left,style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                            //         Text(
                            //           gatePasslist[index].gatePassDate != null
                            //               ? DateFormat("hh:mm a").format(
                            //                   DateTime.parse(gatePasslist[index]
                            //                       .fromTime!))
                            //               : "N/A",
                            //           style: TextStyle(
                            //             color: MyColors.text5ColorCode,
                            //             fontSize: 18,
                            //           ),
                            //         )
                            //       ],
                            //     )),
                            //     Expanded(
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.start,
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         children: [
                            //           Text(
                            //             "To Time",
                            //             style: TextStyle(
                            //                 color: MyColors
                            //                     .textprofiledetailColorCode,
                            //                 fontSize: 18),
                            //           ),
                            //           // Text(gatePasslist[index].toTime!=null ? gatePasslist[index].toTime! : "",style: TextStyle(color: MyColors.text5ColorCode,fontSize: 18),),
                            //           Text(
                            //             gatePasslist[index].gatePassDate != null
                            //                 ? DateFormat("hh:mm a").format(
                            //                     DateTime.parse(
                            //                         gatePasslist[index]
                            //                             .toTime!))
                            //                 : "N/A",
                            //             style: TextStyle(
                            //               color: MyColors.text5ColorCode,
                            //               fontSize: 18,
                            //             ),
                            //           )
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: _infoTile(
                                    Icons.schedule,
                                    "From Time",
                                    gatePasslist[index].fromTime != null
                                        ? DateFormat("hh:mm a").format(
                                            DateTime.parse(
                                              gatePasslist[index].fromTime!,
                                            ),
                                          )
                                        : "N/A",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _infoTile(
                                    Icons.access_time_filled,
                                    "To Time",
                                    gatePasslist[index].toTime != null
                                        ? DateFormat("hh:mm a").format(
                                            DateTime.parse(
                                              gatePasslist[index].toTime!,
                                            ),
                                          )
                                        : "N/A",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

          /*const Center(
    child: Text("Gate Pass Screen", style: TextStyle(fontFamily: 'Dubai'),),
      ),*/
        ));
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: MyColors.lightBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

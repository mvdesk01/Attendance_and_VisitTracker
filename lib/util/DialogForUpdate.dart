import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/screen/Gate%20Pass/gate_pass.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/screen/Leave/leave.dart';
import 'package:attendance_system_ios/screen/Transaction/COff%20Debit/CoffDebitScreen.dart';
import 'package:attendance_system_ios/screen/Transaction/CoffCreditScreen.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialogForUpdate{

  popUp(BuildContext context,String title,String id){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: 350,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Lottie.network(
                        'https://assets7.lottiefiles.com/packages/lf20_dp4jvfth.json',width: 115,height: 115),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0,bottom: 10),
                      child: Text(title,textAlign:TextAlign.center ,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                    ),
                    MaterialButton(
                      onPressed: () {
                        //print(("exist");
                        if(id=="3"){
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;
                          Navigator.of(context).popUntil((_) => count-- <= 0);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: GatePass())));
                        }
                        else if(id=="1")
                        {
                          //print(("id==1");
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;
                          Navigator.of(context).popUntil((_) => count-- <= 0);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: CoffDebitscreen())));

                        }
                        else if(id=="2"){
                          //print(("id==2");
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;
                          Navigator.of(context).popUntil((_) => count-- <= 0);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: Coffcreditscreen())));
                        }
                        else if(id=="4"){
                          //print(("id==4");
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;
                          Navigator.of(context).popUntil((_) => count-- <= 0);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: HomeScreen())));

                         /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: DriverMasterScreen())));*/
                        }

                        else if(id=="5"){
                          //print(("id==5");
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;

                          Navigator.of(context).popUntil((_) => count-- <= 0);

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: HomeScreen())));
                        }
                        else if(id=="6"){
                          //print(("id==6");
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;

                          Navigator.of(context).popUntil((_) => count-- <= 0);

                        /*  Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: SubscriptionMasterScreen())));*/
                        }
                        else if(id=="7"){
                          //print(("id==7");
                          Navigator.of(context).pop();
                          Navigator.pop(context, true);
                          int count = 1;

                          Navigator.of(context).popUntil((_) => count-- <= 0);

                         /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                      create: (context) {
                                        return MainBloc(webService: WebService());
                                      },
                                      child: AlertMasterScreen())));*/
                        }

                        else{

                        }

                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                      child: Text(
                        "Done",
                        style: TextStyle(fontSize:18,color: MyColors.whiteColorCode),
                      ),
                      color:MyColors.blueColorCode,
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}

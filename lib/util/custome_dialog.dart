import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomDialog{

  popUp(BuildContext context,String title){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: 260,
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
                      //  print("exist");
                        Navigator.of(context).pop();
                        Navigator.pop(context, true);

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

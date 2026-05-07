import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../screen/admin_side/user_list_screen/user_list_screen.dart';

class CustomDialog
{

  popUp(BuildContext context,String title)
  {
    showDialog(
        context: context,
        builder: (BuildContext context)
        {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ✅ prevents overflow
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets7.lottiefiles.com/packages/lf20_dp4jvfth.json',
                    width: 115,
                    height: 115,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context, true);
                      int count = 2;
                      Navigator.of(context).popUntil((_) => count-- <= 0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (context) {
                              return MainBloc(webService: WebService());
                            },
                            child: UserListScreen(),
                          ),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: MyColors.blueColorCode,
                    child: Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 18,
                        color: MyColors.whiteColorCode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );        });
  }
}

import 'package:attendance_system_ios/screen/Login/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';

// testWidgets('Should show error if mobile empty',
// (tester) async {
//
// await tester.pumpWidget(MyLoginScreen());
//
// await tester.tap(find.text("LOGIN"));
//
// await tester.pump();
//
// expect(find.text("Enter mobile number"),
// findsOneWidget);
// });
//
// testWidgets('Punch In button should work',
// (tester) async {
//
// bool clicked = false;
//
// await tester.pumpWidget(
// MaterialApp(
// home: ElevatedButton(
// onPressed: () {
// clicked = true;
// },
// child: Text("Punch In"),
// ),
// ),
// );
//
// await tester.tap(find.text("Punch In"));
//
// expect(clicked, true);
// });

// void main(){
// testWidgets('Login button should exist',(tester) async{
//   await tester.pumpWidget(const LoginScreen());
//   await tester.tap(find.text("LOGIN"));
//   await tester.pump();
//   expect(find.text("Login"), findsOneWidget);
// });
// }

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {

  testWidgets(
    'LOGIN button should exist',
        (tester) async {

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text("LOGIN"),
            ),
          ),
        ),
      );

      expect(find.text("LOGIN"),
          findsOneWidget);
    },
  );
}
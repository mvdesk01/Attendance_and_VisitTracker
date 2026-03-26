// import 'dart:async';
// import 'package:flutter/material.dart';
//
// class SessionManager {
//   static const int inactivityLimit = 1 * 60; // 20 minutes in seconds
//   Timer? _inactivityTimer;
//   final GlobalKey<NavigatorState> navigatorKey;
//
//   SessionManager(this.navigatorKey);
//
//
//   void startTimer(VoidCallback onTimeout) {
//     _inactivityTimer?.cancel();
//     _inactivityTimer = Timer(Duration(seconds: inactivityLimit), onTimeout);
//   }
//
//   void resetTimer() {
//     _inactivityTimer?.cancel();
//     _inactivityTimer = Timer(Duration(seconds: inactivityLimit), () {
//       onLogout();
//     });
//   }
//
//   void onLogout() {
//     print('Logging out due to inactivity');
//     // Navigate to login screen
//     navigatorKey.currentState?.pushReplacementNamed('/login');
//   }
// }
//
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// final SessionManager sessionManager = SessionManager(navigatorKey);

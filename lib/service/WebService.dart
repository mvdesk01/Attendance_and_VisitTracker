import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:attendance_system_ios/model/CoffCredit/CreditCOffEntryRequest.dart';
import 'package:attendance_system_ios/model/CoffCredit/FetchCoffTransactionsResponse.dart';
import 'package:attendance_system_ios/model/CoffCredit/GetStaffDetailsForCoffResponse.dart';
import 'package:attendance_system_ios/model/CoffDebit/GetCoffsTransactionsResponse.dart';
import 'package:attendance_system_ios/model/CoffDebit/SubmitCoffDebitRequest.dart';
import 'package:attendance_system_ios/model/Expense/ViewexpenseAdmin.dart';
import 'package:attendance_system_ios/model/GatePass/AddGatepassRequest.dart';
import 'package:attendance_system_ios/model/GatePass/CancelGatePass.dart';
import 'package:attendance_system_ios/model/GatePass/CancelgatepassResponse.dart';
import 'package:attendance_system_ios/model/GatePass/StaffDetailsResponse.dart';
import 'package:attendance_system_ios/model/Leave/CancelLeave.dart';
import 'package:attendance_system_ios/model/Leave/LeavePendingResponse.dart';
import 'package:attendance_system_ios/model/Leave/LeaveTypeDetails.dart';
import 'package:attendance_system_ios/model/Leave/Staffdetails.dart';
import 'package:attendance_system_ios/model/Leave/SubmitLeaveResponse.dart';
import 'package:attendance_system_ios/model/Login/LoginResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfMeetingFormNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingDataByVisitSrNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMALLDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMRowDataRequest.dart';
import 'package:attendance_system_ios/model/Profile/ProfileResponse.dart';
import 'package:attendance_system_ios/model/Profile/UpdateUserinfo.dart';
import 'package:attendance_system_ios/model/SanctionModel/SanctionApprove.dart';
import 'package:attendance_system_ios/model/SanctionModel/Sanctionn.dart';
import 'package:attendance_system_ios/model/UsersList/AddStaffRequest.dart';
import 'package:attendance_system_ios/model/UsersList/GetAllusersListResponse.dart';
import 'package:attendance_system_ios/model/VisitHistory/VisitDataResponse.dart';
import 'package:attendance_system_ios/model/VisitHistory/VisitLatLongListResponse.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitDetailedRecordsResponse.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitRecordsResponse.dart';
import 'package:attendance_system_ios/screen/Splash%20Screen/splash_screen.dart';
import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:attendance_system_ios/util/Constant.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:path/path.dart';
import '../main.dart';
import '../model/CancellationRequestData/CCreditCancellationRequest.dart';
import '../model/CancellationRequestData/CDebitCancellationRequest.dart';
import '../model/CancellationRequestData/CancellationRequestResponse.dart';
import '../model/CancellationRequestData/GatepassCancellationRequest.dart';
import '../model/CancellationRequestData/LeaveCancellationRequest.dart';
import '../model/CancellationRequestData/SUbmitOtCancellation.dart';
import '../model/CancellationRequestData/SubmilLeaveCancellation.dart';
import '../model/CancellationRequestData/SubmitCDebitCancellation.dart';
import '../model/CancellationRequestData/SubmitCoffCancellation.dart';
import '../model/CancellationRequestData/SubmitGatepassCancellation.dart';
import '../model/CancellationRequestData/SubmitTourCancellation.dart';
import '../model/CancellationRequestData/TourCancellationRequest.dart';
import '../model/Expense/Submitexpenserecords.dart';
import '../model/GatePass/GatePassResponse.dart';
import '../model/MinutesOfTheMettingForm/UpdateMMAllData.dart';
import '../model/MinutesOfTheMettingForm/UpdateMMData.dart';
import '../model/RemoteLocation/RemoteLocation.dart';
import '../model/Tour/AppliedTour.dart';
import '../model/Tour/Getstaffdetails.dart';
import '../model/Tour/Submittourdetails.dart';
import '../model/UsersList/SearchbystaffcodeResponse.dart';
import '../model/UsersList/UpdateUUID.dart';
import '../screen/Login/login_screen.dart';
import '../util/customExceptions.dart';

class WebService

{
  Future<LoginResponse?> userLogin(String username, String password) async {
    try {
      print("🔹 API URL: ${Constant.loginUrl}");
      print("🔹 Username: $username");
      print("🔹 Password: $password");

      final url = Uri.parse(
        "${Constant.loginUrl}UserId=$username&Password=$password",
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      print("✅ Response Status: ${response.statusCode}");
      print("✅ Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      }
      else if (response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: "Invalid Credentials. Please check your username or password.",
          toastLength: Toast.LENGTH_LONG,
        );
        // return LoginResponse.fromJson(jsonDecode(response.body));
        return null;
      }
      else if (response.statusCode == 404) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String errorMessage = data['message'] ?? "Server not found.";
        Fluttertoast.showToast(msg: errorMessage);
        // return LoginResponse.fromJson(jsonDecode(response.body));
        return null;
      }
      else {
        Fluttertoast.showToast(
          msg: "Unexpected error occurred. Please try again later.",
        );
        // return LoginResponse.fromJson(jsonDecode(response.body));
        return null;
      }

    } on SocketException catch (_) {
      // 🔹 Handles no internet, airplane mode, unreachable host, etc.
      Fluttertoast.showToast(
        msg: "No internet connection. Please check your network and try again.",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    } on TimeoutException catch (_) {
      // 🔹 Handles slow network or timeout
      Fluttertoast.showToast(
        msg: "Request timed out. Please try again later.",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    } catch (e) {
      // 🔹 Any other error
      LogFileManager.writeLog('Error in user login: $e');
      print('❌ Error in user login: $e');
      Fluttertoast.showToast(
        msg: "Something went wrong. Please try again.",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  Future<StaffDetailsResponse?> getStaffDetails(String StaffCode,String token) async {
try{
  print(Constant.staffDetailsUrl);
  print("username--->"+StaffCode );

  final response = await http.get(
    Uri.parse(Constant.staffDetailsUrl+StaffCode),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
  ).timeout(Duration(seconds: 15));

  print("getStaffDetails response---->" + response.body);
  print("getStaffDetails response status code---->" + response.statusCode.toString());
  print(response.body);
  if(response.statusCode==200) {
    print('gatepass data updated successfully');
    return StaffDetailsResponse.fromJson(jsonDecode(response.body));

  }else if(response.statusCode==400){
    Fluttertoast.showToast(
      msg: "  " +response.body+"...!",
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 1,
      // Set the text color
    );
    return StaffDetailsResponse.fromJson(jsonDecode(response.body));
  }
  else if(response.statusCode==401){
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Unauthorized. Kindly Login Again!!'),
        action: SnackBarAction(
          label: 'Login Again',
          onPressed: () {
            isloggedIn= true;
            // Navigate using the global navigator key
            MyApp.navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) =>SplashScreen()),
            );
          },
        ),
        duration: Duration(minutes: 2), // Make it sticky
      ),
    );

    return StaffDetailsResponse.fromJson(jsonDecode(response.body));
  }
  return StaffDetailsResponse.fromJson(jsonDecode(response.body));
} on TimeoutException{
  // 🔹 Handles slow network or timeout
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text('Request timed out'),
      action: SnackBarAction(
        label: 'Try Again',
        onPressed: () {
           getStaffDetails(
            StaffCode,
            token,
          );
        },
      ),
      duration: Duration(days: 2), // Make it sticky
    ),
  );
}
catch(e){
  LogFileManager.writeLog('Error in getStaffDetails: $e');
  print('Error in getStaffDetails: $e');
  return null;
}
}


  Future<GatePassResponse?> getPendingGatepass(String StaffCode,String token) async {
    try{
      print("getPendingGatepass : "+Constant.getPendinggatePassUrl);
      print("username--->"+StaffCode );
      final response = await http.get(
        Uri.parse(Constant.getPendinggatePassUrl +StaffCode ),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      print("getPendingGatepass response---->" + response.body);
      print("getPendingGatepass status code---->" + response.statusCode.toString());
      if(response.statusCode==200){
        return GatePassResponse.fromJson(jsonDecode(response.body));
      }
      else if(response.statusCode==400){
        print('gatepass: ${response.body}');
        Fluttertoast.showToast(
          msg: "  " +response.body+"...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        return GatePassResponse.fromJson(jsonDecode(response.body));

      }
      else if(response.statusCode==401){
        print(response.body);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );


        // scaffoldMessengerKey.currentState?.showSnackBar(
        //   SnackBar(
        //     content: Text('Unauthorized. Kindly Login Again!!'),
        //     action: SnackBarAction(
        //       label: 'Login Again',
        //       onPressed: () {
        //         // Navigate using the global navigator key
        //         MyApp.navigatorKey.currentState?.pushReplacement(
        //MaterialPageRoute(builder: (context) => SplashScreen()),
        //         );
        //       },
        //     ),
        //     duration: Duration(minutes: 2), // Make it sticky
        //   ),
        // );

        return GatePassResponse.fromJson(jsonDecode(response.body));

      }
      else if(response.statusCode==404){

        Fluttertoast.showToast(
          msg: "  No Pending GatePass!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        //   return GatePassResponse.fromJson(jsonDecode(response.body));

      }
      return GatePassResponse.fromJson(jsonDecode(response.body));
    } catch(e){
      LogFileManager.writeLog('Error in getPendingGatePass: $e');
      print('Error in getPendingGatePass: $e');
      return null;
    }
  }


  Future<CancelGatepassResponse?> addGatePass(
      AddGatepassRequest addGatePassRequest, String token) async {
    try{
      print("addGatePassRequest==========>"+Constant.addGatepass
          +"transactionID :"+ addGatePassRequest.transactionID.toString()+
          "gatePassDate :"+ addGatePassRequest.gatePassDate.toString()+
          "staffCode :"+ addGatePassRequest.staffCode.toString()+
          "designation :"+ addGatePassRequest.designation.toString()+
          "dept :"+ addGatePassRequest.dept.toString()+
          "gatePassTypeCode :"+ addGatePassRequest.gatePassTypeCode.toString()+
          "fromTime :"+ addGatePassRequest.fromTime.toString()+
          "toTime :"+ addGatePassRequest.toTime.toString()+
          "totalTime :"+ addGatePassRequest.totalTime.toString()+
          "shiftCode :"+ addGatePassRequest.shiftCode.toString()+
          "reason :"+ addGatePassRequest.reason.toString()+
          "purpose :"+ addGatePassRequest.purpose.toString()+
          "chkActive :"+ addGatePassRequest.chkActive.toString()+
          "add :"+ addGatePassRequest.add.toString() );

      //String addNewGatePassRequest=addGatePassRequestToJson(addGatePassRequest);
      final response = await http.post(
        Uri.parse(Constant.addGatepass),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(addGatePassRequest),
      );
      print("addGatePassRequest response :" +response.body);
      print("addGatePassRequest response :" +response.statusCode.toString());

      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    } catch(e){
      LogFileManager.writeLog('Error in addGatePass: $e');
      print('Error in addGatePass: $e');
      return null;
    }
  }


  Future<CancelGatepassResponse?> cancelGatePass(
      CancelGatepassRequest cancelGatePassRequest, String token) async {

    try{
      print("CancelGatePassRequest urll==========>"+Constant.cancelGatepass
          +"staffCode :"+ cancelGatePassRequest.staffCode.toString()+
          "transactionId :"+ cancelGatePassRequest.transactionId.toString()+
          "appFlag :"+ cancelGatePassRequest.appFlag.toString()
      );

      //String cancelGatePassRequestt=cancelGatepassRequestToJson(cancelGatePassRequest);
      final response = await http.post(
        Uri.parse(Constant.cancelGatepass),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cancelGatePassRequest),
      );
      print("CancelGatePass response statusCode:" +response.statusCode.toString());

      print("CancelGatePass response Body :" +response.body);

      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    } catch(e){
      LogFileManager.writeLog('Error in cancleGatePass: $e');
      print('Error in cancleGatePass: $e');
    }
  }
//Visit History
  Future<VisitDataResponse?> GetAllVisits(String UserId ,int pageNumber,int pageSize  ,String token) async {
   try{
     print("GetAllVisits : "+Constant.getAllVisitData);
     print("UserId--->"+UserId );
     print("pageNumber--->"+pageNumber.toString() );
     print("pageSize--->"+pageSize.toString() );

     final response = await http.get(
       Uri.parse(Constant.getAllVisitData +UserId +"/"+pageNumber.toString()+"/"+pageSize.toString() ),
       headers: <String, String>{
         'Content-Type': 'application/json; charset=UTF-8',
         'Authorization': 'Bearer $token',
       },
     );
     print("GetAllVisits response---->" + response.body);
     print("GetAllVisits status code---->" + response.statusCode.toString());
     if(response.statusCode==200){
       return VisitDataResponse.fromJson(jsonDecode(response.body));
     }
     else if(response.statusCode==400){
       Fluttertoast.showToast(
         msg: "Visit Records Not Found",
         toastLength: Toast.LENGTH_LONG,
         timeInSecForIosWeb: 1,
         // Set the text color
       );
       // return VisitDataResponse.fromJson(jsonDecode(response.body));

     }
     else if(response.statusCode==401){

       scaffoldMessengerKey.currentState?.showSnackBar(
         SnackBar(
           content: Text('Unauthorized. Kindly Login Again!!'),
           action: SnackBarAction(
             label: 'Login Again',
             onPressed: () {
               isloggedIn= true;
               // Navigate using the global navigator key
               MyApp.navigatorKey.currentState?.pushReplacement(
                 MaterialPageRoute(builder: (context) => SplashScreen()),
               );
             },
           ),
           duration: Duration(minutes: 2), // Make it sticky
         ),
       );

       // return VisitDataResponse.fromJson(jsonDecode(response.body));

     }
     return VisitDataResponse.fromJson(jsonDecode(response.body));
   } catch(e){
     LogFileManager.writeLog("Error in getAllVisits: $e");
     print("Error in getAllVisits: $e");
   }
  }

  Future<VisitLatLongListResponse?> GetVisiLatLongList(String StaffCode  ,String ActualDate ,String SrNoVal  ,String token) async {
  try{
    print("getVisitLatLongList : "+Constant.getVisitLatLongList);
    print("UserId--->"+StaffCode );
    print("ActualDate--->"+ActualDate.toString() );
    print("SrNoVal--->"+SrNoVal.toString() );

    final response = await http.get(
      Uri.parse(Constant.getVisitLatLongList +StaffCode +"/"+ActualDate+"/"+SrNoVal ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print("GetVisiLatLongList response---->" + response.body);
    print("GetVisiLatLongList status code---->" + response.statusCode.toString());
    if(response.statusCode==200){
      return VisitLatLongListResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode==400){
      Fluttertoast.showToast(
        msg: "Visit Records Not Found",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
        // Set the text color
      );
      // return VisitDataResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode==401){


      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );

      // return VisitDataResponse.fromJson(jsonDecode(response.body));
    }
    return VisitLatLongListResponse.fromJson(jsonDecode(response.body));
  } catch(e){
    LogFileManager.writeLog("Error in GetVisitLatLongList: $e");
    print("Error in GetVisitLatLongList: $e");
  }
  }

  ///searchbystaffcode
  Future<UserResponse> searchuserbystaffcode(String token, String staffcode,) async {
    print("${Constant.searchbystaffcode}${staffcode.toUpperCase()}");
    try {
      final uri = Uri.parse(
          "${Constant.searchbystaffcode}${staffcode.toUpperCase()}"
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ fixed
        },
      );

      print("searchbystaffcode: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return UserResponse.fromJson(jsonData); // ✅ IMPORTANT
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }

    } catch (e) {
      LogFileManager.writeLog("searchbystaffcode $e");
      throw Exception(e.toString()); // ✅ important
    }
  }

  //getAllUsersData
  Future<GetAllusersListResponse?> GetAllUsers(String token, String pagenumber, String pagesize) async {
    try{
      print("GetAllUsers : "+ "${Constant.pageinitiationalluserlist}$pagenumber/$pagesize");

      print("getAllUser Token: $token");
      final uri = Uri.parse(
          "${Constant.pageinitiationalluserlist}$pagenumber/$pagesize"
      );
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      print("GetAllUsers ---->" + response.body);
      print("GetAllUsers --->" + response.statusCode.toString());
      print("FULL RESPONSE: ${response.body}");
      if (response.statusCode == 200) {
        return GetAllusersListResponse.fromJson(jsonDecode(response.body));
      }
      else if (response.statusCode == 400) {
        Fluttertoast.showToast(msg: "No Records Found");
        return null; // ✅ IMPORTANT
      }
      else if(response.statusCode==401)
      {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                if (MyApp.navigatorKey.currentState != null) {
                  MyApp.navigatorKey.currentState!.pushReplacement(
                    MaterialPageRoute(builder: (context) => SplashScreen()),
                  );
                } else {
                  Fluttertoast.showToast(msg: "unable to navigate. kindly restart the application!");
                  print("Navigator Key is null. Unable to navigate.");
                }
                // MyApp.navigatorKey.currentState?.pushReplacement(
                //   MaterialPageRoute(builder: (context) =>SplashScreen()),
                // );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),

        );

      }
      return GetAllusersListResponse.fromJson(jsonDecode(response.body));
    } catch(e){
      LogFileManager.writeLog('Error in GetAllUsers: $e');
    }
  }


  Future<bool> requestDataDeletion(String token, String staffCode) async {
    print("requestDataDeletion params: $staffCode");
    try {
      final uri = Uri.parse(
        "${Constant.requestDataDeletion}userId=$staffCode&flag=Y",
      );
      print("${Constant.requestDataDeletion}?userId=$staffCode&flag=Y");

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 10));

      print("requestDataDeletion statuscode: ${response.statusCode}");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["message"] == "Flag Updated Successfully") {
          return true;
        } else {
          final decoded = jsonDecode(response.body);
          print("requestDataDeletion response 200: ${decoded["message"]}");
          Fluttertoast.showToast(msg: "${decoded["message"]}");
          return false;
        }
      } else {
        final decoded = jsonDecode(response.body);
        print("requestDataDeletion response: ${decoded["message"]}");
        Fluttertoast.showToast(msg: "Something went wrong");
        return false;
      }
    } on TimeoutException {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Request timeout. Please try again later.")),
      );
      return false;
    } catch (e) {
      print("requestDataDeletion error: $e");
      LogFileManager.writeLog("requestDataDeletion error: $e");
      return false;
    }
  }
  //GetVisitByFromDateToDate
  Future<VisitRecordsResponse?> GetVisitByFromDateToDate(String UserId   ,int pageNumber  ,int pageSize ,String fromDate, String toDate  ,String token) async {
    try{
      print("GetVisitByFromDateToDate : "+Constant.getVisitByFromDateToDate);
      print("UserId--->"+UserId  );
      print("pageNumber --->"+pageNumber.toString() );
      print("pageSize --->"+pageSize.toString()  );
      print("fromDate --->"+fromDate  );
      print("toDate  --->"+toDate   );
      String encodedFromDate = Uri.encodeComponent(fromDate);
      String encodedToDate = Uri.encodeComponent(toDate);
      print("encodedFromDate --->"+encodedFromDate  );
      print("encodedToDate  --->"+encodedToDate   );
      print(Constant.getVisitByFromDateToDate +UserId  +"/"+pageNumber.toString() +"/"+pageSize.toString() +"/"+ encodedFromDate+"/"+encodedToDate);

//http://114.143.140.28:8020/api/Visit/GetVisitByFromDateToDate/CD02974/1/50/01%2F10%2F2024/25%2F11%2F2024
      final response = await http.get(
        Uri.parse(Constant.getVisitByFromDateToDate +UserId  +"/"+pageNumber.toString() +"/"+pageSize.toString() +"/"+ encodedFromDate+"/"+encodedToDate),
        headers: <String, String>
        {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      print("GetVisitByFromDateToDate response---->" + response.body);
      print("GetVisitByFromDateToDate status code---->" + response.statusCode.toString());
      if(response.statusCode==200)
      {
        try {
          return VisitRecordsResponse.fromJson(jsonDecode(response.body));
        }
        catch(e){
          LogFileManager.writeLog('Error in GetVisitByFromDatetoDate: $e');
          print("Error: $e");
        }
      }
      else if(response.statusCode==400)
      {
        Fluttertoast.showToast(
          msg: "Visit Records Not Found",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        // return VisitDataResponse.fromJson(jsonDecode(response.body));
      }
      else if(response.statusCode==401){

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );

        // return VisitDataResponse.fromJson(jsonDecode(response.body));
      }
      return VisitRecordsResponse.fromJson(jsonDecode(response.body));
    } catch(e){
      LogFileManager.writeLog('Error in GetVisitByFromDatetoDate: $e');
      print('Error in GetVisitByFromDatetoDate: $e');
    }
  }

  //GetVisitRecords
  Future<VisitDetailedRecordsResponse?> GetVisitRecords(String StaffCode    ,String  FromDate   ,String  ToDate  ,String SrNoVal ,String token) async {
    try{
      print("GetVisitRecords : "+Constant.getVisitRecords);
      print("UserId--->"+StaffCode  );
      print("pageNumber --->"+FromDate.toString() );
      print("pageSize --->"+ToDate.toString()  );
      print("fromDate --->"+SrNoVal  );
      print(Constant.getVisitRecords +"StaffCode="+StaffCode  +"&FromDate="+FromDate.toString() +"&ToDate="+ToDate.toString() +"&SrNoVal="+ SrNoVal);

      final response = await http.get(
        Uri.parse(Constant.getVisitRecords +"StaffCode="+StaffCode  +"&FromDate="+FromDate.toString() +"&ToDate="+ToDate.toString() +"&SrNoVal="+ SrNoVal),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      print("GetVisitRecords response---->" + response.body);
      print("GetVisitRecords status code---->" + response.statusCode.toString());
      if(response.statusCode==200){
        return VisitDetailedRecordsResponse.fromJson(jsonDecode(response.body));
      }
      else if(response.statusCode==400){
        Fluttertoast.showToast(
          msg: "Visit Records Not Found",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        // return VisitDataResponse.fromJson(jsonDecode(response.body));
      }
      else if(response.statusCode==401){
        Fluttertoast.showToast(
          msg: " UnAuthorized! ",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
          // Set the text color
        );
        // return VisitDataResponse.fromJson(jsonDecode(response.body));
      }
      return VisitDetailedRecordsResponse?.fromJson(jsonDecode(response.body));
    } catch(e){
      LogFileManager.writeLog("Error in GetVisitRecords: $e");
      print("Error in GetVisitRecords: $e");
    }
  }
//-----------leave----------------
  Future<Staffdetails>getleavestaffdetails(String StaffCode, String token) async{
    print(Constant.getleavestaffdetailsUrl);
    print("username--->"+StaffCode );

    final response = await http.get(
      Uri.parse(Constant.getleavestaffdetailsUrl +StaffCode ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print("userLogin response---->" + response.body);
    print("userLogin response status code---->" + response.statusCode.toString());

    print("username--->"+response.body);

    if(response.statusCode==200){
      return Staffdetails.fromJson(jsonDecode(response.body));

    }else if(response.statusCode==400){
      Fluttertoast.showToast(msg: response.body);
      print("userLogin response==" + response.body);
      print("userLogin response status code==" + response.statusCode.toString());
      return Staffdetails.fromJson(jsonDecode(response.body));

    }
    return Staffdetails.fromJson(jsonDecode(response.body));
  }

  Future<LeavePendingResponse> getpendingleave(String StaffCode, String token, String ApprovedFlag) async {
    print(Constant.getpendingleaveUrl);
    print("username--->" + StaffCode);
    print("ApprovedFlag--->" + ApprovedFlag);

    // Add query parameters to the URL
    final Uri url = Uri.parse(Constant.getpendingleaveUrl)
        .replace(queryParameters: {
      'StaffCode': StaffCode,
      'ApprovedFlag': ApprovedFlag,
    });

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("Response status code: " + response.statusCode.toString());
    print("Response body: " + response.body);

    if (response.statusCode == 200) {
      return LeavePendingResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      Fluttertoast.showToast(
        msg: "  " + response.body + "...!",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return LeavePendingResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode == 401){

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {

                isloggedIn= true;

              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );

    }
    else if (response.statusCode == 404) {
      Fluttertoast.showToast(
        msg: "  No Pending Leaves To Show!",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
    }
    return LeavePendingResponse.fromJson(jsonDecode(response.body));
  }

  Future<LeaveDetails> getleavetypelist(String StaffCode, String token, String Year) async {
    print(Constant.getleavetypelistUrl);
    print("username--->" + StaffCode);
    print("year--->" + Year);

    final uri = Uri.parse(Constant.getleavetypelistUrl).replace(
      queryParameters: {
        'staffcode': StaffCode,
        'year': Year,
      },
    );

    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("userLogin response---->" + response.body);
    print("userLogin response status code---->" + response.statusCode.toString());

    if (response.statusCode == 200) {
      return LeaveDetails.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      Fluttertoast.showToast(msg: response.body);
      print("userLogin response:" + response.body);
      print("userLogin response status code:" + response.statusCode.toString());
      return LeaveDetails.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn = true;
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2),
        ),
      );
    }
    else if (response.statusCode == 404) {
      //Fluttertoast.showToast(msg: "No leave data found for the given staff code.");
      print("userLogin response:" + response.body);
      print("userLogin response status code:" + response.statusCode.toString());
      return LeaveDetails.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to load leave details");
  }

  Future<SubmitLeaveDetails> submitLeaveDetails(SubmitLeaveDetails submitLeaveDetails, String token) async {
    try {
      // Log the URL being used
      print(Constant.submitleaveUrl);

      // Send the POST request
      final response = await http.post(
        Uri.parse(Constant.submitleaveUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(submitLeaveDetails.toJson()), // Serialize the object
      );

      // Log the response
      print("Response Body: ${response.body}");
      print("Response Status Code: ${response.statusCode}");

      // Handle the response
      if (response.statusCode == 200) {
        // Parse and return the successful response
        Fluttertoast.showToast(
          msg: response.body,
          toastLength: Toast.LENGTH_SHORT,
        );

        return SubmitLeaveDetails.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Handle client-side error
        Fluttertoast.showToast(
          msg: "Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Error: ${response.body}");
      }
      else {
        // Handle other unexpected errors
        Fluttertoast.showToast(
          msg: "Unexpected Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Unexpected Error: ${response.body}");
      }
    } catch (e) {
      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to submit leave details: $e");
    }
  }

  Future<CancelLeaveBody>cancelleave(CancelLeaveBody cancelleavebody, String token)async{
    try{
      print(Constant.cancelleaveUrl);
      print(cancelleavebody);
      print(token);

      final response = await http.post(
        Uri.parse(Constant.cancelleaveUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cancelleavebody.toJson()),
        // Serialize the object
      );
      print("Response Body: ${response.body}");
      print("Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parse and return the successful response
        Fluttertoast.showToast(
          msg: "Applied Leave Cancelled",
          toastLength: Toast.LENGTH_SHORT,
        );
        return CancelLeaveBody.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Handle client-side error
        Fluttertoast.showToast(
          msg: "Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Error: ${response.body}");
      } else {
        // Handle other unexpected errors
        Fluttertoast.showToast(
          msg: "Unexpected Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Unexpected Error: ${response.body}");
      }
    } catch (e) {
      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to submit leave details: $e");
    }

  }

  Future<ProfileResponse> userinfo(String staffCode, String token) async {
    print("Fetching user info for staffCode: $staffCode");
    print(Constant.userinfo);
    final response = await http.get(
      Uri.parse(Constant.userinfo+"staffCode="+staffCode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print("User info response: " + response.body);
    print("Response status code: " + response.statusCode.toString());

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the data
      print('Home screen data updated successfully');
      // Fluttertoast.showToast(
      //   msg: "Data Updated!",
      //   toastLength: Toast.LENGTH_LONG,
      //   timeInSecForIosWeb: 1,
      // );
      return ProfileResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return ProfileResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode == 401){

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
        return ProfileResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode == 404){
      // return ProfileResponse.fromJson(jsonDecode(response.body));
      final result = jsonDecode(response.body);
      final message = result['message'] ?? "User Not Found...";
      throw ApiException(message);
    }
    else {
      // If the response status is something else, handle it here
      Fluttertoast.showToast(
        msg: "Unexpected Error: " + response.body + "...!",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return ProfileResponse.fromJson(jsonDecode(response.body));
    }
  }

  Future<ApiResponse> updateuuid(String staffcode, String uuid)async{
    try{
      final response = await http.get(
        Uri.parse( Constant.updateuuid+staffcode+"/"+uuid),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        //headers: {'Content-Type': 'application/json'}
      );
      print(response.body);
      print(response.statusCode);
      if(response.statusCode==200)
      {
        return ApiResponse.fromJson(jsonDecode(response.body));
      }
      else if(response.statusCode==400){
        Fluttertoast.showToast(msg: 'No changes were made!!!!.');
      }
      return ApiResponse.fromJson(jsonDecode(response.body));


    }catch (e) {
      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to submit leave details: $e");
    }
  }

  Future<ApiResponse> updateatsflagg(String staffcode, String atsflag )async{
    try{
      print(Constant.updateatsflag+staffcode+"/"+atsflag);
      final response = await http.post(
        Uri.parse( Constant.updateatsflag+staffcode+"/"+atsflag),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        //headers: {'Content-Type': 'application/json'}
      );
      print(response);
      print(response.body);
      print(response.statusCode);
      if(response.statusCode==200)
      {
        return ApiResponse.fromJson(jsonDecode(response.body));
      }
      else if(response.statusCode==400){
        Fluttertoast.showToast(msg: 'No changes were made!!!!.');
      }
      return ApiResponse.fromJson(jsonDecode(response.body));

    }catch (e) {

      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to update flag: $e");
    }
  }

  Future<CancelGatepassResponse> updateuserinfo(ProfileUpdateRequest updateuserinfo, String token)async{
    try{
      print(Constant.updateuserinfo);

      final response = await http.post(
        Uri.parse(Constant.updateuserinfo),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateuserinfo.toJson()), // Serialize the object
      );
      print("Response Body: ${response.body}");
      print("Response Status Code: ${response.statusCode}");

      // Handle the response
      if (response.statusCode == 200) {
        // Parse and return the successful response
        Fluttertoast.showToast(
          msg: " Details Updated Successfully!",
          toastLength: Toast.LENGTH_SHORT,
        );
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Handle client-side error
        Fluttertoast.showToast(
          msg: "Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Error: ${response.body}");
      }
      else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) =>SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));
      }
      else {
        // Handle other unexpected errors
        Fluttertoast.showToast(
          msg: "Unexpected Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Unexpected Error: ${response.body}");
      }
    }
    catch (e) {
      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to submit leave details: $e");
    }

  }


  Future<List<ApprovedSanctionRecords>> approvesanctionlist(String reportingstaffcode, String flag, String token) async {
    print("GetAllUsers : " + Constant.approvesanction);
    print(Constant.approvesanction+reportingstaffcode+"/"+flag);
    final response = await http.get(
      Uri.parse(Constant.approvesanction+reportingstaffcode+"/"+flag),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("GetAllUsers Response Body: " + response.body);
    print("GetAllUsers Status Code: " + response.statusCode.toString());

    if (response.statusCode == 200) {
      // Parse the response as a list of ApprovedSanctionRecords
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ApprovedSanctionRecords.fromJson(json)).toList();
    } else if (response.statusCode == 400) {
      Fluttertoast.showToast(
        msg: "List not available",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return [];
    } else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    return [];
  }

  // Future<void> submitsanctionsapprovals(List<SanctionRequestModel> sanctionmodels, String token) async {
  //   try {
  //     print(Constant.submitapprovesanction);
  //
  //     // Serialize the list to JSON
  //     final response = await http.post(
  //       Uri.parse(Constant.updateuserinfo),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode(sanctionmodels.map((e) => e.toJson()).toList()), // Convert list to JSON
  //     );
  //
  //     print("Response Body: ${response.body}");
  //     print("Response Status Code: ${response.statusCode}");
  //
  //     // Handle the response
  //     if (response.statusCode == 200) {
  //       Fluttertoast.showToast(
  //         msg: "Leave Details Submitted Successfully!",
  //         toastLength: Toast.LENGTH_SHORT,
  //       );
  //     } else if (response.statusCode == 400) {
  //       Fluttertoast.showToast(
  //         msg: "Error: ${response.body}",
  //         toastLength: Toast.LENGTH_LONG,
  //       );
  //       throw Exception("Error: ${response.body}");
  //     } else {
  //       Fluttertoast.showToast(
  //         msg: "Unexpected Error: ${response.body}",
  //         toastLength: Toast.LENGTH_LONG,
  //       );
  //       throw Exception("Unexpected Error: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Exception occurred: $e");
  //     throw Exception("Failed to submit: $e");
  //   }
  // }

  Future<void> submitsanctionsapprovals(List<SanctionRequestModel> sanctionmodels, String token) async {
    try {
      print(Constant.submitapprovesanction);

      String payload = jsonEncode(sanctionmodels.map((e) => e.toJson()).toList());
      print("Final Payload: $payload");

      // Serialize the list to JSON
      final response = await http.post(
        Uri.parse(Constant.submitapprovesanction),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sanctionmodels.map((e) => e.toJson()).toList()), // Convert list to JSON
      );

      print("Response Body: ${response.body}");
      print("Response Status Code: ${response.statusCode}");

      // Handle the response
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Process Completed",
          toastLength: Toast.LENGTH_SHORT,
        );
      } else if (response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: response.body,
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Error:"+response.body);
      } else {
        Fluttertoast.showToast(
          msg: "Unexpected Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Unexpected Error: ${response.body}");
      }
    } catch (e) {
      print("Exception occurred: $e");
      throw Exception("Failed to submit: $e");
    }
  }


//Add New Staff Entry

  Future<CancelGatepassResponse> addStaffEntry(
      AddStaffRequest addStaffRequest, String token) async {
    print("addStaffEntry==========>"+Constant.addStaffEntry
        +"staffCode :"+ addStaffRequest.staffCode.toString()+
        "firstName :"+ addStaffRequest.firstName.toString()+
        "middleName :"+ addStaffRequest.middleName.toString()+
        "lastName :"+ addStaffRequest.lastName.toString()+
        "displayName :"+ addStaffRequest.displayName.toString()+
        "dateOfBirth :"+ addStaffRequest.dateOfBirth.toString()+
        "joiningDate :"+ addStaffRequest.joiningDate.toString()+
        "plantCode :"+ addStaffRequest.plantCode.toString()
       );

    final response = await http.post(
      Uri.parse(Constant.addStaffEntry),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(addStaffRequest),
    );
    print("addStaffEntry response :" +response.body);
    print("addStaffEntry response :" +response.statusCode.toString());

    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  Future<CancelGatepassResponse> deleteStaffEntry(
      String staffCode, String token) async {
    print(
        "deleteStaffEntry==========>"+Constant.deleteStaffEntry+"/"+staffCode

    );

    final response = await http.post(
      Uri.parse(Constant.deleteStaffEntry+"?staffCode="+staffCode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },

    );
    print("deleteStaffEntry response :" +response.body);
    print("deleteStaffEntry response :" +response.statusCode.toString());

    if(response.statusCode==200)
      {
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));

      }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    else if(response.statusCode==404)
      {
        Fluttertoast.showToast(
          msg:  " User Not Found...!",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
        );
      }

    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  //COff Credit

  Future<GetStaffDetailsForCoffResponse> GetStaffDetailsForCoff(String typeCode,String staffCode,String date, String token) async {
    print("GetStaffDetailsForCoff typeCode: $typeCode"+", ");
    String encodedFromDate = Uri.encodeComponent(date);

    print(Constant.GetStaffDetailsForCoff+"/"+typeCode+"/"+staffCode+"/"+encodedFromDate);
    final response = await http.get(
      Uri.parse(Constant.GetStaffDetailsForCoff+"?Type="+typeCode+"&staffCode="+staffCode+"&Date="+encodedFromDate),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("GetStaffDetailsForCoff : " + response.body);
    print("GetStaffDetailsForCoff  status code: " + response.statusCode.toString());

    if (response.statusCode == 200)
    {

      return GetStaffDetailsForCoffResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400)
    {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg:  response.body ,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return GetStaffDetailsForCoffResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return GetStaffDetailsForCoffResponse.fromJson(jsonDecode(response.body));
    }
      return GetStaffDetailsForCoffResponse.fromJson(jsonDecode(response.body));

  }


  //Credit Coff

  Future<CancelGatepassResponse> SubmitCOffEntry(
      CreditCOffEntryRequest creditCOffEntryRequest, String token) async {
    print("creditCOffEntry==========>"+Constant.SubmitCoff);
    print("creditCOffEntry==========>"
        +"otid :"+ creditCOffEntryRequest.otid.toString()
        +"staffCode :"+ creditCOffEntryRequest.type.toString()+
        "name :"+ creditCOffEntryRequest.name.toString()+
        "department :"+ creditCOffEntryRequest.department.toString()+
        "date :"+ creditCOffEntryRequest.date.toString()+
        "designation :"+ creditCOffEntryRequest.designation.toString()+
        "shift :"+ creditCOffEntryRequest.shift.toString()+
        "totalHrs :"+ creditCOffEntryRequest.totalHrs.toString()+
        "balanceHrs :"+ creditCOffEntryRequest.balanceHrs.toString()+
        "reason :"+ creditCOffEntryRequest.reason.toString()+
        "otherChecked :"+ creditCOffEntryRequest.otherChecked.toString()+
        "otherDetails :"+ creditCOffEntryRequest.otherDetails.toString());

    final response = await http.post(
      Uri.parse(Constant.SubmitCoff),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(creditCOffEntryRequest),
    );
    print("SubmitCoff response :" +response.body);
    print("SubmitCoff response :" +response.statusCode.toString());
    if (response.statusCode == 200) {
      try {
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));
      }catch(e)
      {
        print("FetchCoffTransactions  Error catch Block: " + e.toString());


        Fluttertoast.showToast(
          msg: "No records Found...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );

      }
    }
    else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body ,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }


//FetchCoffTransactions


  Future<FetchCoffTransactionsResponse> FetchCoffTransactions(String staffCode , String token) async {
    print("FetchCoffTransactions staffCode: $staffCode");

    print(Constant.FetchCoffTransactions+"/"+staffCode);
    final response = await http.get(
      Uri.parse(Constant.FetchCoffTransactions+"?StaffCode="+staffCode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("FetchCoffTransactions : " + response.body);
    print("FetchCoffTransactions  status code: " + response.statusCode.toString());

  if (response.statusCode == 200) {
    try {
      return FetchCoffTransactionsResponse.fromJson(jsonDecode(response.body));
    }catch(e)
    {
      print("FetchCoffTransactions  Error catch Block: " + e.toString());


      Fluttertoast.showToast(
        msg: "No records Found...!",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );

    }
  }
  else if (response.statusCode == 400) {
    // Handle error if the response status is 400
    Fluttertoast.showToast(
      msg: response.body ,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 1,
    );
    return FetchCoffTransactionsResponse.fromJson(jsonDecode(response.body));
  }
  else if (response.statusCode == 401) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Unauthorized. Kindly Login Again!!'),
        action: SnackBarAction(
          label: 'Login Again',
          onPressed: () {
            isloggedIn= true;
            // Navigate using the global navigator key
            MyApp.navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) =>SplashScreen()),
            );
          },
        ),
        duration: Duration(minutes: 2), // Make it sticky
      ),
    );
    return FetchCoffTransactionsResponse.fromJson(jsonDecode(response.body));
  }
  return FetchCoffTransactionsResponse.fromJson(jsonDecode(response.body));

  }
//CancelCoffOTHWOFF


  Future<CancelGatepassResponse> CancelCoffOTHWOFF(
      String staffCode,String transactionId, String token) async {
    print(
        Constant.CancelCoffOTHWOFF+"?StaffCode="+staffCode+"&transactionId="+transactionId

    );

    final response = await http.post(
      Uri.parse(Constant.CancelCoffOTHWOFF+"?StaffCode="+staffCode+"&transactionId="+transactionId),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },

    );
    print("CancelCoffOTHWOFF response :" +response.body);
    print("CancelCoffOTHWOFF response statusCode :" +response.statusCode.toString());

    if(response.statusCode==200)
    {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    else if(response.statusCode==404)
    {
      Fluttertoast.showToast(
        msg:  " User Not Found...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }

    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  //GetCoffsTransactions
  Future<GetCoffsTransactionsResponse> GetCoffsTransactions(String staffCode , String token) async {
    print("GetCoffsTransactions staffCode: $staffCode");

    print(Constant.GetCoffsTransactions+"/"+staffCode);
    final response = await http.get(
      Uri.parse(Constant.GetCoffsTransactions+"?StaffCode="+staffCode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("GetCoffsTransactions : " + response.body);
    print("GetCoffsTransactions  status code: " + response.statusCode.toString());

    if (response.statusCode == 200) {
      try {
        return GetCoffsTransactionsResponse.fromJson(jsonDecode(response.body));
      }catch(e)
      {
        print("GetCoffsTransactions  Error catch Block: " + e.toString());


        Fluttertoast.showToast(
          msg: "No records Found...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );

      }
    }
    else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body ,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return GetCoffsTransactionsResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return GetCoffsTransactionsResponse.fromJson(jsonDecode(response.body));
    }
    return GetCoffsTransactionsResponse.fromJson(jsonDecode(response.body));

  }

//CancelCoff
  Future<CancelGatepassResponse> CancelCoff(
      String staffCode,String CoffId, String token) async {
    print(
        Constant.CancelCoff+"?StaffCode="+staffCode+"&CoffId="+CoffId

    );

    final response = await http.post(
      Uri.parse(Constant.CancelCoff+"?StaffCode="+staffCode+"&CoffId="+CoffId),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },

    );
    print("CancelCoff response :" +response.body);
    print("CancelCoff response statusCode :" +response.statusCode.toString());

    if(response.statusCode==200)
    {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    else if(response.statusCode==404)
    {
      Fluttertoast.showToast(
        msg:  " User Not Found...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }

    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }
//SubmitCoffDebit
/*
 "coffID": "string",
    "staffCode": "string",
    "staffName": "string",
    "coffDate": "string",
    "department": "string",
    "designation": "string",
    "shift": "string",
    "balance": "string",
    "fromTime": "string",
    "toTime": "string",
    "reason": "string",
    "check": "string",
    "purpose": "string",
    "add": true
*
*/
  Future<CancelGatepassResponse> SubmitCoffDebit(
      SubmitCoffDebitRequest submitCoffDebitRequest, String token) async {
    print("SubmitCoffDebit==========>"+Constant.SubmitCoffDebit
        +"coffID :"+ submitCoffDebitRequest.coffID.toString()
        +"staffCode :"+ submitCoffDebitRequest.staffCode.toString()+
        "name :"+ submitCoffDebitRequest.staffName.toString()+
        "department :"+ submitCoffDebitRequest.department.toString()+
        "date :"+ submitCoffDebitRequest.coffDate.toString()+
        "designation :"+ submitCoffDebitRequest.designation.toString()+
        "shift :"+ submitCoffDebitRequest.shift.toString()+
        "balanceHrs :"+ submitCoffDebitRequest.balance.toString()+
        "fromTime :"+ submitCoffDebitRequest.fromTime.toString()+
        "toTime :"+ submitCoffDebitRequest.toTime.toString()+
        "reason :"+ submitCoffDebitRequest.reason.toString()+
        "check :"+ submitCoffDebitRequest.check.toString()+
        "purpose :"+ submitCoffDebitRequest.purpose.toString()+
        "add :"+ submitCoffDebitRequest.add.toString()
    );

    final response = await http.post(
      Uri.parse(Constant.SubmitCoffDebit),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(submitCoffDebitRequest),
    );
    print("SubmitCoff response :" +response.body);
    print("SubmitCoff response :" +response.statusCode.toString());
    try{
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));

    }
    catch(e){
      print("Submit coff error..."+e.toString());

    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));

  }

//InsertMMRowsData

  Future<CancelGatepassResponse> InsertMMRowsData(
      InsertMMRowDataRequest insertMMRowDataRequest, String token) async {

    //*{
    //   "pointsOrIssues": "string",
    //   "discussedWith": "string",
    //   "decisionTaken": "string",
    //   "responsibility": "string",
    //   "targetDate": "string",
    //   "statusOrRemark": "string",
    //   "nextDate": "string",
    //   "visitSrNo": "string"
    // }*/
    print("addGatePassRequest==========>"+Constant.InsertMMData
        +"pointsOrIssues :"+ insertMMRowDataRequest.pointsOrIssues.toString()+
        "discussedWith :"+ insertMMRowDataRequest.discussedWith.toString()+
        "decisionTaken :"+ insertMMRowDataRequest.decisionTaken.toString()+
        "responsibility :"+ insertMMRowDataRequest.responsibility.toString()+
        "targetDate :"+ insertMMRowDataRequest.targetDate.toString()+
        "statusOrRemark :"+ insertMMRowDataRequest.statusOrRemark.toString()+
        "nextDate :"+ insertMMRowDataRequest.nextDate.toString()+
        "visitSrNo :"+ insertMMRowDataRequest.visitSrNo.toString()
        );

    //String addNewGatePassRequest=addGatePassRequestToJson(addGatePassRequest);
    final response = await http.post(
      Uri.parse(Constant.InsertMMData),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(insertMMRowDataRequest),
    );
    print("InsertMMRowsData response :" +response.body);
    print("InsertMMRowsData response :" +response.statusCode.toString());

    if(response.statusCode==200)
    {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) =>SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));  }

  //InsertMMAllData

  Future<String> InsertMMAllData(
      InsertMMALLDataRequest insertMMALLDataRequest, String token) async {


    print("InsertMMALLData==========>"+Constant.InsertMMALLData
        +"date :"+ insertMMALLDataRequest.date.toString()+
        "time :"+ insertMMALLDataRequest.time.toString()+
        "subject :"+ insertMMALLDataRequest.subject.toString()+
        "memberPresent :"+ insertMMALLDataRequest.memberPresent.toString()+
        "memberAbsent :"+ insertMMALLDataRequest.memberAbsent.toString()+
        "allRecordsIds :"+ insertMMALLDataRequest.allRecordsIds.toString()+
        "visitSrNo :"+ insertMMALLDataRequest.visitSrNo.toString()
    );

    //String addNewGatePassRequest=addGatePassRequestToJson(addGatePassRequest);
    final response = await http.post(
      Uri.parse(Constant.InsertMMALLData),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(insertMMALLDataRequest),
    );
    print("insertMMALLDataRequest response :" +response.body);
    print("insertMMALLDataRequest response :" +response.statusCode.toString());
    try {
      if (response.statusCode == 200) {
        return response.body;
      }
      else if (response.statusCode == 401) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
      }
      return response.body;
    }catch(e)
    {
      print("Exception--->"+e.toString());
    }
    return response.body;

  }
//UpdateMeetingFormNo

  Future<CancelGatepassResponse> UpdateMeetingFormNo(
      int FormNo ,int SrNo , String token) async {
    print(
        Constant.UpdateMeetingFormNo+FormNo.toString()+"/"+SrNo.toString()

    );

    final response = await http.post(
      Uri.parse( Constant.UpdateMeetingFormNo+FormNo.toString()+"/"+SrNo.toString()),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },

    );
    print("UpdateMeetingFormNo response :" +response.body);
    print("UpdateMeetingFormNo response statusCode :" +response.statusCode.toString());

    if(response.statusCode==200)
    {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  //GetMinutesOfMeetingFormNo

  Future<GetMinutesOfMeetingFormNoResponse> GetMinutesOfMeetingFormNo(String UserId ,String SrNo , String token) async {
    print("GetMinutesOfMeetingFormNo UserId: $UserId");
    print("GetMinutesOfMeetingFormNo SrNo: $SrNo");

    print(Constant.GetMinutesOfMeetingFormNo+UserId+"/"+SrNo);
    final response = await http.get(
      Uri.parse(Constant.GetMinutesOfMeetingFormNo+UserId+"/"+SrNo),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("GetMinutesOfMeetingFormNo : " + response.body);
    print("GetMinutesOfMeetingFormNo  status code: " + response.statusCode.toString());

    if (response.statusCode == 200) {
      try {
        return GetMinutesOfMeetingFormNoResponse.fromJson(jsonDecode(response.body));
      }catch(e)
      {
        print("GetMinutesOfMeetingFormNo  Error catch Block: " + e.toString());


        Fluttertoast.showToast(
          msg: "No records Found...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );

      }
    }
    else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return GetMinutesOfMeetingFormNoResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return GetMinutesOfMeetingFormNoResponse.fromJson(jsonDecode(response.body));
    }
    return GetMinutesOfMeetingFormNoResponse.fromJson(jsonDecode(response.body));

  }

//MinutesOfTheMeetingAllDataByVisitSrNo
  Future<GetMinutesOfTheMeetingAllDataByVisitSrNoResponse> GetMinutesOfTheMeetingAllDataByVisitSrNo(String SrNo , String token) async {
    print("GetMinutesOfTheMeetingAllDataByVisitSrNo SrNo: $SrNo");

    print(Constant.GetMinutesOfTheMeetingAllDataByVisitSrNo+SrNo);
    final response = await http.get(
      Uri.parse(Constant.GetMinutesOfTheMeetingAllDataByVisitSrNo+SrNo),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("GetMinutesOfTheMeetingAllDataByVisitSrNo : " + response.body);
    print("GetMinutesOfTheMeetingAllDataByVisitSrNo  status code: " + response.statusCode.toString());

    if (response.statusCode == 200) {
      try {
        return GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));
      }catch(e)
      {
        print("GetMinutesOfTheMeetingAllDataByVisitSrNo  Error catch Block: " + e.toString());


        Fluttertoast.showToast(
          msg: "No records Found...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );

      }
    }
    else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));
    }
    return GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));

  }
  //MinutesOfTheMeetingDataByVisitSrNo

  Future<GetMinutesOfTheMeetingDataByVisitSrNoResponse> GetMinutesOfTheMeetingDataByVisitSrNo(String VisitSrNo  , String token) async {
    print("GetMinutesOfTheMeetingDataByVisitSrNo SrNo: $VisitSrNo ");

    print(Constant.GetMinutesOfTheMeetingDataByVisitSrNo+VisitSrNo );
    final response = await http.get(
      Uri.parse(Constant.GetMinutesOfTheMeetingDataByVisitSrNo+VisitSrNo ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("GetMinutesOfTheMeetingDataByVisitSrNo : " + response.body);
    print("GetMinutesOfTheMeetingDataByVisitSrNo  status code: " + response.statusCode.toString());

    if (response.statusCode == 200) {
      try {
        return GetMinutesOfTheMeetingDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));
      }catch(e)
      {
        print("GetMinutesOfTheMeetingDataByVisitSrNo  Error catch Block: " + e.toString());


        Fluttertoast.showToast(
          msg: "No records Found...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );

      }
    }
    else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return GetMinutesOfTheMeetingDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return GetMinutesOfTheMeetingDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));
    }
    return GetMinutesOfTheMeetingDataByVisitSrNoResponse.fromJson(jsonDecode(response.body));

  }

  //cancellation
  Future<List<CancellationstaffDetails>> fetcancellationdetails(String staffCode, String fromDate, String toDate, String requestType, String token) async {
    final response = await http.post(
      Uri.parse(Constant.fetchcancellationURl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'requestType': requestType,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CancellationstaffDetails.fromJson(item)).toList();
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    else {
      throw Exception('Failed to fetch cancellation details: ${response.statusCode}');
    }
  }
  Future<List<LeaveCancelRequest>> fetchleavecancellationdetails(String staffCode, String fromDate, String toDate, String requestType, String token) async {
    final response = await http.post(
      Uri.parse(Constant.fetchcancellationURl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'requestType': requestType,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => LeaveCancelRequest.fromJson(item)).toList();
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    else {
      throw Exception('Failed to fetch cancellation details: ${response.statusCode}');
    }
  }
  Future<List<GatepassCancelRequest>> fetchgatepasscancellationdetails(String staffCode, String fromDate, String toDate, String requestType, String token) async {
    final response = await http.post(
      Uri.parse(Constant.fetchcancellationURl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'requestType': requestType,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => GatepassCancelRequest.fromJson(item)).toList();
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    else {
      throw Exception('Failed to fetch cancellation details: ${response.statusCode}');
    }
  }
  Future<List<CCreditCancellationRequest>> fetchccoffcancellationdetails(String staffCode, String fromDate, String toDate, String requestType, String token) async {
    final response = await http.post(
      Uri.parse(Constant.fetchcancellationURl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'requestType': requestType,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CCreditCancellationRequest.fromJson(item)).toList();
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    else {
      throw Exception('Failed to fetch cancellation details: ${response.statusCode}');
    }
  }
  Future<List<CDebitCancellationRequest>> fetchcdebitcancellationdetails(String staffCode, String fromDate, String toDate, String requestType, String token) async {
    final response = await http.post(
      Uri.parse(Constant.fetchcancellationURl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'requestType': requestType,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CDebitCancellationRequest.fromJson(item)).toList();
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    else {
      throw Exception('Failed to fetch cancellation details: ${response.statusCode}');
    }
  }
  Future<List<TourCanceelationRequest>> fetchtourcancellationdetails(String staffCode, String fromDate, String toDate, String requestType, String token) async {
    final response = await http.post(
      Uri.parse(Constant.fetchcancellationURl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'requestType': requestType,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => TourCanceelationRequest.fromJson(item)).toList();
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return [];
    }
    else {
      throw Exception('Failed to fetch cancellation details: ${response.statusCode}');
    }
  }
  Future<List<OTCancellationRequest>> submitOT(List<OTCancellationRequest> otsubmitcancellations, String token,) async {
    String url = Constant.submitOTcancellation;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(otsubmitcancellations.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => OTCancellationRequest.fromJson(json))
            .toList();
      }  else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return [];
      }
      else {
        throw Exception(
            'Failed to submit OT Cancellation: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting OT Cancellation: $e');
      rethrow;
    }
  }
  Future<List<LeaveCancellationDetail>> submitLeave(List<LeaveCancellationDetail> leavesubmitcancellations, String token,) async {
    String url = Constant.submitleavecancellationUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(leavesubmitcancellations.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => LeaveCancellationDetail.fromJson(json))
            .toList();
      }  else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return [];
      }
      else {
        throw Exception(
            'Failed to submit OT Cancellation: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting OT Cancellation: $e');
      rethrow;
    }
  }

  Future<CancelGatepassResponse>UpdateMMAllDataa(UpdateMMAllData updateMMAllData, String token)async{
    final response = await http.post(
      Uri.parse( Constant.UpdateMMAllData),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateMMAllData.toJson()),
    );
    print("UpdateMMAllData :" +response.body);
    print("UpdateMMAllData :" +response.statusCode.toString());
    if(response.statusCode==200)
    {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }else if(response.statusCode == 400){
      Fluttertoast.showToast(
        msg:  " Record not updated",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }

    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  //UpdateMMData
  Future<CancelGatepassResponse>UpdateMMDataa(UpdateMMData updateMMData, String token)async{
    final response = await http.post(
      Uri.parse( Constant.UpdateMMData),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateMMData.toJson()),
    );
    print("UpdateMMData :" +response.body);
    print("UpdateMMData :" +response.statusCode.toString());
    if(response.statusCode==200)
    {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }else if(response.statusCode == 400){
      Fluttertoast.showToast(
        msg:  " Record not updated",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    else if(response.statusCode==401)
    {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  Future<List<GatepassCancellationDetail>> submitgatepass(List<GatepassCancellationDetail> gatepasscancellation, String token,) async {
    String url = Constant.submitgatepasscancellationUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(gatepasscancellation.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => GatepassCancellationDetail.fromJson(json))
            .toList();
      }  else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return [];
      }
      else {
        throw Exception(
            'Failed to submit OT Cancellation: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting OT Cancellation: $e');
      rethrow;
    }
  }
  Future<List<Coffcancellation>> submitcoff(List<Coffcancellation> coff, String token,) async {
    String url = Constant.submitcoffcancellationUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(coff.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => Coffcancellation.fromJson(json))
            .toList();
      }  else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return [];
      }
      else {
        throw Exception(
            'Failed to submit OT Cancellation: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting OT Cancellation: $e');
      rethrow;
    }
  }
  Future<List<CDebitcancellation>> submitcdebit(List<CDebitcancellation> cdebit, String token,) async {
    String url = Constant.submitcdebitcancellationUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cdebit.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => CDebitcancellation.fromJson(json))
            .toList();
      }  else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return [];
      }
      else {
        throw Exception(
            'Failed to submit OT Cancellation: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting OT Cancellation: $e');
      rethrow;
    }
  }
  Future<List<TourCancellationDetail>> submittour(List<TourCancellationDetail> tour, String token,) async {
    String url = Constant.submittourcancellationUrl;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tour.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => TourCancellationDetail.fromJson(json))
            .toList();
      }  else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return [];
      }
      else {
        throw Exception(
            'Failed to submit OT Cancellation: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting OT Cancellation: $e');
      rethrow;
    }
  }
  //expense
  Future<CancelGatepassResponse> submitExpenseRecords(ExpenseModel expenseModelList, String token) async {
    String url = Constant.expensesubmit;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(expenseModelList),
      );
      // Log the response
      print("Response Body: ${response.body}");
      print("Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // final List<dynamic> responseData = jsonDecode(response.body);
        Fluttertoast.showToast(msg: "success!!");
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));;
      }
      else if( response.statusCode == 400){
        //Fluttertoast.showToast(msg: "error: $response", toastLength: Toast.LENGTH_SHORT);
        return CancelGatepassResponse.fromJson(jsonDecode(response.body));
      }
      else {
        // print(object)
        throw Exception(
            'Failed to submit expense records: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      // print("error expense: $e");
      // Fluttertoast.showToast(msg: 'Error submitting expense records: $e',
      //     toastLength: Toast.LENGTH_LONG);
      // You can create a default response indicating an error
      return CancelGatepassResponse( // Assuming your model has a success field
        message: 'Error: $e', // Or any message you want to show
      );
    }
  }

  Future<List<ViewExpenseModel>> showExpenseDetails(String staffCode, String token) async {
    print(Constant.viewexpensedetails);
    print("Staff Code ---> $staffCode");

    try {
      final response = await http.get(
        Uri.parse("${Constant.viewexpensedetails}$staffCode"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response Body ----> ${response.body}");
      print("Response Status Code ----> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => ViewExpenseModel.fromJson(item)).toList();
      } else if (response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: "Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );
        throw Exception("Bad Request: ${response.body}");
      } else {
        throw Exception("Failed to fetch expense details. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("An error occurred while fetching expense details: $e");
    }
  }

//tour
  Future<StaffDetails>gettourstaffdetails(String staffcode, String token) async{
    print(Constant.getstafftourdetails);
    print("username--->"+staffcode );

    final response = await http.get(
      Uri.parse(Constant.getstafftourdetails+ staffcode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print("userLogin response---->" + response.body);
    print("userLogin response status code---->" + response.statusCode.toString());

    print(response.body);

    if(response.statusCode==200){
      return StaffDetails.fromJson(jsonDecode(response.body));

    }else if(response.statusCode==400){
      Fluttertoast.showToast(
        msg: "  " +response.body+"...!",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
        // Set the text color
      );
      return StaffDetails.fromJson(jsonDecode(response.body));

    }
    return StaffDetails.fromJson(jsonDecode(response.body));
  }
  Future<SubmitTourDetails>submittourdetails(SubmitTourDetails submittourdetails, String token) async{
    try {
      // Log the URL being used
      print(Constant.submittourdetails);

      // Send the POST request
      final response = await http.post(
        Uri.parse(Constant.submittourdetails),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(submittourdetails.toJson()), // Serialize the object
      );

      // Log the response
      print("Response Body: ${response.body}");
      print("Response Status Code: ${response.statusCode}");

      // Handle the response
      if (response.statusCode == 200) {
        // Parse and return the successful response
        Fluttertoast.showToast(
          msg: "Tour Details Submitted Successfully!",
          toastLength: Toast.LENGTH_SHORT,
        );
        return SubmitTourDetails.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Handle client-side error
        // Fluttertoast.showToast(
        //   msg:  response.body,
        //   toastLength: Toast.LENGTH_LONG,
        // );
        throw Exception("Error: ${response.body}");
      }
      else if(response.statusCode == 401){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        return  SubmitTourDetails.fromJson(jsonDecode(response.body));
      }
      else {
        // Handle other unexpected errors
        Fluttertoast.showToast(
          msg: "Unexpected Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Unexpected Error: ${response.body}");
      }
    } catch (e) {
      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to submit leave details: $e");
    }
  }
  Future<TourDetailsResponse>appliedtourlist(String Staffcode, String token) async{
    print(Constant.getAppliedTour);
    print("username--->" + Staffcode);
    print("token--->" + token);

    // Add query parameters to the URL
    final Uri url = Uri.parse(Constant.getAppliedTour + Staffcode)
        .replace(queryParameters: {
      'StaffCode': Staffcode,
      'ApprovedFlag': token,
    });

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    print("Response status code: " + response.statusCode.toString());
    print("Response body: " + response.body);

    if (response.statusCode == 200) {
      return TourDetailsResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      Fluttertoast.showToast(
        msg: "  " + response.body + "...!",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return TourDetailsResponse.fromJson(jsonDecode(response.body));
    }
    else if(response.statusCode == 401){
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    return TourDetailsResponse.fromJson(jsonDecode(response.body));
  }
/*
  Future<String> canceltour(String staffcode, String slipId, String token) async {
    // Construct the full URL with query parameters
    final url = Uri.parse('${Constant.canceltour}?staffCode=$staffcode&slipId=$slipId');

    try {
      // Perform the HTTP GET request with the authorization token
      // final response = await http.get(
      //   url,
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );

      final response = await http.post(
        Uri.parse(
            Constant.canceltour + "staffcode" + staffcode + "&slipId" + slipId),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },

      );
print(response.statusCode);
print(response.body);
print(response.headers);
print(staffcode + slipId);
      // Check the response status
      if (response.statusCode == 200) {
        // Parse the response body and return the message
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] ?? 'Tour canceled successfully';
      } else {
        // Return error message for non-200 responses
        return 'Failed to cancel tour: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      // Handle any errors during the request
      return 'Error: $e';
    }
  }
*/

  Future<String> canceltour(String staffcode, String slipId, String token) async {
    // ✅ Build the correct URL with proper query parameters
    print(Constant.canceltour);
    final url = Uri.parse('${Constant.canceltour}staffCode=$staffcode&slipId=$slipId');
print(url);
    try {
      final response = await http.post(
        url, // ✅ This is now correct
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: '', // ✅ Must be empty body as per Swagger
      );

      print(response.statusCode);
      print(response.body);
      print("Called with staffcode: $staffcode and slipId: $slipId");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] ?? 'Tour canceled successfully';
      } else {
        return 'Failed to cancel tour: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<RemoteLocationResponse> remotelocationrequest(RemoteLocationResponse remotelocation, String token) async {
    try {
      // Log the URL being used
      print("Request URL: ${Constant.remotelocationrequest}");

      // Serialize the object to JSON
      final requestBody = jsonEncode(remotelocation.toJson());
      print("Request Body: $requestBody");

      // Send the POST request
      final response = await http.post(
        Uri.parse(Constant.remotelocationrequest),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: requestBody, // Serialized object
      );

      // Log the response
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      // Handle the response
      if (response.statusCode == 200) {
        // Parse and return the successful response
        Fluttertoast.showToast(
          msg: "Location request submitted successfully!",
          toastLength: Toast.LENGTH_SHORT,
        );
        Fluttertoast.showToast(
          msg: "You’ll be able to mark your attendance once it’s approved.",
          toastLength: Toast.LENGTH_SHORT,
        );
        return RemoteLocationResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        // Handle client-side error
        Fluttertoast.showToast(
          msg: "Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Client-side Error: ${response.body}");
      } else if (response.statusCode == 401) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Unauthorized. Kindly Login Again!!'),
            action: SnackBarAction(
              label: 'Login Again',
              onPressed: () {
                isloggedIn= true;
                // Navigate using the global navigator key
                MyApp.navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
            ),
            duration: Duration(minutes: 2), // Make it sticky
          ),
        );
        throw Exception("Unauthorized: ${response.body}");
      } else {
        // Handle other unexpected errors
        Fluttertoast.showToast(
          msg: "Unexpected Error: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
        );
        throw Exception("Unexpected Error: ${response.body}");
      }
    } catch (e) {
      // Log and rethrow the exception
      print("Exception occurred: $e");
      throw Exception("Failed to submit remote location: $e");
    }
  }

  Future<CancelGatepassResponse> acceptremotelocation(String staffcode, String approvedflag, String token) async {
    print("deleteStaffEntry==========>" + Constant.acceptremotelocation + "/" + approvedflag + "/" + staffcode);

    final response = await http.post(
      Uri.parse(
          Constant.acceptremotelocation + "/" + approvedflag + "/" + staffcode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },

    );
    print("deleteStaffEntry response :" + response.body);
    print("deleteStaffEntry response :" + response.statusCode.toString());

    if (response.statusCode == 200) {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    else if (response.statusCode == 404) {
      Fluttertoast.showToast(
        msg: " User Not Found...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  Future<CancelGatepassResponse> showremotelocation(String staffcode,String token) async{
    final url = Uri.parse(Constant.showremotelocation +"/" + staffcode);

    // Perform the HTTP GET request with the authorization token
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("FetchCoffTransactions : " + response.body);
    print("FetchCoffTransactions  status code: " +
        response.statusCode.toString());

    if (response.statusCode == 200) {
      try {
        return CancelGatepassResponse.fromJson(
            jsonDecode(response.body));
      } catch (e) {
        print("FetchCoffTransactions  Error catch Block: " + e.toString());


        Fluttertoast.showToast(
          msg: "No records Found...!",
          toastLength: Toast.LENGTH_LONG,
          timeInSecForIosWeb: 1,
        );
      }
    }
    else if (response.statusCode == 400) {
      // Handle error if the response status is 400
      Fluttertoast.showToast(
        msg: response.body,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 1,
      );
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

  Future<CancelGatepassResponse> nondistancecheck(String staffcode, String approvedflag, String token) async {
    print("nondistancecheck==========>" + Constant.nondistancecheckrequest + "/" + approvedflag + "/" + staffcode);

    final response = await http.post(
      Uri.parse(
          Constant.nondistancecheckrequest + "/" + approvedflag + "/" + staffcode),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },

    );
    print("nondistancecheck response :" + response.body);
    print("nondistancecheck responseCode :" + response.statusCode.toString());

    if (response.statusCode == 200) {
      return CancelGatepassResponse.fromJson(jsonDecode(response.body));
    }
    else if (response.statusCode == 401) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Unauthorized. Kindly Login Again!!'),
          action: SnackBarAction(
            label: 'Login Again',
            onPressed: () {
              isloggedIn= true;
              // Navigate using the global navigator key
              MyApp.navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          duration: Duration(minutes: 2), // Make it sticky
        ),
      );
    }
    else if (response.statusCode == 404) {
      Fluttertoast.showToast(
        msg: " User Not Found...!",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
      );
    }
    return CancelGatepassResponse.fromJson(jsonDecode(response.body));
  }

}





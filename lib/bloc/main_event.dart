import 'package:attendance_system_ios/model/CoffCredit/CreditCOffEntryRequest.dart';
import 'package:attendance_system_ios/model/CoffDebit/SubmitCoffDebitRequest.dart';
import 'package:attendance_system_ios/model/GatePass/AddGatepassRequest.dart';
import 'package:attendance_system_ios/model/GatePass/CancelGatePass.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMALLDataRequest.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/InsertMMRowDataRequest.dart';
import 'package:attendance_system_ios/model/SanctionModel/Sanctionn.dart';
import 'package:attendance_system_ios/model/UsersList/AddStaffRequest.dart';

import '../model/CancellationRequestData/SUbmitOtCancellation.dart';
import '../model/CancellationRequestData/SubmilLeaveCancellation.dart';
import '../model/CancellationRequestData/SubmitCDebitCancellation.dart';
import '../model/CancellationRequestData/SubmitCoffCancellation.dart';
import '../model/CancellationRequestData/SubmitGatepassCancellation.dart';
import '../model/CancellationRequestData/SubmitTourCancellation.dart';
import '../model/Expense/Submitexpenserecords.dart';
import '../model/Leave/CancelLeave.dart';
import '../model/Leave/SubmitLeaveResponse.dart';
import '../model/MinutesOfTheMettingForm/UpdateMMAllData.dart';
import '../model/MinutesOfTheMettingForm/UpdateMMData.dart';
import '../model/Profile/UpdateUserinfo.dart';
import '../model/RemoteLocation/RemoteLocation.dart';
import '../model/Tour/Submittourdetails.dart';

class MainEvent {}
class LoginEvents extends MainEvent {
  String username;
  String password;
  LoginEvents({required this.username, required this.password});
}

class GetStaffDetailsEvents extends MainEvent {
  String StaffCode;
  String token;

  GetStaffDetailsEvents({required this.StaffCode,required this.token});
}

class RequestDataDeletionEvents extends MainEvent{
 String StaffCode;
 String token;

 RequestDataDeletionEvents({required this.StaffCode, required this.token});
}

class GetPendingGatePassEvents extends MainEvent {
  String StaffCode;
  String token;

  GetPendingGatePassEvents({required this.StaffCode,required this.token});
}
class AddGatePassEvents extends MainEvent {
  AddGatepassRequest addGatepassRequest;
  String token;

  AddGatePassEvents({required this.addGatepassRequest,required this.token});
}

class CancelGatePassEvents extends MainEvent {
  CancelGatepassRequest cancelGatepassRequest;
  String token;

  CancelGatePassEvents({required this.cancelGatepassRequest,required this.token});
}
//Add Staff

class AddStaffEntryEvents extends MainEvent {
  AddStaffRequest addStaffRequest;
  String token;

  AddStaffEntryEvents({required this.addStaffRequest,required this.token});
}

//Delete Staff Entry

class DeleteStaffEntryEvents extends MainEvent {
  String staffCode ;
  String token;

  DeleteStaffEntryEvents({required this.staffCode,required this.token});
}
//GetStaffDetailsForCoff
class GetStaffDetailsForCoffEvents extends MainEvent {
  String type;
  String staffCode ;
  String date;
  String token;

  GetStaffDetailsForCoffEvents({required this.type,required this.staffCode,required this.date,required this.token});
}

//Submit Coff
class SubmitCoffEvents extends MainEvent {

  CreditCOffEntryRequest creditCOffEntryRequest;

  String token;

  SubmitCoffEvents({required this.creditCOffEntryRequest,required this.token});
}
//FetchCoffTransactionsEvents
class FetchCoffTransactionsEvents extends MainEvent {

  String satffCode;

  String token;

  FetchCoffTransactionsEvents({required this.satffCode,required this.token});
}
//CancelCoffOTHWOFFEvents
class CancelCoffOTHWOFFEvents extends MainEvent {

  String staffCode;
  String transactionId;

  String token;

  CancelCoffOTHWOFFEvents({required this.staffCode,required this.transactionId,required this.token});
}
//GetCoffsTransactionsEvents

class GetCoffsTransactionsEvents extends MainEvent {

  String staffCode;

  String token;

  GetCoffsTransactionsEvents({required this.staffCode,required this.token});
}
//CancelCoffEvents
class CancelCoffEvents extends MainEvent {

  String staffCode;

  String CoffId;

  String token;

  CancelCoffEvents({required this.staffCode,required this.CoffId,required this.token});
}

//SubmitCoffDebitEvents

class SubmitCoffDebitEvents extends MainEvent {

  SubmitCoffDebitRequest submitCoffDebitRequest;

  String token;

  SubmitCoffDebitEvents({required this.submitCoffDebitRequest,required this.token});
}
//
class InsertMMRowsDataEvents extends MainEvent {

  InsertMMRowDataRequest insertMMRowDataRequest;

  String token;

  InsertMMRowsDataEvents({required this.insertMMRowDataRequest,required this.token});
}
//InsertMMAllData
class InsertMMAllDataEvents extends MainEvent {

  InsertMMALLDataRequest insertMMALLDataRequest;

  String token;

  InsertMMAllDataEvents({required this.insertMMALLDataRequest,required this.token});
}
//UpdateMeetingFormNoEvents
class UpdateMeetingFormNoEvents extends MainEvent {

 int FormNo;
 int SrNo;

  String token;

 UpdateMeetingFormNoEvents({required this.FormNo,required this.SrNo,required this.token});
}
//GetMinutesOfMeetingFormNoEvents
class GetMinutesOfMeetingFormNoEvents extends MainEvent {

  String UserId;
  String SrNo;

  String token;

  GetMinutesOfMeetingFormNoEvents({required this.UserId,required this.SrNo,required this.token});
}
//GetMinutesOfTheMeetingAllDataByVisitSrNoEvents
class GetMinutesOfTheMeetingAllDataByVisitSrNoEvents extends MainEvent {

  String SrNo;

  String token;

  GetMinutesOfTheMeetingAllDataByVisitSrNoEvents({required this.SrNo,required this.token});
}

//GetMinutesOfTheMeetingDataByVisitSrNoEvents
class GetMinutesOfTheMeetingDataByVisitSrNoEvents extends MainEvent {

  String VisitSrNo ;

  String token;

  GetMinutesOfTheMeetingDataByVisitSrNoEvents({required this.VisitSrNo ,required this.token});
}
//Visit History

class VisitHistoryEvents extends MainEvent {
String userId;
int pagenumber;
int pageSize;
String token;

  VisitHistoryEvents({required this.userId,required this.pagenumber,required this.pageSize,required this.token});
}
//VisitlatLongList
class VisitlatLongListEvents extends MainEvent {
  String StaffCode;
  String ActualDate;
  String SrNoVal;
  String token;

  VisitlatLongListEvents({required this.StaffCode,required this.ActualDate,
    required this.SrNoVal,
    required this.token});
}

//GetAllUsersData
class GetAllUsersListEvent extends MainEvent {
  String pagenumber;
  String pagesize;
  String token;

  GetAllUsersListEvent({required this.pagenumber, required this.pagesize, required this.token});

}
class SearchbyStaffcodeEvents extends MainEvent{
  String staffcode;
  String token;
  SearchbyStaffcodeEvents({required this.staffcode, required this.token});
}

//GetVisitListbetweenFromdateAndToDate
class GetVisitByFromDateToDate extends MainEvent {

  String UserId ;
  int pageNumber;
  int pageSize;
  String fromDate;
  String toDate;
  String token;

  GetVisitByFromDateToDate({
    required this.UserId,
    required  this.pageNumber,
    required  this.pageSize,
      required  this.fromDate,
    required this.toDate,
    required this.token});

}

//GetVisitDetailedRecords

class GetVisitDetailedRecordsEvent extends MainEvent {

  String StaffCode ;
  String FromDate ;
  String ToDate ;
  String SrNoVal ;
  String token;

  GetVisitDetailedRecordsEvent({
    required this.StaffCode,
    required  this.FromDate,
    required  this.ToDate,
    required  this.SrNoVal,
    required this.token});

}
class GetLeaveStaffDetails extends MainEvent{
String StaffCode;
String token;

GetLeaveStaffDetails({required this.StaffCode, required this.token});
}
class GetPendingLeaveEvents extends MainEvent{
  String StaffCode;
  String token;
  String ApprovedFlag;

  GetPendingLeaveEvents({required this.StaffCode, required this.token, required this.ApprovedFlag});
}

class GetLeavetypeEvents extends MainEvent{
  String StaffCode;
  String token;
  String Year;
  GetLeavetypeEvents({required this.StaffCode, required this.token, required this.Year});
}

class SubmitLeaveEvents extends MainEvent{
  SubmitLeaveDetails submitleavedetails;
  String token;

  SubmitLeaveEvents({required this.submitleavedetails, required this  .token});
}

class CancelLeaveEvents extends MainEvent{
  CancelLeaveBody cancelleavebody;
  String token;

  CancelLeaveEvents({required this.cancelleavebody, required this.token});

}

class GetUserInfoEvents extends MainEvent{
  String token;
  String Staffcode;

  GetUserInfoEvents({required this.Staffcode, required this.token});
}

class UpdateProfileDetailsEvents extends MainEvent{
  ProfileUpdateRequest updateuserinfo;
  String token;
  UpdateProfileDetailsEvents({required this.updateuserinfo, required this.token});

}


class AllApproveSanctionEvents extends MainEvent{
  String token;
  String ReportingLevelStaffCode;
  String Flag;

  AllApproveSanctionEvents({required this.ReportingLevelStaffCode, required this.Flag, required this.token});

}

class SubmitSactionEvents extends MainEvent {
  final List<SanctionRequestModel> sanctionmodels; // Change type to List
  final String token;
  SubmitSactionEvents({required this.sanctionmodels, required this.token});
}

class FetchCancellationDetails extends MainEvent {
  final String staffCode;
  final String fromDate;
  final String toDate;
  final String requestType;
  final String token;

  FetchCancellationDetails({
    required this.staffCode,
    required this.fromDate,
    required this.toDate,
    required this.requestType,
    required this.token,
  });
}

class SubmitOTcancelRequest extends MainEvent{
  final List<OTCancellationRequest> otcancellationsubmit;
  String token;
  SubmitOTcancelRequest({required this.otcancellationsubmit, required this.token});

}

class SubmitLeaveCancellationRequest extends MainEvent{
  final List<LeaveCancellationDetail> leavecancellationsubmit;
  String token;
  SubmitLeaveCancellationRequest({required this.leavecancellationsubmit, required this.token});
}

class SubmitGatepassCancellationrequest extends MainEvent{
  final List<GatepassCancellationDetail> gatepasscancellationsubmit;
  String token;
  SubmitGatepassCancellationrequest({required this.gatepasscancellationsubmit, required this.token});
}

class SubmitCoffCancellationrequest extends MainEvent{
  final List<Coffcancellation> coffcancellationsubmit;
  String token;
  SubmitCoffCancellationrequest({required this.coffcancellationsubmit, required this.token});
}

class SubmitCdebitCancellationrequest extends MainEvent{
  final List<CDebitcancellation> cdebitcancellationsubmit;
  String token;
  SubmitCdebitCancellationrequest({required this.cdebitcancellationsubmit, required this.token});
}

class SubmitTourCancellationrequest extends MainEvent{
  final List<TourCancellationDetail> tourcancellationsubmit;
  String token;
  SubmitTourCancellationrequest({required this.tourcancellationsubmit, required this.token});
}

class SubmitExpensedata extends MainEvent{
  ExpenseModel expensemodell;
  String token;
  SubmitExpensedata({required this.expensemodell, required this.token});
}

class Fetchstafftourdetails extends MainEvent{
  String Staffcode;
  String token;
  Fetchstafftourdetails({required this.Staffcode, required this.token});

}
class Submittourdetailsevent extends MainEvent{
  SubmitTourDetails submittour;
  String token;
  Submittourdetailsevent({required this.submittour, required this.token});
}

class FetchappliedTourevent extends MainEvent{
  String Staffcode;
  String token;
  FetchappliedTourevent({required this.Staffcode, required this.token});
}

class CancelTourevents extends MainEvent{
  String staffCode;
  String slipId;
  String token;

  CancelTourevents({required this.staffCode, required this.slipId, required this.token});
}

class ShowexpenseAdmin extends MainEvent{
  String staffcode;
  String token;
  ShowexpenseAdmin({required this.staffcode, required this.token});
}
class Remotelocation extends MainEvent{
  RemoteLocationResponse remotelocation;
  String token;
  Remotelocation({required this.remotelocation, required this.token});
}
class AcceptlocationRequest extends MainEvent{
  String staffcode;
  String approvedflag;
  String token;
  AcceptlocationRequest({required this.staffcode, required this.approvedflag, required this.token});
}
class Showremotelocation extends MainEvent{
  String staffcode;
  String token;
  Showremotelocation({required this.staffcode, required this.token});
}
class NonDistancecheckRequest extends MainEvent{
  String staffcode;
  String approvedflag;
  String token;
  NonDistancecheckRequest({required this.staffcode, required this.approvedflag, required this.token});
}
class UpdateUUID extends MainEvent{
  String UserId;
  String UUID;
  UpdateUUID({required this.UserId,required this.UUID});

}

class UpdateUserFlagATS extends MainEvent{
  String UserId;
  String AtsFlag;
  UpdateUserFlagATS({required this.UserId, required this.AtsFlag});
}

class UpdateMMALLDataEvents extends MainEvent{
  UpdateMMAllData updateMMAllData;
  String token;
  UpdateMMALLDataEvents({required this.updateMMAllData,required this.token});
}

//update minutesofmeeting tabledata
class UpdateMMDataEvents extends MainEvent{
  UpdateMMData updateMMData;
  String token;
  UpdateMMDataEvents({required this.updateMMData,required this.token});
}
import 'package:attendance_system_ios/model/CoffCredit/FetchCoffTransactionsResponse.dart';
import 'package:attendance_system_ios/model/CoffCredit/GetStaffDetailsForCoffResponse.dart';
import 'package:attendance_system_ios/model/CoffDebit/GetCoffsTransactionsResponse.dart';
import 'package:attendance_system_ios/model/GatePass/CancelgatepassResponse.dart';
import 'package:attendance_system_ios/model/GatePass/GatePassResponse.dart';
import 'package:attendance_system_ios/model/GatePass/StaffDetailsResponse.dart';
// import 'package:attendance_system_ios/modelResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfMeetingFormNoResponse.dart';
import 'package:attendance_system_ios/model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingDataByVisitSrNoResponse.dart';
import 'package:attendance_system_ios/model/UsersList/GetAllusersListResponse.dart';
import 'package:attendance_system_ios/model/VisitHistory/VisitDataResponse.dart';
import 'package:attendance_system_ios/model/VisitHistory/VisitLatLongListResponse.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitDetailedRecordsResponse.dart';
import 'package:attendance_system_ios/model/VisitReport/VisitRecordsResponse.dart';
import 'package:equatable/equatable.dart';

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
import '../model/Expense/ViewexpenseAdmin.dart';
import '../model/Leave/CancelLeave.dart';
import '../model/Leave/LeavePendingResponse.dart';
import '../model/Leave/LeaveTypeDetails.dart';
import '../model/Leave/Staffdetails.dart';
import '../model/Leave/SubmitLeaveResponse.dart';
import '../model/Login/LoginResponse.dart';
import '../model/MinutesOfTheMettingForm/CustomerList.dart';
import '../model/MinutesOfTheMettingForm/GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.dart';
import '../model/Profile/ProfileResponse.dart';
import '../model/RemoteLocation/RemoteLocation.dart';
import '../model/SanctionModel/SanctionApprove.dart';
import '../model/SanctionModel/Sanctionn.dart';
import '../model/Tour/AppliedTour.dart';
import '../model/Tour/Getstaffdetails.dart';
import '../model/Tour/Submittourdetails.dart';
import '../model/UsersList/SearchbystaffcodeResponse.dart';
import '../model/UsersList/UpdateUUID.dart';

class MainState extends Equatable{
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }

  @override
  
  List<Object?> get props => throw UnimplementedError();
}

class MainInitialState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class LoginLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class LoginLoadedState extends MainState {
  final LoginResponse? loginResponse;

  LoginLoadedState({required this.loginResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class LoginErrorState extends MainState {
  final String msg;

  LoginErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetStaffDetailsLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetStaffDetailsLoadedState extends MainState {
  final StaffDetailsResponse? staffDetailsResponse;

  GetStaffDetailsLoadedState({required this.staffDetailsResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetStaffDetailsErrorState extends MainState {
  final String msg;

  GetStaffDetailsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class RequestDataDeletionLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class RequestDataDeletionLoadedState extends MainState {
  final bool result;

  RequestDataDeletionLoadedState({required this.result});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class RequestDataDeletionErrorState extends MainState {
  final String msg;

  RequestDataDeletionErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetPendingGatePassLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetPendingGatePassLoadedState extends MainState {
  final GatePassResponse? gatePassResponse;

  GetPendingGatePassLoadedState({required this.gatePassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetPendingGatePassErrorState extends MainState {
  final String msg;

  GetPendingGatePassErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Add GatePass
class AddGatePassLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class AddGatePassLoadedState extends MainState {
  final CancelGatepassResponse? cancelGatepassResponse;

  AddGatePassLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class AddGatePassErrorState extends MainState {
  final String msg;

  AddGatePassErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Cancel GatePass
class CancelGatePassLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class CancelGatePassLoadedState extends MainState {
 final CancelGatepassResponse? cancelGatePassResponse;

  CancelGatePassLoadedState({required this.cancelGatePassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class CancelGatePassErrorState extends MainState {
  final String msg;

  CancelGatePassErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//Add Staff

//Add GatePass
class AddStaffEntryLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class AddStaffEntryLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  AddStaffEntryLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class AddStaffEntryErrorState extends MainState {
  final String msg;

  AddStaffEntryErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Delete Staff Entry

class DeleteStaffEntryLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class DeleteStaffEntryLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  DeleteStaffEntryLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class DeleteStaffEntryErrorState extends MainState {
  final String msg;

  DeleteStaffEntryErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//GetStaffDetailsForCoff

class GetStaffDetailsForCoffLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetStaffDetailsForCoffLoadedState extends MainState {
  final GetStaffDetailsForCoffResponse getStaffDetailsForCoffResponse;

  GetStaffDetailsForCoffLoadedState(
      {required this.getStaffDetailsForCoffResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetStaffDetailsForCoffErrorState extends MainState {
  final String msg;

  GetStaffDetailsForCoffErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//SubmitCoff

class SubmitCoffEventsLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffEventsLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  SubmitCoffEventsLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffEventsErrorState extends MainState {
  final String msg;

  SubmitCoffEventsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//FetchCoffTransactionsLoadingState

class FetchCoffTransactionsLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class FetchCoffTransactionsLoadedState extends MainState {
  final FetchCoffTransactionsResponse fetchCoffTransactionsResponse;

  FetchCoffTransactionsLoadedState(
      {required this.fetchCoffTransactionsResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class FetchCoffTransactionsErrorState extends MainState {
  final String msg;

  FetchCoffTransactionsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Cancel Coff

class CancelCoffOTHWOFFLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class CancelCoffOTHWOFFLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  CancelCoffOTHWOFFLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class CancelCoffOTHWOFFErrorState extends MainState {
  final String msg;

  CancelCoffOTHWOFFErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//GetCoffsTransactions

class GetCoffsTransactionsLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetCoffsTransactionsLoadedState extends MainState {
  final GetCoffsTransactionsResponse getCoffsTransactionsResponse;

  GetCoffsTransactionsLoadedState({required this.getCoffsTransactionsResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetCoffsTransactionsErrorState extends MainState {
  final String msg;

  GetCoffsTransactionsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//CancelCoffLoadingState

class CancelCoffLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class CancelCoffLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  CancelCoffLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class CancelCoffErrorState extends MainState {
  final String msg;

  CancelCoffErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//SubmitCoffDebitLoadingState

class SubmitCoffDebitLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffDebitLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  SubmitCoffDebitLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffDebitErrorState extends MainState {
  final String msg;

  SubmitCoffDebitErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//InsertMMRowsData

class InsertMMRowsDataLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class InsertMMRowsDataLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  InsertMMRowsDataLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class InsertMMRowsDataErrorState extends MainState {
  final String msg;

  InsertMMRowsDataErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//InsertMMAllData

class InsertMMAllDataLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class InsertMMAllDataLoadedState extends MainState {
  final String cancelGatepassResponse;

  InsertMMAllDataLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class InsertMMAllDataErrorState extends MainState {
  final String msg;

  InsertMMAllDataErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//UpdateMeetingFormNoLoadingState
class UpdateMeetingFormNoLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class UpdateMeetingFormNoLoadedState extends MainState {
  final CancelGatepassResponse cancelGatepassResponse;

  UpdateMeetingFormNoLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class UpdateMeetingFormNoErrorState extends MainState {
  final String msg;

  UpdateMeetingFormNoErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//GetMinutesOfMeetingFormNoLoadingState

class GetMinutesOfMeetingFormNoLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetMinutesOfMeetingFormNoLoadedState extends MainState {
  final GetMinutesOfMeetingFormNoResponse getMinutesOfMeetingFormNoResponse;

  GetMinutesOfMeetingFormNoLoadedState(
      {required this.getMinutesOfMeetingFormNoResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetMinutesOfMeetingFormNoErrorState extends MainState {
  final String msg;

  GetMinutesOfMeetingFormNoErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//GetMinutesOfTheMeetingAllDataByVisitSrNoLoadingState
class GetMinutesOfTheMeetingAllDataByVisitSrNoLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState extends MainState {
  final GetMinutesOfTheMeetingAllDataByVisitSrNoResponse
      getMinutesOfTheMeetingAllDataByVisitSrNoResponse;

  GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState(
      {required this.getMinutesOfTheMeetingAllDataByVisitSrNoResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetMinutesOfTheMeetingAllDataByVisitSrNoErrorState extends MainState {
  final String msg;

  GetMinutesOfTheMeetingAllDataByVisitSrNoErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//GetMinutesOfTheMeetingDataByVisitSrNoLoadingState

class GetMinutesOfTheMeetingDataByVisitSrNoLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetMinutesOfTheMeetingDataByVisitSrNoLoadedState extends MainState {
  final GetMinutesOfTheMeetingDataByVisitSrNoResponse
      getMinutesOfTheMeetingDataByVisitSrNoResponse;

  GetMinutesOfTheMeetingDataByVisitSrNoLoadedState(
      {required this.getMinutesOfTheMeetingDataByVisitSrNoResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetMinutesOfTheMeetingDataByVisitSrNoErrorState extends MainState {
  final String msg;

  GetMinutesOfTheMeetingDataByVisitSrNoErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Visit History

class VisitHistoryLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class VisitHistoryLoadedState extends MainState {
  final VisitDataResponse? visitDataResponse;

  VisitHistoryLoadedState({required this.visitDataResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class VisitHistoryErrorState extends MainState {
  final String msg;

  VisitHistoryErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Visit History

class VisitlatLongListLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class VisitlatLongListLoadedState extends MainState {
  final VisitLatLongListResponse? visitLatLongListResponse;

  VisitlatLongListLoadedState({required this.visitLatLongListResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class VisitlatLongListErrorState extends MainState {
  final String msg;

  VisitlatLongListErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//GetVisitByFromDateToDateLoadingState

class GetVisitByFromDateToDateLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetVisitByFromDateToDateLoadedState extends MainState {
  final VisitRecordsResponse? visitRecordsResponse;

  GetVisitByFromDateToDateLoadedState({required this.visitRecordsResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetVisitByFromDateToDateErrorState extends MainState {
  final String msg;

  GetVisitByFromDateToDateErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}
//GetVisitDetailedRecordsLoadingState

class GetVisitDetailedRecordsLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetVisitDetailedRecordsLoadedState extends MainState {
  final VisitDetailedRecordsResponse? visitDetailedRecordsResponse;

  GetVisitDetailedRecordsLoadedState(
      {required this.visitDetailedRecordsResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetVisitDetailedRecordsErrorState extends MainState {
  String msg;

  GetVisitDetailedRecordsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetLeaveStaffDetailsLoadingtstate extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetLeaveStaffDetailsLoadedtstate extends MainState {
  final Staffdetails staffdetails;

  GetLeaveStaffDetailsLoadedtstate({required this.staffdetails});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetLeaveStaffDetailsErrorState extends MainState {
  final String msg;

  GetLeaveStaffDetailsErrorState({required this.msg});
}

class GetPendingLeaveLoadingStatae extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetPendingLeaveLoadedState extends MainState {
  final LeavePendingResponse leavependingresponse;

  GetPendingLeaveLoadedState({required this.leavependingresponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetPendingLeaveErrorState extends MainState {
  final String msg;

  GetPendingLeaveErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetLeaveTypeLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetLeaveTypeLoadedState extends MainState {
  final LeaveDetails leavedetails;

  GetLeaveTypeLoadedState({required this.leavedetails});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetLeaveTypeErrorState extends MainState {
  final String msg;

  GetLeaveTypeErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetSubmitLeaveLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetSubmitLeaveLoadedState extends MainState {
  final SubmitLeaveDetails submitLeaveDetails;

  GetSubmitLeaveLoadedState({required this.submitLeaveDetails});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetSubmitLeaveErrorState extends MainState {
  final String msg;

  GetSubmitLeaveErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetCancelLeaveLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetCancelLeaveLoadedState extends MainState {
  final CancelLeaveBody cancelleavebodyy;

  GetCancelLeaveLoadedState({required this.cancelleavebodyy});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetCancelLeaveErrorState extends MainState {
  final String msg;

  GetCancelLeaveErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetUserinfoLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetUserinfoLoadedState extends MainState {
  final ProfileResponse profileuserinfo;

  GetUserinfoLoadedState({required this.profileuserinfo});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetUserinfoErrorState extends MainState {
  final String msg;

  GetUserinfoErrorState({required this.msg});

  @override
  List<Object> get props => [msg];
}

class UpdateUserinfoLoadingState extends MainState {
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class UpdateUserinfoLoadedState extends MainState {
  final CancelGatepassResponse updateuserinfo;

  UpdateUserinfoLoadedState({required this.updateuserinfo});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class UpdateUserinfoErrorState extends MainState {
  final String msg;

  UpdateUserinfoErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class ApproveSanctionLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class ApproveSanctionLoadedState extends MainState {
  final List<ApprovedSanctionRecords> approvedsanctionrecords;

  ApproveSanctionLoadedState({required this.approvedsanctionrecords});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class ApproveSanctionErrorState extends MainState {
  final String msg;

  ApproveSanctionErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitApprovesanctionLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitApprovesanctionLoadedState extends MainState {
  final List<SanctionRequestModel>?
      sanctionrequestmodels; // Optional list for response
  SubmitApprovesanctionLoadedState({this.sanctionrequestmodels});

  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitApproveSanctionErrorState extends MainState {
  final String msg;

  SubmitApproveSanctionErrorState({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

//OTCancellation
class FetchCancellationDetailsLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchCancellationDetailsLoadedState extends MainState {
  final List<CancellationstaffDetails>? cancellationRequest;

  FetchCancellationDetailsLoadedState({required this.cancellationRequest});

  @override
  List<Object> get props => throw UnimplementedError();
}

class FetCancellationDetailsErrorState extends MainState {
  final String msg;

  FetCancellationDetailsErrorState({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

class submitOTLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class submitOTLoadedState extends MainState {
  final List<OTCancellationRequest> otcancellationsubmit;

  submitOTLoadedState({required this.otcancellationsubmit});

  @override
  List<Object> get props => throw UnimplementedError();
}

class submitOTErrorState extends MainState {
  final String msg;

  submitOTErrorState({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

//LeaveCancellation
class FetchLeaveCancellationLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchLeaveCancellationLoadedState extends MainState {
  final List<LeaveCancelRequest>? cancelleaverequest;

  FetchLeaveCancellationLoadedState({required this.cancelleaverequest});

  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchLeaveCancellationErrorState extends MainState {
  final String msg;

  FetchLeaveCancellationErrorState({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitLeaveCancellationLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitLeaveCancellationLoadedState extends MainState {
  final List<LeaveCancellationDetail> leavecancellationsubmit;

  SubmitLeaveCancellationLoadedState({required this.leavecancellationsubmit});

  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitLeaveCancellationErrorState extends MainState {
  final String msg;

  SubmitLeaveCancellationErrorState({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

//GatePassCancellation
class FetchGatepassCancellationLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchGatepassCancellationLoadedState extends MainState {
  final List<GatepassCancelRequest>? cancelgatepassrequest;

  FetchGatepassCancellationLoadedState({required this.cancelgatepassrequest});

  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchGatePassCancellationErrorstate extends MainState {
  final String msg;
  FetchGatePassCancellationErrorstate({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitgatepassCancellationLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitgatepassCancellationLoadedState extends MainState {
  final List<GatepassCancellationDetail> gatepasscancellationsubmit;

  SubmitgatepassCancellationLoadedState({required this.gatepasscancellationsubmit});

  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitGatepassCancellationErrorState extends MainState {
  final String msg;

  SubmitGatepassCancellationErrorState({required this.msg});
  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Coff
class FetchCoffCancellationLoadingState extends MainState {
  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchCoffCancellationLoadedState extends MainState {
  final List<CCreditCancellationRequest>? cancelcoffrequest;

  FetchCoffCancellationLoadedState({required this.cancelcoffrequest});

  @override
  List<Object> get props => throw UnimplementedError();
}

class FetchCoffCancellationErrorState extends MainState {
  final String msg;

  FetchCoffCancellationErrorState({required this.msg});

  @override
  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffCancellationLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffCancellationLoadedState extends MainState {
  final List<Coffcancellation> coffcancellationsubmit;

  SubmitCoffCancellationLoadedState({required this.coffcancellationsubmit});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitCoffCancellationerrorState extends MainState {
  String msg;

  SubmitCoffCancellationerrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//CDebit
class FetchCDebitCancellationLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class FetchCDebitCancellationLoadedState extends MainState {
  final List<CDebitCancellationRequest>? cancelcdebitrequest;

  FetchCDebitCancellationLoadedState({required this.cancelcdebitrequest});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class FetchCDebitCancellationErrorState extends MainState {
  String msg;

  FetchCDebitCancellationErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitCdebitCancellationLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitCdebitCancellationLoadedState extends MainState {
  final List<CDebitcancellation> cdebitcancellationsubmit;

  SubmitCdebitCancellationLoadedState({required this.cdebitcancellationsubmit});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitCdebitCancellationErrorState extends MainState {
  String msg;

  SubmitCdebitCancellationErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//Tour
class FetchTourLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class FetchTourLoadedState extends MainState {
  final List<TourCanceelationRequest>? canceltourrequest;

  FetchTourLoadedState({required this.canceltourrequest});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class FetchTourErrorState extends MainState {
  String msg;

  FetchTourErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitTourCancellationLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitTourCancellationLoadedState extends MainState {
  final List<TourCancellationDetail> tourcancellationsubmit;

  SubmitTourCancellationLoadedState({required this.tourcancellationsubmit});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitTourCancellationErrorState extends MainState {
  String msg;

  SubmitTourCancellationErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitexpenseLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitexpenseLoadedState extends MainState {
  CancelGatepassResponse cancelGatepassResponse;

  SubmitexpenseLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitexpenseErrorstate extends MainState {
  String msg;

  SubmitexpenseErrorstate({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetTourstaffdetailLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetTourstaffdetailsLoadedState extends MainState {
  StaffDetails staffdetails;

  GetTourstaffdetailsLoadedState({required this.staffdetails});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetTourstaffdetailsErrorState extends MainState {
  String msg;

  GetTourstaffdetailsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmittourdetailsLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class SubmitTourdetailsLoadedState extends MainState {
  SubmitTourDetails toursubmission;

  SubmitTourdetailsLoadedState({required this.toursubmission});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class SubmitTourdetailsErrorState extends MainState {
  String msg;

  SubmitTourdetailsErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class FetchappliedTourLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class FetchappliedTourLoadedState extends MainState {
  TourDetailsResponse appliedtourdetails;

  FetchappliedTourLoadedState({required this.appliedtourdetails});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class FetchappliedTourErrorstate extends MainState {
  String msg;

  FetchappliedTourErrorstate({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class CancelappliedtourLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class CancelappliedtourLoadedState extends MainState {
  String canceltour;

  CancelappliedtourLoadedState({required this.canceltour});
}

class CancelappliedtourErrorState extends MainState {
  String msg;

  CancelappliedtourErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class showexpensedetailsadminLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class showexpensedetailsadminLoadedState extends MainState {
  final List<ViewExpenseModel> expenses;

  showexpensedetailsadminLoadedState({required this.expenses});
}

class showexpensedetailsadminErrorState extends MainState {
  String msg;

  showexpensedetailsadminErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class remotelocationLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class remotelocationLoadedState extends MainState {
  RemoteLocationResponse remotelocationresponse;

  remotelocationLoadedState({required this.remotelocationresponse});

  // SubmitTourDetails toursubmission;
  // SubmitTourdetailsLoadedState({required this.toursubmission});
  @override
  
  List<Object> get props => throw UnimplementedError();
}

class remotelocationErrorState extends MainState {
  String msg;

  remotelocationErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class acceptrequestLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class acceptrequestLoadedState extends MainState {
  CancelGatepassResponse cancelGatepassResponse;

  acceptrequestLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class acceptrequestErrorState extends MainState {
  String msg;

  acceptrequestErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class showremotelocationLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class showremotelocationLoadedState extends MainState {
  CancelGatepassResponse cancelGatepassResponse;

  showremotelocationLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class showremotelocationErrorState extends MainState {
  String msg;

  showremotelocationErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class nondistancecheckLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class nondistancecheckLoadedState extends MainState {
  CancelGatepassResponse cancelGatepassResponse;

  nondistancecheckLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class nondistancecheckErrorState extends MainState {
  String msg;

  nondistancecheckErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class updateUUIDLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class updateUUIDLoadedState extends MainState {
  ApiResponse apiresponsee;

  updateUUIDLoadedState({required this.apiresponsee});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class updateUUIDErrorState extends MainState {
  String msg;

  updateUUIDErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class updateUserAtsFlagLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class updateUserAtsFlagLoadedState extends MainState {
  ApiResponse apiresponsee;

  updateUserAtsFlagLoadedState({required this.apiresponsee});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class updateUserAtsFlagErrorState extends MainState {
  String msg;

  updateUserAtsFlagErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class UpdateMMALlDataLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class UpdateMMAllDataLoadedState extends MainState {
  CancelGatepassResponse cancelGatepassResponse;

  UpdateMMAllDataLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class UpdateMMAllDataErrorState extends MainState {
  String msg;

  UpdateMMAllDataErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

//ipdate minutesofmeeting tablerecods
class UpdateMMDataLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class UpdateMMDataLoadedState extends MainState {
  // UpdateMMData updateMMData;
  // UpdateMMDataLoadedState({required this.updateMMData});
  CancelGatepassResponse cancelGatepassResponse;

  UpdateMMDataLoadedState({required this.cancelGatepassResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class UpdateMMDataErrorState extends MainState {
  String msg;

  UpdateMMDataErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

///searchbystaffcode
class SearchbyStaffcodeLoadingPage extends MainState {
  @override
  List<Object?> get props => [];
}

class SearchbyStaffcodeLoadedPage extends MainState {
  UserResponse? userResponse;

  SearchbyStaffcodeLoadedPage({required this.userResponse});

  @override
  List<Object?> get props => [userResponse];
}

class SearchbyStaffcodeErrorPage extends MainState {
  final String message;

  SearchbyStaffcodeErrorPage({required this.message});

  @override
  List<Object?> get props => [message];
}

///GETAllUsers

class GetAllUsersListLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetAllUsersListLoadedState extends MainState {
  GetAllusersListResponse? getAllusersListResponse;

  GetAllUsersListLoadedState({required this.getAllusersListResponse});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetAllUsersListErrorState extends MainState {
  String msg;

  GetAllUsersListErrorState({required this.msg});

  @override
  
  List<Object> get props => throw UnimplementedError();
}

class GetAllClientLoadingState extends MainState {
  @override

  List<Object> get props => throw UnimplementedError();
}

class GetAllClientLoadedState extends MainState {
  final CustomerResponse response;

  GetAllClientLoadedState({required this.response});
}

class GetAllClientErrorState extends MainState {
  final String error;

  GetAllClientErrorState({required this.error});
}

class AddMultiRemoteLocationLoadingState extends MainState {
  @override
  List <Object> get props => [];
}

class AddMultiRemoteLocationLoadedState extends MainState {
  var response;
  AddMultiRemoteLocationLoadedState( {this.response});
  @override
  List<Object> get props => [response];
}

class AddMultiRemoteLocationErrorState extends MainState {
  String msg;
  AddMultiRemoteLocationErrorState({required this.msg});
  @override
  List<Object> get props => [msg];
}

class GetMultiRemoteLocationLoadingState extends MainState {
  @override
  List<Object?> get  props => [];
}

class GetMultiRemoteLocationLoadedState extends MainState {
  final response;
  GetMultiRemoteLocationLoadedState(this.response);
  @override
  List<Object?> get props => [response];
}

class GetMultiRemoteLocationErrorState extends MainState {
  String msg;
  GetMultiRemoteLocationErrorState({required this.msg});
  @override
  List<Object?> get props => [msg];
}

class DeleteMultiRemoteLocationLoadingState extends MainState {
  @override
  List<Object> get props => [];
}
class DeleteMultiRemoteLocationLoadedState extends MainState {
  final response;
  DeleteMultiRemoteLocationLoadedState(this.response);
  @override
  List<Object> get props => [response];
}
class DeleteMultiRemoteLocationErrorState extends MainState {
  String msg;
  DeleteMultiRemoteLocationErrorState({required this.msg});
  @override
  List<Object?> get props => [msg];
}

class UpdateMultiRemoteLocationLoadingState extends MainState {
  @override
  List<Object> get props => [];
}
class UpdateMultiRemoteLocationLoadedState extends MainState {
  final response;
  UpdateMultiRemoteLocationLoadedState(this.response);
  @override
  List<Object> get props => [response];
}
class UpdateMultiRemoteLocationErrorState extends MainState {
  String msg;
  UpdateMultiRemoteLocationErrorState({required this.msg});
  @override
  List<Object?> get props => [msg];
}

import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/Expense/ViewexpenseAdmin.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/CancellationRequestData/CCreditCancellationRequest.dart';
import '../model/CancellationRequestData/CDebitCancellationRequest.dart';
import '../model/CancellationRequestData/CancellationRequestResponse.dart';
import '../model/CancellationRequestData/GatepassCancellationRequest.dart';
import '../model/CancellationRequestData/LeaveCancellationRequest.dart';
import '../model/CancellationRequestData/SubmilLeaveCancellation.dart';
import '../model/CancellationRequestData/SubmitCDebitCancellation.dart';
import '../model/CancellationRequestData/SubmitCoffCancellation.dart';
import '../model/CancellationRequestData/SubmitGatepassCancellation.dart';
import '../model/CancellationRequestData/SubmitTourCancellation.dart';
import '../model/CancellationRequestData/TourCancellationRequest.dart';
import '../model/SanctionModel/SanctionApprove.dart';
import '../util/customExceptions.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  WebService webService;

  var changepassword_Response;

  MainBloc({required this.webService}) : super(MainInitialState());

  //get changepassword_Response => null;

  @override
  Stream<MainState> mapEventToState(MainEvent event) async* {
    {
      if (event is LoginEvents) {
        try {
          yield LoginLoadingState();
          var loginresponse =
              await webService.userLogin(event.username, event.password);
          yield LoginLoadedState(loginResponse: loginresponse);
        } catch (e) {
          //print(e.toString());
          yield LoginErrorState(msg: e.toString());
        }
      } else if (event is GetStaffDetailsEvents) {
        try {
          yield GetStaffDetailsLoadingState();
          var staffdetailsresponse =
              await webService.getStaffDetails(event.StaffCode, event.token);
          yield GetStaffDetailsLoadedState(
              staffDetailsResponse: staffdetailsresponse);
        } catch (e) {
          //print(e.toString());
          yield GetStaffDetailsErrorState(msg: e.toString());
        }
      } else if (event is RequestDataDeletionEvents) {
        try {
          yield RequestDataDeletionLoadingState();
          var requestDataDeletionResponse = await webService
              .requestDataDeletion(event.token, event.StaffCode);
          yield RequestDataDeletionLoadedState(
              result: requestDataDeletionResponse);
        } catch (e) {
          yield RequestDataDeletionErrorState(msg: e.toString());
        }
      } else if (event is GetPendingGatePassEvents) {
        try {
          yield GetPendingGatePassLoadingState();
          var gatePassResponse =
              await webService.getPendingGatepass(event.StaffCode, event.token);
          yield GetPendingGatePassLoadedState(
              gatePassResponse: gatePassResponse);
        } catch (e) {
          //print(e.toString());
          yield GetPendingGatePassErrorState(msg: e.toString());
        }
      } else if (event is AddGatePassEvents) {
        try {
          yield AddGatePassLoadingState();
          var cancelGatepassResponse = await webService.addGatePass(
              event.addGatepassRequest, event.token);
          yield AddGatePassLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield AddGatePassErrorState(msg: e.toString());
        }
      } else if (event is CancelGatePassEvents) {
        try {
          yield CancelGatePassLoadingState();
          var cancelGatePassResponse = await webService.cancelGatePass(
              event.cancelGatepassRequest, event.token);
          yield CancelGatePassLoadedState(
              cancelGatePassResponse: cancelGatePassResponse);
        } catch (e) {
          //print(e.toString());
          yield CancelGatePassErrorState(msg: e.toString());
        }
      }
      //Add Staff
      else if (event is AddStaffEntryEvents) {
        try {
          yield AddStaffEntryLoadingState();
          var addStaffRequest = await webService.addStaffEntry(
              event.addStaffRequest, event.token);
          yield AddStaffEntryLoadedState(
              cancelGatepassResponse: addStaffRequest);
        } catch (e) {
          //print(e.toString());
          yield AddStaffEntryErrorState(msg: e.toString());
        }
      }
      //delete Staffentry

      else if (event is DeleteStaffEntryEvents) {
        try {
          yield DeleteStaffEntryLoadingState();
          var deleteStaffRequest =
              await webService.deleteStaffEntry(event.staffCode, event.token);
          yield DeleteStaffEntryLoadedState(
              cancelGatepassResponse: deleteStaffRequest);
        } catch (e) {
          //print(e.toString());
          yield DeleteStaffEntryErrorState(msg: e.toString());
        }
      }
//GetStaffDetailsForCoff
      else if (event is GetStaffDetailsForCoffEvents) {
        try {
          yield GetStaffDetailsForCoffLoadingState();
          var getStaffDetailsForCoffResponse =
              await webService.GetStaffDetailsForCoff(
                  event.type, event.staffCode, event.date, event.token);
          yield GetStaffDetailsForCoffLoadedState(
              getStaffDetailsForCoffResponse: getStaffDetailsForCoffResponse);
        } catch (e) {
          //print(e.toString());
          yield DeleteStaffEntryErrorState(msg: e.toString());
        }
      }
//Submit Coff

      else if (event is SubmitCoffEvents) {
        try {
          yield SubmitCoffEventsLoadingState();
          var getStaffDetailsForCoffResponse = await webService.SubmitCOffEntry(
              event.creditCOffEntryRequest, event.token);
          yield SubmitCoffEventsLoadedState(
              cancelGatepassResponse: getStaffDetailsForCoffResponse);
        } catch (e) {
          //print(e.toString());
          yield SubmitCoffEventsErrorState(msg: e.toString());
        }
      }
//FetchCoffTransactions
      else if (event is FetchCoffTransactionsEvents) {
        try {
          yield FetchCoffTransactionsLoadingState();
          var fetchCoffTransactionsResponse =
              await webService.FetchCoffTransactions(
                  event.satffCode, event.token);
          yield FetchCoffTransactionsLoadedState(
              fetchCoffTransactionsResponse: fetchCoffTransactionsResponse);
        } catch (e) {
          //print(e.toString());
          yield FetchCoffTransactionsErrorState(msg: e.toString());
        }
      }
//CancelCoff
      else if (event is CancelCoffOTHWOFFEvents) {
        try {
          yield CancelCoffOTHWOFFLoadingState();
          var cancelGatepassResponse = await webService.CancelCoffOTHWOFF(
              event.staffCode, event.transactionId, event.token);
          yield CancelCoffOTHWOFFLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield CancelCoffOTHWOFFErrorState(msg: e.toString());
        }
      }
//GetCoffsTransactions

      else if (event is GetCoffsTransactionsEvents) {
        try {
          yield GetCoffsTransactionsLoadingState();
          var getCoffsTransactionsResponse =
              await webService.GetCoffsTransactions(
                  event.staffCode, event.token);
          yield GetCoffsTransactionsLoadedState(
              getCoffsTransactionsResponse: getCoffsTransactionsResponse);
        } catch (e) {
          //print(e.toString());
          yield GetCoffsTransactionsErrorState(msg: e.toString());
        }
      }

//CancelCoff
      else if (event is CancelCoffEvents) {
        try {
          yield CancelCoffLoadingState();
          var cancelGatepassResponse = await webService.CancelCoff(
              event.staffCode, event.CoffId, event.token);
          yield CancelCoffLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield CancelCoffErrorState(msg: e.toString());
        }
      }

      //SubmitCoffDebit
      else if (event is SubmitCoffDebitEvents) {
        try {
          yield SubmitCoffDebitLoadingState();
          var cancelGatepassResponse = await webService.SubmitCoffDebit(
              event.submitCoffDebitRequest, event.token);
          yield SubmitCoffDebitLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield SubmitCoffDebitErrorState(msg: e.toString());
        }
      }
      //InsertMMRowsData
      else if (event is InsertMMRowsDataEvents) {
        try {
          yield InsertMMRowsDataLoadingState();
          var cancelGatepassResponse = await webService.InsertMMRowsData(
              event.insertMMRowDataRequest, event.token);
          yield SubmitCoffDebitLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield InsertMMRowsDataErrorState(msg: e.toString());
        }
      }
//InsertMMAllData
      else if (event is InsertMMAllDataEvents) {
        try {
          yield InsertMMAllDataLoadingState();
          String cancelGatepassResponse = await webService.InsertMMAllData(
              event.insertMMALLDataRequest, event.token);
          yield InsertMMAllDataLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield InsertMMAllDataErrorState(msg: e.toString());
        }
      }
      //UpdateMeetingFormNo
      else if (event is UpdateMeetingFormNoEvents) {
        try {
          yield UpdateMeetingFormNoLoadingState();
          var cancelGatepassResponse = await webService.UpdateMeetingFormNo(
              event.FormNo, event.SrNo, event.token);
          yield UpdateMeetingFormNoLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          //print(e.toString());
          yield UpdateMeetingFormNoErrorState(msg: e.toString());
        }
      }
      //GetMinutesOfMeetingFormNo
      else if (event is GetMinutesOfMeetingFormNoEvents) {
        try {
          yield GetMinutesOfMeetingFormNoLoadingState();
          var getMinutesOfMeetingFormNoResponse =
              await webService.GetMinutesOfMeetingFormNo(
                  event.UserId, event.SrNo, event.token);
          yield GetMinutesOfMeetingFormNoLoadedState(
              getMinutesOfMeetingFormNoResponse:
                  getMinutesOfMeetingFormNoResponse);
        } catch (e) {
          //print(e.toString());
          yield GetMinutesOfMeetingFormNoErrorState(msg: e.toString());
        }
      }
      //GetMinutesOfTheMeetingAllDataByVisitSrNo
      else if (event is GetMinutesOfTheMeetingAllDataByVisitSrNoEvents) {
        try {
          yield GetMinutesOfTheMeetingAllDataByVisitSrNoLoadingState();
          var getMinutesOfTheMeetingAllDataByVisitSrNoResponse =
              await webService.GetMinutesOfTheMeetingAllDataByVisitSrNo(
                  event.SrNo, event.token);
          yield GetMinutesOfTheMeetingAllDataByVisitSrNoLoadedState(
              getMinutesOfTheMeetingAllDataByVisitSrNoResponse:
                  getMinutesOfTheMeetingAllDataByVisitSrNoResponse);
        } catch (e) {
          //print(e.toString());
          yield GetMinutesOfTheMeetingAllDataByVisitSrNoErrorState(
              msg: e.toString());
        }
      }
      //GetMinutesOfTheMeetingDataByVisitSrNo

      else if (event is GetMinutesOfTheMeetingDataByVisitSrNoEvents) {
        try {
          yield GetMinutesOfTheMeetingDataByVisitSrNoLoadingState();
          var getMinutesOfTheMeetingDataByVisitSrNoResponse =
              await webService.GetMinutesOfTheMeetingDataByVisitSrNo(
                  event.VisitSrNo, event.token);
          yield GetMinutesOfTheMeetingDataByVisitSrNoLoadedState(
              getMinutesOfTheMeetingDataByVisitSrNoResponse:
                  getMinutesOfTheMeetingDataByVisitSrNoResponse);
        } catch (e) {
          //print(e.toString());
          yield GetMinutesOfTheMeetingDataByVisitSrNoErrorState(
              msg: e.toString());
        }
      } else if (event is VisitHistoryEvents) {
        try {
          yield VisitHistoryLoadingState();
          var visitDataResponse = await webService.GetAllVisits(
              event.userId, event.pagenumber, event.pageSize, event.token);
          yield VisitHistoryLoadedState(visitDataResponse: visitDataResponse);
        } catch (e) {
          //print(e.toString());
          yield VisitHistoryErrorState(msg: e.toString());
        }
      }
      //VisitlatLongListEvents
      else if (event is VisitlatLongListEvents) {
        try {
          yield VisitlatLongListLoadingState();
          var visitLatLongListResponse = await webService.GetVisiLatLongList(
              event.StaffCode, event.ActualDate, event.SrNoVal, event.token);
          yield VisitlatLongListLoadedState(
              visitLatLongListResponse: visitLatLongListResponse);
        } catch (e) {
          //print(e.toString());
          yield VisitlatLongListErrorState(msg: e.toString());
        }
      }
      //GetVisitByFromDateToDate
      else if (event is GetVisitByFromDateToDate) {
        try {
          yield GetVisitByFromDateToDateLoadingState();
          var visitRecordsResponse = await webService.GetVisitByFromDateToDate(
              event.UserId,
              event.pageNumber,
              event.pageSize,
              event.fromDate,
              event.toDate,
              event.token);
          yield GetVisitByFromDateToDateLoadedState(
              visitRecordsResponse: visitRecordsResponse);
        } catch (e) {
          //print(e.toString());
          yield GetVisitByFromDateToDateErrorState(msg: e.toString());
        }
      }

      //GetVisitDetailedRecords
      else if (event is GetVisitDetailedRecordsEvent) {
        try {
          yield GetVisitDetailedRecordsLoadingState();
          var visitDetailedRecordsResponse = await webService.GetVisitRecords(
              event.StaffCode,
              event.FromDate,
              event.ToDate,
              event.SrNoVal,
              event.token);
          yield GetVisitDetailedRecordsLoadedState(
              visitDetailedRecordsResponse: visitDetailedRecordsResponse);
        } catch (e) {
          //print(e.toString());
          yield GetVisitDetailedRecordsErrorState(msg: e.toString());
        }
      } else if (event is GetLeaveStaffDetails) {
        try {
          yield GetLeaveStaffDetailsLoadingtstate();
          var staffdetails = await webService.getleavestaffdetails(
              event.StaffCode, event.token);
          yield GetLeaveStaffDetailsLoadedtstate(staffdetails: staffdetails);
        } catch (e) {
          //print(e.toString());
          yield GetLeaveStaffDetailsErrorState(msg: e.toString());
        }
      } else if (event is GetPendingLeaveEvents) {
        try {
          yield GetPendingLeaveLoadingStatae();
          var pendingdetails = await webService.getpendingleave(
              event.StaffCode, event.token, event.ApprovedFlag);
          yield GetPendingLeaveLoadedState(
              leavependingresponse: pendingdetails);
        } catch (e) {
          yield GetPendingLeaveErrorState(msg: e.toString());
        }
      } else if (event is GetLeavetypeEvents) {
        try {
          yield GetLeaveTypeLoadingState();
          var leavetypedetails = await webService.getleavetypelist(
              event.StaffCode, event.token, event.Year);
          yield GetLeaveTypeLoadedState(leavedetails: leavetypedetails);
        } catch (e) {
          yield GetLeaveTypeErrorState(msg: e.toString());
        }
      } else if (event is SubmitLeaveEvents) {
        try {
          yield GetSubmitLeaveLoadingState();
          var submitleaves = await webService.submitLeaveDetails(
              event.submitleavedetails, event.token);
          yield GetSubmitLeaveLoadedState(submitLeaveDetails: submitleaves);
        } catch (e) {
          yield GetSubmitLeaveErrorState(msg: e.toString());
        }
      } else if (event is CancelLeaveEvents) {
        try {
          yield GetCancelLeaveLoadingState();
          var cancelleave =
              await webService.cancelleave(event.cancelleavebody, event.token);
          yield GetCancelLeaveLoadedState(cancelleavebodyy: cancelleave);
        } catch (e) {
          yield GetCancelLeaveErrorState(msg: e.toString());
        }
      } else if (event is GetUserInfoEvents) {
        try {
          yield GetUserinfoLoadingState();
          var userinfo =
              await webService.userinfo(event.Staffcode, event.token);
          yield GetUserinfoLoadedState(profileuserinfo: userinfo);
        } on ApiException catch (e) {
          emit(GetUserinfoErrorState(msg: e.message));
        } catch (e) {
          yield GetUserinfoErrorState(msg: e.toString());
        }
      } else if (event is UpdateProfileDetailsEvents) {
        try {
          yield UpdateUserinfoLoadingState();
          var updateuserinfo = await webService.updateuserinfo(
              event.updateuserinfo, event.token);
          yield UpdateUserinfoLoadedState(updateuserinfo: updateuserinfo);
        } catch (e) {
          yield UpdateUserinfoErrorState(msg: e.toString());
        }
      }

      if (event is AllApproveSanctionEvents) {
        try {
          yield (ApproveSanctionLoadingState());
          print("ReportingLevelStaffCode: ${event.ReportingLevelStaffCode}");
          print("Flag: ${event.Flag.trim()}");
          print("Token: ${event.token}");
          List<ApprovedSanctionRecords> records =
              await webService.approvesanctionlist(
            event.ReportingLevelStaffCode,
            event.Flag.trim(), // Trim to ensure proper matching
            event.token,
          );
          yield (ApproveSanctionLoadedState(approvedsanctionrecords: records));
        } catch (e) {
          yield (ApproveSanctionErrorState(msg: e.toString()));
        }
      }

      if (event is SubmitSactionEvents) {
        try {
          yield SubmitApprovesanctionLoadingState();
          await webService.submitsanctionsapprovals(
              event.sanctionmodels, event.token); // Pass the list
          yield SubmitApprovesanctionLoadedState();
        } catch (e) {
          yield SubmitApproveSanctionErrorState(msg: e.toString());
        }
      }

      //OT
      else if (event is FetchCancellationDetails) {
        yield FetchCancellationDetailsLoadingState();
        try {
          final List<CancellationstaffDetails> cancellationRequestt =
              await webService.fetcancellationdetails(
            event.staffCode,
            event.fromDate,
            event.toDate,
            event.requestType,
            event.token,
          );

          yield FetchCancellationDetailsLoadedState(
              cancellationRequest: cancellationRequestt);
        } catch (e) {
          yield FetCancellationDetailsErrorState(msg: e.toString());
        }
      } else if (event is SubmitOTcancelRequest) {
        try {
          yield submitOTLoadingState();
          var submitOT = await webService.submitOT(
              event.otcancellationsubmit, event.token);
          yield submitOTLoadedState(otcancellationsubmit: submitOT);
        } catch (e) {
          yield submitOTErrorState(msg: e.toString());
        }
      }

      //Leave
      else if (event is FetchCancellationDetails) {
        yield FetchLeaveCancellationLoadingState();
        try {
          final List<LeaveCancelRequest> cancellationleaveRequestt =
              await webService.fetchleavecancellationdetails(
            event.staffCode,
            event.fromDate,
            event.toDate,
            event.requestType,
            event.token,
          );
          yield FetchLeaveCancellationLoadedState(
              cancelleaverequest: cancellationleaveRequestt);
        } catch (e) {
          yield FetCancellationDetailsErrorState(msg: e.toString());
        }
      } else if (event is SubmitLeaveCancellationRequest) {
        try {
          yield SubmitLeaveCancellationLoadingState();
          final List<LeaveCancellationDetail> leavecancellation =
              await webService.submitLeave(
                  event.leavecancellationsubmit, event.token);
          yield SubmitLeaveCancellationLoadedState(
              leavecancellationsubmit: leavecancellation);
        } catch (e) {
          yield SubmitLeaveCancellationErrorState(msg: e.toString());
        }
      }

      //Gatepass
      else if (event is FetchCancellationDetails) {
        yield FetchGatepassCancellationLoadingState();
        try {
          final List<GatepassCancelRequest> cancellationleaveRequestt =
              await webService.fetchgatepasscancellationdetails(
            event.staffCode,
            event.fromDate,
            event.toDate,
            event.requestType,
            event.token,
          );
          yield FetchGatepassCancellationLoadedState(
              cancelgatepassrequest: cancellationleaveRequestt);
        } catch (e) {
          yield FetCancellationDetailsErrorState(msg: e.toString());
        }
      } else if (event is SubmitGatepassCancellationrequest) {
        try {
          yield SubmitgatepassCancellationLoadingState();
          final List<GatepassCancellationDetail> gatepasscancellation =
              await webService.submitgatepass(
                  event.gatepasscancellationsubmit, event.token);
          yield SubmitgatepassCancellationLoadedState(
              gatepasscancellationsubmit: gatepasscancellation);
        } catch (e) {
          yield SubmitGatepassCancellationErrorState(msg: e.toString());
        }
      }

      //Coff
      else if (event is FetchCancellationDetails) {
        try {
          yield FetchCoffCancellationLoadingState();
          final List<CCreditCancellationRequest> coffcancellation =
              await webService.fetchccoffcancellationdetails(
            event.staffCode,
            event.fromDate,
            event.toDate,
            event.requestType,
            event.token,
          );
          yield FetchCoffCancellationLoadedState(
              cancelcoffrequest: coffcancellation);
        } catch (e) {
          yield FetchCoffCancellationErrorState(msg: e.toString());
        }
      } else if (event is SubmitCoffCancellationrequest) {
        try {
          yield SubmitCoffCancellationLoadingState();
          final List<Coffcancellation> coffcancellation = await webService
              .submitcoff(event.coffcancellationsubmit, event.token);
          yield SubmitCoffCancellationLoadedState(
              coffcancellationsubmit: coffcancellation);
        } catch (e) {
          yield SubmitCoffCancellationerrorState(msg: e.toString());
        }
      }
      //Cdebit
      else if (event is FetchCancellationDetails) {
        try {
          yield FetchCDebitCancellationLoadingState();
          final List<CDebitCancellationRequest> cdebitcancellation =
              await webService.fetchcdebitcancellationdetails(
            event.staffCode,
            event.fromDate,
            event.toDate,
            event.requestType,
            event.token,
          );
          yield FetchCDebitCancellationLoadedState(
              cancelcdebitrequest: cdebitcancellation);
        } catch (e) {
          yield FetchCDebitCancellationErrorState(msg: e.toString());
        }
      } else if (event is SubmitCdebitCancellationrequest) {
        try {
          yield SubmitCdebitCancellationLoadingState();
          final List<CDebitcancellation> cdebitcancell = await webService
              .submitcdebit(event.cdebitcancellationsubmit, event.token);
          yield SubmitCdebitCancellationLoadedState(
              cdebitcancellationsubmit: cdebitcancell);
        } catch (e) {
          yield SubmitCdebitCancellationErrorState(msg: e.toString());
        }
      }
      //Tour
      else if (event is FetchCancellationDetails) {
        try {
          yield FetchTourLoadingState();
          final List<TourCanceelationRequest> tourcancellation =
              await webService.fetchtourcancellationdetails(
            event.staffCode,
            event.fromDate,
            event.toDate,
            event.requestType,
            event.token,
          );
          yield FetchTourLoadedState(canceltourrequest: tourcancellation);
        } catch (e) {
          yield FetchTourErrorState(msg: e.toString());
        }
      } else if (event is SubmitTourCancellationrequest) {
        try {
          yield SubmitTourCancellationLoadingState();
          final List<TourCancellationDetail> tourcancellation = await webService
              .submittour(event.tourcancellationsubmit, event.token);
          yield SubmitTourCancellationLoadedState(
              tourcancellationsubmit: tourcancellation);
        } catch (e) {
          yield SubmitTourCancellationErrorState(msg: e.toString());
        }
      } else if (event is SubmitExpensedata) {
        try {
          yield SubmitexpenseLoadingState();
          var expensedetails = await webService.submitExpenseRecords(
              event.expensemodell, event.token);
          yield SubmitexpenseLoadedState(
              cancelGatepassResponse: expensedetails);
        } catch (e) {
          yield SubmitexpenseErrorstate(msg: e.toString());
        }
      } else if (event is Fetchstafftourdetails) {
        try {
          yield GetTourstaffdetailLoadingState();
          var staffdetails = await webService.gettourstaffdetails(
              event.Staffcode, event.token);
          yield GetTourstaffdetailsLoadedState(staffdetails: staffdetails);
        } catch (e) {
          yield GetTourstaffdetailsErrorState(msg: e.toString());
        }
      } else if (event is Submittourdetailsevent) {
        try {
          yield SubmittourdetailsLoadingState();
          var submitdetails =
              await webService.submittourdetails(event.submittour, event.token);
          yield SubmitTourdetailsLoadedState(toursubmission: submitdetails);
        } catch (e) {
          yield SubmitTourdetailsErrorState(msg: e.toString());
        }
      } else if (event is FetchappliedTourevent) {
        try {
          yield FetchappliedTourLoadingState();
          var appliedtour =
              await webService.appliedtourlist(event.Staffcode, event.token);
          yield FetchappliedTourLoadedState(appliedtourdetails: appliedtour);
        } catch (e) {
          yield FetchappliedTourErrorstate(msg: e.toString());
        }
      } else if (event is CancelTourevents) {
        try {
          yield CancelappliedtourLoadingState();
          String canceltour = await webService.canceltour(
              event.staffCode, event.slipId, event.token);
          yield CancelappliedtourLoadedState(canceltour: canceltour);
        } catch (e) {
          yield CancelappliedtourErrorState(msg: e.toString());
        }
      } else if (event is ShowexpenseAdmin) {
        try {
          yield showexpensedetailsadminLoadingState();
          final List<ViewExpenseModel> expenseview =
              await webService.showExpenseDetails(event.staffcode, event.token);
          yield showexpensedetailsadminLoadedState(expenses: expenseview);
        } catch (e) {
          yield showexpensedetailsadminErrorState(msg: e.toString());
        }
      } else if (event is Remotelocation) {
        try {
          yield remotelocationLoadingState();
          var remoteupdate = await webService.remotelocationrequest(
              event.remotelocation, event.token);
          yield remotelocationLoadedState(remotelocationresponse: remoteupdate);
        } catch (e) {
          yield remotelocationErrorState(msg: e.toString());
        }
      } else if (event is AcceptlocationRequest) {
        try {
          yield acceptrequestLoadingState();
          var acceptremoterequest = await webService.acceptremotelocation(
              event.staffcode, event.approvedflag, event.token);
          yield acceptrequestLoadedState(
              cancelGatepassResponse: acceptremoterequest);
        } catch (e) {
          yield acceptrequestErrorState(msg: e.toString());
        }
      } else if (event is Showremotelocation) {
        try {
          yield showremotelocationLoadingState();
          var showremoteaddress =
              await webService.showremotelocation(event.staffcode, event.token);
          yield showremotelocationLoadedState(
              cancelGatepassResponse: showremoteaddress);
        } catch (e) {
          yield showremotelocationErrorState(msg: e.toString());
        }
      } else if (event is NonDistancecheckRequest) {
        try {
          yield nondistancecheckLoadingState();
          var nondistancecheckrequest = await webService.nondistancecheck(
              event.staffcode, event.approvedflag, event.token);
          yield nondistancecheckLoadedState(
              cancelGatepassResponse: nondistancecheckrequest);
        } catch (e) {
          yield nondistancecheckErrorState(msg: e.toString());
        }
      } else if (event is UpdateUUID) {
        try {
          yield updateUUIDLoadingState();
          var updateuuidrequest =
              await webService.updateuuid(event.UserId, event.UUID);
          yield updateUUIDLoadedState(apiresponsee: updateuuidrequest);
        } catch (e) {
          // yield updateUUIDErrorState(apiresponse: );
        }
      } else if (event is UpdateUserFlagATS) {
        try {
          yield updateUserAtsFlagLoadingState();
          var updateatsflag =
              await webService.updateatsflagg(event.UserId, event.AtsFlag);
          yield updateUserAtsFlagLoadedState(apiresponsee: updateatsflag);
        } catch (e) {
          yield updateUserAtsFlagErrorState(msg: e.toString());
        }
      } else if (event is UpdateMMALLDataEvents) {
        try {
          yield UpdateMMALlDataLoadingState();
          var cancelGatepassResponse = await webService.UpdateMMAllDataa(
              event.updateMMAllData, event.token);
          yield UpdateMMAllDataLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          yield UpdateMMAllDataErrorState(msg: e.toString());
        }
      }
      //updateMMData
      else if (event is UpdateMMDataEvents) {
        try {
          yield UpdateMMDataLoadingState();
          var cancelGatepassResponse =
              await webService.UpdateMMDataa(event.updateMMData, event.token);
          yield UpdateMMDataLoadedState(
              cancelGatepassResponse: cancelGatepassResponse);
        } catch (e) {
          yield UpdateMMDataErrorState(msg: e.toString());
        }
      } else if (event is SearchbyStaffcodeEvents) {
        try {
          yield SearchbyStaffcodeLoadingPage();

          var userResponse = await webService.searchuserbystaffcode(
              event.token, event.staffcode);

          yield SearchbyStaffcodeLoadedPage(userResponse: userResponse);
        } catch (e) {
          yield SearchbyStaffcodeErrorPage(message: e.toString());
        }
      }

      //GetAllUsersDataList
      else if (event is GetAllUsersListEvent) {
        try {
          yield GetAllUsersListLoadingState();
          var getAllusersListResponse = await webService.GetAllUsers(
              event.token, event.pagenumber, event.pagesize);
          yield GetAllUsersListLoadedState(
              getAllusersListResponse: getAllusersListResponse);
        } catch (e) {
          //print(e.toString());
          yield GetAllUsersListErrorState(msg: e.toString());
        }
      } else if (event is GetVisitClientListEvent) {
        try {
          yield GetAllClientLoadingState();

          var response = await webService.getAllCustomers(
              event.pagenumber, event.pagesize);

          if (response != null && response.status == true) {
            yield GetAllClientLoadedState(response: response);
          } else {
            yield GetAllClientErrorState(error: "No Data Found");
          }
        } catch (e) {
          yield GetAllClientErrorState(error: e.toString());
        }
      }

      else if (event is AddMultipleRemoteLocation) {
        try{
          yield AddMultiRemoteLocationLoadingState();
          var response = await webService.addMultiRemoteLocation(event.token, event.staffcode, event.flag, event.lat, event.long, event.locationName, event.radius);
          yield AddMultiRemoteLocationLoadedState(response: response);
        } catch (e){
          yield AddMultiRemoteLocationErrorState(msg: e.toString());
        }
      }

      else if( event is GetMultiRemoteLocation){
        try{
          yield GetMultiRemoteLocationLoadingState();
          final response = await webService.getMultiRemoteLocations(event.token, event.staffCode);
          yield GetMultiRemoteLocationLoadedState(response);
        } catch (e){
          yield GetMultiRemoteLocationErrorState(msg: e.toString());
        }
      }

      else if (event is DeleteMultiRemoteLocation) {
        try {
          yield DeleteMultiRemoteLocationLoadingState();
          final response = await webService.deleteMultiRemoteLocation(event.staffCode, event.token, event.srNo);
          yield DeleteMultiRemoteLocationLoadedState(response);
        } catch (e) {
          yield DeleteMultiRemoteLocationErrorState(msg: e.toString());
        }
      }

      else if (event is UpdateMultiRemoteLocationEvent) {
        try{
          yield UpdateMultiRemoteLocationLoadingState();
          final response = await webService.updateMultiRemoteLocation(event.srNo, event.flag, event.staffCode, event.token, event.radius, event.locationName, event.lat, event.long);
          yield UpdateMultiRemoteLocationLoadedState(response);
        } catch (e) {
          yield UpdateMultiRemoteLocationErrorState(msg: e.toString());
        }
      }

    }
  }
}

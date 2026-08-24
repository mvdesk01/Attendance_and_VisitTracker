import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/ResponsibiltyModel.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/decision.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/meetinghistory.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

import '../../domain/enteties/customer.dart';
import '../../domain/enteties/meetinghistory_group.dart';
import '../../domain/enteties/submitmeeting_request.dart';
import '../../domain/enteties/submitmeeting_result.dart';
import '../../domain/repositories/mom_repositories.dart';
import '../datasource/mom_local_datasource.dart';
import '../datasource/remote_datasource.dart';
import '../model/custom_decision_master.dart';
import '../model/customer_model.dart';
import '../model/decision_model.dart';
import '../model/discussionpointrequest_model.dart';
import '../model/meetingrequest_model.dart';
import '../model/new_customer_master.dart';

class MomRepositoryImpl implements MomRepository {
  final MomRemoteDatasource remoteDatasource;
  final MomLocalDatasource localDatasource;

  MomRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  ///customer
  @override
  Future<List<Customer>> getCustomers({
    required String userName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedCustomers = await localDatasource.getCachedCustomers();

      if (cachedCustomers.isNotEmpty) {
        return cachedCustomers;
      }
    }

    final customers = await remoteDatasource.getCustomers(
      userName: userName,
    );

    await localDatasource.cacheCustomers(customers);

    return customers;
  }

  @override
  Future<void> saveSelectedCustomer(Customer customer) async {
    await localDatasource.saveSelectedCustomer(
      CustomerModel.fromEntity(customer),
    );
  }

  @override
  Future<Customer?> getSelectedCustomer() async {
    return await localDatasource.getSelectedCustomer();
  }

  ///decision
  @override
  Future<List<Decision>> getDecisions({
    required String userName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedDecisions = await localDatasource.getCachedDecisions();

      if (cachedDecisions.isNotEmpty) {
        return cachedDecisions;
      }
    }

    final decisions = await remoteDatasource.getDecisions(
      userName: userName,
    );

    await localDatasource.cacheDecisions(decisions);

    return decisions;
  }

  @override
  Future<Decision?> getSelectedDecision() async {
    return await localDatasource.getSelectedDecision();
  }

  @override
  Future<void> saveSelectedDecision(Decision decision) async {
    await localDatasource.saveSelectedDecision(
      DecisionModel.fromEntity(decision),
    );
  }

  ///responsibility

  @override
  Future<List<Responsibility>> getResponsibility({
    required String userName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedResponsibility =
          await localDatasource.getcachedResponsibility();

      if (cachedResponsibility.isNotEmpty) {
        return cachedResponsibility;
      }
    }

    final responsibility = await remoteDatasource.getResponsibility(
      userName: userName,
    );

    await localDatasource.cacheResponsibility(responsibility);

    return responsibility;
  }

  @override
  Future<Responsibility?> getSelectedResponsibility() async {
    return await localDatasource.getSelectedResposibility();
  }

  @override
  Future<void> saveSelectedResponsibility(Responsibility responsibility) async {
    await localDatasource.savedSelectedResponsibility(
      Responsibiltymodel.fromEntity(responsibility),
    );
  }

  ///submit meeting

  @override
  Future<SubmitMeetingResult> submitMeeting(
    SubmitMeetingRequest request,
  ) async {
    bool meetingSaved = false;
    bool pointsSaved = true;

    String meetingMessage = "";

    List<String> pointMessages = [];

    try {
      /// -------------------------
      /// Save Meeting
      /// -------------------------

      meetingMessage = await remoteDatasource.saveMeeting(
        MeetingRequestModel.fromEntity(
          request.meeting,
        ),
      );

      meetingSaved = meetingMessage.toLowerCase().contains("success");

      /// -------------------------
      /// Save Discussion Points
      /// -------------------------

      for (final point in request.discussionPoints) {
        final message = await remoteDatasource.saveDiscussionPoint(
          DiscussionPointRequestModel.fromEntity(point),
        );

        pointMessages.add(message);

        if (!message.toLowerCase().contains("success")) {
          pointsSaved = false;
        }
      }
    } catch (e) {
      return SubmitMeetingResult(
        meetingSaved: false,
        pointsSaved: false,
        meetingMessage: e.toString(),
        pointMessages: pointMessages,
      );
    }

    return SubmitMeetingResult(
      meetingSaved: meetingSaved,
      pointsSaved: pointsSaved,
      meetingMessage: meetingMessage,
      pointMessages: pointMessages,
    );
  }

  @override
  Future<List<MeetingHistoryGroup>> getMeetingHistory({
    required String customerCode,
    required String meetingDate,
  }) async {
    final history = await remoteDatasource.getMeetingHistory(
      customerCode: customerCode,
      meetingDate: meetingDate,
    );

    final Map<String, List<MeetingHistory>> grouped = {};

    for (final item in history) {
      grouped.putIfAbsent(item.meetingId, () => []);
      grouped[item.meetingId]!.add(item);
    }

    final List<MeetingHistoryGroup> meetings = [];

    grouped.forEach((meetingId, points) {
      final first = points.first;

      meetings.add(
        MeetingHistoryGroup(
          meetingId: first.meetingId,
          customer: first.customer,
          memberPresent: first.memberPresent,
          memberAbsent: first.memberAbsent,
          meetingDate: first.meetingDate,
          meetingTime: first.meetingTime,
          nextMeetingDate: first.nextMeetingDate,
          discussionPoints: points,
        ),
      );
    });

    return meetings;
  }

  @override
  Future<String> addCustomDecision({
    required String decisionName,
    required String entryBy,
  }) async {
    final request = DecisionMasterRequest(
      decisionCode: "0",
      decisionName: decisionName,
      status: "Y",
      entryBy: entryBy,
    );

    return await remoteDatasource.addCustomDecision(request);
  }

  @override
  Future<String> addCustomer({
    required String customerName,
    required String contactPerson,
    required String address,
    required String mobileNo,
    required String emailId,
    required String entryBy,
  }) async {
    final request = CustomerMasterRequest(
      customername: customerName,
      contactperson: contactPerson,
      address: address,
      mobileno: mobileNo,
      emailid: emailId,
      entryby: entryBy,
      flag: "I",
    );

    return await remoteDatasource.addCustomer(request);
  }
}

///test

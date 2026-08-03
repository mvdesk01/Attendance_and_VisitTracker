import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

import '../enteties/customer.dart';
import '../enteties/decision.dart';
import '../enteties/meetinghistory_group.dart';
import '../enteties/submitmeeting_request.dart';
import '../enteties/submitmeeting_result.dart';

abstract class MomRepository {
  ///customer
  Future<List<Customer>> getCustomers({
    required String userName,
    bool forceRefresh = false,
  });

  Future<void> saveSelectedCustomer(Customer customer);

  Future<Customer?> getSelectedCustomer();

  ///decision
  Future<List<Decision>> getDecisions({
    required String userName,
    bool forceRefresh = false,
  });

  Future<void> saveSelectedDecision(Decision decision);

  Future<Decision?> getSelectedDecision();

  ///responsibility
  Future<List<Responsibility>> getResponsibility({
    required String userName,
    bool forceRefresh = false,
  });

  Future<void> saveSelectedResponsibility(Responsibility responsibility);

  Future<Responsibility?> getSelectedResponsibility();

  ///submit meeting
  Future<SubmitMeetingResult> submitMeeting(
    SubmitMeetingRequest request,
  );

  Future<List<MeetingHistoryGroup>> getMeetingHistory(
      {required String customerCode, required String meetingDate});
}

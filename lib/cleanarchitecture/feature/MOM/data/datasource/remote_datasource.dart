import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/ResponsibiltyModel.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/meetinghistory_model.dart';

import '../model/customer_model.dart';
import '../model/decision_model.dart';
import '../model/discussionpointrequest_model.dart';
import '../model/meetingrequest_model.dart';

abstract class MomRemoteDatasource {
  Future<List<CustomerModel>> getCustomers({
    required String userName,
  });

  Future<List<DecisionModel>> getDecisions({
    required String userName,
  });

  Future<List<Responsibiltymodel>> getResponsibility({
    required String userName,
  });

  Future<String> saveMeeting(
    MeetingRequestModel meeting,
  );

  Future<String> saveDiscussionPoint(
    DiscussionPointRequestModel point,
  );

  Future<List<MeetinghistoryModel>> getMeetingHistory({
    required String customerCode,
    required String meetingDate,
  });
}

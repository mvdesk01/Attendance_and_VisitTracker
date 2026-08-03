import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/datasource/remote_datasource.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/ResponsibiltyModel.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/meetinghistory_model.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../model/customer_model.dart';
import '../model/decision_model.dart';
import '../model/discussionpointrequest_model.dart';
import '../model/meetingrequest_model.dart';

class MomRemoteDatasourceImpl implements MomRemoteDatasource {
  final Dio dio = DioClient().dio;

  @override
  Future<List<CustomerModel>> getCustomers({
    required String userName,
  }) async {
    final Response response = await dio.post(
      'Customer',
      data: {
        "UserName": userName,
      },
    );

    return (response.data as List)
        .map((e) => CustomerModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<DecisionModel>> getDecisions({
    required String userName,
  }) async {
    final response = await dio.post(
      "Decision",
      data: {
        "UserName": userName,
      },
    );
    print(response.data);

    return (response.data as List)
        .map((e) => DecisionModel.fromJson(e))
        .toList();
  }

  Future<List<Responsibiltymodel>> getResponsibility({
    required String userName,
  }) async {
    final response = await dio.post(
      "Responsibility",
      data: {
        "UserName": userName,
      },
    );
    return (response.data as List)
        .map((e) => Responsibiltymodel.fromJson(e))
        .toList();
  }

  @override
  Future<String> saveMeeting(
    MeetingRequestModel meeting,
  ) async {
    final response = await dio.post(
      "MOMMasterDetails",
      data: meeting.toJson(),
    );

    return response.data.first["OutMsg"];
  }

  @override
  Future<String> saveDiscussionPoint(
    DiscussionPointRequestModel point,
  ) async {
    final response = await dio.post(
      "MOMPointsDetails",
      data: point.toJson(),
    );

    return response.data.first["OutMsg"];
  }

  @override
  Future<List<MeetinghistoryModel>> getMeetingHistory(
      {required String customerCode, required String meetingDate}) async {
    final response = await dio.post(
      "MOMMeetingDetails",
      data: {
        "Customer": customerCode,
        "MeetingDate": meetingDate,
      },
    );

    return (response.data as List)
        .map((e) => MeetinghistoryModel.fromJson(e))
        .toList();
  }
}

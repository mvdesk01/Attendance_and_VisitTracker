import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/datasource/remote_datasource.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/ResponsibiltyModel.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/meetinghistory_model.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../model/custom_decision_master.dart';
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
    try {
      print("Calling Customer API...");

      final response = await dio.post(
        "Customer",
        data: {
          "UserName": userName,
        },
      );

      print("Customer API Response:");
      print(response.data);

      return (response.data as List)
          .map((e) => CustomerModel.fromJson(e))
          .toList();
    } catch (e, s) {
      print("Customer API Error:");
      print(e);
      print(s);
      rethrow;
    }
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
  Future<List<MeetinghistoryModel>> getMeetingHistory({
    required String customerCode,
    required String meetingDate,
  }) async {
    final Response response = await dio.post(
      "MOMMeetingDetails",
      data: {
        "Customer": customerCode,
        "MeetingDate": meetingDate,
      },
    );

    print("========== MOM HISTORY API ==========");
    print(response.data);

    final list = (response.data as List)
        .map((e) => MeetinghistoryModel.fromJson(e))
        .toList();

    print("Total Records: ${list.length}");

    for (final item in list) {
      print(
        "MeetingId: ${item.meetingId} | Point: ${item.point}",
      );
    }

    return list;
  }

  // @override
  // Future<String> addCustomDecision(
  //   DecisionMasterRequest request,
  // ) async {
  //   final Response response =
  //       await dio.post("DecisionMaster", data: jsonEncode(request.toJson()));
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     final json = jsonDecode(response.data);
  //     final result = DecisionMasterResponse.fromJson(json);
  //     return result.outMsg;
  //   }
  //   throw Exception(
  //     'Failed to add decision. '
  //     'Status code: ${response.statusCode}',
  //   );
  // }
  /*@override
  Future<String> addCustomDecision(
    DecisionMasterRequest request,
  ) async {
    final Response response = await dio.post(
      "DecisionMaster",
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final result = DecisionMasterResponse.fromJson(
        Map<String, dynamic>.from(data),
      );

      return result.outMsg;
    }

    throw Exception(
      'Failed to add decision. '
      'Status code: ${response.statusCode}',
    );
  }*/
  @override
  Future<String> addCustomDecision(
    DecisionMasterRequest request,
  ) async {
    final Response response = await dio.post(
      "DecisionMaster",
      data: request.toJson(),
    );

    print("DecisionMaster Response: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      // API returns:
      // [
      //   {
      //     "OutMsg": "Details save successfully"
      //   }
      // ]

      if (data is List && data.isNotEmpty) {
        final result = DecisionMasterResponse.fromJson(
          Map<String, dynamic>.from(data.first),
        );

        return result.outMsg;
      }

      // Just in case API returns an object in future.
      if (data is Map) {
        final result = DecisionMasterResponse.fromJson(
          Map<String, dynamic>.from(data),
        );

        return result.outMsg;
      }

      throw Exception(
        "Unexpected DecisionMaster response format",
      );
    }

    throw Exception(
      'Failed to add decision. '
      'Status code: ${response.statusCode}',
    );
  }
}

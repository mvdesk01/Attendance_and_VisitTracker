import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/datasource/remote_datasource.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/ResponsibiltyModel.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/meetinghistory_model.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../core/network/dio_client.dart';
import '../model/custom_decision_master.dart';
import '../model/customer_model.dart';
import '../model/decision_model.dart';
import '../model/discussionpointrequest_model.dart';
import '../model/meetingrequest_model.dart';
import '../model/new_customer_master.dart';

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

  // @override
  // Future<String> saveMeeting(
  //   MeetingRequestModel meeting,
  // ) async {
  //   final response = await dio.post(
  //     "MOMMasterDetails",
  //     data: meeting.toJson(),
  //   );
  //
  //   return response.data.first["OutMsg"];
  // }
  @override
  Future<String> saveMeeting(
    MeetingRequestModel meeting,
  ) async {
    try {
      final response = await dio.post(
        "MOMMasterDetails",
        data: meeting.toJson(),
      );

      return response.data.first["OutMsg"]?.toString() ??
          "Meeting saved successfully.";
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception(
        "Unable to save meeting. Please try again.",
      );
    }
  }

  // @override
  // Future<String> saveDiscussionPoint(
  //   DiscussionPointRequestModel point,
  // ) async {
  //   final response = await dio.post(
  //     "MOMPointsDetails",
  //     data: point.toJson(),
  //   );
  //
  //   return response.data.first["OutMsg"];
  // }
  @override
  Future<String> saveDiscussionPoint(
    DiscussionPointRequestModel point,
  ) async {
    try {
      final response = await dio.post(
        "MOMPointsDetails",
        data: point.toJson(),
      );

      return response.data.first["OutMsg"]?.toString() ??
          "Discussion point saved successfully.";
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception(
        "Unable to save discussion point. Please try again.",
      );
    }
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

  @override
  Future<String> addCustomer(
    CustomerMasterRequest request,
  ) async {
    final Response response = await dio.post(
      "CustomerMaster",
      data: request.toJson(),
    );

    print("========== CUSTOMER MASTER API ==========");
    print("Request: ${request.toJson()}");
    print("Response: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      // API response:
      // [
      //   {
      //     "OutMsg": "Details save successfully"
      //   }
      // ]

      if (data is List && data.isNotEmpty) {
        final result = CustomerMasterResponse.fromJson(
          Map<String, dynamic>.from(data.first),
        );

        return result.outMsg;
      }

      if (data is Map) {
        final result = CustomerMasterResponse.fromJson(
          Map<String, dynamic>.from(data),
        );

        return result.outMsg;
      }

      throw Exception(
        "Unexpected CustomerMaster response format",
      );
    } else if (response.statusCode == 500) {
      Fluttertoast.showToast(msg: "Server error");
    }

    throw Exception(
      "Failed to add customer. "
      "Status code: ${response.statusCode}",
    );
  }

  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timed out. Please check your internet connection.";

      case DioExceptionType.sendTimeout:
        return "Request timed out while sending. Please try again.";

      case DioExceptionType.receiveTimeout:
        return "Server response timed out. Please try again.";

      case DioExceptionType.connectionError:
        return "Unable to connect to the server. Please check your internet connection.";

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;

        switch (statusCode) {
          case 400:
            return "Invalid request. Please check the entered information.";

          case 401:
            return "Unauthorized request. Please login again.";

          case 403:
            return "You are not authorized to perform this action.";

          case 404:
            return "Requested service was not found.";

          case 409:
            return "A conflict occurred. Please try again.";

          case 422:
            return "The submitted data is invalid.";

          case 429:
            return "Too many requests. Please try again later.";

          case 500:
            return "Server error. Please try again later.";

          case 502:
            return "Server is temporarily unavailable.";

          case 503:
            return "Service is temporarily unavailable.";

          case 504:
            return "Server response timed out. Please try again.";

          default:
            return "Request failed"
                "${statusCode != null ? " ($statusCode)" : ""}. "
                "Please try again.";
        }

      case DioExceptionType.cancel:
        return "Request was cancelled.";

      case DioExceptionType.badCertificate:
        return "Unable to establish a secure connection.";

      case DioExceptionType.unknown:
        return "Something went wrong. Please check your internet connection and try again.";
    }
  }
}

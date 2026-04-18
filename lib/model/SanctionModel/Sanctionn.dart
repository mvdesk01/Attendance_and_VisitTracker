import 'dart:convert';

SanctionRequestModel profileResponseFromJson(String str) =>
    SanctionRequestModel.fromJson(json.decode(str));

String profileResponseToJson(SanctionRequestModel data) =>
    json.encode(data.toJson());

class SanctionRequestModel {
  final String tid;
  final String staffCode;
  final String requestType;
  final String ttlDays;
  final String sDate;
  final String eDate;
  final bool appRadio;
  final bool rejRadio;
  final String rejectReason;
  final bool approvalRadio;
  final bool sanctionRadio;

  SanctionRequestModel({
    required this.tid,
    required this.staffCode,
    required this.requestType,
    required this.ttlDays,
    required this.sDate,
    required this.eDate,
    required this.appRadio,
    required this.rejRadio,
    required this.rejectReason,
    required this.approvalRadio,
    required this.sanctionRadio,
  });

  factory SanctionRequestModel.fromJson(Map<String, dynamic> json) {
    return SanctionRequestModel(
      tid: json['tid'] ?? '',
      staffCode: json['staffCode'] ?? '',
      requestType: json['requestType'] ?? '',
      ttlDays: json['ttlDays'] ?? '',
      sDate: json['sDate'] ?? '',
      eDate: json['eDate'] ?? '',
      appRadio: json['appRadio'] ?? false,
      rejRadio: json['rejRadio'] ?? false,
      rejectReason: json['rejectReason'] ?? '',
      approvalRadio: json['approvalRadio'] ?? false,
      sanctionRadio: json['sanctionRadio'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'staffCode': staffCode,
      'requestType': requestType,
      'ttlDays': ttlDays,
      'sDate': sDate,
      'eDate': eDate,
      'appRadio': appRadio,
      'rejRadio': rejRadio,
      'rejectReason': rejectReason,
      'approvalRadio': approvalRadio,
      'sanctionRadio': sanctionRadio,
    };
  }
}

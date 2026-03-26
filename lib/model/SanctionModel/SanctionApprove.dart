import 'dart:convert';

ApprovedSanctionRecords profileResponseFromJson(String str) =>
    ApprovedSanctionRecords.fromJson(json.decode(str));

String profileResponseToJson(ApprovedSanctionRecords data) =>
    json.encode(data.toJson());

class ApprovedSanctionRecords {
  final int tid;
  final String staffCode;
  final String name;
  final String date;
  final String type;
  final String daysHours;
  final String coffType;
  final String aFlag;
  final String eDate;

  ApprovedSanctionRecords({
    required this.tid,
    required this.staffCode,
    required this.name,
    required this.date,
    required this.type,
    required this.daysHours,
    required this.coffType,
    required this.aFlag,
    required this.eDate,
  });

  // Method to convert JSON to model
  factory ApprovedSanctionRecords.fromJson(Map<String, dynamic> json) {
    return ApprovedSanctionRecords(
      tid: json['tid'] ?? 0,
      staffCode: json['staffCode'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      daysHours: json['daysHours'] ?? '',
      coffType: json['coffType'] ?? '',
      aFlag: json['aFlag'] ?? '',
      eDate: json['eDate'] ?? '',
    );
  }

  // Method to convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'staffCode': staffCode,
      'name': name,
      'date': date,
      'type': type,
      'daysHours': daysHours,
      'coffType': coffType,
      'aFlag': aFlag,
      'eDate': eDate,
    };
  }
}

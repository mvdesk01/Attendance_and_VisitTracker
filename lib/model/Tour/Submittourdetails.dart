import 'dart:convert';

SubmitTourDetails tourDetailsFromJson(String str) => SubmitTourDetails.fromJson(json.decode(str));

String tourDetailsToJson(SubmitTourDetails data) => json.encode(data.toJson());

class SubmitTourDetails {
  String? slipId;
  String? staffCode;
  String? name;
  String? department;
  String? designation;
  String? fromDate;
  String? toDate;
  String? addressOnTour;
  String? reason;
  String? purpose;
  bool? add;

  SubmitTourDetails({
    this.slipId,
    this.staffCode,
    this.name,
    this.department,
    this.designation,
    this.fromDate,
    this.toDate,
    this.addressOnTour,
    this.reason,
    this.purpose,
    this.add,
  });

  factory SubmitTourDetails.fromJson(Map<String, dynamic> json) => SubmitTourDetails(
    slipId: json['slipId'] ?? '',
    staffCode: json['staffCode'] ?? '',
    name: json['name'] ?? '',
    department: json['department'] ?? '',
    designation: json['designation'] ?? '',
    fromDate: json['fromDate'] ?? '',
    toDate: json['toDate'] ?? '',
    addressOnTour: json['addressOnTour'] ?? '',
    reason: json['reason'] ?? '',
    purpose: json['purpose'] ?? '',
    add: json['add'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'slipId': slipId,
    'staffCode': staffCode,
    'name': name,
    'department': department,
    'designation': designation,
    'fromDate': fromDate,
    'toDate': toDate,
    'addressOnTour': addressOnTour,
    'reason': reason,
    'purpose': purpose,
    'add': add,
  };
}

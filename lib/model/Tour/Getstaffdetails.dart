import 'dart:convert';

StaffDetails StaffDetailsFromJson(String str) => StaffDetails.fromJson(json.decode(str));

String StaffDetailsToJson(StaffDetails data) => json.encode(data.toJson());

class StaffDetails {
  Message? message;

  StaffDetails({this.message});

  factory StaffDetails.fromJson(Map<String, dynamic> json) {
    return StaffDetails(
      message: json['message'] != null ? Message.fromJson(json['message']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (message != null) {
      data['message'] = message!.toJson();
    }
    return data;
  }
}

class Message {
  StaffMessage? message;

  Message({this.message});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: json['message'] != null ? StaffMessage.fromJson(json['message']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (message != null) {
      data['message'] = message!.toJson();
    }
    return data;
  }
}

class StaffMessage {
  String? staffCode;
  String? fullName;
  String? plantName;
  String? dateOfJoining;
  String? designation;
  String? department;
  String? year;
  String? fromDate;
  String? toDate;
  String? category;
  String? gender;

  StaffMessage({
    this.staffCode,
    this.fullName,
    this.plantName,
    this.dateOfJoining,
    this.designation,
    this.department,
    this.year,
    this.fromDate,
    this.toDate,
    this.category,
    this.gender,
  });

  factory StaffMessage.fromJson(Map<String, dynamic> json) {
    return StaffMessage(
      staffCode: json['staffCode'] ?? '',
      fullName: json['fullName'] ?? '',
      plantName: json['plantName'] ?? '',
      dateOfJoining: json['dateOfJoining'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? '',
      year: json['year'],
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      category: json['category'] ?? '',
      gender: json['gender'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'fullName': fullName,
      'plantName': plantName,
      'dateOfJoining': dateOfJoining,
      'designation': designation,
      'department': department,
      'year': year,
      'fromDate': fromDate,
      'toDate': toDate,
      'category': category,
      'gender': gender,
    };
  }
}

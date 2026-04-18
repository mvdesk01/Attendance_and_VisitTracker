import 'dart:convert';

LeaveDetails leaveDetailsResponseFromJson(String str) =>
    LeaveDetails.fromJson(json.decode(str));

String leaveDetailsResponseToJson(LeaveDetails data) => json.encode(data.toJson());

class LeaveDetails {
  List<LeaveType>? leaveTypes;

  LeaveDetails({this.leaveTypes});

  LeaveDetails.fromJson(Map<String, dynamic> json) {
    if (json['message'] != null) {
      leaveTypes = <LeaveType>[];
      json['message'].forEach((v) {
        leaveTypes!.add(LeaveType.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.leaveTypes != null) {
      data['message'] = this.leaveTypes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LeaveType {
  String? leaveTypeCode;
  String? leaveTypeName;
  String? daysRemaining;
  String? totalDays;
  String? minDaysAllowed;
  String? maxDaysAllowed;

  LeaveType({
    this.leaveTypeCode,
    this.leaveTypeName,
    this.daysRemaining,
    this.totalDays,
    this.minDaysAllowed,
    this.maxDaysAllowed,
  });

  LeaveType.fromJson(Map<String, dynamic> json) {
    leaveTypeCode = json['leaveTypeCode'];
    leaveTypeName = json['leaveTypeName'];
    daysRemaining = json['daysRemaining'];
    totalDays = json['totalDays'];
    minDaysAllowed = json['minDaysAllowed'];
    maxDaysAllowed = json['maxDaysAllowed'];
  }

  get totalAllowed => null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['leaveTypeCode'] = this.leaveTypeCode;
    data['leaveTypeName'] = this.leaveTypeName;
    data['daysRemaining'] = this.daysRemaining;
    data['totalDays'] = this.totalDays;
    data['minDaysAllowed'] = this.minDaysAllowed;
    data['maxDaysAllowed'] = this.maxDaysAllowed;
    return data;
  }
}

import 'dart:convert';

StaffDetailsResponse StaffDetailsResponseFromJson(String str) =>
    StaffDetailsResponse.fromJson(json.decode(str));

String StaffDetailsResponseToJson(StaffDetailsResponse data) => json.encode(data.toJson());


class StaffDetailsResponse {
  Message? message;

  StaffDetailsResponse({this.message});

  StaffDetailsResponse.fromJson(Map<String, dynamic> json) {
    message =
    json['message'] != null ? new Message.fromJson(json['message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    return data;
  }
}

class Message {
  int? transactionID;
  String? gatePassDate;
  String? staffCode;
  String? staffName;
  String? departmentName;
  String? designation;
  String? shift;

  /// 👇 NEW FIELD
  String? errorMessage;

  Message({
    this.transactionID,
    this.gatePassDate,
    this.staffCode,
    this.staffName,
    this.departmentName,
    this.designation,
    this.shift,
    this.errorMessage,
  });

  Message.fromJson(Map<String, dynamic> json) {
    // Success fields
    transactionID = json['transactionID'];
    gatePassDate = json['gatePassDate'];
    staffCode = json['staffCode'];
    staffName = json['staffName'];
    departmentName = json['departmentName'];
    designation = json['designation'];
    shift = json['shift'];

    // 🔴 Error case
    if (json['message'] is String) {
      errorMessage = json['message'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['transactionID'] = transactionID;
    data['gatePassDate'] = gatePassDate;
    data['staffCode'] = staffCode;
    data['staffName'] = staffName;
    data['departmentName'] = departmentName;
    data['designation'] = designation;
    data['shift'] = shift;

    if (errorMessage != null) {
      data['message'] = errorMessage;
    }
    return data;
  }
}
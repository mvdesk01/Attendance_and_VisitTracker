import 'dart:convert';

SubmitCoffDebitRequest SubmitCoffDebitRequestFromJson(String str) => SubmitCoffDebitRequest.fromJson(json.decode(str));

String SubmitCoffDebitRequestToJson(SubmitCoffDebitRequest data) => json.encode(data.toJson());

class SubmitCoffDebitRequest {
  String? coffID;
  String? staffCode;
  String? staffName;
  String? coffDate;
  String? department;
  String? designation;
  String? shift;
  String? balance;
  String? fromTime;
  String? toTime;
  String? reason;
  String? check;
  String? purpose;
  bool? add;

  SubmitCoffDebitRequest(
      {this.coffID,
        this.staffCode,
        this.staffName,
        this.coffDate,
        this.department,
        this.designation,
        this.shift,
        this.balance,
        this.fromTime,
        this.toTime,
        this.reason,
        this.check,
        this.purpose,
        this.add});

  SubmitCoffDebitRequest.fromJson(Map<String, dynamic> json) {
    coffID = json['coffID'];
    staffCode = json['staffCode'];
    staffName = json['staffName'];
    coffDate = json['coffDate'];
    department = json['department'];
    designation = json['designation'];
    shift = json['shift'];
    balance = json['balance'];
    fromTime = json['fromTime'];
    toTime = json['toTime'];
    reason = json['reason'];
    check = json['check'];
    purpose = json['purpose'];
    add = json['add'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['coffID'] = this.coffID;
    data['staffCode'] = this.staffCode;
    data['staffName'] = this.staffName;
    data['coffDate'] = this.coffDate;
    data['department'] = this.department;
    data['designation'] = this.designation;
    data['shift'] = this.shift;
    data['balance'] = this.balance;
    data['fromTime'] = this.fromTime;
    data['toTime'] = this.toTime;
    data['reason'] = this.reason;
    data['check'] = this.check;
    data['purpose'] = this.purpose;
    data['add'] = this.add;
    return data;
  }
}
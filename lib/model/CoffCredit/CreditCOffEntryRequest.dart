import 'dart:convert';

CreditCOffEntryRequest CreditCOffEntryRequestResponseFromJson(String str) => CreditCOffEntryRequest.fromJson(json.decode(str));

String CreditCOffEntryRequestResponseToJson(CreditCOffEntryRequest data) => json.encode(data.toJson());


class CreditCOffEntryRequest {
  String? otid;
  String? type;
  String? staffCode;
  String? name;
  String? department;
  String? date;
  String? designation;
  String? shift;
  String? totalHrs;
  String? balanceHrs;
  String? reason;
  bool? otherChecked;
  String? otherDetails;

  CreditCOffEntryRequest(
      {this.otid,
        this.type,
        this.staffCode,
        this.name,
        this.department,
        this.date,
        this.designation,
        this.shift,
        this.totalHrs,
        this.balanceHrs,
        this.reason,
        this.otherChecked,
        this.otherDetails});

  CreditCOffEntryRequest.fromJson(Map<String, dynamic> json) {
    otid = json['otid'];
    type = json['type'];
    staffCode = json['staffCode'];
    name = json['name'];
    department = json['department'];
    date = json['date'];
    designation = json['designation'];
    shift = json['shift'];
    totalHrs = json['totalHrs'];
    balanceHrs = json['balanceHrs'];
    reason = json['reason'];
    otherChecked = json['otherChecked'];
    otherDetails = json['otherDetails'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['otid'] = this.otid;
    data['type'] = this.type;
    data['staffCode'] = this.staffCode;
    data['name'] = this.name;
    data['department'] = this.department;
    data['date'] = this.date;
    data['designation'] = this.designation;
    data['shift'] = this.shift;
    data['totalHrs'] = this.totalHrs;
    data['balanceHrs'] = this.balanceHrs;
    data['reason'] = this.reason;
    data['otherChecked'] = this.otherChecked;
    data['otherDetails'] = this.otherDetails;
    return data;
  }
}
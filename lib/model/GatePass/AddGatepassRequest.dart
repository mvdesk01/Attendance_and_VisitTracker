import 'dart:convert';

AddGatepassRequest addGatePassRequestFromJson(String str) => AddGatepassRequest.fromJson(json.decode(str));

String addGatePassRequestToJson(AddGatepassRequest data) => json.encode(data.toJson());



class AddGatepassRequest {
  String? transactionID;
  String? gatePassDate;
  String? staffCode;
  String? designation;
  String? dept;
  String? gatePassTypeCode;
  String? fromTime;
  String? toTime;
  int? totalTime;
  String? shiftCode;
  String? reason;
  String? purpose;
  bool? chkActive;
  bool? add;

  AddGatepassRequest(
      {this.transactionID,
        this.gatePassDate,
        this.staffCode,
        this.designation,
        this.dept,
        this.gatePassTypeCode,
        this.fromTime,
        this.toTime,
        this.totalTime,
        this.shiftCode,
        this.reason,
        this.purpose,
        this.chkActive,
        this.add});

  AddGatepassRequest.fromJson(Map<String, dynamic> json) {
    transactionID = json['transactionID'];
    gatePassDate = json['gatePassDate'];
    staffCode = json['staffCode'];
    designation = json['designation'];
    dept = json['dept'];
    gatePassTypeCode = json['gatePassTypeCode'];
    fromTime = json['fromTime'];
    toTime = json['toTime'];
    totalTime = json['totalTime'];
    shiftCode = json['shiftCode'];
    reason = json['reason'];
    purpose = json['purpose'];
    chkActive = json['chkActive'];
    add = json['add'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transactionID'] = this.transactionID;
    data['gatePassDate'] = this.gatePassDate;
    data['staffCode'] = this.staffCode;
    data['designation'] = this.designation;
    data['dept'] = this.dept;
    data['gatePassTypeCode'] = this.gatePassTypeCode;
    data['fromTime'] = this.fromTime;
    data['toTime'] = this.toTime;
    data['totalTime'] = this.totalTime;
    data['shiftCode'] = this.shiftCode;
    data['reason'] = this.reason;
    data['purpose'] = this.purpose;
    data['chkActive'] = this.chkActive;
    data['add'] = this.add;
    return data;
  }
}
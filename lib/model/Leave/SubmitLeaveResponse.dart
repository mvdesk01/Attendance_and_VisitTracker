import 'dart:convert';

SubmitLeaveDetails leaveDetailsFromJson(String str) =>
    SubmitLeaveDetails.fromJson(json.decode(str));

String leaveDetailsToJson(SubmitLeaveDetails data) => json.encode(data.toJson());

class SubmitLeaveDetails {
  String? flag ;  // default to 'insert'
  String? transactionId;
  String? staffCode;
  String? name;
  String? plant;
  String? doj;  // date of joining
  String? dept;  // department
  String? weeklyOff;
  String? leaveType;
  String? leaveBalance;
  String? fromDate;
  String? toDate;
  String? fromTime;
  String? toTime;
  bool? rdoFfirstHalf;
  bool? rdoFSecondHalf;
  bool? rdoTsecondHalf;
  bool? rdoTfirstHalf;
  String? year;
  String? totalDays;
  String? checkInFraction;  // added for Leave in Fraction
  String? address;
  String? reason;
  String? mobileNo;

  SubmitLeaveDetails({
    this.flag,
    this.transactionId,
    this.staffCode,
    this.name,
    this.plant,
    this.doj,
    this.dept,
    this.weeklyOff,
    this.leaveType,
    this.leaveBalance,
    this.fromDate,
    this.toDate,
    this.fromTime,
    this.toTime,
    this.rdoFfirstHalf,
    this.rdoFSecondHalf,
    this.rdoTsecondHalf,
    this.rdoTfirstHalf,
    this.year,
    this.totalDays,
    this.checkInFraction,
    this.address,
    this.reason,
    this.mobileNo,
  });

  factory SubmitLeaveDetails.fromJson(Map<String, dynamic> json) => SubmitLeaveDetails(
    flag: json['flag'],
    transactionId: json['transactionId'],
    staffCode: json['staffCode'],
    name: json['name'],
    plant: json['plant'],
    doj: json['doj'],
    dept: json['dept'],
    weeklyOff: json['weeklyOff'],
    leaveType: json['leaveType'],
    leaveBalance: json['leaveBalance'],
    fromDate: json['fromDate'],
    toDate: json['toDate'],
    fromTime: json['fromTime'],
    toTime: json['toTime'],
    rdoFfirstHalf: json['rdoFfirstHalf'],
    rdoFSecondHalf: json['rdoFSecondHalf'],
    rdoTsecondHalf: json['rdoTsecondHalf'],
    rdoTfirstHalf: json['rdoTfirstHalf'],
    year: json['year'],
    totalDays: json['totalDays'],
    checkInFraction: json['checkInFraction'],
    address: json['address'],
    reason: json['reason'],
    mobileNo: json['mobileNo'],
  );

  Map<String, dynamic> toJson() => {
    'flag': flag,
    'transactionId': transactionId,
    'staffCode': staffCode,
    'name': name,
    'plant': plant,
    'doj': doj,
    'dept': dept,
    'weeklyOff': weeklyOff,
    'leaveType': leaveType,
    'leaveBalance': leaveBalance,
    'fromDate': fromDate,
    'toDate': toDate,
    'fromTime': fromTime,
    'toTime': toTime,
    'rdoFfirstHalf': rdoFfirstHalf,
    'rdoFSecondHalf': rdoFSecondHalf,
    'rdoTsecondHalf': rdoTsecondHalf,
    'rdoTfirstHalf': rdoTfirstHalf,
    'year': year,
    'totalDays': totalDays,
    'checkInFraction': checkInFraction,
    'address': address,
    'reason': reason,
    'mobileNo': mobileNo,
  };
}


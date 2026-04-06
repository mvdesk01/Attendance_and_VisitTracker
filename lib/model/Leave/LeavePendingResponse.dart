import 'dart:convert';

LeavePendingResponse leavePendingResponseFromJson(String str) =>
    LeavePendingResponse.fromJson(json.decode(str));

String leavePendingResponseToJson(LeavePendingResponse data) =>
    json.encode(data.toJson());

class LeavePendingResponse {
  List<Message>? message;

  LeavePendingResponse({this.message});

  factory LeavePendingResponse.fromJson(Map<String, dynamic> json) =>
      LeavePendingResponse(
        message: json['message'] != null
            ? List<Message>.from(
            json['message'].map((x) => Message.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
    if (message != null)
      'message': List<dynamic>.from(message!.map((x) => x.toJson())),
  };
}

class Message {
  int? transactionId;
  String? transactionDate;
  String? staffCode;
  String? startingDate;
  String? stFhflag;
  String? stShflag;
  String? endingDate;
  String? enFhflag;
  String? enShflag;
  String? leaveTypeCode;
  double? noOfDays;
  String? reason;
  String? addrOnLeave;
  String? approvedFlag;
  String? approvedDate;
  String? approvedBy;
  String? comment;
  String? acFlag;
  String? acUser;
  String? acDate;
  String? reasonOnReject;
  String? mobileNo;
  String? transferstatus;
  String? fromTime;
  String? toTime;
  String? fractionOfLeave;
  double? totalTime;
  String? pcipaddress;

  Message({
    this.transactionId,
    this.transactionDate,
    this.staffCode,
    this.startingDate,
    this.stFhflag,
    this.stShflag,
    this.endingDate,
    this.enFhflag,
    this.enShflag,
    this.leaveTypeCode,
    this.noOfDays,
    this.reason,
    this.addrOnLeave,
    this.approvedFlag,
    this.approvedDate,
    this.approvedBy,
    this.comment,
    this.acFlag,
    this.acUser,
    this.acDate,
    this.reasonOnReject,
    this.mobileNo,
    this.transferstatus,
    this.fromTime,
    this.toTime,
    this.fractionOfLeave,
    this.totalTime,
    this.pcipaddress,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    transactionId: json['transactionId'],
    transactionDate: json['transactionDate'],
    staffCode: json['staffCode'],
    startingDate: json['startingDate'],
    stFhflag: json['stFhflag'],
    stShflag: json['stShflag'],
    endingDate: json['endingDate'],
    enFhflag: json['enFhflag'],
    enShflag: json['enShflag'],
    leaveTypeCode: json['leaveTypeCode'],
    noOfDays: (json['noOfDays'] as num?)?.toDouble(),
    reason: json['reason'],
    addrOnLeave: json['addrOnLeave'],
    approvedFlag: json['approvedFlag'],
    approvedDate: json['approvedDate'],
    approvedBy: json['approvedBy'],
    comment: json['comment'],
    acFlag: json['acFlag'],
    acUser: json['acUser'],
    acDate: json['acDate'],
    reasonOnReject: json['reasonOnReject'],
    mobileNo: json['mobileNo'],
    transferstatus: json['transferstatus'],
    fromTime: json['fromTime'],
    toTime: json['toTime'],
    fractionOfLeave: json['fractionOfLeave'],
    totalTime: (json['totalTime'] as num?)?.toDouble(),
    pcipaddress: json['pcipaddress'],
  );

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'transactionDate': transactionDate,
    'staffCode': staffCode,
    'startingDate': startingDate,
    'stFhflag': stFhflag,
    'stShflag': stShflag,
    'endingDate': endingDate,
    'enFhflag': enFhflag,
    'enShflag': enShflag,
    'leaveTypeCode': leaveTypeCode,
    'noOfDays': noOfDays,
    'reason': reason,
    'addrOnLeave': addrOnLeave,
    'approvedFlag': approvedFlag,
    'approvedDate': approvedDate,
    'approvedBy': approvedBy,
    'comment': comment,
    'acFlag': acFlag,
    'acUser': acUser,
    'acDate': acDate,
    'reasonOnReject': reasonOnReject,
    'mobileNo': mobileNo,
    'transferstatus': transferstatus,
    'fromTime': fromTime,
    'toTime': toTime,
    'fractionOfLeave': fractionOfLeave,
    'totalTime': totalTime,
    'pcipaddress': pcipaddress,
  };
}

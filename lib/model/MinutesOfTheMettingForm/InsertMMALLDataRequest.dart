import 'dart:convert';

InsertMMALLDataRequest InsertMMALLDataRequestFromJson(String str) =>
    InsertMMALLDataRequest.fromJson(json.decode(str));

String InsertMMALLDataRequestToJson(InsertMMALLDataRequest data) =>
    json.encode(data.toJson());

class InsertMMALLDataRequest {
  String? date;
  String? time;
  String? subject;
  String? memberPresent;
  String? memberAbsent;
  String? allRecordsIds;
  String? visitSrNo;
  String? custcode;

  InsertMMALLDataRequest(
      {this.date,
      this.time,
      this.subject,
      this.memberPresent,
      this.memberAbsent,
      this.allRecordsIds,
      this.visitSrNo,
      this.custcode});

  InsertMMALLDataRequest.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    time = json['time'];
    subject = json['subject'];
    memberPresent = json['memberPresent'];
    memberAbsent = json['memberAbsent'];
    allRecordsIds = json['allRecordsIds'];
    visitSrNo = json['visitSrNo'];
    custcode = json['custCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['time'] = this.time;
    data['subject'] = this.subject;
    data['memberPresent'] = this.memberPresent;
    data['memberAbsent'] = this.memberAbsent;
    data['allRecordsIds'] = this.allRecordsIds;
    data['visitSrNo'] = this.visitSrNo;
    data['custCode'] = this.custcode;
    return data;
  }
}

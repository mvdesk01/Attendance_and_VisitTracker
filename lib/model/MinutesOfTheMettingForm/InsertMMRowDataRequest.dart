import 'dart:convert';

InsertMMRowDataRequest InsertMMRowDataRequestFromJson(String str) =>
    InsertMMRowDataRequest.fromJson(json.decode(str));

String InsertMMRowDataRequestToJson(InsertMMRowDataRequest data) => json.encode(data.toJson());

class InsertMMRowDataRequest {
  String? pointsOrIssues;
  String? discussedWith;
  String? decisionTaken;
  String? responsibility;
  String? targetDate;
  String? statusOrRemark;
  String? nextDate;
  String? visitSrNo;

  InsertMMRowDataRequest(
      {this.pointsOrIssues,
        this.discussedWith,
        this.decisionTaken,
        this.responsibility,
        this.targetDate,
        this.statusOrRemark,
        this.nextDate,
        this.visitSrNo});

  InsertMMRowDataRequest.fromJson(Map<String, dynamic> json) {
    pointsOrIssues = json['pointsOrIssues'];
    discussedWith = json['discussedWith'];
    decisionTaken = json['decisionTaken'];
    responsibility = json['responsibility'];
    targetDate = json['targetDate'];
    statusOrRemark = json['statusOrRemark'];
    nextDate = json['nextDate'];
    visitSrNo = json['visitSrNo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pointsOrIssues'] = this.pointsOrIssues;
    data['discussedWith'] = this.discussedWith;
    data['decisionTaken'] = this.decisionTaken;
    data['responsibility'] = this.responsibility;
    data['targetDate'] = this.targetDate;
    data['statusOrRemark'] = this.statusOrRemark;
    data['nextDate'] = this.nextDate;
    data['visitSrNo'] = this.visitSrNo;
    return data;
  }
}
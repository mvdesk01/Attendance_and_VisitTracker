import 'dart:convert';

GetMinutesOfTheMeetingDataByVisitSrNoResponse GetMinutesOfTheMeetingDataByVisitSrNoResponseFromJson(String str) =>
    GetMinutesOfTheMeetingDataByVisitSrNoResponse.fromJson(json.decode(str));

String GetMinutesOfTheMeetingDataByVisitSrNoResponseToJson(GetMinutesOfTheMeetingDataByVisitSrNoResponse data) => json.encode(data.toJson());


class GetMinutesOfTheMeetingDataByVisitSrNoResponse {
  List<Message>? message;

  GetMinutesOfTheMeetingDataByVisitSrNoResponse({this.message});

  GetMinutesOfTheMeetingDataByVisitSrNoResponse.fromJson(
      Map<String, dynamic> json) {
    if (json['message'] != null) {
      message = <Message>[];
      json['message'].forEach((v) {
        message!.add(new Message.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Message {
  int? srNo;
  String? pointsOrIssues;
  String? disccussedwith;
  String? decisionTaken;
  String? responsibility;
  String? targateDate;
  String? statusOrRemark;
  String? nextDate;
  String? visitSrNo;

  Message(
      {this.srNo,
        this.pointsOrIssues,
        this.disccussedwith,
        this.decisionTaken,
        this.responsibility,
        this.targateDate,
        this.statusOrRemark,
        this.nextDate,
        this.visitSrNo});

  Message.fromJson(Map<String, dynamic> json) {
    srNo = json['srNo'];
    pointsOrIssues = json['pointsOrIssues'];
    disccussedwith = json['disccussedwith'];
    decisionTaken = json['decisionTaken'];
    responsibility = json['responsibility'];
    targateDate = json['targateDate'];
    statusOrRemark = json['statusOrRemark'];
    nextDate = json['nextDate'];
    visitSrNo = json['visitSrNo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['srNo'] = this.srNo;
    data['pointsOrIssues'] = this.pointsOrIssues;
    data['disccussedwith'] = this.disccussedwith;
    data['decisionTaken'] = this.decisionTaken;
    data['responsibility'] = this.responsibility;
    data['targateDate'] = this.targateDate;
    data['statusOrRemark'] = this.statusOrRemark;
    data['nextDate'] = this.nextDate;
    data['visitSrNo'] = this.visitSrNo;
    return data;
  }
}
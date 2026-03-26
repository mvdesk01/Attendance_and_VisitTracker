import 'dart:convert';

GetMinutesOfTheMeetingAllDataByVisitSrNoResponse GetMinutesOfTheMeetingAllDataByVisitSrNoResponseFromJson(String str) =>
    GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(json.decode(str));

String GetMinutesOfTheMeetingAllDataByVisitSrNoResponseToJson(GetMinutesOfTheMeetingAllDataByVisitSrNoResponse data) => json.encode(data.toJson());


class GetMinutesOfTheMeetingAllDataByVisitSrNoResponse {
  List<Message>? message;

  GetMinutesOfTheMeetingAllDataByVisitSrNoResponse({this.message});

  GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(
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
  String? date;
  String? time;
  String? subject;
  String? memberPresent;
  String? memberAbsent;
  String? allrecordIds;
  String? visitSrNo;

  Message(
      {this.srNo,
        this.date,
        this.time,
        this.subject,
        this.memberPresent,
        this.memberAbsent,
        this.allrecordIds,
        this.visitSrNo});

  Message.fromJson(Map<String, dynamic> json) {
    srNo = json['srNo'];
    date = json['date'];
    time = json['time'];
    subject = json['subject'];
    memberPresent = json['memberPresent'];
    memberAbsent = json['memberAbsent'];
    allrecordIds = json['allrecordIds'];
    visitSrNo = json['visitSrNo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['srNo'] = this.srNo;
    data['date'] = this.date;
    data['time'] = this.time;
    data['subject'] = this.subject;
    data['memberPresent'] = this.memberPresent;
    data['memberAbsent'] = this.memberAbsent;
    data['allrecordIds'] = this.allrecordIds;
    data['visitSrNo'] = this.visitSrNo;
    return data;
  }
}
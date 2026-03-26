import 'dart:convert';

GetMinutesOfMeetingFormNoResponse GetMinutesOfMeetingFormNoResponseFromJson(String str) =>
    GetMinutesOfMeetingFormNoResponse.fromJson(json.decode(str));

String GetMinutesOfMeetingFormNoResponseToJson(GetMinutesOfMeetingFormNoResponse data) => json.encode(data.toJson());

class GetMinutesOfMeetingFormNoResponse {
  Message? message;

  GetMinutesOfMeetingFormNoResponse({this.message});

  GetMinutesOfMeetingFormNoResponse.fromJson(Map<String, dynamic> json) {
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
  String? userId;
  int? srNo;
  String? minutesofMeetFormNo;

  Message({this.userId, this.srNo, this.minutesofMeetFormNo});

  Message.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    srNo = json['srNo'];
    minutesofMeetFormNo = json['minutesofMeetFormNo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['srNo'] = this.srNo;
    data['minutesofMeetFormNo'] = this.minutesofMeetFormNo;
    return data;
  }
}
// import 'dart:convert';
//
// GetMinutesOfTheMeetingAllDataByVisitSrNoResponse
//     GetMinutesOfTheMeetingAllDataByVisitSrNoResponseFromJson(String str) =>
//         GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(
//             json.decode(str));
//
// String GetMinutesOfTheMeetingAllDataByVisitSrNoResponseToJson(
//         GetMinutesOfTheMeetingAllDataByVisitSrNoResponse data) =>
//     json.encode(data.toJson());
//
// class GetMinutesOfTheMeetingAllDataByVisitSrNoResponse {
//   List<Message>? message;
//
//   GetMinutesOfTheMeetingAllDataByVisitSrNoResponse({this.message});
//
//   GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(
//       Map<String, dynamic> json) {
//     if (json['message'] != null) {
//       message = <Message>[];
//       json['message'].forEach((v) {
//         message!.add(new Message.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.message != null) {
//       data['message'] = this.message!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Message {
//   int? srNo;
//   String? date;
//   String? time;
//   String? subject;
//   String? memberPresent;
//   String? memberAbsent;
//   String? allrecordIds;
//   String? visitSrNo;
//   String? custCode;
//
//   Message(
//       {this.srNo,
//       this.date,
//       this.time,
//       this.subject,
//       this.memberPresent,
//       this.memberAbsent,
//       this.allrecordIds,
//       this.visitSrNo,
//       this.custCode});
//
//   Message.fromJson(Map<String, dynamic> json) {
//     srNo = json['srNo'];
//     date = json['date'];
//     time = json['time'];
//     subject = json['subject'];
//     memberPresent = json['memberPresent'];
//     memberAbsent = json['memberAbsent'];
//     allrecordIds = json['allrecordIds'];
//     visitSrNo = json['visitSrNo'];
//     custCode = json['custCode'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['srNo'] = this.srNo;
//     data['date'] = this.date;
//     data['time'] = this.time;
//     data['subject'] = this.subject;
//     data['memberPresent'] = this.memberPresent;
//     data['memberAbsent'] = this.memberAbsent;
//     data['allrecordIds'] = this.allrecordIds;
//     data['visitSrNo'] = this.visitSrNo;
//     data['custCode'] = this.custCode;
//     return data;
//   }
// }
class GetMinutesOfTheMeetingAllDataByVisitSrNoResponse {
  bool? status;
  String? message;
  List<MeetingWrapper>? data;

  GetMinutesOfTheMeetingAllDataByVisitSrNoResponse({
    this.status,
    this.message,
    this.data,
  });

  factory GetMinutesOfTheMeetingAllDataByVisitSrNoResponse.fromJson(
      Map<String, dynamic> json) {
    return GetMinutesOfTheMeetingAllDataByVisitSrNoResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<MeetingWrapper>.from(
              json['data'].map((x) => MeetingWrapper.fromJson(x)))
          : [],
    );
  }
}

class MeetingWrapper {
  MeetingData? meetingData;
  String? customerName;

  MeetingWrapper({this.meetingData, this.customerName});

  factory MeetingWrapper.fromJson(Map<String, dynamic> json) {
    return MeetingWrapper(
      meetingData: json['meetingData'] != null
          ? MeetingData.fromJson(json['meetingData'])
          : null,
      customerName: json['customerName'],
    );
  }
}

class MeetingData {
  int? srNo;
  String? date;
  String? time;
  String? subject;
  String? memberPresent;
  String? memberAbsent;
  String? allrecordIds;
  String? visitSrNo;
  String? custCode;

  MeetingData({
    this.srNo,
    this.date,
    this.time,
    this.subject,
    this.memberPresent,
    this.memberAbsent,
    this.allrecordIds,
    this.visitSrNo,
    this.custCode,
  });

  factory MeetingData.fromJson(Map<String, dynamic> json) {
    return MeetingData(
      srNo: json['srNo'],
      date: json['date'],
      time: json['time'],
      subject: json['subject'],
      memberPresent: json['memberPresent'],
      memberAbsent: json['memberAbsent'],
      allrecordIds: json['allrecordIds'],
      visitSrNo: json['visitSrNo'],
      custCode: json['custCode'],
    );
  }
}

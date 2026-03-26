import 'dart:convert';

GetCoffsTransactionsResponse GetCoffsTransactionsResponseFromJson(String str) => GetCoffsTransactionsResponse.fromJson(json.decode(str));

String GetCoffsTransactionsResponseToJson(GetCoffsTransactionsResponse data) => json.encode(data.toJson());





class GetCoffsTransactionsResponse {
  List<Message>? message;

  GetCoffsTransactionsResponse({this.message});

  GetCoffsTransactionsResponse.fromJson(Map<String, dynamic> json) {
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
  int? cOffId;
  String? staffCode;
  String? name;
  String? cOffDate;
  String? fromTime;
  String? toTime;

  Message(
      {this.cOffId,
        this.staffCode,
        this.name,
        this.cOffDate,
        this.fromTime,
        this.toTime});

  Message.fromJson(Map<String, dynamic> json) {
    cOffId = json['cOffId'];
    staffCode = json['staffCode'];
    name = json['name'];
    cOffDate = json['cOffDate'];
    fromTime = json['fromTime'];
    toTime = json['toTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cOffId'] = this.cOffId;
    data['staffCode'] = this.staffCode;
    data['name'] = this.name;
    data['cOffDate'] = this.cOffDate;
    data['fromTime'] = this.fromTime;
    data['toTime'] = this.toTime;
    return data;
  }
}
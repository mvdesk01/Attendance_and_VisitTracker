import 'dart:convert';

FetchCoffTransactionsResponse FetchCoffTransactionsResponseFromJson(String str) => FetchCoffTransactionsResponse.fromJson(json.decode(str));

String FetchCoffTransactionsResponseToJson(FetchCoffTransactionsResponse data) => json.encode(data.toJson());

class FetchCoffTransactionsResponse {
  List<Message>? message;

  FetchCoffTransactionsResponse({this.message});

  FetchCoffTransactionsResponse.fromJson(Map<String, dynamic> json) {
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
  String? otwofFid;
  String? staff;
  String? type;
  String? otDate;
  String? ttlHrs;

  Message({this.otwofFid, this.staff, this.type, this.otDate, this.ttlHrs});

  Message.fromJson(Map<String, dynamic> json) {
    otwofFid = json['otwofFid'];
    staff = json['staff'];
    type = json['type'];
    otDate = json['otDate'];
    ttlHrs = json['ttlHrs'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['otwofFid'] = this.otwofFid;
    data['staff'] = this.staff;
    data['type'] = this.type;
    data['otDate'] = this.otDate;
    data['ttlHrs'] = this.ttlHrs;
    return data;
  }
}
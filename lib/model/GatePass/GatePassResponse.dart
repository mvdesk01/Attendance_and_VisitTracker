import 'dart:convert';

GatePassResponse GatePassResponseFromJson(String str) =>
    GatePassResponse.fromJson(json.decode(str));

String GatePassResponseToJson(GatePassResponse data) => json.encode(data.toJson());

class GatePassResponse {
  List<Message>? message;

  GatePassResponse({this.message});

  GatePassResponse.fromJson(Map<String, dynamic> json) {
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
  int? transactionId;
  String? gatePassDate;
  String? staffCode;
  String? name;
  String? type;
  String? fromTime;
  String? toTime;
  String? customerName;

  Message(
      {this.transactionId,
        this.gatePassDate,
        this.staffCode,
        this.name,
        this.type,
        this.fromTime,
        this.toTime,
        this.customerName});

  Message.fromJson(Map<String, dynamic> json) {
    transactionId = json['transactionId'];
    gatePassDate = json['gatePassDate'];
    staffCode = json['staffCode'];
    name = json['name'];
    type = json['type'];
    fromTime = json['fromTime'];
    toTime = json['toTime'];
    customerName = json['customerName'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transactionId'] = this.transactionId;
    data['gatePassDate'] = this.gatePassDate;
    data['staffCode'] = this.staffCode;
    data['name'] = this.name;
    data['type'] = this.type;
    data['fromTime'] = this.fromTime;
    data['toTime'] = this.toTime;
    data['customerName'] = this.customerName;
    return data;
  }
}
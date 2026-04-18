import 'dart:convert';

VisitDetailedRecordsResponse VisitDetailedRecordsResponseFromJson(String str) =>
    VisitDetailedRecordsResponse.fromJson(json.decode(str));

String VisitDetailedRecordsResponseToJson(VisitDetailedRecordsResponse data) =>
    json.encode(data.toJson());

class VisitDetailedRecordsResponse {
  List<Message>? message;

  VisitDetailedRecordsResponse({this.message});

  VisitDetailedRecordsResponse.fromJson(Map<String, dynamic> json) {
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
  String? transactionDate;
  String? transactionTime;
  String? latitude;
  String? longitude;
  String? staffCode;
  String? deviceId;
  String? uuidid;
  int? process;
  String? actualDate;
  String? actualTime;
  String? address;
  String? speed;
  String? distance;
  String? srNoVo;
  String? status;
  String? distanceInkmMeter;
  String? gpsCheckFlag;
  String? batteryPercentage;

  Message(
      {this.transactionId,
        this.transactionDate,
        this.transactionTime,
        this.latitude,
        this.longitude,
        this.staffCode,
        this.deviceId,
        this.uuidid,
        this.process,
        this.actualDate,
        this.actualTime,
        this.address,
        this.speed,
        this.distance,
        this.srNoVo,
        this.status,
        this.distanceInkmMeter,
        this.gpsCheckFlag,
        this.batteryPercentage});

  Message.fromJson(Map<String, dynamic> json) {
    transactionId = json['transactionId'];
    transactionDate = json['transactionDate'];
    transactionTime = json['transactionTime'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    staffCode = json['staffCode'];
    deviceId = json['deviceId'];
    uuidid = json['uuidid'];
    process = json['process'];
    actualDate = json['actualDate'];
    actualTime = json['actualTime'];
    address = json['address'];
    speed = json['speed'];
    distance = json['distance'];
    srNoVo = json['srNoVo'];
    status = json['status'];
    distanceInkmMeter = json['distanceInkmMeter'];
    gpsCheckFlag = json['gpsCheckFlag'];
    batteryPercentage = json['batteryPercentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transactionId'] = this.transactionId;
    data['transactionDate'] = this.transactionDate;
    data['transactionTime'] = this.transactionTime;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['staffCode'] = this.staffCode;
    data['deviceId'] = this.deviceId;
    data['uuidid'] = this.uuidid;
    data['process'] = this.process;
    data['actualDate'] = this.actualDate;
    data['actualTime'] = this.actualTime;
    data['address'] = this.address;
    data['speed'] = this.speed;
    data['distance'] = this.distance;
    data['srNoVo'] = this.srNoVo;
    data['status'] = this.status;
    data['distanceInkmMeter'] = this.distanceInkmMeter;
    data['gpsCheckFlag'] = this.gpsCheckFlag;
    data['batteryPercentage'] = this.batteryPercentage;
    return data;
  }
}

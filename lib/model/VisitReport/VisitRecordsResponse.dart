import 'dart:convert';

VisitRecordsResponse VisitRecordsResponseFromJson(String str) => VisitRecordsResponse.fromJson(json.decode(str));

String VisitRecordsResponseToJson(VisitRecordsResponse data) => json.encode(data.toJson());
class VisitRecordsResponse {
  int? totalCount;
  int? pageNumber;
  int? pageSize;
  List<Data>? data;

  VisitRecordsResponse(
      {this.totalCount, this.pageNumber, this.pageSize, this.data});

  VisitRecordsResponse.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    pageNumber = json['pageNumber'];
    pageSize = json['pageSize'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    data['pageNumber'] = this.pageNumber;
    data['pageSize'] = this.pageSize;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? srNo;
  String? userId;
  String? selectDate;
  String? fromtime;
  String? totime;
  String? reason;
  String? destination;
  String? latitude;
  String? longitude;
  String? startingLat;
  String? startingLong;
  String? status;
  String? stopLat;
  String? stopLon;
  String? source;
  String? visitDate;
  String? mettingMom;
  String? minutesofMeetFormNo;

  Data(
      {this.srNo,
        this.userId,
        this.selectDate,
        this.fromtime,
        this.totime,
        this.reason,
        this.destination,
        this.latitude,
        this.longitude,
        this.startingLat,
        this.startingLong,
        this.status,
        this.stopLat,
        this.stopLon,
        this.source,
        this.visitDate,
        this.mettingMom,
        this.minutesofMeetFormNo});

  Data.fromJson(Map<String, dynamic> json) {
    srNo = json['srNo'];
    userId = json['userId'];
    selectDate = json['selectDate'];
    fromtime = json['fromtime'];
    totime = json['totime'];
    reason = json['reason'];
    destination = json['destination'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    startingLat = json['startingLat'];
    startingLong = json['startingLong'];
    status = json['status'];
    stopLat = json['stopLat'];
    stopLon = json['stopLon'];
    source = json['source'];
    visitDate = json['visitDate'];
    mettingMom = json['mettingMom'];
    minutesofMeetFormNo = json['minutesofMeetFormNo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['srNo'] = this.srNo;
    data['userId'] = this.userId;
    data['selectDate'] = this.selectDate;
    data['fromtime'] = this.fromtime;
    data['totime'] = this.totime;
    data['reason'] = this.reason;
    data['destination'] = this.destination;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['startingLat'] = this.startingLat;
    data['startingLong'] = this.startingLong;
    data['status'] = this.status;
    data['stopLat'] = this.stopLat;
    data['stopLon'] = this.stopLon;
    data['source'] = this.source;
    data['visitDate'] = this.visitDate;
    data['mettingMom'] = this.mettingMom;
    data['minutesofMeetFormNo'] = this.minutesofMeetFormNo;
    return data;
  }
}


class FetchVisitDetailsBySrNo {
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

  FetchVisitDetailsBySrNo(
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

  FetchVisitDetailsBySrNo.fromJson(Map<String, dynamic> json) {
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

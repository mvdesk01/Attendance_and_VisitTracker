import 'dart:convert';

VisitLatLongListResponse VisitLatLongListResponseFromJson(String str) => VisitLatLongListResponse.fromJson(json.decode(str));

String VisitLatLongListResponseToJson(VisitLatLongListResponse data) => json.encode(data.toJson());

class VisitLatLongListResponse {
  List<LatLongList>? message;

  VisitLatLongListResponse({this.message});

  VisitLatLongListResponse.fromJson(Map<String, dynamic> json) {
    if (json['message'] != null) {
      message = <LatLongList>[];
      json['message'].forEach((v) {
        message!.add(new LatLongList.fromJson(v));
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

class LatLongList {
  String? latitude;
  String? longitude;

  LatLongList({this.latitude, this.longitude});

  LatLongList.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    return data;
  }
}


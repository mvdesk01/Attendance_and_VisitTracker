import 'dart:convert';

CancelGatepassResponse CancelGatepassResponseFromJson(String str) => CancelGatepassResponse.fromJson(json.decode(str));

String CancelGatepassResponseToJson(CancelGatepassResponse data) => json.encode(data.toJson());


class CancelGatepassResponse {
  String? message;

  CancelGatepassResponse({this.message});

  CancelGatepassResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    return data;
  }
}
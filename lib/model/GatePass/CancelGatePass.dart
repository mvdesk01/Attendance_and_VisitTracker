import 'dart:convert';

CancelGatepassRequest cancelGatepassRequestFromJson(String str) => CancelGatepassRequest.fromJson(json.decode(str));

String cancelGatepassRequestToJson(CancelGatepassRequest data) => json.encode(data.toJson());


class CancelGatepassRequest {
  String? staffCode;
  String? transactionId;
  String? appFlag;

  CancelGatepassRequest({this.staffCode, this.transactionId, this.appFlag});

  CancelGatepassRequest.fromJson(Map<String, dynamic> json) {
    staffCode = json['staffCode'];
    transactionId = json['transactionId'];
    appFlag = json['appFlag'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['staffCode'] = this.staffCode;
    data['transactionId'] = this.transactionId;
    data['appFlag'] = this.appFlag;
    return data;
  }
}
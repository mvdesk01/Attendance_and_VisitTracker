import 'dart:convert';

CancelLeaveBody requestBodyFromJson(String str) =>
    CancelLeaveBody.fromJson(json.decode(str));

String requestBodyToJson(CancelLeaveBody data) =>
    json.encode(data.toJson());

class CancelLeaveBody {
  String? flag;
  String? tid;
  String? rReason;
  String? staffcode;

  CancelLeaveBody({this.flag, this.tid, this.rReason, this.staffcode});

  CancelLeaveBody.fromJson(Map<String, dynamic> json) {
    flag = json['flag'];
    tid = json['tid'];
    rReason = json['rReason'];
    staffcode = json['staffcode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['flag'] = this.flag;
    data['tid'] = this.tid;
    data['rReason'] = this.rReason;
    data['staffcode'] = this.staffcode;
    return data;
  }
}

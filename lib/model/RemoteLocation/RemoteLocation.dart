import 'dart:convert';

RemoteLocationResponse remoteLocationResponseFromJson(String str) =>
    RemoteLocationResponse.fromJson(json.decode(str));

String remoteLocationResponseToJson(RemoteLocationResponse data) =>
    json.encode(data.toJson());

class RemoteLocationResponse {
  String? staffCode;
  String? approvedFlag;
  String? remoteLocation;
  String? remoteLatitude;
  String? remoteLongitude;

  RemoteLocationResponse({
    this.staffCode,
    this.approvedFlag,
    this.remoteLocation,
    this.remoteLatitude,
    this.remoteLongitude,
  });

  RemoteLocationResponse.fromJson(Map<String, dynamic> json) {
    staffCode = json['staffcode'];
    approvedFlag = json['approvedflag'];
    remoteLocation = json['remotelocation'];
    remoteLatitude = json['remotelatitude'];
    remoteLongitude = json['remotelongitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['staffcode'] = staffCode;
    data['approvedflag'] = approvedFlag;
    data['remotelocation'] = remoteLocation;
    data['remotelatitude'] = remoteLatitude;
    data['remotelongitude'] = remoteLongitude;
    return data;
  }
}

import 'dart:convert';

ProfileResponse profileResponseFromJson(String str) =>
    ProfileResponse.fromJson(json.decode(str));

String profileResponseToJson(ProfileResponse data) =>
    json.encode(data.toJson());

class ProfileResponse {
  Message? message;

  ProfileResponse({this.message});

  ProfileResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'] != null ? Message.fromJson(json['message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    return data;
  }
}

class Message {
  int? srno;
  String? staffCode;
  String? displayName;
  String? emailId;
  String? password;
  String? mobileNo;
  String? createdOn;
  String? createdBy;
  String? latitude;
  String? longitude;
  String? currAddress;
  String? uuid;
  String? userType;
  String? modifiedOn;
  String? modifiedby;
  String? deptCode;
  String? deptName;
  String? uniqueNumber;
  String? addressapproveFlag;
  String? newRemoteLocation;
  String? remoteLatitude;
  String? remoteLongitude;
  String? distanceCheckFlag;
  String? profilePic;
  String? atsCheckflag;
  String? plantCode;

  Message({
    this.srno,
    this.staffCode,
    this.displayName,
    this.emailId,
    this.password,
    this.mobileNo,
    this.createdOn,
    this.createdBy,
    this.latitude,
    this.longitude,
    this.currAddress,
    this.uuid,
    this.userType,
    this.modifiedOn,
    this.modifiedby,
    this.deptCode,
    this.deptName,
    this.uniqueNumber,
    this.addressapproveFlag,
    this.newRemoteLocation,
    this.remoteLatitude,
    this.remoteLongitude,
    this.distanceCheckFlag,
    this.profilePic,
    this.atsCheckflag,
    this.plantCode
  });

  Message.fromJson(Map<String, dynamic> json) {
    srno = json['srno'];
    staffCode = json['staffCode'];
    displayName = json['displayName'];
    emailId = json['emailId'];
    password = json['password'];
    mobileNo = json['mobileNo'];
    createdOn = json['createdOn'];
    createdBy = json['createdBy'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    currAddress = json['currAddress'];
    uuid = json['uuid'];
    userType = json['userType'];
    modifiedOn = json['modifiedOn'];
    modifiedby = json['modifiedby'];
    deptCode = json['deptCode'];
    deptName = json['deptName'];
    uniqueNumber = json['uniqueNumber'];
    addressapproveFlag = json['addressapproveFlag'];
    newRemoteLocation = json['newRemoteLocation'];
    remoteLatitude = json['remoteLatitude'];
    remoteLongitude = json['remoteLongitude'];
    distanceCheckFlag = json['distanceCheckFlag'];
    profilePic = json['profilePic'];
    atsCheckflag = json['atsCheckFlag'];
    plantCode = json['plantCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['srno'] = this.srno;
    data['staffCode'] = this.staffCode;
    data['displayName'] = this.displayName;
    data['emailId'] = this.emailId;
    data['password'] = this.password;
    data['mobileNo'] = this.mobileNo;
    data['createdOn'] = this.createdOn;
    data['createdBy'] = this.createdBy;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['currAddress'] = this.currAddress;
    data['uuid'] = this.uuid;
    data['userType'] = this.userType;
    data['modifiedOn'] = this.modifiedOn;
    data['modifiedby'] = this.modifiedby;
    data['deptCode'] = this.deptCode;
    data['deptName'] = this.deptName;
    data['uniqueNumber'] = this.uniqueNumber;
    data['addressapproveFlag'] = this.addressapproveFlag;
    data['newRemoteLocation'] = this.newRemoteLocation;
    data['remoteLatitude'] = this.remoteLatitude;
    data['remoteLongitude'] = this.remoteLongitude;
    data['distanceCheckFlag'] = this.distanceCheckFlag;
    data['profilePic'] = this.profilePic;
    data['atsCheckFlag'] = this.atsCheckflag;
    data['plantCode'] = this.plantCode;
    return data;
  }
}

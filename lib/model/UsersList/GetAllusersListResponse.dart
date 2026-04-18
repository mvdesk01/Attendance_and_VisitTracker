import 'dart:convert';

import 'SearchbystaffcodeResponse.dart';

GetAllusersListResponse GetAllusersListResponseFromJson(String str) =>
    GetAllusersListResponse.fromJson(json.decode(str));

String GetAllusersListResponseToJson(GetAllusersListResponse data) =>
    json.encode(data.toJson());

class GetAllusersListResponse {
  bool? status;
  int? totalcount;
  String? message;
  List<Message>? data;

  GetAllusersListResponse(
      {this.status, this.totalcount, this.message, this.data});

  GetAllusersListResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    totalcount = json['totalCount'];
    message = json['message'];

    if (json['data'] != null) {
      data = <Message>[];
      json['data'].forEach((v) {
        data!.add(Message.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataMap = {};

    dataMap['status'] = status;
    dataMap['totalCount'] = totalcount;
    dataMap['message'] = message;

    if (data != null) {
      dataMap['data'] = data!.map((v) => v.toJson()).toList();
    }

    return dataMap;
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
  String? isDeletedFlag;

  Message(
      {this.srno,
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
        this.isDeletedFlag});

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
    isDeletedFlag = json['isDeletedFlag'];
  }

  factory Message.fromUserData(UserData e) {
    return Message(
      staffCode: e.staffCode,
      displayName: e.displayName,
      mobileNo: e.mobileNo,
      emailId: e.emailId,
      isDeletedFlag: e.isDeletedFlag,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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
    data['isDeletedFlag'] = this.isDeletedFlag;
    return data;
  }
}

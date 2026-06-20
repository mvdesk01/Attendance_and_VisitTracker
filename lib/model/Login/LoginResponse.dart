
import 'dart:convert';

LoginResponse? loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  Message? message;
  Token? token;

  LoginResponse({this.message, this.token});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    message =
    json['message'] != null ? new Message.fromJson(json['message']) : null;
    token = json['token'] != null ? new Token.fromJson(json['token']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    if (this.token != null) {
      data['token'] = this.token!.toJson();
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
  String? plantCode;

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
    plantCode = json['plantCode'];
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
    data['plantCode'] = this.plantCode;
    return data;
  }
}

class Token {
  Result? result;
  int? id;
  String? exception;
  int? status;
  bool? isCanceled;
  bool? isCompleted;
  bool? isCompletedSuccessfully;
  int? creationOptions;
  String? asyncState;
  bool? isFaulted;

  Token(
      {this.result,
        this.id,
        this.exception,
        this.status,
        this.isCanceled,
        this.isCompleted,
        this.isCompletedSuccessfully,
        this.creationOptions,
        this.asyncState,
        this.isFaulted});

  Token.fromJson(Map<String, dynamic> json) {
    result =
    json['result'] != null ? new Result.fromJson(json['result']) : null;
    id = json['id'];
    exception = json['exception'];
    status = json['status'];
    isCanceled = json['isCanceled'];
    isCompleted = json['isCompleted'];
    isCompletedSuccessfully = json['isCompletedSuccessfully'];
    creationOptions = json['creationOptions'];
    asyncState = json['asyncState'];
    isFaulted = json['isFaulted'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result!.toJson();
    }
    data['id'] = this.id;
    data['exception'] = this.exception;
    data['status'] = this.status;
    data['isCanceled'] = this.isCanceled;
    data['isCompleted'] = this.isCompleted;
    data['isCompletedSuccessfully'] = this.isCompletedSuccessfully;
    data['creationOptions'] = this.creationOptions;
    data['asyncState'] = this.asyncState;
    data['isFaulted'] = this.isFaulted;
    return data;
  }
}

class Result {
  String? token;

  Result({this.token});

  Result.fromJson(Map<String, dynamic> json) {
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['token'] = this.token;
    return data;
  }
}

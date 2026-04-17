class UserResponse {
  final bool status;
  final String message;
  final List<UserData> data;

  UserResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? List<UserData>.from(json['data'].map((x) => UserData.fromJson(x)))
          : [], // ✅ IMPORTANT FIX
    );
  }
}

class UserData {
  final int srno;
  final String staffCode;
  final String displayName;
  final String emailId;
  final String password;
  final String mobileNo;
  final String createdOn;
  final String createdBy;
  final String latitude;
  final String longitude;
  final String currAddress;
  final String uuid;
  final String userType;

  final String? modifiedOn;
  final String? modifiedby;
  final String? deptCode;
  final String? deptName;
  final String? uniqueNumber;
  final String? addressapproveFlag;
  final String? newRemoteLocation;
  final String? remoteLatitude;
  final String? remoteLongitude;
  final String? distanceCheckFlag;
  final String? profilePic;
  final String? uuidFlag;
  final String? atsCheckFlag;
  final String? plantCode;
  final String? isDeletedFlag;

  UserData({
    required this.srno,
    required this.staffCode,
    required this.displayName,
    required this.emailId,
    required this.password,
    required this.mobileNo,
    required this.createdOn,
    required this.createdBy,
    required this.latitude,
    required this.longitude,
    required this.currAddress,
    required this.uuid,
    required this.userType,
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
    this.uuidFlag,
    this.atsCheckFlag,
    this.plantCode,
    this.isDeletedFlag,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      srno: json['srno'] ?? 0,
      staffCode: json['staffCode'] ?? '',
      displayName: json['displayName'] ?? '',
      emailId: json['emailId'] ?? '',
      password: (json['password'] ?? '').toString().trim(),
      mobileNo: json['mobileNo'] ?? '',
      createdOn: json['createdOn'] ?? '',
      createdBy: json['createdBy'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      currAddress: (json['currAddress'] ?? '').toString().trim(),
      uuid: json['uuid'] ?? '',
      userType: json['userType'] ?? '',
      modifiedOn: json['modifiedOn'],
      modifiedby: json['modifiedby'],
      deptCode: json['deptCode'],
      deptName: json['deptName'],
      uniqueNumber: json['uniqueNumber'],
      addressapproveFlag: json['addressapproveFlag'],
      newRemoteLocation: json['newRemoteLocation'],
      remoteLatitude: json['remoteLatitude'],
      remoteLongitude: json['remoteLongitude'],
      distanceCheckFlag: json['distanceCheckFlag'],
      profilePic: json['profilePic'],
      uuidFlag: json['uuidFlag'],
      atsCheckFlag: json['atsCheckFlag'],
      plantCode: json['plantCode'],
      isDeletedFlag: json['isDeletedFlag'],
    );
  }
}

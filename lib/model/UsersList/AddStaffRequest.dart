import 'dart:convert';

AddStaffRequest AddStaffRequestFromJson(String str) => AddStaffRequest.fromJson(json.decode(str));

String AddStaffRequestToJson(AddStaffRequest data) => json.encode(data.toJson());

class AddStaffRequest {
  String? staffCode;
  String? firstName;
  String? middleName;
  String? lastName;
  String? displayName;
  String? dateOfBirth;
  String? joiningDate;
  String? plantCode;

  AddStaffRequest(
      {this.staffCode,
        this.firstName,
        this.middleName,
        this.lastName,
        this.displayName,
        this.dateOfBirth,
        this.joiningDate,
        this.plantCode});

  AddStaffRequest.fromJson(Map<String, dynamic> json) {
    staffCode = json['staffCode'];
    firstName = json['firstName'];
    middleName = json['middleName'];
    lastName = json['lastName'];
    displayName = json['displayName'];
    dateOfBirth = json['dateOfBirth'];
    joiningDate = json['joiningDate'];
    plantCode = json['plantCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['staffCode'] = this.staffCode;
    data['firstName'] = this.firstName;
    data['middleName'] = this.middleName;
    data['lastName'] = this.lastName;
    data['displayName'] = this.displayName;
    data['dateOfBirth'] = this.dateOfBirth;
    data['joiningDate'] = this.joiningDate;
    data['plantCode'] = this.plantCode;
    return data;
  }
}
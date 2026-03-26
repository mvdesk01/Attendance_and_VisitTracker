import 'dart:convert';

GetStaffDetailsForCoffResponse GetStaffDetailsForCoffResponseFromJson(String str) => GetStaffDetailsForCoffResponse.fromJson(json.decode(str));

String GetStaffDetailsForCoffResponseToJson(GetStaffDetailsForCoffResponse data) => json.encode(data.toJson());



class GetStaffDetailsForCoffResponse {
  Message? message;

  GetStaffDetailsForCoffResponse({this.message});

  GetStaffDetailsForCoffResponse.fromJson(Map<String, dynamic> json) {
    message =
    json['message'] != null ? new Message.fromJson(json['message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    return data;
  }
}

class Message {
  String? name;
  String? department;
  String? designation;
  String? balanceHours;
  List<String>? shiftNames;

  Message(
      {this.name,
        this.department,
        this.designation,
        this.balanceHours,
        this.shiftNames});

  Message.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    department = json['department'];
    designation = json['designation'];
    balanceHours = json['balanceHours'];
    shiftNames = json['shiftNames'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['department'] = this.department;
    data['designation'] = this.designation;
    data['balanceHours'] = this.balanceHours;
    data['shiftNames'] = this.shiftNames;
    return data;
  }
}
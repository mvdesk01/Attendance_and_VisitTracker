import 'dart:convert';

Staffdetails StaffDetailsResponseFromJson(String str) =>
    Staffdetails.fromJson(json.decode(str));

String StaffDetailsResponseToJson(Staffdetails data) => json.encode(data.toJson());

class Staffdetails {
  Message? message;

  Staffdetails({this.message});

  Staffdetails.fromJson(Map<String, dynamic> json) {
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

class Message{
  String? staffCode;
  String? fullName;
  String? plantName;
  String? dateOfJoining;
  String? designantion;
  String? department;
  String? year;
  String? fromdate;
  String? toDate;
  String? category;
  String? gender;

  Message(
      this.staffCode,
      this.fullName,
      this.plantName,
      this.dateOfJoining,
      this.designantion,
      this.department,
      this.year,
      this.fromdate,
      this.toDate,
      this.category,
      this.gender);

  Message.fromJson(Map<String, dynamic> json){
    staffCode = json['staffCode'];
    fullName = json['fullName'];
    plantName = json['plantName'];
    dateOfJoining = json['dateofJoining'];
    designantion = json['designantion'];
    department = json['department'];
    year = json['year'];
    fromdate = json['fromdate'];
    toDate = json['toDate'];
    category = json['category'];
    gender = json['gender'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['staffCode'] = this.staffCode;
    data['fullName'] = this.fullName;
    data['plantName'] = this.plantName;
    data['dateofJoining'] = this.dateOfJoining;
    data['designantion'] = this.designantion;
    data['department'] = this.department;
    data['year'] = this.year;
    data['fromdate'] = this.fromdate;
    data['toDate'] = this.toDate;
    data['category'] = this.category;
    data['gender'] = this.gender;
    return data;
  }
}
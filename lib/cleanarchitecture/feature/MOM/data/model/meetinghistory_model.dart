import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/meetinghistory.dart';

///test
class MeetinghistoryModel extends MeetingHistory {
  const MeetinghistoryModel({
    required super.meetingId,
    required super.customer,
    required super.memberPresent,
    required super.memberAbsent,
    required super.meetingDate,
    required super.meetingTime,
    required super.nextMeetingDate,
    required super.point,
    required super.discussedWith,
    required super.decision,
    required super.responsibility,
    required super.targetDate,
    required super.status,
  });

  factory MeetinghistoryModel.fromJson(Map<String, dynamic> json) {
    return MeetinghistoryModel(
      meetingId: json['MeetingID'] ?? '',
      customer: json['Customer'] ?? '',
      memberPresent: json['MemberPresent'] ?? '',
      memberAbsent: json['MemberAbsent'] ?? '',
      meetingDate: json['MeetingDate'] ?? '',
      meetingTime: json['MeetingTime'] ?? '',
      nextMeetingDate: json['NextMeetingDate'] ?? '',
      point: json['Points'] ?? '',
      discussedWith: json['DiscussedWith'] ?? '',
      decision: json['Decision'] ?? '',
      responsibility: json['Responsibility'] ?? '',
      targetDate: json['TargetDate'] ?? '',
      status: json['Status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MeetingID': meetingId,
      'Customer': customer,
      'MemberPresent': memberPresent,
      'MemberAbsent': memberAbsent,
      'MeetingDate': meetingDate,
      'MeetingTime': meetingTime,
      'NextMeetingDate': nextMeetingDate,
      'Points': point,
      'DiscussedWith': discussedWith,
      'Decision': decision,
      'Responsibility': responsibility,
      'TargetDate': targetDate,
      'Status': status,
    };
  }

  factory MeetinghistoryModel.fromEntity(MeetingHistory history) {
    return MeetinghistoryModel(
      meetingId: history.meetingId,
      customer: history.customer,
      memberPresent: history.memberPresent,
      memberAbsent: history.memberAbsent,
      meetingDate: history.meetingDate,
      meetingTime: history.meetingTime,
      nextMeetingDate: history.nextMeetingDate,
      point: history.point,
      discussedWith: history.discussedWith,
      decision: history.decision,
      responsibility: history.responsibility,
      targetDate: history.targetDate,
      status: history.status,
    );
  }
}

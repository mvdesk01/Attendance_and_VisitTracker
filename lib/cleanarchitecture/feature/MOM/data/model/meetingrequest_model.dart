import '../../domain/enteties/meeting.dart';

class MeetingRequestModel extends Meeting {
  const MeetingRequestModel({
    required super.meetingId,
    required super.customerCode,
    required super.memberPresent,
    required super.memberAbsent,
    required super.meetingDateTime,
    required super.nextMeetingDate,
    required super.entryBy,
    required super.flag,
  });

  factory MeetingRequestModel.fromEntity(Meeting meeting) {
    return MeetingRequestModel(
      meetingId: meeting.meetingId,
      customerCode: meeting.customerCode,
      memberPresent: meeting.memberPresent,
      memberAbsent: meeting.memberAbsent,
      meetingDateTime: meeting.meetingDateTime,
      nextMeetingDate: meeting.nextMeetingDate,
      entryBy: meeting.entryBy,
      flag: meeting.flag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "MeetingID": meetingId,
      "CustomerCode": customerCode,
      "MemberPresent": memberPresent,
      "MemberAbsent": memberAbsent,
      "MeetingDateTime": meetingDateTime,
      "NextMeetingDate": nextMeetingDate,
      "EntryBy": entryBy,
      "Flag": flag,
    };
  }
}

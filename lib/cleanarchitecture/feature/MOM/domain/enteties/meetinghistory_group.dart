import 'meetinghistory.dart';

class MeetingHistoryGroup {
  final String meetingId;
  final String customer;
  final String memberPresent;
  final String memberAbsent;
  final String meetingDate;
  final String meetingTime;
  final String nextMeetingDate;

  final List<MeetingHistory> discussionPoints;

  const MeetingHistoryGroup({
    required this.meetingId,
    required this.customer,
    required this.memberPresent,
    required this.memberAbsent,
    required this.meetingDate,
    required this.meetingTime,
    required this.nextMeetingDate,
    required this.discussionPoints,
  });
}

///test

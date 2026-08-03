class MeetingHistory {
  final String meetingId;
  final String customer;
  final String memberPresent;
  final String memberAbsent;
  final String meetingDate;
  final String meetingTime;
  final String nextMeetingDate;

  final String point;
  final String discussedWith;
  final String decision;
  final String responsibility;
  final String targetDate;
  final String status;

  const MeetingHistory({
    required this.meetingId,
    required this.customer,
    required this.memberPresent,
    required this.memberAbsent,
    required this.meetingDate,
    required this.meetingTime,
    required this.nextMeetingDate,
    required this.point,
    required this.discussedWith,
    required this.decision,
    required this.responsibility,
    required this.targetDate,
    required this.status,
  });
}

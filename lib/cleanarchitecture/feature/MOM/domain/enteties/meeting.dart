class Meeting {
  final String meetingId;
  final String customerCode;
  final String memberPresent;
  final String memberAbsent;
  final String meetingDateTime;
  final String nextMeetingDate;
  final String entryBy;
  final String flag;

  const Meeting({
    required this.meetingId,
    required this.customerCode,
    required this.memberPresent,
    required this.memberAbsent,
    required this.meetingDateTime,
    required this.nextMeetingDate,
    required this.entryBy,
    required this.flag,
  });
}

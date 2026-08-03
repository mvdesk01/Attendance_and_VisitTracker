import 'meeting.dart';
import 'meetingpoints.dart';

class SubmitMeetingRequest {
  final Meeting meeting;

  final List<DiscussionPoint> discussionPoints;

  const SubmitMeetingRequest({
    required this.meeting,
    required this.discussionPoints,
  });
}

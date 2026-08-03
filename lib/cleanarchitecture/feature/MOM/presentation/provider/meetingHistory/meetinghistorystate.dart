import '../../../domain/enteties/meetinghistory_group.dart';

class MeetingHistoryState {
  final bool isLoading;
  final List<MeetingHistoryGroup> meetingHistory;
  final String? error;

  const MeetingHistoryState({
    this.isLoading = false,
    this.meetingHistory = const [],
    this.error,
  });

  MeetingHistoryState copyWith({
    bool? isLoading,
    List<MeetingHistoryGroup>? meetingHistory,
    String? error,
  }) {
    return MeetingHistoryState(
      isLoading: isLoading ?? this.isLoading,
      meetingHistory: meetingHistory ?? this.meetingHistory,
      error: error,
    );
  }
}

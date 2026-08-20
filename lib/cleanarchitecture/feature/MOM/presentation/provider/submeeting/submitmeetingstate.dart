import '../../../domain/enteties/submitmeeting_result.dart';

class MeetingSubmitState {
  final bool isLoading;
  final SubmitMeetingResult? result;
  final String? error;

  const MeetingSubmitState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  MeetingSubmitState copyWith({
    bool? isLoading,
    SubmitMeetingResult? result,
    String? error,
  }) {
    return MeetingSubmitState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
    );
  }
}

///test

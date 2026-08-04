import 'package:attendance_system_ios/cleanarchitecture/core/DI/providers_di.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/presentation/provider/meetingHistory/meetinghistorystate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meetinghistoryprovider.g.dart';

@riverpod
class MeetingHistoryNotifier extends _$MeetingHistoryNotifier {
  @override
  MeetingHistoryState build() {
    return const MeetingHistoryState();
  }

  Future<void> loadMeetingHistory({
    required String customerCode,
    required String meetingDate,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final history = await ref.read(getMeetinhHistoryCaseProvider).call(
            customerCode: customerCode,
            meetingDate: meetingDate,
          );

      state = state.copyWith(
        isLoading: false,
        meetingHistory: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

///test

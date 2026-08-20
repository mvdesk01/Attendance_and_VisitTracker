import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/presentation/provider/submeeting/submitmeetingstate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/DI/providers_di.dart';
import '../../../domain/enteties/submitmeeting_request.dart';

part 'submitmeetingprovider.g.dart';

@riverpod
class MeetingSubmitNotifier extends _$MeetingSubmitNotifier {
  @override
  MeetingSubmitState build() {
    return const MeetingSubmitState();
  }

  Future<void> submitMeeting(
    SubmitMeetingRequest request,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final result = await ref.read(submitMeetingUseCaseProvider).call(request);

      state = state.copyWith(
        isLoading: false,
        result: result,
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

import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/presentation/provider/submeeting/submitmeetingstate.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
      result: null,
    );

    try {
      final result = await ref.read(submitMeetingUseCaseProvider).call(request);

      state = state.copyWith(
        isLoading: false,
        result: result,
        error: null,
      );
    } catch (e, stack) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        result: null,
      );
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'submetting meeting MOM',
      );
    }
  }
}

///test

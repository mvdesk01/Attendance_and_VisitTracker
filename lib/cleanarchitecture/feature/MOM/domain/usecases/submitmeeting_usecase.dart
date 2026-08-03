import '../enteties/submitmeeting_request.dart';
import '../enteties/submitmeeting_result.dart';
import '../repositories/mom_repositories.dart';

class SubmitMeetingUseCase {
  final MomRepository repository;

  SubmitMeetingUseCase(this.repository);

  Future<SubmitMeetingResult> call(
    SubmitMeetingRequest request,
  ) {
    return repository.submitMeeting(request);
  }
}

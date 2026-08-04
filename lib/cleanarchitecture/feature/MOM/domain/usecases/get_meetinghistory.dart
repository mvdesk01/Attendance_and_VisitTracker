import '../enteties/meetinghistory_group.dart';
import '../repositories/mom_repositories.dart';

class GetMeetinghistoryUseCase {
  final MomRepository repository;

  GetMeetinghistoryUseCase(this.repository);

  Future<List<MeetingHistoryGroup>> call({
    required String customerCode,
    required String meetingDate,
  }) {
    return repository.getMeetingHistory(
      customerCode: customerCode,
      meetingDate: meetingDate,
    );
  }
}

///test

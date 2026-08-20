import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/decision.dart';

import '../repositories/mom_repositories.dart';

class GetDecisionUseCase {
  final MomRepository repository;

  GetDecisionUseCase(this.repository);

  Future<List<Decision>> call({
    required String userName,
    bool forceRefresh = false,
  }) {
    return repository.getDecisions(
      userName: userName,
      forceRefresh: forceRefresh,
    );
  }
}

///test

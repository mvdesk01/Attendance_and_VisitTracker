import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

import '../repositories/mom_repositories.dart';

class GetResponsibilityUseCase {
  final MomRepository repository;

  GetResponsibilityUseCase(this.repository);

  Future<List<Responsibility>> call({
    required String userName,
    bool forceRefresh = false,
  }) {
    return repository.getResponsibility(
      userName: userName,
      forceRefresh: forceRefresh,
    );
  }
}

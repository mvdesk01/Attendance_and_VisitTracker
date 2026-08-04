import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

import '../repositories/mom_repositories.dart';

class GetSelectedResponsibilityUseCase {
  final MomRepository repository;

  GetSelectedResponsibilityUseCase(this.repository);

  Future<Responsibility?> call() {
    return repository.getSelectedResponsibility();
  }
}

///test

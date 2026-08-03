import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

import '../repositories/mom_repositories.dart';

class SaveSelectedResponsibilityUseCase {
  final MomRepository repository;

  SaveSelectedResponsibilityUseCase(this.repository);

  Future<void> call(Responsibility responsibility) {
    return repository.saveSelectedResponsibility(responsibility);
  }
}

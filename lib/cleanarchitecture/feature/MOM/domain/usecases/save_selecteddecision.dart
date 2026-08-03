import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/decision.dart';

import '../repositories/mom_repositories.dart';

class SaveSelecteddecisionUseCase {
  final MomRepository repository;

  SaveSelecteddecisionUseCase(this.repository);

  Future<void> call(Decision decision) {
    return repository.saveSelectedDecision(decision);
  }
}

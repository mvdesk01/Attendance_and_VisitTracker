import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/decision.dart';

import '../repositories/mom_repositories.dart';

class GetSelecteddecisionUseCase {
  final MomRepository repository;

  GetSelecteddecisionUseCase(this.repository);

  Future<Decision?> call() {
    return repository.getSelectedDecision();
  }
}

///test

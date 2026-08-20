import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/get_decision.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/get_meetinghistory.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/get_responsibility.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/get_selecteddecision.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/get_selectedresponsibility.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/save_selecteddecision.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/usecases/save_selectedresponsibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feature/MOM/data/datasource/mom_datasource_impl.dart';
import '../../feature/MOM/data/datasource/mom_local_datasource.dart';
import '../../feature/MOM/data/datasource/remote_datasource.dart';
import '../../feature/MOM/data/repositories/mom_repository_impl.dart';
import '../../feature/MOM/domain/repositories/mom_repositories.dart';
import '../../feature/MOM/domain/usecases/add_custom_decision.dart';
import '../../feature/MOM/domain/usecases/get_customername.dart';
import '../../feature/MOM/domain/usecases/get_selectedcustomer.dart';
import '../../feature/MOM/domain/usecases/save_selectedcustomer.dart';
import '../../feature/MOM/domain/usecases/submitmeeting_usecase.dart';

///test
final remoteDatasourceProvider = Provider<MomRemoteDatasource>((ref) {
  return MomRemoteDatasourceImpl();
});

final localDatasourceProvider = Provider<MomLocalDatasource>((ref) {
  return MomLocalDatasourceImpl();
});

final repositoryProvider = Provider<MomRepository>((ref) {
  return MomRepositoryImpl(
    remoteDatasource: ref.read(remoteDatasourceProvider),
    localDatasource: ref.read(localDatasourceProvider),
  );
});

final getCustomersUseCaseProvider = Provider<GetCustomersUseCase>((ref) {
  return GetCustomersUseCase(
    ref.read(repositoryProvider),
  );
});

final getSelectedCustomerUseCaseProvider =
    Provider<GetSelectedCustomerUseCase>((ref) {
  return GetSelectedCustomerUseCase(
    ref.read(repositoryProvider),
  );
});

final saveSelectedCustomerUseCaseProvider =
    Provider<SaveSelectedCustomerUseCase>((ref) {
  return SaveSelectedCustomerUseCase(
    ref.read(repositoryProvider),
  );
});

///decision
final getdecisionusecaseProvider = Provider<GetDecisionUseCase>((ref) {
  return GetDecisionUseCase(
    ref.read(repositoryProvider),
  );
});

final getselectedDecisionuseCaseProvider =
    Provider<GetSelecteddecisionUseCase>((ref) {
  return GetSelecteddecisionUseCase(
    ref.read(repositoryProvider),
  );
});

final saveselectedDecisionUseCaseProvider =
    Provider<SaveSelecteddecisionUseCase>((ref) {
  return SaveSelecteddecisionUseCase(
    ref.read(repositoryProvider),
  );
});

///responsibility

final getResponsibilityusecaseProvider =
    Provider<GetResponsibilityUseCase>((ref) {
  return GetResponsibilityUseCase(
    ref.read(repositoryProvider),
  );
});

final getselectedResponsibilityuseCaseProvider =
    Provider<GetSelectedResponsibilityUseCase>((ref) {
  return GetSelectedResponsibilityUseCase(
    ref.read(repositoryProvider),
  );
});

final saveSelectedResponsibilityUseCaseProvider =
    Provider<SaveSelectedResponsibilityUseCase>((ref) {
  return SaveSelectedResponsibilityUseCase(
    ref.read(repositoryProvider),
  );
});

///submitmeeting
final submitMeetingUseCaseProvider = Provider<SubmitMeetingUseCase>((ref) {
  return SubmitMeetingUseCase(
    ref.read(repositoryProvider),
  );
});

final getMeetinhHistoryCaseProvider = Provider<GetMeetinghistoryUseCase>((ref) {
  return GetMeetinghistoryUseCase(
    ref.read(repositoryProvider),
  );
});

final addcustomDecisionUseCaseProvider =
Provider<AddCustomDecisionUseCase>((ref) {
  return AddCustomDecisionUseCase(
    ref.read(repositoryProvider),
  );
});
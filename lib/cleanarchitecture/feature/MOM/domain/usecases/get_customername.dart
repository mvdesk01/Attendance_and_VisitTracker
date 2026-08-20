import '../enteties/customer.dart';
import '../repositories/mom_repositories.dart';

class GetCustomersUseCase {
  final MomRepository repository;

  GetCustomersUseCase(this.repository);

  Future<List<Customer>> call({
    required String userName,
    bool forceRefresh = false,
  }) {
    return repository.getCustomers(
      userName: userName,
      forceRefresh: forceRefresh,
    );
  }
}

///test

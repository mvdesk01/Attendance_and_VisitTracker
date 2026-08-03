import '../enteties/customer.dart';
import '../repositories/mom_repositories.dart';

class GetSelectedCustomerUseCase {
  final MomRepository repository;

  GetSelectedCustomerUseCase(this.repository);

  Future<Customer?> call() {
    return repository.getSelectedCustomer();
  }
}

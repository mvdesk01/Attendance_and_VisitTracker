import '../enteties/customer.dart';
import '../repositories/mom_repositories.dart';

class SaveSelectedCustomerUseCase {
  final MomRepository repository;

  SaveSelectedCustomerUseCase(this.repository);

  Future<void> call(Customer customer) {
    return repository.saveSelectedCustomer(customer);
  }
}

///test

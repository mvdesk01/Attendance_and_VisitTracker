import '../repositories/mom_repositories.dart';

class AddCustomerUseCase {
  final MomRepository repository;

  AddCustomerUseCase(this.repository);

  Future<String> call({
    required String customerName,
    required String contactPerson,
    required String address,
    required String mobileNo,
    required String emailId,
    required String entryBy,
  }) async {
    return await repository.addCustomer(
      customerName: customerName,
      contactPerson: contactPerson,
      address: address,
      mobileNo: mobileNo,
      emailId: emailId,
      entryBy: entryBy,
    );
  }
}

import '../../domain/enteties/customer.dart';

class CustomerState {
  final bool isLoading;
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final String? error;

  const CustomerState({
    this.isLoading = false,
    this.customers = const [],
    this.selectedCustomer,
    this.error,
  });

  CustomerState copyWith({
    bool? isLoading,
    List<Customer>? customers,
    Customer? selectedCustomer,
    String? error,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      error: error,
    );
  }
}

///test

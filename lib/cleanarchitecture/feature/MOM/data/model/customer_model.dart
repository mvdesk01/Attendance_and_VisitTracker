import '../../domain/enteties/customer.dart';

///test
class CustomerModel extends Customer {
  const CustomerModel({
    required super.customerCode,
    required super.customerName,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerCode: json['CustomerCode'] ?? '',
      customerName: json['CustomerName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CustomerCode': customerCode,
      'CustomerName': customerName,
    };
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      customerCode: customer.customerCode,
      customerName: customer.customerName,
    );
  }
}

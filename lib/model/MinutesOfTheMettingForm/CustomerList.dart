class CustomerResponse {
  final bool status;
  final String message;
  final List<CustomerData> data;

  CustomerResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? "",
      data: (json['data'] as List<dynamic>)
          .map((e) => CustomerData.fromJson(e))
          .toList(),
    );
  }
}

class CustomerData {
  final int custCode;
  final String custName;
  final String status;

  CustomerData({
    required this.custCode,
    required this.custName,
    required this.status,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      custCode: json['custCode'] ?? 0,
      custName: json['custName'] ?? "",
      status: json['status'] ?? "",
    );
  }
}

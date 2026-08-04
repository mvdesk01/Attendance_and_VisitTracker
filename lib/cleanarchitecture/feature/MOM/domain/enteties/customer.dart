class Customer {
  final String customerCode;
  final String customerName;

  const Customer({
    required this.customerCode,
    required this.customerName,
  });

  Customer copyWith({
    String? customerCode,
    String? customerName,
  }) {
    return Customer(
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && customerCode == other.customerCode;

  @override
  int get hashCode => customerCode.hashCode;
}

///test

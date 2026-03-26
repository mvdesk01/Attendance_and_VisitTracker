class LeaveCancellationDetail {
  final String status;
  final String staffCode;
  final String name;
  final String startDate;
  final String endDate;
  final String leaveType;
  final String days;
  String reason; // Mutable field to allow modification.
  final String transactionId;

  // Constructor
  LeaveCancellationDetail({
    required this.status,
    required this.staffCode,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.days,
    required this.reason,
    required this.transactionId,
  });

  // Factory method to create an instance from JSON
  factory LeaveCancellationDetail.fromJson(Map<String, dynamic> json) {
    return LeaveCancellationDetail(
      status: json['status'] as String,
      staffCode: json['staffcode'] as String,
      name: json['name'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      leaveType: json['leaveType'] as String,
      days: json['days'] as String,
      reason: json['reason'] as String,
      transactionId: json['transactionid'] as String,
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffCode,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'leaveType': leaveType,
      'days': days,
      'reason': reason,
      'transactionid': transactionId,
    };
  }
}

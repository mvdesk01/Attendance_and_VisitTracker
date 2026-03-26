class GatepassCancellationDetail {
  final String status;
  final String staffCode;
  final String name;
  final String date;
  final String fromTime;
  final String toTime;
  final String type;
  String reason; // Mutable field to allow modification.
  final String transactionId;

  // Constructor
  GatepassCancellationDetail({
    required this.status,
    required this.staffCode,
    required this.name,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.type,
    required this.reason,
    required this.transactionId,
  });

  // Factory method to create an instance from JSON
  factory GatepassCancellationDetail.fromJson(Map<String, dynamic> json) {
    return GatepassCancellationDetail(
      status: json['status'] as String,
      staffCode: json['staffcode'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      fromTime: json['fromtime'] as String,
      toTime: json['totime'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
      transactionId: json['transactionId'] as String,
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffCode,
      'name': name,
      'date': date,
      'fromtime': fromTime,
      'totime': toTime,
      'type': type,
      'reason': reason,
      'transactionId': transactionId,
    };
  }
}
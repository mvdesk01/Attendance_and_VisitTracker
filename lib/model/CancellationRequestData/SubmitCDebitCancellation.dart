class CDebitcancellation {
  final String status;
  final String staffCode;
  final String name;
  final String fromTime;
  final String date;
  final String toTime;
  final String reason;
  final String transactionId;

  // Constructor
  CDebitcancellation({
    required this.status,
    required this.staffCode,
    required this.name,
    required this.fromTime,
    required this.date,
    required this.toTime,
    required this.reason,
    required this.transactionId,
  });

  // Factory method to create a GatepassTransaction from a JSON map
  factory CDebitcancellation.fromJson(Map<String, dynamic> json) {
    return CDebitcancellation(
      status: json['status'] as String,
      staffCode: json['staffcode'] as String,
      name: json['name'] as String,
      fromTime: json['fromtime'] as String,
      date: json['date'] as String,
      toTime: json['totime'] as String,
      reason: json['reason'] as String,
      transactionId: json['transactionID'] as String,
    );
  }

  // Method to convert a GatepassTransaction instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffCode,
      'name': name,
      'fromtime': fromTime,
      'date': date,
      'totime': toTime,
      'reason': reason,
      'transactionID': transactionId,
    };
  }
}

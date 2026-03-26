class CCreditCancellationRequest {
  final String status;
  final String transactionId;
  final String staffCode;
  final String name;
  final String date;
  final String hours;
  final String type;
  final String reason;

  CCreditCancellationRequest({
    required this.status,
    required this.transactionId,
    required this.staffCode,
    required this.name,
    required this.date,
    required this.hours,
    required this.type,
    required this.reason,
  });

  factory CCreditCancellationRequest.fromJson(Map<String, dynamic> json) {
    return CCreditCancellationRequest(
      status: json['status'] as String,
      transactionId: json['transactionId'] as String,
      staffCode: json['staffCode'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      hours: json['hours'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'transactionId': transactionId,
      'staffCode': staffCode,
      'name': name,
      'date': date,
      'hours': hours,
      'type': type,
      'reason': reason,
    };
  }
}

class OTCancellationRequest {
  final String status;
  final String staffCode;
  final String name;
  final String date;
  final String hours;
  final String reason;
  final String transactionId;

  OTCancellationRequest({
    required this.status,
    required this.staffCode,
    required this.name,
    required this.date,
    required this.hours,
    required this.reason,
    required this.transactionId,
  });

  // Factory method to create a CancellationRequest from a JSON map
  factory OTCancellationRequest.fromJson(Map<String, dynamic> json) {
    return OTCancellationRequest(
      status: json['status'] ?? '',
      staffCode: json['staffcode'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      hours: json['hours'] ?? '',
      reason: json['reason'] ?? '',
      transactionId: json['transactionid'] ?? '',
    );
  }

  // Method to convert a CancellationRequest into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffCode,
      'name': name,
      'date': date,
      'hours': hours,
      'reason': reason,
      'transactionid': transactionId,
    };
  }
}

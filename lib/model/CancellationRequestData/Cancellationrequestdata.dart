

class CancellationRequest {
  final String staffCode;
  final String fromDate;
  final String toDate;
  final String requestType;

  CancellationRequest({
    required this.staffCode,
    required this.fromDate,
    required this.toDate,
    required this.requestType,
  });

  // Method to convert JSON to model
  factory CancellationRequest.fromJson(Map<String, dynamic> json) {
    return CancellationRequest(
      staffCode: json['staffCode'] ?? '',
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      requestType: json['requestType'] ?? '',
    );
  }

  // Method to convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'fromDate': fromDate,
      'toDate': toDate,
      'requestType': requestType,
    };
  }
}

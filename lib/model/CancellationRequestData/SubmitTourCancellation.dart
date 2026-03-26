class TourCancellationDetail {
  final String status;
  final String staffCode;
  final String name;
  final String startDate;
  final String endDate;
  final String tourAddress;
  String reason; // Mutable field to allow modification.
  final String transactionId;

  // Constructor
  TourCancellationDetail({
    required this.status,
    required this.staffCode,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.tourAddress,
    required this.reason,
    required this.transactionId,
  });

  // Factory method to create an instance from JSON
  factory TourCancellationDetail.fromJson(Map<String, dynamic> json) {
    return TourCancellationDetail(
      status: json['status'] as String,
      staffCode: json['staffcode'] as String,
      name: json['name'] as String,
      startDate: json['startdate'] as String,
      endDate: json['enddate'] as String,
      tourAddress: json['touraddress'] as String,
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
      'startdate': startDate,
      'enddate': endDate,
      'touraddress': tourAddress,
      'reason': reason,
      'transactionid': transactionId,
    };
  }
}

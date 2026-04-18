class TourCanceelationRequest {
  final String status;
  final String staffcode;
  final String name;
  final String startdate;
  final String enddate;
  final String touraddress;
  late final String reason;
  final String transactionid;

  TourCanceelationRequest({
    required this.status,
    required this.staffcode,
    required this.name,
    required this.startdate,
    required this.enddate,
    required this.touraddress,
    required this.reason,
    required this.transactionid,
  });

  factory TourCanceelationRequest.fromJson(Map<String, dynamic> json) {
    return TourCanceelationRequest(
      status: json['status'] as String,
      staffcode: json['staffcode'] as String,
      name: json['name'] as String,
      startdate: json['startdate'] as String,
      enddate: json['enddate'] as String,
      touraddress: json['touraddress'] as String,
      reason: json['reason'] as String,
      transactionid: json['transactionid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffcode,
      'name': name,
      'startdate': startdate,
      'enddate': enddate,
      'touraddress': touraddress,
      'reason': reason,
      'transactionid': transactionid,
    };
  }
}

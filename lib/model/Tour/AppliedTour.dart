class TourDetailsResponse {
  final List<TourDetail> message;

  TourDetailsResponse({required this.message});

  factory TourDetailsResponse.fromJson(Map<String, dynamic> json) {
    return TourDetailsResponse(
      message: (json['message'] as List<dynamic>)
          .map((item) => TourDetail.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message.map((item) => item.toJson()).toList(),
    };
  }
}

class TourDetail {
  final int slipId;
  final String staffCode;
  final String name;
  final String startDate;
  final String endDate;
  final String address;
  final String purpose;

  TourDetail({
    required this.slipId,
    required this.staffCode,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.address,
    required this.purpose,
  });

  factory TourDetail.fromJson(Map<String, dynamic> json) {
    return TourDetail(
      slipId: json['slipId'],
      staffCode: json['staffCode'],
      name: json['name'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      address: json['address'],
      purpose: json['purpose'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slipId': slipId,
      'staffCode': staffCode,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'address': address,
      'purpose': purpose,
    };
  }
}

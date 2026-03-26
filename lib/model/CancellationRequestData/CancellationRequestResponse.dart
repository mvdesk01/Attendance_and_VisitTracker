class CancellationstaffDetails {
  final int otwoffid;
  final String staffCode;
  final String name;
  final String otDate;
  final String ttlHrs;
  bool selected; // For checkbox
  String reason;

  CancellationstaffDetails({
    required this.otwoffid,
    required this.staffCode,
    required this.name,
    required this.otDate,
    required this.ttlHrs,
    this.selected = false,
    this.reason = "",
  });

  // Method to convert JSON to model
  factory CancellationstaffDetails.fromJson(Map<String, dynamic> json) {
    return CancellationstaffDetails(
      otwoffid: json['otwoffid'] ?? 0,
      staffCode: json['staffCode'] ?? '',
      name: json['name'] ?? '',
      otDate: json['otDate'] ?? '',
      ttlHrs: json['ttlHrs'] ?? '',

    );
  }

  // Method to convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'otwoffid': otwoffid,
      'staffCode': staffCode,
      'name': name,
      'otDate': otDate,
      'ttlHrs': ttlHrs,
    };
  }
}

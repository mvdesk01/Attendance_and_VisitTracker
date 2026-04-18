class ProfileUpdateRequest {
  final String staffCode;
  final String profilePic;
  final String email;
  final String mobileNo;

  ProfileUpdateRequest({
    required this.staffCode,
    required this.profilePic,
    required this.email,
    required this.mobileNo,
  });

  // Convert a ProfileUpdateRequest object to JSON
  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'profilePic': profilePic,
      'email': email,
      'mobileNo': mobileNo,
    };
  }

  // Create a ProfileUpdateRequest object from JSON
  factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateRequest(
      staffCode: json['staffCode'],
      profilePic: json['profilePic'],
      email: json['email'],
      mobileNo: json['mobileNo'],
    );
  }
}

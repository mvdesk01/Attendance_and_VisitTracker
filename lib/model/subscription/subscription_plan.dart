class SubscriptionPlan {
  final int planId;
  final String planName;
  final int duration;
  final double price;

  SubscriptionPlan({
    required this.planId,
    required this.planName,
    required this.duration,
    required this.price,
  });

  factory SubscriptionPlan.fromJson(
      Map<String, dynamic> json) {
    return SubscriptionPlan(
      planId: json["planId"],
      planName: json["planName"],
      duration: json["planDurationInMonths"],
      price: (json["price"] as num).toDouble(),
    );
  }
}

class SubscriberModel {
  final int subscriptionId;
  final int planId;
  final String userId;
  final String? userName;
  final String planName;
  final String subscriptionNo;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String paymentStatus;
  final double amount;

  SubscriberModel({
    required this.subscriptionId,
    required this.planId,
    required this.userId,
    this.userName,
    required this.planName,
    required this.subscriptionNo,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.paymentStatus,
    required this.amount,
  });

  factory SubscriberModel.fromJson(
      Map<String, dynamic> json) {
    return SubscriberModel(
      subscriptionId: json["subscriptionId"],
      planId: json["planId"],
      userId: json["userId"],
      userName: json["userName"] ?? json["displayName"],
      planName: json["planName"],
      subscriptionNo: json["subscriptionNo"],
      startDate: DateTime.parse(
        json["startDate"],
      ),
      endDate: DateTime.parse(
        json["endDate"],
      ),
      isActive: json["isActive"],
      paymentStatus: json["paymentStatus"],
      amount: (json["amount"] as num).toDouble(),
    );
  }
}
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../util/Constant.dart';

class SubscriptionService {
  Future<bool> checkSubscription(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(Constant.checkmenurights + userId),
      );

      print("SUBSCRIPTION STATUS : ${response.statusCode}");
      print("SUBSCRIPTION RESPONSE : ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        return json["status"] == true;
      }

      return false;
    } catch (e) {
      print("Subscription Error : $e");
      return false;
    }
  }
}

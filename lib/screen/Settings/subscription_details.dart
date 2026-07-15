import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState
    extends State<SubscriptionDetailsScreen> {

  final storage = const FlutterSecureStorage();

  bool isLoading = true;

  Map<String, dynamic>? subscription;

  @override
  void initState() {
    super.initState();
    loadSubscription();
  }

  Future<void> loadSubscription() async {

    String? userId = await storage.read(key: "username");

    try {

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(
        Uri.parse(
          "http://114.143.140.28:8020/api/Subscription/CheckActiveSubscription/$userId",
        ),
      );

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        "application/json",
      );

      final response = await request.close();

      final body =
      await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {

        final json = jsonDecode(body);

        if (json["status"] == true) {
          subscription = json["data"];
        }
      }
    } catch (e) {

      debugPrint(e.toString());

    }

    setState(() {
      isLoading = false;
    });
  }

  String formatDate(String value) {

    return DateFormat("dd MMM yyyy").format(
      DateTime.parse(value),
    );
  }

  int remainingDays(String expiry) {

    return DateTime.parse(expiry)
        .difference(DateTime.now())
        .inDays;
  }

  Widget buildTile(
      String title,
      String value,
      IconData icon,
      ) {

    return ListTile(
      leading: Icon(icon,color: Colors.blue),
      title: Text(title),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Subscription",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white
        ),
        ),
        centerTitle: true,
        backgroundColor: MyColors.lightBlue,
      ),

      body: isLoading

          ? const Center(
        child: CircularProgressIndicator(),
      )

          : subscription == null

          ? const Center(
        child: Text(
          "No Active Subscription",
          style: TextStyle(fontSize: 16),
        ),
      )

          : SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Card(

          elevation: 5,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          child: Padding(

            padding: const EdgeInsets.all(16),

            child: Column(

              children: [

                const Icon(
                  Icons.workspace_premium,
                  size: 70,
                  color: Colors.orange,
                ),

                const SizedBox(height: 10),

                Text(
                  "Subscription Active",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const Divider(height: 30),

                buildTile(
                  "Subscription No",
                  subscription!["subscriptionNo"],
                  Icons.confirmation_number,
                ),

                buildTile(
                  "User ID",
                  subscription!["userId"],
                  Icons.person,
                ),

                buildTile(
                  "Amount",
                  "₹${subscription!["amount"]}",
                  Icons.currency_rupee,
                ),

                buildTile(
                  "Payment Status",
                  subscription!["paymentStatus"],
                  Icons.payment,
                ),

                buildTile(
                  "Status",
                  subscription!["isActive"]
                      ? "Active"
                      : "Inactive",
                  Icons.verified,
                ),

                buildTile(
                  "Start Date",
                  formatDate(
                    subscription!["startDate"],
                  ),
                  Icons.calendar_today,
                ),

                buildTile(
                  "Expiry Date",
                  formatDate(
                    subscription!["endDate"],
                  ),
                  Icons.event,
                ),

                buildTile(
                  "Remaining Days",
                  "${remainingDays(subscription!["endDate"])} Days",
                  Icons.timelapse,
                ),

                buildTile(
                  "Auto Renew",
                  subscription!["isAutoRenew"]
                      ? "Enabled"
                      : "Disabled",
                  Icons.refresh,
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
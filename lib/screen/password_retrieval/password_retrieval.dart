import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class PasswordRetrieval extends StatefulWidget {
  const PasswordRetrieval({super.key});

  @override
  State<PasswordRetrieval> createState() => _PasswordRetrievalState();
}

class _PasswordRetrievalState extends State<PasswordRetrieval> {
  final TextEditingController staffCodeController =
  TextEditingController();

  bool isLoading = false;

  Future<void> retrievePassword() async {
    final staffCode = staffCodeController.text.trim();

    if (staffCode.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Staff Code");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "http://114.143.140.28:8020/Users/RetrivePassword?staffCode=$staffCode",
        ),
        headers: {
          "accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text("Password Retrieval"),
              content: const Text(
                "Your password has been sent to your registered email address.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        } else {
          Fluttertoast.showToast(
            msg: data["message"] ?? "Unable to retrieve password",
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Server Error (${response.statusCode})",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Something went wrong",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    staffCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Retrieve Password"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Icon(
                  Icons.lock_reset,
                  size: 90,
                  color: Colors.blue.shade700,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Enter your Staff Code and your password will be sent to your registered email address.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: staffCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: "Staff Code",
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : retrievePassword,
                    child: const Text(
                      "Retrieve Password",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
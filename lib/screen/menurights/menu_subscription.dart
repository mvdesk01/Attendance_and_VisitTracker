import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class MenuSubscriptionScreen extends StatefulWidget {
  const MenuSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<MenuSubscriptionScreen> createState() => _MenuSubscriptionScreenState();
}

class _MenuSubscriptionScreenState extends State<MenuSubscriptionScreen> {
  final TextEditingController staffCodeController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;
  bool isEditMode = false;
  String editingUser = "";

  Future<void> selectDate(bool isFromDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          fromDate = pickedDate;
        } else {
          toDate = pickedDate;
        }
      });
    }
  }

  void saveSubscription() {
    if (isEditMode) {
      Fluttertoast.showToast(
        msg: "Subscription updated",
        toastLength: Toast.LENGTH_SHORT,
      );
    } else {
      Fluttertoast.showToast(
        msg: "User added for subscription",
        toastLength: Toast.LENGTH_SHORT,
      );
    }

    setState(() {
      isEditMode = false;
      editingUser = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Subscription"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  controller: staffCodeController,
                  decoration: InputDecoration(
                    labelText: "Staff Code",
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: staffNameController,
                  decoration: InputDecoration(
                    labelText: "Staff Name",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () => selectDate(true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "From Date",
                      prefixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      fromDate == null
                          ? "Select From Date"
                          : DateFormat('dd-MM-yyyy').format(fromDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () => selectDate(false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "To Date",
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      toDate == null
                          ? "Select To Date"
                          : DateFormat('dd-MM-yyyy').format(toDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: saveSubscription,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "SAVE",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showSubscribedUsers();
                    },
                    icon: const Icon(Icons.people),
                    label: const Text(
                      "SUBSCRIBED USERS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showSubscribedUsers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildUserCard(
                name: "Shreya Shankar",
                validity: "06/06/2026 - 06/06/2027",
                active: true,
              ),
              const SizedBox(height: 12),
              buildUserCard(
                name: "Manish",
                validity: "05/06/2025 - 05/06/2026",
                active: false,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget buildUserCard({
    required String name,
    required String validity,
    required bool active,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active ? "ACTIVE" : "INACTIVE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 10),
                Text(validity),
              ],
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
                onPressed: () {
                  setState(() {
                    isEditMode = true;
                    editingUser = name;

                    if (name == "Shreya Shankar") {
                      staffCodeController.text = "EMP001";
                      staffNameController.text = "Shreya Shankar";

                      fromDate = DateTime(2026, 6, 6);
                      toDate = DateTime(2027, 6, 6);

                      amountController.text = "1200";
                    } else {
                      staffCodeController.text = "EMP002";
                      staffNameController.text = "Manish";

                      fromDate = DateTime(2025, 6, 5);
                      toDate = DateTime(2026, 6, 5);

                      amountController.text = "1000";
                    }
                  });

                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

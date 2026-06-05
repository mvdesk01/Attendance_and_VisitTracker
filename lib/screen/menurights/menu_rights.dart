import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MenuRightsScreen extends StatefulWidget {
  const MenuRightsScreen({super.key});

  @override
  State<MenuRightsScreen> createState() => _MenuRightsScreenState();
}

class _MenuRightsScreenState extends State<MenuRightsScreen> {
  String? selectedEmployee;

  bool expenseReport = false;
  bool inOutReport = false;
  bool employeeProfile = false;
  bool visitReport = false;

  final List<Map<String, String>> employees = [
    {"name": "Shreya Shankar", "code": "Cd03080"},
    {"name": "Manish Vishwakarma", "code": "cd03159"},
    {"name": "Amit Sonawane", "code": "cd00490"},
    {"name": "Sushmita Powar", "code": "cd03184"},
  ];

  final List<MenuRightModel> functionalities = [
    MenuRightModel("Gate Pass"),
    MenuRightModel("Leave"),
    MenuRightModel("C-Off Credit"),
    MenuRightModel("C-Off Debit"),
    MenuRightModel("Expense"),
    MenuRightModel("Tour"),
    MenuRightModel("Punch In / Out"),
    MenuRightModel("Visit Management"),
    MenuRightModel("Profile"),
    MenuRightModel("Expense Sanction"),
    MenuRightModel("Admin Rights"),
  ];

  void saveRights() {
    Fluttertoast.showToast(
      msg: "Menu Rights Updated Successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Rights"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedEmployee,
              decoration: InputDecoration(
                labelText: "Select Employee",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: employees.map((employee) {
                final value = "${employee['name']} (${employee['code']})";

                return DropdownMenuItem(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEmployee = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 8,
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      "Sr.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Functionality",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      "Rights",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: functionalities.length,
                itemBuilder: (context, index) {
                  final item = functionalities[index];

                  if (item.name == "Admin Rights") {
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text("${index + 1}"),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      item.isExpanded = !item.isExpanded;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        item.isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Checkbox(
                                  value: item.isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      item.isSelected = value ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.isExpanded)
                          Container(
                            margin: const EdgeInsets.only(left: 40),
                            child: Column(
                              children: [
                                buildSubMenu(
                                  "Employee Expense Report",
                                  expenseReport,
                                  (value) {
                                    setState(() {
                                      expenseReport = value ?? false;
                                    });
                                  },
                                ),
                                buildSubMenu(
                                  "Employee In/Out Report",
                                  inOutReport,
                                  (value) {
                                    setState(() {
                                      inOutReport = value ?? false;
                                    });
                                  },
                                ),
                                buildSubMenu(
                                  "Employee Profile",
                                  employeeProfile,
                                  (value) {
                                    setState(() {
                                      employeeProfile = value ?? false;
                                    });
                                  },
                                ),
                                buildSubMenu(
                                  "Employee Visit Report",
                                  visitReport,
                                  (value) {
                                    setState(() {
                                      visitReport = value ?? false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text("${index + 1}"),
                          ),
                        ),
                        Expanded(
                          child: Text(item.name),
                        ),
                        SizedBox(
                          width: 70,
                          child: Checkbox(
                            value: item.isSelected,
                            onChanged: (value) {
                              setState(() {
                                item.isSelected = value ?? false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveRights,
                child: const Text(
                  "SAVE RIGHTS",
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
    );
  }

  Widget buildSubMenu(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: Row(
        children: [
          const Expanded(
            child: SizedBox(),
          ),
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuRightModel {
  final String name;
  bool isSelected;
  bool isExpanded;

  MenuRightModel(
    this.name, {
    this.isSelected = false,
    this.isExpanded = false,
  });
}

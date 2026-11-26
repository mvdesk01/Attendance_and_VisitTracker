import 'package:flutter/material.dart';

class TimeLogRowState {
  String? projectName;
  String? projectCode;
  bool isNewRow = true;
  bool isSaveEnabled = false;
  bool hasChanges = false;

  dynamic transactionId = 0;
  String? moduleCode;
  String? moduleName;

  List<Map<String, String>> subModuleList = [];
  bool isSubModuleLoading = false;
  final TextEditingController activityController = TextEditingController();

  final TextEditingController startTimeController = TextEditingController();

  final TextEditingController endTimeController = TextEditingController();

  final TextEditingController problemController = TextEditingController();

  final TextEditingController timeWastedController = TextEditingController();

  void dispose() {
    activityController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    problemController.dispose();
    timeWastedController.dispose();
  }
}

import 'package:flutter/material.dart';

class TimeLogRowState {
  String? projectName;
  String? projectCode;
  bool isNewRow = true;
  bool isSaveEnabled = false;

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

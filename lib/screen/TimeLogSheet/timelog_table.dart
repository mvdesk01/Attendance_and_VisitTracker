import 'dart:convert';

import 'package:attendance_system_ios/screen/TimeLogSheet/timelog_row_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../cleanarchitecture/core/network/dio_client.dart';

class TimeLogTable extends StatefulWidget {
  final Color primaryColor;
  final String logdate;
  final VoidCallback? onClose;

  const TimeLogTable({
    super.key,
    required this.primaryColor,
    required this.logdate,
    this.onClose,
  });

  @override
  State<TimeLogTable> createState() => _TimeLogTableState();
}

class _TimeLogTableState extends State<TimeLogTable> {
  List<TimeLogRowState> timeLogRows = [];

  // Project API values will be added here later.
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<Map<String, String>> projectList = [];

  bool isProjectLoading = false;
  String? projectError;
  bool isSaving = false;
  bool isLoadingTimeLogs = true;

  // bool isNewRow = true;

  static const String projectCacheKey = "TimeLog_Project_Cache";

  @override
  void initState() {
    super.initState();
    fetchProjects();

    // Display minimum 2 rows initially.
    //timeLogRows.add(TimeLogRowState());
    // Fetch saved records only in View mode.
    viewTimeLogSheet();
    // Start with one blank row for new entry.
    //timeLogRows.add(TimeLogRowState());

    //timeLogRows.add(TimeLogRowState());
    print(widget.logdate);
  }

  Future<void> fetchProjects() async {
    if (!mounted) return;

    setState(() {
      isProjectLoading = true;
      projectError = null;
    });

    // First load previously saved projects.
    try {
      final cachedData = await storage.read(key: projectCacheKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedData);

        if (mounted) {
          setState(() {
            projectList =
                decoded.map((item) => Map<String, String>.from(item)).toList();
          });
        }
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Project cache error: $e',
      );
      debugPrint("Project cache error: $e");
    }

    // Fetch the latest projects from the server.
    try {
      final staffCode = await storage.read(key: "Staff_Code");

      if (staffCode == null || staffCode.isEmpty) {
        throw Exception("Staff code not found");
      }

      final response = await DioClient().dio.post(
        "ProjectMaster",
        data: {
          "UserName": staffCode,
        },
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;

        final List<Map<String, String>> fetchedProjects = data.map((item) {
          return {
            "ProjectCode": item["ProjectCode"].toString(),
            "ProjectName": item["ProjectName"].toString(),
          };
        }).toList();

        if (mounted) {
          setState(() {
            projectList = fetchedProjects;
            projectError = null;
          });
        }

        // Save the latest successful response for offline use.
        await storage.write(
          key: projectCacheKey,
          value: jsonEncode(fetchedProjects),
        );

        debugPrint("Projects fetched: ${fetchedProjects.length}");
      } else {
        throw Exception("Unable to fetch projects");
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Project API error: $e',
      );
      debugPrint("Project API error: $e");

      if (mounted) {
        setState(() {
          projectError = "Unable to fetch latest projects";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isProjectLoading = false;
        });
      }
    }
  }

  Future<void> viewTimeLogSheet() async {
    if (!mounted) return;

    setState(() {
      isLoadingTimeLogs = true;
    });

    try {
      final staffCode = await storage.read(key: "Staff_Code");

      if (staffCode == null || staffCode.isEmpty) {
        showMessage("Staff code not found");
        return;
      }

      final response = await DioClient().dio.post(
        "ViewTimeLogSheet",
        data: {
          "UserName": staffCode,
          "LogDate": widget.logdate,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is! List) {
          throw Exception("Invalid TimeLog response");
        }

        final List<dynamic> data = response.data;
        final List<TimeLogRowState> fetchedRows = [];

        for (final item in data) {
          final row = TimeLogRowState();

          row.isNewRow = false;

          row.projectCode = item["ProjectCode"]?.toString();
          row.projectName = item["ProjectName"]?.toString();

          row.activityController.text = item["Activity"]?.toString() ?? "";

          row.startTimeController.text = item["StartTime"]?.toString() ?? "";

          row.endTimeController.text = item["EndTime"]?.toString() ?? "";

          row.problemController.text = item["ProblemFaced"]?.toString() ?? "";

          row.timeWastedController.text = item["TimeWasted"]?.toString() ?? "";

          fetchedRows.add(row);
        }

        // If no saved records exist, show one blank editable row.
        if (fetchedRows.isEmpty) {
          fetchedRows.add(TimeLogRowState());
        }

        if (!mounted) {
          for (final row in fetchedRows) {
            row.dispose();
          }
          return;
        }

        setState(() {
          for (final row in timeLogRows) {
            row.dispose();
          }

          timeLogRows = fetchedRows;
        });

        debugPrint("TimeLog records fetched: ${data.length}");
      } else {
        showMessage("Unable to fetch TimeLog details");
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'ViewTimeLogSheet API error: $e',
      );

      debugPrint("ViewTimeLogSheet API error: $e");
      showMessage("Unable to load TimeLog details");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTimeLogs = false;
        });
      }
    }
  }

  Future<void> showProjectPicker(TimeLogRowState row) async {
    if (projectList.isEmpty) {
      showMessage("No projects available");
      return;
    }

    final searchController = TextEditingController();

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          String searchText = "";

          return StatefulBuilder(
            builder: (context, dialogSetState) {
              final filteredProjects = projectList.where((project) {
                return (project["ProjectName"] ?? "")
                    .toLowerCase()
                    .contains(searchText.toLowerCase());
              }).toList();

              return Dialog(
                child: SizedBox(
                  width: 400,
                  height: 450,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Select Project",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText: "Search project",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            dialogSetState(() {
                              searchText = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: filteredProjects.isEmpty
                              ? const Center(
                                  child: Text("No projects found"),
                                )
                              : ListView.builder(
                                  itemCount: filteredProjects.length,
                                  itemBuilder: (context, index) {
                                    final project = filteredProjects[index];

                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        project["ProjectName"] ?? "",
                                      ),
                                      onTap: () {
                                        setState(() {
                                          row.projectName =
                                              project["ProjectName"];
                                          row.projectCode =
                                              project["ProjectCode"];
                                        });

                                        Navigator.pop(dialogContext);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      // Dispose only after the dialog route has completely closed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchController.dispose();
      });
    }
  }

  @override
  void dispose() {
    for (var row in timeLogRows) {
      row.dispose();
    }
    super.dispose();
  }

  void addTimeLogRow() {
    if (isLoadingTimeLogs || isSaving) return;

    setState(() {
      timeLogRows.insert(0, TimeLogRowState());
    });
  }

  void showMessage(String message) {
    Fluttertoast.showToast(msg: message);
  }

  int? convertTimeToMinutes(String time) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

    if (!regex.hasMatch(time)) return null;

    final parts = time.split(':');

    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void validateStartTime(TimeLogRowState row, String value) {
    if (value.length != 5) return;

    int? minutes = convertTimeToMinutes(value);

    if (minutes == null) {
      showMessage("Enter valid time in HH:mm format");
      row.startTimeController.clear();
      return;
    }

    if (minutes < 515) {
      showMessage("Start time cannot be before 08:35 AM");
      row.startTimeController.clear();
      return;
    }

    int? endMinutes = convertTimeToMinutes(row.endTimeController.text);

    if (endMinutes != null && endMinutes <= minutes) {
      row.endTimeController.clear();
      showMessage("End time must be after start time");
    }
  }

  void validateEndTime(TimeLogRowState row, String value) {
    if (value.length != 5) return;

    int? endMinutes = convertTimeToMinutes(value);
    int? startMinutes = convertTimeToMinutes(row.startTimeController.text);

    if (endMinutes == null) {
      showMessage("Enter valid time in HH:mm format");
      row.endTimeController.clear();
      return;
    }

    if (startMinutes == null) {
      showMessage("Please enter valid start time first");
      row.endTimeController.clear();
      return;
    }

    if (endMinutes <= startMinutes) {
      showMessage("End time must be after start time");
      row.endTimeController.clear();
    }
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    if (endMinutes > currentMinutes) {
      showMessage("End time cannot be greater than current time");
      row.endTimeController.clear();
      return;
    }
  }

  Widget buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 30),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        border: Border.all(color: Colors.white, width: 0.2),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget buildDataCell({
    required double width,
    required Widget child,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 75),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade400,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  // Widget buildTextField({
  //   required TextEditingController controller,
  //   String? hint,
  //   int minLines = 1,
  //   int maxLines = 1,
  //   TextInputType keyboardType = TextInputType.text,
  //   int? maxLength,
  //   Function(String)? onChanged,
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     minLines: minLines,
  //     maxLines: maxLines,
  //     keyboardType: keyboardType,
  //     maxLength: maxLength,
  //     onChanged: onChanged,
  //     decoration: InputDecoration(
  //       hintText: hint,
  //       hintStyle: const TextStyle(fontSize: 12),
  //       border: const OutlineInputBorder(),
  //       contentPadding: const EdgeInsets.all(8),
  //       counterText: "",
  //     ),
  //   );
  // }
  Widget buildTextField({
    required TextEditingController controller,
    String? hint,
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: readOnly ? null : onChanged,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(8),
        counterText: "",
      ),
    );
  }

  Widget buildTimeLogRow(TimeLogRowState row, int index) {
    return Container(
      color: index.isEven ? Colors.grey.shade100 : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDataCell(
            width: 55,
            child: SizedBox(
              height: 130,
              child: Center(
                child: Text("${index + 1}"),
              ),
            ),
          ),
          buildDataCell(
            width: 215,
            child: SizedBox(
              height: 130,
              child: Center(
                child: InkWell(
                  onTap: row.isNewRow
                      ? () {
                          showProjectPicker(row);
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.projectName ?? "Select Project",
                            style: TextStyle(
                              fontSize: 12,
                              color: row.projectName == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (row.isNewRow) const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          buildDataCell(
            width: 200,
            child: buildTextField(
              controller: row.activityController,
              minLines: 3,
              maxLines: 5,
              hint: "Enter Activity",
              readOnly: !row.isNewRow,
            ),
          ),
          buildDataCell(
            width: 120,
            child: buildTextField(
              controller: row.startTimeController,
              hint: "HH:mm",
              keyboardType: TextInputType.datetime,
              maxLength: 5,
              readOnly: !row.isNewRow,
              onChanged: (value) {
                validateStartTime(row, value);
              },
            ),
          ),
          buildDataCell(
            width: 120,
            child: buildTextField(
              controller: row.endTimeController,
              hint: "HH:mm",
              keyboardType: TextInputType.datetime,
              maxLength: 5,
              readOnly: !row.isNewRow,
              onChanged: (value) {
                validateEndTime(row, value);
              },
            ),
          ),
          buildDataCell(
            width: 200,
            child: buildTextField(
              controller: row.problemController,
              minLines: 3,
              maxLines: 5,
              hint: "Enter Problem",
              readOnly: !row.isNewRow,
            ),
          ),
          buildDataCell(
            width: 140,
            child: buildTextField(
              controller: row.timeWastedController,
              hint: "Enter Time",
              readOnly: !row.isNewRow,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeLogTable() {
    const double tableWidth = 1050;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade500,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TimeLog Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed:
                    (isLoadingTimeLogs || isSaving) ? null : addTimeLogRow,
                icon: Icon(
                  Icons.add_circle,
                  color: widget.primaryColor,
                  size: 30,
                ),
              ),
            ],
          ),
          if (isProjectLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Loading projects...",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (projectError != null && projectList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                "Showing previously saved projects. Latest list could not be loaded.",
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          if (projectError != null && projectList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Unable to load projects. Check your network.",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: isProjectLoading ? null : fetchProjects,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (isLoadingTimeLogs)
            const Padding(
              padding: EdgeInsets.all(15),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (!isLoadingTimeLogs)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          buildHeaderCell("Sr. No.", 55),
                          buildHeaderCell("Project Name", 215),
                          buildHeaderCell("Activity", 200),
                          buildHeaderCell("Start Time", 120),
                          buildHeaderCell("End Time", 120),
                          buildHeaderCell("Problem Faced", 200),
                          buildHeaderCell("Time Wasted", 140),
                        ],
                      ),
                      ...List.generate(
                        timeLogRows.length,
                        (index) => buildTimeLogRow(
                          timeLogRows[index],
                          index,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void clearTimeLogData() {
    setState(() {
      for (var row in timeLogRows) {
        row.projectName = null;
        row.activityController.clear();
        row.startTimeController.clear();
        row.endTimeController.clear();
        row.problemController.clear();
        row.timeWastedController.clear();
        row.projectCode = null;
      }
    });

    //showMessage("Entered data cleared");
  }

  Future<void> saveTimeLogData() async {
    if (isSaving || isLoadingTimeLogs) return;

    // Consider only rows containing entered data.
    // final enteredRows = timeLogRows.where((row) {
    //   return row.projectCode != null ||
    //       row.activityController.text.trim().isNotEmpty ||
    //       row.startTimeController.text.trim().isNotEmpty ||
    //       row.endTimeController.text.trim().isNotEmpty ||
    //       row.problemController.text.trim().isNotEmpty ||
    //       row.timeWastedController.text.trim().isNotEmpty;
    // }).toList();

    final enteredRows = timeLogRows.where((row) {
      return row.isNewRow &&
          (row.projectCode != null ||
              row.activityController.text.trim().isNotEmpty ||
              row.startTimeController.text.trim().isNotEmpty ||
              row.endTimeController.text.trim().isNotEmpty ||
              row.problemController.text.trim().isNotEmpty ||
              row.timeWastedController.text.trim().isNotEmpty);
    }).toList();

    if (enteredRows.isEmpty) {
      showMessage("Please enter at least one row");
      return;
    }

    // Validate all rows before making API calls.
    for (int i = 0; i < enteredRows.length; i++) {
      final row = enteredRows[i];

      if (row.projectCode == null) {
        showMessage("Select project in row ${i + 1}");
        return;
      }

      if (row.activityController.text.trim().isEmpty) {
        showMessage("Enter activity in row ${i + 1}");
        return;
      }

      if (convertTimeToMinutes(row.startTimeController.text) == null) {
        showMessage("Enter valid start time in row ${i + 1}");
        return;
      }

      if (convertTimeToMinutes(row.endTimeController.text) == null) {
        showMessage("Enter valid end time in row ${i + 1}");
        return;
      }

      final start = convertTimeToMinutes(row.startTimeController.text)!;
      final end = convertTimeToMinutes(row.endTimeController.text)!;

      if (start < 515 || end <= start) {
        showMessage("Check start and end time in row ${i + 1}");
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final staffCode = await storage.read(key: "Staff_Code");

      if (staffCode == null || staffCode.isEmpty) {
        showMessage("Staff code not found. Please login again.");
        return;
      }

      // Send all row requests concurrently for faster submission.
      // final results = await Future.wait(
      //   enteredRows.map((row) async {
      //     try {
      //       final requestData = {
      //         "UserName": staffCode,
      //         "LogDate": widget.logdate,
      //         "ProjectCode": row.projectCode,
      //         "Activity": row.activityController.text.trim(),
      //         "StartTime": row.startTimeController.text.trim(),
      //         "EndTime": row.endTimeController.text.trim(),
      //         "ProblemFaced": row.problemController.text.trim().isEmpty
      //             ? "NA"
      //             : row.problemController.text.trim(),
      //         "TimeWasted": row.timeWastedController.text.trim().isEmpty
      //             ? "0"
      //             : row.timeWastedController.text.trim(),
      //         "Flag": "I",
      //       };
      //
      //       final response = await DioClient().dio.post(
      //             "TimeLogSheet",
      //             data: requestData,
      //           );
      //
      //       final responseData = response.data;
      //
      //       if (response.statusCode == 201 &&
      //           responseData is List &&
      //           responseData.isNotEmpty) {
      //         final outMsg = responseData[0]["OutMsg"]?.toString() ?? "";
      //
      //         if (outMsg.toLowerCase().contains("save successfully")) {
      //           showMessage(outMsg);
      //           clearTimeLogData();
      //           return true;
      //         }
      //       }
      //
      //       return false;
      //     } catch (e) {
      //       showMessage("Failed to submit");
      //       debugPrint("TimeLog row API error: $e");
      //       return false;
      //     }
      //   }),
      // );
      final results = await Future.wait(
        enteredRows.map((row) async {
          try {
            final requestData = {
              "UserName": staffCode,
              "LogDate": widget.logdate,
              "ProjectCode": row.projectCode,
              "Activity": row.activityController.text.trim(),
              "StartTime": row.startTimeController.text.trim(),
              "EndTime": row.endTimeController.text.trim(),
              "ProblemFaced": row.problemController.text.trim().isEmpty
                  ? "NA"
                  : row.problemController.text.trim(),
              "TimeWasted": row.timeWastedController.text.trim().isEmpty
                  ? "0"
                  : row.timeWastedController.text.trim(),
              "Flag": "I",
            };

            final response = await DioClient().dio.post(
                  "TimeLogSheet",
                  data: requestData,
                );

            final responseData = response.data;

            if (response.statusCode == 201 &&
                responseData is List &&
                responseData.isNotEmpty) {
              final outMsg = responseData[0]["OutMsg"]?.toString() ?? "";

              if (outMsg.toLowerCase().contains("save successfully")) {
                return {
                  "success": true,
                  "message": outMsg,
                };
              }
            }

            return {
              "success": false,
              "message": "",
            };
          } catch (e, stack) {
            await FirebaseCrashlytics.instance.recordError(
              e,
              stack,
              reason: 'TimeLog row API error: $e',
            );
            debugPrint("TimeLog row API error: $e");

            return {
              "success": false,
              "message": "",
            };
          }
        }),
      );

      // final successCount = results.where((result) => result).length;
      // final failedCount = results.length - successCount;
      //
      // if (!mounted) return;
      //
      // if (failedCount == 0) {
      //   showMessage("$successCount row(s) saved successfully");
      // } else {
      //   showMessage("$successCount saved, $failedCount failed");
      // }
      final successCount = results.where((r) => r["success"] == true).length;

      final failedCount = results.length - successCount;

      final successMessages = results
          .where((r) => r["success"] == true)
          .map((r) => r["message"].toString())
          .where((message) => message.isNotEmpty)
          .toSet();

      if (!mounted) return;

      if (failedCount == 0) {
        showMessage(
          "$successCount row(s) saved successfully. "
          "${successMessages.join(", ")}",
        );

        // Close the table after all new rows are saved.
        widget.onClose?.call();
      } else {
        // Successful rows should not be submitted again.
        for (int i = 0; i < results.length; i++) {
          if (results[i]["success"] == true) {
            enteredRows[i].isNewRow = false;
          }
        }

        if (successCount == 0) {
          showMessage("Unable to save TimeLog data. Please try again.");
        } else {
          showMessage(
            "$successCount row(s) saved. "
            "$failedCount row(s) failed. "
            "${successMessages.join(", ")}",
          );
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'TimeLog save error: $e',
      );
      debugPrint("TimeLog save error: $e");
      if (mounted) {
        showMessage("Unable to save TimeLog data");
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildTimeLogTable(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:
                  (isSaving || isLoadingTimeLogs) ? null : saveTimeLogData,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Save"),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              onPressed: isSaving ? null : clearTimeLogData,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              onPressed: isSaving ? null : widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
              child: const Text("Close"),
            ),
          ],
        ),
      ],
    );
  }
}

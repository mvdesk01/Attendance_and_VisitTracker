import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../cleanarchitecture/feature/MOM/domain/enteties/decision.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/meetingpoints.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/decision/decisionprovider.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/responsibility/responsibilityprovider.dart';

class DiscussionPointRow extends ConsumerStatefulWidget {
  final int serialNumber;
  final VoidCallback onDelete;
  final Map<String, String>? initialData;
  final bool isExisting;
  final String customerCode;

  const DiscussionPointRow({
    super.key,
    required this.serialNumber,
    required this.onDelete,
    this.initialData,
    required this.customerCode,
    this.isExisting = false,
  });

  @override
  ConsumerState<DiscussionPointRow> createState() => DiscussionPointRowState();
}

class DiscussionPointRowState extends ConsumerState<DiscussionPointRow> {
  final pointController = TextEditingController();
  final discussedController = TextEditingController();
  final targetDateController = TextEditingController();

  String? decision;
  String? selectedDecisionCode;

  List<Responsibility> selectedMembers = [];
  List<String> selectedMemberNames = [];

  // Special dropdown value
  static const String addCustomDecisionValue = "__ADD_CUSTOM_DECISION__";

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      pointController.text = widget.initialData!["point"] ?? "";
      discussedController.text = widget.initialData!["discussedWith"] ?? "";
      targetDateController.text = widget.initialData!["targetDate"] ?? "";

      decision = widget.initialData!["decisionTaken"];

      selectedMemberNames = (widget.initialData?["responsibility"] ?? "")
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    pointController.dispose();
    discussedController.dispose();
    targetDateController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      targetDateController.text = DateFormat("dd/MM/yyyy").format(picked);

      setState(() {});
    }
  }

  DiscussionPoint getDiscussionPoint({
    required String entryBy,
    required String last,
  }) {
    return DiscussionPoint(
      point: pointController.text.trim(),
      discussedWith: discussedController.text.trim(),
      decisionCode: selectedDecisionCode ?? "",
      responsibilityCodes: selectedMembers.map((e) => e.userCode).join(","),
      responsibilityNames: selectedMembers.map((e) => e.userName).join(","),
      targetDate: targetDateController.text.trim(),
      entryBy: entryBy,
      flag: widget.isExisting ? "U" : "I",
      last: last,
    );
  }

  Widget cell({
    required Widget child,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SizedBox.expand(
        child: child,
      ),
    );
  }

  bool validate() {
    print("------------");
    print("Point: ${pointController.text}");
    print("Discussed: ${discussedController.text}");
    print("Decision Name: $decision");
    print("Decision Code: $selectedDecisionCode");
    print("Members: ${selectedMembers.length}");
    print("Member Names: $selectedMemberNames");
    print("Target: ${targetDateController.text}");

    if (pointController.text.trim().isEmpty) {
      return false;
    }

    if (discussedController.text.trim().isEmpty) {
      return false;
    }

    if (selectedDecisionCode == null || selectedDecisionCode!.isEmpty) {
      return false;
    }

    if (selectedMembers.isEmpty) {
      return false;
    }

    if (targetDateController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  // ============================================================
  // ADD CUSTOM DECISION
  // ============================================================

  Future<void> _showAddCustomDecisionDialog() async {
    final controller = TextEditingController();

    try {
      final decisionName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool isAdding = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("Add Custom Decision"),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: "Decision Name",
                    hintText: "Enter decision name",
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isAdding
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text("Cancel"),
                  ),
                  FilledButton(
                    onPressed: isAdding
                        ? null
                        : () async {
                            final value = controller.text.trim();

                            if (value.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please enter decision name",
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isAdding = true;
                            });

                            final success = await ref
                                .read(
                                  decisionNotifierProvider.notifier,
                                )
                                .addCustomDecision(
                                  decisionName: value,
                                );

                            if (!context.mounted) {
                              return;
                            }

                            if (success) {
                              Navigator.of(dialogContext).pop(value);
                            } else {
                              setDialogState(() {
                                isAdding = false;
                              });
                            }
                          },
                    child: isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Add"),
                  ),
                ],
              );
            },
          );
        },
      );
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      controller.dispose();
      if (!mounted || decisionName == null) {
        return;
      }

      // Important:
      // Give Flutter one frame to completely remove the dialog
      // from the Overlay before changing the decision list.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      final decisionState = ref.read(
        decisionNotifierProvider,
      );

      Decision? addedDecision;

      for (final item in decisionState.decisions) {
        if (item.decisionName.trim().toLowerCase() ==
            decisionName.trim().toLowerCase()) {
          addedDecision = item;
          break;
        }
      }

      if (addedDecision == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Decision added, but could not be found in the decision list.",
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      // Select the newly-created decision in this row.
      setState(() {
        decision = addedDecision!.decisionName;
        selectedDecisionCode = addedDecision!.decisionCode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${addedDecision!.decisionName}" added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final decisionState = ref.watch(decisionNotifierProvider);

    final responsibilityState = ref.watch(responsibilityNotifierProvider);

    // Restore decision code when editing an existing MOM.
    if ((selectedDecisionCode == null || selectedDecisionCode!.isEmpty) &&
        decision != null &&
        decisionState.decisions.isNotEmpty) {
      final match = decisionState.decisions.where(
        (e) =>
            e.decisionName.trim().toLowerCase() ==
            decision!.trim().toLowerCase(),
      );

      if (match.isNotEmpty) {
        selectedDecisionCode = match.first.decisionCode;
      }
    }

    // Restore responsibility when editing an existing MOM.
    // if (selectedMembers.isEmpty &&
    //     selectedMemberNames.isNotEmpty &&
    //     responsibilityState.responsibility.isNotEmpty) {
    //   selectedMembers = responsibilityState.responsibility.where((e) {
    //     return selectedMemberNames.any(
    //       (name) =>
    //           name.trim().toLowerCase() == e.userName.trim().toLowerCase(),
    //     );
    //   }).toList();
    // }
    // ============================================================
// RESTORE RESPONSIBILITY WHEN EDITING
// ============================================================

    if (widget.isExisting && selectedMembers.isEmpty) {
      final customer = Responsibility(
        userCode: widget.customerCode,
        userName: "CUSTOMER",
      );

      // Existing MOM has no saved responsibility.
      // Default to CUSTOMER.
      if (selectedMemberNames.isEmpty) {
        selectedMembers = [customer];
      } else {
        // Existing MOM has saved responsibilities.
        // Restore them normally.
        final allResponsibilities = [
          customer,
          ...responsibilityState.responsibility,
        ];

        selectedMembers = allResponsibilities.where((e) {
          return selectedMemberNames.any(
            (name) =>
                name.trim().toLowerCase() == e.userName.trim().toLowerCase(),
          );
        }).toList();
      }
    }

    return Container(
      color: widget.serialNumber.isEven ? Colors.grey.shade50 : Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // SERIAL NUMBER
            // ==================================================

            cell(
              width: 30,
              child: Center(
                child: Text(
                  widget.serialNumber.toString(),
                ),
              ),
            ),

            // ==================================================
            // POINT
            // ==================================================

            cell(
              width: 320,
              child: TextFormField(
                controller: pointController,
                minLines: 4,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  isDense: true,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            // ==================================================
            // DISCUSSED WITH
            // ==================================================

            cell(
              width: 180,
              child: SizedBox.expand(
                child: TextFormField(
                  controller: discussedController,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // DECISION
            // ==================================================

            cell(
              width: 200,
              child: SizedBox.expand(
                child: DropdownButtonFormField<String>(
                  value: decision != null &&
                          decisionState.decisions.any(
                            (e) => e.decisionName == decision,
                          )
                      ? decision
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  items: [
                    // Existing decisions
                    ...decisionState.decisions.map(
                      (decisionItem) {
                        return DropdownMenuItem<String>(
                          value: decisionItem.decisionName,
                          child: Text(
                            decisionItem.decisionName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),

                    // Custom decision option
                    const DropdownMenuItem<String>(
                      value: addCustomDecisionValue,
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Add Custom Decision",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    if (value == addCustomDecisionValue) {
                      // IMPORTANT:
                      // Do not open the dialog directly from the dropdown callback.
                      // Let the dropdown overlay finish closing first.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;

                        _showAddCustomDecisionDialog();
                      });

                      return;
                    }

                    // Normal decision
                    final selected = decisionState.decisions
                        .where(
                          (item) => item.decisionName == value,
                        )
                        .firstOrNull;

                    if (selected == null) {
                      return;
                    }

                    setState(() {
                      decision = selected.decisionName;
                      selectedDecisionCode = selected.decisionCode;
                    });
                  },
                  // onChanged: (value) async {
                  //   if (value == null) {
                  //     return;
                  //   }
                  //
                  //   // User selected:
                  //   // + Add Custom Decision
                  //   // if (value == addCustomDecisionValue) {
                  //   //   await _showAddCustomDecisionDialog();
                  //   //   return;
                  //   // }
                  //   if (value == addCustomDecisionValue) {
                  //     // Let the dropdown overlay close first.
                  //     await Future<void>.delayed(
                  //       const Duration(milliseconds: 100),
                  //     );
                  //
                  //     if (!mounted) return;
                  //
                  //     await _showAddCustomDecisionDialog();
                  //     return;
                  //   }
                  //   // Normal decision
                  //   final selected = decisionState.decisions
                  //       .where(
                  //         (item) => item.decisionName == value,
                  //       )
                  //       .firstOrNull;
                  //
                  //   if (selected == null) {
                  //     return;
                  //   }
                  //
                  //   setState(() {
                  //     decision = selected.decisionName;
                  //
                  //     selectedDecisionCode = selected.decisionCode;
                  //   });
                  // },
                ),
              ),
            ),

            // ==================================================
            // RESPONSIBILITY
            // ==================================================

            cell(
              width: 260,
              child: DropdownSearch<Responsibility>.multiSelection(
                items: (filter, infiniteScrollProps) async {
                  print(
                    "Dropdown Items: "
                    "${responsibilityState.responsibility.length}",
                  );
                  final customer = Responsibility(
                    userCode: widget.customerCode,
                    userName: "CUSTOMER",
                  );
                  return [customer, ...responsibilityState.responsibility];
                },
                selectedItems: selectedMembers,
                itemAsString: (Responsibility item) => item.userName,
                compareFn: (a, b) => a.userCode == b.userCode,
                popupProps: PopupPropsMultiSelection.modalBottomSheet(
                  showSearchBox: true,
                  showSelectedItems: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search Responsibility",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                dropdownBuilder: (context, selectedItems) {
                  return Text(
                    selectedItems.isEmpty
                        ? "Select Responsibility"
                        : selectedItems.map((e) => e.userName).join(", "),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                onChanged: (values) {
                  setState(() {
                    selectedMembers = values;
                  });
                },
              ),
            ),

            // ==================================================
            // TARGET DATE
            // ==================================================

            cell(
              width: 170,
              child: SizedBox.expand(
                child: TextFormField(
                  controller: targetDateController,
                  readOnly: true,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.center,
                  onTap: pickDate,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // DELETE
            // ==================================================

            cell(
              width: 40,
              child: Center(
                child: IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

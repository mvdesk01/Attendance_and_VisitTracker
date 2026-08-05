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

  const DiscussionPointRow({
    super.key,
    required this.serialNumber,
    required this.onDelete,
    this.initialData,
    this.isExisting = false,
  });

  @override
  ConsumerState<DiscussionPointRow> createState() => DiscussionPointRowState();
}

///test
class DiscussionPointRowState extends ConsumerState<DiscussionPointRow> {
  final pointController = TextEditingController();
  final discussedController = TextEditingController();
  final targetDateController = TextEditingController();

  String? decision;
  String? selectedDecisionCode;

  List<Responsibility> selectedMembers = [];
  List<String> selectedMemberNames = [];

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

  // DiscussionPoint getDiscussionPoint({
  //   required String entryBy,
  //   required String flag,
  // }) {
  //   return DiscussionPoint(
  //     point: pointController.text.trim(),
  //     discussedWith: discussedController.text.trim(),
  //     decisionCode: selectedDecisionCode ?? "",
  //     responsibilityCodes: selectedMembers.map((e) => e.userCode).join(","),
  //     responsibilityNames: selectedMembers.map((e) => e.userName).join(","),
  //     targetDate: targetDateController.text.trim(),
  //     entryBy: entryBy,
  //     flag: flag,
  //   );
  // }
  DiscussionPoint getDiscussionPoint({
    required String entryBy,
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

  @override
  Widget build(BuildContext context) {
    final decisionState = ref.watch(decisionNotifierProvider);
    final responsibilityState = ref.watch(responsibilityNotifierProvider);

    if (selectedMembers.isEmpty &&
        selectedMemberNames.isNotEmpty &&
        responsibilityState.responsibility.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          selectedMembers = responsibilityState.responsibility
              .where((e) => selectedMemberNames.contains(e.userName))
              .toList();
        });
      });
    }
    return Container(
      color: widget.serialNumber.isEven ? Colors.grey.shade50 : Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cell(
              width: 30,
              child: Center(
                child: Text(widget.serialNumber.toString()),
              ),
            ),
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
            cell(
              width: 200,
              child: SizedBox.expand(
                  child: DropdownButtonFormField<Decision>(
                      value: decisionState.decisions
                              .any((e) => e.decisionName == decision)
                          ? decisionState.decisions.firstWhere(
                              (e) => e.decisionName == decision,
                            )
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
                      items: decisionState.decisions.map((decisionItem) {
                        return DropdownMenuItem<Decision>(
                          value: decisionItem,
                          child: Text(
                            decisionItem.decisionName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          decision = value.decisionName;

                          selectedDecisionCode = value.decisionCode;
                        });
                      })),
            ),
            cell(
              width: 260,
              child: DropdownSearch<Responsibility>.multiSelection(
                items: (filter, infiniteScrollProps) async {
                  print(
                      "Dropdown Items: ${responsibilityState.responsibility.length}");
                  return responsibilityState.responsibility;
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
              ),
            ),
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

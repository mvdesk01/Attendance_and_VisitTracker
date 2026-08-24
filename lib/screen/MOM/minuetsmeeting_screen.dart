// class MinutesOfTheMeetingFormScreen extends StatefulWidget {
//   const MinutesOfTheMeetingFormScreen({super.key});
//
//   @override
//   State<MinutesOfTheMeetingFormScreen> createState() =>
//       _MinutesOfTheMeetingFormScreenState();
// }
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../cleanarchitecture/core/DI/providers_di.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/customer.dart';
import '../../cleanarchitecture/feature/MOM/domain/enteties/meetinghistory_group.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/customerprovider.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/customerstate.dart';
import '../../cleanarchitecture/feature/MOM/presentation/provider/meetingHistory/meetinghistoryprovider.dart';
import 'addnewMeeting.dart';

class MinutesOfTheMeetingFormScreen extends ConsumerStatefulWidget {
  const MinutesOfTheMeetingFormScreen({super.key});

  @override
  ConsumerState<MinutesOfTheMeetingFormScreen> createState() =>
      _MinutesOfTheMeetingFormScreenState();
}

class _MinutesOfTheMeetingFormScreenState
    extends ConsumerState<MinutesOfTheMeetingFormScreen> {
  final TextEditingController meetingDateController = TextEditingController();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final contactPersonController = TextEditingController();
  final storage = const FlutterSecureStorage();

  ///test
  @override
  void initState() {
    super.initState();
    meetingDateController.text =
        DateFormat("dd/MM/yyyy").format(DateTime.now());

    Future.microtask(() async {
      await ref.read(customerNotifierProvider.notifier).loadCustomers();

      final customer = ref.read(customerNotifierProvider).selectedCustomer;

      if (customer != null) {
        await ref
            .read(meetingHistoryNotifierProvider.notifier)
            .loadMeetingHistory(
              customerCode: customer.customerCode,
              meetingDate: meetingDateController.text,
            );
      }
    });
  }

  Future<void> pickMeetingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    meetingDateController.text = DateFormat("dd/MM/yyyy").format(picked);

    final customer = ref.read(customerNotifierProvider).selectedCustomer;

    if (customer != null) {
      await ref
          .read(meetingHistoryNotifierProvider.notifier)
          .loadMeetingHistory(
            customerCode: customer.customerCode,
            meetingDate: meetingDateController.text,
          );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerNotifierProvider);
    final historyState = ref.watch(meetingHistoryNotifierProvider);
    final selectedCustomer = customerState.selectedCustomer;

    // Theme tokens
    final primaryColor = const Color(0xFF0F172A); // Slate 900
    final accentColor = const Color(0xFF4F46E5); // Indigo 600
    final backgroundColor = const Color(0xFFF8FAFC);
    // Slate 50

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Minutes of Meeting",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18.0,
              color: primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("CUSTOMER SELECTION"),
                const SizedBox(height: 10),
                _buildCustomerCard(primaryColor, accentColor, customerState),
                const SizedBox(height: 28),
                _buildSectionHeader("LAST RECORDED MEETING"),
                const SizedBox(height: 10),
                if (historyState.isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (historyState.meetingHistory.isEmpty)
                  _buildNoMeetingCard()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyState.meetingHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPreviousMeetingCard(
                          historyState.meetingHistory[index],
                          accentColor,
                          customerState,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: SafeArea(
            child: historyState.meetingHistory.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Meeting history exists.\nCreate new meeting?",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            // Option to create new meeting anyway
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMeetingScreen(
                                  customer: customerState.selectedCustomer!,
                                  selectedMeetingDate: DateFormat(
                                    "dd/MM/yyyy",
                                  ).parse(meetingDateController.text),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Create Anyway",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: customerState.selectedCustomer == null
                          ? null
                          : () async {
                              final saved = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddMeetingScreen(
                                    customer: customerState.selectedCustomer!,
                                    selectedMeetingDate: DateFormat(
                                      "dd/MM/yyyy",
                                    ).parse(meetingDateController.text),
                                  ),
                                ),
                              );

                              if (saved == true) {
                                await ref
                                    .read(
                                        meetingHistoryNotifierProvider.notifier)
                                    .loadMeetingHistory(
                                      customerCode: customerState
                                          .selectedCustomer!.customerCode,
                                      meetingDate: meetingDateController.text,
                                    );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        "Create New Minutes",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCustomerCard(
    Color primaryColor,
    Color accentColor,
    CustomerState customerState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Customer Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                " *",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownSearch<Customer>(
              selectedItem: customerState.selectedCustomer,
              compareFn: (Customer a, Customer b) =>
                  a.customerCode == b.customerCode,
              itemAsString: (Customer customer) => customer.customerName,
              items: (String filter, LoadProps? loadProps) async {
                if (filter.isEmpty) {
                  return customerState.customers;
                }

                return customerState.customers.where((customer) {
                  return customer.customerName
                      .toLowerCase()
                      .contains(filter.toLowerCase());
                }).toList();
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search Customer",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                emptyBuilder: (context, searchEntry) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No customer found"),
                  ),
                ),
                itemBuilder: (context, customer, isDisabled, isSelected) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      customer.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Customer",
                  hintText: "Select Customer",
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accentColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              onChanged: (customer) async {
                print("========== CUSTOMER CHANGED ==========");

                if (customer == null) {
                  print("Customer is null");
                  return;
                }

                print("Selected Customer : ${customer.customerName}");
                print("Customer Code : ${customer.customerCode}");

                await ref
                    .read(customerNotifierProvider.notifier)
                    .selectCustomer(customer);

                print("Customer Saved");

                await ref
                    .read(meetingHistoryNotifierProvider.notifier)
                    .loadMeetingHistory(
                      customerCode: customer.customerCode,
                      meetingDate: meetingDateController.text,
                    );

                print("History API Finished");
              }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => addNewcustomer(),
              child: Text(
                "Could not find customer. Add new Customer ",
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Text(
                "Meeting Date",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                " *",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: meetingDateController,
            readOnly: true,
            onTap: pickMeetingDate,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
              prefixIcon: const Icon(Icons.event),
              suffixIcon: const Icon(Icons.calendar_month),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousMeetingCard(MeetingHistoryGroup meeting,
      Color accentColor, CustomerState customerState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history_rounded,
                        color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Meeting Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: "Date",
                  value: meeting.meetingDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaChip(
                  icon: Icons.access_time_rounded,
                  label: "Time",
                  value: meeting.meetingTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaChip(
            icon: Icons.people_outline_rounded,
            label: "Members Present",
            value: meeting.memberPresent,
          ),
          const SizedBox(height: 12),
          _buildMetaChip(
            icon: Icons.people_outline_rounded,
            label: "Members Absent",
            value: meeting.memberAbsent,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                // Navigate to AddMeetingScreen with pre-filled data
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMeetingScreen(
                      customer: customerState.selectedCustomer!,
                      meetingHistory: meeting,
                      isEditing: true,
                    ),
                  ),
                );

                if (updated == true) {
                  await ref
                      .read(meetingHistoryNotifierProvider.notifier)
                      .loadMeetingHistory(
                        customerCode:
                            customerState.selectedCustomer!.customerCode,
                        meetingDate: meetingDateController.text,
                      );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text(
                "View Meeting Summary",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMeetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.event_note_rounded, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            "No Previous Meetings",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4),
          Text(
            "There are no past meeting records for this customer.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> addNewcustomer() async {
  //   final customerData = await _showAddCustomerDialog();
  //
  //   if (!mounted || customerData == null) {
  //     return;
  //   }
  //
  //   print(
  //     "Customer Name: ${customerData["name"]}",
  //   );
  //
  //   print(
  //     "Customer Mobile: ${customerData["mobile"]}",
  //   );
  //
  //   print(
  //     "Customer Address: ${customerData["address"]}",
  //   );
  //
  //   print(
  //     "Customer Email: ${customerData["email"]}",
  //   );
  //
  //   print(
  //     "Contact Person: ${customerData["contactPerson"]}",
  //   );
  //
  //   // TODO:
  //   // Call Add Customer API here.
  // }
  Future<void> addNewcustomer() async {
    final customerData = await _showAddCustomerDialog();

    if (!mounted || customerData == null) {
      return;
    }
    nameController.clear();
    mobileController.clear();
    addressController.clear();
    emailController.clear();
    contactPersonController.clear();

    final staffCode = await storage.read(
      key: 'Staff_Code',
    );

    if (staffCode == null || staffCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Staff code not found"),
        ),
      );
      return;
    }

    try {
      final result = await ref.read(addCustomerUseCaseProvider).call(
            customerName: customerData["name"] ?? "",
            contactPerson: customerData["contactPerson"] ?? "",
            address: customerData["address"] ?? "",
            mobileNo: customerData["mobile"] ?? "",
            emailId: customerData["email"] ?? "",
            entryBy: staffCode,
          );

      print("Add Customer Response: $result");

      if (!mounted) return;

      if (result.trim().toLowerCase() == "details save successfully") {
        // Refresh existing customer list API
        await ref.read(customerNotifierProvider.notifier).refreshCustomers();

        if (!mounted) return;

        // Get refreshed customer list
        final customerState = ref.read(customerNotifierProvider);

        // Find newly added customer by name
        final newCustomer = customerState.customers
            .where(
              (customer) =>
                  customer.customerName.trim().toLowerCase() ==
                  (customerData["name"] ?? "").trim().toLowerCase(),
            )
            .firstOrNull;

        if (newCustomer != null) {
          // Select the newly added customer
          await ref
              .read(customerNotifierProvider.notifier)
              .selectCustomer(newCustomer);

          print(
            "New Customer Selected: "
            "${newCustomer.customerName}",
          );

          print(
            "New Customer Code: "
            "${newCustomer.customerCode}",
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Customer added successfully",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
          ),
        );
      }
    } catch (e) {
      print("Add Customer Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to add customer: $e",
          ),
        ),
      );
    }
  }

  Future<Map<String, String>?> _showAddCustomerDialog() async {
    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- HEADER ----------------

                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.blue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add New Customer",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Enter customer details below",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Customer Information",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- NAME ----------------

                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Customer Name",
                      hintText: "Enter customer name",
                      prefixIcon: const Icon(
                        Icons.business_outlined,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- MOBILE ----------------

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "Customer Mobile",
                      hintText: "Enter mobile number",
                      counterText: "",
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- ADDRESS ----------------

                  TextField(
                    controller: addressController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: "Customer Address",
                      hintText: "Enter customer address",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          bottom: 42,
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- EMAIL ----------------

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Customer Email",
                      hintText: "Enter email address",
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- CONTACT PERSON ----------------

                  TextField(
                    controller: contactPersonController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Contact Person",
                      hintText: "Enter contact person",
                      prefixIcon: const Icon(
                        Icons.person_outline,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---------------- BUTTONS ----------------

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              48,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            print(
                                "========== ADD CUSTOMER BUTTON CLICKED ==========");

                            print("Name: ${nameController.text}");
                            print("Mobile: ${mobileController.text}");
                            print("Address: ${addressController.text}");
                            print("Email: ${emailController.text}");
                            print(
                                "Contact Person: ${contactPersonController.text}");

                            final isValid = newcustomernamevalidation();

                            print("Validation result: $isValid");

                            if (!isValid) {
                              print("Customer validation failed");
                              return;
                            }

                            print("Customer validation successful");

                            Navigator.of(dialogContext).pop({
                              "name": nameController.text.trim(),
                              "mobile": mobileController.text.trim(),
                              "address": addressController.text.trim(),
                              "email": emailController.text.trim(),
                              "contactPerson":
                                  contactPersonController.text.trim(),
                            });

                            print("Dialog closed with customer data");
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              48,
                            ),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Add Customer",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    meetingDateController.dispose();
    nameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    emailController.dispose();
    contactPersonController.dispose();

    super.dispose();
  }

  bool newcustomernamevalidation() {
    if (nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Enter customer name",
      );
      return false;
    }

    if (mobileController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Enter customer mobile number",
      );
      return false;
    }

    if (mobileController.text.trim().length != 10) {
      Fluttertoast.showToast(
        msg: "Enter correct mobile number",
      );
      return false;
    }

    if (addressController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Enter customer address",
      );
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Enter customer email ID",
      );
      return false;
    }

    if (contactPersonController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Enter Contact Person",
      );
      return false;
    }

    return true;
  }
}

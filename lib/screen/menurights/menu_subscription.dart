import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../bloc/main_bloc.dart';
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';
import '../../model/subscription/subscriber_model.dart';
import '../../model/subscription/subscription_plan.dart';

class MenuSubscriptionScreen extends StatefulWidget {
  const MenuSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<MenuSubscriptionScreen> createState() => _MenuSubscriptionScreenState();
}

class _MenuSubscriptionScreenState extends State<MenuSubscriptionScreen> {
  final storage = const FlutterSecureStorage();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController staffCodeController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  String token = "";
  String sessUser = "";
  bool isLoading = false;

  DateTime? fromDate;
  DateTime? toDate;

  SubscriptionPlan? selectedPlan;

  List<SubscriptionPlan> plans = [];
  List<SubscriberModel> subscribers = [];

  late MainBloc mainBloc;
  List<Message> searchedUsers = [];
  Message? selectedUser;
  Timer? _debounce;
  bool showSuggestion = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    token = await storage.read(key: "Auth_Token") ?? "";
    sessUser = await storage.read(key: "Staff_Code") ?? "";
    await getPlans();
    await getSubscribers();
  }

  //------------------------------------------------------------
  /// GET ALL PLANS
  //------------------------------------------------------------
  Future<void> getPlans() async {
    try {
      final client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(
        Uri.parse("http://114.143.140.28:8020/api/Subscription/GetAllPlans"),
      );

      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(body);
        plans = (jsonResponse["data"] as List)
            .map((e) => SubscriptionPlan.fromJson(e))
            .toList();
        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading plans: $e");
    }
  }

  //------------------------------------------------------------
  /// GET SUBSCRIBERS
  //------------------------------------------------------------
  Future<void> getSubscribers() async {
    try {
      setState(() => isLoading = true);

      final client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(
          Uri.parse("http://114.143.140.28:8020/api/Subscription/GetAllSubscribers"));

      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        final newList = (json["data"] as List)
            .map((e) => SubscriberModel.fromJson(e))
            .toList();

        setState(() {
          subscribers = newList;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading subscribers: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  //------------------------------------------------------------
  /// ACTIVATE SUBSCRIPTION
  //------------------------------------------------------------
  Future<void> activateSubscription() async {
    if (staffCodeController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please select an employee");
      return;
    }

    if (selectedPlan == null) {
      Fluttertoast.showToast(msg: "Please select a subscription plan");
      return;
    }

    try {
      setState(() => isLoading = true);

      final client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      final request = await client.postUrl(
          Uri.parse("http://114.143.140.28:8020/api/Subscription/AddSubscribe")
      );

      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");

      request.write(jsonEncode({
        "userId": staffCodeController.text,
        "planId": selectedPlan!.planId
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: "Subscription activated successfully");
         _resetForm();
        await getSubscribers();
      } else {
        Fluttertoast.showToast(msg: "Failed to activate subscription");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error activating subscription: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  //------------------------------------------------------------
  /// CANCEL SUBSCRIPTION
  //------------------------------------------------------------
  Future<void> cancelSubscription(String subscriptionNum) async {
    final TextEditingController reasonController = TextEditingController();
    
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Subscription"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to cancel this subscription?"),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason for cancellation",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CLOSE"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Fluttertoast.showToast(msg: "Please provide a reason");
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("CANCEL SUBSCRIPTION", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => isLoading = true);

      final client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      final reason = Uri.encodeComponent(reasonController.text.trim());
      final url = "http://114.143.140.28:8020/api/Subscription/CancelSubscription/$subscriptionNum/$sessUser/$reason";

      final request = await client.postUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: "Subscription cancelled successfully");
        await getSubscribers();
      } else {
        Fluttertoast.showToast(msg: json["message"] ?? "Failed to cancel subscription");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error cancelling subscription: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      selectedUser = null;
      selectedPlan = null;

      searchController.clear();
      staffCodeController.clear();
      staffNameController.clear();
      amountController.clear();
      toDateController.clear();

      searchedUsers.clear();
      showSuggestion = false;

      fromDate = null;
      toDate = null;
    });
  }

  //------------------------------------------------------------
  /// SEARCH USER
  //------------------------------------------------------------
  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      String sanitizedText = text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');

      if (sanitizedText.isEmpty) {
        setState(() {
          searchedUsers.clear();
          showSuggestion = false;
        });
      } else {
        if (token.isNotEmpty) {
          mainBloc.add(SearchbyStaffcodeEvents(
            staffcode: sanitizedText,
            token: token,
          ));
        }
      }
    });
  }

  Future<void> selectDate(bool from) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      if (from) {
        fromDate = picked;
        _updateToDate();
      }
    });
  }

  void _updateToDate() {
    if (fromDate != null && selectedPlan != null) {
      toDate = DateTime(
        fromDate!.year,
        fromDate!.month + selectedPlan!.duration,
        fromDate!.day,
      );
      toDateController.text = DateFormat("dd-MM-yyyy").format(toDate!);
    } else {
      toDate = null;
      toDateController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Menu Subscription", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          if (state is SearchbyStaffcodeLoadingPage) {
            setState(() => isLoading = true);
          } else if (state is SearchbyStaffcodeLoadedPage) {
            setState(() {
              isLoading = false;
              searchedUsers = state.userResponse?.data
                      .map((e) => Message(
                            staffCode: e.staffCode,
                            displayName: e.displayName,
                            mobileNo: e.mobileNo,
                            emailId: e.emailId,
                          ))
                      .toList() ??
                  [];
              showSuggestion = true;
            });
          } else if (state is SearchbyStaffcodeErrorPage) {
            setState(() {
              isLoading = false;
              searchedUsers.clear();
            });
          }
        },
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: getSubscribers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSubscriptionForm(),
                    const SizedBox(height: 25),
                    _buildSubscribedUsersHeader(),
                    const SizedBox(height: 10),
                    _buildSubscribedUsersList(),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionForm() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Activate New Subscription", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 15),
            _buildSearchBar(),
            if (showSuggestion && searchedUsers.isNotEmpty && selectedUser == null)
              _buildSuggestionsList(),
            const SizedBox(height: 15),
            _buildReadOnlyField(staffNameController, "Staff Name", Icons.person),
            const SizedBox(height: 15),
            _buildPlanDropdown(),
            const SizedBox(height: 15),
            _buildDatePickerField(),
            const SizedBox(height: 15),
            _buildReadOnlyField(toDateController, "To Date", Icons.event_available),
            const SizedBox(height: 15),
            _buildReadOnlyField(amountController, "Amount", Icons.currency_rupee),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : activateSubscription,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("ACTIVATE", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildPlanDropdown() {
    return DropdownButtonFormField<SubscriptionPlan>(
      value: selectedPlan,
      decoration: InputDecoration(
        labelText: "Subscription Plan",
        prefixIcon: const Icon(Icons.workspace_premium, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: plans.map((plan) {
        return DropdownMenuItem(
          value: plan,
          child: Text("${plan.planName} (${plan.duration} Month)"),
        );
      }).toList(),
      onChanged: (plan) {
        if (plan == null) return;
        setState(() {
          selectedPlan = plan;
          amountController.text = plan.price.toStringAsFixed(0);
          
          // Auto-fill dates
          final now = DateTime.now();
          fromDate ??= DateTime(now.year, now.month, now.day);
          _updateToDate();
        });
      },
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () => selectDate(true),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "From Date",
          prefixIcon: const Icon(Icons.calendar_month, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          fromDate == null ? "Select Start Date" : DateFormat("dd-MM-yyyy").format(fromDate!),
          style: TextStyle(color: fromDate == null ? Colors.grey.shade600 : Colors.black),
        ),
      ),
    );
  }

  Widget _buildSubscribedUsersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Active Subscriptions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text("${subscribers.length} total", style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSubscribedUsersList() {
    if (subscribers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(child: Text("No Active Subscribers Found", style: TextStyle(color: Colors.grey))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subscribers.length,
      itemBuilder: (context, index) => buildSubscriberCard(subscribers[index]),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      onChanged: onSearchTextChanged,
      decoration: InputDecoration(
        labelText: "Search Employee (Code/Name)",
        prefixIcon: const Icon(Icons.search, color: Colors.blue),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  searchController.clear();
                  staffCodeController.clear();
                  staffNameController.clear();
                  setState(() {
                    selectedUser = null;
                    searchedUsers.clear();
                    showSuggestion = false;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: searchedUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = searchedUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, color: Colors.blue, size: 20)),
            title: Text(user.displayName ?? "No Name", style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(user.staffCode ?? ""),
            onTap: () {
              setState(() {
                selectedUser = user;
                searchController.text = "${user.displayName} (${user.staffCode})";
                staffCodeController.text = user.staffCode ?? "";
                staffNameController.text = user.displayName ?? "";
                searchedUsers.clear();
                showSuggestion = false;
              });
            },
          );
        },
      ),
    );
  }

  Widget buildSubscriberCard(SubscriberModel subscriber) {
    final bool isExpired = subscriber.endDate.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: subscriber.isActive ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(Icons.person, color: subscriber.isActive ? Colors.green : Colors.red),
        ),
        title: Text(subscriber.userName ?? subscriber.userId, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("ID: ${subscriber.userId}", style: TextStyle(color: Colors.grey.shade600)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: subscriber.isActive ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subscriber.isActive ? "ACTIVE" : "INACTIVE",
            style: TextStyle(color: subscriber.isActive ? Colors.green.shade800 : Colors.red.shade800, 
              fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _buildInfoRow(Icons.workspace_premium, "Plan", subscriber.planName, color: Colors.amber.shade800),
                _buildInfoRow(Icons.currency_rupee, "Amount", "₹ ${subscriber.amount.toStringAsFixed(0)}", color: Colors.green.shade700),
                _buildInfoRow(Icons.calendar_today, "Validity", "${formatDate(subscriber.startDate)} to ${formatDate(subscriber.endDate)}", 
                  color: isExpired ? Colors.red : Colors.blue.shade700),
                _buildInfoRow(Icons.receipt_long, "Reference", subscriber.subscriptionNo, color: Colors.grey.shade700),
                _buildInfoRow(Icons.payment, "Payment", subscriber.paymentStatus, color: Colors.deepPurple.shade700),
                const SizedBox(height: 10),
                if (subscriber.isActive)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => cancelSubscription(subscriber.subscriptionNo),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text("CANCEL SUBSCRIPTION", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);
}

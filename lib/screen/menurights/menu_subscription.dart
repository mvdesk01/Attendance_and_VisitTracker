import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
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
  State<MenuSubscriptionScreen> createState() =>
      _MenuSubscriptionScreenState();
}

class _MenuSubscriptionScreenState extends State<MenuSubscriptionScreen> {
  final storage = const FlutterSecureStorage();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController staffCodeController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String token = "";

  bool isLoading = false;
  bool isEditMode = false;

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

    await getPlans();

    await getSubscribers();
  }

//------------------------------------------------------------
  /// GET ALL PLANS
//------------------------------------------------------------

  Future<void> getPlans() async {
    try {
      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(
        Uri.parse(
            "http://114.143.140.28:8020/api/Subscription/GetAllPlans"),
      );

      request.headers.set(
          HttpHeaders.authorizationHeader,
          "Bearer $token");

      request.headers.set(
          HttpHeaders.contentTypeHeader,
          "application/json");

      final response = await request.close();

      final body =
      await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(body);

        plans = (jsonResponse["data"] as List)
            .map((e) => SubscriptionPlan.fromJson(e))
            .toList();

        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

//------------------------------------------------------------
  /// GET SUBSCRIBERS
//------------------------------------------------------------

  Future<void> getSubscribers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.getUrl(
          Uri.parse(
              "http://114.143.140.28:8020/api/Subscription/GetAllSubscribers"));

      request.headers.set(
          HttpHeaders.authorizationHeader,
          "Bearer $token");

      request.headers.set(
          HttpHeaders.contentTypeHeader,
          "application/json");

      final response = await request.close();

      final body =
      await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final json = jsonDecode(body);

        subscribers = (json["data"] as List)
            .map((e) => SubscriberModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

//------------------------------------------------------------
  /// ADD/UPDATE SUBSCRIPTION
//------------------------------------------------------------

  Future<void> addSubscription() async {
    if (staffCodeController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Select User");

      return;
    }

    if (selectedPlan == null) {
      Fluttertoast.showToast(
          msg: "Select Plan");

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await client.postUrl(
          Uri.parse(
              "http://114.143.140.28:8020/api/Subscription/AddSubscribe")
      );

      request.headers.set(
          HttpHeaders.authorizationHeader,
          "Bearer $token");

      request.headers.set(
          HttpHeaders.contentTypeHeader,
          "application/json");

      request.write(
          jsonEncode({
            "userId": staffCodeController.text,
            "planId": selectedPlan!.planId
          })
      );

      final response =
      await request.close();

      final body =
      await response.transform(utf8.decoder).join();

      final json = jsonDecode(body);

      if (response.statusCode == 200 &&
          json["status"] == true) {
        Fluttertoast.showToast(
            msg: isEditMode ? "Subscription Updated" : "Subscription Added");

        // Refresh list
        await getSubscribers();
        
        // Reset Form
        _resetForm();
      }
      else {
        Fluttertoast.showToast(
            msg: json["message"] ?? "Failed");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  void _resetForm() {
    setState(() {
      isEditMode = false;
      selectedUser = null;
      selectedPlan = null;
      searchController.clear();
      staffCodeController.clear();
      staffNameController.clear();
      amountController.clear();
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

//------------------------------------------------------------

  Future<void> selectDate(bool from) async {
    DateTime? picked =
    await showDatePicker(

      context: context,

      initialDate: fromDate ?? DateTime.now(),

      firstDate: DateTime(2024),

      lastDate: DateTime(2035),

    );

    if (picked == null) return;

    setState(() {
      if (from) {
        fromDate = picked;

        if (selectedPlan != null) {
          toDate = DateTime(

            picked.year,
            picked.month + selectedPlan!.duration,

            picked.day,

          );
        }
      }
    });
  }

//------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Subscription"),
        centerTitle: true,
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  ///========================
                  /// Subscription Form
                  ///========================

                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [

                          _buildSearchBar(),
                          if (showSuggestion && searchedUsers.isNotEmpty && selectedUser == null)
                            _buildSuggestionsList(),

                          const SizedBox(height: 15),

                          TextField(
                            controller: staffNameController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Staff Name",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          DropdownButtonFormField<SubscriptionPlan>(
                            value: selectedPlan,
                            decoration: InputDecoration(
                              labelText: "Subscription Plan",
                              prefixIcon:
                              const Icon(Icons.workspace_premium),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: plans.map((plan) {
                              return DropdownMenuItem(
                                value: plan,
                                child: Text(
                                  "${plan.planName} (${plan.duration} Month)",
                                ),
                              );
                            }).toList(),
                            onChanged: (plan) {
                              if (plan == null) return;

                              setState(() {
                                selectedPlan = plan;

                                amountController.text =
                                    plan.price.toStringAsFixed(0);

                                fromDate ??= DateTime.now();

                                toDate = DateTime(
                                  fromDate!.year,
                                  fromDate!.month + plan.duration,
                                  fromDate!.day,
                                );
                              });
                            },
                          ),

                          const SizedBox(height: 15),

                          InkWell(
                            onTap: () => selectDate(true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "From Date",
                                prefixIcon:
                                const Icon(Icons.calendar_month),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                fromDate == null
                                    ? "Select From Date"
                                    : DateFormat("dd-MM-yyyy")
                                    .format(fromDate!),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: "To Date",
                              prefixIcon:
                              const Icon(Icons.event_available),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              toDate == null
                                  ? "-"
                                  : DateFormat("dd-MM-yyyy")
                                  .format(toDate!),
                            ),
                          ),

                          const SizedBox(height: 15),

                          TextField(
                            controller: amountController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Amount",
                              prefixIcon:
                              const Icon(Icons.currency_rupee),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          Row(
                            children: [
                              if (isEditMode) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    child: const Text("CANCEL"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: addSubscription,
                                  icon: const Icon(Icons.save),
                                  label: Text(
                                    isEditMode
                                        ? "UPDATE SUBSCRIPTION"
                                        : "SAVE SUBSCRIPTION",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Subscribed Users",
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge,
                    ),
                  ),

                  const SizedBox(height: 10),

                  subscribers.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(25),
                    child: Text(
                      "No Subscribers Found",
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: subscribers.length,
                    itemBuilder: (context, index) {
                      final subscriber =
                      subscribers[index];

                      return buildSubscriberCard(
                        subscriber,
                      );
                    },
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      onChanged: onSearchTextChanged,
      decoration: InputDecoration(
        labelText: "Search Staff Code / Name",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        suffixIcon: (selectedUser != null || searchController.text.isNotEmpty)
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
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: searchedUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = searchedUsers[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
            title: Text(user.displayName ?? "No Name", style: const TextStyle(fontWeight: FontWeight.w500)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscriber.userName ?? "N/A",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subscriber.userId,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: subscriber.isActive
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscriber.isActive
                        ? "ACTIVE"
                        : "INACTIVE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 12),

            buildInfoRow(
              Icons.workspace_premium,
              subscriber.planName,
            ),

            buildInfoRow(
              Icons.currency_rupee,
              "₹ ${subscriber.amount.toStringAsFixed(0)}",
            ),

            buildInfoRow(
              Icons.calendar_month,
              "${formatDate(subscriber.startDate)}  -  ${formatDate(
                  subscriber.endDate)}",
            ),

            buildInfoRow(
              Icons.receipt_long,
              subscriber.subscriptionNo,
            ),

            buildInfoRow(
              Icons.payments,
              subscriber.paymentStatus,
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

                    staffCodeController.text =
                        subscriber.userId;

                    staffNameController.text =
                        subscriber.userName ?? subscriber.userId;

                    amountController.text =
                        subscriber.amount.toStringAsFixed(0);

                    fromDate = subscriber.startDate;
                    toDate = subscriber.endDate;

                    selectedPlan = plans.firstWhere(
                          (element) =>
                      element.planId ==
                          subscriber.planId,
                      orElse: () => plans.first,
                    );

                    searchController.text = "${subscriber.userName ?? ""} (${subscriber.userId})";
                    selectedUser = null;
                    showSuggestion = false;
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon,
      String value,) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat(
      "dd-MM-yyyy",
    ).format(date);
  }

}

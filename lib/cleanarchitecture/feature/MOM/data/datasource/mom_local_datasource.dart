import 'dart:convert';

import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/data/model/ResponsibiltyModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/customer_model.dart';
import '../model/decision_model.dart';

abstract class MomLocalDatasource {
  ///customer
  Future<void> cacheCustomers(List<CustomerModel> customers);

  Future<List<CustomerModel>> getCachedCustomers();

  Future<void> saveSelectedCustomer(CustomerModel customer);

  Future<CustomerModel?> getSelectedCustomer();

  ///decision
  Future<void> cacheDecisions(List<DecisionModel> decisions);

  Future<List<DecisionModel>> getCachedDecisions();

  Future<void> saveSelectedDecision(DecisionModel decision);

  Future<DecisionModel?> getSelectedDecision();

  ///responsibility

  Future<void> cacheResponsibility(List<Responsibiltymodel> responsibility);

  Future<List<Responsibiltymodel>> getcachedResponsibility();

  Future<void> savedSelectedResponsibility(Responsibiltymodel responsibility);

  Future<Responsibiltymodel?> getSelectedResposibility();
}

class MomLocalDatasourceImpl implements MomLocalDatasource {
  static const customerKey = "mom_customers";
  static const selectedCustomerKey = "mom_selected_customer";

  static const decisionKey = "mom_decisions";
  static const selectedDecisionKey = "mom_selected_decision";

  static const responsibilitykey = "mom_responsibility";
  static const selectedresponsibility = "mom_selected_responsibility";

  ///customer
  @override
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      customerKey,
      jsonEncode(
        customers.map((e) => e.toJson()).toList(),
      ),
    );
  }

  @override
  Future<List<CustomerModel>> getCachedCustomers() async {
    final pref = await SharedPreferences.getInstance();

    final json = pref.getString(customerKey);

    if (json == null || json.isEmpty) {
      return [];
    }

    final List list = jsonDecode(json);

    return list.map((e) => CustomerModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveSelectedCustomer(CustomerModel customer) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      selectedCustomerKey,
      jsonEncode(customer.toJson()),
    );
  }

  @override
  Future<CustomerModel?> getSelectedCustomer() async {
    final pref = await SharedPreferences.getInstance();

    final json = pref.getString(selectedCustomerKey);

    if (json == null) return null;

    return CustomerModel.fromJson(
      jsonDecode(json),
    );
  }

  ///decision

  @override
  Future<void> cacheDecisions(List<DecisionModel> decisions) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      decisionKey,
      jsonEncode(
        decisions.map((e) => e.toJson()).toList(),
      ),
    );
  }

  @override
  Future<List<DecisionModel>> getCachedDecisions() async {
    final pref = await SharedPreferences.getInstance();

    final json = pref.getString(decisionKey);

    if (json == null || json.isEmpty) {
      return [];
    }

    final List list = jsonDecode(json);

    return list.map((e) => DecisionModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveSelectedDecision(DecisionModel decision) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      selectedDecisionKey,
      jsonEncode(decision.toJson()),
    );
  }

  @override
  Future<DecisionModel?> getSelectedDecision() async {
    final pref = await SharedPreferences.getInstance();

    final json = pref.getString(selectedDecisionKey);

    if (json == null) return null;

    return DecisionModel.fromJson(
      jsonDecode(json),
    );
  }

  ///responsibility
  @override
  Future<void> cacheResponsibility(
      List<Responsibiltymodel> responsibility) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      responsibilitykey,
      jsonEncode(
        responsibility.map((e) => e.toJson()).toList(),
      ),
    );
  }

  @override
  Future<List<Responsibiltymodel>> getcachedResponsibility() async {
    final pref = await SharedPreferences.getInstance();

    final json = pref.getString(responsibilitykey);

    if (json == null || json.isEmpty) {
      return [];
    }

    final List list = jsonDecode(json);

    return list.map((e) => Responsibiltymodel.fromJson(e)).toList();
  }

  @override
  Future<void> savedSelectedResponsibility(
      Responsibiltymodel responsibility) async {
    final pref = await SharedPreferences.getInstance();

    await pref.setString(
      selectedresponsibility,
      jsonEncode(responsibility.toJson()),
    );
  }

  @override
  Future<Responsibiltymodel?> getSelectedResposibility() async {
    final pref = await SharedPreferences.getInstance();

    final json = pref.getString(selectedresponsibility);

    if (json == null) return null;

    return Responsibiltymodel.fromJson(
      jsonDecode(json),
    );
  }
}

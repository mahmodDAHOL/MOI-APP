import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../utils/helper.dart';
import 'shared_preferences_controller.dart';

class ReportController extends GetxController {
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();
  var showAggregateValue = false.obs; // Checkbox state
  RxString selectedGroup = "Monthly".obs; // Dropdown value
  Rx<DateTimeRange> dateRange =
      DateTimeRange(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 12, 31),
      ).obs; // Date range

  Future<Map<String, dynamic>?> getReportData(String reportName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final String rawUrl = '$domain/api/method/frappe.desk.query_report.run';

    final Map<String, dynamic> body = {
      "report_name": reportName,
      "filters": jsonEncode({
        "company": "Ministry of Information",
        "is_active": "Yes",
        "status": "Open",
      }),
      "ignore_prepared_report": false.toString(),
      "are_default_filters": true.toString(),
      "_": DateTime.now().millisecondsSinceEpoch.toString(),
    };
    // String bodyEncoded = Uri.encodeComponent(jsonEncode(body));
    final Uri url = Uri.parse(rawUrl).replace(queryParameters: body);
    // String url = "$rawUrl?$bodyEncoded";
    final headers = {
      ...session.headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['message'] != null) {
        return jsonData['message'];
      } else {
        return null;
      }
    } else {
      print("Failed to load report. Status code: ${response.statusCode}");
      return null;
    }
  }
}

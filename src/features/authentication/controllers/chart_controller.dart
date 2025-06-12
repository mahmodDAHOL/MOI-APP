import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:moi_app/src/utils/helper.dart';

import 'shared_preferences_controller.dart';

class ChartController extends GetxController {
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();

  Future<Map<String, dynamic>> getChartParams(String chartName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.form.load.getdoc",
    );

    final reqBody = {
      'doctype': 'Dashboard Chart',
      'name': chartName,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await session.post(reportViewUrl, body: reqBody);
    final data = jsonDecode(response.body);

    Map<String, dynamic> chartParams =
        data['docs'] != null ? data['docs'][0] : {};
    return chartParams;
  }

  Future<ChartInfo> getChartInfo(String chartName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    Map<String, dynamic> chartParams = await getChartParams(chartName);

    final url = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get",
    );

    Map<String, dynamic> body = {
      'chart_name': 'Department Wise Openings',
      'filters': chartParams['filters_json'],
      'refresh': 1,
      'time_interval': "",
      'timespan': "",
      'from_date': "",
      'to_date': "",
      'heatmap_year': "",
    };

    final encodedBody = buildQueryString(body);

    final headers = {
      ...session.headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final res = await http.post(url, headers: headers, body: encodedBody);
    final resData = jsonDecode(res.body);
    Map<String, dynamic> chartData;
    if (resData["message"] != null) {
      chartData = resData["message"];
    } else {
      chartData = {};
    }
    return ChartInfo(chartParams: chartParams, chartData: chartData);
  }

  Future<Map<String, dynamic>> getChartData(
    Map<String, dynamic> chartParams,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get",
    );
    String docJson = jsonEncode(chartParams);
    String reqBody = Uri.encodeComponent(docJson);
    final headers = {...session.headers};

    http.Response response = await http.post(
      reportViewUrl,
      headers: headers,
      body: reqBody,
    );
    Map<String, dynamic> data = jsonDecode(response.body);
    Map<String, dynamic> doctypeData;
    if (data['docs'] != null) {
      doctypeData = data['docs'][0];
    } else {
      doctypeData = {};
    }
    return doctypeData;
  }

  Future<ChartInfo> getQueryReport(String reportName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.query_report.run",
    );
    Map<String, dynamic> chartParams = await getChartParams(reportName);

    final reqBody = {
      'report_name': reportName,
      'filters': chartParams['filters_json'].toString(),
      'ignore_prepared_report': '1',
    };

    final response = await session.post(reportViewUrl, body: reqBody);
    final chartData = jsonDecode(response.body)['message'];

    return ChartInfo(chartParams: chartParams, chartData: chartData);
  }
}

class ChartInfo {
  final Map<String, dynamic> chartParams;
  final Map<String, dynamic> chartData;

  ChartInfo({required this.chartParams, required this.chartData});
}

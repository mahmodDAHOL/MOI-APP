import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:moi_app/src/utils/helper.dart';

import '../models/dashbaord_card_model.dart';
import '../models/dashboard_chart_model.dart';
import '../screens/home/chart_builder.dart';
import 'shared_preferences_controller.dart';

class ChartController extends GetxController {
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();

  Future<DashboardChart> getDashboardChartParams(String chartName) async {
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

    DashboardChart chartParams =
        data['docs'] != null
            ? DashboardChart.fromMap(data['docs'][0])
            : DashboardChart.fromMap({});
    if (chartParams.customOptions != "") {
      Map customOptions = jsonDecode(chartParams.customOptions);
      if (customOptions['colors'] != null &&
          customOptions['colors'].isNotEmpty) {
        chartParams.color = customOptions['colors'][0];
      }
    }
    return chartParams;
  }

  Future<ChartRequestParams> getChartRequestBody(chartMeta) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final String? company = prefs.getString("company");
    String chartName = chartMeta.chartName;
    Uri url;
    Map<String, dynamic> body;

    switch (chartMeta.chartType) {
      case "Custom":
        url = Uri.parse(
          "$domain/api/method/${await getDashboardChartSource(chartName)}",
        );
        body = {
          'chart_name': chartMeta.chartName,
          'filters': '{"company":"$company"}',
          'refresh': 1,
          'time_interval': "",
          'timespan': "",
          'from_date': "",
          'to_date': "",
          'heatmap_year': "",
        };
        break;

      case "Report":
        url = Uri.parse("$domain/api/method/frappe.desk.query_report.run");
        String filters = "";
        Map filtersMap = {};
        if (chartMeta.dynamicFiltersJson.contains("month") &&
            chartMeta.dynamicFiltersJson.contains("year")) {
          final now = DateTime.now();
          filtersMap = {
            'month': '${now.month}', // 1 - 12
            'year': '${now.year}', // e.g. 2025
            'company': company,
          };
        }
        Map<String, dynamic> filtersJson = jsonDecode(chartMeta.filtersJson);
        filters = jsonEncode({...filtersMap, ...filtersJson});
        body = {
          'report_name': chartMeta.reportName,
          'filters': filters,
          'ignore_prepared_report': 1,
        };
        break;

      default:
        url = Uri.parse(
          "$domain/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get",
        );
        body = {
          'chart_name': chartMeta.chartName,
          'filters': chartMeta.filtersJson,
          'refresh': 1,
          'time_interval': "",
          'timespan': "",
          'from_date': "",
          'to_date': "",
          'heatmap_year': "",
        };
    }
    return ChartRequestParams(url: url, body: body);
  }

  Future<Map<String, List<AxisData>>> getChartDataset(
    DashboardChart chartMeta,
  ) async {
    ChartRequestParams chartRequestParams = await getChartRequestBody(
      chartMeta,
    );
    Map<String, dynamic> body = chartRequestParams.body;
    Uri url = chartRequestParams.url;
    final encodedBody = buildQueryString(body);

    final headers = {
      ...session.headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final res = await http.post(url, headers: headers, body: encodedBody);
    final resData = jsonDecode(res.body);

    Map<String, dynamic> chartData;
    if (resData["message"] != null) {
      if (chartMeta.chartType == "Report") {
        chartData = resData["message"]['chart']['data'];
        chartMeta.color =
            resData["message"]["chart"]["colors"]?.first ?? chartMeta.color;
      } else {
        chartData = resData["message"];
      }
    } else {
      chartData = {};
    }

    return _processChartData(chartMeta, chartData);
  }

  Map<String, List<AxisData>> _processChartData(
    DashboardChart chartMeta,
    Map<String, dynamic> chartDataset,
  ) {
    Map<String, List<AxisData>> chartData = {};

    if (chartDataset.containsKey('labels') &&
        chartDataset.containsKey('datasets')) {
      List labels = chartDataset['labels'];
      List datasets = chartDataset['datasets'];
      for (var entry in datasets) {
        String name = entry['name'];
        List value = entry['values'];
        chartData[name] = List.generate(
          labels.length,
          (i) => AxisData(labels[i].toString(), value[i]),
        );
      }
    }

    return chartData;
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

  Future<ChartDataset> getQueryReport(String reportName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.query_report.run",
    );
    // Map<String, dynamic> chartParams = await getChartParams(reportName);
    Map<String, dynamic> chartParams = {};

    final reqBody = {
      'report_name': reportName,
      'filters': chartParams['filters_json'].toString(),
      'ignore_prepared_report': '1',
    };

    final response = await session.post(reportViewUrl, body: reqBody);
    final chartData = jsonDecode(response.body)['message'];

    return ChartDataset(chartParams: chartParams, chartData: chartData);
  }

  Future<String?> getDashboardChartSource(String chartName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard_chart_source.dashboard_chart_source.get_config",
    );
    final reqBody = {'name': chartName};

    final response = await session.post(reportViewUrl, body: reqBody);
    final chartData = jsonDecode(response.body)['message'];

    String? source = getSource(chartData, chartName);
    return source;
  }

}

class ChartDataset {
  final Map<String, dynamic> chartParams;
  final Map<String, dynamic> chartData;

  ChartDataset({required this.chartParams, required this.chartData});
}

class ChartRequestParams {
  final Uri url;
  final Map<String, dynamic> body;

  ChartRequestParams({required this.url, required this.body});
}

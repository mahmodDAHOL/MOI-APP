import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:moi_app/src/utils/helper.dart';

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
    return chartParams;
  }

  Future<List<AxisData>> getChartDataset(DashboardChart chartMeta) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final url = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get",
    );

    Map<String, dynamic> body = {
      'chart_name': chartMeta.chartName,
      'filters': chartMeta.filtersJson,
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

    return _processChartData(chartMeta, chartData);
  }

  List<AxisData> _processChartData(
    DashboardChart chartMeta,
    Map<String, dynamic> chartDataset,
  ) {
    List<AxisData> chartData = [];

    String chartType = chartMeta.chartType.toLowerCase();
    if (chartDataset.containsKey('labels') &&
        chartDataset.containsKey('datasets')) {
      List labels = chartDataset['labels'];
      List datasets = chartDataset['datasets'];
      chartData = List.generate(
        labels.length,
        (i) => AxisData(labels[i].toString(), datasets[0]['values'][i]),
      );
    }
    // switch (chartType) {
    //   case 'count':
    //   case 'sum':
    //   case 'average':
    //   case 'group by':

    //   case 'custom':
    //   case 'report':
    //   default:
    //     print('Unknown chart type: ${chartMeta.chartType}');
    //     break;
    // }

    // Build dataset based on chart visualization type
    // switch (chartMeta.type.toLowerCase()) {
    //   case 'line':
    //   case 'bar':
    //     result['labels'] = labels;
    //     result['datasets'] = [
    //       {'values': values},
    //     ];
    //     break;

    //   case 'pie':
    //   case 'donut':
    //   case 'percentage':
    //     result['labels'] = labels;
    //     result['values'] = values;
    //     break;

    //   // case 'heatmap':
    //   //   // Heatmap expects 2D grid of values
    //   //   result['grid'] = _generateHeatmapGrid(values);
    //   //   break;

    //   default:
    //     result['labels'] = [];
    //     result['datasets'] = [];
    //     print('Unsupported chart type: ${chartMeta.type}');
    // }

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
}

class ChartDataset {
  final Map<String, dynamic> chartParams;
  final Map<String, dynamic> chartData;

  ChartDataset({required this.chartParams, required this.chartData});
}

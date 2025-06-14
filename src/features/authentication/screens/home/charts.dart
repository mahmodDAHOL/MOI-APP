import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/chart_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/dashboard_chart_model.dart';
import 'chart_builder.dart';
import 'dynamic_list.dart';

Widget buildChartsPageFutureBuilder(String app) {
  final HomeController homeController = Get.put(HomeController());
  final ChartController chartController = Get.put(ChartController());

  return DynamicListBuilder(
    future: homeController.fetchDesktopPageElements(app),
    sectionKey: 'charts',
    itemBuilder: (context, index, item) {
      return FutureBuilder<DashboardChart>(
        future: chartController.getDashboardChartParams(item['chart_name']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          DashboardChart chartMeta = snapshot.data!;
          return _buildBarChart(chartMeta);
        },
      );
    },
  );
}

Widget _buildBarChart(DashboardChart chartMeta) {
  final ChartController chartController = Get.put(ChartController());
  return FutureBuilder<List<AxisData>>(
    future: chartController.getChartDataset(chartMeta),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container();
      }
      if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      }

      List<AxisData> chartData = snapshot.data!;
      String chartType = chartMeta.type;
      String chartTitle = chartMeta.chartName;

      return ChartBuilderScreen(
        chartData: chartData,
        chartType: chartType,
        chartTitle: chartTitle,
      );
    },
  );
}

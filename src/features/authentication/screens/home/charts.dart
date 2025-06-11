import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import 'chart_builder.dart';
import 'dynamic_list.dart';

Widget buildChartsPageFutureBuilder(String app) {
  final HomeController homeController = Get.put(HomeController());

  return DynamicListBuilder(
    future: homeController.fetchDesktopPageElements(app),
    sectionKey: 'charts',
    itemBuilder: (context, index, item) {
      return FutureBuilder<ChartInfo>(
        future: homeController.getChartInfo(item["chart_name"]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          ChartInfo chartInfo = snapshot.data!;
          String chartType = chartInfo.chartParams['type'];
          String chartTitle = chartInfo.chartParams['chart_name'];

          if (chartInfo.chartData.isEmpty) {
            return ChartBuilderScreen(
              chartData: [],
              chartType: chartType,
              chartTitle: chartTitle,
            );
          }

          List labels = chartInfo.chartData['labels'];
          List datasets = chartInfo.chartData['datasets'];
          List<AxisData> chartData = List.generate(
            labels.length,
            (i) => AxisData(labels[i].toString(), datasets[0]['values'][i]),
          );

          return ChartBuilderScreen(
            chartData: chartData,
            chartType: chartType,
            chartTitle: chartTitle,
          );
        },
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../controllers/chart_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/dashboard_chart_model.dart';
import 'chart_builder.dart';
import 'dashboard_card.dart';
import 'dynamic_list.dart';

Widget buildChartsPage(String app) {
  final HomeController homeController = Get.put(HomeController());

  return Center(
    child: Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200), // Adjust as needed
          child: DynamicListBuilder(
            future: homeController.fetchDesktopPageElements(app),
            sectionKey: 'number_cards',
            itemBuilder: (context, index, item) {
              return getCardItem(item);
            },
          ),
        ),
        Expanded(
          child: DynamicListBuilder(
            future: homeController.fetchDesktopPageElements(app),
            sectionKey: 'charts',
            itemBuilder: (context, index, item) {
              return getChartItem(item);
            },
          ),
        ),
      ],
    ),
  );
}

Widget getChartItem(Map item) {
  final ChartController chartController = Get.put(ChartController());
  return FutureBuilder<DashboardChart>(
    future: chartController.getDashboardChartParams(item['chart_name']),
    builder: (context, chartMetaSnapshot) {
      if (chartMetaSnapshot.connectionState == ConnectionState.waiting) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simulated title
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      width: 100,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Simulated bar/chart area
                  Expanded(
                    child: Row(
                      children:
                          List.generate(10, (i) => i).map((i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Container(
                                width: 10,
                                height: 100,
                                color: Colors.grey.shade300,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (chartMetaSnapshot.hasError) {
        return Center(
          child: Text("Chart Meta Error: ${chartMetaSnapshot.error}"),
        );
      }

      DashboardChart chartMeta = chartMetaSnapshot.data!;

      return FutureBuilder<Map<String, List<AxisData>>>(
        future: chartController.getChartDataset(chartMeta),
        builder: (context, chartDataSnapshot) {
          if (chartDataSnapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simulated title
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          width: 100,
                          height: 16,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Simulated bar/chart area
                      Expanded(
                        child: Row(
                          children:
                              List.generate(10, (i) => i).map((i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Container(
                                    width: 10,
                                    height: 100,
                                    color: Colors.grey.shade300,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          // if (chartDataSnapshot.hasError) {
          //   return Center(
          //     child: Text("Chart Data Error: ${chartDataSnapshot.error}"),
          //   );
          // }

          Map<String, List<AxisData>> chartData = chartDataSnapshot.data!;

          return KeepAliveChart(
            chart: ChartBuilderScreen(
              chartData: chartData,
              chartMeta: chartMeta,
            ),
          );
        },
      );
    },
  );
}

class KeepAliveChart extends StatefulWidget {
  final Widget chart;

  const KeepAliveChart({super.key, required this.chart});

  @override
  State<KeepAliveChart> createState() => _KeepAliveChartState();
}

class _KeepAliveChartState extends State<KeepAliveChart>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for keep-alive to work
    return widget.chart;
  }
}

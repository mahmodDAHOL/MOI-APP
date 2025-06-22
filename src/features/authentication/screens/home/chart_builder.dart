import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../../../utils/helper.dart';
import '../../controllers/home_controller.dart';
import '../../models/dashboard_chart_model.dart';

class ChartBuilderScreen extends StatelessWidget {
  ChartBuilderScreen({
    super.key,
    required this.chartData,
    required this.chartMeta,
  });
  final HomeController homeController = Get.put(HomeController());

  final Map<String, List<AxisData>> chartData;
  final DashboardChart chartMeta;
  Color get color => hexToColor(chartMeta.color);
  String? get firstKey {
    if (chartData.isEmpty) return null;
    return chartData.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    String chartType = chartMeta.type;
    String chartTitle = chartMeta.chartName;
    bool showLegend = false;
    if (chartData.isNotEmpty) {
      showLegend =
          (['Donut', 'Pie'].contains(chartType) &&
              chartData[firstKey]!.isNotEmpty) ||
          (chartType == "Line" && chartData.length > 1) ||
          (chartType == "Bar" && chartData.length > 1);
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            chartTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 250,
            width: double.infinity,
            child:
                chartData.isEmpty
                    ? Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No Data Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    : Stack(
                      fit: StackFit.expand,
                      children: [
                        buildChart(chartType),
                        if (showLegend)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Opacity(
                              opacity: 0.4,
                              child: LegendBoxWidget(chartType),
                            ),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget buildChart(String chartType) {
    switch (chartType.toLowerCase()) {
      case 'bar':
        return _buildBarChart();
      case 'line':
        return _buildLineChart();
      case 'donut':
      case 'pie':
        return _buildDonutChart(chartType.toLowerCase());
      default:
        return Center(child: Text('Unsupported chart type: $chartType'));
    }
  }

  Widget _buildBarChart() {
    final String? firstKey =
        chartData.keys.isNotEmpty ? chartData.keys.first : null;
    final List<String> projects =
        chartData.values.first.map((d) => d.xAxis).toList();
    final List<String> categories = chartData.keys.toList();

    // Extract all unique group names
    final List<String> groups =
        chartData.values.first.map((d) => d.xAxis).toList();

    // Calculate total height for each group and find the maximum
    double maxValue = groups
        .map<double>((groupName) {
          // Sum all values across categories for this group
          double totalHeight = chartData.entries.fold<double>(0, (sum, entry) {
            final dataPoint = entry.value.firstWhere(
              (data) => data.xAxis == groupName,
              orElse: () => AxisData('', 0),
            );
            return sum + dataPoint.yAxis.toDouble();
          });
          return totalHeight;
        })
        .reduce(max);

    double interval = getProperYAxisInterval(maxValue).toDouble();
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups:
              projects
                  .asMap()
                  .map((index, projectName) {
                    double cumulativeHeight = 0;

                    final rods =
                        categories.map((category) {
                          final List<AxisData> dataList = chartData[category]!;
                          final dataPoint = dataList.firstWhere(
                            (data) => data.xAxis == projectName,
                            orElse: () => AxisData('', 0),
                          );

                          final double fromY = cumulativeHeight;
                          final double toY =
                              cumulativeHeight + dataPoint.yAxis.toDouble();

                          cumulativeHeight = toY;

                          final int colorIndex = categories.indexOf(category);

                          return BarChartRodData(
                            fromY: fromY,
                            toY: toY,
                            width: 20, // Adjust bar width
                            color: _getSegmentColor(colorIndex),
                            borderRadius: BorderRadius.zero,
                          );
                        }).toList();

                    return MapEntry(
                      index,
                      BarChartGroupData(
                        groupVertically: true,
                        x: index,
                        barRods: rods,
                        showingTooltipIndicators: [], // Optional: Show tooltips
                      ),
                    );
                  })
                  .values
                  .toList(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  String label = chartData[firstKey]![index].xAxis;

                  if (index >= 0 && index < chartData[firstKey]!.length) {
                    return Transform.rotate(
                      angle: -pi / 4,
                      child: Tooltip(
                        message: label,
                        preferBelow: false,
                        child: Text(
                          label.length > 7
                              ? '${label.substring(0, 7)}...'
                              : label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  // Skip drawing the last tick if it exceeds maxY or isn't aligned with interval
                  if (value % interval != 0) {
                    return const SizedBox(); // Hide widget
                  }

                  return Text(
                    formatLargeNumber(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          maxY: maxValue + interval,
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    num maxValue = chartData.values
        .map((list) => list.map((d) => d.yAxis).reduce(max))
        .reduce(max);
    if (maxValue <= 0) {
      maxValue = 5;
    }

    double interval = getProperYAxisInterval(maxValue).toDouble();
    return LineChart(
      LineChartData(
        maxY: maxValue + interval,
        lineBarsData:
            chartData.entries.mapIndexed((index, entry) {
              List<AxisData> dataList = entry.value;

              return LineChartBarData(
                spots:
                    dataList.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.yAxis.toDouble());
                    }).toList(),
                isCurved: true,
                color: _getSegmentColor(index), // now index is valid
                barWidth: 4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
                isStepLineChart: true,
              );
            }).toList(),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 70,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Only show label if the tick is a whole number
                if (value % 1 == 0) {
                  int index = value.toInt();
                  // if (index >= 0 &&
                  //     index < chartData[chartData.keys.first]!.length) {
                  String label = chartData[chartData.keys.first]![index].xAxis;
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Transform.rotate(
                      angle: -pi / 4,
                      child: Tooltip(
                        message: label,
                        preferBelow: false,
                        child: Text(
                          label.length > 7
                              ? '${label.substring(0, 7)}...'
                              : label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  );
                  // }
                }
                return const SizedBox(); // Hide non-integer ticks
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 60,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % interval != 0) {
                  return const SizedBox(); // Hide widget
                }
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildDonutChart(String chartType) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius:
            chartType == 'pie'
                ? 0
                : 40, // Radius for the inner space (donut hole)
        sections: _buildDonutSections(),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutSections() {
    return chartData[firstKey]!.asMap().entries.map((e) {
      int index = e.key;
      AxisData data = e.value;

      final double sectionValue = data.yAxis.toDouble();

      return PieChartSectionData(
        color: _getSegmentColor(index),
        value: sectionValue,
        showTitle: false,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getSegmentColor(int index) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
      Colors.lime,
      Colors.amber,
      Colors.cyan,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.blueGrey,
      Colors.greenAccent,
      Colors.yellow,
      Colors.grey,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
      Colors.orangeAccent,

      // Add 20 more colors below
      Colors.blue.shade900,
      Colors.green.shade900,
      Colors.orange.shade900,
      Colors.purple.shade900,
      Colors.red.shade900,
      Colors.teal.shade900,
      Colors.indigo.shade900,
      Colors.brown.shade900,
      Colors.pink.shade900,
      Colors.lime.shade900,
      Colors.amber.shade900,
      Colors.cyan.shade900,
      Colors.lightBlue.shade900,
      Colors.lightGreen.shade900,
      Colors.deepOrange.shade900,
      Colors.deepPurple.shade900,
      Colors.blueGrey.shade900,
      Colors.greenAccent.shade700,
      Colors.yellow.shade900,
      Colors.grey.shade900,
    ];

    return colors[index % colors.length];
  }

  Widget LegendBoxWidget(String chartType) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chartType == "Line")
            ...getLineChartLagend()
          else if (chartType == "Pie" || chartType == "Donut")
            ...getPieChartLagend()
          else if (chartType == "Bar")
            ...getBarChartLagend()
          else
            Text("Unsupported chart type"),
        ],
      ),
    );
  }

  List<Widget> getLineChartLagend() {
    return chartData.entries.map<Widget>((entry) {
      final String lineKey = entry.key;

      // Get color by index
      final Color color = _getSegmentColor(
        chartData.keys.toList().indexOf(lineKey),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            lineKey, // Line name
            style: const TextStyle(fontSize: 10),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> getPieChartLagend() {
    return chartData[firstKey]!.map<Widget>((data) {
      final Color color = _getSegmentColor(chartData[firstKey]!.indexOf(data));
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(data.xAxis, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 6),
          Text(data.yAxis.toString(), style: const TextStyle(fontSize: 10)),
        ],
      );
    }).toList();
  }

  List<Widget> getBarChartLagend() {
    return chartData.entries.map<Widget>((entry) {
      final String lineKey = entry.key;
      final List<AxisData> dataList = entry.value;

      // Get max value for this line
      final double maxValue =
          dataList.map((d) => d.yAxis).reduce(max).toDouble();

      // Get color by index
      final Color color = _getSegmentColor(
        chartData.keys.toList().indexOf(lineKey),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            lineKey, // Line name
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 6),
          Text(
            maxValue.toStringAsFixed(0), // Max value
            style: const TextStyle(fontSize: 10),
          ),
        ],
      );
    }).toList();
  }
}

class AxisData {
  final String xAxis;
  final num yAxis;

  AxisData(this.xAxis, this.yAxis);
}

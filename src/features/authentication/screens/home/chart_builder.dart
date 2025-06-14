import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../../../utils/helper.dart';
import '../../controllers/home_controller.dart';

class ChartBuilderScreen extends StatelessWidget {
  ChartBuilderScreen({
    super.key,
    required this.chartData,
    required this.chartType,
    required this.chartTitle,
  });
  final HomeController homeController = Get.put(HomeController());

  final List<AxisData> chartData;
  final String chartType;
  final String chartTitle;

  @override
  Widget build(BuildContext context) {
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
            height: 500,
            width: double.infinity,
            child:
                chartData.isEmpty
                    ? const Center(
                      child: Text(
                        'No Data Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : Stack(
                      children: [
                        // Chart goes here
                        buildChart(chartType),

                        if (chartData.isNotEmpty &&
                            ['Donut', 'Pie'].contains(chartType))
                          LagendBoxWidget(),
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
    return BarChart(
      BarChartData(
        barGroups:
            chartData
                .asMap()
                .map((i, data) {
                  final double rawValue = data.yAxis.toDouble();

                  return MapEntry(
                    i,
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rawValue,
                          color: tPrimaryColor,
                          width: 22,
                          rodStackItems: [],
                        ),
                      ],
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
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return Text(
                    chartData[index].xAxis,
                    style: TextStyle(fontSize: 12),
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
              interval:
                  getProperYAxisInterval(
                    chartData,
                  ).toDouble(), // Control spacing
              getTitlesWidget: (value, meta) {

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
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots:
                chartData.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.yAxis.toDouble());
                }).toList(),
            isCurved: true,
            color: tPrimaryColor,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
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
                  if (index >= 0 && index < chartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        chartData[index].xAxis,
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }
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
                return Text('${value.toInt()}');
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
    return chartData.asMap().entries.map((e) {
      int index = e.key;
      AxisData data = e.value;

      final double sectionValue = data.yAxis.toDouble();

      return PieChartSectionData(
        color: _getSegmentColor(index),
        value: sectionValue,
        showTitle: false,
        radius: 80,
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
    ];
    return colors[index % colors.length];
  }

  Widget LagendBoxWidget() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
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
          children:
              chartData.map<Widget>((data) {
                final Color color = _getSegmentColor(chartData.indexOf(data));
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(data.xAxis, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      data.yAxis.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

class AxisData {
  final String xAxis;
  final num yAxis;

  AxisData(this.xAxis, this.yAxis);
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
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
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        : chartType == 'Bar'
                        ? _buildBarChart()
                        : _buildLineChart(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups:
            chartData
                .asMap()
                .map(
                  (i, data) => MapEntry(
                    i,
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data.yAxis.toDouble(),
                          color: tPrimaryColor,
                          width: 22,
                          rodStackItems: [],
                        ),
                      ],
                    ),
                  ),
                )
                .values
                .toList(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 120, // More space for rotated labels
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  String label = chartData[index].xAxis;
                  return _buildBottomLabel(label);
                }
                return Container(); // Fallback
              },
            ),
          ),
          // leftTitles: AxisTitles(
          //   sideTitles: SideTitles(
          //     showTitles: true,
          //     getTitlesWidget: (value, meta) {
          //       return Text('${value.toInt()}');
          //     },
          //   ),
          // ),
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
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(chartData[value.toInt()].xAxis);
              },
            ),
            // axisNameWidget: Padding(
            //   padding: const EdgeInsets.only(top: 8.0),
            //   child: Text(
            //     'xAxis',
            //     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            //   ),
            // ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: RotatedBox(
                quarterTurns: -1,
                child: Text(
                  'yAxis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBottomLabel(String label) {
    bool isLongLabel = label.length > 10;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child:
          isLongLabel
              ? Transform.rotate(
                angle: -1.0, // ~57 degrees
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
    );
  }
}

class AxisData {
  final String xAxis;
  final int yAxis;

  AxisData(this.xAxis, this.yAxis);
}

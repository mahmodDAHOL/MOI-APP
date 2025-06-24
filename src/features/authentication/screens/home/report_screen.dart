import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/constants/colors.dart';

import '../../controllers/report_controller.dart';
import '../../models/dashboard_chart_model.dart';
import 'chart_builder.dart';
import 'dashboard_card.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key, required this.reportName});
  ReportController reportController = Get.put(ReportController());

  String reportName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sales Invoice")),
      body: buildTableSection(),
    );
  }

  Widget buildTableSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: reportController.getReportData(reportName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No Data Available.'));
        }
        Map<String, dynamic> items = snapshot.data!;
        List tableData = items['result'];
        int rowNum = tableData.length;
        List<String> columnsName =
            items['columns']
                .map<String>((col) => col['label'].toString())
                .toList();
        int colNum = columnsName.length;
        Map chartMap = items['chart'];
        List cardMap = items['report_summary'];
        Map<String, dynamic> chartData = chartMap['data'];
        Map<String, List<AxisData>> processedChartData = processChartData(
          chartData,
        );
        DashboardChart chartMeta = DashboardChart.fromJson({
          'color': chartMap['color'] ?? chartMap['colors'][0],
          'chart_type': chartMap['type'],
          'chart_name': "",
        });
        List<Widget> cardWidgetList =
            cardMap.map((cardData) {
              return DashboardCardWidget(cardData: cardData);
            }).toList();

        return ListView(
          shrinkWrap: true,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: cardWidgetList),
            ),
            ChartBuilderScreen(
              chartData: processedChartData,
              chartMeta: chartMeta,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("")),
                  ...List.generate(
                    colNum,
                    (index) => DataColumn(
                      label: Text(
                        columnsName[index],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: tPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: List.generate(
                  rowNum, // Number of rows
                  (rowIndex) => DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 5,
                          child: Checkbox(value: false, onChanged: (value) {}),
                        ),
                      ),
                      ...List.generate(colNum, (colIndex) {
                        final values = tableData[rowIndex].values.toList();
                        return DataCell(Text(values[colIndex].toString()));
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<AxisData>> processChartData(
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
}

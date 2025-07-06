import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/constants/colors.dart';

import '../../../../common_widgets/form/multi_select_widget.dart';
import '../../../../common_widgets/keep_alive_wrapper.dart';
import '../../../../utils/helper.dart';
import '../../controllers/report_controller.dart';
import '../../models/dashboard_chart_model.dart';
import '../form_screen/form_screen.dart';
import 'chart_builder.dart';
import 'dashboard_card.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key, required this.reportName}) {
    reportController.loadData(reportName);
  }
  ReportController reportController = Get.put(ReportController());

  String reportName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(reportName)),
      body: ListView(
        children: [
          FutureBuilder<Widget?>(
            future: reportController.getFiltersList(reportName).then((
              filtersList,
            ) {
              if (filtersList != null && filtersList.isNotEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filtersList.length + 1,
                  itemBuilder: (context, fieldIndex) {
                    if (fieldIndex < filtersList.length) {
                      Map<String, dynamic> field = filtersList[fieldIndex];
                      return _buildFieldWidget(field, context);
                    } else {
                      return SizedBox(height: 16); // Optional extra spacing
                    }
                  },
                );
              } else {
                return SizedBox.shrink(); // Empty widget
              }
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text("Error loading filters");
              }

              return snapshot.data ?? SizedBox.shrink();
            },
          ),

          Obx(() {
            if (reportController.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            final filtersJson = jsonEncode(
              reportController.filters,
            ); // triggers Obx on any change
            final filters = jsonDecode(
              filtersJson,
            ); // optional: cast back to Map<String, dynamic>
            return buildTableSection(filters);
          }),
        ],
      ),
    );
  }

  Widget buildTableSection(Map filters) {
    return KeepAliveWrapper(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: reportController.getReportData(reportName, filters),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No Data Available.'));
          }
          Map<String, dynamic> items = snapshot.data!;
          if (!items.containsKey('result')) {
            return SizedBox(
              height: 250,
              width: double.infinity,
              child: Card(
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
              ),
            );
          }

          List tableData = items['result'];
          int rowNum = tableData.length;
          List<String> columnsName =
              items['columns']
                  .map<String>((col) => col['label'].toString())
                  .toList();
          int colNum = columnsName.length;
          var chartMap = items['chart'];
          List? cardMap = items['report_summary'];

          Map<String, dynamic> chartData = {};
          Map<String, List<AxisData>> processedChartData = {};
          DashboardChart chartMeta = DashboardChart.fromJson({});
          if (chartMap is Map && chartMap.containsKey('data')) {
            chartData = chartMap['data'];
            processedChartData = processChartData(chartData);
            chartMeta = DashboardChart.fromJson({
              'color':
                  chartMap['color'] ??
                  chartMap['colors']?[0] ??
                  tPrimaryColor.toString(),
              'chart_type': chartMap['type'],
              'chart_name': "",
            });
          } else if (chartMap is List && chartMap.isNotEmpty) {
            chartData = chartMap[0]['data'];
            processedChartData = processChartData(chartData);
            chartMeta = DashboardChart.fromJson({
              'color':
                  chartMap[0]['color'] ??
                  chartMap[0]['colors']?[0] ??
                  tPrimaryColor.toString(),
              'chart_type': chartMap[0]['type'],
              'chart_name': "",
            });
          }

          List<Widget> cardWidgetList =
              cardMap != null
                  ? cardMap.map((cardData) {
                    return DashboardCardWidget(cardData: cardData);
                  }).toList()
                  : [];

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
              if (tableData.isNotEmpty)
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
                              child: Checkbox(
                                value: false,
                                onChanged: (value) {},
                              ),
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
      ),
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

  Widget _buildFieldWidget(Map<String, dynamic> field, BuildContext context) {
    String type = field['fieldtype'];
    switch (type) {
      case "Text":
      case "Data":
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(labelText: field['label']),
            controller: TextEditingController(
              text:
                  field['default']?.toString() ??
                  reportController.filters[field['fieldname']]?.toString() ??
                  "",
            ),
            onChanged: (value) {
              reportController.filters[field['fieldname']] = value.toString();
            },
          ),
        );

      case "Select":
        return Obx(() {
          return ListTile(
            title: Text(field['label'] ?? field['fieldname']),
            subtitle: Text(
              reportController.filters[field['fieldname']]?.toString() ??
                  field['default'] ??
                  "Select Option",
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(children: getSelectOptions(field));
                },
              );
            },
          );
        });
      case "MultiSelectList":
        return MultiSelectField(field: field);

      case "Link":
        return Obx(() {
          return ListTile(
            title: Text(field['label'] ?? field['fieldname']),
            subtitle: Text(
              reportController.filters[field['fieldname']]?.toString() ??
                  field['default'] ??
                  "Select Option",
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        title: Text(
                          "Select an option",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {},
                      ),
                      ...field['options']!.map((option) {
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            reportController.filters[field['fieldname']] =
                                option.toString();
                            Get.back();
                          },
                        );
                      }),
                      ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.add, size: 20),
                            Expanded(
                              child: Text(
                                "Create a new ${field['label']}",
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Get.to(
                            () => DynamicForm(
                              doctype: field['label']!,
                              fullForm: false,
                              forEditing: false,
                            ),
                            preventDuplicates: false,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        });

      case "Date":
        return Obx(() {
          final selectedDate =
              reportController.filters[field['fieldname']] != null
                  ? DateTime.tryParse(
                    reportController.filters[field['fieldname']]!,
                  )
                  : null;

          return ListTile(
            title: Text(field['label'] ?? field['fieldname']),
            subtitle: Text(
              selectedDate != null
                  ? "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}"
                  : field['default'] ?? "Select Date",
            ),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final initialDate = selectedDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                reportController.filters[field['fieldname']] =
                    picked.toString();
              }
            },
          );
        });

      case "Check":
        return Obx(() {
          final bool isChecked =
              toBool(reportController.filters[field['fieldname']].toString()) ==
                  true ||
              (toBool(field['default'].toString()) == true &&
                  reportController.filters[field['fieldname']] == null);

          return ListTile(
            title: Text(field['label'] ?? field['fieldname']),
            trailing: Checkbox(
              value: isChecked,
              onChanged: (value) {
                reportController.filters[field['fieldname']] = toIntBool(value);
              },
            ),
          );
        });

      default:
        return SizedBox(height: 1);
      // return Text(
      //   "${field['fieldname']} ${type} ",
      //   style: TextStyle(color: Colors.red),
      // );
    }
  }

  List<Widget> getSelectOptions(field) {
    var options = field['options'] ?? [];
    if (options is String && options.contains('\n')) {
      options = options.split('\n');
    }
    return options.map<Widget>((option) {
      if (option is Map<String, dynamic> || option is Map) {
        final value = option['value'];
        if (value != null) {
          option = value;
        }
      }
      return ListTile(
        title: Text(option),
        onTap: () {
          reportController.filters[field['fieldname']] = option.toString();
          Get.back();
        },
      );
    }).toList();
  }

  // Future<Widget?> getFilterFields() async {
  //   List<Map<String, dynamic>>? filtersList = await reportController
  //       .getFiltersList(reportName);
  //   if (filtersList != null) {
  //     return ListView.builder(
  //       shrinkWrap: true,
  //       physics: NeverScrollableScrollPhysics(),
  //       itemCount: filtersList.length + 1,
  //       itemBuilder: (context, fieldIndex) {
  //         if (fieldIndex < filtersList.length) {
  //           Map<String, dynamic> field = filtersList[fieldIndex];
  //           return _buildFieldWidget(field, reportController, context);
  //         }
  //       },
  //     );
  //   } else {
  //     return null;
  //   }
  // }
}

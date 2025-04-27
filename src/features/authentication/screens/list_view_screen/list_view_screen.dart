import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/list_view_controller.dart';

class ListViewScreen extends StatelessWidget {
  ListViewScreen({super.key});
  final ListViewController listViewController = Get.put(ListViewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("List View")),
      body: SingleChildScrollView(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: listViewController.getReportView(), // Call the future
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No data available."));
            } else {
              List<Map<String, dynamic>> reportData = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  // Dynamically generate columns based on keys
                  columns:
                      reportData.isNotEmpty
                          ? reportData.first.keys.map((key) {
                            return DataColumn(
                              label: Expanded(
                                child: Text(
                                  key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: 15),
                                ),
                              ),
                            );
                          }).toList()
                          : [],
                  // Dynamically generate rows based on reportData
                  rows:
                      reportData.map((item) {
                        return DataRow(
                          cells:
                              item.entries.map((entry) {
                                return DataCell(
                                  Text(
                                    entry.value?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                        );
                      }).toList(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

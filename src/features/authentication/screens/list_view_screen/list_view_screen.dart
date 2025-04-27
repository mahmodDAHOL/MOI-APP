import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/list_view_controller.dart';

class ListViewScreen extends StatelessWidget {
  ListViewScreen({super.key, required this.doctype});

  final ListViewController listViewController = Get.put(ListViewController());
  final String doctype;

  // Controller for the filter TextField
  final TextEditingController filterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("List View")),
      body: Column(
        children: [
          // Add a filter TextField at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: filterController,
              decoration: InputDecoration(
                labelText: "Filter",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    // Clear the filter text
                    filterController.clear();
                  },
                ),
              ),
              onChanged: (value) {
                // Update the filter value in the controller
                listViewController.filter.value = value;
              },
            ),
          ),

          // Main content: SingleChildScrollView with FutureBuilder
          Expanded(
            child: Obx(() {
              return SingleChildScrollView(
                child: FutureBuilder<List<Map<String, dynamic>>?>(
                  future: listViewController.getReportView(
                    doctype,
                    listViewController.filter.value,
                  ),
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
              );
            }),
          ),
        ],
      ),
    );
  }
}

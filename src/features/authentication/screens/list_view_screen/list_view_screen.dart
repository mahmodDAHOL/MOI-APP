import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/helper.dart';
import '../../controllers/form_controller.dart';
import '../../controllers/list_view_controller.dart';
import '../form_screen/form_screen.dart';

class ListViewScreen extends StatelessWidget {
  ListViewScreen({super.key, required this.doctype});

  final ListViewController listViewController = Get.put(ListViewController());
  final FormController formController = Get.find();
  final String doctype;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween, // Ensures the Row doesn't take full width
          children: [
            Container(
              width: 200,
              child: Text(
                doctype,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () {
                formController.reset();
                Get.off(
                  () => DynamicForm(
                    doctype: doctype,
                    fullForm: false,
                    forEditing: false,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20), // Optional
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.add, size: 37),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        int filtersNum = listViewController.filters.length;
        return Column(
          children: [
            // Add a filter TextField at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed:
                      () => listViewController.addFilter(context, doctype),
                ),
                if (filtersNum > 0)
                  ElevatedButton(
                    onPressed: () => listViewController.showFilters(context),
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                      child: Text("Filters ($filtersNum)"),
                    ),
                  ),
                if (filtersNum > 0)
                  ElevatedButton(
                    onPressed: listViewController.clearFilters,
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                      child: Text("Clear Filters"),
                    ),
                  ),
              ],
            ),

            Divider(),

            // Main content: SingleChildScrollView with FutureBuilder
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: FutureBuilder<List<Map<String, dynamic>>?>(
                  future: listViewController.getReportView(doctype, context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No data available."));
                    } else {
                      List<Map<String, dynamic>> reportData = snapshot.data!;
                      return Column(
                        children: [
                          Obx(() => _buildActionBar(context, reportData)),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: getTable(context, reportData),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                borderWidth: 0.5,
                borderColor: Colors.blue,
                selectedBorderColor: Colors.green,
                selectedColor: Colors.white,
                fillColor: Colors.green,
                color: Colors.black,
                isSelected: List<bool>.from(listViewController.isSelected),
                onPressed: (int index) {
                  for (
                    int i = 0;
                    i < listViewController.isSelected.length;
                    i++
                  ) {
                    listViewController.isSelected[i] =
                        (i ==
                            index); // Set true for the selected index, false for others
                  }
                },
                children:
                    listViewController.elmCountoptions.map((String option) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          option,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    List<Map<String, dynamic>> reportData,
  ) {
    if (!listViewController.hasSelection) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[300],
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              if (listViewController.selectedRowIndices.length > 1) {
                showAutoDismissDialog(context, "Select only one item");
              } else {
                formController.reset();
                final selectedItem =
                    reportData[listViewController.selectedRowIndices.first];
                bool success = await listViewController.getItemInfo(
                  doctype,
                  selectedItem['name'],
                );
                if (success) {
                  Get.to(
                    () => DynamicForm(
                      doctype: doctype,
                      fullForm: false,
                      forEditing: true,
                    ),
                  );
                } else {
                  showAutoDismissDialog(context, "You can't edit this record");
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              listViewController.deleteSelected(context, reportData, doctype);
              listViewController.refreshed.value =
                  !listViewController.refreshed.value;
            },
          ),
        ],
      ),
    );
  }

  Widget getTable(context, reportData) {
    return Obx(
      () => DataTable(
        columns: [
          ...reportData.first.keys.map((key) {
            return DataColumn(
              label: Expanded(
                child: Text(
                  key,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 15),
                ),
              ),
            );
          }).toList(),
        ],
        rows:
            reportData
                .asMap()
                .map<int, DataRow>((int index, Map<String, dynamic> item) {
                  return MapEntry<int, DataRow>(
                    index,
                    DataRow(
                      selected: listViewController.selectedRowIndices.contains(
                        index,
                      ),
                      onSelectChanged: (bool? selected) {
                        listViewController.toggleSelection(index);
                      },
                      cells:
                          item.entries.map<DataCell>((entry) {
                            return DataCell(
                              Text(
                                entry.value?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                    ),
                  );
                })
                .values
                .toList(),
      ),
    );
  }
}

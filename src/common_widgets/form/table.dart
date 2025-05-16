import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/controllers/form_controller.dart';
import '../../features/authentication/models/form_field_model.dart';
import '../../utils/helper.dart';

class TableWithAddButton extends StatelessWidget {
  TableWithAddButton({
    super.key,
    required this.doctype,
    required this.tableFields,
    required this.field,
  });
  final FormController controller = Get.find();

  final String doctype;
  final List<FormFieldData> tableFields;
  final FormFieldData field;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      print(field.fieldName);
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(doctype, style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                defaultColumnWidth: const FixedColumnWidth(150.0),

                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Gray background for header row
                    ),
                    children:
                        tableFields.map((field) {
                          return TableCell(
                            child: Center(
                              child: Text(
                                field.fieldName.replaceAll('_', " "),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  ...getTableRows(controller.tableRowValues[field.fieldName]),
                ],
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () {
                  var tableData = field.tableDoctypeData!.toMap();
                  for (var tableField in tableFields) {
                    tableData.addAll({tableField.fieldName: ""});
                  }
                  controller.tablesData[field.fieldName].add(tableData);
                  controller.tablesData.refresh();
                  controller.tableRowValues[field.fieldName].add(
                    getElementsAfterKey(tableData, 'idx'),
                  );
                  controller.tableRowValues.refresh();
                },
                child: const Text('Add Row'),
              ),
            ),
          ],
        ),
      );
    });
  }

  TableRow GetTableRow(List<dynamic> row, int rowIndex) {
    return TableRow(
      children:
          row
              .asMap()
              .map((colIndex, value) {
                return MapEntry(
                  colIndex,
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: TextField(
                        onChanged: (text) {
                          String fieldName = field.fieldName;

                          // Get the full row (a map, e.g., { "name": "John", "role": "Dev" })
                          var row =
                              controller.tableRowValues[fieldName]![rowIndex];

                          // Convert row to mutable map if it's immutable
                          var mutableRow = Map<String, dynamic>.from(row);

                          // Get all keys in order to find the correct column
                          var keys = row.keys.toList(); // ["name", "role"]
                          var keyToUpdate = keys[colIndex]; // e.g., "name"

                          // Update value
                          mutableRow[keyToUpdate] = text;

                          // Replace the old row with updated one
                          controller.tableRowValues[fieldName]![rowIndex] =
                              mutableRow;

                          // Notify UI
                          controller.tableRowValues.refresh();

                          // controller.tablesData[fieldName].add(controller.tableRowValues);
                        },
                        textAlign: TextAlign.center,
                        controller: TextEditingController(text: value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                );
              })
              .values
              .toList(),
    );
  }

  List<TableRow> getTableRows(List<dynamic> tableFields) {
    List<TableRow> TableRows =
        tableFields.asMap().entries.map((entry) {
          int rowIndex = entry.key;
          Map<String, dynamic> row = entry.value;
          return GetTableRow(row.values.toList(), rowIndex);
        }).toList();
    return TableRows;
  }
}

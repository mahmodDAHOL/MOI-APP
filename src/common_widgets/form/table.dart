import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/controllers/form_controller.dart';
import '../../features/authentication/models/form_field_model.dart';

class TableWithAddButton extends StatelessWidget {
  TableWithAddButton({
    super.key,
    required this.doctype,
    required this.tableFields,
    required this.field,
  });
  final FormController controller = Get.put(FormController());

  final String doctype;
  final List<FormFieldData> tableFields;
  final FormFieldData field;

  @override
  Widget build(BuildContext context) {
    // return Obx(() {
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
                                field.label ?? field.fieldName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  
                  // ...controller.tablesData[field.fieldName]?.asMap.entries.map(
                  //   (entry) {
                  //     int rowIndex = entry.key;
                  //     Map<String, String> row = entry.value;
                  //     return GetTableRow(row, rowIndex);
                  //   },
                  // ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(

                onPressed: () {
                  var tableData = field.tableDoctypeData!.toMap();
                  for (var field in tableFields) {
                    tableData.addAll({field.fieldName: ""});
                  }
                  controller.tablesData[field.fieldName] = tableData;
                  controller.tablesData.refresh();
                },
                child: const Text('Add Row'),
              ),
            ),
          ],
        ),
      );
    // });
  }

  TableRow GetTableRow(Map<String, String> row, int rowIndex) {
    return TableRow(
      children:
          (row as List<String>)
              .asMap()
              .map((colIndex, value) {
                return MapEntry(
                  colIndex,
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: TextField(
                        onChanged: (text) {
                          // controller.tableRows[field
                          //         .tableIndex][rowIndex][colIndex] =
                          //     text;
                          // controller.tableRows.refresh();
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
}

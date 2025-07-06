import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/controllers/form_controller.dart';
import '../../features/authentication/models/field_type_model.dart';
import '../../features/authentication/models/form_field_model.dart';
import '../../features/authentication/screens/form_screen/form_screen.dart';
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
                  getTableHeader(context, tableFields),

                  ...getTableRows(field.fieldName, context),
                ],
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () {
                  controller.tableRowValues[field.fieldName].add(
                    getInitialRow(tableFields),
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

  TableRow GetTableRow(
    String tableFieldName,
    Map<dynamic, dynamic> row, // Make sure row is typed
    int rowIndex,
    BuildContext context,
  ) {
    // Get list of ordered field names from field.data
    List<dynamic> tableFields =
        field.data.map((tablefield) {
          if (tablefield.type == FieldType.link &&
              tablefield.data['options'].runtimeType == String) {
            return tablefield.copyWith(options: tablefield.data['options']);
          }
          return tablefield;
        }).toList();

    // Extract ordered field names
    List<String> orderedFieldNames =
        tableFields
            .map<String?>((f) => f.fieldName)
            .where((name) => name != null)
            .cast<String>()
            .toList();

    // Build table cells in correct order
    List<TableCell> cells =
        orderedFieldNames
            .map((fieldName) {
              // Get value safely
              var value = row[fieldName];

              // Get corresponding field definition
              var fieldDef = tableFields.firstWhere(
                (f) => f.fieldName == fieldName,
                orElse:
                    () =>
                        NullTableField(), // define NullField() as fallback if needed
              );

              Widget? tableCell = _buildFieldWidget(
                tableFieldName,
                fieldDef,
                rowIndex,
                orderedFieldNames.indexOf(fieldName),
                field.tableDoctypeData?.toJson(),
                value,
                controller,
                context,
              );
              // Return widget for the cell
              return tableCell != null ? TableCell(child: tableCell) : null;
            })
            .whereType<TableCell>()
            .toList();

    // Return TableRow with ordered cells
    return TableRow(children: cells);
  }

  List<TableRow> getTableRows(String tableFieldName, BuildContext context) {
    List<dynamic> tableFields = controller.tableRowValues[tableFieldName] ?? [];
    List<TableRow> tableRows =
        tableFields.asMap().entries.map((entry) {
          int rowIndex = entry.key;
          Map<dynamic, dynamic> row = entry.value;
          return GetTableRow(tableFieldName, row, rowIndex, context);
        }).toList();
    return tableRows;
  }

  TableRow getTableHeader(BuildContext context, List tableFields) {
    List<TableCell> tableFieldsName =
        tableFields
            .where((field) => field.type != FieldType.unknown)
            .map<TableCell>((field) {
              return TableCell(
                child: Center(
                  child: Text(
                    field.data['label'] ?? "",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.black),
                  ),
                ),
              );
            })
            .toList();
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey[300], // Gray background for header row
      ),
      children: tableFieldsName,
    );
  }

  Widget? _buildFieldWidget(
    String tableFieldName,
    FormFieldData field,
    rowIndex,
    colIndex,
    tableData,
    value,
    FormController controller,
    BuildContext context,
  ) {
    switch (field.type) {
      case FieldType.text:
        return TextField(
          onChanged: (text) {
            Map<String, dynamic> mutableRow = editTableRow(
              tableFieldName,
              controller.tableRowValues,
              rowIndex,
              colIndex,
              text,
            );
            tableData.addAll(mutableRow);

            controller.tablesData[tableFieldName]!.add(tableData);

            controller.tableRowValues.refresh();
            controller.tablesData.refresh();
          },

          textAlign: TextAlign.center,
          controller: TextEditingController(text: value.toString()),
          decoration: const InputDecoration(border: InputBorder.none),
        );
      case FieldType.select:
        return Obx(() {
          return ListTile(
            title: Text(field.data['label'] ?? field.data['fieldName']),
            subtitle: Text(getLinkValue(tableFieldName, rowIndex, colIndex)),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(
                    children:
                        (field.data['options'] ?? []).map<Widget>((option) {
                          return ListTile(
                            title: Text(option),
                            onTap: () {
                              Map<String, dynamic> mutableRow = editTableRow(
                                tableFieldName,
                                controller.tableRowValues,
                                rowIndex,
                                colIndex,
                                option,
                              );
                              tableData.addAll(mutableRow);

                              controller.tablesData[tableFieldName]!.add(
                                tableData,
                              );

                              controller.tableRowValues.refresh();
                              controller.tablesData.refresh();
                              Get.back();
                            },
                          );
                        }).toList(),
                  );
                },
              );
            },
          );
        });
      case FieldType.check:
        return Obx(() {
          String? checkboxValue =
              getCheckBoxValue(tableFieldName, rowIndex, colIndex).toString();
          final bool isChecked = toBool(checkboxValue) == true;

          return ListTile(
            trailing: Checkbox(
              value: isChecked,
              onChanged: (value) {
                Map<String, dynamic> mutableRow = editTableRow(
                  tableFieldName,
                  controller.tableRowValues,
                  rowIndex,
                  colIndex,
                  value.toString(),
                );
                tableData.addAll(mutableRow);

                controller.tablesData[tableFieldName]!.add(tableData);

                controller.tableRowValues.refresh();
                controller.tablesData.refresh();
              },
            ),
          );
        });

      case FieldType.link:
        return Obx(() {
          return ListTile(
            title: Text(field.data['label'] ?? field.data['fieldName']),
            subtitle: Text(getLinkValue(tableFieldName, rowIndex, colIndex)),

            trailing: Icon(Icons.arrow_drop_down),
            onTap: () async {
              List options = await field.data['options']!;
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

                      ...options.map((option) {
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            Map<String, dynamic> mutableRow = editTableRow(
                              tableFieldName,
                              controller.tableRowValues,
                              rowIndex,
                              colIndex,
                              option.toString(),
                            );
                            tableData.addAll(mutableRow);

                            controller.tablesData[tableFieldName]!.add(
                              tableData,
                            );

                            controller.tableRowValues.refresh();
                            controller.tablesData.refresh();

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
                                "Create a new ${field.data['label']}",
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Get.to(
                            () => DynamicForm(
                              doctype: field.label!,
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
      case FieldType.date:
        return ListTile(
          title: Text(field.data['label'] ?? field.data['fieldName']),
          subtitle: Text(getLinkValue(tableFieldName, rowIndex, colIndex)),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              Map<String, dynamic> mutableRow = editTableRow(
                tableFieldName,
                controller.tableRowValues,
                rowIndex,
                colIndex,
                picked.toString(),
              );
              tableData.addAll(mutableRow);

              controller.tablesData[tableFieldName]!.add(tableData);

              controller.tableRowValues.refresh();
              controller.tablesData.refresh();
            }
          },
        );
      case FieldType.datetime:
        return ListTile(
          title: Text(field.data['label'] ?? field.data['fieldName']),
          subtitle: Text(getLinkValue(tableFieldName, rowIndex, colIndex)),
          trailing: Icon(Icons.access_time),
          onTap: () async {
            final datePicked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );

            if (datePicked == null) return;

            final timePicked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (timePicked == null) return;

            // Combine date and time
            final selectedDateTime = DateTime(
              datePicked.year,
              datePicked.month,
              datePicked.day,
              timePicked.hour,
              timePicked.minute,
            );

            // Save as ISO string or format it as needed
            String datetimeString = selectedDateTime.toIso8601String();

            Map<String, dynamic> mutableRow = editTableRow(
              tableFieldName,
              controller.tableRowValues,
              rowIndex,
              colIndex,
              datetimeString,
            );

            tableData.addAll(mutableRow);

            controller.tablesData[tableFieldName]!.add(tableData);

            controller.tableRowValues.refresh();
            controller.tablesData.refresh();
          },
        );
      default:
        return null;
      // return Text(field.fieldName, style: TextStyle(color: Colors.red));
    }
  }

  String getLinkValue(String tableFieldName, int rowIndex, int colIndex) {
    var tableData = controller.tableRowValues[tableFieldName];
    var rowData =
        tableData is List && rowIndex >= 0 && rowIndex < tableData.length
            ? tableData[rowIndex]
            : null;
    rowData = rowData.values.toList();
    var cellValue =
        rowData is List && colIndex >= 0 && colIndex < rowData.length
            ? rowData[colIndex]
            : null;

    String displayText = cellValue?.toString() ?? "Select Option";
    return displayText;
  }

  String? getCheckBoxValue(String tableFieldName, int rowIndex, int colIndex) {
    var tableData = controller.tableRowValues[tableFieldName];
    var rowData =
        tableData is List && rowIndex >= 0 && rowIndex < tableData.length
            ? tableData[rowIndex]
            : null;
    rowData = rowData.values.toList();
    var cellValue =
        rowData is List && colIndex >= 0 && colIndex < rowData.length
            ? rowData[colIndex]
            : null;

    return cellValue.toString();
  }

  void changeValue(
    String tableFieldName,
    int rowIndex,
    int colIndex,
    String value,
  ) {
    var tableData = controller.tablesData[tableFieldName];
    if (tableData is List && rowIndex >= 0 && rowIndex < tableData.length) {
      var rowData = tableData[rowIndex];
      if (rowData is List && colIndex >= 0 && colIndex < rowData.length) {
        rowData[colIndex] = value;

        controller.tablesData.refresh();
      }
    }
  }
}

class NullTableField {
  final String fieldName = '';
  // Add other default properties needed by _buildFieldWidget
}

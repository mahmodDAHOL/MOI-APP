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
    Map<String, dynamic> row,
    int rowIndex,
    BuildContext context,
  ) {
    List<dynamic> rowValues = row.values.toList();
    var tableData = field.tableDoctypeData!.toJson();
    List tableFields =
        field.data.map((tablefield) {
          if (tablefield.type == FieldType.link) {
            if (tablefield.options.runtimeType == String) {
              tablefield = tablefield.copyWith(
                options: controller.searchLink(
                  tablefield.data['label'],
                  doctype,
                ),
              );
            }
          }
          return tablefield;
        }).toList();

    return TableRow(
      children:
          rowValues
              .asMap()
              .map((colIndex, value) {
                return MapEntry(
                  colIndex,
                  TableCell(
                    child: _buildFieldWidget(
                      tableFieldName,
                      tableFields[colIndex],
                      rowIndex,
                      colIndex,
                      tableData,
                      value,
                      controller,
                      context,
                    ),
                  ),
                );
              })
              .values
              .toList(),
    );
  }

  List<TableRow> getTableRows(String tableFieldName, BuildContext context) {
    List<dynamic> tableFields = controller.tableRowValues[tableFieldName];
    List<TableRow> TableRows =
        tableFields.asMap().entries.map((entry) {
          int rowIndex = entry.key;
          Map<String, dynamic> row = entry.value;
          return GetTableRow(tableFieldName, row, rowIndex, context);
        }).toList();
    return TableRows;
  }

  TableRow getTableHeader(BuildContext context, List tableFields) {
    List<TableCell> tableFieldsName =
        tableFields.map<TableCell>((field) {
          return TableCell(
            child: Center(
              child: Text(
                field.fieldName.replaceAll('_', " "),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }).toList();
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey[300], // Gray background for header row
      ),
      children: tableFieldsName,
    );
  }

  Widget _buildFieldWidget(
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
        return Padding(
          padding: const EdgeInsets.all(1),
          child: TextField(
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
            controller: TextEditingController(text: value),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        );
      case FieldType.select:
        return Obx(() {
          return ListTile(
            title: Text(field.data['label'] ?? field.data['fieldName']),
            subtitle: Text(
              controller.formValues[field.fieldName]?.toString() ??
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
      case FieldType.link:
        return Obx(() {
          return ListTile(
            title: Text(field.label ?? field.fieldName),
            subtitle: Text(
              controller.formValues[field.fieldName]?.toString() ??
                  "Select Option",
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () async {
              List<String> options = await field.options!;
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
                            controller.formValues[field.fieldName] =
                                option.toString();
                            Get.back();
                          },
                        );
                      }),

                      ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.add, size: 20),
                            Text("Create a new ${field.label}"),
                          ],
                        ),
                        onTap: () {
                          Get.to(
                            () => DynamicForm(
                              doctype: field.label!,
                              fullForm: false,
                              forEditing: false,
                            ),
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
      default:
        return Text(field.fieldName, style: TextStyle(color: Colors.red));
      // return SizedBox(height: 1,);
    }
  }

  List<Widget> getSelectOptions(field) {
    return (field.data['options'] ?? []).map<Widget>((option) {
      return ListTile(
        title: Text(option),
        onTap: () {
          controller.formValues[field.fieldName] = option.toString();
          Get.back();
        },
      );
    }).toList();
  }
}

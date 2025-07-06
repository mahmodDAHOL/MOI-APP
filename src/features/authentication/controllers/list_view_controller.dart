import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moi_app/src/features/authentication/controllers/form_controller.dart';

import '../../../utils/helper.dart';
import '../models/field_type_model.dart';
import '../models/form_field_model.dart';
import '../screens/list_view_screen/list_view_screen.dart';
import 'shared_preferences_controller.dart';

class ListViewController extends GetxController {
  final session = Get.find<Session>();
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final FormController formController = Get.put(FormController());

  final List<String> elmCountoptions = ['20', '100', '500', '2500'];
  RxList<dynamic> isSelected = [true, false, false, false].obs;

  var refreshed = false.obs;

  RxList<Filter> filters = RxList.of(<Filter>[]);
  final RxList<FilterField> fieldsList = RxList.of(<FilterField>[]);
  List<String> valuesList = [];
  final Rx<FilterField?> selectedField = Rx<FilterField?>(null);
  final Rx<FilterField?> selectedOperator = Rx<FilterField?>(null);
  final selectedValue = Rx<dynamic>("");
  final TextEditingController _valueController = TextEditingController();

  late StateSetter stateSetter;

  Map<String, String> operatorsMap = Map.from({
    "Equals": "=",
    "Not Equals": "!=",
    "Like": "like",
    "Not Like": "not like",
    "In": "in",
    "Not In": "not in",
    "Is": "is",
    "Greater Than": ">",
    "Less Than": "<",
    "Greater Than Or Equal To": ">=",
    "Less Than Or Equal To": "<=",
    "Between": "Between",
    "Timespan": "Timespan",
    "Descendants Of": "descendants of",
    "Not Descendants Of": "not descendants of",
    "Descendants Of (inclusive)": "descendants of (inclusive)",
    "Ancestors Of": "ancestors of",
    "Not Ancestors Of": "not ancestors of",
    "Fiscal Year": "fiscal year",
  });

  void showFilters(context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text("Filters"),
          content: SizedBox(
            height: 150,
            child: Obx(
              () => ListView.builder(
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          filter.field.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          filter.operator.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          filter.value.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          // Remove filter
                          filters.removeAt(index);

                          // If no filters left, close dialog
                          if (filters.isEmpty) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void addFilter(context, doctype) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Filter"),
          content: StatefulBuilder(
            builder: (context, setState) {
              stateSetter = setState; // Save setState to use inside functions

              return Obx(() => getFilterForm(context, doctype));
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                filters.add(
                  Filter(
                    field: selectedField.value!, // Default field
                    operator: selectedOperator.value!, // Default operator
                    value: selectedValue.value,
                  ),
                );
                Navigator.pop(context);
                selectedValue.value = null;
              },
              child: Text("Add Filter"),
            ),
          ],
        );
      },
    );
  }

  Widget getFilterForm(BuildContext context, String doctype) {
    formController.getFormLayout(
      doctype,
      true,
      false,
      skipCache: false,
    ); // to load field in memory then use by filter field
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Field Dropdown
        DropdownButtonFormField<FilterField>(
          decoration: InputDecoration(labelText: "Field"),
          isExpanded: true, // Allows full width
          items:
              fieldsList.map<DropdownMenuItem<FilterField>>((
                FilterField field,
              ) {
                return DropdownMenuItem<FilterField>(
                  value: field,
                  child: Text(
                    field.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              selectedField.value = FilterField(
                name: value.name,
                label: value.label,
                type: value.type,
                options: value.options,
              );
            }
          },
        ),

        SizedBox(height: 5),

        // Operator Dropdown
        DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: "Operator"),
          isExpanded: true,
          items:
              operatorsMap.entries.map((opr) {
                return DropdownMenuItem<String>(
                  value: opr.value,
                  child: Text(
                    opr.key,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              selectedOperator.value = FilterField(name: value, label: value);
            }
          },
        ),

        SizedBox(height: 5),

        getFilterValueField(context),
      ],
    );
  }

  Widget getFilterValueField(BuildContext context) {
    final field = selectedField.value;
    final operator = selectedOperator.value?.name ?? "";

    if (field == null) return SizedBox.shrink();

    // Handle Link or Select types
    if ([FieldType.link, FieldType.select].contains(field.type)) {
      return _buildDropdown(
        context,
        label: "Value",
        items:
            field.options!
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => selectedValue.value = value ?? "",
      );
    }

    // Handle Checkbox with true/false
    if (field.type == FieldType.check) {
      return _buildDropdown(
        context,
        label: "Value",
        items:
            ["true", "false"]
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
        onChanged: (value) => selectedValue.value = value ?? "",
      );
    }

    // Handle Date type
    if (field.type == FieldType.date) {
      return _buildDateField(context, operator);
    }

    // Handle 'is' operator with Set/Unset options
    if (operator == "is") {
      return _buildDropdown(
        context,
        label: "Value",
        items:
            ["Set", "Not Set"]
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.toLowerCase(),
                    child: Text(option),
                  ),
                )
                .toList(),
        onChanged: (value) => selectedValue.value = value ?? "",
      );
    }

    // Handle 'is' operator with Set/Unset options
    if (["like", "not like"].contains(operator)) {
      return _buildTextField(context, "use % as wildcard");
    }
    // Handle 'in', 'not in' → convert comma-separated string to list
    if (["in", "not in"].contains(operator)) {
      return _buildMultiSelectField(context, operator);
    }

    // Default TextFormField
    return _buildTextField(context, "Value");
  }

  Widget _buildMultiSelectField(BuildContext context, String operator) {
    String? currentValue = selectedValue.value;

    if (currentValue != null &&
        selectedValue.value is String &&
        currentValue.contains(',')) {
      selectedValue.value =
          currentValue.split(',').map((s) => s.trim()).toList();
    }

    return TextFormField(
      controller:
          _valueController
            ..text =
                selectedValue.value is List
                    ? selectedValue.value.join(", ")
                    : selectedValue.value.toString(),
      decoration: InputDecoration(labelText: "Comma-separated values"),
      onChanged: (value) {
        if (["in", "not in"].contains(operator)) {
          selectedValue.value = value; // Store raw string until used
        }
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required List<DropdownMenuItem<String>> items,
    required void Function(String? value) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(BuildContext context, String operator) {
    return ListTile(
      title: Text(selectedField.value!.label),
      subtitle: Obx(() {
        var value = selectedValue.value;

        if (value is List && operator == "Between" && value.length == 2) {
          return Text("${value[0]} to ${value[1]}");
        } else if (value is String || value is DateTime) {
          final dateStr = value.toString().split(" ").first;
          return Text(dateStr);
        }

        return Text("Select Date");
      }),
      trailing: Icon(Icons.calendar_today),
      onTap: () async {
        if (operator == "Between") {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            initialEntryMode: DatePickerEntryMode.calendarOnly,
          );

          if (range != null) {
            selectedValue.value = [
              DateFormat('yyyy-MM-dd').format(range.start),
              DateFormat('yyyy-MM-dd').format(range.end),
            ];
          }
        } else {
          final date = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );

          if (date != null) {
            selectedValue.value = DateFormat('yyyy-MM-dd').format(date);
          }
        }
      },
    );
  }

  Widget _buildTextField(BuildContext context, String labelText) {
    return TextFormField(
      controller: _valueController,
      keyboardType: TextInputType.text,
      maxLines: null,
      maxLength: null,
      decoration: InputDecoration(
        labelText: labelText,
        alignLabelWithHint: true,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      validator: (value) {
        if ((value?.trim().isEmpty ?? true)) {
          return "Please enter a value";
        }
        return null;
      },
      onChanged: (value) => selectedValue.value = value,
    );
  }

  List<FilterField> getFieldsNameForFilter(dynamic prefs, String doctype) {
    List<FilterField> filterFields = [];
    bool fullForm = true;
    String? tabsAsString = prefs.getString('tabs $doctype $fullForm');
    if (tabsAsString != null) {
      Map<String, List<FormFieldData>> tabs = decodeFormFieldsMap(tabsAsString);
      for (var tab in tabs.values) {
        for (var field in tab) {
          if (field.type == FieldType.unknown ||
              field.type == FieldType.tabBreak ||
              field.type == FieldType.table) {
            continue;
          }
          if (field.type == FieldType.text) field.options = null;
          filterFields.add(
            FilterField(
              name: field.fieldName,
              label: field.label ?? "",
              type: field.type,
              options: field.options,
            ),
          );
        }
      }
    }
    return filterFields;
  }

  void clearFilters() {
    filters.clear();
    filters.refresh();
  }

  // Check if any row is selected
  bool get hasSelection => selectedRowIndices.isNotEmpty;

  int getSelectedIndex() {
    return isSelected.indexWhere((element) => element == true);
  }

  // Track selected row indices
  final selectedRowIndices = <int>[].obs;

  // Toggle selection for a specific row
  void toggleSelection(int index) {
    if (selectedRowIndices.contains(index)) {
      selectedRowIndices.remove(index);
      selectedRowIndices.refresh();
    } else {
      selectedRowIndices.add(index);
      selectedRowIndices.refresh();
    }
  }

  // Clear all selections
  void clearSelections() {
    selectedRowIndices.clear();
    selectedRowIndices.refresh();
  }

  // Delete selected rows
  Future<void> deleteSelected(
    BuildContext context,
    List<Map<String, dynamic>> reportData,
    String doctype,
  ) async {
    List<String> entriesToDelete =
        selectedRowIndices.map<String>((idx) {
          String name = reportData[idx]['name']; // primary key
          return name;
        }).toList();
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final url = Uri.parse(
      "$domain/api/method/frappe.desk.reportview.delete_items",
    );
    String items = jsonEncode(entriesToDelete);
    Map<String, String> reqBody = {'items': items, 'doctype': doctype};
    final response = await session.post(url, body: reqBody);
    if (response.statusCode != 200) {
      String message = jsonDecode(response.body)['exception'];
      showAutoDismissDialog(context, message);
    } else {
      Map<String, dynamic> data = jsonDecode(response.body);
      if (data["_server_messages"] != null) {
        var errorMessages = jsonDecode(data["_server_messages"]);
        String errorMessage = jsonDecode(errorMessages[0])['message'];
        String cleanErrorMessage = removeHtmlTags(errorMessage);
        showAutoDismissDialog(context, "Error: $cleanErrorMessage");
      } else {
        clearSelections();
        Get.off(ListViewScreen(doctype: doctype), preventDuplicates: false);
        // showAutoDismissDialog(context, "deleted Successfully");
      }
    }
    clearSelections();
  }

  Future<List<Map<String, dynamic>>?> getReportView(
    String doctype,
    BuildContext context,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final url = Uri.parse("$domain/api/method/frappe.desk.reportview.get");

    List<Map<String, dynamic>> listviewFields =
        await getListviewFields(doctype) ?? [];
    List<FilterField> filterFields = getFieldsNameForFilter(prefs, doctype);
    fieldsList.value = filterFields;
    listviewFields.insert(0, {"fieldname": "name"});
    String fields =
        '["${listviewFields.map((field) => "`tab$doctype`.`${field['fieldname']}`").join('","')}"]'
            .replaceAll("status_field", "docstatus");

    String filterList = buildFilterList(doctype, filters.cast<Filter>());

    int index = isSelected.indexWhere((element) => element == true);
    Map<String, String> reqBody = {
      'doctype': doctype,
      'fields': fields,
      'filters': filterList, // Use the filter value here
      'order_by': '`tab$doctype`.`modified` desc',
      'start': '0',
      'page_length': elmCountoptions[index],
      'view': 'List',
      'group_by': '',
      'with_comment_count': '1',
    };

    final response = await session.post(url, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
    if (data["message"] != null && data["message"].isNotEmpty) {
      List<String> keys = List<String>.from(data["message"]["keys"]);
      keys = keys.map((item) => item.replaceAll('_', ' ')).toList();

      List<List<dynamic>> values = List<List<dynamic>>.from(
        data["message"]["values"],
      );

      List<Map<String, dynamic>> listOfMaps = [];

      for (var row in values) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < keys.length; i++) {
          map[keys[i].toString()] = row[i];
        }
        listOfMaps.add(map);
      }
      return listOfMaps;
    } else if (data["exception"] != null && data["exception"].isNotEmpty) {
      String errorMessage = jsonDecode(response.body)['exception'];
      showAutoDismissDialog(context, "Error: $errorMessage");
      return [];
    } else {
      return [];
    }
  }

  String buildFilterList(String doctype, List<Filter> filters) {
    List<String> filterStrings =
        filters.map((filter) {
          List<String> parts = [
            doctype,
            filter.field.name,
            filter.operator.name,
          ];

          // Apply quotes only on first 3 items
          List<String> quotedParts = parts.map((p) => '"$p"').toList();

          // Handle value separately
          String valueStr;
          if (filter.value is List) {
            // If value is already a list, encode it as JSON array
            valueStr = jsonEncode(filter.value);
          } else {
            // If it's a single value, just quote it
            valueStr = '"${filter.value}"';
          }

          // Join quoted parts + raw value
          String result = '[${quotedParts.join(", ")}, $valueStr]';
          return result;
        }).toList();

    return '[${filterStrings.join(', ')}]';
  }

  Future<List<Map<String, dynamic>>?> getListviewFields(String doctype) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final url = Uri.parse(
      "$domain/api/method/frappe.desk.listview.get_list_settings",
    );

    Map<String, String> reqBody = {'doctype': doctype};
    final response = await session.post(url, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);

    if (data.containsKey("message") &&
        data["message"] != null &&
        data["message"].containsKey("fields") &&
        data["message"]["fields"] != null) {
      List<Map<String, dynamic>> fields = List<Map<String, dynamic>>.from(
        jsonDecode(data["message"]["fields"]),
      );
      return fields;
    } else {
      final reportViewUrl = Uri.parse(
        "$domain/api/method/frappe.desk.doctype.list_view_settings.list_view_settings.get_default_listview_fields",
      );
      final response = await session.post(reportViewUrl, body: reqBody);
      Map<String, dynamic> data = jsonDecode(response.body);
      if (data.containsKey("message") && data["message"] != null) {
        List fields = data["message"];
        // Transform the list into a list of maps
        List<Map<String, dynamic>> defaultFields =
            fields.map((field) {
              return {"fieldname": field, "label": field.replaceAll("_", " ")};
            }).toList();

        return defaultFields;
      }
    }
  }

  Future<bool> getItemInfo(String doctype, String itemName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final url = Uri.parse("$domain/api/method/frappe.desk.form.load.getdoc");

    Map<String, String> reqBody = {
      'doctype': doctype,
      'name': itemName,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final response = await session.post(url, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
    if (data['docs'] != null) {
      Map<String, dynamic> doctypeData = data['docs'][0];
      for (var entry in doctypeData.entries) {
        // doctypeData.entries.map((entry) {
        String fieldName = entry.key.toString();
        var value = entry.value;
        if (value.runtimeType == List) {
          // table field
          formController.tableRowValues[fieldName] = removeTableMetadata(value);
        } else {
          formController.formValues[fieldName] = value;
        }
      }
    } else {
      return false;
    }
    formController.tableRowValues.refresh();
    formController.formValues.refresh();
    return true;
  }
}

class Filter {
  Filter({required this.field, required this.operator, required this.value});
  FilterField field;

  FilterField operator;

  dynamic value;
}

class FilterField {
  FilterField({
    required this.name,
    required this.label,

    this.options = const [],
    this.type = FieldType.text,
  });

  final String name;
  final String label;
  final FieldType type;
  List? options;
}

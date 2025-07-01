import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/form_controller.dart';

import '../../../utils/helper.dart';
import '../models/field_type_model.dart';
import '../models/form_field_model.dart';
import 'shared_preferences_controller.dart';
import 'package:intl/intl.dart';

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
  final RxString selectedValue = "".obs;
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
                    children: [
                      Expanded(
                        child: Text(
                          filter.field.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 4),

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
                          filter.value,
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

              return Obx(() => getFilterForm(context));
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
              },
              child: Text("Add Filter"),
            ),
          ],
        );
      },
    );
  }

  Widget getFilterForm(BuildContext context) {
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
    if ([
      FieldType.link,
      FieldType.select,
    ].contains(selectedField.value?.type)) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: "Value"),
        isExpanded: true, // Allows full width
        items:
            selectedField.value?.options!.map<DropdownMenuItem<String>>((
              option,
            ) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            selectedValue.value = value;
          }
        },
      );
    } else if (selectedField.value?.type == FieldType.check) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: "Value"),
        isExpanded: true, // Allows full width
        items: [
          DropdownMenuItem<String>(
            value: '1',
            child: Text('true', style: TextStyle(fontSize: 14)),
          ),
          DropdownMenuItem<String>(
            value: '0',
            child: Text('false', style: TextStyle(fontSize: 14)),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            selectedValue.value = value;
          }
        },
      );
    } else if (selectedField.value?.type == FieldType.date) {
      final field = selectedField.value!;
      final operator = selectedOperator.value?.name ?? "";

      return ListTile(
        title: Text(field.label),
        subtitle: Obx(() {
          if (selectedValue.value.isNotEmpty) {
            if (operator == "Between") {
              // Show date range
              final dates = selectedValue.value.split(" - ");
              if (dates.length == 2) {
                return Text("${dates[0]} to ${dates[1]}");
              }
            } else {
              // Show single date
              DateTime? date = DateTime.tryParse(selectedValue.value);
              if (date != null) {
                return Text(DateFormat('yyyy-MM-dd').format(date));
              }
            }
          }
          return Text("Select Date");
        }),
        trailing: Icon(Icons.calendar_today),
        onTap: () async {
          if (operator == "Between") {
            // Date Range Picker
            final initialRange =
                selectedValue.value.isNotEmpty
                    ? selectedValue.value
                        .split(" - ")
                        .map((d) => DateTime.parse(d))
                        .toList()
                    : [DateTime.now(), DateTime.now().add(Duration(days: 7))];

            final pickedRange = await showDateRangePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
            );

            if (pickedRange != null) {
              String rangeString =
                  "${DateFormat('yyyy-MM-dd').format(pickedRange.start)} - ${DateFormat('yyyy-MM-dd').format(pickedRange.end)}";
              selectedValue.value = rangeString;
            }
          } else {
            // Single Date Picker
            DateTime? initialDate =
                selectedValue.value.isNotEmpty
                    ? DateTime.tryParse(selectedValue.value)
                    : DateTime.now();

            final pickedDate = await showDatePicker(
              context: context,
              initialDate: initialDate!,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );

            if (pickedDate != null) {
              selectedValue.value = pickedDate.toIso8601String();
            }
          }
        },
      );
    } else {
      return TextFormField(
        controller: _valueController,
        keyboardType: TextInputType.text,
        maxLines: null, // allows multiple lines
        minLines: 1,
        maxLength: null,
        decoration: InputDecoration(
          labelText: "Value",
          alignLabelWithHint: true,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter a value";
          }
          return null;
        },
        onChanged: (value) {
          selectedValue.value = value;
        },
      );
    }
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
            filter.value,
          ];
          return '[${parts.map((p) => '"$p"').join(', ')}]';
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

class Filter {
  Filter({required this.field, required this.operator, required this.value});
  FilterField field;

  FilterField operator;

  String value;
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

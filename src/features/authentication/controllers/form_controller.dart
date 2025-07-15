import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../utils/helper.dart';
import '../models/doctype_model.dart';
import '../models/field_type_model.dart';
import '../models/form_field_model.dart';
import '../screens/list_view_screen/list_view_screen.dart';
import 'shared_preferences_controller.dart';

class FormController extends GetxController {
  final session = Get.find<Session>();
  final sharedPreferencesController = Get.put(SharedPreferencesController());

  RxMap formValues = {}.obs;
  var isSubmitting = false.obs;
  RxBool skipCache = false.obs;
  RxMap<dynamic, dynamic> tablesData = {}.obs;
  RxMap<dynamic, dynamic> tableRowValues = {}.obs; // rows for each table

  void reset() {
    formValues.clear();
    tablesData.clear();
    tableRowValues.clear();

    // Notify UI and controllers
    formValues.refresh();
    tablesData.refresh();
    tableRowValues.refresh();
  }

  Future<Map<String, dynamic>> getFormLayoutData(String doctype) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final url = Uri.parse(
      "$domain/api/method/frappe.desk.form.load.getdoctype",
    );
    String cachedTimestamp = DateTime.now().toUtc().toString().replaceFirst(
      'Z',
      '',
    );
    Map<String, String> reqBody = {
      'doctype': doctype,
      'with_parent': '1',
      'cached_timestamp': cachedTimestamp,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await session.post(url, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  }

  Future<Map<String, List<FormFieldData>>> getFormLayout(
    String doctype,
    bool fullForm,
    bool forEditing, {
    bool skipCache = false, // ← NEW PARAMETER
  }) async {
    Map<String, dynamic> data = await getFormLayoutData(doctype);

    final prefs = await sharedPreferencesController.prefs;

    Map<String, List<FormFieldData>> tabs = {};

    if (!skipCache) {
      // ← Only use cache if skipCache == false
      String? tabsAsString = prefs.getString('tabs $doctype $fullForm');
      if (tabsAsString != null) {
        tabs = decodeFormFieldsMap(tabsAsString);
        for (var tab in tabs.values) {
          for (var field in tab) {
            if (field.type == FieldType.table) {
              if (tableRowValues[field.fieldName] == null || !forEditing) {
                tableRowValues[field.fieldName] = [];
              }
              if (tablesData[field.fieldName] == null || !forEditing) {
                tablesData[field.fieldName] = [];
              }
            }
          }
        }
        return tabs;
      }
    }

    if (data["docs"] != null && data["docs"].isNotEmpty) {
      var docsList = data["docs"];
      tabs = await getTabs(doctype, docsList, 0, fullForm);

      prefs.setString('tabs $doctype $fullForm', encodeFormFieldsMap(tabs));

      return tabs;
    } else {
      return {};
    }
  }

  Future<Map<String, dynamic>> getTableField(
    String doctype,
    dynamic doctypeData,
    dynamic field,
    Map<String, dynamic> fieldMap,
  ) async {
    for (var doc in doctypeData) {
      if (doc['name'] == field['options']) {
        List<dynamic> fieldsMeta = doc['fields'];
        Map<String, dynamic> tablefieldMap = {};
        for (var field in fieldsMeta) {
          final tableFieldName = field["fieldname"];

          if (field['fieldtype'] == "Select" && field.containsKey('options')) {
            try {
              field['options'] = field['options'].split("\n");
            } catch (e) {
              field['options'] = []; // item barcode type doesn't return options
            }
          }
          if (field['fieldtype'] == "Link") {
            field['options'] = await searchLink(field['options'], doctype);
          }
          tablefieldMap[tableFieldName] = field;
        }
        field['data'] = tablefieldMap;
      }
    }
    return field;
  }

  Future<Map<String, List<FormFieldData>>> getTabs(
    String referenceDoctype,
    var doctypeData,
    int indexOfFfield,
    bool fullForm,
  ) async {
    String doctype = doctypeData[indexOfFfield]['name'];

    List<dynamic> fieldsOrder = getFieldsOrder(
      doctypeData,
      indexOfFfield,
      fullForm,
    );
    Map<String, dynamic> fieldMap = await getFieldMap(
      doctype,
      referenceDoctype,
      doctypeData,
      indexOfFfield,
    );
    int tableIndex = 0;
    Map<String, List<FormFieldData>> formTabs = {};
    List<FormFieldData> fields = [];
    int tabBreakCount = 0;
    String? previousTabName;

    bool hasDefaultTab = false;

    for (var entry in fieldsOrder.asMap().entries) {
      int index = entry.key;
      String? fieldName = entry.value;
      if (fieldName == null) continue;

      var prevFieldName;
      bool condition;
      try {
        prevFieldName = fieldsOrder[index - 1];
        condition = fieldMap[prevFieldName]['fieldtype'] != 'Tab Break';
      } catch (e) {
        prevFieldName = null;
        condition = true;
      }

      if (fullForm) {
        // Handle special case where no Tab Break at first field, instead Section break
        if (fields.isEmpty &&
            fieldMap[fieldName]['fieldtype'] == 'Section Break' &&
            condition) {
          Map<String, dynamic> fieldMeta = fieldMap[fieldName] ?? {};
          FormFieldData? field = await getFormFieldsData(
            fieldName,
            fieldMeta,
            tableIndex,
          );

          tabBreakCount++;

          if (tabBreakCount > 1 && previousTabName != null) {
            formTabs[previousTabName] = fields;
            fields = [];
          } else {
            fields = [];
          }

          previousTabName = field?.label;
          continue;
        }

        // First field is NOT Tab Break or Section Break → create default tab
        if (fields.isEmpty &&
            fieldMap[fieldName]['fieldtype'] != 'Tab Break' &&
            fieldMap[fieldName]['fieldtype'] != 'Section Break' &&
            !hasDefaultTab) {
          previousTabName = 'Details';
          tabBreakCount = 1;
          hasDefaultTab = true;
        }

        Map<String, dynamic> fieldMeta = fieldMap[fieldName] ?? {};
        final String fieldTypeStr = fieldMeta['fieldtype'] ?? 'Unknown';

        if (fieldTypeStr == "Table") {
          fieldMeta = await getTableFieldsFromUserSettings(doctype, fieldMeta);
        }

        FormFieldData? field = await getFormFieldsData(
          fieldName,
          fieldMeta,
          tableIndex,
        );

        if (fieldTypeStr == "Table" && field != null) {
          tableIndex++;
          tablesData[field.fieldName] = [];
          tableRowValues[field.fieldName] = [];
        }

        if (fieldTypeStr == "Tab Break") {
          tabBreakCount++;

          if (tabBreakCount > 1 && previousTabName != null) {
            formTabs[previousTabName] = fields;
            fields = []; // Reset for new section
          } else {
            fields = []; // First Tab Break → reset fields
          }

          previousTabName = field?.label;
          continue;
        }

        if (field != null) {
          fields.add(field);
        }
      } else {
        // fullForm is false
        if (fieldName == null) continue;
        var fieldMeta = fieldMap[fieldName] ?? {};
        final String fieldTypeStr = fieldMeta['fieldtype'] ?? 'Unknown';
        if (fieldTypeStr == "Table") {
          fieldMeta = await getTableFieldsFromUserSettings(doctype, fieldMeta);
        }

        FormFieldData? field = await getFormFieldsData(
          fieldName,
          fieldMeta,
          tableIndex,
        );
        if (field != null) {
          fields.add(field);
        }
      }
    }

    if (fullForm) {
      // After loop: add last section if any
      if (tabBreakCount >= 1 && previousTabName != null && fields.isNotEmpty) {
        formTabs[previousTabName] = fields;
      } else if (hasDefaultTab && fields.isNotEmpty) {
        // If using default tab and there are fields left
        formTabs['Details'] = fields;
      }
    } else {
      formTabs['Main Form'] = fields;
    }
    return formTabs;
  }

  Future<FormFieldData> getTableFormFieldsData(
    String fieldName,
    dynamic fieldMeta,
    int tableIndex,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? owner = prefs.getString("login_email");
    Map<String, dynamic> dataMap = fieldMeta['data'];

    final String fieldTypeStr = fieldMeta['fieldtype'] ?? 'Unknown';
    final FieldType fieldType = stringToFieldType(fieldTypeStr, "sddd");
    TableDoctypeData tableDoctypeData = TableDoctypeData(
      docstatus: 0,
      doctype: fieldMeta['options'],
      name: "new-uom-conversion-detail-wipzjudtsj",
      owner: '$owner',
      parent: "new-item-idekfywkco",
      parentfield: fieldMeta['fieldname'],
      parenttype: fieldMeta['parent'],
      idx: tableIndex + 1,
    );
    List<FormFieldData> data =
        dataMap.entries.map((entry) {
          return FormFieldData(
            fieldName: entry.key,
            type: stringToFieldType(entry.value['fieldtype'], "dddd"),
            label: fieldMeta['label'] ?? entry.key,
            options: fieldMeta['options'],
            defaultValue: fieldMeta['default'],
            data: entry.value,
            tableIndex: tableIndex,
            tableDoctypeData: tableDoctypeData,
          );
        }).toList();

    try {
      return FormFieldData(
        fieldName: fieldName,
        type: fieldType,
        label: fieldMeta['label'] ?? fieldName,
        options: fieldMeta['options'],
        defaultValue: fieldMeta['default'],
        data: data,
        tableIndex: tableIndex,
        tableDoctypeData: tableDoctypeData,
      );
    } catch (e) {
      return FormFieldData(
        fieldName: fieldName,
        type: fieldType,
        label: fieldMeta['label'] ?? fieldName,
        options: null,
        defaultValue: fieldMeta['default'],
        tableIndex: tableIndex,
        tableDoctypeData: tableDoctypeData,
      );
    }
  }

  Future<FormFieldData?> getFormFieldsData(
    String fieldName,
    dynamic fieldMeta,
    int tableIndex,
  ) async {
    final String fieldTypeStr = fieldMeta['fieldtype'] ?? 'Unknown';
    if (fieldMeta['hidden'] == 1) {
      return null;
    }
    if (fieldTypeStr == "Table") {
      return getTableFormFieldsData(fieldName, fieldMeta, tableIndex);
    }

    final FieldType fieldType = stringToFieldType(fieldTypeStr, fieldName);

    try {
      return FormFieldData(
        fieldName: fieldName,
        type: fieldType,
        label: fieldMeta['label'] ?? fieldName,
        options: fieldMeta['options'],
        defaultValue: fieldMeta['default'],
      );
    } catch (e) {
      return FormFieldData(
        fieldName: fieldName,
        type: fieldType,
        label: fieldMeta['label'] ?? fieldName,
        options: null,
        defaultValue: fieldMeta['default'],
      );
    }
  }

  List<dynamic> getFieldsOrder(
    dynamic doctypeData,
    int indexOfFfield,
    bool fullForm,
  ) {
    var fieldsOrder =
        doctypeData[indexOfFfield]['fields'].map((field) {
          if (field['reqd'] == 0) {
            if (fullForm) {
              return field['fieldname'];
            }
          } else {
            return field['fieldname'];
          }
        }).toList();
    return fieldsOrder;
  }

  Future<Map<String, dynamic>> getFieldMap(
    String doctype,
    String referenceDoctype,
    dynamic doctypeData,
    int indexOfFfield,
  ) async {
    List<dynamic> fieldsMeta = doctypeData[indexOfFfield]['fields'];
    Map<String, dynamic> fieldMap = {};
    for (var field in fieldsMeta) {
      final fieldName = field["fieldname"];

      if (field['fieldtype'] == "Select" && field.containsKey('options')) {
        try {
          field['options'] = field['options'].split("\n");
        } catch (e) {
          field['options'] = []; // doctype doesn't return options
        }
      }
      if (field['fieldtype'] == "Link") {
        if (field['options'].runtimeType == String) {
          field['options'] = await searchLink(field['options'], doctype);
        } else {
          field['options'] = await searchLink(doctype, referenceDoctype);
        }
      }
      if (field['fieldtype'] == "Table") {
        field = await getTableField(doctype, doctypeData, field, fieldMap);
      }

      fieldMap[fieldName] = field;
    }
    return fieldMap;
  }

  Future<List<String>> searchLink(
    String doctype,
    String referenceDoctype,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final url = Uri.parse("$domain/api/method/frappe.desk.search.search_link");
    // if (doctype.contains("From ")){
    //   doctype = doctype.replaceFirst("From ", "");
    // }
    Map<String, String> reqBody = {
      'txt': '',
      'doctype': doctype,
      'ignore_user_permissions': '1',
      'reference_doctype': referenceDoctype,
      'page_length': '10',
    };

    final response = await session.post(url, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);

    if (data["message"] != null &&
        data["message"] is List &&
        data["message"].isNotEmpty) {
      try {
        return data["message"]
            .map<String>((option) => option['value']?.toString() ?? '')
            .toList();
      } catch (e) {
        print('Error parsing message list: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  Future<void> submitForm(String doctype, bool forEditing, context) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final String? owner = prefs.getString("login_email");

    Map<String, dynamic> jsonReq = {
      "docstatus": 0,
      "doctype": doctype,
      "__unsaved": 1,
      "owner": owner,
      "__run_link_triggers": 1,
    };

    Map<String, dynamic> fullDoc = {
      ...jsonReq,
      ...tableRowValues,
      ...formValues,
    };

    Uri url;
    http.Response response;
    if (forEditing) {
      url = Uri.parse("$domain/api/method/frappe.desk.form.save.savedocs");
      String docJson = jsonEncode(fullDoc);
      String docDataEncoded = Uri.encodeComponent(docJson);
      String updatedJsonString = 'doc=$docDataEncoded&action=Save';
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        ...session.headers,
      };

      response = await http.post(
        url,
        headers: headers,
        body: updatedJsonString,
      );
      if (response.statusCode == 200) {
        isSubmitting.value = false;
        Get.off(ListViewScreen(doctype: doctype));
      } else {
        // String errorMessage = jsonDecode(response.body)['exception'];
        isSubmitting.value = false;
        showAutoDismissDialog(context, "Error: ${response.body}");
      }
    } else {
      url = Uri.parse("$domain/api/method/frappe.client.save");
      String docJson = jsonEncode(fullDoc);
      Map<String, String> reqBody = {'doc': docJson};
      response = await session.post(url, body: reqBody);
      if (response.statusCode == 200) {
        isSubmitting.value = false;
        Get.off(ListViewScreen(doctype: doctype));
      } else {
        String errorMessage = jsonDecode(response.body)['exception'];
        isSubmitting.value = false;
        showAutoDismissDialog(context, "Error: $errorMessage");
      }
    }
  }

  Future<Map<String, dynamic>> getUserSettings(String doctype) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    Uri userSettingsUrl = Uri.parse(
      "$domain/api/method/frappe.model.utils.user_settings.get",
    );
    Map<String, String> reqBody = {'doctype': doctype};
    http.Response response = await session.post(userSettingsUrl, body: reqBody);
    final responseBody = jsonDecode(response.body); // First decode
    final String messageStr = responseBody['message']; // Still a String
    final Map<String, dynamic> userSettings = jsonDecode(
      messageStr,
    ); // Now a Map
    return userSettings;
  }

  Future<Map<String, dynamic>> getTableFieldsFromUserSettings(
    String doctype,
    Map<String, dynamic> fieldMeta,
  ) async {
    // Get user settings
    final userSettings = await getUserSettings(doctype);

    // Extract GridView settings
    final tableUserSettings = userSettings['GridView'] as Map<String, dynamic>?;

    // Get table label from options
    final tableLabel = fieldMeta['options'] as String?;

    if (tableUserSettings == null || tableLabel == null) {
      return fieldMeta; // Missing required data
    }

    // Get fields defined in user settings (with order)
    final List<dynamic>? userFields =
        tableUserSettings[tableLabel] as List<dynamic>?;

    if (userFields == null || userFields.isEmpty) {
      return fieldMeta;
    }

    // Extract ordered field names
    final List<String> orderedFieldNames =
        userFields
            .where((item) => item is Map<String, dynamic>)
            .map((item) => item['fieldname'] as String?)
            .where((name) => name != null)
            .cast<String>()
            .toList();

    if (orderedFieldNames.isEmpty) {
      return fieldMeta;
    }

    // Build ordered map based on user-defined field order
    final Map<String, dynamic> orderedData = {};
    final Map<String, dynamic>? originalData =
        fieldMeta['data'] as Map<String, dynamic>?;

    if (originalData != null) {
      for (String fieldName in orderedFieldNames) {
        if (originalData.containsKey(fieldName)) {
          orderedData[fieldName] = originalData[fieldName];
        }
      }
    }

    // Return updated fieldMeta with ordered data
    return {...fieldMeta, 'data': orderedData};
  }

  Future<void> removeTableRow(
    String tableFieldName,
    int index,
    BuildContext context,
  ) async {
    bool? confirm = await showConfirmationDialog(
      context,
      'Are you sure you want to delete this row?',
    );

    if (confirm == true) {
      tableRowValues[tableFieldName]?.removeAt(index);
      tableRowValues.refresh();
    }
  }

  Future<void> clearTableRows(
    String tableFieldName,
    BuildContext context,
  ) async {
    bool? confirm = await showConfirmationDialog(
      context,
      'Are you sure you want to delete all rows?',
    );

    if (confirm == true) {
      tableRowValues[tableFieldName]?.clear();
      tableRowValues.refresh();
    }
  }
}

import 'dart:convert';

import 'package:get/get.dart';

import '../../../utils/helper.dart';
import '../models/doctype_model.dart';
import '../models/form_field_model.dart';
import '../screens/list_view_screen/list_view_screen.dart';
import 'shared_preferences_controller.dart';

enum FieldType { text, date, select, check, link, tabBreak, table, unknown }

class FormController extends GetxController {
  final session = Get.find<Session>();
  final sharedPreferencesController = Get.put(SharedPreferencesController());

  RxMap formValues = {}.obs;
  RxBool isSubmitting = false.obs;
  // RxMap<Map> tableRows = List.generate(100, (_) => {}).obs;
  var tablesData = {}.obs;
  List<FormFieldData> fields = [];

  Future<List<List<FormFieldData>>> getFormLayout(
    String doctype,
    bool fullForm,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final reportViewUrl = Uri.parse(
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

    final response = await session.post(reportViewUrl, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
    List<List<FormFieldData>> listOfDocs = [];

    if (data["docs"] != null && data["docs"].isNotEmpty) {
      var docsList = data["docs"];

      for (int i = 0; i < docsList.length; i++) {
        List<FormFieldData> fields = await getFields(
          doctype,
          docsList,
          i,
          fullForm,
        );
        listOfDocs.add(fields);
      }

      return listOfDocs;
    } else {
      return [];
    }
  }

  Future<List<FormFieldData>> getFields(
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
    List<FormFieldData> fields = [];
    for (var fieldName in fieldsOrder) {
      final fieldMeta = fieldMap[fieldName] ?? {};
      final String fieldTypeStr = fieldMeta['fieldtype'] ?? 'Unknown';
      FormFieldData field = await getFormFieldsData(
        fieldName,
        fieldMeta,
        tableIndex,
      );
      if (fieldTypeStr == "Table") {
        // tableIndex++;
        // tablesData[field.fieldName] = [];
      }
      fields.add(field);
    }
    return fields;
  }

  Future<FormFieldData> getFormFieldsData(
    String fieldName,
    dynamic fieldMeta,
    int tableIndex,
  ) async {
    final String fieldTypeStr = fieldMeta['fieldtype'] ?? 'Unknown';
    final prefs = await sharedPreferencesController.prefs;
    final String? owner = prefs.getString("login_email");
    if (fieldTypeStr == "Table") {
      Map<String, dynamic> data = fieldMeta['data'];
      final FieldType fieldType = _parseFieldType(fieldTypeStr);
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
      try {
        return FormFieldData(
          fieldName: fieldName,
          type: fieldType,
          label: fieldMeta['label'] ?? fieldName,
          options: fieldMeta['options'],
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
          tableIndex: tableIndex,
          tableDoctypeData: tableDoctypeData,
        );
      }
    }

    final FieldType fieldType = _parseFieldType(fieldTypeStr);

    try {
      return FormFieldData(
        fieldName: fieldName,
        type: fieldType,
        label: fieldMeta['label'] ?? fieldName,
        options: fieldMeta['options'],
      );
    } catch (e) {
      return FormFieldData(
        fieldName: fieldName,
        type: fieldType,
        label: fieldMeta['label'] ?? fieldName,
        options: null,
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
        for (var doc in doctypeData) {
          if (doc['name'] == field['options']) {
            List<dynamic> fieldsMeta = doc['fields'];
            Map<String, dynamic> tablefieldMap = {};
            for (var field in fieldsMeta) {
              final tableFieldName = field["fieldname"];

              if (field['fieldtype'] == "Select" &&
                  field.containsKey('options')) {
                try {
                  field['options'] = field['options'].split("\n");
                } catch (e) {
                  field['options'] =
                      []; // item barcode type doesn't return options
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
      }

      fieldMap[fieldName] = field;
    }
    return fieldMap;
  }

  FieldType _parseFieldType(String typeStr) {
    switch (typeStr) {
      case 'Date':
        return FieldType.date;
      case 'Select':
        return FieldType.select;
      case 'Link':
        return FieldType.link;
      case 'Check':
        return FieldType.check;
      case 'Text':
      case 'Small Text':
      case 'Text Editor':
      case 'Float':
      case 'Int':
      case 'Currency':
      case 'Data':
        return FieldType.text;
      case 'Tab Break':
        return FieldType.tabBreak;
      case 'Table':
        return FieldType.table;
      default:
        return FieldType.unknown;
    }
  }

  Future<List<String>> searchLink(
    String doctype,
    String referenceDoctype,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.search.search_link",
    );
    Map<String, String> reqBody = {
      'txt': '',
      'doctype': doctype,
      'ignore_user_permissions': '1',
      'reference_doctype': referenceDoctype,
      'page_length': '10',
    };

    final response = await session.post(reportViewUrl, body: reqBody);
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

  Future<void> submitForm(String doctype, context) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final String? owner = prefs.getString("login_email");

    final reportViewUrl = Uri.parse("$domain/api/method/frappe.client.save");
    Map<String, dynamic> jsonReq = {
      "docstatus": 0,
      "doctype": doctype,
      "__islocal": 1,
      "__unsaved": 1,
      "owner": owner,
      "__run_link_triggers": 1,
    };
    formValues = formValues;
    // tableRows.map((table) {
    // {
    //       "docstatus": 0,
    //       "doctype": "UOM Conversion Detail", ####
    //       "name": "new-uom-conversion-detail-wipzjudtsj", ####
    //       "__islocal": 1,
    //       "__unsaved": 1,
    //       "owner": $owner,
    //       "parent": "new-item-idekfywkco",  ####
    //       "parentfield": "uoms",
    //       "parenttype": $doctype,
    //       "idx": 1,
    //       "__unedited": false,
    //       "uom": null,
    //       "conversion_factor": 222
    //   }
    // });
    Map<String, dynamic> fullDoc = {...jsonReq, ...formValues};

    String docJson = jsonEncode(fullDoc);
    Map<String, String> reqBody = {'doc': docJson};
    final response = await session.post(reportViewUrl, body: reqBody);
    if (response.statusCode == 200) {
      isSubmitting.value = false;
      Get.to(ListViewScreen(doctype: doctype));
    } else {
      String errorMessage = jsonDecode(response.body)['exception'];
      isSubmitting.value = false;
      showAutoDismissDialog(context, "Error: $errorMessage");
    }
  }
}

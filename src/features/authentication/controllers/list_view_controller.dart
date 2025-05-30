import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/form_controller.dart';

import '../../../utils/helper.dart';
import 'shared_preferences_controller.dart';

class ListViewController extends GetxController {
  final session = Get.find<Session>();
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final FormController formController = Get.put(FormController());

  final List<String> options = ['20', '100', '500', '2500'];
  RxList<dynamic> isSelected = [true, false, false, false].obs;

  // Observable filter variable
  var filter = ''.obs;
  var refreshed = false.obs;

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
          return reportData[idx]['item name'];
        }).toList();
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.reportview.delete_items",
    );
    String items = jsonEncode(entriesToDelete);
    Map<String, String> reqBody = {'items': items, 'doctype': doctype};
    final response = await session.post(reportViewUrl, body: reqBody);
    if (response.statusCode != 200) {
      String message = jsonDecode(response.body)['exception'];
      showAutoDismissDialog(context, message);
    }
    clearSelections();
  }

  Future<List<Map<String, dynamic>>?> getReportView(
    String doctype,
    String filter,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.reportview.get",
    );

    List<Map<String, dynamic>>? listviewFields = await getListviewFields(
      doctype,
    );

    if (listviewFields != null) {
      // Use the filter value in the request
      String fields =
          '["${listviewFields.map((field) => "`tab$doctype`.`${field['fieldname']}`").join('","')}"]'
              .replaceAll("status_field", "docstatus");
      String filterList;
      if (filter.isNotEmpty) {
        List listElemets = [doctype, "name", "like", "%$filter%"];
        // Convert the list to a string with quotes around each element
        filterList = "[${listElemets.map((item) => '"$item"').join(", ")}]";
      } else {
        filterList = '';
      }

      int index = isSelected.indexWhere((element) => element == true);
      Map<String, String> reqBody = {
        'doctype': doctype,
        'fields': fields,
        'filters': '[$filterList]', // Use the filter value here
        'order_by': '`tab$doctype`.`modified` desc',
        'start': '0',
        'page_length': options[index],
        'view': 'List',
        'group_by': '',
        'with_comment_count': '1',
      };

      final response = await session.post(reportViewUrl, body: reqBody);
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
      } else {
        return [];
      }
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getListviewFields(String doctype) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.listview.get_list_settings",
    );

    Map<String, String> reqBody = {'doctype': doctype};
    final response = await session.post(reportViewUrl, body: reqBody);
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
      List fields = data["message"];

      // Transform the list into a list of maps
      List<Map<String, dynamic>> defaultFields =
          fields.map((field) {
            return {"fieldname": field, "label": field.replaceAll("_", " ")};
          }).toList();

      return defaultFields;
    }
  }

  Future<List<Map<String, dynamic>>?> getItemInfo(
    String doctype,
    String itemName,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.form.load.getdoc",
    );

    Map<String, String> reqBody = {
      'doctype': doctype,
      'name': itemName,
      // '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final response = await session.post(reportViewUrl, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
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
  }
}

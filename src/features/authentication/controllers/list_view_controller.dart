import 'dart:convert';

import 'package:get/get.dart';

import '../../../utils/helper.dart';

class ListViewController extends GetxController {
  final session = Get.find<Session>();
  final String domain = 'https://mooii.erpnext.com';
  Future<List<Map<String, dynamic>>> getReportView() async {
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.reportview.get",
    );
    List<Map<String, dynamic>> defualtFields = await getListviewFields();
    String fields = '["${defualtFields.map((field) => "`tabItem`.`${field["fieldname"]}`").join('","')}"]';
    Map<String, String> reqBody = {
      'doctype': 'Item',
      'fields': fields,
      'filters': '[]',
      'order_by': '`tabItem`.`modified` desc',
      'start': '0',
      'page_length': '20',
      'view': 'List',
      'group_by': '',
      'with_comment_count': '1',
    };
    final response = await session.post(reportViewUrl, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
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
  }

  Future<List<Map<String, dynamic>>> getListviewFields() async {
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.listview.get_list_settings",
    );
    Map<String, String> reqBody = {'doctype': 'Item'};
    final response = await session.post(reportViewUrl, body: reqBody);
    Map<String, dynamic> data = jsonDecode(response.body);
    List<Map<String, dynamic>> defualtFields = List<Map<String, dynamic>>.from(jsonDecode(data["message"]["fields"]));
    return defualtFields;
  }
}

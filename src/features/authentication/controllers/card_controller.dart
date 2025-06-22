import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../utils/helper.dart';
import '../models/dashbaord_card_model.dart';
import 'shared_preferences_controller.dart';

class CardController extends GetxController {
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();

  Future<DashboardCard> getDashboardCardParams(cardName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final Map<String, String> queryParams = {
      'doctype': 'Number Card',
      'name': cardName,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    // Build URL with query parameters
    final Uri url = Uri.parse(
      '$domain/api/method/frappe.desk.form.load.getdoc',
    ).replace(queryParameters: queryParams);

    final headers = {...session.headers};

    // Make GET request (body is null for GET)
    final res = await http.get(url, headers: headers);
    final data = jsonDecode(res.body);

    DashboardCard cardParams =
        data['docs'] != null
            ? DashboardCard.fromMap(data['docs'][0])
            : DashboardCard.fromMap({});

    return cardParams;
  }

  Future<Map<String, dynamic>> getCardData(DashboardCard cardMeta) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    List filters = jsonDecode(cardMeta.filtersJson);
    Map<String, dynamic> doc = cardMeta.toJson();
    Uri url = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.number_card.number_card.get_result",
    );
    String encodedDoc = Uri.encodeComponent(jsonEncode(doc));
    String encodedFilters = Uri.encodeComponent(jsonEncode(filters));
    final encodedBody = 'doc=$encodedDoc&filters=$encodedFilters';

    final headers = {
      ...session.headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final res = await http.post(url, headers: headers, body: encodedBody);
    final resData = jsonDecode(res.body);

    Map<String, dynamic> cardData;
    if (resData["message"] != null) {
      String value = resData["message"].toString();

      cardData = {'name': doc['name'], 'value': value};
    } else {
      cardData = {};
    }

    return cardData;
  }
}

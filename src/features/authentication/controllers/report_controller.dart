import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:moi_app/src/features/authentication/controllers/form_controller.dart';

import '../../../utils/helper.dart';
import 'shared_preferences_controller.dart';

class ReportController extends GetxController {
  String? domain;
  String company = "";

  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final formController = Get.put(FormController());
  final session = Get.find<Session>();

  var isLoading = true.obs;
  RxMap filters = <String, dynamic>{}.obs;
  RxList selectedItems = [].obs;

  Future<void> loadData(String reportName) async {
    isLoading.value = true;
    List<Map<dynamic, dynamic>>? filtersList = await getFiltersList(reportName);
    if (filtersList != null) {
      for (var filter in filtersList) {
        final fieldname = filter['fieldname']?.toString() ?? '';
        final value = filter['default']?.toString() ?? '';
        filters[fieldname] = value;
      }
    }
    isLoading.value = false;
  }

  Future<Map<String, dynamic>?> getReportData(
    String reportName,
    Map filters,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    final String rawUrl = '$domain/api/method/frappe.desk.query_report.run';

    final Map<String, dynamic> body = {
      "report_name": reportName,
      "filters": jsonEncode(filters),
      "ignore_prepared_report": false.toString(),
      "are_default_filters": true.toString(),
      "_": DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final Uri url = Uri.parse(rawUrl).replace(queryParameters: body);
    final headers = {
      ...session.headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['message'] != null) {
        return jsonData['message'];
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getFiltersList(String reportName) async {
    final prefs = await sharedPreferencesController.prefs;
    domain = prefs.getString("domain");
    final String rawUrl =
        '$domain/api/method/frappe.desk.query_report.get_script';

    final Map<String, String> body = {"report_name": reportName};
    final Uri url = Uri.parse(rawUrl).replace(queryParameters: body);

    final response = await session.post(url, body: body);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['message'] != null) {
        String rawData = jsonData['message']['script'];
        String filtersList = extractAllArrays(rawData);

        filtersList = filtersList.replaceAll(
          "frappe.defaults.get_user_default(\"Company\")",
          "\"$company\"",
        );
        filtersList = filtersList.replaceAll(
          "frappe.defaults.get_default(\"company\")",
          "\"$company\"",
        );

        filtersList = removeGetDataField(filtersList);
        filtersList = removeOnChangeField(filtersList);
        filtersList = removeDefaultField(filtersList);
        int i = 0;
        while (filtersList.contains("get_query")) {
          i += 1;
          filtersList = removeGetQueryField(filtersList);
          if (i > 20) break;
        }
        filtersList = replaceTranslations(filtersList);
        List<Map<String, dynamic>> processedFilters = extractAllJsObjects(
          filtersList,
        );
        List<Map<String, dynamic>> filters = [];
        for (var filter in processedFilters) {
          if (filter['fieldtype'] == "MultiSelectList" &&
              filter['options'] is String) {
            filter['options'] = await formController.searchLink(
              filter['options'],
              "",
            );
          }
          if (filter['fieldtype'] == "Link") {
            filter['options'] = await formController.searchLink(
              filter['options'],
              "",
            );
          }
          filters.add(filter);
        }
        return filters;
      } else {
        return null;
      }
    }
    return null;
  }

  static String extractAllArrays(String text) {
    final startIndex = text.indexOf('filters: [');
    if (startIndex == -1) return '';

    int openBracketIndex = text.indexOf('[', startIndex);
    if (openBracketIndex == -1) return '';

    int count = 1;
    int i = openBracketIndex + 1;

    while (i < text.length && count > 0) {
      if (text[i] == '[') {
        count++;
      } else if (text[i] == ']') {
        count--;
      }
      i++;
    }

    if (count == 0) {
      return text.substring(openBracketIndex + 1, i - 1);
    }
    return '';
  }

  String replaceTranslations(String script) {
    final regex = RegExp(r'__\((.*?".*?")\)');
    return script.replaceAllMapped(regex, (match) {
      final key = match.group(1);
      if (key == null) return '""';

      return key;
    });
  }

  String removeGetDataField(String script) {
    final regex = RegExp(
      r'get_data\s*:\s*function\s*\([^)]*\)\s*\{(?:[^{}]|\{[^{}]*\}|\{[^{}]*\{[^{}]*\}[^{}]*\}|\{[^{}]*\{[^{}]*\{[^{}]*\}[^{}]*\}[^{}]*\})*\},',
    );
    return script.replaceAllMapped(regex, (match) {
      final key = match.group(0);
      if (key == null) return '""';

      return "";
    });
  }

  String removeOnChangeField(String script) {
    final regex = RegExp(
      r'on_change\s*(?:(?:\:\s*(?:\([^)]*\)\s*=>\s*\{(?:[^{}]*|\{[^{}]*\})*\}|function\s*\([^)]*\)\s*\{(?:[^{}]*|\{[^{}]*\})*\}))|\([^)]*\)\s*\{(?:[^{}]*|\{[^{}]*\})*\}),',
    );
    return script.replaceAllMapped(regex, (match) {
      final key = match.group(0);
      if (key == null) return '""';

      return "";
    });
  }

  String removeGetQueryField(String script) {
    final String target = 'get_query:';
    int startIndex = script.indexOf(target);

    if (startIndex == -1) return script;

    int contentStart = startIndex + target.length;

    int i = contentStart;
    int depth = 0;
    bool insideValue = false;

    while (i < script.length) {
      if (!insideValue) {
        if (script[i] == '{' || script[i] == '(' || script[i] == 'f') {
          insideValue = true;
        } else if (script[i] == ',' || script[i] == '}') {
          break;
        }
      }

      if (insideValue) {
        if (script[i] == '{') {
          depth++;
        } else if (script[i] == '}') {
          depth--;
          if (depth == 0) break;
        } else if (script[i] == '(') {
          depth++;
        } else if (script[i] == ')') {
          depth--;
        }
      }

      i++;
    }

    if (depth == 0 || !insideValue) {
      int end = i;
      String matchedString = script.substring(startIndex, end + 1);
      script = script.replaceAll(matchedString, "");
      return script;
    }

    return script;
  }

  String removeDefaultField(String script) {
    // remove default field that starts with frappe.
    final regex = RegExp(
      r'default:\s*((?:frappe|erpnext)\.(?:[^\(\),\}]+|\((?:[^\(\)]*|\([^\(\)]*\))*\))+),',
    );
    return script.replaceAllMapped(regex, (match) {
      final key = match.group(0);
      if (key == null) return '""';

      return "";
    });
  }

  String? extractOuterJsObject(String input, int startIndex) {
    if (input[startIndex] != '{') return null;

    int depth = 0;
    final end = input.length;

    for (int i = startIndex; i < end; i++) {
      final char = input[i];

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return input.substring(startIndex, i + 1);
        }
      }
    }

    return null; // No matching closing found
  }

  List<Map<String, dynamic>> extractAllJsObjects(String input) {
    List<Map<String, dynamic>> objects = [];
    int i = 0;

    while (i < input.length) {
      if (input[i] == '{') {
        String? obj = extractOuterJsObject(input, i);
        if (obj != null) {
          try {
            objects.add(parseLooseJsonToMap(obj));
            i += obj.length; // Move past the matched object
          } catch (e) {
            i++;
          }
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    return objects;
  }

  Map<String, dynamic> parseLooseJsonToMap(String input) {
    // Step 1: Quote the keys
    String fixed = input.replaceAllMapped(
      RegExp(r'(?<=\{|,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
      (m) => '"${m.group(1)}":',
    );

    try {
      final result = jsonDecode(
        fixJsonWithDateQuoting(removeTrailingCommas(fixed)),
      );
      if (result is Map<String, dynamic>) {
        return result;
      } else {
        throw FormatException("Not a JSON Map");
      }
    } catch (e) {
      throw FormatException("Failed to parse JSON: $e\nFixed JSON:\n$fixed");
    }
  }

  String removeTrailingCommas(String json) {
    // Remove any comma followed by optional whitespace and a closing } or ]
    final cleaned = json.replaceAllMapped(
      RegExp(r',\s*(\}|\])'),
      (match) => match.group(1)!,
    );
    return cleaned;
  }

  String fixJsonWithDateQuoting(String input) {
    // Step 1: Remove trailing commas before } or ]
    input = input.replaceAllMapped(RegExp(r',\s*(\}|\])'), (m) => m.group(1)!);

    // Step 2: Quote unquoted date-like values
    // Matches key: value where value looks like a date and is not quoted
    input = input.replaceAllMapped(
      RegExp(
        r'("?\w+"?\s*:\s*)(\d{4}[-/.]\d{2}[-/.]\d{2}|\d{2}[-/.]\d{2}[-/.]\d{4})(?=\s*[,}\]])',
      ),
      (m) => '${m.group(1)}"${m.group(2)}"',
    );

    return input;
  }
}

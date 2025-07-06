import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import '../features/authentication/controllers/shared_preferences_controller.dart';
import '../features/authentication/models/form_field_model.dart';
import '../features/authentication/screens/home/chart_builder.dart';

class Session {
  Map<String, String> headers = {};

  void setHeader(Map<String, String> headers) {
    this.headers = headers;
  }

  Future<http.Response> get(Uri url) async {
    final response = await http.get(url, headers: headers);
    _updateCookies(response.headers);
    return response;
  }

  Future<http.Response> post(Uri url, {Map<String, String>? body}) async {
    http.Response response = await http.post(url, headers: headers, body: body);
    _updateCookies(response.headers);
    return response;
  }

  void _updateCookies(Map<String, String> responseHeaders) {
    final setCookieHeader = responseHeaders['set-cookie'];
    if (setCookieHeader != null) {
      final cookies = _parseCookies(setCookieHeader);
      headers['Cookie'] = cookies.join('; ');
    }
  }

  List<String> _parseCookies(String setCookieHeader) {
    final cookies = <String>[];
    final cookieParts = setCookieHeader.split(',');
    for (final part in cookieParts) {
      final keyValue = part.split(';').first.trim();
      if (keyValue.isNotEmpty) {
        cookies.add(keyValue);
      }
    }
    return cookies;
  }
}

Future<Map<String, dynamic>?> getDesktopPage(String domain, String app) async {
  Session session = Get.find<Session>();
  final sharedPreferencesController = Get.put(SharedPreferencesController());

  final prefs = await sharedPreferencesController.prefs;

  final homeUrl = Uri.parse("$domain/app/$app");
  final homeResponse = await session.get(homeUrl);
  final homeHtmlContent = homeResponse.body;

  final frappeBootData = _extractFrappeBoot(homeHtmlContent);
  if (frappeBootData == null) {
    print("Failed to extract frappe.boot data.");
    return null;
  }

  List allowedWorkspaces = frappeBootData['allowed_workspaces'];
  Map<String, dynamic> sysDefaults = frappeBootData['sysdefaults'];
  String company = sysDefaults['company'];
  prefs.setString('company', company);
  List allowedWorkspace =
      allowedWorkspaces.where((map) {
        return map['title'] == app;
      }).toList();
  final workspaceData = jsonEncode(allowedWorkspace.first);
  final postData = {'page': workspaceData};

  // Fetch desktop page
  final desktopPageUrl = Uri.parse(
    "$domain/api/method/frappe.desk.desktop.get_desktop_page",
  );
  final desktopPageResponse = await session.post(
    desktopPageUrl,
    body: postData,
  );

  return jsonDecode(desktopPageResponse.body);
}

String? extractCsrfToken(String htmlContent) {
  final document = parser.parse(htmlContent);
  final scriptTags = document.getElementsByTagName('script');
  for (final script in scriptTags) {
    final scriptContent = script.text;
    if (scriptContent.contains('frappe.csrf_token')) {
      final match = RegExp(
        r'frappe\.csrf_token\s*=\s*"([^"]+)"',
      ).firstMatch(scriptContent);
      if (match != null) {
        return match.group(1);
      }
    }
  }
  return null;
}

Map<String, dynamic>? _extractFrappeBoot(String htmlContent) {
  final document = parser.parse(htmlContent);
  final scriptTags = document.getElementsByTagName('script');
  for (final script in scriptTags) {
    final scriptContent = script.text;
    if (scriptContent.contains('frappe.boot')) {
      final match = RegExp(
        r'frappe\.boot\s*=\s*({.*?});',
        dotAll: true,
      ).firstMatch(scriptContent);
      if (match != null) {
        try {
          return jsonDecode(match.group(1)!);
        } catch (e) {
          print("Failed to parse frappe.boot JSON: $e");
        }
      }
    }
  }
  return null;
}

// Helper function to parse the date string into a DateTime object
DateTime? parseCustomDate(String dateString) {
  try {
    // Split the date string into parts
    List<String> parts = dateString.split(' ');
    if (parts.length < 5) {
      throw FormatException("Invalid date format");
    }

    // Extract day, month, year, hour, minute, second
    int day = int.parse(parts[0]);
    String monthStr = parts[1];
    int year = int.parse(parts[2]);
    List<String> timeParts = parts[3].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    int second = int.parse(timeParts[2]);

    // Map month name to month number
    Map<String, int> monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    if (!monthMap.containsKey(monthStr)) {
      throw FormatException("Invalid month: $monthStr");
    }
    int month = monthMap[monthStr]!;

    // Create a DateTime object
    return DateTime.utc(year, month, day, hour, minute, second);
  } catch (e) {
    print("Error parsing date: $e");
    return null;
  }
}

/// Zips a list of lists into a list of lists where each sublist contains
/// the i-th elements from each input list (stops at the shortest list).
List<List<dynamic>> zip(List<List<dynamic>> lists) {
  if (lists.isEmpty) return [];

  // Get the minimum length among all lists
  int minLength = lists
      .map((list) => list.length)
      .reduce((a, b) => a < b ? a : b); // ✅ Correct way to find minimum

  List<List<dynamic>> result = [];

  for (int i = 0; i < minLength; i++) {
    List<dynamic> row = [];
    for (List<dynamic> list in lists) {
      row.add(list[i]);
    }
    result.add(row);
  }

  return result;
}

void showAutoDismissDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      Future.delayed(Duration(seconds: 7), () {
        Navigator.of(context).pop(); // Close dialog
      });
      return AlertDialog(
        title: Text("Notice"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Close"),
          ),
        ],
      );
    },
  );
}

Map<String, dynamic> getElementsAfterKey(
  Map<String, dynamic> map,
  String targetKey,
) {
  // Convert keys to list to access by index
  final List<String> keys = map.keys.toList();

  // Find the index of the target key
  final int keyIndex = keys.indexOf(targetKey);

  // If key not found or it's the last key, return empty map
  if (keyIndex == -1 || keyIndex == keys.length - 1) {
    return {};
  }

  // Get the keys that come after the target key
  final List<String> keysAfterTarget = keys.sublist(keyIndex + 1);

  // Build the resulting map
  final Map<String, dynamic> result = {};
  for (final String key in keysAfterTarget) {
    result[key] = map[key];
  }

  return result;
}

String encodeFormFieldsMap(Map<String, List<FormFieldData>> map) {
  final encodedMap = map.map((key, value) {
    final encodedList = value.map((field) => field.toJson()).toList();
    return MapEntry(key, encodedList);
  });

  return jsonEncode(encodedMap);
}

Map<String, List<FormFieldData>> decodeFormFieldsMap(String jsonString) {
  final parsedMap = jsonDecode(jsonString) as Map<String, dynamic>;

  return parsedMap.map((key, value) {
    if (value is! List) {
      throw FormatException(
        "Expected List for key '$key', got ${value.runtimeType}",
      );
    }

    final List<dynamic> list = value;
    final fields =
        list.map((item) {
          if (item is! Map<String, dynamic>) {
            throw FormatException(
              "Expected Map<String, dynamic>, got ${item.runtimeType}",
            );
          }
          if (item['data'] != null) {
            return FormFieldData.fromJson(item);
          }
          return FormFieldData.fromJson(item);
        }).toList();

    return MapEntry(key, fields);
  });
}

Map<String, String> getInitialRow(List<FormFieldData> tableFields) {
  final Map<String, String> row = {};
  for (var field in tableFields) {
    row[field.fieldName] = "";
  }
  return row;
}

Map<String, dynamic> editTableRow(
  String tableFieldName,
  tableRowValues,
  rowIndex,
  colIndex,
  text,
) {
  // Get the full row (a map, e.g., { "tableFieldName1": "tabeFieldValue1", "tableFieldName2": "tabeFieldValue2", })
  var row = tableRowValues[tableFieldName][rowIndex];

  // Convert row to mutable map if it's immutable
  var mutableRow = Map<String, dynamic>.from(row);

  // Get all keys in order to find the correct column
  var keys = row.keys.toList(); // ["tableFieldName1", "tableFieldName2"]
  var keyToUpdate = keys[colIndex]; // e.g., "tableFieldName1"

  // Update value
  mutableRow[keyToUpdate] = text;

  // Replace the old row with updated one
  tableRowValues[tableFieldName]![rowIndex] = mutableRow;
  return mutableRow;
}

bool toBool(String? value) {
  if (value == null) return false;

  final lower = value.trim().toLowerCase();
  return ['true', '1', 'yes', 'on'].contains(lower);
}

int toIntBool(bool? value) {
  if (value == null) return 0;
  return value ? 1 : 0;
}

List removeTableMetadata(List data) {
  List<String> keysToRemove = [
    'name',
    'owner',
    'creation',
    'modified',
    'modified_by',
    'docstatus',
    'idx',
    'parent',
    'parentfield',
    'parenttype',
    'doctype',
  ];

  List editedData =
      data.map((row) {
        if (row is Map) {
          final Map copy = Map.from(row);
          copy.removeWhere((key, value) => keysToRemove.contains(key));
          return copy;
        }
        return row;
      }).toList();

  return editedData;
}

final Map<String, IconData> erpnextToFlutterIcons = {
  'py': Icons.insert_drive_file,
  'light-bulb': Icons.lightbulb_outline,
  'flame': Icons.whatshot,
  'repo-template': Icons.copy,
  'repo-deleted': Icons.delete_forever,
  'arrow-right': Icons.arrow_forward,
  '-entry-fill': Icons.edit,
  'filter': Icons.filter_list,
  'project-symlink': Icons.link,
  'pivot-column': Icons.table_chart,
  'kebab-horizontal': Icons.more_horiz,
  'search': Icons.search,
  'check-circle': Icons.check_circle_outline,
  'location': Icons.location_on,
  'heart': Icons.favorite_border,
  'discussion-duplicate': Icons.content_copy,
  'package-dependencies': Icons.schema,
  'git-merge': Icons.merge_type,
  'arrow-up': Icons.arrow_upward,
  'diff-removed': Icons.remove_circle_outline,
  'sparkle-fill': Icons.auto_awesome,
  'package-dependents': Icons.list_alt,
  'diff-renamed': Icons.drive_file_rename_outline,
  'lock': Icons.lock_outline,
  'beaker': Icons.science_outlined,
  'feed-pull-request-closed': Icons.block,
  'fiscal-host': Icons.account_balance_wallet,
  'check': Icons.check_box_outline_blank,
  'checklist': Icons.playlist_add_check,
  'bookmark-slash-fill': Icons.bookmark_remove,
  'file-moved': Icons.file_present,
  'tab': Icons.tab,
  'rel-file-path': Icons.folder_open,
  'unmute': Icons.volume_up,
  'heading': Icons.text_fields,
  'feed-repo': Icons.source,
  'feed-person': Icons.person_outline,
  'git-merge-queue': Icons.queue,
  'discussion-outdated': Icons.warning_amber_rounded,
  'cross-reference': Icons.link,
  'ue-tracks': Icons.playlist_play,
  'trashed': Icons.delete_sweep,
  'strikethrough': Icons.format_strikethrough,
  'bookmark': Icons.bookmark_outline,
  'smiley': Icons.sentiment_satisfied_alt,
  'chevron-up': Icons.keyboard_arrow_up,
  'play': Icons.play_arrow,
  'git-commit': Icons.commit,
  'hourglass': Icons.hourglass_empty,
  'verified': Icons.verified_user,
  'list-unordered': Icons.format_list_bulleted,
  'diff-added': Icons.add_circle_outline,
  'diamond': Icons.diamond_outlined,
  'quote': Icons.format_quote,
  'trash': Icons.delete_outline,
  'grabber': Icons.drag_handle,
  'milestone': Icons.flag,
  'move-to-end': Icons.last_page,
  'history': Icons.history,
  'fold': Icons.unfold_less,
  'feed-discussion': Icons.chat_bubble_outline,
  'reply': Icons.reply,
  'accessibility-inset': Icons.accessibility_new,
  'bell': Icons.notifications_outlined,
  'fold-down': Icons.expand_more,
  'ruby': Icons.settings,
  'lock-fill': Icons.lock,
  'bell-slash': Icons.notifications_off,
  'undo': Icons.undo,
  'graph': Icons.show_chart,
  'home': Icons.home,
  'sync': Icons.sync,
  'number': Icons.looks_one,
  'rocket': Icons.rocket_launch,
  'hubot': Icons.android,
  'megaphone': Icons.campaign,
  'paperclip': Icons.attach_file,
  'file-zip': Icons.archive,
  'mute': Icons.volume_off,
  'report': Icons.report,
  'shield-check': Icons.shield,
  'de': Icons.code,
  'arrow-switch': Icons.swap_horiz,
  'broadcast': Icons.radio,
  'key': Icons.key,
  'git-compare': Icons.compare_arrows,
  'package': Icons.inventory,
  'project-roadmap': Icons.map,
  'project': Icons.work_outline,
  'arrow-up-right': Icons.open_in_new,
  'command-palette': Icons.dashboard_customize,
  'share': Icons.share,
  'file-directory-symlink': Icons.folder_special,
  'north-star': Icons.star_half,
  'heart-fill': Icons.favorite,
  'database': Icons.storage,
  'mention': Icons.alternate_email,
  'skip-fill': Icons.skip_next,
  'gn-out': Icons.logout,
  'arrow-down': Icons.arrow_downward,
  'zap': Icons.flash_on,
  'calendar': Icons.calendar_today,
  'organization': Icons.people,
  'shield-lock': Icons.security,
  'filter-remove': Icons.filter_none,
  'bookmark-fill': Icons.bookmark,
  'meter': Icons.speed,
  'trophy': Icons.emoji_events,
  'feed-issue-open': Icons.bug_report,
  'mail': Icons.email,
  'people': Icons.people,
  'sponsor-tiers': Icons.workspace_premium,
  'alert-fill': Icons.error,
  'markdown': Icons.text_format,
  'blocked': Icons.block,
  'rt-desc': Icons.sort_by_alpha,
  'pause': Icons.pause,
  'unverified': Icons.cancel,
  'pencil': Icons.edit,
  'upload': Icons.upload,
  'terminal': Icons.terminal,
  'container': Icons.layers,
  'person': Icons.person,
  'thumbsup': Icons.thumb_up,
  'hash': Icons.tag,
  'law': Icons.gavel,
  'repo': Icons.folder_shared,
  'link-external': Icons.open_in_new,
  'pin': Icons.push_pin,
  'unlock': Icons.lock_open,
  'unread': Icons.mark_email_unread,
  'diff-modified': Icons.change_circle,
  'shield': Icons.shield,
  'desktop-download': Icons.download,
  'log': Icons.receipt,
  'redo': Icons.refresh,
  'plus-circle': Icons.add_circle_outline,
  'browser': Icons.public,
  'arrow-left': Icons.arrow_back,
  'descan': Icons.qr_code_scanner,
  'repo-pull': Icons.download,
  'repo-forked': Icons.fork_right,
  'hare-android': Icons.share,
  'credit-card': Icons.credit_card,
  'read': Icons.visibility,
  'server': Icons.desktop_windows,
  'infinity': Icons.change_history,
  'repo-locked': Icons.lock,
  'file-directory': Icons.folder,
  'shield-slash': Icons.block,
  'rows': Icons.view_list,
  'sign-in': Icons.login,
  'square-fill': Icons.crop_square,
  'tag': Icons.sell,
  'file-diff': Icons.compare_arrows,
  'paste': Icons.content_paste,
  'x': Icons.clear,
  'bell-fill': Icons.notifications_active,
  'skip': Icons.skip_next,
  'file-code': Icons.code,
  'triangle-down': Icons.arrow_drop_down,
  'typography': Icons.text_fields,
  'question': Icons.help_outline,
  'video': Icons.videocam,
  'back': Icons.arrow_back_ios,
  'ls': Icons.folder_open,
  'key-asterisk': Icons.key,
  'moon': Icons.dark_mode,
  'apps': Icons.apps,
  'square': Icons.crop_square,
  'dash': Icons.horizontal_rule,
  'support': Icons.support,
  'integration': Icons.sync,
  'table_2': Icons.table_chart,
  'star': Icons.star,
  'income': Icons.attach_money,
  'sell': Icons.sell,
  'accounting': Icons.account_balance,
  'setting': Icons.settings,
  'users': Icons.people,
  'non-profit': Icons.volunteer_activism,
  'quality': Icons.check_circle_outline,
  'stock': Icons.store,
  'buying': Icons.shopping_cart,
  'getting-started': Icons.start,
  'file': Icons.insert_drive_file,
  'list': Icons.list_alt,
  'hr': Icons.person,
  'assets': Icons.devices,
  'website': Icons.language,
  'quality-3': Icons.verified_user,
  'assign': Icons.assignment_turned_in,
  'money-coins-1': Icons.money,
  'crm': Icons.contacts,
  'expenses': Icons.receipt,
  'tool': Icons.build,
};

String makeFirstLetterSmall(String input) {
  if (input.isEmpty) return input;
  return input[0].toLowerCase() + input.substring(1);
}

String buildQueryString(Map<String, dynamic> params) {
  final List<String> pairs = [];

  void addPair(String key, dynamic value) {
    if (value == null) return;

    String encodedValue;
    if (value is List || value is Map) {
      // Convert List/Map to JSON string then URL encode
      encodedValue = Uri.encodeComponent(jsonEncode(value));
    } else {
      encodedValue = Uri.encodeComponent(value.toString());
    }

    pairs.add('${Uri.encodeComponent(key)}=$encodedValue');
  }

  params.forEach(addPair);

  return pairs.join('&');
}

String formatLargeNumber(double number) {
  if (number >= 1000) {
    int inK = (number / 1000).toInt();
    return '$inK K';
  } else if (number >= 1000000) {
    int inK = (number / 1000000).toInt();
    return '$inK M';
  } else {
    if (number <= 1) {
      return number.toString();
    } else {
      return number.toStringAsFixed(0);
    }
  }
}

num getProperYAxisInterval(num maxValue) {
  if (maxValue >= 5000) return 1000;
  if (maxValue >= 2000) return 500;
  if (maxValue >= 500) return 100;
  if (maxValue >= 200) return 50;
  if (maxValue >= 100) return 25;
  if (maxValue >= 50) return 10;
  if (maxValue >= 20) return 5;
  if (maxValue >= 10) return 2;
  if (maxValue >= 5) return 1;
  return maxValue <= 1 ? 0.5 : 1;
}

Color hexToColor(String hexString) {
  // Remove the '#' character if present
  String cleanedHexString = hexString.replaceAll('#', '');

  // Ensure the string has exactly 6 characters (RGB)
  assert(cleanedHexString.length == 6, "Hex string must be 6 characters long");

  // Convert to integer and create Color object
  int hexValue = int.parse(cleanedHexString, radix: 16);
  return Color(0xFF000000 | hexValue); // 0xFF for full opacity
}

String? getSource(String input, String chartName) {
  RegExp regExp = RegExp(r'method:\s*"([^"]+)"');
  Match? match = regExp.firstMatch(input);

  if (match != null) {
    String methodValue = match.group(1)!;
    return methodValue;
  } else {
    print("Method not found.");
    return null;
  }
}

String removeHtmlTags(String htmlString) {
  final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlString.replaceAll(exp, '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

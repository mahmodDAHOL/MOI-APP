import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

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
    final response = await http.post(url, headers: headers, body: body);
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

Future<Map<String, dynamic>?> getDesktopPage(String domain) async {
  Session session = Get.find<Session>();

  try {
    final homeUrl = Uri.parse("$domain/app/home");
    final homeResponse = await session.get(homeUrl);
    final homeHtmlContent = homeResponse.body;

    final frappeBootData = _extractFrappeBoot(homeHtmlContent);
    if (frappeBootData == null) {
      print("Failed to extract frappe.boot data.");
      return null;
    }

    final allowedWorkspaces = frappeBootData['allowed_workspaces'][0];
    final workspaceData = jsonEncode(allowedWorkspaces);
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
  } catch (e) {
    print("An error occurred: $e");
    return null;
  }
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
      Future.delayed(Duration(seconds: 3), () {
        Navigator.of(context).pop(); // Close dialog
      });
      return AlertDialog(
        title: Text("Notice"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Close"),
          )
        ],
      );
    },
  );
}

Map<String, dynamic> getElementsAfterKey(
    Map<String, dynamic> map, String targetKey) {
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
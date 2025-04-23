import 'dart:convert';

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

Future<bool> login(
  Session session,
  String domain,
  String username,
  String password,
) async {
  final loginUrl = Uri.parse("$domain/api/method/login");
  final loginResponse = await session.post(
    loginUrl,
    body: {"usr": username, "pwd": password},
  );

  if (loginResponse.statusCode == 200) {
    print("Login successful.");
    return true;
  } else {
    print("Login failed with status code: ${loginResponse.statusCode}");
    return false;
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

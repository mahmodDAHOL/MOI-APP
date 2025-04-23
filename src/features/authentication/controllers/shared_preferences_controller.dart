import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesController extends GetxController {
  // Return a Future<SharedPreferences>
  Future<SharedPreferences> get prefs async {
    return await SharedPreferences.getInstance();
  }
}
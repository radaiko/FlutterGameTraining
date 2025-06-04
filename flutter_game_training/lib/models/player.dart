import 'package:shared_preferences/shared_preferences.dart';

class Player {
  static int get level => _level;
  static int _level = 0;

  static void levelUp() {
    _level++;
    _saveLevel();
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    int savedLevel = prefs.getInt('player_level') ?? 0;
    _level = savedLevel;
  }

  static Future<void> _saveLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_level', _level);
  }
}

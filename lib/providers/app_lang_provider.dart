import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageProvider extends ChangeNotifier {
  String? _languageCode;
  bool _isLoading = true;
  static const String _localeKey = 'locale';

  bool get isLoading => _isLoading;
  String? get languageCode => _languageCode;

  Locale? get locale => (_languageCode == null) ? null : Locale(_languageCode!);

  AppLanguageProvider() {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_localeKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }
}

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LocaleProvider extends ChangeNotifier {
//   Locale? _locale;
//   static const String _localeKey = 'locale';

//   Locale? get locale => _locale;

//   LocaleProvider() {
//     loadLocale(); // در زمان ساخت، زبان ذخیره شده را بارگذاری کن
//   }

//   // بارگذاری زبان از حافظه
//   Future<void> loadLocale() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? languageCode = prefs.getString(_localeKey);

//     if (languageCode != null) {
//       _locale = Locale(languageCode);
//       notifyListeners();
//     }
//   }

//   // تنظیم و ذخیره زبان جدید
//   Future<void> setLocale(Locale locale) async {
//     _locale = locale;
//     notifyListeners(); // به ویجت‌ها اطلاع بده که دوباره رندر شوند

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_localeKey, locale.languageCode); // ذخیره در حافظه
//   }
// }

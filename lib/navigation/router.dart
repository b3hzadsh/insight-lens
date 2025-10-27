import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:test_app/pages/set_language.dart';
import 'package:test_app/pages/splash.dart' show SplashScreen;
import 'package:test_app/providers/app_lang_provider.dart';
import 'package:test_app/widgets/home_wrapper_loader.dart';

class AppRouter {
  final AppLanguageProvider languageProvider;

  AppRouter(this.languageProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: languageProvider,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return SplashScreen();
        },
      ),
      GoRoute(
        path: '/predict',
        builder: (BuildContext context, GoRouterState state) {
          return HomeWrapperLoader();
        },
      ),
      GoRoute(
        path: '/settings/language',
        builder: (BuildContext context, GoRouterState state) {
          return SetLocalePage();
        },
      ),
    ],

    // --- بخش اصلاح شده ---
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = languageProvider.isLoading;
      final langCode = languageProvider.languageCode;

      // 'requestedLocation' مکانی است که کاربر *قصد دارد* به آن برود
      final requestedLocation = state.matchedLocation;

      // حالت ۱: در حال بارگذاری از حافظه
      if (isLoading) {
        // در صفحه اسپلش بمان
        return (requestedLocation == '/') ? null : '/';
      }

      // حالت ۲: بارگذاری تمام شده، زبان انتخاب نشده (بار اول)
      if (!isLoading && langCode == null) {
        // کاربر را به صفحه تنظیمات زبان بفرست
        return (requestedLocation == '/settings/language')
            ? null
            : '/settings/language';
      }

      // حالت ۳: بارگذاری تمام شده، زبان قبلاً انتخاب شده (دفعات بعد)
      if (!isLoading && langCode != null) {
        // ✅ اینجا اصلاح شد:
        // فقط اگر کاربر در صفحه اسپلش (/) است،
        // او را به صفحه پیش‌بینی (predict) هدایت کن.
        if (requestedLocation == '/') {
          return '/predict';
        }

        // در هر حالت دیگری (مثلاً اگر کاربر صراحتاً
        // روی دکمه کلیک کرده تا به /settings/language برود)،
        // اجازه بده ناوبری انجام شود و ریدایرکت نکن.
      }

      // در غیر این صورت، هیچ ریدایرکتی لازم نیست
      return null;
    },
    // --- پایان بخش اصلاح شده ---
  );
}

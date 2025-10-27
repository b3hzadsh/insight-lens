// router.dart
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
    // ۱. به پروایدر گوش کن
    refreshListenable: languageProvider,

    // ۲. مسیر اولیه *همیشه* اسپلش است
    initialLocation: '/',

    routes: [
      // ۳. مسیر صفحه اسپلش را اضافه کن
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

    // ۴. منطق اصلی هدایت (Redirect)
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = languageProvider.isLoading;
      final langCode = languageProvider.languageCode;
      final currentLocation = state.matchedLocation;

      // حالت ۱: در حال بارگذاری از حافظه
      // کاربر باید در صفحه اسپلش بماند
      if (isLoading) {
        return (currentLocation == '/') ? null : '/';
      }

      // حالت ۲: بارگذاری تمام شده، زبان انتخاب نشده (بار اول)
      // کاربر باید به صفحه تنظیمات زبان برود
      if (!isLoading && langCode == null) {
        return (currentLocation == '/settings/language')
            ? null
            : '/settings/language';
      }

      // حالت ۳: بارگذاری تمام شده، زبان قبلاً انتخاب شده
      // کاربر باید به صفحه پیش‌بینی برود
      if (!isLoading && langCode != null) {
        // اگر کاربر در صفحه اسپلش یا تنظیمات است، او را به predict ببر
        if (currentLocation == '/' || currentLocation == '/settings/language') {
          return '/predict';
        }
      }

      // در غیر این صورت (مثلاً کاربر خودش دستی در /predict است)، کاری نکن
      return null;
    },
  );
}

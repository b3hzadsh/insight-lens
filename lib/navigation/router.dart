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

    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = languageProvider.isLoading;
      final langCode = languageProvider.languageCode;
      final requestedLocation = state.matchedLocation;

      if (isLoading) {
        return (requestedLocation == '/') ? null : '/';
      }
      if (!isLoading && langCode == null) {
        return (requestedLocation == '/settings/language')
            ? null
            : '/settings/language';
      }
      if (!isLoading && langCode != null) {
        if (requestedLocation == '/') {
          return '/predict';
        }
      }
      return null;
    },
  );
}

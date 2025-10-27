import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:test_app/providers/app_lang_provider.dart'
    show AppLanguageProvider;

class SetLocalePage extends StatelessWidget {
  const SetLocalePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<AppLanguageProvider>(
      context,
      listen: false,
    );
    return Scaffold(
      appBar: AppBar(title: Text('Set Language')),
      body: Center(
        child: Column(
          children: [
            Text('Language setting page content goes here.'),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    localeProvider.setLanguage('fa');
                    context.go('/predict');
                  },
                  child: Text('Persian'),
                ),
                ElevatedButton(
                  onPressed: () {
                    localeProvider.setLanguage('en');
                    context.go('/predict');
                  },
                  child: Text('English'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

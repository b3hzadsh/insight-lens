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

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Select Language')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome!',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please select your language to continue.',
              style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                localeProvider.setLanguage('fa');
                context.go('/predict');
              },
              child: Text('فارسی (Persian)'),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                localeProvider.setLanguage('en');
                context.go('/predict');
              },
              child: Text('English'),
            ),
          ],
        ),
      ),
    );
  }
}

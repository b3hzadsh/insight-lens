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

    // از تم برنامه برای استایل‌دهی استفاده می‌کنیم
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Language',
        ), // "Set" کمی دستوری است، "Select" بهتر است
      ),
      // ۱. از Padding برای فاصله از لبه‌های صفحه استفاده می‌کنیم
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          // ۲. محتوا را در مرکز صفحه (عمودی) قرار می‌دهیم
          mainAxisAlignment: MainAxisAlignment.center,
          // ۳. دکمه‌ها را تمام‌عرض می‌کنیم
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ۴. یک متن راهنمای واضح‌تر
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
            // ۵. فاصله زیاد تا دکمه‌ها
            SizedBox(height: 48),

            // ۶. دکمه فارسی با استایل بهتر
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // ۷. دکمه را بلندتر و خواناتر می‌کنیم
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // منطق شما دست نخورده است
                localeProvider.setLanguage('fa');
                context.go('/predict');
              },
              // ۸. متن واضح‌تر برای دکمه
              child: Text('فارسی (Persian)'),
            ),

            // ۹. فاصله بین دو دکمه
            SizedBox(height: 16),

            // ۱۰. دکمه انگلیسی
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // منطق شما دست نخورده است
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

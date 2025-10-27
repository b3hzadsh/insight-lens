import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show context;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:test_app/l10n/app_localizations.dart';
import 'package:test_app/providers/ame.dart';
import 'package:test_app/navigation/router.dart' show router;
import 'package:test_app/navigation/router.dart';
import 'package:test_app/providers/app_lang_provider.dart'
    show AppLanguageProvider;
import 'package:test_app/widgets/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Camera permission required')),
          ),
        ),
      );
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      runApp(
        MaterialApp(
          home: Scaffold(body: Center(child: Text('No camera found'))),
        ),
      );
      return;
    }

    final firstCamera = cameras.first;
    runApp(
      ChangeNotifierProvider(
        create: (context) => AppLanguageProvider(),
        child: MyApp(firstCamera: firstCamera),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.firstCamera});
  final CameraDescription firstCamera;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<AppLanguageProvider>(context);
    final appRouter = AppRouter(languageProvider);

    return Consumer<AppLanguageProvider>(
      builder: (context, provider, child) {
        return MaterialApp.router(
          routerConfig: appRouter.router,
          locale: provider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Color(0xFFFF00FF),
          ),
        );
      },
    );
  }
}

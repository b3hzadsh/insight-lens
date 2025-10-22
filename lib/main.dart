import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_app/widgets/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      print('❌ Camera permission denied');
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
      print('❌ No cameras available');
      runApp(
        MaterialApp(
          home: Scaffold(body: Center(child: Text('No camera found'))),
        ),
      );
      return;
    }

    final firstCamera = cameras.first;
    print('✅ Camera loaded: ${firstCamera.name}');
    runApp(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFFFF00FF),
        ),
        home: Home(camera: firstCamera),
      ),
    );
  } catch (e) {
    print('❌ Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

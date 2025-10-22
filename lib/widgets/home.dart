import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:test_app/recognition_isolate.dart';
import 'package:test_app/services/camera-service.dart';
import 'package:test_app/services/tensorflow-service.dart';
import 'package:test_app/widgets/camera-header.dart';
import 'package:test_app/widgets/camera-screen.dart';
import 'package:test_app/widgets/recognition.dart';

class Home extends StatefulWidget {
  final CameraDescription camera;
  const Home({Key? key, required this.camera}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final TensorflowService _tensorflowService = TensorflowService();
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (_isInitialized) return;
    try {
      print('--- Starting One-Time Initialization ---');
      await _cameraService
          .startService(widget.camera)
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Camera initialization timed out');
            },
          );
      await _tensorflowService.start().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('TensorflowService initialization timed out');
        },
      );
      await _cameraService.startStreaming().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Camera streaming timed out');
        },
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      print('--- One-Time Initialization Complete ---');
    } catch (e) {
      print('❌ Error initializing services: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error initializing: $e')));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print('App Resumed: Starting camera stream.');
        if (_isInitialized) {
          _cameraService.startStreaming();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        print('App Paused/Inactive: Stopping camera stream.');
        _cameraService.stopImageStream();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.stopImageStream();
    _cameraService.dispose();
    _tensorflowService.stop();
    print('✅ Home disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraScreen(controller: _cameraService.cameraController),
          CameraHeader(),
          StreamBuilder<List<Recognition>>(
            stream: _tensorflowService.recognitionStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    color: Colors.black54,
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                );
              }
              return RecognitionWidget(results: snapshot.data ?? []);
            },
          ),
        ],
      ),
    );
  }
}

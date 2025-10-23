import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:test_app/recognition_isolate.dart';
import 'package:test_app/services/camera_service.dart';
import 'package:test_app/services/tensorflow_service.dart';
import 'package:test_app/widgets/camera_header.dart';
import 'package:test_app/widgets/camera_screen.dart';
import 'package:test_app/widgets/recognition.dart';

class Home extends StatefulWidget {
  final CameraDescription camera;
  const Home({super.key, required this.camera});

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
    Future.delayed(Duration.zero, () {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    if (_isInitialized) return;
    try {
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
    } catch (e) {
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
        if (_isInitialized) {
          _cameraService.startStreaming();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: CameraScreen(controller: _cameraService.cameraController),
          ),
          Positioned(top: 0, left: 0, right: 0, child: CameraHeader()),
          StreamBuilder<List<Recognition>>(
            stream: _tensorflowService.recognitionStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
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

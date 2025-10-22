import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_app/services/tensorflow-service.dart';

class CameraService {
  static final CameraService _cameraService = CameraService._internal();
  factory CameraService() => _cameraService;
  CameraService._internal();

  final TensorflowService _tensorflowService = TensorflowService();
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  bool _isPredicting = false;
  int _frameCounter = 0;

  Future<void> startService(CameraDescription cameraDescription) async {
    try {
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        print('❌ Camera permission denied');
        throw Exception('Camera permission required');
      }

      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      print('✅ Camera initialized successfully');
    } catch (e) {
      print('❌ Error initializing camera: $e');
      _cameraController = null;
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<void> startStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('❌ CameraController not initialized');
      return;
    }
    if (_cameraController!.value.isStreamingImages) {
      print('Already streaming');
      return;
    }
    if (!_tensorflowService.isReady) {
      print('❌ TensorflowService not ready');
      return;
    }

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        _frameCounter++;
        if (_frameCounter % 3 != 0) return; // Skip every 3rd frame
        if (_isPredicting) return;
        _isPredicting = true;
        try {
          print(
            '--- Frame Received at ${DateTime.now()}! Sending to service... ---',
          );
          _tensorflowService.runModel(image); // No await
        } catch (e) {
          print('❌ Error dispatching frame to isolate: $e');
        } finally {
          _isPredicting = false;
        }
      });
      print('✅ Image streaming started');
    } catch (e) {
      print('❌ Error starting image stream: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
        print('✅ Image stream stopped');
      } catch (e) {
        print('❌ Error stopping image stream: $e');
      }
    }
  }

  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _tensorflowService.stop();
    print('✅ CameraService disposed');
  }
}

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

  // file: services/camera-service.dart

  Future<void> startStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('❌ CameraController not initialized');
      return;
    }
    if (_cameraController!.value.isStreamingImages) {
      print('Already streaming');
      return;
    }

    print('[CAMERA] Waiting for TensorflowService to be ready...');
    try {
      // حلقه for قبلی را حذف و این خط را جایگزین کن
      await _tensorflowService.readyFuture.timeout(const Duration(seconds: 5));
    } catch (e) {
      print('❌ TensorflowService not ready after timeout: $e');
      return;
    }
    print('[CAMERA] ✅ TensorflowService is ready. Starting image stream.');

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        _frameCounter++;
        if (_frameCounter % 3 != 0) return;
        if (_isPredicting) return;

        _isPredicting = true;
        try {
          // این لاگ بسیار مهم است، آن را اضافه کن
          print('[CAMERA] Sending frame to TensorflowService...');
          _tensorflowService.runModel(image);
        } catch (e) {
          print('❌ Error dispatching frame to isolate: $e');
        } finally {
          _isPredicting = false;
        }
      });
      print('✅ Image streaming started successfully');
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
    stopImageStream();
    _cameraController?.dispose();
    _cameraController = null;
    _tensorflowService.stop();
    print('✅ CameraService disposed');
  }
}

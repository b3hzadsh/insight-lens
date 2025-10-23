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
        throw Exception('Camera permission required');
      }

      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
    } catch (e) {
      print('❌ Error initializing camera: $e');
      _cameraController = null;
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<void> startStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_cameraController!.value.isStreamingImages) {
      return;
    }

    try {
      await _tensorflowService.readyFuture.timeout(const Duration(seconds: 5));
    } catch (e) {
      print('❌ TensorflowService not ready after timeout: $e');
      return;
    }

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (_isPredicting) return;
        _isPredicting = true;

        try {
          await _tensorflowService.runModel(image);
        } catch (e) {
          print(e);
        } finally {
          _isPredicting = false;
        }
      });
    } catch (e) {
      print('❌ Error starting image stream: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
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
  }
}

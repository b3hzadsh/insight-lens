import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:test_app/recognition_isolate.dart';

class TensorflowService {
  final StreamController<List<Recognition>> _recognitionController =
      StreamController.broadcast();
  Stream<List<Recognition>> get recognitionStream =>
      _recognitionController.stream;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> start() async {
    final receivePort = ReceivePort();
    try {
      final modelFileName = 'mobilenet_v1_1.0_224.tflite';
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      final modelData = await rootBundle.load('assets/$modelFileName');
      final modelBytes = modelData.buffer.asUint8List();
      final labels = labelsData.split('\n');
      print(
        '[MAIN THREAD] Model loaded: ${modelBytes.length} bytes, Labels: ${labels.length}',
      );

      final initData = IsolateInitData(
        receivePort.sendPort,
        modelBytes,
        labels,
      );
      _isolate = await Isolate.spawn(runIsolate, initData);
      print('[MAIN THREAD] Isolate spawned. Attaching listener...');

      receivePort.listen((message) {
        print(
          '[MAIN THREAD] Message received from Isolate: ${message.runtimeType}',
        );
        if (message is SendPort) {
          _isolateSendPort = message;
          _isReady = true;
          print('✅ [MAIN THREAD] Isolate send port received.');
        } else if (message is List<Map<String, dynamic>>) {
          final recognitions = message
              .map((e) => Recognition(e['label'], e['confidence']))
              .toList();
          _recognitionController.add(recognitions);
        } else if (message is String && message.contains('Error')) {
          print('❌ $message');
          _recognitionController.addError(message);
        }
      });
    } catch (e) {
      print('❌ Error starting TensorflowService: $e');
      _recognitionController.addError('Error starting service: $e');
      _isReady = false;
    }
  }

  void runModel(CameraImage image) {
    if (_isolateSendPort == null || !_isReady) {
      print('❌ Isolate SendPort not initialized or not ready');
      return;
    }
    try {
      final isolateData = IsolateCameraImage(
        image.planes.map((p) => p.bytes).toList(),
        image.height,
        image.width,
        image.planes.length > 1 ? image.planes[1].bytesPerRow : image.width,
        image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
      );
      _isolateSendPort!.send(isolateData);
      print(
        '[MAIN THREAD] Frame sent to isolate: ${image.width}x${image.height}',
      );
    } catch (e) {
      print('❌ Error sending frame to isolate: $e');
    }
  }

  void stop() {
    if (_isolateSendPort != null) {
      _isolateSendPort!.send('stop');
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _isReady = false;
    _recognitionController.close();
    print('✅ TensorflowService stopped');
  }
}

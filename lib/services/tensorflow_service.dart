import 'dart:async';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:test_app/recognition_isolate.dart';

class TensorflowService {
  static final TensorflowService _instance = TensorflowService._internal();

  factory TensorflowService() => _instance;

  TensorflowService._internal();
  final StreamController<List<Recognition>> _recognitionController =
      StreamController.broadcast();
  Stream<List<Recognition>> get recognitionStream =>
      _recognitionController.stream;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  bool _isReady = false;
  bool get isReady => _isReady;
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get readyFuture => _readyCompleter.future;
  Completer<void>? _inferenceCompleter;

  Future<void> start() async {
    final receivePort = ReceivePort();
    try {
      final modelFileName = 'mobilenet_v1_1.0_224.tflite';
      final labelsData = await rootBundle.loadString('assets/labels_fa.txt');
      final modelData = await rootBundle.load('assets/$modelFileName');
      final modelBytes = modelData.buffer.asUint8List();
      final labels = labelsData.split('\n');

      final initData = IsolateInitData(
        receivePort.sendPort,
        modelBytes,
        labels,
      );

      _isolate = await Isolate.spawn(runIsolate, initData);
      receivePort.listen((message) {
        if (message is SendPort) {
          _isolateSendPort = message;
          _isReady = true;
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }
        } else if (message is List) {
          final recognitions = message
              .map((e) => Recognition(e['label'], e['confidence'] as double))
              .toList();
          _inferenceCompleter?.complete();
          _recognitionController.add(recognitions);
        } else if (message is String && message.contains('Error')) {
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.completeError(message);
          }
          _recognitionController.addError(message);
          _inferenceCompleter?.completeError(message);
        }
      });
    } catch (e) {
      print('❌ Error starting TensorflowService: $e');
      _recognitionController.addError('Error starting service: $e');
      _isReady = false;
      rethrow;
    }
  }

  Future<void> runModel(CameraImage image) {
    if (_isolateSendPort == null || !_isReady) {
      return Future.value();
    }

    _inferenceCompleter = Completer<void>();

    try {
      final isolateData = IsolateCameraImage(
        image.planes.map((p) => p.bytes).toList(),
        image.height,
        image.width,
        image.planes[0].bytesPerRow,
        image.planes.length > 1 ? image.planes[1].bytesPerRow : image.width,
        image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
      );

      _isolateSendPort!.send(isolateData);
    } catch (e) {
      _inferenceCompleter?.completeError(e);
    }
    return _inferenceCompleter!.future;
  }

  void stop() {
    if (_isolateSendPort != null) {
      _isolateSendPort!.send('stop');
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _isReady = false;
    if (_inferenceCompleter != null && !_inferenceCompleter!.isCompleted) {
      _inferenceCompleter!.completeError('Service stopped');
    }
    _inferenceCompleter = null;
    _recognitionController.close();
  }
}

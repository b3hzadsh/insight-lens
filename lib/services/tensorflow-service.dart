import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
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

  Future<void> start() async {
    final receivePort = ReceivePort(); // پورتی برای دریافت پیام از Isolate
    try {
      // --- ۱. بارگذاری مدل و لیبل‌ها ---
      final modelFileName = 'mobilenet_v1_1.0_224.tflite';
      final labelsData = await rootBundle.loadString('assets/labels_fa.txt');
      final modelData = await rootBundle.load('assets/$modelFileName');
      final modelBytes = modelData.buffer.asUint8List();
      final labels = labelsData.split('\n');
      print(
        '[MAIN THREAD] Model loaded: ${modelBytes.length} bytes, Labels: ${labels.length}',
      );

      // --- ۲. آماده‌سازی داده‌های اولیه برای ارسال به Isolate ---
      final initData = IsolateInitData(
        receivePort.sendPort, // پورت خودمان را به Isolate می‌دهیم
        modelBytes,
        labels,
      );

      // --- ۳. ایجاد و اجرای Isolate ---
      _isolate = await Isolate.spawn(runIsolate, initData);
      print('[MAIN THREAD] Isolate spawned. Attaching listener...');

      // --- ۴. اصلاحیه کلیدی: استفاده از listen برای ارتباط دائمی ---
      // حلقه‌ی 'await for' قبلی، بعد از اولین پیام خارج می‌شد.
      // متد 'listen' یک شنونده‌ی دائمی ایجاد می‌کند که تمام پیام‌های ورودی
      // (هم پیام اولیه و هم نتایج تشخیص) را مدیریت می‌کند.
      receivePort.listen((message) {
        print(
          '[MAIN THREAD] Message received from Isolate: ${message.runtimeType}',
        );

        if (message is SendPort) {
          // اولین پیام، SendPort خود Isolate است. آن را ذخیره می‌کنیم.
          _isolateSendPort = message;
          _isReady = true;
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }
          print(
            '✅ [MAIN THREAD] Isolate send port received. Service is ready.',
          );
        } else if (message is List) {
          // پیام‌های بعدی، نتایج تشخیص هستند.
          final recognitions = message
              .map((e) => Recognition(e['label'], e['confidence'] as double))
              .toList();
          _recognitionController.add(recognitions); // ارسال نتایج به UI
        } else if (message is String && message.contains('Error')) {
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.completeError(message);
          }
          // مدیریت پیام‌های خطا از سمت Isolate
          print('❌ $message');
          _recognitionController.addError(message);
        }
      });
    } catch (e) {
      print('❌ Error starting TensorflowService: $e');
      _recognitionController.addError('Error starting service: $e');
      _isReady = false;
      rethrow;
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

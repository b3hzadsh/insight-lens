import 'dart:async';
import 'package:camera/camera.dart';
import 'package:test_app/services/tensorflow-service.dart';

// singleton class used as a service
class CameraService {
  // singleton boilerplate
  static final CameraService _cameraService = CameraService._internal();

  factory CameraService() {
    return _cameraService;
  }
  CameraService._internal();
  // singleton boilerplate

  final TensorflowService _tensorflowService = TensorflowService();

  // ### 1. Null Safety ###
  // کنترلر دوربین اکنون Nullable است تا با قوانین جدید دارت سازگار باشد
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  // این فلگ برای کنترل اجرای مدل روی فریم‌ها استفاده می‌شود
  // تا از پردازش بیش از حد جلوگیری شود
  bool _isPredicting = false;

  // ### 2. بهبود متد startService ###
  // این متد اکنون async است و به طور کامل کنترلر را مقداردهی اولیه می‌کند
  Future<void> startService(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium, // استفاده از رزولوشن متوسط برای بهبود پر포먼س
    );

    // مقداردهی اولیه کنترلر
    await _cameraController?.initialize();
  }

  // ### 3. بهبود متد startStreaming ###
  // این متد جریان تصویر را برای پردازش توسط سرویس TensorFlow آغاز می‌کند
  Future<void> startStreaming() async {
    // ابتدا بررسی می‌کنیم که کنترلر مقداردهی شده باشد
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('❌ Error: Camera controller is not initialized.');
      return;
    }

    // بررسی می‌کنیم که آیا جریان تصویر در حال اجراست یا خیر
    if (_cameraController!.value.isStreamingImages) {
      print('ℹ️ Image stream is already running.');
      return;
    }

    // شروع جریان تصویر
    await _cameraController?.startImageStream((CameraImage image) {
      // اگر در حال پردازش فریم قبلی نیستیم، فریم جدید را پردازش کن
      if (!_isPredicting) {
        _isPredicting =
            true; // فلگ را تنظیم می‌کنیم تا فریم‌های دیگر وارد نشوند
        try {
          // اجرای مدل روی فریم فعلی
          _tensorflowService.runModel(image);
        } catch (e) {
          print('❌ Error running model with current frame: $e');
        } finally {
          // چه پردازش موفق بود و چه ناموفق، بعد از اتمام کار فلگ را آزاد می‌کنیم
          // این بخش باعث می‌شود پردازش متوقف نشود
          // نیازی به Future.delayed نیست چون پردازش مدل خودش زمان‌بر است
          _isPredicting = false;
        }
      }
    });
  }

  // ### 4. متد stopImageStream ###
  // این متد جریان تصویر را متوقف می‌کند
  Future<void> stopImageStream() async {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController?.stopImageStream();
    }
  }

  // ### 5. متد dispose ###
  // منابع کنترلر دوربین را آزاد می‌کند
  void dispose() {
    _cameraController?.dispose();
  }
}

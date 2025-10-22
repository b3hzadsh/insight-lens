import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// مسیرها را متناسب با ساختار پروژه خودتان تنظیم کنید
import 'package:test_app/services/camera-service.dart';
import 'package:test_app/services/tensorflow-service.dart';
import 'package:test_app/widgets/camera-header.dart';
import 'package:test_app/widgets/camera-screen.dart';
import 'package:test_app/widgets/recognition.dart';

class Home extends StatefulWidget {
  final CameraDescription camera;

  const Home({Key? key, required this.camera}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  // Services injection
  final TensorflowService _tensorflowService = TensorflowService();
  final CameraService _cameraService = CameraService();

  // Future برای کنترل وضعیت مقداردهی اولیه سرویس‌ها
  late Future<void> _initializeServicesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // در initState، فرآیند طولانی مقداردهی اولیه را شروع می‌کنیم
    _initializeServicesFuture = _initializeServices();
  }

  // متد اصلی برای مقداردهی اولیه سرویس‌ها
  Future<void> _initializeServices() async {
    await _cameraService.startService(widget.camera);
    await _tensorflowService.loadModel();
    // پس از لود شدن مدل، استریم تصویر را شروع می‌کنیم
    _cameraService.startStreaming();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // منابع هر دو سرویس را آزاد می‌کنیم
    _cameraService.dispose();
    _tensorflowService.dispose();
    super.dispose();
  }

  // مدیریت بهینه چرخه حیات اپلیکیشن
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // اگر اپلیکیشن متوقف یا غیرفعال شد، استریم دوربین را برای صرفه‌جویی در باتری متوقف می‌کنیم
    // و هنگام بازگشت، دوباره آن را فعال می‌کنیم.
    switch (state) {
      case AppLifecycleState.resumed:
        _cameraService.startStreaming();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        // منتظر می‌مانیم تا فرآیند مقداردهی اولیه تمام شود
        future: _initializeServicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // اگر همه چیز آماده بود، پیش‌نمایش دوربین و نتایج را نشان بده
            return Stack(
              children: <Widget>[
                // ویجت نمایش پیش‌نمایش دوربین
                CameraScreen(controller: _cameraService.cameraController),
                // هدر بالای صفحه
                const CameraHeader(),
                // استفاده از StreamBuilder برای نمایش نتایج زنده
                StreamBuilder<List<Recognition>>(
                  stream: _tensorflowService.recognitionStream,
                  builder: (context, recognitionSnapshot) {
                    return RecognitionWidget(
                      // داده‌های جدید را به ویجت نمایش نتایج پاس می‌دهیم
                      results: recognitionSnapshot.data,
                    );
                  },
                ),
              ],
            );
          } else {
            // در غیر این صورت، یک نمایشگر لودینگ نشان بده
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

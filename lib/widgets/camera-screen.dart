import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// 1. تبدیل به StatelessWidget برای بهینه‌سازی
class CameraScreen extends StatelessWidget {
  // 2. کنترلر اکنون Nullable است تا برنامه کرش نکند
  final CameraController? controller;

  const CameraScreen({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 3. اگر کنترلر آماده نبود، یک صفحه سیاه خالی نشان بده
    if (controller == null || !controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    // حفظ افکت گرادینت بالای صفحه
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Colors.black, Colors.transparent],
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height / 2));
      },
      blendMode: BlendMode.darken,
      // 4. ساده‌سازی منطق نمایش تصویر دوربین
      child: _buildCameraPreview(context),
    );
  }

  // این متد کمکی، پیش‌نمایش دوربین را طوری اندازه می‌دهد که تمام صفحه را بپوشاند
  Widget _buildCameraPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = controller!.value.aspectRatio;

    // با استفاده از Transform.scale، تصویر را بدون تغییر نسبت ابعاد، بزرگ می‌کنیم
    // تا تمام صفحه را پر کند.
    return Transform.scale(
      scale: deviceRatio / previewRatio,
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: previewRatio,
        child: CameraPreview(controller!),
      ),
    );
  }
}

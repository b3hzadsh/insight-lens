import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  final CameraController? controller;

  const CameraScreen({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Colors.black, Colors.transparent],
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height / 2));
      },
      blendMode: BlendMode.darken,
      child: _buildCameraPreview(context),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = controller!.value.aspectRatio;
    return CameraPreview(controller!);

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

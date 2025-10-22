// recognition_isolate.dart

import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// این تابع نقطه ورود و اجرای ایزوله ما در پس‌زمینه است
void runIsolate(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  late Interpreter interpreter;
  late List<String> labels;

  // منتظر دریافت داده از رشته اصلی می‌مانیم
  await for (final message in receivePort) {
    if (message is String && message == 'load') {
      // بارگذاری مدل و لیبل‌ها در داخل ایزوله
      try {
        final modelFileName = 'small-075-224-classification-metadata.tflite';
        interpreter = await Interpreter.fromAsset(modelFileName);
        labels = await FileUtil.loadLabels('assets/$modelFileName');
        sendPort.send('Model loaded successfully');
      } catch (e) {
        sendPort.send('Error loading model: $e');
      }
    } else if (message is CameraImage) {
      // اگر یک فریم تصویر دریافت شد، پردازش را شروع کن
      try {
        final recognition = _performInference(message, interpreter, labels);
        sendPort.send(recognition);
      } catch (e) {
        print('Error in isolate inference: $e');
        sendPort.send(null); // در صورت خطا، null بفرست
      }
    }
  }
}

// تمام کدهای پردازش تصویر و اجرای مدل به اینجا منتقل شده‌اند
List<Map<String, dynamic>> _performInference(
  CameraImage image,
  Interpreter interpreter,
  List<String> labels,
) {
  // ۱. پردازش تصویر
  final inputImage = _processCameraImage(image);
  if (inputImage == null) return [];

  // ۲. تعریف شکل خروجی
  final outputShape = interpreter.getOutputTensor(0).shape;
  final output = List.filled(
    outputShape.reduce((a, b) => a * b),
    0.0,
  ).reshape(outputShape);

  // ۳. اجرای مدل
  interpreter.run(inputImage, output);

  // ۴. پردازش خروجی
  final probabilities = output[0] as List<double>;
  final recognitions = _processOutput(probabilities, labels);

  // ۵. تبدیل نتایج به یک فرمت قابل ارسال (Map)
  return recognitions
      .map((rec) => {'label': rec.label, 'confidence': rec.confidence})
      .toList();
}

// تابع پردازش تصویر (بدون تغییر)
List<List<List<List<double>>>>? _processCameraImage(CameraImage cameraImage) {
  final int modelInputSize = 224;

  img.Image? convertedImage;

  if (Platform.isAndroid) {
    // برای اندروید، فرمت YUV است
    convertedImage = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.yuv,
    );
  } else if (Platform.isIOS) {
    // برای iOS، فرمت BGRA است
    convertedImage = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  if (convertedImage == null) return null;

  final resizedImage = img.copyResizeCropSquare(
    convertedImage,
    size: modelInputSize,
  );

  var imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
  var modelInput = List.generate(
    1,
    (i) => List.generate(
      modelInputSize,
      (j) => List.generate(modelInputSize, (k) => List.generate(3, (l) => 0.0)),
    ),
  );

  int pixelIndex = 0;
  for (int i = 0; i < modelInputSize; i++) {
    for (int j = 0; j < modelInputSize; j++) {
      modelInput[0][i][j][0] = imageBytes[pixelIndex++] / 255.0; // R
      modelInput[0][i][j][1] = imageBytes[pixelIndex++] / 255.0; // G
      modelInput[0][i][j][2] = imageBytes[pixelIndex++] / 255.0; // B
    }
  }

  return modelInput;
}

// تابع پردازش خروجی (بدون تغییر)
List<Recognition> _processOutput(List<double> output, List<String> labels) {
  const int numResults = 3;
  List<int> topIndices = List.generate(output.length, (index) => index)
    ..sort((a, b) => output[b].compareTo(output[a]));

  List<Recognition> recognitions = [];
  for (int i = 0; i < numResults; i++) {
    int index = topIndices[i];
    if (index < labels.length) {
      recognitions.add(Recognition(labels[index], output[index]));
    }
  }
  return recognitions;
}

// کلاس Recognition برای نگهداری نتایج (بدون تغییر)
class Recognition {
  final String label;
  final double confidence;
  Recognition(this.label, this.confidence);
}

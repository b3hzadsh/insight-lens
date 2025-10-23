import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// new by per
class IsolateCameraImage {
  final List<Uint8List> planes;
  final int height;
  final int width;
  final int yRowStride; // <--- این خط را اضافه کنید
  final int uvRowStride;
  final int uvPixelStride;

  IsolateCameraImage(
    this.planes,
    this.height,
    this.width,
    this.yRowStride, // <--- این خط را اضافه کنید
    this.uvRowStride,
    this.uvPixelStride,
  );
}

class IsolateInitData {
  final SendPort mainSendPort;
  final Uint8List modelBytes;
  final List<String> labels;
  IsolateInitData(this.mainSendPort, this.modelBytes, this.labels);
}

class Recognition {
  final String label;
  final double confidence;
  Recognition(this.label, this.confidence);
}

// تبدیل YUV420 بدون استفاده از helper
img.Image? _convertYUV420ToRGB(IsolateCameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int yRowStride = image.yRowStride; // <--- این خط را اضافه کنید
  final int uvRowStride = image.uvRowStride;
  final int uvPixelStride = image.uvPixelStride;

  try {
    final outputImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        // final int index = y * width + x;
        final int index = y * yRowStride + x; // <--- خط جدید (صحیح)

        final int yp = image.planes[0][index];
        final int up = image.planes[1][uvIndex];
        final int vp = image.planes[2][uvIndex];

        // تبدیل دقیق YUV به RGB (فرمول استاندارد ITU-R BT.601)
        double yVal = yp.toDouble();
        double uVal = up.toDouble() - 128.0;
        double vVal = vp.toDouble() - 128.0;

        int r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
        int g = (yVal - 0.344136 * uVal - 0.714136 * vVal)
            .clamp(0, 255)
            .toInt();
        int b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();
        //
        // فرمول بهینه‌شده برای تبدیل YUV به RGB
        // int r = (yVal + 1.402 * (vVal - 128)).clamp(0, 255).toInt();
        // int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
        //     .clamp(0, 255)
        //     .toInt();
        // int b = (yVal + 1.772 * (uVal - 128)).clamp(0, 255).toInt();
        //
        outputImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    // چرخش برای تصحیح orientation دوربین (بسته به حالت گوشی ممکن است نیاز به تغییر داشته باشد)
    final rotatedImage = img.copyRotate(outputImage, angle: 270);
    return rotatedImage;
  } catch (e) {
    print('[ISOLATE] ❌ Error converting YUV to RGB: $e');
    return null;
  }
}

void runIsolate(IsolateInitData initData) async {
  late Interpreter interpreter;
  final labels = initData.labels;

  try {
    print('[ISOLATE] Starting model initialization...');
    interpreter = Interpreter.fromBuffer(
      initData.modelBytes,
      options: InterpreterOptions()..threads = 1,
    );
    print(
      "hi shape : ${interpreter.getInputTensor(0).shape}",
    ); // [1, 224, 224, 3]
    print('[ISOLATE] Model loaded successfully: ${labels.length} labels');
  } catch (e) {
    print('[ISOLATE] Error loading model: $e');
    initData.mainSendPort.send('Error loading model: $e');
    return;
  }

  final receivePort = ReceivePort();
  initData.mainSendPort.send(receivePort.sendPort);
  print('[ISOLATE] Sent SendPort to main thread');

  await for (final message in receivePort) {
    if (message == 'stop') {
      print('[ISOLATE] Stopping isolate');
      receivePort.close();
      interpreter.close();
      return;
    }
    if (message is IsolateCameraImage) {
      try {
        final recognition = _performInference(message, interpreter, labels);
        initData.mainSendPort.send(recognition);
      } catch (e) {
        print('[ISOLATE] Error in inference: $e');
        initData.mainSendPort.send('Error in inference: $e');
      }
    }
  }
}

List<Map<String, dynamic>> _performInference(
  IsolateCameraImage image,
  Interpreter interpreter,
  List<String> labels,
) {
  final inputImage = _processCameraImage(image);
  if (inputImage == null) {
    print('[ISOLATE] Failed to process camera image');
    return [];
  }
  try {
    final outputShape = interpreter.getOutputTensor(0).shape;
    final output = List<double>.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(outputShape);
    interpreter.run(inputImage, output);
    final probabilities = output[0] as List<double>;
    final recognitions = _processOutput(probabilities, labels);
    print('[ISOLATE] Inference completed: ${recognitions.length} results');
    return recognitions
        .map((rec) => {'label': rec.label, 'confidence': rec.confidence})
        .toList();
  } catch (e) {
    print('[ISOLATE] Error running inference: $e');
    return [];
  }
}

List<List<List<List<double>>>>? _processCameraImage(
  IsolateCameraImage cameraImage,
) {
  const int modelInputSize = 224;
  img.Image? rgbImage;

  try {
    // ۱. تبدیل به RGB بر اساس پلتفرم
    if (Platform.isAndroid && cameraImage.planes.length == 3) {
      rgbImage = _convertYUV420ToRGB(cameraImage);
    } else if (Platform.isIOS && cameraImage.planes.length == 1) {
      rgbImage = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: cameraImage.planes[0].buffer,
        order: img.ChannelOrder.rgba,
      );
    } else {
      print(
        '[ISOLATE] Unsupported image format: ${cameraImage.planes.length} planes',
      );
      return null;
    }

    if (rgbImage == null) {
      print('[ISOLATE] Failed to convert image to RGB');
      return null;
    }

    // ۲. resize & crop به سایز مدل
    final resizedImage = img.copyResizeCropSquare(
      rgbImage,
      size: modelInputSize,
    );

    // ۳. استخراج بایت‌های RGB
    final imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);

    // ۴. ساخت Tensor [1,224,224,3] با نرمال‌سازی [0,1]
    final modelInput = List.generate(
      1,
      (_) => List.generate(
        modelInputSize,
        (_) =>
            List.generate(modelInputSize, (_) => List<double>.filled(3, 0.0)),
      ),
    );

    int pixelIndex = 0;
    for (int i = 0; i < modelInputSize; i++) {
      for (int j = 0; j < modelInputSize; j++) {
        // print('value of r is : ${imageBytes[pixelIndex++]}');
        final r = (imageBytes[pixelIndex++] - 127.5) / 127.5;
        final g = (imageBytes[pixelIndex++] - 127.5) / 127.5;
        final b = (imageBytes[pixelIndex++] - 127.5) / 127.5;

        modelInput[0][i][j][0] = r;
        modelInput[0][i][j][1] = g;
        modelInput[0][i][j][2] = b;
      }
    }
    print('[ISOLATE] ✅ Image processed successfully for MobileNet V1');
    return modelInput;
  } catch (e) {
    print('[ISOLATE] ❌ Error processing camera image: $e');
    return null;
  }
}

List<Recognition> _processOutput(List<double> output, List<String> labels) {
  const int numResults = 3;
  List<int> topIndices = List.generate(output.length, (index) => index)
    ..sort((a, b) => output[b].compareTo(output[a]));

  List<Recognition> recognitions = [];
  for (int i = 0; i < numResults && i < topIndices.length; i++) {
    int index = topIndices[i];
    if (index < labels.length && index >= 0) {
      recognitions.add(Recognition(labels[index], output[index]));
    } else {
      print(
        '[ISOLATE] Invalid label index: $index, labels length: ${labels.length}',
      );
    }
  }
  return recognitions;
}

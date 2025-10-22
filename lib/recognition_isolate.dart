import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateCameraImage {
  final List<Uint8List> planes;
  final int height;
  final int width;
  final int uvRowStride;
  final int uvPixelStride;

  IsolateCameraImage(
    this.planes,
    this.height,
    this.width,
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

img.Image? _convertYUV420(IsolateCameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int uvRowStride = image.uvRowStride;
  final int uvPixelStride = image.uvPixelStride;

  try {
    final yuv420image = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final int index = y * width + x;
        final yp = image.planes[0][index];
        final up = image.planes[1][uvIndex];
        final vp = image.planes[2][uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        yuv420image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    print('[ISOLATE] YUV420 converted to RGB: ${width}x${height}');
    return yuv420image;
  } catch (e) {
    print('[ISOLATE] Error converting YUV420: $e');
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
  final int modelInputSize = 224;
  img.Image? convertedImage;

  try {
    if (Platform.isAndroid && cameraImage.planes.length == 3) {
      convertedImage = _convertYUV420(cameraImage);
    } else if (Platform.isIOS && cameraImage.planes.length == 1) {
      convertedImage = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: cameraImage.planes[0].buffer,
        order: img.ChannelOrder.bgra,
      );
      print(
        '[ISOLATE] BGRA converted to RGB: ${cameraImage.width}x${cameraImage.height}',
      );
    } else {
      print(
        '[ISOLATE] Unsupported image format: ${cameraImage.planes.length} planes',
      );
      return null;
    }

    if (convertedImage == null) {
      print('[ISOLATE] Failed to convert image');
      return null;
    }

    final resizedImage = img.copyResizeCropSquare(
      convertedImage,
      size: modelInputSize,
    );
    var imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    var modelInput = List.generate(
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
        modelInput[0][i][j][0] = imageBytes[pixelIndex++] / 255.0; // R
        modelInput[0][i][j][1] = imageBytes[pixelIndex++] / 255.0; // G
        modelInput[0][i][j][2] = imageBytes[pixelIndex++] / 255.0; // B
      }
    }
    return modelInput;
  } catch (e) {
    print('[ISOLATE] Error processing camera image: $e');
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

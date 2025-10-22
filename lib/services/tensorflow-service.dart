import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Recognition {
  final String label;
  final double confidence;

  Recognition(this.label, this.confidence);

  @override
  String toString() {
    return 'Recognition(label: $label, confidence: $confidence)';
  }
}

// singleton class used as a service
class TensorflowService {
  // singleton boilerplate
  static final TensorflowService _tensorflowService =
      TensorflowService._internal();

  factory TensorflowService() {
    return _tensorflowService;
  }
  TensorflowService._internal();
  // singleton boilerplate

  final StreamController<List<Recognition>> _recognitionController =
      StreamController.broadcast();
  Stream<List<Recognition>> get recognitionStream =>
      _recognitionController.stream;

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    if (_isModelLoaded) return; // اگر مدل قبلا لود شده، کاری نکن

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_v1_1.0_224.tflite',
      );

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n');

      print('✅ Model and labels loaded successfully');
      _isModelLoaded = true;
    } catch (e) {
      print('❌ Error loading model: $e');
    }
  }

  Future<void> runModel(CameraImage cameraImage) async {
    if (!_isModelLoaded || _interpreter == null) {
      print('Model not loaded, skipping inference');
      return;
    }

    final inputImage = _processCameraImage(cameraImage);
    if (inputImage == null) return;

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputType = _interpreter!.getOutputTensor(0).type;

    final output = List.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(outputShape);

    _interpreter!.run(inputImage, output);

    final recognitions = _processOutput(output[0] as List<double>);

    if (!_recognitionController.isClosed) {
      _recognitionController.add(recognitions);
    }
  }

  List<List<List<List<double>>>>? _processCameraImage(CameraImage cameraImage) {
    final int modelInputSize = 224;

    final convertedImage = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra, // یا هر فرمت دیگری که دوربین شما می‌دهد
    );

    final resizedImage = img.copyResizeCropSquare(
      convertedImage,
      size: modelInputSize,
    );

    var imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    var modelInput = List.generate(
      1,
      (i) => List.generate(
        modelInputSize,
        (j) =>
            List.generate(modelInputSize, (k) => List.generate(3, (l) => 0.0)),
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

  List<Recognition> _processOutput(List<double> output) {
    if (_labels == null) return [];

    const int numResults = 3;

    List<int> topIndices = List.generate(output.length, (index) => index)
      ..sort((a, b) => output[b].compareTo(output[a]));

    List<Recognition> recognitions = [];
    for (int i = 0; i < numResults; i++) {
      int index = topIndices[i];
      if (index < _labels!.length) {
        recognitions.add(Recognition(_labels![index], output[index]));
      }
    }

    return recognitions;
  }

  void dispose() {
    _interpreter?.close();
    _recognitionController.close();
    _isModelLoaded = false;
    print('Interpreter and StreamController closed.');
  }
}

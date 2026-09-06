import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

/// Alternative model service (kept for reference / future use).
/// The active inference pipeline uses [VisionClassifier] in vision_classifier.dart.
class ModelService {
  // Asset path must match pubspec.yaml assets declaration
  static const String modelPath = 'Assets/models/model.tflite';
  static const String fallbackModelPath = 'Assets/models/DR_Model.tflite';
  static const int inputSize = 288; // MobileNetV3Large v3 input: 288x288

  // Labels in model output index order (alphabetical, as loaded by Keras):
  //   index 0 → Mild
  //   index 1 → Normal
  //   index 2 → Severe
  static const List<String> _labels = ['Mild', 'Normal', 'Severe'];

  late Interpreter _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Close any existing interpreter to prevent memory leaks
      try {
        _interpreter.close();
      } catch (_) {
        // Ignore if interpreter wasn't initialized
      }

      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/DR_Model.tflite');

      if (!await modelFile.exists()) {
        print('[ModelService] Copying model from assets...');
        try {
          final modelData = await rootBundle.load(modelPath);
          await modelFile.writeAsBytes(modelData.buffer.asUint8List());
          print('[ModelService] Model copied: ${modelFile.path} (${await modelFile.length()} bytes)');
        } catch (e) {
          print('[ModelService] Error copying model: $e');
          rethrow;
        }
      } else {
        print('[ModelService] Using existing model: ${modelFile.path} (${await modelFile.length()} bytes)');
      }

      // Try loading from assets first
      try {
        final interpreterOptions = InterpreterOptions()..threads = 2;
        _interpreter = await Interpreter.fromAsset(modelPath, options: interpreterOptions);
        _isInitialized = true;
        print('[ModelService] Model loaded from assets.');
      } catch (assetError) {
        print('[ModelService] Asset load failed ($assetError), trying file...');
        final interpreterOptions = InterpreterOptions()..threads = 2;
        _interpreter = Interpreter.fromFile(modelFile, options: interpreterOptions);
        _isInitialized = true;
        print('[ModelService] Model loaded from file.');
      }

      if (_isInitialized) {
        final inputTensor = _interpreter.getInputTensor(0);
        final outputTensor = _interpreter.getOutputTensor(0);
        print('[ModelService] Input  shape: ${inputTensor.shape}, type: ${inputTensor.type}');
        print('[ModelService] Output shape: ${outputTensor.shape}, type: ${outputTensor.type}');
      }
    } catch (e, stack) {
      print('[ModelService] ERROR initializing: $e\n$stack');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    try {
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) throw Exception('Model failed to initialize');
      }

      final imageBytes = await imageFile.readAsBytes();
      var image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Resize to model input dimensions
      var resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

      final inputShape = _interpreter.getInputTensor(0).shape;
      final outputShape = _interpreter.getOutputTensor(0).shape;

      print('[ModelService] Input shape: $inputShape, Output shape: $outputShape');

      // Build normalised flat input [0, 255]
      final List<double> flatInput = [];
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          flatInput.add(pixel.r.toDouble());
          flatInput.add(pixel.g.toDouble());
          flatInput.add(pixel.b.toDouble());
        }
      }

      // Reshape to [1, H, W, 3]
      final List<dynamic> inputData = [flatInput.reshape([inputSize, inputSize, 3])];

      // Output buffer: [1, numClasses]
      final int numClasses = outputShape[1];
      final List<dynamic> outputBuffer = [List<double>.filled(numClasses, 0.0)];

      print('[ModelService] Running inference...');
      _interpreter.run(inputData, outputBuffer);
      print('[ModelService] Raw output: $outputBuffer');

      // Find argmax
      var maxIdx = 0;
      var maxVal = (outputBuffer[0][0] as num).toDouble();
      for (int i = 1; i < numClasses; i++) {
        final double val = (outputBuffer[0][i] as num).toDouble();
        if (val > maxVal) {
          maxVal = val;
          maxIdx = i;
        }
      }

      // Apply confidence threshold
      String predictedDisease;
      if (maxVal >= 0.50 && maxIdx < _labels.length) {
        predictedDisease = _labels[maxIdx];
      } else {
        predictedDisease = 'Unknown (Low Confidence)';
      }

      print('[ModelService] Predicted: $predictedDisease (idx=$maxIdx, conf=${(maxVal * 100).toStringAsFixed(1)}%)');

      return {
        'disease': predictedDisease,
        'confidence': maxVal,
        'detections': [],
      };
    } catch (e, stack) {
      print('[ModelService] ERROR in detectDisease: $e\n$stack');
      rethrow;
    }
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
    }
  }
}

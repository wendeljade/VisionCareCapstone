import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class VisionClassifier {
  Interpreter? _interpreter;

  // Labels MUST match the model's output index order.
  // The model was trained with Keras image_dataset_from_directory which
  // sorts class folders alphabetically:
  //   index 0 → Mild
  //   index 1 → Normal
  //   index 2 → Severe
  static const List<String> _labels = ['Mild', 'Normal', 'Severe'];

  // Minimum confidence to accept a prediction as valid.
  // 3-class softmax → random baseline is ~33%, so 50% is a safe threshold.
  static const double _confidenceThreshold = 0.50;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      try {
        _interpreter = await Interpreter.fromAsset(
          'Assets/models/model.tflite',
          options: options,
        );
      } catch (_) {
        _interpreter = await Interpreter.fromAsset(
          'Assets/models/DR_Model.tflite',
          options: options,
        );
      }
      // Log tensor shapes to assist debugging
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      print('[VisionClassifier] Model loaded successfully.');
      print('[VisionClassifier] Input  shape: ${inputTensor.shape}, type: ${inputTensor.type}');
      print('[VisionClassifier] Output shape: ${outputTensor.shape}, type: ${outputTensor.type}');
    } catch (e) {
      print('[VisionClassifier] ERROR loading model: $e');
      _interpreter = null;
    }
  }

  bool get isReady => _interpreter != null;

  // ─────────────────────────────────────────────────────────────────────────
  // STRUCTURAL VALIDATOR
  // Validates based on RNFL patterns and Optic Disc presence.
  // Works for both Camera and Gallery images.
  // ─────────────────────────────────────────────────────────────────────────
  bool isValidRetinaStructure(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      // Analyse in 128x128 sample for structural and chromatic analysis
      final sample = img.copyResize(image, width: 128, height: 128);
      List<int> grays = [];
      int rSum = 0, gSum = 0, bSum = 0;
      int maxG = 0;
      int cornerSum = 0;
      int cornerCount = 0;

      for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
          final p = sample.getPixel(x, y);
          int r = p.r.toInt();
          int g = p.g.toInt();
          int b = p.b.toInt();

          rSum += r;
          gSum += g;
          bSum += b;

          int gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
          grays.add(gray);
          if (gray > maxG) maxG = gray;

          // Outer corner sampling (outer 14% bounds - fundus circular lens aperture)
          if ((x < 18 || x > 109) && (y < 18 || y > 109)) {
            cornerSum += gray;
            cornerCount++;
          }
        }
      }

      double avgR = rSum / 16384;
      double avgG = gSum / 16384;
      double avgB = bSum / 16384;
      double avgGTotal = grays.reduce((a, b) => a + b) / 16384;
      double avgCorner = cornerCount > 0 ? cornerSum / cornerCount : 0;

      // 1. Structural Complexity (retinal blood vessels and nerve fiber patterns)
      int complexity = 0;
      for (int i = 1; i < 127; i++) {
        for (int j = 1; j < 127; j++) {
          int idx = i * 128 + j;
          int diff = (grays[idx] - grays[idx - 1]).abs() +
              (grays[idx] - grays[idx - 128]).abs();
          if (diff > 12) complexity++;
        }
      }

      // 2. Ocular Chromaticity Check (Warm amber/red fundus spectrum)
      bool hasOcularColorProfile = (avgR >= avgB * 1.05) &&
          ((avgR - avgB) > 5 || (avgR - avgG).abs() > 5);

      // 3. Dark Vignette Corner Check (Circular camera aperture surround)
      bool hasDarkVignetteCorners = avgCorner <= 30.0;

      // 4. Optic Disc Hotspot Presence
      bool hasOpticDisc = maxG >= (avgGTotal * 1.7) && maxG >= 135;

      // 5. Retinal Vascular Texture Density
      bool hasRetinalTexture = complexity >= 500 && complexity <= 4200;

      // 6. Dynamic Range Contrast Check
      bool hasDynamicRange = (maxG - avgGTotal) >= 35;

      return hasOcularColorProfile &&
          hasDarkVignetteCorners &&
          hasOpticDisc &&
          hasRetinalTexture &&
          hasDynamicRange;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PREPROCESSING
  // Resize to model input size.
  // MobileNetV3 with include_preprocessing=True expects inputs in [0, 255],
  // so we pass the raw pixel values (cast to float) directly.
  // ─────────────────────────────────────────────────────────────────────────
  Uint8List _preprocess(File imageFile) {
    final imageBytes = imageFile.readAsBytesSync();
    final decodedImage = img.decodeImage(imageBytes)!;
    final inputShape = _interpreter!.getInputTensor(0).shape;
    // shape is [1, height, width, 3]
    final int inputH = inputShape[1];
    final int inputW = inputShape[2];
    final resizedImage = img.copyResize(decodedImage, width: inputW, height: inputH);

    final buffer = Float32List(inputH * inputW * 3);
    var index = 0;
    for (var y = 0; y < inputH; y++) {
      for (var x = 0; x < inputW; x++) {
        final pixel = resizedImage.getPixel(x, y);
        buffer[index++] = pixel.r.toDouble();
        buffer[index++] = pixel.g.toDouble();
        buffer[index++] = pixel.b.toDouble();
      }
    }
    return buffer.buffer.asUint8List();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PREDICTION
  // Returns a map with:
  //   "disease"    → String  label ('Mild', 'Normal', 'Severe', or 'INVALID_OBJECT')
  //   "severity"   → String  human-readable severity ('Normal', 'Mild DR', 'Severe DR')
  //   "confidence" → double  highest softmax score [0, 1]
  //   "isValid"    → bool    whether the prediction passed all checks
  // ─────────────────────────────────────────────────────────────────────────
  Map<String, dynamic> predict(File imageFile) {
    if (_interpreter == null) {
      print('[VisionClassifier] predict() called but model is not loaded.');
      return {
        "disease": "Error",
        "severity": "Unknown",
        "confidence": 0.0,
        "isValid": false,
      };
    }

    // STEP 1: Structural retina validation
    if (!isValidRetinaStructure(imageFile)) {
      return {
        "disease": "INVALID_OBJECT",
        "severity": "Unknown",
        "confidence": 0.0,
        "isValid": false,
      };
    }

    // STEP 2: Run TFLite inference
    final input = _preprocess(imageFile);
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final int numClasses = outputShape[1]; // expected: 3
    var output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
    _interpreter!.run(input, output);

    // STEP 3: Find highest-confidence class
    int maxIndex = 0;
    double maxScore = -1.0;
    for (int i = 0; i < numClasses; i++) {
      final double score = output[0][i].toDouble();
      if (score > maxScore) {
        maxScore = score;
        maxIndex = i;
      }
    }

    print('[VisionClassifier] Raw scores: ${output[0]}');
    print('[VisionClassifier] Predicted index=$maxIndex, confidence=${(maxScore * 100).toStringAsFixed(1)}%');

    // STEP 4: Confidence gate
    if (maxScore < _confidenceThreshold) {
      return {
        "disease": "INVALID_OBJECT",
        "severity": "Unknown",
        "confidence": maxScore,
        "isValid": false,
      };
    }

    // STEP 5: Map index → label
    final String label = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';

    // STEP 6: Build severity string for display
    final String severity = _buildSeverity(label);

    return {
      "disease": label,
      "severity": severity,
      "confidence": maxScore,
      "isValid": true,
    };
  }

  /// Returns a human-readable severity string consistent across the entire app.
  static String _buildSeverity(String label) {
    switch (label.toLowerCase()) {
      case 'normal':
        return 'Normal (No DR)';
      case 'mild':
        return 'Mild Diabetic Retinopathy';
      case 'severe':
        return 'Severe Diabetic Retinopathy';
      default:
        return 'Unknown';
    }
  }

  /// Convenience method: given a raw disease label string, returns its
  /// severity string. Used by UI layers that only have the stored disease name.
  static String severityFromLabel(String label) => _buildSeverity(label);

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

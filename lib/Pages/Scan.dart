import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import './Results.dart';
import '../database/database_helper.dart';
import '../vision_classifier.dart';

class Scan extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  final String? address;
  final String? contactNumber;
  final String? dateOfBirth;
  final String? age;
  final String? gender;

  const Scan({
    super.key,
    this.patientName,
    this.patientId,
    this.address,
    this.contactNumber,
    this.dateOfBirth,
    this.age,
    this.gender,
  });

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  static const int _maxSelectedImages = 5;
  List<File> _selectedImages = [];
  int _selectedImageIndex = 0;
  bool get _hasSelection => _selectedImages.isNotEmpty;
  final VisionClassifier _visionClassifier = VisionClassifier();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Eye detection variables
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _eyeDetected = false;
  bool _canProcess = true;
  bool _isCameraStreamActive = false;
  int _consecutiveDetections = 0;
  int _frameCounter = 0;
  static const int _detectionThreshold = 3;
  static const int _frameSkip = 3; // process every 3rd frame to reduce GC pressure

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _initializeDetector();
    _setupCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });
  }

  void _initializeDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.05, // detect eyes even at very close range
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          _startImageStream();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null) return;
    _isCameraStreamActive = true;
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isCameraStreamActive || !_canProcess || !mounted) return;
      if (_isProcessing || _hasSelection) return;
      // Skip frames to reduce GC pressure from constant processing
      _frameCounter++;
      if (_frameCounter % _frameSkip != 0) return;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_canProcess || !_isCameraStreamActive) return;
    _isDetecting = true;

    try {
      bool eyeInFrame = false;

      // STEP 1: ML Kit Face/Eye Detection (works for normal-distance shots)
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        // Re-check after await — widget may have been disposed
        if (!mounted || !_isCameraStreamActive) return;
        if (faces.isNotEmpty) {
          for (Face face in faces) {
            final leftEye = face.landmarks[FaceLandmarkType.leftEye];
            final rightEye = face.landmarks[FaceLandmarkType.rightEye];
            if (leftEye != null || rightEye != null) {
              eyeInFrame = true;
              break;
            }
          }
        }
      }

      // STEP 2: Strict retina fallback for close-up/macro eye shots where
      // ML Kit cannot detect a whole face. Uses tighter thresholds than before
      // to prevent false positives on random objects.
      if (!eyeInFrame && _isCameraStreamActive) {
        eyeInFrame = _isRetinaLike(image);
      }

      // Final guard before touching state
      if (!mounted || !_isCameraStreamActive) return;

      if (eyeInFrame) {
        // Eye found: increment counter, only confirm after threshold
        _consecutiveDetections++;
        if (_consecutiveDetections >= _detectionThreshold && !_eyeDetected) {
          setState(() => _eyeDetected = true);
        }
      } else {
        // No eye: reset counter and immediately show warning
        _consecutiveDetections = 0;
        if (_eyeDetected) {
          setState(() => _eyeDetected = false);
        }
      }
    } catch (e) {
      debugPrint('Error detecting eyes: $e');
    } finally {
      _isDetecting = false;
    }
  }


  /// Strict retinal structure check — fallback for close-up/macro eye shots
  /// where ML Kit cannot see a full face. Thresholds are intentionally tight
  /// to avoid false positives on random objects.
  bool _isRetinaLike(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final Uint8List bytes = image.planes[0].bytes; // Y Plane (Luminance)

      // Focus on the central area of the frame
      int startY = height ~/ 4;
      int endY = 3 * height ~/ 4;
      int startX = width ~/ 4;
      int endX = 3 * width ~/ 4;

      int totalY = 0;
      int maxY = 0;
      int sampleCount = 0;
      int complexity = 0;

      for (int y = startY; y < endY; y += 10) {
        for (int x = startX; x < endX; x += 10) {
          int index = y * width + x;
          if (index < bytes.length) {
            int val = bytes[index];
            totalY += val;
            if (val > maxY) maxY = val;

            if (x > startX && y > startY) {
              int prevX = bytes[index - 10];
              int prevY = bytes[index - (width * 10)];
              int diff = (val - prevX).abs() + (val - prevY).abs();
              if (diff > 15) complexity++;
            }
            sampleCount++;
          }
        }
      }

      if (sampleCount == 0) return false;
      double avgY = totalY / sampleCount;

      // --- STRICT THRESHOLDS (tightened to reduce false positives) ---

      // 1. Strong localized highlight (optic disc): must be 50% brighter than avg
      bool hasOpticDisc = maxY > (avgY * 1.5) && maxY > 150;

      // 2. High texture complexity (retinal vessels): at least 12% of samples
      bool hasRetinalTexture = complexity > (sampleCount * 0.12);

      // 3. Strong dynamic range (dark background + bright disc)
      bool hasDynamicRange = (maxY - avgY) > 50;

      return hasOpticDisc && hasRetinalTexture && hasDynamicRange;
    } catch (e) {
      return false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameras![0].sensorOrientation;
    final InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.yuv420) || (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1 && Platform.isIOS) return null;
    if (image.planes.length != 3 && Platform.isAndroid) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  @override
  void dispose() {
    _canProcess = false;
    _isCameraStreamActive = false;
    // Stop the image stream immediately
    try { _cameraController?.stopImageStream(); } catch (_) {}
    // IMPORTANT: Delay closing the face detector to allow any in-flight
    // processImage() call to complete. Closing it immediately while awaiting
    // causes a null callback into libflutter.so → SIGSEGV crash.
    final detectorToClose = _faceDetector;
    Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
      try { detectorToClose.close(); } catch (_) {}
    });
    _animationController.dispose();
    _cameraController?.dispose();
    _visionClassifier.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    await _visionClassifier.loadModel();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _selectedImages = [File(file.path)];
        _selectedImageIndex = 0;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _processImage() async {
    if (!_hasSelection) return;

    try {
      setState(() {
        _isProcessing = true;
      });
      _animationController.forward();

      // Artificial delay to show the scanning animation
      await Future.delayed(const Duration(seconds: 3));

      // Process EACH selected image individually into independent result objects
      final Map<String, dynamic> outcome = await _processImagesIndividually(_selectedImages);
      final List<Map<String, dynamic>> validResults = outcome["validResults"] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> invalidResults = outcome["invalidResults"] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
      _animationController.stop();

      // 1. ALL SELECTED IMAGES ARE NON-RETINAL / INVALID
      if (validResults.isEmpty) {
        final invalidNames = invalidResults
            .map((r) => (r["file"] as File).path.split(RegExp(r'[/\\]')).last)
            .join(', ');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0B2239),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text("Invalid Image", style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              invalidResults.length == 1
                  ? "Please upload a valid retinal/fundus image. The selected image ($invalidNames) was determined to be non-retinal or invalid."
                  : "Please upload valid retinal/fundus images. The ${invalidResults.length} selected image(s) ($invalidNames) were determined to be non-retinal or invalid.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFF5ED3F2), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }

      // 2. MIXED SELECTION WARNING: Inform user per invalid image with exact filename references
      if (invalidResults.isNotEmpty) {
        final invalidNames = invalidResults
            .map((r) => (r["file"] as File).path.split(RegExp(r'[/\\]')).last)
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${invalidResults.length} non-retinal image(s) ($invalidNames) were rejected. Please upload valid retinal photos.',
            ),
            backgroundColor: Colors.orangeAccent[700],
          ),
        );
      }

      // 3. VALID RETINA RESULTS FLOW: Display valid results in Diagnostic Assessment sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final height = MediaQuery.of(context).size.height * 0.88;
          return SizedBox(
            height: height,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF011627),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: validResults.length == 1
                  ? ResultsContent(
                      disease: validResults[0]["disease"],
                      date: validResults[0]["date"],
                      imagePath: validResults[0]["imagePath"],
                      confidence: validResults[0]["confidence"],
                      patientName: widget.patientName,
                      patientId: widget.patientId,
                      address: widget.address,
                      contactNumber: widget.contactNumber,
                      dateOfBirth: widget.dateOfBirth,
                      age: widget.age,
                      gender: widget.gender,
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Evaluation Results (${validResults.length} Retinal Images)",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text(
                                "Swipe to view each image result",
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            itemCount: validResults.length,
                            itemBuilder: (context, index) {
                              final res = validResults[index];
                              return ResultsContent(
                                disease: res["disease"],
                                date: res["date"],
                                imagePath: res["imagePath"],
                                confidence: res["confidence"],
                                patientName: widget.patientName,
                                patientId: widget.patientId,
                                address: widget.address,
                                contactNumber: widget.contactNumber,
                                dateOfBirth: widget.dateOfBirth,
                                age: widget.age,
                                gender: widget.gender,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    }
  }

  /// Evaluates each selected image individually and routes invalid images directly to error handling,
  /// while preserving valid retina images into independent result objects.
  Future<Map<String, dynamic>> _processImagesIndividually(List<File> imageFiles) async {
    final List<Map<String, dynamic>> validResults = [];
    final List<Map<String, dynamic>> invalidResults = [];
    final dbHelper = DatabaseHelper();

    for (final file in imageFiles) {
      // 1. Evaluate ONLY the current image with VisionClassifier
      final result = _visionClassifier.predict(file);
      final bool isValid = result["isValid"] ?? false;
      final String disease = result["disease"] ?? "INVALID_OBJECT";
      final String severity = result["severity"] ?? "Unknown";
      final double confidence = result["confidence"] ?? 0.0;

      if (!isValid || disease == "INVALID_OBJECT") {
        // NON-RETINA / INVALID IMAGE:
        // Direct to invalid handling — preserve exact image/file reference
        invalidResults.add({
          "file": file,
          "imagePath": file.path,
          "disease": "INVALID_OBJECT",
          "severity": "Unknown",
          "confidence": 0.0,
          "isValid": false,
          "date": DateFormat('MMMM dd, yyyy').format(DateTime.now()),
        });
      } else {
        // VALID RETINA IMAGE:
        // Save current image file uniquely to persistent storage
        final String imagePath = await dbHelper.saveImage(file);

        // Save individual diagnosis record to SQLite database for THIS specific image
        await dbHelper.insertDiagnosis(
          disease,
          imagePath,
          confidence,
          patientName: widget.patientName,
          patientId: widget.patientId,
          address: widget.address,
          contactNumber: widget.contactNumber,
          dateOfBirth: widget.dateOfBirth,
          age: widget.age,
          gender: widget.gender,
        );

        // Create ONE individual result object attached to its exact imagePath and file
        validResults.add({
          "file": file,
          "imagePath": imagePath,
          "disease": disease,
          "severity": severity,
          "confidence": confidence,
          "isValid": true,
          "date": DateFormat('MMMM dd, yyyy').format(DateTime.now()),
        });
      }
    }

    return {
      "validResults": validResults,
      "invalidResults": invalidResults,
    };
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= _maxSelectedImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only select up to 5 images.')),
        );
      }
      return;
    }

    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 4000,
        maxHeight: 4000,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty && mounted) {
        final newFiles = pickedFiles.map((file) => File(file.path)).toList();
        final combined = List<File>.from(_selectedImages)..addAll(newFiles);
        if (combined.length > _maxSelectedImages) {
          final allowed = combined.sublist(0, _maxSelectedImages);
          setState(() {
            _selectedImages = allowed;
            if (_selectedImageIndex >= _selectedImages.length) {
              _selectedImageIndex = 0;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only the first 5 images were added.')),
          );
        } else {
          setState(() {
            _selectedImages = combined;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPatient = widget.patientName != null && widget.patientName!.isNotEmpty;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF12343B), // Deep Navy clinical camera enclosure
      appBar: AppBar(
        backgroundColor: const Color(0xFF12343B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Retinal Imaging Suite',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (hasPatient)
              Text(
                'Patient: ${widget.patientName}',
                style: const TextStyle(
                  color: Color(0xFF63C7B2),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFF203238), height: 1),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Clinical Camera Viewfinder / Image Frame
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1C20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D4B50), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image or Camera Preview
                              _hasSelection
                                  ? Image.file(_selectedImages[_selectedImageIndex], fit: BoxFit.cover)
                                  : _isCameraInitialized && _cameraController != null
                                      ? FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: _cameraController!.value.previewSize?.height ?? 1,
                                            height: _cameraController!.value.previewSize?.width ?? 1,
                                            child: CameraPreview(_cameraController!),
                                          ),
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                color: Color(0xFF63C7B2),
                                                strokeWidth: 2.5,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                "Initializing ophthalmic sensor...",
                                                style: TextStyle(color: Color(0xFFDCE8E5), fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),

                              // Clinical Reticle HUD Overlay
                              if (!_hasSelection) _buildGridOverlay(),

                              // Alignment Status Overlay (Top-Center)
                              if (!_hasSelection && _isCameraInitialized && !_isProcessing)
                                Positioned(
                                  top: 16,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: _eyeDetected
                                            ? const Color(0xFF3E9B78).withOpacity(0.9)
                                            : const Color(0xFFC95757).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _eyeDetected ? Icons.check_circle_outline : Icons.center_focus_weak,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _eyeDetected ? "RETINAL FIELD ALIGNED" : "POSITION RETINAL FIELD",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Scanning Laser Line
                              if (_isProcessing && _hasSelection)
                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: constraints.maxHeight * _scanAnimation.value,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF63C7B2).withOpacity(0.8),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ],
                                          color: const Color(0xFF63C7B2),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // Processing Analysis Overlay
                              if (_isProcessing)
                                Container(
                                  color: Colors.black.withOpacity(0.65),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFF63C7B2),
                                          strokeWidth: 3,
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          "Analyzing Retinal Biomarkers...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "Evaluating vascular integrity",
                                          style: TextStyle(
                                            color: Color(0xFFDCE8E5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              if (_hasSelection)
                _buildSelectedImagesPreview(),

              const SizedBox(height: 12),

              // Action Controls
              if (!_isProcessing)
                Column(
                  children: [
                    if (_hasSelection)
                      _buildMainButton(
                        icon: Icons.analytics_outlined,
                        label: "EVALUATE RETINA",
                        color: const Color(0xFF63C7B2),
                        textColor: const Color(0xFF12343B),
                        onTap: _processImage,
                      )
                    else
                      _buildMainButton(
                        icon: Icons.camera_alt_outlined,
                        label: "CAPTURE SCAN",
                        color: _eyeDetected ? const Color(0xFF63C7B2) : const Color(0xFF68777B),
                        textColor: _eyeDetected ? const Color(0xFF12343B) : Colors.white70,
                        onTap: _eyeDetected ? _takePicture : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please position camera to align with retinal field."),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryButton(
                            icon: Icons.photo_library_outlined,
                            label: 'pick_from_gallery'.tr(),
                            onTap: _pickImageFromGallery,
                          ),
                        ),
                        if (_hasSelection) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecondaryButton(
                              icon: Icons.refresh_rounded,
                              label: 'Retake',
                              onTap: () {
                                setState(() {
                                  _selectedImages.clear();
                                  _selectedImageIndex = 0;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const reticleColor = Color(0x5563C7B2);
        const bracketColor = Color(0xAA63C7B2);
        const bracketLen = 22.0;
        const bracketWidth = 2.0;

        return Stack(
          children: [
            // Center Ophthalmic Crosshairs
            Positioned(
              left: w / 2,
              top: h * 0.25,
              bottom: h * 0.25,
              child: Container(width: 1, color: reticleColor),
            ),
            Positioned(
              top: h / 2,
              left: w * 0.2,
              right: w * 0.2,
              child: Container(height: 1, color: reticleColor),
            ),
            // Central Circular Reticle Target (Fundus Zone)
            Center(
              child: Container(
                width: w * 0.65,
                height: w * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: reticleColor, width: 1.2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF63C7B2), width: 1.5),
                ),
              ),
            ),
            // Top-Left Bracket
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: bracketLen, height: bracketWidth, color: bracketColor),
                  Container(width: bracketWidth, height: bracketLen, color: bracketColor),
                ],
              ),
            ),
            // Top-Right Bracket
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: bracketLen, height: bracketWidth, color: bracketColor),
                  Container(width: bracketWidth, height: bracketLen, color: bracketColor),
                ],
              ),
            ),
            // Bottom-Left Bracket
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: bracketWidth, height: bracketLen, color: bracketColor),
                  Container(width: bracketLen, height: bracketWidth, color: bracketColor),
                ],
              ),
            ),
            // Bottom-Right Bracket
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: bracketWidth, height: bracketLen, color: bracketColor),
                  Container(width: bracketLen, height: bracketWidth, color: bracketColor),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedImagesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected ${_selectedImages.length}/$_maxSelectedImages scans',
                style: const TextStyle(color: Color(0xFFDCE8E5), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Tap thumbnail to inspect',
                style: TextStyle(color: Color(0xFF68777B), fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final bool isSelected = index == _selectedImageIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF63C7B2) : const Color(0xFF2D4B50),
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: textColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF0F262B),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF2D4B50), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF63C7B2)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

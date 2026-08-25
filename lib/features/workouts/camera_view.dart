import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/theme/theme.dart';

class CameraView extends StatefulWidget {
  final Function(InputImage inputImage) onImage;
  final Widget? overlay;

  const CameraView({
    super.key,
    required this.onImage,
    this.overlay,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = -1;
  bool _isProcessingFrame = false;

  // Frame Throttling: process 1 frame out of every N frames
  int _frameCount = 0;
  final int _processEveryNFrames = 3; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Default to front camera
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        _cameraIndex = i;
        break;
      }
    }
    
    // Fallback if no front camera
    if (_cameraIndex == -1) _cameraIndex = 0;

    await _startLiveFeed();
  }

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // Lower res for faster ML processing
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller?.initialize();
    if (!mounted) return;

    _controller?.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
    
    setState(() {}); // Show loading spinner
    await _startLiveFeed();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame) return;

    _frameCount++;
    if (_frameCount % _processEveryNFrames != 0) return; // Throttle

    _isProcessingFrame = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final camera = _cameras[_cameraIndex];
    
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    
    await widget.onImage(inputImage);
    
    _isProcessingFrame = false;
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        if (widget.overlay != null) widget.overlay!,
        Positioned(
          top: 50,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white24,
            onPressed: _flipCamera,
            child: const Icon(Icons.flip_camera_ios, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

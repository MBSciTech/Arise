import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

final poseDetectorProvider = Provider<PoseDetectorService>((ref) {
  return PoseDetectorService();
});

enum ExerciseType { squats, pushups }
enum WorkoutState { calibrating, tracking, lostTracking }
enum MovementPhase { top, bottom, unknown }

class PoseDetectorService {
  final PoseDetector _poseDetector;
  
  // State Machine
  WorkoutState _currentState = WorkoutState.calibrating;
  MovementPhase _currentPhase = MovementPhase.unknown;
  
  int repCount = 0;
  ExerciseType _exercise = ExerciseType.squats;
  
  // Debounce & Hysteresis
  DateTime? _lastRepTime;
  final Duration _repDebounce = const Duration(milliseconds: 300);
  
  // Calibration
  DateTime? _calibrationStartTime;
  final Duration _calibrationDuration = const Duration(seconds: 2);
  
  // Callback when a rep is completed successfully
  void Function()? onRepCompleted;
  
  PoseDetectorService() : _poseDetector = PoseDetector(options: PoseDetectorOptions()) {
    _lastRepTime = DateTime.now();
  }
  
  void setExercise(ExerciseType type) {
    _exercise = type;
    reset();
  }
  
  void reset() {
    repCount = 0;
    _currentState = WorkoutState.calibrating;
    _currentPhase = MovementPhase.unknown;
    _calibrationStartTime = null;
  }
  
  void dispose() {
    _poseDetector.close();
  }

  // Process image and return the pose and current workout state
  Future<(Pose?, WorkoutState)> processImage(InputImage inputImage) async {
    final poses = await _poseDetector.processImage(inputImage);
    
    if (poses.isEmpty) {
      _currentState = WorkoutState.lostTracking;
      return (null, _currentState);
    }
    
    final pose = poses.first;
    _evaluateState(pose);
    
    return (pose, _currentState);
  }
  
  void _evaluateState(Pose pose) {
    final bool isVisible = _checkLandmarkVisibility(pose);
    
    if (!isVisible) {
      _currentState = WorkoutState.lostTracking;
      _calibrationStartTime = null; // Reset calibration if they drop out
      return;
    }
    
    // If they are visible but were lost, or just starting
    if (_currentState == WorkoutState.lostTracking || _currentState == WorkoutState.calibrating) {
      _currentState = WorkoutState.calibrating;
      
      _calibrationStartTime ??= DateTime.now();
      
      if (DateTime.now().difference(_calibrationStartTime!) > _calibrationDuration) {
        _currentState = WorkoutState.tracking;
      }
      return;
    }
    
    // Active tracking
    if (_currentState == WorkoutState.tracking) {
      _countReps(pose);
    }
  }
  
  bool _checkLandmarkVisibility(Pose pose) {
    final double confidenceThreshold = 0.5;
    
    if (_exercise == ExerciseType.squats) {
      final hip = pose.landmarks[PoseLandmarkType.leftHip];
      final knee = pose.landmarks[PoseLandmarkType.leftKnee];
      final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
      
      if (hip == null || knee == null || ankle == null) return false;
      return hip.likelihood > confidenceThreshold && 
             knee.likelihood > confidenceThreshold && 
             ankle.likelihood > confidenceThreshold;
             
    } else if (_exercise == ExerciseType.pushups) {
      final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
      
      if (shoulder == null || elbow == null || wrist == null) return false;
      return shoulder.likelihood > confidenceThreshold && 
             elbow.likelihood > confidenceThreshold && 
             wrist.likelihood > confidenceThreshold;
    }
    return false;
  }
  
  void _countReps(Pose pose) {
    double angle = 0;
    double topThreshold = 0;
    double bottomThreshold = 0;
    
    if (_exercise == ExerciseType.squats) {
      angle = _getAngle(
        pose.landmarks[PoseLandmarkType.leftHip]!,
        pose.landmarks[PoseLandmarkType.leftKnee]!,
        pose.landmarks[PoseLandmarkType.leftAnkle]!
      );
      // Squat thresholds: Standing is ~170+, bottom is < 90
      topThreshold = 160.0;
      bottomThreshold = 100.0;
    } else if (_exercise == ExerciseType.pushups) {
      angle = _getAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder]!,
        pose.landmarks[PoseLandmarkType.leftElbow]!,
        pose.landmarks[PoseLandmarkType.leftWrist]!
      );
      // Pushup thresholds: Extended is ~160+, bottom is < 90
      topThreshold = 150.0;
      bottomThreshold = 90.0;
    }

    // Hysteresis State Machine
    if (angle < bottomThreshold) {
      _currentPhase = MovementPhase.bottom;
    } else if (angle > topThreshold && _currentPhase == MovementPhase.bottom) {
      // Debounce check
      final now = DateTime.now();
      if (_lastRepTime == null || now.difference(_lastRepTime!) > _repDebounce) {
        repCount++;
        _lastRepTime = now;
        _currentPhase = MovementPhase.top;
        if (onRepCompleted != null) onRepCompleted!();
      }
    }
  }

  double _getAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    double result =
        math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);
    result = result * (180.0 / math.pi);
    result = result.abs();
    if (result > 180.0) {
      result = 360.0 - result;
    }
    return result;
  }
}

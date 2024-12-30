
// ignore_for_file: prefer_const_declarations, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fyp/providers/location_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class DetectionService extends ChangeNotifier {
// Add ValueNotifier for blinking icon visibility
  final ValueNotifier<bool> isDetectionActive = ValueNotifier(false);

  CameraController? _cameraController;
  late FlutterVision _vision;
  bool _isDetecting = false;

  late DateTime startTime; // Track start time
  late DateTime endTime;   // Track end time

  // Detection-specific variables
  int _blinkCount = 0;
  int _yawnCount = 0;
  int _sleepCount = 0;
  int _eyeCloseDuration = 0;
  int _mouthOpenFrames = 0;
  int _noFaceDuration = 0;
  bool _isCooldown = false;

  // Emergency state variables
  bool _hasTriggeredSleep = false;
  bool _isInEmergencyState = false;
  DateTime? _lastEmailSent;
  static const int EMAIL_COOLDOWN_DURATION = 300; // 5 minutes

  // Alarm handling
  bool _isAlarmPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _detectionTimer;

  // Configurable thresholds
  static const int ALERT_THRESHOLD = 30; // 2 seconds (assuming ~15 FPS)
  static const int EYE_CLOSURE_THRESHOLD = 75;
  static const int NO_FACE_THRESHOLD = 75;
  static const int YAWN_FRAMES_THRESHOLD = 15;
  static const int COOLDOWN_SECONDS = 10;

  // Getters for state
  CameraController? get cameraController => _cameraController;
  int get blinkCount => _blinkCount;
  int get yawnCount => _yawnCount;
  int get sleepCount => _sleepCount;
  bool get isDetecting => _isDetecting;
  
  bool _isStreaming = false;

/*
  Future<void> initialize() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );

    _vision = FlutterVision();
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController.initialize();
    await _vision.loadYoloModel(
      labels: 'lib/models/labels.txt',
      modelPath: 'lib/models/best_float32.tflite',
      modelVersion: "yolov8",
      numThreads: 4,
      useGpu: true,
    );

    notifyListeners();
  }
  */

 Future<void> initialize() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );

    _vision = FlutterVision();
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController?.initialize(); // Use null-aware operator
      await _vision.loadYoloModel(
        labels: 'lib/models/labels.txt',
        modelPath: 'lib/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 4,
        useGpu: true,
      );
    } catch (e) {
      debugPrint("Error initializing camera or YOLO model: $e");
      _cameraController = null; // Reset if initialization fails
    }

    notifyListeners();
  }



Future<void> startDetection(BuildContext context) async {
  if (_isDetecting || _isStreaming) {
    debugPrint("Detection is already in progress or camera is streaming.");
    return;
  }
  
  // Check if the camera controller is initialized
  if (_cameraController == null || !(_cameraController?.value.isInitialized ?? false)) {
    debugPrint("Camera controller is not initialized. Aborting detection start.");
    return;
  }

  // Check if the camera is already streaming images
  if (_cameraController?.value.isStreamingImages ?? false) {
    debugPrint("Camera is already streaming images. Cannot start a new stream.");
    return;
  }

  // Set the blinking icon to active
    isDetectionActive.value = true;

  _isStreaming = true;
  _isDetecting = true;

  startTime = DateTime.now(); // Record start time


  final int frameIntervalMs = 1000 ~/ 15; // 1000 milliseconds divided by 15 frames per second
  DateTime lastFrameTime = DateTime.now();

  try {
    _cameraController?.startImageStream((image) async {
      final now = DateTime.now();
      if (now.difference(lastFrameTime).inMilliseconds < frameIntervalMs) {
        // Skip frames to maintain the target FPS
        return;
      }
      lastFrameTime = now;

      final results = await _vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.5,
        confThreshold: 0.5,
        classThreshold: 0.4,
      );

      debugPrint("YOLO Results: $results");
      _handleDetectionResults(results, context);
    });
  } catch (e) {
    debugPrint("Error starting image stream: $e");
    _isStreaming = false;
  }

  notifyListeners();
}




  Future<void> stopDetection() async {
  if (!_isStreaming) {
    debugPrint("No active streaming to stop.");
    return;
  }

  // Set the blinking icon to active
    isDetectionActive.value = false;

  _isDetecting = false;
  _detectionTimer?.cancel();
  endTime = DateTime.now(); // Record end time


  try {
    await _cameraController?.stopImageStream();
  } catch (e) {
    debugPrint("Error stopping image stream: $e");
  } finally {
    _isStreaming = false;  // Ensure this flag is reset regardless of success or failure
  }

  // Store detection data to Firestore
    await storeDetectionData();

  _resetDetectionState();
  notifyListeners();
}


  void _handleDetectionResults(List<Map<String, dynamic>> results, BuildContext context) {
    final hasFace = results.any((item) => item['tag'] == 'face');
    final hasEyeClosed = results.any((item) => item['tag'] == 'eye_closed');
    final hasMouthOpen = results.any((item) => item['tag'] == 'mouth_open');
    final hasEyeOpen = results.any((item) => item['tag'] == 'eye_open');


    debugPrint("YOLO Results: $results");

    if (results.isEmpty) {
      _handleNoFaceDetected();
    } else if (hasFace) {
      _handleFaceDetected(hasEyeClosed, hasMouthOpen,hasEyeOpen);
    } else {
      _handleNoFaceDetected();
    }

    _checkForEmergencyConditions(context);
    notifyListeners();
  }

  void _handleFaceDetected(bool hasEyeClosed, bool hasMouthOpen,bool hasEyeOpen) {
    _noFaceDuration = 0;

    if (hasEyeClosed) {
      _eyeCloseDuration++;
      if (_eyeCloseDuration >= ALERT_THRESHOLD && !_hasTriggeredSleep) {
        _triggerSleepEvent();
      }
    } else if(hasEyeOpen){
      if (_eyeCloseDuration > 0 && _eyeCloseDuration < ALERT_THRESHOLD) {
        _blinkCount++;
      }
      _eyeCloseDuration = 0;
    }
    else if(!hasEyeClosed && !hasEyeOpen && _eyeCloseDuration > 0)
    {
      _eyeCloseDuration++;
    }

    if (hasMouthOpen) {
      _mouthOpenFrames++;
      if (_mouthOpenFrames >= YAWN_FRAMES_THRESHOLD && !_isCooldown) {
        _yawnCount++;
        _startCooldown();
      }
    } else {
      _mouthOpenFrames = 0;
    }
  }

  void _handleNoFaceDetected() {
    _noFaceDuration++;

    // Continue counting eyeCloseDuration and mouthOpenFrames even if no face is detected
    if(_eyeCloseDuration > 0){
      _eyeCloseDuration++;
    }

    if (_mouthOpenFrames > 0) {
    _mouthOpenFrames++; // Continue counting if mouth was previously open
  }

    if (_noFaceDuration >= ALERT_THRESHOLD && !_hasTriggeredSleep) {
      _triggerSleepEvent();
    }
  }

  void _checkForEmergencyConditions(BuildContext context) async {
    if (_eyeCloseDuration >= EYE_CLOSURE_THRESHOLD || _noFaceDuration >= NO_FACE_THRESHOLD) {
      if (!_isInEmergencyState) {
        _isInEmergencyState = true;
        _playAlarm();
        _sleepCount++;

        if (_canSendEmail()) {
          await _sendEmergencyEmail(context);
        }
      }
    } else {
      _isInEmergencyState = false;
      _stopAlarm();
    }
  }

  void _triggerSleepEvent() {
    _playAlarm();
    _hasTriggeredSleep = true;
  }

  void _startCooldown() {
    _isCooldown = true;
    Timer(Duration(seconds: COOLDOWN_SECONDS), () {
      _isCooldown = false;
    });
  }

  bool _canSendEmail() {
    return _lastEmailSent == null ||
        DateTime.now().difference(_lastEmailSent!).inSeconds >= EMAIL_COOLDOWN_DURATION;
  }

  Future<void> _sendEmergencyEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final contactSnapshot = await FirebaseFirestore.instance
          .collection('EmergencyContact')
          .doc(user.uid)
          .get();

      final emergencyEmail = contactSnapshot.data()?['contactEmail'] ?? '';
      final emergencyName = contactSnapshot.data()?['contactName'] ?? '';

      if (emergencyEmail.isEmpty) return;

      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final currentLocation = locationProvider.currentLocation;

      if (currentLocation == null) return;

      final address = await locationProvider.getAddressFromCoordinates(
        currentLocation.latitude,
        currentLocation.longitude,
      );

      String smtpPassword = '';

    if(user.email == "wongsx-pm21@student.tarc.edu.my"){
      smtpPassword = 'bsgq bipm tako zans';
    }
    else if(user.email == 'jessietan431@gmail.com'){
      smtpPassword = 'kfkj ovgt xmdj mdli'; 
    }
    else if(user.email == 'wongxuansau2012@gmail.com'){
      smtpPassword = 'grbb fyag zrwv nstb';
    }


      final smtpServer = gmail(user.email!, smtpPassword); // Use a valid password
      final message = Message()
        ..from = Address(user.email!, "Drowsiness Detection System")
        ..recipients.add(emergencyEmail)
        ..subject = "Driver Drowsiness Alert"
        ..text = '''
        Hi $emergencyName,

        The driver ${user.email} is showing signs of danger:
        - Danger Type: ${_noFaceDuration >= ALERT_THRESHOLD ? "No face detected" : "Excessive eye closure"}
        - Address: ${address ?? "Unknown"}
        - Location: Latitude: ${currentLocation.latitude}, Longitude: ${currentLocation.longitude}

        Please take necessary actions immediately.
        ''';

      await send(message, smtpServer);
      _lastEmailSent = DateTime.now();
    } catch (e) {
      print("Failed to send email: $e");
    }
  }

  void _playAlarm() async {
    if (!_isAlarmPlaying) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource("alarm/Danger_Alarm_Sound_Effect.mp3"));
      _isAlarmPlaying = true;
    }
  }

  void _stopAlarm() async {
    if (_isAlarmPlaying) {
      await _audioPlayer.stop();
      _isAlarmPlaying = false;
    }
  }

  void _resetDetectionState() {
    _blinkCount = 0;
    _yawnCount = 0;
    _sleepCount = 0;
    _eyeCloseDuration = 0;
    _mouthOpenFrames = 0;
    _noFaceDuration = 0;
    _isCooldown = false;
    _hasTriggeredSleep = false;
    _isInEmergencyState = false;
    _stopAlarm();
  }

  Future<void> storeDetectionData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("User not logged in.");
      return;
    }

    // Calculate duration in seconds
    final duration = endTime.difference(startTime).inSeconds;

    // Construct the data to be stored
    final detectionData = {
      'blinkingCount': blinkCount,
      'yawnCount': yawnCount,
      'sleepCount': sleepCount,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationDetection': duration,
      'userID': user.uid,
    };

    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('DrowsinessDetectionHistory')
          .add(detectionData);
      print("Detection data stored successfully.");
    } catch (e) {
      print("Error storing detection data: $e");
    }
  }


  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _vision.closeYoloModel();
    _audioPlayer.dispose();
    super.dispose();
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

List<CameraDescription>? cameras;

void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  FlutterVision vision = FlutterVision();
  CameraController? controller;
  final AudioPlayer audioPlayer = AudioPlayer();

  // Load Cameras
  if (cameras == null) {
    cameras = await availableCameras();
  }

  // Select the front camera
  CameraDescription frontCamera = cameras!.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras![0], // Fallback to the first camera if no front camera is available
  );

  controller = CameraController(
    frontCamera,
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );

  await controller.initialize();

  await vision.loadYoloModel(
    labels: 'lib/models/labels.txt',
    modelPath: 'lib/models/best_float32.tflite',
    modelVersion: "yolov8",
    numThreads: 4,
    useGpu: true,
  );

  // Starting to process images in the background
  controller.startImageStream((CameraImage image) async {
    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.5,
      confThreshold: 0.5,
      classThreshold: 0.4,
    );

    debugPrint("YOLO Results: $result");

    bool hasFace = result.any((item) => item['tag'] == 'face');
    bool hasEyeClosed = result.any((item) => item['tag'] == 'eye_closed');

    // Logic to handle the results and trigger alarms, email sending, etc.
    if (!hasFace || hasEyeClosed) {
      playAlarm(audioPlayer);
      handleEmergencyCondition();
    } else {
      stopAlarm(audioPlayer);
    }
  });
}

void playAlarm(AudioPlayer audioPlayer) async {
  String audioPath = "alarm/Danger_Alarm_Sound_Effect.mp3";
  await audioPlayer.setReleaseMode(ReleaseMode.loop);
  await audioPlayer.play(AssetSource(audioPath));
}

void stopAlarm(AudioPlayer audioPlayer) async {
  await audioPlayer.stop();
}

Future<void> handleEmergencyCondition() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final contactSnapshot = await FirebaseFirestore.instance
        .collection('EmergencyContact')
        .doc(user.uid)
        .get();

    if (!contactSnapshot.exists) return;

    final emergencyEmail = contactSnapshot.data()?['contactEmail'] ?? '';
    final emergencyName = contactSnapshot.data()?['contactName'] ?? '';

    if (emergencyEmail.isEmpty) return;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    final userName = userSnapshot.data()?['name'] ?? 'Unknown User';
    final userEmail = userSnapshot.data()?['email'] ?? 'Unknown Email';

    final smtpUsername = userEmail;
    String smtpPassword = ''; // Set this securely

    final smtpServer = gmail(smtpUsername, smtpPassword);
    final message = Message()
      ..from = Address(smtpUsername, 'Drowsiness Detection System')
      ..recipients.add(emergencyEmail)
      ..subject = 'Driver Drowsiness Alert'
      ..text = '''
    Hi $emergencyName,
    The driver $userName is showing signs of danger.
    Please take necessary actions immediately.
    Regards,
    NavSafe
    ''';

    await send(message, smtpServer);
  } catch (e) {
    print("Error sending email: $e");
  }
}

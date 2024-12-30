
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp/services/drowsiness_detection_service.dart';
import 'package:fyp/common_widgets.dart';
import 'package:camera/camera.dart';

class DrowsinessDetectionPage extends StatefulWidget {
  const DrowsinessDetectionPage({Key? key}) : super(key: key);

  @override
  State<DrowsinessDetectionPage> createState() =>
      _DrowsinessDetectionPageState();
}

class _DrowsinessDetectionPageState extends State<DrowsinessDetectionPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 2;

/*
  @override
void initState() {
  super.initState();
  Future.microtask(() async {
    try {
      await Provider.of<DetectionService>(context, listen: false).initialize();
      setState(() {}); // Rebuild the widget once initialization completes
    } catch (e) {
      debugPrint("Error during initialization: $e");
    }
  });
}
*/
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe lifecycle changes
    Future.microtask(() async {
      try {
        await Provider.of<DetectionService>(context, listen: false).initialize();
        setState(() {}); // Rebuild the widget once initialization completes
      } catch (e) {
        debugPrint("Error during initialization: $e");
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop observing lifecycle
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final detectionService = Provider.of<DetectionService>(context, listen: false);

    if (state == AppLifecycleState.resumed) {
      // Resume camera when app returns to the foreground
      if (!detectionService.cameraController!.value.isStreamingImages) {
        detectionService.startDetection(context);
      }
    } else if (state == AppLifecycleState.paused) {
      // Pause camera when app moves to the background
      detectionService.stopDetection();
    }
  }


  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);

   /*
  if (!detectionService.cameraController.value.isInitialized) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  */
  // Safely check if the camera controller is initialized
    if (detectionService.cameraController == null ||
        !(detectionService.cameraController?.value.isInitialized ?? false)) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Drowsiness Detection"),
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            child: Container(
              color: Colors.black,
              child: AspectRatio(
                /*
                aspectRatio: detectionService.cameraController?.value.aspectRatio,
                child: CameraPreview(detectionService.cameraController),
                */
                aspectRatio: detectionService.cameraController?.value.aspectRatio ?? 1.0,
                child: CameraPreview(detectionService.cameraController!),
              ),
            ),
          ),

          // Detection Metrics and Start/Stop Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  "Blinks: ${detectionService.blinkCount}, "
                  "Yawns: ${detectionService.yawnCount}, "
                  "Sleeps: ${detectionService.sleepCount}",
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    backgroundColor: detectionService.isDetecting
                        ? Colors.red
                        : Colors.green,
                  ),
                  onPressed: detectionService.isDetecting
                      ? () => detectionService.stopDetection()
                      : () => detectionService.startDetection(context),
                  child: Text(
                    detectionService.isDetecting ? "STOP DETECT" : "START DETECT",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Custom Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: (index) => _onItemTapped(index),
        currentIndex: _selectedIndex,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/account');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/drowsiness');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/emergency');
        break;
    }
  }
}



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationPage extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destination;
  final String placeName; // Added to hold place name
  final String address;   // Added to hold address

  const NavigationPage({
    Key? key,
    required this.currentLocation,
    required this.destination,
    required this.placeName,
    required this.address,
  }) : super(key: key);

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  MapBoxNavigationViewController? _controller;
  FlutterTts _tts = FlutterTts();
  bool _isNavigating = false;
  bool _routeBuilt = false;
  bool _arrived = false;
  String? _instruction;
  String? _lastInstruction;
  double? _distanceRemaining, _durationRemaining;
  late MapBoxOptions _navigationOption;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double? _currentSpeedKmh; // Speed in km/h
double? _previousDistanceRemaining;
DateTime? _lastProgressUpdate;

  Future<void> initialize() async {
    if (!mounted) return;

    _navigationOption = MapBoxNavigation.instance.getDefaultOptions();
    _navigationOption.initialLatitude = widget.currentLocation.latitude;
    _navigationOption.initialLongitude = widget.currentLocation.longitude;
    _navigationOption.mode = MapBoxNavigationMode.driving;
    MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

    // Save navigation data to Firestore
    await _storeNavigationData();
  }

  Future<void> _storeNavigationData() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in.");
      return;
    }

    final navigationData = {
      'placeName': widget.placeName,
      'address': widget.address,
      'location': GeoPoint(widget.destination.latitude, widget.destination.longitude),
      'userID': FirebaseFirestore.instance.collection('Users').doc(user.uid),
      'addedTime': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('NavigationHistory').add(navigationData);
      print("Navigation data stored successfully.");
    } catch (e) {
      print("Error storing navigation data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tts.stop();
    super.dispose();
  }


  Future<void> _onRouteEvent(e) async {
    _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
    _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

    switch (e.eventType) {
      case MapBoxEvent.route_built:
        print("Route built. Starting navigation...");
        _controller?.startNavigation();
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.navigation_running:
        print("Navigation is running.");
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived ?? false;

        // Get speed during progress update
        await _getSpeed();

        if (progressEvent.currentStepInstruction != null) {
          _instruction = progressEvent.currentStepInstruction;
          if (_instruction != _lastInstruction) {
            _lastInstruction = _instruction;
            //await _announceInstruction(_instruction!);
          }
        }
        break;
      case MapBoxEvent.on_arrival:
        _arrived = true;
        print("You have arrived at your destination.");
        await _showArrivalDialog();
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        print("Navigation finished or cancelled.");
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }

    setState(() {});
  }

 /// Get speed in km/h and update the state
Future<void> _getSpeed() async {
  try {
    if (_controller != null) {
      // Retrieve distance and time differences for speed calculation
      final distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();

      if (distanceRemaining != null && _lastProgressUpdate != null && _previousDistanceRemaining != null) {
        // Calculate time difference in seconds
        final now = DateTime.now();
        final timeElapsed = now.difference(_lastProgressUpdate!).inSeconds;

        if (timeElapsed > 0) {
          final distanceCovered = (_previousDistanceRemaining! - distanceRemaining).abs(); // Distance in meters
          final speedMps = distanceCovered / timeElapsed; // Speed in m/s
          _currentSpeedKmh = speedMps * 3.6; // Convert to km/h
        }

        // Update previous state
        _previousDistanceRemaining = distanceRemaining;
        _lastProgressUpdate = now;
      }
    }
  } catch (e) {
    print("Error calculating speed: $e");
  }
}

 

  Future<void> _announceInstruction(String instruction) async {
    await _tts.stop();
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.speak(instruction);
  }

  Future<void> _showArrivalDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Arrival"),
        content: Text("You have successfully arrived at your destination."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _exitNavigation() {
    _controller?.finishNavigation();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: MapBoxNavigationView(
                  options: _navigationOption,
                  onRouteEvent: _onRouteEvent,
                  onCreated: (MapBoxNavigationViewController controller) async {
                    _controller = controller;
                    await controller.initialize();
                    await controller.buildRoute(
                      wayPoints: [
                        WayPoint(
                          name: "Current Location",
                          latitude: widget.currentLocation.latitude,
                          longitude: widget.currentLocation.longitude,
                        ),
                        WayPoint(
                          name: "Destination",
                          latitude: widget.destination.latitude,
                          longitude: widget.destination.longitude,
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_routeBuilt && !_isNavigating)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _controller?.startNavigation();
                    },
                    child: Text("Start Navigation"),
                  ),
                ),
              if (_isNavigating && !_arrived)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_instruction != null) Text("Instruction: $_instruction"),
                      if (_distanceRemaining != null && _durationRemaining != null)
                        Text(
                          "Remaining Distance: ${_distanceRemaining!.toStringAsFixed(2)} meters | Duration: ${_durationRemaining!.toStringAsFixed(2)} mins",
                        ),
                    ],
                  ),
                ),
                // Speed Display
                    if (_currentSpeedKmh != null)
                      Text(
                        "Speed: ${_currentSpeedKmh!.toStringAsFixed(2)} km/h",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ],
          ),
          Positioned(
            bottom: 75,
            right: 10,
            width: 80,
            child: FloatingActionButton(
              onPressed: _exitNavigation,
              child: Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

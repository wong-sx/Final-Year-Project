// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // Import Geocoding package
import '../services/location_service.dart';
import '../services/map_service.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  GoogleMapController? _mapController;
  Marker? _currentLocationMarker;
  Marker? _destinationMarker;
  Polyline? _routePolyline;
  String? distance;
  String? duration;

  List<Marker> _searchMarkers = [];
  List<dynamic> _searchResults = [];

  GoogleMapController? get mapController => _mapController;
  Marker? get currentLocationMarker => _currentLocationMarker;
  Marker? get destinationMarker => _destinationMarker;
  Polyline? get routePolyline => _routePolyline;
  String? get travelDistance => distance;
  String? get travelDuration => duration;
  List<Marker> get searchMarkers => _searchMarkers;
  List<dynamic> get searchResults => _searchResults;
  LatLng? get currentLocation => _currentLocationMarker?.position;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> updateCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      _currentLocationMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );

      notifyListeners();
    } catch (e) {
      print('Could not retrieve location: $e');
    }
  }

  // Method to get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print('Error in getting address: $e');
    }
    return null;
  }

  Future<void> searchLocation(String query) async {
    try {
      final results = await _mapService.searchPlace(query);
      _searchResults = results.take(10).toList();

      _searchMarkers.clear();
      for (var result in _searchResults) {
        final location = LatLng(
          result['geometry']['location']['lat'],
          result['geometry']['location']['lng'],
        );
        _searchMarkers.add(
          Marker(
            markerId: MarkerId(result['place_id']),
            position: location,
            infoWindow: InfoWindow(title: result['name']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error in search: $e');
      throw e;
    }
  }

  void selectSearchResult(int index) {
    if (index < 0 || index >= _searchResults.length) return;

    final result = _searchResults[index];
    final location = LatLng(
      result['geometry']['location']['lat'],
      result['geometry']['location']['lng'],
    );

    _searchMarkers.clear();
    _destinationMarker = Marker(
      markerId: MarkerId('selectedLocation'),
      position: location,
      infoWindow: InfoWindow(title: result['name']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));

    getRouteToDestination(location);
  }

  Future<void> getRouteToDestination(LatLng destination) async {
    try {
      final position = await _locationService.getCurrentLocation();
      final origin = LatLng(position.latitude, position.longitude);
      final directions = await _mapService.getDirections(origin, destination);

      final polylinePoints = decodePolyline(directions['polyline']).map((point) {
        return LatLng(point[0].toDouble(), point[1].toDouble());
      }).toList();

      _routePolyline = Polyline(
        polylineId: PolylineId('route'),
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
      );

      distance = directions['distance'];
      duration = directions['duration'];

      notifyListeners();
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void clearRoute() {
    _destinationMarker = null;
    _routePolyline = null;
    distance = null;
    duration = null;
    notifyListeners();
  }
}

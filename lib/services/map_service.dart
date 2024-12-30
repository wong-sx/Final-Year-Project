import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final String _apiKey = 'AIzaSyCtFrTIeSaWI9LLbfVDMJwmrMILvlggbHk';

  /// Searches for places based on a text query.
   Future<List<dynamic>> searchPlace(String query) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polylinePoints = route['overview_polyline']['points'];
        final legs = route['legs'][0];
        final distance = legs['distance']['text'];
        final duration = legs['duration']['text'];
        
        return {
          'polyline': polylinePoints,
          'distance': distance,
          'duration': duration,
        };
      } else {
        throw Exception('No routes found');
      }
    } else {
      throw Exception('Failed to load directions');
    }
  }
}

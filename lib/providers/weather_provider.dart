// weather_provider.dart

import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _currentWeather;
  bool _isLoading = false;

  Map<String, dynamic>? get weather => _currentWeather;
  bool get isLoading => _isLoading;

  Future<void> fetchWeather(double latitude, double longitude) async {
    print("fetchWeather called with latitude: $latitude, longitude: $longitude"); // Add this line
    _isLoading = true;
    notifyListeners();

    final fetchedWeather = await _weatherService.fetchWeather(latitude, longitude);

    if (fetchedWeather != null) {
      _currentWeather = fetchedWeather;
    } else {
      print("No weather data received from API");
    }

    _isLoading = false;
    notifyListeners();
  }
}

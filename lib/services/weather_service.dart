// weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Place your OpenWeatherMap API key here
  static const String _apiKey = "1cf69c94062eb312532f2dd62762a10f";

  Future<Map<String, dynamic>?> fetchWeather(double latitude, double longitude) async {
  try {
    final url = Uri.parse('https://api.openweathermap.org/data/3.0/onecall?lat=$latitude&lon=$longitude&exclude=minutely,hourly,daily,alerts&appid=$_apiKey');
    final response = await http.get(url);

    print("Weather API Response Status: ${response.statusCode}");
    print("Weather API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print("Weather API error: ${response.statusCode}");
    }
  } catch (e) {
    print("Failed to fetch weather data: $e");
  }
  return null;
}
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fyp/common_widgets.dart';
import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  WeatherFactory wf = WeatherFactory("1cf69c94062eb312532f2dd62762a10f");
  Weather? _currentWeather;
 List<Weather>? _dailyForecast;
List<Weather>? _hourlyForecast;
bool _isPermissionDenied = false;




   int _selectedIndex = 4;
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
      case 4:
        Navigator.pushReplacementNamed(context, '/weather');
        break;
    }
  }


  @override
  void initState() {
    super.initState();
     _dailyForecast = [];
  _hourlyForecast = [];
   // _loadWeather();
    //_determinePosition();
     _checkAndLoadWeather();
  }



void _loadWeather() async {
  try {
    Position position = await _determinePosition();
    await _getCurrentWeather(position);
    await _getDailyForecast(position);
    await _getHourlyForecast(position);
  } catch (error) {
    // Handle errors (e.g., permission denied, service disabled)
    print('Error loading weather data: $error');
  }
}

  void _checkAndLoadWeather() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    setState(() {
      _isPermissionDenied = true;
    });
  } else {
    _loadWeather();
   // _determinePosition();
  }
}

 

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
       if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
    setState(() => _isPermissionDenied = true);
    return Future.error('Location permissions are denied');
  }
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    } 
setState(() {
    _isPermissionDenied = false; // Reset the flag when permissions are granted
  });
    return await Geolocator.getCurrentPosition();
  }
  _getCurrentWeather(Position position) async {
    Weather weather = await wf.currentWeatherByLocation(position.latitude, position.longitude);
     
    
    setState(() {
      _currentWeather = weather;
     
    });
  }

 _getDailyForecast(Position position) async {
  List<Weather> forecast = await wf.fiveDayForecastByLocation(position.latitude, position.longitude);
  
  var dailyForecast = <Weather>{};

  // Use a Set to track unique dates
  var seenDates = Set<String>();

  // Iterate over the forecast and add the first occurrence of a forecast for each day
  for (var weather in forecast) {
    String date = DateFormat('yyyy-MM-dd').format(weather.date!);
    if (!seenDates.contains(date)) {
      seenDates.add(date);
      dailyForecast.add(weather);
    }
  }

  setState(() {
    _dailyForecast = dailyForecast.toList();
  });
}

_getHourlyForecast(Position position) async {
  List<Weather> forecast = await wf.fiveDayForecastByLocation(position.latitude, position.longitude);
  setState(() {
    _hourlyForecast = forecast;
  });
}




// Update _getWeatherIcon function to handle the 'Unknown' case or any other unexpected weather condition
Widget _getWeatherIcon(String? condition) {
  switch (condition) {
    case 'Clear':
      return Icon(Icons.wb_sunny, color: Colors.yellow);
    case 'Clouds':
      return Icon(Icons.wb_cloudy, color: Colors.blue);
    case 'Rain':
      return Image.asset('assets/rain.png', width: 24, height: 24);
    default:
      return Icon(Icons.error);
  }
}

_requestPermission() async {
  setState(() {
    _isPermissionDenied = false; // Reset the flag to hide the message
  });

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    // Inform the user they need to enable permission from the app settings
    await Geolocator.openAppSettings();
  } else {
    // Permissions are already granted, load the weather
    _loadWeather();
  }
}

  @override
  Widget build(BuildContext context) {
    
 if (_isPermissionDenied) {
    // Show the message to enable location service
    return Scaffold(
       appBar: AppBar(
         title: Text(
    'Weather Information',
    style: TextStyle(color: Colors.white,fontSize: 20), // Set the text color to white
  ),
  centerTitle: true, // Center the title
  automaticallyImplyLeading: false, // Removes the back button
  backgroundColor: const Color(0xFF04CD73),
      ),
      body: Center(
         child: Padding(
    padding: EdgeInsets.all(20.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please enable location service and grant permission in your device settings to use this feature.',
              style: TextStyle(fontSize: 14), textAlign: TextAlign.center,),
            ElevatedButton(
              onPressed: () {
                _requestPermission(); // Call this function when the button is pressed
              },
              child: Text('Setting'),
            ),
          ],
        ),
        ),
      ),
       bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: _onItemTapped,
          currentIndex: _selectedIndex,
      )
    );
  }
    return Scaffold(
      /* appBar: CommonAppBar(
        title: 'Weather Information',
      ),*/
      appBar: AppBar(
         title: Text(
    'Weather Information',
    style: TextStyle(color: Colors.white,fontSize: 20), // Set the text color to white
  ),
  centerTitle: true, // Center the title
  automaticallyImplyLeading: false, // Removes the back button
  backgroundColor: Colors.blue, // Set the
      ),
      body: SingleChildScrollView(
     child: Container(
         decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
         // colors: [Colors.lightBlueAccent, Colors.white],
          colors: [Colors.blue, Colors.white],
           stops: [0.3, 1.0], // Adjust these values
        ),
      ),
    /* decoration: BoxDecoration(
  color: Color.fromARGB(255, 197, 225, 238), // Set the color to light blue
),*/
        child: Padding( // Add padding around the main content
        padding: EdgeInsets.all(10.0), 
        child: Column(
          children: [
         
 if (_currentWeather != null) ...[
  Container(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        Center( // Center the location name horizontally
          child: Text(
            _currentWeather!.areaName ?? 'Location',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // Align the icon and temperature to the right
          children: [
            Text(
              "${_currentWeather!.temperature?.celsius?.toStringAsFixed(1) ?? 'N/A'}°C",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5), // Space between temperature and icon
            Image.network(
              'http://openweathermap.org/img/w/${_currentWeather!.weatherIcon}.png',
              scale: 0.5,
            ),
          ],
        ),
        Text(
                  'High: ${_currentWeather!.tempMax?.celsius?.toStringAsFixed(1)}°  Low: ${_currentWeather!.tempMin?.celsius?.toStringAsFixed(1)}°',
                  style: TextStyle(fontSize: 18),
                ),
                
        Text(
          _currentWeather!.weatherDescription ?? 'Weather',
          style: TextStyle(fontSize: 18),
        ),
      ],
    ),
  ),
    // Space after current weather
  //Divider(color: Colors.grey.shade300, thickness: 1),  // Light grey horizontal line
],


 Padding(
            padding: EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    top: 1.0,
    bottom: 5.0,
  ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Weather Details',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

Container(
   margin: EdgeInsets.symmetric(horizontal: 4),
  padding: EdgeInsets.fromLTRB(5,10,5,10), // Add padding inside the container
  decoration: BoxDecoration(
    color: Color.fromARGB(255, 243, 247, 249), // Background color
    borderRadius: BorderRadius.circular(8), // Border radius
  ),
  child: Column(


  children: [
    // First row: Wind Speed, Humidity, Chance of Rain
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
            children: [
              Icon(Icons.air, size: 24, color: Colors.blue),
              Text('${_currentWeather?.windSpeed?.toStringAsFixed(1) ?? 'N/A'} km/h'),
              Text('Wind Speed'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Icon(Icons.opacity, size: 24, color: Colors.blue),
              Text('${_currentWeather?.humidity?.toString() ?? 'N/A'}%'),
              Text('Humidity'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Icon(Icons.umbrella, size: 24, color: Colors.blue),
              // " ${dailyWeather.rainLast3Hours?.toStringAsFixed(1) ?? '0'}%", 
              
                
              Text('${_currentWeather?.rainLastHour?.toStringAsFixed(1) ?? '0'}%'),
              Text('Chance of Rain'),
            ],
          ),
        ),
      ],
    ),
    SizedBox(height: 20), // Space between rows
    // Second row: UV Index, Sunrise, Sunset
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Column(
           /* children: [
              Image.asset('assets/pressure.png', width: 24, height: 24),
              Text('${_currentWeather?.pressure ?? 'N/A'}'),
              Text('Pressure'),
            ],*/
            children: [
              Image.asset('assets/temperature.png', width: 24, height: 24),
              Text('${_currentWeather?.tempFeelsLike ?.celsius?.toStringAsFixed(1) ??  'N/A'}°C'),
              Text('Feels Like'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/sunrise.png', width: 24, height: 24),
              Text('${_currentWeather?.sunrise != null ? DateFormat('hh:mm a').format(_currentWeather!.sunrise!) : 'N/A'}'),
              Text('Sunrise'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/sunset.png', width: 24, height: 24),
              Text('${_currentWeather?.sunset != null ? DateFormat('hh:mm a').format(_currentWeather!.sunset!) : 'N/A'}'),
              Text('Sunset'),
            ],
          ),
        ),
      ],
    ),
  ],
),
        ),


 SizedBox(height: 20),  // Space after additional weather information
         // Divider(color: Colors.grey.shade300, thickness: 1),  // Light grey horizontal line         
            Padding(
            padding: EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    top: 1.0,
    bottom: 5.0,
  ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hourly Forecast',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
         


Container(
  height: 140, // Height to accommodate two rows for date and time
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: _hourlyForecast?.length ?? 0,
    itemBuilder: (context, index) {
      Weather weather = _hourlyForecast![index];
      return Container(
        width: 100, // Increased width to accommodate the icon and text
        margin: EdgeInsets.symmetric(horizontal: 4), // Margin for spacing
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 243, 247, 249), // Background color for each hour container
          borderRadius: BorderRadius.circular(8), // Optional rounded corners
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Text(
              DateFormat('EEE').format(weather.date!), // Day
              style: TextStyle(fontSize: 16),
            ),
            Text(
              DateFormat('ha').format(weather.date!), // Hour
              style: TextStyle(fontSize: 16),
            ),
            _getWeatherIcon(weather.weatherMain),
            Text(
              "${weather.temperature?.celsius?.toStringAsFixed(1) ?? 'N/A'}°C",
              style: TextStyle(fontSize: 18),
            ),
            Row(
              mainAxisSize: MainAxisSize.min, // Keep the row as small as possible
              children: [
                Icon(Icons.water_drop, size: 16, color: Colors.blue), // Water drop icon
                Text(
                  " ${weather.rainLast3Hours ?? 0}%", // Rain percentage
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      );
    },
  ),
),
SizedBox(height: 20),  // Space after additional weather information
       //   Divider(color: Colors.grey.shade300, thickness: 1),  // Light grey horizontal line
          
/*if (_forecast != null) ..._forecast!.map((weather) => ListTile(
   title: Text("Forecast for ${weather.date} in ${weather.areaName}"),
            subtitle: Text("${weather.temperature?.celsius?.toStringAsFixed(1) ?? 'N/A'}°C, ${weather.weatherDescription}"),
)),*/
  // 5-day forecast list
     Padding(
            padding: EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    top: 1.0,
    bottom: 5.0,
  ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '5-Days Forecast ',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        


if (_dailyForecast != null) ...[
  ListView.builder(
    shrinkWrap: true, // Use this if within another scrolling view
    physics: NeverScrollableScrollPhysics(), // Use this if within another scrolling view
    itemCount: _dailyForecast!.length,
    itemBuilder: (context, index) {
      var dailyWeather = _dailyForecast![index];
      return Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 243, 247, 249), // Background color for each day
          borderRadius: BorderRadius.circular(8), // Optional rounded corners
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Margin for spacing
        child: ListTile(
          leading: _getWeatherIcon(dailyWeather.weatherMain),
          title: Text(
            "${DateFormat('EEEE').format(dailyWeather.date!)}", // Display day of the week
          ),
          subtitle: Row(
            children: <Widget>[
              Text(
                "${DateFormat('MMMd').format(dailyWeather.date!)}", // Display date
              ),
              SizedBox(width: 10),
              Icon(Icons.water_drop, size: 16, color: Colors.blue), // Water drop icon
              Text(
                " ${dailyWeather.rainLast3Hours?.toStringAsFixed(1) ?? '0'}%", // Rain percentage
              ),
              SizedBox(width: 10),
              Text(
                "${dailyWeather.temperature?.celsius?.toStringAsFixed(1) ?? 'N/A'}°C", // Temperature
              ),
            ],
          ),
        ),
      );
    },
  ),
],


        ],
      ),

      ),
      ),
    ),

      bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: _onItemTapped,
          currentIndex: _selectedIndex,
      )
  );
}
}

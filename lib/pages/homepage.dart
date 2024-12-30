// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fyp/providers/location_provider.dart';
import 'package:fyp/providers/weather_provider.dart';
import 'package:fyp/common_widgets.dart';
import 'navigation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isShowingResults = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndWeather();
  }

  void _initializeLocationAndWeather() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);

    // Update the location and fetch weather automatically
    await locationProvider.updateCurrentLocation();
    if (locationProvider.currentLocation != null) {
      // Fetch the weather data based on the current location
      weatherProvider.fetchWeather(
        locationProvider.currentLocation!.latitude,
        locationProvider.currentLocation!.longitude,
      );
    } else {
      print("Location is null, cannot fetch weather.");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (mounted) {
      Provider.of<LocationProvider>(context, listen: false).setMapController(controller);
      Provider.of<LocationProvider>(context, listen: false).updateCurrentLocation();
    }
  }

  Future<void> _searchLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final query = _searchController.text;
    if (query.isNotEmpty) {
      try {
        await locationProvider.searchLocation(query);
        setState(() {
          _isShowingResults = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _selectSearchResult(int index) {
    Provider.of<LocationProvider>(context, listen: false).selectSearchResult(index);
    setState(() {
      _isShowingResults = false;
    });
    _zoomToFitRoute();
  }

  void _zoomToFitRoute() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.routePolyline != null && locationProvider.routePolyline!.points.isNotEmpty) {
      double minLat = locationProvider.routePolyline!.points.first.latitude;
      double maxLat = locationProvider.routePolyline!.points.first.latitude;
      double minLng = locationProvider.routePolyline!.points.first.longitude;
      double maxLng = locationProvider.routePolyline!.points.first.longitude;

      for (var point in locationProvider.routePolyline!.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
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
      case 4:
        Navigator.pushReplacementNamed(context, '/weather');
        break;
    }
  }

  Future<bool> _onWillPop() async {
    if (_isShowingResults) {
      setState(() {
        _isShowingResults = false;
      });
      return false;
    }
    return true;
  }

  IconData _getWeatherIcon(int conditionCode) {
    if (conditionCode < 300) {
      return Icons.thunderstorm;
    } else if (conditionCode < 600) {
      return Icons.grain;
    } else if (conditionCode < 700) {
      return Icons.ac_unit;
    } else if (conditionCode < 800) {
      return Icons.waves;
    } else if (conditionCode == 800) {
      return Icons.wb_sunny;
    } else if (conditionCode <= 804) {
      return Icons.cloud;
    } else {
      return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Consumer<LocationProvider>(
              builder: (context, provider, child) {
                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(5.4564274, 100.2815509),
                    zoom: 10,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  markers: {
                    if (provider.currentLocationMarker != null) provider.currentLocationMarker!,
                    if (provider.destinationMarker != null) provider.destinationMarker!,
                    ...provider.searchMarkers,
                  },
                  polylines: provider.routePolyline != null ? {provider.routePolyline!} : {},
                );
              },
            ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search destination',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) => _searchLocation(),
                ),
              ),
            ),
            if (_isShowingResults && locationProvider.searchResults.isNotEmpty)
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 300,
                  child: ListView.builder(
                    itemCount: locationProvider.searchResults.length,
                    itemBuilder: (context, index) {
                      final result = locationProvider.searchResults[index];
                      return ListTile(
                        title: Text(result['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(result['formatted_address'] ?? ''),
                        onTap: () => _selectSearchResult(index),
                      );
                    },
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 16,
              right: 16,
              child: (locationProvider.travelDistance != null && locationProvider.travelDuration != null)
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your location → ${locationProvider.destinationMarker?.infoWindow.title}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Estimate: ${locationProvider.travelDuration} • Distance: ${locationProvider.travelDistance}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  locationProvider.clearRoute();
                                  locationProvider.updateCurrentLocation();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (locationProvider.currentLocation != null && locationProvider.destinationMarker != null) {
                                    final destinationMarker = locationProvider.destinationMarker!;
                                    final placeName = destinationMarker.infoWindow.title ?? "Destination";

                                    final address = await locationProvider.getAddressFromCoordinates(
                                      destinationMarker.position.latitude,
                                      destinationMarker.position.longitude,
                                    ) ?? "Address not available";

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NavigationPage(
                                          currentLocation: locationProvider.currentLocation!,
                                          destination: LatLng(
                                            destinationMarker.position.latitude,
                                            destinationMarker.position.longitude,
                                          ),
                                          placeName: placeName,
                                          address: address,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Current location or destination is not set.")),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0D7400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Go Now', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(),
            ),
            Positioned(
            bottom: 150,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Provider.of<LocationProvider>(context, listen: false).updateCurrentLocation();
                    if (locationProvider.currentLocation != null) {
                      weatherProvider.fetchWeather(
                        locationProvider.currentLocation!.latitude,
                        locationProvider.currentLocation!.longitude,
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                Consumer<WeatherProvider>(
                  builder: (context, weatherProvider, child) {
                    if (weatherProvider.isLoading) {
                      return const CircularProgressIndicator();
                    }

                    if (weatherProvider.weather == null) {
                      // Show custom asset image if no weather data is available
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        child: Image.asset(
                          'assets/images/weather_no_available.png', // Make sure the path is correct
                          width: 30,
                          height: 30,
                        ),
                      );
                    }

                    final weatherData = weatherProvider.weather!;
                    final conditionCode = weatherData['current']['weather'][0]['id'] ?? 800;

                    IconData weatherIcon = _getWeatherIcon(conditionCode);

                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                
                      child: Icon(
                        weatherIcon,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
        bottomNavigationBar: CustomBottomNavigationBar(
          onItemSelected: _onItemTapped,
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

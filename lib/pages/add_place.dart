import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'package:google_maps_webservice/places.dart';

class AddPlacePage extends StatefulWidget {
  const AddPlacePage({Key? key}) : super(key: key);

  @override
  _AddPlacePageState createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Marker? _selectedPlaceMarker;
  List<Prediction> _placePredictions = [];
  final _places = GoogleMapsPlaces(apiKey: 'AIzaSyCtFrTIeSaWI9LLbfVDMJwmrMILvlggbHk'); // Replace with your API Key
  String? _selectedAddress; // Store the selected address from Google

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the current location when the page loads
      Provider.of<LocationProvider>(context, listen: false).updateCurrentLocation();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Provider.of<LocationProvider>(context, listen: false).setMapController(controller);
  }

  void _searchPlace(String query) async {
    if (query.isNotEmpty) {
      final response = await _places.autocomplete(query);
      if (response.isOkay) {
        setState(() {
          _placePredictions = response.predictions.take(15).toList(); // Limit to 15 results
        });
      } else {
        setState(() {
          _placePredictions = [];
        });
      }
    } else {
      setState(() {
        _placePredictions = [];
      });
    }
  }

  void _selectPlace(Prediction prediction) async {
    final detail = await _places.getDetailsByPlaceId(prediction.placeId!);
    if (detail.isOkay) {
      final lat = detail.result.geometry!.location.lat;
      final lng = detail.result.geometry!.location.lng;
      final position = LatLng(lat, lng);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));

      setState(() {
        _selectedPlaceMarker = Marker(
          markerId: MarkerId(prediction.placeId!),
          position: position,
          infoWindow: InfoWindow(title: detail.result.name),
        );
        _selectedAddress = detail.result.formattedAddress; // Set the selected address
        _placePredictions = [];
      });
    }
  }

  Future<void> _confirmPlace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _selectedPlaceMarker != null) {
      final placeName = _selectedPlaceMarker!.infoWindow.title;
      final address = _selectedAddress;
      final location = GeoPoint(
        _selectedPlaceMarker!.position.latitude,
        _selectedPlaceMarker!.position.longitude,
      );

      // Check if the place is already saved
      final querySnapshot = await FirebaseFirestore.instance
          .collection('SavePlace')
          .where('userID', isEqualTo: FirebaseFirestore.instance.collection('Users').doc(user.uid))
          .where('placeName', isEqualTo: placeName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Show dialog if place is already saved
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Place Already Saved",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "This place has already been saved to your list of saved locations.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(150, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // Save place to Firestore
        final placeData = {
          'placeName': placeName,
          'address': address,
          'location': location,
          'userID': FirebaseFirestore.instance.collection('Users').doc(user.uid),
          'addedTime': Timestamp.now(),
        };

        await FirebaseFirestore.instance.collection('SavePlace').add(placeData);

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark_added,
                    color: Color(0xFF04CD73),
                    size: 100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Place Saved Successfully",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your place has been saved and added to your list of saved locations.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Return to Saved Places page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF04CD73),
                      minimumSize: const Size(150, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Back to Saved Places",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a place'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search address',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _searchPlace,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: locationProvider.currentLocation ?? LatLng(37.7749, -122.4194),
                    zoom: 15,
                  ),
                  markers: {
                    if (locationProvider.currentLocationMarker != null)
                      locationProvider.currentLocationMarker!,
                    if (_selectedPlaceMarker != null) _selectedPlaceMarker!,
                  },
                ),
                if (_placePredictions.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _placePredictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _placePredictions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(prediction.description!),
                            onTap: () => _selectPlace(prediction),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedPlaceMarker != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _confirmPlace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF04CD73),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Confirm and Save",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

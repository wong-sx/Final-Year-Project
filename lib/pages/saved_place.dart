import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'navigation_page.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({Key? key}) : super(key: key);

  @override
  _SavedPlacesPageState createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot>? _savedPlacesStream;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  void _loadSavedPlaces() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _savedPlacesStream = _firestore
            .collection('SavePlace')
            .where('userID', isEqualTo: _firestore.collection('Users').doc(user.uid))
            .snapshots();
      });
    }
  }

  Future<void> _removePlace(String placeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Place'),
          content: const Text('Are you sure you want to remove this place?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('SavePlace').doc(placeId).delete();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_forever,
                    color: Colors.green,
                    size: 100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Place Removed",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "The selected place has been successfully removed from your saved places.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(150, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove place: $e")),
        );
      }
    }
  }

  Future<void> _startNavigation(LatLng destination, String placeName, String address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start Navigation'),
          content: const Text('Do you want to start navigation to this place?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go Now'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.updateCurrentLocation();

      if (locationProvider.currentLocation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NavigationPage(
              currentLocation: locationProvider.currentLocation!,
              destination: destination,
              placeName: placeName,
              address: address,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get current location")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () {
                Navigator.pushNamed(context, '/addPlace').then((_) => _loadSavedPlaces());
              },
            ),
            title: const Text(
              'Add a place',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _savedPlacesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No saved places found.'),
                  );
                }

                final savedPlaces = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: savedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = savedPlaces[index];
                    final placeId = place.id;
                    final placeName = place['placeName'] ?? 'Unnamed Place';
                    final address = place['address'] ?? 'No address provided';
                    final location = place['location'] as GeoPoint;
                    final destination = LatLng(location.latitude, location.longitude);

                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(placeName),
                      subtitle: Text(address),
                      trailing: PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'navigate') {
                            _startNavigation(destination, placeName, address);
                          } else if (value == 'remove') {
                            _removePlace(placeId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'navigate',
                            child: Text('Start Navigation'),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

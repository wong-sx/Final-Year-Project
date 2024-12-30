import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'navigation_page.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class NavigationHistoryPage extends StatefulWidget {
  const NavigationHistoryPage({Key? key}) : super(key: key);

  @override
  _NavigationHistoryPageState createState() => _NavigationHistoryPageState();
}

class _NavigationHistoryPageState extends State<NavigationHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _navigationHistoryStream;

  @override
  void initState() {
    super.initState();
    _loadNavigationHistory();
  }

  void _loadNavigationHistory() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _navigationHistoryStream = _firestore
            .collection('NavigationHistory')
            .where('userID', isEqualTo: _firestore.collection('Users').doc(user.uid))
            .snapshots();
      });
    }
  }

  Future<void> _removeNavigation(String historyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Navigation'),
          content: const Text('Are you sure you want to remove this navigation history?'),
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
      await _firestore.collection('NavigationHistory').doc(historyId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Navigation history removed.")),
      );
    }
  }

  Future<void> _removeAllNavigationHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove All History'),
          content: const Text('Are you sure you want to remove all navigation history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshots = await _firestore
            .collection('NavigationHistory')
            .where('userID', isEqualTo: _firestore.collection('Users').doc(user.uid))
            .get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All navigation history removed.")),
        );
      }
    }
  }

  Future<void> _navigateAgain(LatLng destination, String placeName, String address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start Navigation'),
          content: const Text('Do you want to start navigation to this place again?'),
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
        title: const Text('Navigation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _removeAllNavigationHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _navigationHistoryStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No navigation history found.'),
                  );
                }

                final historyList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final history = historyList[index];
                    final historyId = history.id;
                    final placeName = history['placeName'] ?? 'Unnamed Place';
                    final address = history['address'] ?? 'No address provided';
                    final location = history['location'] as GeoPoint;
                    final destination = LatLng(location.latitude, location.longitude);

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(placeName),
                      subtitle: Text(address),
                      trailing: PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'navigate') {
                            _navigateAgain(destination, placeName, address);
                          } else if (value == 'remove') {
                            _removeNavigation(historyId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'navigate',
                            child: Text('Navigate Again'),
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

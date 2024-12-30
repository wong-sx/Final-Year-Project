import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:fyp/common_widgets.dart'; // Import common widget for navigation
import 'package:fyp/services/admin_activity_logger.dart';

class AccountProfilePage extends StatelessWidget {
  const AccountProfilePage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print("Error fetching user data: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Profile"),
        backgroundColor: const Color(0xFF04CD73),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data ?? {};
          final userName = userData['name'] ?? 'Unknown User';
          final role = userData['role'] ?? 'user';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child:
                            Icon(Icons.person, size: 60, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName, // Show user's name here
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Button Section
                _buildMenuButton(
                  context,
                  icon: Icons.place,
                  text: "Save Place",
                  onTap: () {
                    Navigator.pushNamed(context, '/savedPlaces'); // Navigate to Save Place page
                  },
                ),
                const SizedBox(height: 10),
                _buildMenuButton(
                  context,
                  icon: Icons.history,
                  text: "Navigation History",
                  onTap: () {
                    Navigator.pushNamed(
                        context, '/navigationHistory'); // Navigate to Navigation History page
                  },
                ),
                const SizedBox(height: 10),
                _buildMenuButton(
                  context,
                  icon: Icons.report,
                  text: "Drowsiness Report",
                  onTap: () {
                    Navigator.pushNamed(context,
                        '/drowsinessReport'); // Navigate to Drowsiness Report page
                  },
                ),
                const SizedBox(height: 10),
                // Conditionally render Admin Page button
                if (role == "admin")
                  _buildMenuButton(
                    context,
                    icon: Icons.admin_panel_settings,
                    text: "Admin Page",
                    onTap: () {
                      Navigator.pushNamed(context, '/adminPage'); // Navigate to Admin Page
                    },
                  ),
                const SizedBox(height: 10),
                _buildMenuButton(
                  context,
                  icon: Icons.logout,
                  text: "Logout",
                  onTap: () async {
                    if (role == "admin") {
                      // Log admin logout activity before signing out
                      final logger = AdminActivityLogger();
                      await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'Logout', details: 'Admin Logged Out');
                    }
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(
                        context, '/login'); // Navigate back to login page
                  },
                ),
              ],
            ),
          );
        },
      ),
      // Add CustomBottomNavigationBar from common_widget.dart
      bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: (index) {
          // Handle navigation with index; for account, use the specific index for it
          if (index == 1) Navigator.pushReplacementNamed(context, '/account');
          if (index == 2) Navigator.pushReplacementNamed(context, '/drowsiness');
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 3) Navigator.pushReplacementNamed(context, '/emergency');
        },
        currentIndex: 1, // Set the default to the "Account" page
      ),
    );
  }

  // Helper method to create menu buttons
  Widget _buildMenuButton(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF04CD73), size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

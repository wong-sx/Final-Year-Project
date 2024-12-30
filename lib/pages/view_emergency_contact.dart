import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/edit_emergency_contact.dart';
import 'package:fyp/pages/register_emergency_contact.dart';
import 'package:fyp/common_widgets.dart';

class ViewEmergencyContactPage extends StatefulWidget {
  @override
  _ViewEmergencyContactPageState createState() => _ViewEmergencyContactPageState();
}

class _ViewEmergencyContactPageState extends State<ViewEmergencyContactPage> {
  String? contactName;
  String? contactEmail;
  int _selectedIndex = 3; // Default index set to 3 for "Emergency"

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  void _loadEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('EmergencyContact').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          contactName = doc['contactName'];
          contactEmail = doc['contactEmail'];
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegisterEmergencyContactPage()),
        );
      }
    }
  }

  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEmergencyContactPage(name: contactName, email: contactEmail)),
    ).then((_) => _loadEmergencyContact());
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        title: const Text(
          'View Registered Contact',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'CURRENT EMERGENCY CONTACT',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              if (contactName != null && contactEmail != null) ...[
                TextField(
                  controller: TextEditingController(text: contactName),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: TextEditingController(text: contactEmail),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _navigateToEditPage,
                  child: Text(
                    'EDIT',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: _onItemTapped,
        currentIndex: _selectedIndex,
      ),
    );
  }
}

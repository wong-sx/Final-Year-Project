import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_emergency_contact.dart';
import 'package:fyp/common_widgets.dart';

class RegisterEmergencyContactPage extends StatefulWidget {
  @override
  _RegisterEmergencyContactPageState createState() => _RegisterEmergencyContactPageState();
}

class _RegisterEmergencyContactPageState extends State<RegisterEmergencyContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  int _selectedIndex = 3; // Default index set to 3 for "Emergency"
  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _checkExistingEmergencyContact();
  }

  // Method to check if the user already has an emergency contact in Firestore
  void _checkExistingEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('EmergencyContact').doc(user.uid).get();
      if (doc.exists) {
        // Navigate to the view emergency contact page if data exists
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ViewEmergencyContactPage()),
        );
      }
    }
  }

  void _saveContact() async {
    final user = FirebaseAuth.instance.currentUser;

    // Reset errors before validation
    setState(() {
      _nameError = null;
      _emailError = null;
    });

    // Validation checks
    if (_nameController.text.isEmpty || _nameController.text.length > 25) {
      setState(() {
        _nameError = _nameController.text.isEmpty
            ? "Name cannot be empty"
            : "Name cannot exceed 25 characters";
      });
      return;
    }

    if (_emailController.text.isEmpty || !_isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = "Please enter a valid email address";
      });
      return;
    }

    if (_emailController.text == user?.email) {
      setState(() {
        _emailError = "Emergency contact email cannot be the same as your account email";
      });
      return;
    }

    // If validation passes, save contact to Firestore
    if (user != null) {
      await FirebaseFirestore.instance.collection('EmergencyContact').doc(user.uid).set({
        'contactName': _nameController.text,
        'contactEmail': _emailController.text,
        'userID': FirebaseFirestore.instance.collection('Users').doc(user.uid),
      });

      // Navigate to the view emergency contact page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ViewEmergencyContactPage()),
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
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
        title: const Text('Emergency Contact Set Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REGISTER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'You need to save the emergency contact',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveContact,
                child: Text(
                  'SAVE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        onItemSelected: _onItemTapped,
        currentIndex: _selectedIndex,
      ),
    );
  }
}

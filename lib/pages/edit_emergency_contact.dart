import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/view_emergency_contact.dart';

class EditEmergencyContactPage extends StatefulWidget {
  final String? name;
  final String? email;

  EditEmergencyContactPage({this.name, this.email});

  @override
  _EditEmergencyContactPageState createState() => _EditEmergencyContactPageState();
}

class _EditEmergencyContactPageState extends State<EditEmergencyContactPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _nameError;
  String? _emailError;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
  }

  void _updateContact() async {
    setState(() {
      _nameError = null;
      _emailError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    } else if (name.length > 25) {
      setState(() => _nameError = 'Name cannot exceed 25 characters');
      return;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Email cannot be empty');
      return;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Invalid email format');
      return;
    } else if (email == _currentUser?.email) {
      setState(() => _emailError = 'Emergency contact email cannot be the same as your account email');
      return;
    }

    if (_currentUser != null) {
      await FirebaseFirestore.instance.collection('EmergencyContact').doc(_currentUser.uid).update({
        'contactName': name,
        'contactEmail': email,
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ViewEmergencyContactPage()),
      );
    }
  }

  void _cancelEdit() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ViewEmergencyContactPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Emergency Contact'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _cancelEdit,
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
                'CHANGE CONTACT',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('You can change the new emergency contact', textAlign: TextAlign.center),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'New Name',
                  errorText: _nameError,
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
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'New E-mail',
                  errorText: _emailError,
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updateContact,
                    child: Text('SAVE', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(120, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _cancelEdit,
                    child: Text('CANCEL', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      minimumSize: Size(120, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

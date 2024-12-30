import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _errorMessage;

  Future<void> _sendPasswordResetEmail() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Check if the email exists in Firestore
      final email = _emailController.text.trim();
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        // Email does not exist in Firestore
        setState(() {
          _errorMessage = "Email does not exist in our records.";
        });
        return;
      }

      // Send password reset email through Firebase Authentication
      await _auth.sendPasswordResetEmail(email: email);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Password Reset Email Sent"),
            content: const Text(
                "We've sent you an email to reset your password. Please check your inbox."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context,'/'); // Go back to login page
                },
                child: const Text("Back to Login"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Update error message if an unexpected error occurs
      setState(() {
        if (e is FirebaseAuthException && e.code == 'invalid-email') {
          _errorMessage = "The email address is invalid.";
        } else {
          _errorMessage = "Failed to send reset email. Please try again.";
        }
      });
    }
  }
}


  // Email validation
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    setState(() {
      _errorMessage = null; // Clear API error message for validation error
    });
    return 'Please enter your email';
  }
  final emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$';
  if (!RegExp(emailPattern).hasMatch(value)) {
    setState(() {
      _errorMessage = null; // Clear API error message for validation error
    });
    return 'Please enter a valid email address';
  }
  return null;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Align content to the start
              children: [
                Image.asset('assets/images/navSafe_Logo.png', height: 100),
                const SizedBox(height: 20),
                const Text(
                  "Forgot Password",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enter your email to receive a password reset link",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 10),
                // Show error message if email is invalid or does not exist
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton(
                  onPressed: _sendPasswordResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF04CD73),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Send Reset Link",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

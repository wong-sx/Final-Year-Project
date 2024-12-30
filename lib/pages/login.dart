import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/services/admin_activity_logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _authErrorMessage;
  final AdminActivityLogger logger = AdminActivityLogger();

  Future<void> _login() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Reset the error message
      if (mounted) {
        setState(() {
          _authErrorMessage = null;
        });
      }

      // Attempt login with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check user details
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        if (!userDoc.exists) {
          if (mounted) {
            setState(() {
              _authErrorMessage = 'User does not exist in Firestore';
            });
          }
          await _auth.signOut(); // Log out from Firebase Authentication
          return;
        }

        bool isActive = userDoc['active'] ?? false;
        if (!isActive) {
          await _showMessageDialog(
            title: "Account Disabled",
            message: "Your account has been deactivated. Please contact support for assistance.",
          );
          await _auth.signOut(); // Log out from Firebase Authentication
          return;
        }

        String? role = userDoc['role'] as String?;
        if (role == 'admin') {
          // Log admin login activity
          await logger.logActivity(
            user.uid,
            'Login',
            details: 'Admin logged in',
          );
        }

        // Navigate to home or account page upon successful login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // Show error message if login fails
      if (mounted) {
        setState(() {
          _authErrorMessage = 'Invalid email or password';
        });
      }
    }
  }
}


Future<void> _showMessageDialog({
  required String title,
  required String message,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}



  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    const emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allows screen to resize when keyboard is open
      body: Center(
        child: SingleChildScrollView( // Wrap content in SingleChildScrollView to allow scrolling
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/images/navSafe_Logo.png', height: 100), // Logo from assets
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Welcome to NavSafe",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail, // Email validation
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword, // Password validation
                ),
                const SizedBox(height: 10),
                if (_authErrorMessage != null)
                  Text(
                    _authErrorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                const SizedBox(height: 10),
                // Align TextButtons with input fields using padding
                Padding(
                  padding: const EdgeInsets.only(left: 8.0), // Aligns with input fields
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register'); // Navigate to registration page
                        },
                        child: const Text("Not yet registered? Register Now"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgotPassword'); // Navigate to password reset page
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF04CD73), // Set button color to #04CD73
                      minimumSize: const Size(double.infinity, 60), // Make button wider and taller
                      padding: const EdgeInsets.symmetric(vertical: 18), // Increase vertical padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18, // Larger font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

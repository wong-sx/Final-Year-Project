import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/services/admin_activity_logger.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'user'; // Default role
  bool _obscurePassword = true;

  // Password validation flags
  bool hasMinLength = false;
  bool hasLowercase = false;
  bool hasUppercase = false;
  bool hasSpecialChar = false;

  // Email existence error flag
  String? _emailError;

  // Check password validity
  void _checkPassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8;
      hasLowercase = value.contains(RegExp(r'[a-z]'));
      hasUppercase = value.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = value.contains(RegExp(r'[@#\$%^&+=!]'));
    });
  }

  // Check if the email already exists
  Future<bool> _isEmailExist(String email) async {
    try {
      final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      // If there's an error, assume email is not found
      return false;
    }
  }

  // Create Account Method
  Future<void> _createAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      String email = _emailController.text.trim();

      // Check if the email already exists
      bool emailExists = await _isEmailExist(email);
      if (emailExists) {
        setState(() {
          _emailError = 'Email is already in use. Please use a different one.';
        });
        return;
      } else {
        setState(() {
          _emailError = null; // Clear any previous error
        });
      }

      try {
        // Create the user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );

        // If the user is created successfully, store additional information in Firestore
        await FirebaseFirestore.instance.collection('Users').add({
          'uid': userCredential.user?.uid, // Store the UID from Firebase Authentication
          'name': _nameController.text.trim(),
          'email': email,
          'role': _selectedRole,
          'password':_passwordController.text.trim(),
        });

        // Log the account creation activity
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final logger = AdminActivityLogger();
          await logger.logActivity(
            currentUser.uid,
            'create_account',
            details: 'Created account for user: ${_nameController.text.trim()} with role: $_selectedRole',
          );

        }

        // Show success dialog
        _showSuccessDialog();
      } on FirebaseAuthException catch (e) {
        // Handle authentication errors
        setState(() {
          _emailError = e.message;
        });
      } catch (e) {
        // Handle other errors
        setState(() {
          _emailError = 'An unexpected error occurred. Please try again later.';
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the email';
    }
    final emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!hasMinLength || !hasLowercase || !hasUppercase || !hasSpecialChar) {
      return 'Password must meet all requirements';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
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
              children: [
                Image.asset('assets/images/navSafe_Logo.png', height: 100),
                const SizedBox(height: 20),
                const Text(
                  "NavSafe",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create a new account to manage users and access admin privileges!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    filled: true,
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  onChanged: (value) {
                    setState(() {
                      _emailError = null; // Clear email error message when the user re-enters the email
                    });
                  },
                ),
                // Display email error message here
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _emailError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onChanged: _checkPassword,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordRequirement("At least 8 characters", hasMinLength),
                    _buildPasswordRequirement("At least 1 lowercase letter", hasLowercase),
                    _buildPasswordRequirement("At least 1 uppercase letter", hasUppercase),
                    _buildPasswordRequirement("At least 1 special character (@, #, etc.)", hasSpecialChar),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: ['user', 'admin'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Select Role',
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF04CD73),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Create Account",
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

  // Widget to show each password requirement
  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check : Icons.close,
          color: isValid ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF04CD73),
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "Account Created Successfully",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to admin page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF04CD73),
                  minimumSize: Size(150, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Back to Admin",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

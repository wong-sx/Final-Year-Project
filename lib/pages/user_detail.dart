import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/services/admin_activity_logger.dart'; // Admin Logger

class UserDetailPage extends StatefulWidget {
  final String userId; // Firestore Document ID

  const UserDetailPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String email;
  late String role;
  late String password;
  bool isActive = true;
  bool isPasswordVisible = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        name = userDoc['name'] ?? 'No Name';
        email = userDoc['email'] ?? 'No Email';
        role = userDoc['role'] ?? 'user'; // Default to 'user' if not provided
        isActive = userDoc['active'] ?? true;
        isLoading = false; // Loading complete
      });
    } else {
      setState(() {
        isLoading = false; // Stop loading
      });
      await _showErrorDialog('User not found.');
    }
  } catch (e) {
    setState(() {
      isLoading = false; // Stop loading
    });
    await _showErrorDialog('Error fetching user details: $e');
  }
}

  

  // Validation Methods
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name cannot be empty';
    if (value.length > 25) return 'Name must be 25 characters or less';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }


  // Dialogs
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 80, color: Colors.amber),
                  SizedBox(height: 16),
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text(message, style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                        child: Text('Cancel', style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text('Success', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text(message, style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text(message, style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action Methods
  Future<void> _updateUser() async {
    if (await _showConfirmationDialog('Confirm Update', 'Are you sure you want to update this user?')) {
      if (_formKey.currentState!.validate()) {
        try {
          await FirebaseFirestore.instance.collection('Users').doc(widget.userId).update({
            'name': name,
            'email': email,
            'role': role,
          });

          final logger = AdminActivityLogger();
          await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'update_user', details: 'Updated user: $name ($email)');

          await _showSuccessDialog('User updated successfully!');
        } catch (e) {
          await _showErrorDialog('Error updating user: $e');
        }
      }
    }
  }

/*
  Future<void> _deleteUser() async {
    if (await _showConfirmationDialog('Confirm Deletion', 'Are you sure you want to delete this user?')) {
      try {
        await FirebaseFirestore.instance.collection('Users').doc(widget.userId).delete();
        await FirebaseFirestore.instance.collection('NavigationHistory').where('userID', isEqualTo: widget.userId).get().then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
        await FirebaseFirestore.instance.collection('SavePlace').where('userID', isEqualTo: widget.userId).get().then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
          await FirebaseFirestore.instance.collection('EmergencyContact').where('userID', isEqualTo: widget.userId).get().then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        // Delete Drowsiness Detection History
        await FirebaseFirestore.instance
            .collection('DrowsinessDetectionHistory')
            .where('userID', isEqualTo: widget.userId)
            .get()
            .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });


        final logger = AdminActivityLogger();
        await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'delete_user', details: 'Deleted user: $name ($email)');

        await _showSuccessDialog('User deleted successfully!');
        Navigator.pop(context);
      } catch (e) {
        await _showErrorDialog('Error deleting user: $e');
      }
    }
  }
  */

  Future<void> _deleteUser() async {
  if (await _showConfirmationDialog(
      'Confirm Deletion', 'Are you sure you want to delete this user?')) {
    try {
      // Delete the user document from Firestore
      await FirebaseFirestore.instance.collection('Users').doc(widget.userId).delete();

      // Delete related collections (if applicable)
      await FirebaseFirestore.instance
          .collection('NavigationHistory')
          .where('userID', isEqualTo: widget.userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection('SavePlace')
          .where('userID', isEqualTo: widget.userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection('EmergencyContact')
          .where('userID', isEqualTo: widget.userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection('DrowsinessDetectionHistory')
          .where('userID', isEqualTo: widget.userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });


      // Log the deletion activity
      final logger = AdminActivityLogger();
      await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'delete_user',
          details: 'Deleted user: $name ($email)');

      await _showSuccessDialog('User deleted successfully!');
      Navigator.pop(context); // Navigate back to the previous screen
    } catch (e) {
      await _showErrorDialog('Error deleting user: $e');
    }
  }
}
 

   // Activate User
  Future<void> _activateUser() async {
   if (await _showConfirmationDialog(
        'Confirm Activation', 'Are you sure you want to activate this user?')) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .update({'active': true});
        await _showSuccessDialog('User activated successfully!');
      // Log the activity
      final logger = AdminActivityLogger();
      await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'activate_user',
          details: 'Activated user: $name ($email)');

      setState(() {
        isActive = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error activating user')));
    }
  }
  } 

  // Deactivate User
  Future<void> _deactivateUser() async {
    if (await _showConfirmationDialog(
        'Confirm Deactivation', 'Are you sure you want to deactivate this user?')) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .update({'active': false});
      // Log the activity
      final logger = AdminActivityLogger();
      await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'deactivate_user',
          details: 'Deactivated user: $name ($email)');

      setState(() {
        isActive = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deactivating user')));
    }
  }
  }

  @override
  Widget build(BuildContext context) {
     if (isLoading) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Detail')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }


    return Scaffold(
      appBar: AppBar(title: Text('User Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
                validator: _validateName,
              ),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (value) => email = value,
                validator: _validateEmail,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role'),
                  RadioListTile(
                    title: Text('Admin'),
                    value: 'admin',
                    groupValue: role,
                    onChanged: (value) {
                      setState(() {
                        role = value.toString();
                      });
                    },
                  ),
                  RadioListTile(
                    title: Text('User'),
                    value: 'user',
                    groupValue: role,
                    onChanged: (value) {
                      setState(() {
                        role = value.toString();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _updateUser, child: Text('Update')),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (isActive) {
                    await _deactivateUser();
                  } else {
                    await _activateUser();
                  }
                },
                child: Text(isActive ? 'Deactivate User' : 'Activate User'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _deleteUser,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityLogger {
  // Singleton pattern to use the same instance across the app
  static final AdminActivityLogger _instance = AdminActivityLogger._internal();

  factory AdminActivityLogger() {
    return _instance;
  }

  AdminActivityLogger._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logActivity(String userId, String activityType, {String? details}) async {
    try {
      await _firestore.collection('AdminActivityLog').add({
        'userId': userId,
        'activityType': activityType, // e.g., 'login', 'logout', 'create_account'
        'activityDetails': details ?? '',
        'activityDate': FieldValue.serverTimestamp(),
      });
      print("Activity logged successfully.");
    } catch (e) {
      print("Error logging activity: $e");
    }
  }
}

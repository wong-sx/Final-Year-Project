import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminLogPage extends StatefulWidget {
  @override
  _AdminLogPageState createState() => _AdminLogPageState();
}

class _AdminLogPageState extends State<AdminLogPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchAdminLogs() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('AdminActivityLog')
          .orderBy('activityDate', descending: true) // Sort by latest date
          .get();

      List<Map<String, dynamic>> logs = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch username based on userId from Users collection
        String userId = data['userId'] ?? 'Unknown User';
        String userName = 'Unknown User';

        try {
          DocumentSnapshot userSnapshot =
              await _firestore.collection('Users').doc(userId).get();
          if (userSnapshot.exists) {
            userName = userSnapshot['name'] ?? 'Unknown User';
          }
        } catch (e) {
          debugPrint('Error fetching user name for userId $userId: $e');
        }

        return {
          'userName': userName,
          'activityType': data['activityType'] ?? 'Unknown Activity',
          'activityDetails': data['activityDetails'] ?? 'No details provided',
          'activityDate': data['activityDate'] != null
              ? (data['activityDate'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList());

      return logs;
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      throw Exception('Failed to fetch logs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Admin Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back to the previous page
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAdminLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching logs.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No logs available.'));
          }

          List<Map<String, dynamic>> logs = snapshot.data!;

          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.all(10.0),
            itemBuilder: (context, index) {
              Map<String, dynamic> log = logs[index];
              bool isEven = index % 2 == 0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isEven ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isEven ? Colors.green : Colors.grey,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    log['userName'], // Display the user name
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['activityType'], // Display activity type
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log['activityDetails'], // Display activity details
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  trailing: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(log['activityDate']),
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

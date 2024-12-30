import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fyp/pages/drowsiness_detail.dart';

class UsageListPage extends StatefulWidget {
  @override
  _UsageListPageState createState() => _UsageListPageState();
}

class _UsageListPageState extends State<UsageListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _usageHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    final user = _auth.currentUser;

    if (user == null) {
      print("User not logged in.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('DrowsinessDetectionHistory')
          .where('userID', isEqualTo: user.uid)
          .get();

      final data = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'data': doc.data(),
        };
      }).toList();

      // Sort the data by startTime in descending order (new to old)
      data.sort((a, b) {
       final dataA = a['data'] as Map<String, dynamic>?; // Cast `data` to a Map
      final dataB = b['data'] as Map<String, dynamic>?;

      final dateA = (dataA?['startTime'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final dateB = (dataB?['startTime'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return dateB.compareTo(dateA); // Descending order
    });

      setState(() {
        _usageHistory = data;
        _isLoading = false;
      });

      print("Usage history fetched and sorted successfully. Count: ${_usageHistory.length}");
    } catch (e) {
      print("Error fetching usage data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatDuration(int seconds) {
  if (seconds < 60) {
    return '$seconds second${seconds > 1 ? 's' : ''}';
  } else {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}, $remainingSeconds second${remainingSeconds > 1 ? 's' : ''}';
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usage History'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _usageHistory.isEmpty
              ? Center(child: Text('No usage history found.'))
              : ListView.builder(
                  itemCount: _usageHistory.length,
                  itemBuilder: (context, index) {
                    final document = _usageHistory[index];
                    final data = document['data'];
                    final startTime = (data['startTime'] as Timestamp).toDate();
                    final endTime = (data['endTime'] as Timestamp).toDate();

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.teal),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          title: Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(startTime)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Time: ${DateFormat('HH:mm').format(startTime)}'),
                              Text('End Time: ${DateFormat('HH:mm').format(endTime)}'),
                              Text('Duration: ${formatDuration(data['durationDetection'])}'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: CircleBorder(),
                            ),
                            child: Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DrowsinessDetailPage(documentId: document['id']),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

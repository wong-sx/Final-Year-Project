import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail.dart';
import 'create_account.dart';
import 'generate_report.dart';
import 'admin_log.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Admin'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Create Account') {
                _navigateToCreateAccount(context);
              } else if (value == 'Generate Report') {
                _navigateToGenerateReport(context);
              } else if (value == 'Admin Log') {
                _navigateToAdminLog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'Create Account',
                child: Text('Create Account'),
              ),
              PopupMenuItem(
                value: 'Generate Report',
                child: Text('Generate Report'),
              ),
               PopupMenuItem(
                value: 'Admin Log',
                child: Text('Admin Log'),
              ),
            ],
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'Search User...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // User List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }

                // Categorize users based on roles
                var admins = snapshot.data!.docs.where((doc) {
                  var role = doc['role'].toString().toLowerCase();
                  var name = doc['name'].toString().toLowerCase();
                  var email = doc['email'].toString().toLowerCase();
                  return role == 'admin' &&
                      (name.contains(searchQuery) || email.contains(searchQuery));
                }).toList();

                var users = snapshot.data!.docs.where((doc) {
                  var role = doc['role'].toString().toLowerCase();
                  var name = doc['name'].toString().toLowerCase();
                  var email = doc['email'].toString().toLowerCase();
                  return role == 'user' &&
                      (name.contains(searchQuery) || email.contains(searchQuery));
                }).toList();

                return ListView(
                  children: [
                    // Admin Section
                    if (admins.isNotEmpty) ...[
                      Container(
                        color: Colors.teal.shade100, // Background color for Admin section
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          'Admins',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      ...admins.map((admin) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                admin['name'][0],
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(admin['name']),
                            subtitle: Text(admin['email']),
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: Colors.grey),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserDetailPage(userId: admin.id),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserDetailPage(userId: admin.id),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ],
                    // User Section
                    if (users.isNotEmpty) ...[
                      Container(
                        color: Colors.blue.shade100, // Background color for User section
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          'Users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      ...users.map((user) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                user['name'][0],
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(user['name']),
                            subtitle: Text(user['email']),
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: Colors.grey),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserDetailPage(userId: user.id),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserDetailPage(userId: user.id),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ],
                    // No Results
                    if (admins.isEmpty && users.isEmpty)
                      Center(child: Text('No results found.')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to Create Account Page
  void _navigateToCreateAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAccountPage()),
    );
  }

  // Navigate to Generate Report Page
  void _navigateToGenerateReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenerateReportPage()),
    );
  }

  // Navigate to Admin Log Page
  void _navigateToAdminLog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminLogPage()),
    );
  }
}

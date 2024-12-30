import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:fyp/services/admin_activity_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';


class GenerateReportPage extends StatefulWidget {
  @override
  _GenerateReportPageState createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> userData = [];
  bool isLoading = false;
  final GlobalKey chartKey = GlobalKey(); // Global key to capture chart

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _fetchData() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date range')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    DateTime start = _selectedDateRange!.start;
    DateTime end = _selectedDateRange!.end.add(Duration(hours: 23, minutes: 59, seconds: 59));

    try {
      // Fetch users
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('Users').get();

      // Fetch navigation and drowsiness data
      QuerySnapshot navSnapshot = await FirebaseFirestore.instance
          .collection('NavigationHistory')
          .where('addedTime', isGreaterThanOrEqualTo: start)
          .where('addedTime', isLessThanOrEqualTo: end)
          .get();

      QuerySnapshot drowsinessSnapshot = await FirebaseFirestore.instance
          .collection('DrowsinessDetectionHistory')
          .where('startTime', isGreaterThanOrEqualTo: start)
          .where('startTime', isLessThanOrEqualTo: end)
          .get();

      Map<String, dynamic> userStats = {};

      // Initialize user stats
      for (var user in userSnapshot.docs) {
        userStats[user.id] = {
          'name': user['name'],
          'email': user['email'],
          'navigateLogged': 0,
          'drowsinessEvents': 0,
          'lastActivity': null,
        };
      }

      // Process navigation data
      for (var nav in navSnapshot.docs) {
        String userId = nav['userID'] is DocumentReference
            ? nav['userID'].id
            : nav['userID'];

        if (userStats.containsKey(userId)) {
          userStats[userId]['navigateLogged'] += 1;
          userStats[userId]['lastActivity'] = nav['addedTime'].toDate();
        }
      }

      // Process drowsiness data
      for (var drowsiness in drowsinessSnapshot.docs) {
        String userId = drowsiness['userID'] is DocumentReference
            ? drowsiness['userID'].id
            : drowsiness['userID'];

        if (userStats.containsKey(userId)) {
          userStats[userId]['drowsinessEvents'] += 1;
          userStats[userId]['lastActivity'] = drowsiness['endTime'].toDate();
        }
      }

      // Convert to list
      userData = userStats.values.map((e) => e as Map<String, dynamic>).toList();

      // Log the activity
      final logger = AdminActivityLogger();
      await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'generate_report', details: 'Report generated for date range: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}');

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Widget _buildLineChart() {
  if (_selectedDateRange == null || userData.isEmpty) {
    return Center(child: Text('No data available.'));
  }

  final List<FlSpot> navigateSpots = [];
  final List<FlSpot> drowsySpots = [];
  double maxNavigate = 0, maxDrowsy = 0;

  DateTime startDate = _selectedDateRange!.start;
  DateTime endDate = _selectedDateRange!.end;

  // Iterate over the date range
  for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
    DateTime date = startDate.add(Duration(days: i));
    double navigateCount = 0;
    double drowsyCount = 0;

    // Sum data for each date
    for (var user in userData) {
      if (user['lastActivity'] != null &&
          DateFormat('yyyy-MM-dd').format(user['lastActivity']) ==
              DateFormat('yyyy-MM-dd').format(date)) {
        navigateCount += (user['navigateLogged'] ?? 0).toDouble();
        drowsyCount += (user['drowsinessEvents'] ?? 0).toDouble();
      }
    }

    // Add only valid spots within the chart's range
    navigateSpots.add(FlSpot(i.toDouble(), navigateCount));
    drowsySpots.add(FlSpot(i.toDouble(), drowsyCount));

    maxNavigate = maxNavigate < navigateCount ? navigateCount : maxNavigate;
    maxDrowsy = maxDrowsy < drowsyCount ? drowsyCount : maxDrowsy;
  }

  return Column(
    children: [
      Expanded(
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              verticalInterval: 1,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
              getDrawingVerticalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(), // Y-axis labels
                    style: TextStyle(fontSize: 12),
                  ),
                  interval: 1,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value > endDate.difference(startDate).inDays) {
                      return Text(''); // Avoid showing invalid labels
                    }
                    DateTime date =
                        startDate.add(Duration(days: value.toInt()));
                    return Text(
                      DateFormat('dd/MM').format(date), // X-axis date labels
                      style: TextStyle(fontSize: 10),
                    );
                  },
                  interval: 1,
                ),
              ),
            ),
            lineBarsData: [
              // Line for Navigate Usage
              LineChartBarData(
                spots: navigateSpots,
                isCurved: false,
                barWidth: 4,
                gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
              // Line for Drowsy Detection Usage
              LineChartBarData(
                spots: drowsySpots,
                isCurved: false,
                barWidth: 4,
                gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
            ],
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            minY: 0, // Y-axis starts at 0
            maxX: endDate.difference(startDate).inDays.toDouble(), // Limit x-axis to date range
            minX: 0,
          ),
        ),
      ),
      // Legend
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendIndicator(Colors.blue, 'Navigate Usage'),
            SizedBox(width: 20),
            _buildLegendIndicator(Colors.red, 'Drowsy Detection Usage'),
          ],
        ),
      ),
    ],
  );
}


Widget _buildLegendIndicator(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12)),
    ],
  );
}



  Future<Uint8List> _captureChartAsImage(GlobalKey chartKey) async {
    try {
      RenderRepaintBoundary boundary =
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw Exception("Error capturing chart: $e");
    }
  }

  Future<void> _exportAsPDF() async {
  // Request storage permission
  if (await Permission.storage.request().isGranted ||
      await Permission.manageExternalStorage.request().isGranted) {
    
    // Use File Picker to select directory
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    // Check if the user selected a directory
    if (directoryPath != null) {
      final pdf = pw.Document();
      final chartImage = await _captureChartAsImage(chartKey);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'User Activity Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Date Range: ${_selectedDateRange != null ? DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start) : ''} - ${_selectedDateRange != null ? DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end) : ''}',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'User Activity Chart',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Image(
                pw.MemoryImage(chartImage),
                height: 200,
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Email', 'Navigate Usage', 'Drowsy Detection Usage', 'Last Activity'],
                data: userData
                    .map((data) => [
                          data['name'],
                          data['email'],
                          data['navigateLogged'].toString(),
                          data['drowsinessEvents'].toString(),
                          data['lastActivity'] != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(data['lastActivity'])
                              : 'N/A',
                        ])
                    .toList(),
              ),
            ],
          ),
        ),
      );

      try {
        // Save the file in the selected directory
        final file = File("$directoryPath/user_activity_report.pdf");
        await file.writeAsBytes(await pdf.save());

        final logger = AdminActivityLogger();
        await logger.logActivity(FirebaseAuth.instance.currentUser!.uid, 'export_report', details: 'Report exported to $directoryPath/user_activity_report.pdf');

        // Show success dialog
        _showSuccessDialog(context, 'PDF successfully saved at: ${file.path}');
      } catch (e) {
        // Show error dialog if there's an issue saving the PDF
        _showSuccessDialog(context, 'Error saving PDF: $e');
      }
    } else {
      // Show error dialog if no directory was selected
      _showSuccessDialog(context, 'No directory selected. Please choose a directory to save the file.');
    }
  } else {
    // If storage permission is denied, show message
    _showSuccessDialog(context, 'Storage permission denied. Please enable it in settings.');
    openAppSettings(); // Opens app settings for the user to enable permission
  }
}


Future<void> _showSuccessDialog(BuildContext context, String message) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User can’t dismiss dialog by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Success!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Activity Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(_selectedDateRange == null
                  ? 'Select Date Range'
                  : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'),
              trailing: Icon(Icons.calendar_today),
              onTap: _pickDateRange,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchData,
              child: Text('Generate Report'),
            ),
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : userData.isNotEmpty
                    ? Expanded(
                        child: Column(
                          children: [
                            Text('User Activity Chart', style: TextStyle(fontSize: 16)),
                            RepaintBoundary(
                              key: chartKey,
                              child: Container(
                                height: 300,
                                child: _buildLineChart(),
                              ),
                            ),
                            SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: userData.length,
                                itemBuilder: (context, index) {
                                  final data = userData[index];
                                  return ListTile(
                                    title: Text(data['name']),
                                    subtitle: Text(data['email']),
                                    trailing: Text(
                                      'Navigate: ${data['navigateLogged']} | Drowsy: ${data['drowsinessEvents']}',
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _exportAsPDF,
                              child: Text('Export as PDF'),
                            ),
                          ],
                        ),
                      )
                    : Center(child: Text('No data available for the selected date range')),
          ],
        ),
      ),
    );
  }
}

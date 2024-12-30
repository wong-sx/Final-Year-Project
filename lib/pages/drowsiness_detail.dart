import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DrowsinessDetailPage extends StatefulWidget {
  final String documentId; // Pass the selected document's ID

  

  DrowsinessDetailPage({required this.documentId});

  @override
  _DrowsinessDetailPageState createState() => _DrowsinessDetailPageState();
}

class _DrowsinessDetailPageState extends State<DrowsinessDetailPage> {
  DocumentSnapshot? document;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    // Fetch the selected document from Firebase using the document ID
    final doc = await FirebaseFirestore.instance
        .collection('DrowsinessDetectionHistory')
        .doc(widget.documentId)
        .get();

    setState(() {
      document = doc;
    });
  }

  /// Convert seconds to a readable duration format
  String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}, $minutes minute${minutes > 1 ? 's' : ''}, $seconds second${seconds > 1 ? 's' : ''}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}, $seconds second${seconds > 1 ? 's' : ''}';
    } else {
      return '$seconds second${seconds > 1 ? 's' : ''}';
    }
  }

  List<String> generateRecommendations(Map<String, dynamic> data) {
  List<String> recommendations = [];
  final blinkingCount = data['blinkingCount'] ?? 0;
  final yawningCount = data['yawnCount'] ?? 0;
  final sleepCount = data['sleepCount'] ?? 0;
  final detectionDuration = data['durationDetection'] ?? 0; // In seconds

  // Calculate blink rate (blinks per minute)
  final detectionDurationMinutes = detectionDuration / 60;
  final blinkRate = (detectionDurationMinutes > 0)
      ? (blinkingCount / detectionDurationMinutes)
      : 0;

  // Short Duration Recommendations (< 5 minutes)
  if (detectionDurationMinutes < 5) {
    if (blinkRate >= 8 && blinkRate <= 10 && yawningCount == 0 && sleepCount == 0) {
      recommendations.add("No signs of drowsiness were detected during this short session. Great job staying alert and focused!");
    } else if (blinkRate < 4) {
      recommendations.add("This short session detected signs of extreme drowsiness—ensure you're rested before driving.");
    } else if (blinkRate > 10) {
      recommendations.add("This short session shows signs of eye strain or fatigue—consider refreshing yourself before driving.");
    }
    if (yawningCount > 0 || sleepCount > 0) {
      recommendations.add("Even during this short session, drowsiness was detected—prioritize rest before driving again.");
    }
  }

  // Moderate Duration Recommendations (5–15 minutes)
  else if (detectionDurationMinutes >= 5 && detectionDurationMinutes <= 15) {
    if (blinkRate >= 8 && blinkRate <= 10 && yawningCount == 0 && sleepCount == 0) {
      recommendations.add("No signs of drowsiness were detected during this moderate session. Keep up the good work and stay alert!");
    } else if (blinkRate < 4) {
      recommendations.add("Signs of drowsiness were detected during this moderate session—consider taking breaks on longer drives.");
    } else if (blinkRate > 10) {
      recommendations.add("Frequent blinking during this session indicates eye strain or distractions—refresh yourself and stay focused.");
    }
    if (yawningCount > 0 || sleepCount > 0) {
      recommendations.add("Drowsiness detected during this moderate session—ensure you rest adequately before your next drive.");
    }
  }

  // Long Duration Recommendations (> 15 minutes)
  else if (detectionDurationMinutes > 15) {
    if (blinkRate >= 8 && blinkRate <= 10 && yawningCount == 0 && sleepCount == 0) {
      recommendations.add("No signs of drowsiness were detected during this long session. Great job staying focused—remember to take regular breaks for safety.");
    } else if (blinkRate < 4) {
      recommendations.add("Signs of severe drowsiness detected during this long session—rest is critical before continuing.");
    } else if (blinkRate > 10) {
      recommendations.add("Frequent blinking during this long session suggests fatigue—take a break to recover focus.");
    }
    if (yawningCount > 0 || sleepCount > 0) {
      recommendations.add("Drowsiness during this prolonged session poses a high risk—stop driving and rest immediately.");
    }
  }

  return recommendations;
}


  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Drowsiness Details'),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = document!.data() as Map<String, dynamic>;
    final yawning = data['yawnCount'] ?? 0;
    final blinking = data['blinkingCount'] ?? 0;
    final eyeClosure = data['sleepCount'] ?? 0;

    final totalEvents = yawning + blinking + eyeClosure;
    final durationSeconds = data['durationDetection'] ?? 0;
    final formattedDuration = formatDuration(durationSeconds);

    // Calculate percentages for the pie chart
    final yawningPercentage = (totalEvents == 0) ? 0.0 : (yawning / totalEvents) * 100;
    final blinkingPercentage = (totalEvents == 0) ? 0.0 : (blinking / totalEvents) * 100;
    final eyeClosurePercentage = (totalEvents == 0) ? 0.0 : (eyeClosure / totalEvents) * 100;

    // Generate recommendations based on the data
     final recommendations = generateRecommendations(data);


/*
    // Pie chart sections
    final pieSections = [
      PieChartSectionData(
        color: Colors.yellow,
        value: yawningPercentage,
        title: '${yawningPercentage.toStringAsFixed(1)}%',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: blinkingPercentage,
        title: '${blinkingPercentage.toStringAsFixed(1)}%',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: eyeClosurePercentage,
        title: '${eyeClosurePercentage.toStringAsFixed(1)}%',
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
    */

    return Scaffold(
      appBar: AppBar(
        title: Text('Drowsiness Details'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  border: Border.all(color: Colors.teal),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${data['startTime'].toDate().toString().substring(0, 10)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Start Time: ${data['startTime'].toDate().toString().substring(11, 16)}'),
                    Text('End Time: ${data['endTime'].toDate().toString().substring(11, 16)}'),
                    Text('Total Time Detection: $formattedDuration'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Detection Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              SizedBox(height: 16),
             Center(
  child: LayoutBuilder(
    builder: (context, constraints) {
      // Determine the shortest side of the available space
      final shortestSide = constraints.biggest.shortestSide;

      return Container(
        width: shortestSide * 0.8, // Constrain width to 80% of the shortest side
        height: shortestSide * 0.8, // Constrain height to 80% of the shortest side
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                color: Colors.yellow,
                value: yawningPercentage,
                title: '${yawningPercentage.toStringAsFixed(1)}%',
                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                radius : shortestSide/3,
              ),
              PieChartSectionData(
                color: Colors.red,
                value: blinkingPercentage,
                title: '${blinkingPercentage.toStringAsFixed(1)}%',
                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                radius : shortestSide/3,
              ),
              PieChartSectionData(
                color: Colors.orange,
                value: eyeClosurePercentage,
                title: '${eyeClosurePercentage.toStringAsFixed(1)}%',
                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                radius : shortestSide/3,
              ),
            ],
            centerSpaceRadius: 0, // Solid pie chart
            borderData: FlBorderData(show: false),
            sectionsSpace: 2, // Space between sections
          ),
        ),
      );
    },
  ),
),

              SizedBox(height: 16),
              // Add legend below the pie chart
              Column(
                children: [
                  LegendTile(color: Colors.yellow, label: 'Yawning'),
                  LegendTile(color: Colors.red, label: 'Blinking'),
                  LegendTile(color: Colors.orange, label: 'Sleep Count'),
                ],
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Drowsiness Type')),
                    DataColumn(label: Text('Frequency')),
                  ],
                  rows: [
                    DataRow(cells: [DataCell(Text('Yawning')), DataCell(Text(yawning.toString()))]),
                    DataRow(cells: [DataCell(Text('Eye Blinking')), DataCell(Text(blinking.toString()))]),
                    DataRow(cells: [DataCell(Text('Sleep Count')), DataCell(Text(eyeClosure.toString()))]),
                  ],
                ),
              ),
              // Recommendations Section
            Text(
              'Recommendations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations
                  .map((rec) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.teal),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegendTile extends StatelessWidget {
  final Color color;
  final String label;

  LegendTile({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

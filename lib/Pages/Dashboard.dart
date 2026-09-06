import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import './Results.dart';
import './AboutPage.dart';
import './PatientDetails.dart';
import '../database/database_helper.dart';
import '../widgets/custom_bottom_nav.dart';
import '../vision_classifier.dart';
import 'dart:io';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Future<List<Map<String, dynamic>>> _getRecentDiagnoses() async {
    final dbHelper = DatabaseHelper();
    final diagnoses = await dbHelper.getDiagnoses();
    return diagnoses.take(3).toList(); // Only show last 3 diagnoses
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final height = screenSize.height - padding.top - padding.bottom;
    final width = screenSize.width;

    // Calculate responsive dimensions
    final containerWidth = width * 0.9; // 90% of screen width
    final imageHeight = height * 0.25; // 25% of available height
    final diagnosesHeight = height * 0.40; // 40% to fit exactly 3 items

    return Scaffold(
      backgroundColor: const Color(0xFF04101A), // Dark background color to match the new design
      body: SingleChildScrollView(
        // Wrap the body in a SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, // 4% padding
            vertical: height * 0.02, // 2% padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.04), // 4% spacing

              // User Profile and Welcome Text
              Row(
                children: [
                  PopupMenuButton(
                    child: Container(
                      height: width * 0.08, // Shrunk from 0.12
                      width: width * 0.08,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Image.asset(
                          'Assets/images/Usericon.png',
                          height: width * 0.05,
                          width: width * 0.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            SizedBox(width: width * 0.02),
                            Text(
                              'About Vision Care',
                              style: TextStyle(
                                fontSize: width * 0.035,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.pushNamed(context, '/about');
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: width * 0.04),
                  Container(
                    constraints: BoxConstraints(maxWidth: width * 0.7),
                    child: Text(
                      'Welcome', 
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.02),

              // Info Container with overlay
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
                child: Container(
                  height: imageHeight,
                  width: containerWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.04),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(width * 0.04),
                    child: Stack(
                      fit: StackFit.expand, // Ensures stack fills the container
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.asset(
                            'Assets/images/DashboardBanner.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.04),

              // New Scan Button Design to match Screenshot
              Center(
                child: SizedBox(
                  width: containerWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PatientDetails()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color(0xFF5ED3F2), // Light blue
                      padding: EdgeInsets.symmetric(vertical: height * 0.025),
                      elevation: 0, // Minimal, no light outside
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(width * 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: width * 0.06),
                        SizedBox(width: width * 0.02),
                        Text(
                          'START NEW SCAN',
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.06), // Increased spacing to move it down slightly

              // Recent Diagnoses Section
              Row(
                children: [
                  Icon(Icons.table_rows_rounded, color: const Color(0xFF5ED3F2), size: width * 0.06),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: AutoSizeText(
                      'Recent Scans',
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      minFontSize: 12,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getRecentDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF5ED3F2)));
                  }
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return Container(
                      width: containerWidth,
                      padding: EdgeInsets.all(width * 0.06),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2231),
                        borderRadius: BorderRadius.circular(width * 0.04),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history, color: Colors.white24, size: width * 0.12),
                          SizedBox(height: height * 0.01),
                          Text('No scans yet', style: TextStyle(color: Colors.white38, fontSize: width * 0.035)),
                        ],
                      ),
                    );
                  }
                  return Container(
                    width: containerWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2231),
                      borderRadius: BorderRadius.circular(width * 0.04),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(width * 0.04),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            color: const Color(0xFF0B2239),
                            padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.015),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('Patient', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.03))),
                                Expanded(flex: 3, child: Text('Result', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.03))),
                                Expanded(flex: 2, child: Text('Conf.', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.03), textAlign: TextAlign.center)),
                                Expanded(flex: 3, child: Text('Date', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.03), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 1),
                          // Table Rows
                          ...data.asMap().entries.map((entry) {
                            final i = entry.key;
                            final diagnosis = entry.value;
                            final String rawDisease = diagnosis['disease'] ?? 'Unknown';
                            final String patientName = diagnosis['patientName'] ?? 'Unknown Patient';
                            final double confidence = diagnosis['confidence'] != null
                                ? (diagnosis['confidence'] as num).toDouble()
                                : 0.0;
                            final String date = diagnosis['date'] ?? '';
                            final String displayLabel = VisionClassifier.severityFromLabel(rawDisease);
                            final String diseaseKey = rawDisease.toLowerCase();

                            Color severityColor;
                            String severityText;
                            IconData severityIcon;
                            if (diseaseKey.contains('severe')) {
                              severityColor = Colors.redAccent;
                              severityText = 'Severe DR';
                              severityIcon = Icons.warning_rounded;
                            } else if (diseaseKey.contains('mild')) {
                              severityColor = Colors.orangeAccent;
                              severityText = 'Mild DR';
                              severityIcon = Icons.info_rounded;
                            } else {
                              severityColor = const Color(0xFF4CAF50);
                              severityText = 'No DR';
                              severityIcon = Icons.check_circle_rounded;
                            }

                            // Format date to short form
                            String shortDate = date;
                            try {
                              final parsed = DateTime.parse(date);
                              shortDate = '${parsed.month}/${parsed.day}/${parsed.year.toString().substring(2)}';
                            } catch (_) {}

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Results(
                                      disease: rawDisease,
                                      date: date,
                                      imagePath: diagnosis['imagePath'] ?? '',
                                      confidence: confidence,
                                      patientName: patientName,
                                      patientId: diagnosis['patientId'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                color: i.isEven ? Colors.transparent : Colors.white.withOpacity(0.03),
                                padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.013),
                                child: Row(
                                  children: [
                                    // Patient name
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: width * 0.03,
                                            backgroundColor: const Color(0xFF5ED3F2).withOpacity(0.15),
                                            child: Text(
                                              patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                                              style: TextStyle(color: const Color(0xFF5ED3F2), fontSize: width * 0.025, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          SizedBox(width: width * 0.015),
                                          Expanded(
                                            child: Text(
                                              patientName,
                                              style: TextStyle(color: Colors.white, fontSize: width * 0.028, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Severity badge
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        margin: EdgeInsets.only(right: width * 0.02),
                                        padding: EdgeInsets.symmetric(horizontal: width * 0.015, vertical: width * 0.008),
                                        decoration: BoxDecoration(
                                          color: severityColor.withOpacity(0.12),
                                          border: Border.all(color: severityColor.withOpacity(0.4)),
                                          borderRadius: BorderRadius.circular(width * 0.03),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(severityIcon, color: severityColor, size: width * 0.03),
                                            SizedBox(width: width * 0.01),
                                            Flexible(
                                              child: Text(
                                                severityText,
                                                style: TextStyle(color: severityColor, fontSize: width * 0.025, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Confidence
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${(confidence * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(color: Colors.white70, fontSize: width * 0.028),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    // Date
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        shortDate,
                                        style: TextStyle(color: Colors.white38, fontSize: width * 0.026),
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          SizedBox(height: height * 0.005),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }


  Widget _buildDiagnosisItem(String displayLabel, String date, double width, {String? rawDisease, double? confidence}) {
    // Determine color from the raw disease key (Normal/Mild/Severe)
    final String diseaseKey = (rawDisease ?? displayLabel).toLowerCase();
    Color severityColor;
    if (diseaseKey.contains('severe')) {
      severityColor = Colors.redAccent;
    } else if (diseaseKey.contains('mild')) {
      severityColor = Colors.orangeAccent;
    } else {
      severityColor = Colors.green;
    }

    return InkWell(
      onTap: () {
        // Get the diagnosis details from the database
        DatabaseHelper().getDiagnoses().then((diagnoses) {
          final diagnosis = diagnoses.firstWhere(
            (d) => d['disease'] == (rawDisease ?? displayLabel) && d['date'] == date,
            orElse: () => {'imagePath': '', 'confidence': confidence}, // Use passed confidence as fallback
          );
          
          final double? finalConfidence = diagnosis['confidence'] != null 
              ? (diagnosis['confidence'] as num).toDouble() 
              : confidence;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Results(
                disease: rawDisease ?? displayLabel,
                date: date,
                imagePath: diagnosis['imagePath'] ?? '',
                confidence: finalConfidence,
              ),
            ),
          );
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: width * 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.03),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper().getDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox(width: width * 0.15, height: width * 0.15);
                  final diagnosis = snapshot.data!.firstWhere(
                    (d) => d['disease'] == (rawDisease ?? displayLabel) && d['date'] == date,
                    orElse: () => {'imagePath': ''},
                  );
                  
                  return diagnosis['imagePath']?.isNotEmpty == true
                      ? Image.file(
                          File(diagnosis['imagePath']),
                          height: width * 0.15,
                          width: width * 0.15,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: width * 0.15,
                          width: width * 0.15,
                          color: Colors.grey.shade800,
                          child: Icon(Icons.image_not_supported, color: Colors.white54),
                        );
                },
              ),
            ),
            SizedBox(width: width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    displayLabel,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    minFontSize: 10,
                    maxLines: 1,
                  ),
                  SizedBox(height: width * 0.015),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: width * 0.005),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.15),
                          border: Border.all(color: severityColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(width * 0.02),
                        ),
                        child: Text(
                          'Severity: ${diseaseKey.contains("severe") ? "Severe DR" : diseaseKey.contains("mild") ? "Mild DR" : "No DR"}',
                          style: TextStyle(
                            color: severityColor,
                            fontSize: width * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Icon(Icons.info_outline, color: Colors.grey, size: width * 0.035),
                    ],
                  ),
                  SizedBox(height: width * 0.015),
                  AutoSizeText(
                    date,
                    style: TextStyle(
                      fontSize: width * 0.03,
                      color: Colors.grey.shade500,
                    ),
                    minFontSize: 8,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import './Results.dart';
import './AboutPage.dart';
import './PatientDetails.dart';
import '../database/database_helper.dart';
import '../widgets/custom_bottom_nav.dart';
import '../vision_classifier.dart';
import '../services/auth_service.dart';
import './LoginPage.dart';
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

  void _showDoctorProfile(BuildContext context) {
    final doctor = AuthService.currentDoctor;
    final fullName = doctor != null && doctor.fullName.isNotEmpty
        ? doctor.fullName
        : 'Doctor Profile';
    final email = doctor != null && doctor.email.isNotEmpty
        ? doctor.email
        : 'Not provided';
    final username = doctor != null && doctor.username.isNotEmpty
        ? doctor.username
        : 'Not provided';
    final license = doctor != null && doctor.licenseNumber.isNotEmpty
        ? doctor.licenseNumber
        : 'Not provided';
    final clinicLocation = doctor != null && doctor.clinicLocation.isNotEmpty
        ? doctor.clinicLocation
        : 'Not provided';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A12343B),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE8E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title and verified badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Doctor Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12343B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF4EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF12343B),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified Doctor',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF12343B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Healthcare Provider Account Details',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF68777B),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFDCE8E5), height: 1),
              const SizedBox(height: 16),

              // Full Name
              _buildProfileDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: fullName,
              ),
              const SizedBox(height: 14),

              // Email Address
              _buildProfileDetailRow(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: email,
              ),
              const SizedBox(height: 14),

              // Username
              _buildProfileDetailRow(
                icon: Icons.badge_outlined,
                label: 'Username',
                value: username,
              ),
              const SizedBox(height: 14),

              // Professional License Number / PRC Number
              _buildProfileDetailRow(
                icon: Icons.assignment_ind_outlined,
                label: 'Professional License / PRC Number',
                value: license,
              ),
              const SizedBox(height: 14),

              // Clinic/Hospital & Location
              _buildProfileDetailRow(
                icon: Icons.local_hospital_outlined,
                label: 'Clinic/Hospital & Location',
                value: clinicLocation,
              ),
              const SizedBox(height: 24),
              // Privacy & Data Protection section
              const Text(
                'Privacy & Data Protection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12343B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'VisionCare stores your account information and patient screening data locally to provide screening services and keep records. Patient information and screening results should only be accessed for authorized healthcare purposes.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF68777B),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Patient Screening Data'),
                        content: const Text('Are you sure you want to delete all patient screening records? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final dbHelper = DatabaseHelper();
                      final all = await dbHelper.getDiagnoses();
                      for (var d in all) {
                        await dbHelper.deleteDiagnosis(d['id'] as int);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, color: Color(0xFFC95757), size: 18),
                  label: const Text(
                    'Delete Patient Screening Data',
                    style: TextStyle(
                      color: Color(0xFFC95757),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDE8E8),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFF8B4B4), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 1. Clear the current login session
                    AuthService().logout();
                    Navigator.pop(ctx); // Close modal
                    // 2. Return the user to the Login screen
                    // 3. The user must log in again before accessing Dashboard
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFC95757),
                    size: 18,
                  ),
                  label: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      color: Color(0xFFC95757),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDE8E8),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFF8B4B4), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
          ),
          child: Icon(icon, color: const Color(0xFF12343B), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF68777B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12343B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get logged-in doctor name
    final doctor = AuthService.currentDoctor;
    final doctorName = doctor != null && doctor.fullName.isNotEmpty
        ? doctor.fullName
        : 'VisionCare Clinical';

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final height = screenSize.height - padding.top - padding.bottom;
    final width = screenSize.width;

    // Calculate responsive dimensions
    final containerWidth = width * 0.9; // 90% of screen width
    final imageHeight = height * 0.25; // 25% of available height
    final diagnosesHeight = height * 0.40; // 40% to fit exactly 3 items

    return WillPopScope(
  onWillPop: () async => false,
  child: Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.035),

              // Clinical Header with Logged-in Doctor Name and Info Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
  width: 45,
  height: 45,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(color: const Color(0xFF63C7B2), width: 1.5),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0C12343B),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Image.asset(
    'Assets/images/Logo.png',
    fit: BoxFit.contain,
  ),
),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showDoctorProfile(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  doctorName,
                                  style: TextStyle(
                                    fontSize: width * 0.046,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF12343B),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFF68777B),
                                  size: 18,
                                ),
                              ],
                            ),
                            const Text(
                              'Diabetic Retinopathy Screening',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF68777B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF12343B), size: 24),
                    onPressed: () => AboutPage.showAsModal(context),
                    tooltip: 'About VisionCare',
                  ),
                ],
              ),

              SizedBox(height: height * 0.025),

              // Banner Container with clinical framing
              GestureDetector(
                onTap: () {
                  AboutPage.showAsModal(context);
                },
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A12343B),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'Assets/images/DashboardBanner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.03),

              // Start New Scan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientDetails()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF12343B),
                    backgroundColor: const Color(0xFF63C7B2), // Medical Mint
                    padding: EdgeInsets.symmetric(vertical: height * 0.022),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 20, color: Color(0xFF12343B)),
                      const SizedBox(width: 10),
                      const Text(
                        'START NEW SCAN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF12343B),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: height * 0.04),

              // Recent Diagnoses Section Header
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Color(0xFF12343B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Screenings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF12343B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getRecentDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFF63C7B2)),
                    ));
                  }
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(width * 0.08),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE8E5)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history_edu_rounded, color: Color(0xFF68777B), size: 40),
                          SizedBox(height: 12),
                          Text(
                            'No previous screenings recorded',
                            style: TextStyle(color: Color(0xFF68777B), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                          // Table Header
                          Row(
                            children: [
                              Expanded(flex: 3, child: Text('Patient', style: TextStyle(color: const Color(0xFF12343B), fontWeight: FontWeight.bold, fontSize: width * 0.034))),
                              Expanded(flex: 3, child: Text('Assessment', style: TextStyle(color: const Color(0xFF12343B), fontWeight: FontWeight.bold, fontSize: width * 0.034))),
                              Expanded(flex: 2, child: Text('Conf.', style: TextStyle(color: const Color(0xFF12343B), fontWeight: FontWeight.bold, fontSize: width * 0.034), textAlign: TextAlign.center)),
                              Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(right: width * 0.02), child: Text('Date', style: TextStyle(color: const Color(0xFF12343B), fontWeight: FontWeight.bold, fontSize: width * 0.034), textAlign: TextAlign.right))))
                            ],
                          ),
                          const Divider(color: Color(0xFFDCE8E5), height: 1),
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
                            final String diseaseKey = rawDisease.toLowerCase();

                            Color severityColor;
                            String severityText;
                            IconData severityIcon;
                            if (diseaseKey.contains('severe')) {
                              severityColor = const Color(0xFFC95757); // Severe
                              severityText = 'Severe DR';
                              severityIcon = Icons.warning_rounded;
                            } else if (diseaseKey.contains('mild')) {
                              severityColor = const Color(0xFFD49A38); // Mild
                              severityText = 'Mild DR';
                              severityIcon = Icons.info_rounded;
                            } else {
                              severityColor = const Color(0xFF3E9B78); // Normal
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
                                      address: diagnosis['address'],
                                      contactNumber: diagnosis['contactNumber'],
                                      dateOfBirth: diagnosis['dateOfBirth'],
                                      age: diagnosis['age'],
                                      gender: diagnosis['gender'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                color: i.isEven ? Colors.white : const Color(0xFFF7FAF9),
                                padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.013),
                                child: Row(
                                  children: [
                                    // Patient name
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        patientName,
                                        style: TextStyle(color: const Color(0xFF203238), fontSize: width * 0.034, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                                          border: Border.all(color: severityColor.withOpacity(0.5)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(severityIcon, color: severityColor, size: width * 0.028),
                                            SizedBox(width: width * 0.01),
                                            Flexible(
                                              child: Text(
                                                severityText,
                                                style: TextStyle(color: severityColor, fontSize: width * 0.032, fontWeight: FontWeight.bold),
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
                                        style: TextStyle(color: const Color(0xFF203238), fontSize: width * 0.034, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    // Date
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: width * 0.02),
                                          child: Text(
                                            shortDate,
                                            style: TextStyle(color: const Color(0xFF68777B), fontSize: width * 0.026),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          SizedBox(height: height * 0.005),
                        ],
                      );

                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    ),
);

  }


  Widget _buildDiagnosisItem(String displayLabel, String date, double width, {String? rawDisease, double? confidence}) {
    // Determine color from the raw disease key (Normal/Mild/Severe)
    final String diseaseKey = (rawDisease ?? displayLabel).toLowerCase();
    Color severityColor;
    if (diseaseKey.contains('severe')) {
      severityColor = const Color(0xFFC95757);
    } else if (diseaseKey.contains('mild')) {
      severityColor = const Color(0xFFD49A38);
    } else {
      severityColor = const Color(0xFF3E9B78);
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
              borderRadius: BorderRadius.circular(8),
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
                          color: const Color(0xFFDCE8E5),
                          child: const Icon(Icons.image_not_supported, color: Color(0xFF68777B)),
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
                      color: const Color(0xFF203238),
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
                          color: severityColor.withOpacity(0.12),
                          border: Border.all(color: severityColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(6),
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
                      const Icon(Icons.info_outline, color: Color(0xFF68777B), size: 14),
                    ],
                  ),
                  SizedBox(height: width * 0.015),
                  AutoSizeText(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF68777B),
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

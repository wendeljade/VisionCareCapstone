import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Dashboard.dart';
import '../services/auth_service.dart';



class Results extends StatefulWidget {
  final String disease;
  final String date;
  final String imagePath;
  final double? confidence;
  final String? patientName;
  final String? patientId;
  final String? address;
  final String? contactNumber;
  final String? dateOfBirth;
  final String? age;
  final String? gender;

  const Results({
    Key? key,
    required this.disease,
    required this.date,
    required this.imagePath,
    this.confidence,
    this.patientName,
    this.patientId,
    this.address,
    this.contactNumber,
    this.dateOfBirth,
    this.age,
    this.gender,
  }) : super(key: key);

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  // Keep state minimal in Results; actual UI and export logic lives in ResultsContent
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: ResultsContent(
          disease: widget.disease,
          date: widget.date,
          imagePath: widget.imagePath,
          confidence: widget.confidence,
          patientName: widget.patientName,
          patientId: widget.patientId,
          address: widget.address,
          contactNumber: widget.contactNumber,
          dateOfBirth: widget.dateOfBirth,
          age: widget.age,
          gender: widget.gender,
        ),
      ),
    );
  }
}

class ResultsContent extends StatefulWidget {
  final String disease;
  final String date;
  final String imagePath;
  final double? confidence;
  final String? patientName;
  final String? patientId;
  final String? address;
  final String? contactNumber;
  final String? dateOfBirth;
  final String? age;
  final String? gender;

  const ResultsContent({
    Key? key,
    required this.disease,
    required this.date,
    required this.imagePath,
    this.confidence,
    this.patientName,
    this.patientId,
    this.address,
    this.contactNumber,
    this.dateOfBirth,
    this.age,
    this.gender,
  }) : super(key: key);

  @override
  State<ResultsContent> createState() => _ResultsContentState();
}

class _ResultsContentState extends State<ResultsContent> {
  bool _isExporting = false;

  Color _getStatusColor(String disease) {
    final normalized = disease.toLowerCase();
    if (normalized.contains('normal')) {
      return const Color(0xFF3E9B78); // Normal
    } else if (normalized.contains('mild')) {
      return const Color(0xFFD49A38); // Mild
    } else if (normalized.contains('severe')) {
      return const Color(0xFFC95757); // Severe
    }
    return const Color(0xFF12343B);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No date available';
    try {
      return DateFormat('MMM d, yyyy - HH:mm').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  pw.Widget _getRecommendationWidget(String disease, PdfColor color) {
    final normalized = disease.toLowerCase();
    String title = '';
    String body;

    if (normalized.contains('normal')) {
      title = "";
      body = "No significant signs of retinopathy were detected. It is recommended to maintain regular eye screenings and continue managing your blood sugar levels as advised by your physician.";
    } else if (normalized.contains('mild')) {
      title = "Ophthalmologist Consultation Recommended:";
      body = "Potential early signs of retinopathy have been identified. It is recommended that you consult an Ophthalmologist for a comprehensive eye examination and professional confirmation.";
    } else if (normalized.contains('severe')) {
      title = "URGENT: Ophthalmologist Consultation Required:";
      body = "Significant signs of retinopathy have been detected. There is an urgent need to consult an Ophthalmologist immediately for professional verification and necessary treatment planning.";
    } else {
      title = "Inconclusive Result:";
      body = "The screening result is inconclusive. For your safety, please consult an Ophthalmologist for a professional verification.";
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color, fontSize: 10)),
          pw.SizedBox(height: 4),
        ],
        pw.Text(body, style: pw.TextStyle(fontSize: 10, color: color, lineSpacing: 2)),
      ],
    );
  }

  Future<void> _exportToPDF() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();

      Uint8List? logoBytes;
      try {
        logoBytes = (await rootBundle.load('Assets/images/Logo.png')).buffer.asUint8List();
      } catch (e) {
        debugPrint('Logo asset not found: $e');
      }

      final imageFile = File(widget.imagePath);
      Uint8List? scanImageBytes = await imageFile.exists() ? await imageFile.readAsBytes() : null;

      final int probabilityPercent = ((widget.confidence ?? 0.0) * 100).toInt();
      final String displayDisease = widget.disease;
      final Color statusColor = _getStatusColor(displayDisease);
      final PdfColor pdfStatusColor = PdfColor.fromInt(statusColor.value);
final doctor = AuthService.currentDoctor;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), width: 150),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('VISIONCARE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('Advanced Eye Screening Report', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('DIABETIC RETINOPATHY ANALYSIS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Container(
                            margin: const pw.EdgeInsets.symmetric(vertical: 10),
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Column(
                              children: [
                                _buildPdfRow('Name:', widget.patientName ?? 'N/A'),
                                _buildPdfRow('Address:', widget.address ?? 'N/A'),
                                _buildPdfRow('Contact Number:', widget.contactNumber ?? 'N/A'),
                                _buildPdfRow('Date of Birth:', widget.dateOfBirth ?? 'N/A'),
                                _buildPdfRow('Age:', widget.age ?? 'N/A'),
                                _buildPdfRow('Gender:', widget.gender ?? 'N/A'),
                                _buildPdfRow('Scan Date:', _formatDate(widget.date)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text('PROBABILITY: $probabilityPercent%', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            displayDisease.toUpperCase(),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: pdfStatusColor),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (scanImageBytes != null)
                          pw.Container(
                            height: 150,
                            width: 150,
                            child: pw.Image(pw.MemoryImage(scanImageBytes), fit: pw.BoxFit.contain),
                          ),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: 150,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('RECOMMENDATION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdfStatusColor)),
                              pw.SizedBox(height: 6),
                              _getRecommendationWidget(displayDisease, pdfStatusColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Doctor: ${doctor?.fullName ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 8),
                    pw.Text("Professional License No.: ${doctor?.licenseNumber ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 8),
                    pw.Text('Position/Specialization: N/A', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 8),
                    pw.Text("Affiliated Institution/Clinic: ${doctor?.clinicLocation ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 16),
                    pw.Text('Signature: _________________________________________________', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey400),
                pw.Center(child: pw.Text('This result is for Pre-Screening purposes only and is not a medical diagnosis. Please consult an Opthalmologist for confirmation.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/VisionCare_Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Report saved to Documents'),
          action: SnackBarAction(label: 'OPEN', onPressed: () => OpenFile.open(file.path)),
        ));
      }
    } catch (e) {
      debugPrint("PDF Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int probabilityPercent = ((widget.confidence ?? 0.0) * 100).toInt();
    final Color statusColor = _getStatusColor(widget.disease);
    
    final String displayDisease = widget.disease.toLowerCase().contains('normal') ? 'Normal'.tr() :
                                  widget.disease.toLowerCase().contains('mild') ? 'Mild Diabetic Retinopathy'.tr() :
                                  widget.disease.toLowerCase().contains('severe') ? 'Severe Diabetic Retinopathy'.tr() :
                                  widget.disease == 'INVALID_OBJECT' ? 'Non-Retinal / Invalid Image'.tr() :
                                  widget.disease;

    final hasImage = widget.imagePath.isNotEmpty && File(widget.imagePath).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF12343B)),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
            (route) => false,
          ),
        ),
        title: const Text(
          'Diagnostic Assessment',
          style: TextStyle(
            color: Color(0xFF12343B),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFDCE8E5), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primary Diagnostic Finding Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0612343B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Badge & Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.disease.toLowerCase().contains('normal')
                            ? Icons.check_circle_outline_rounded
                            : widget.disease.toLowerCase().contains('mild')
                                ? Icons.info_outline_rounded
                                : Icons.warning_amber_rounded,
                        color: statusColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayDisease.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Confidence Metric Gauge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Model Confidence',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF68777B),
                          ),
                        ),
                        Text(
                          '$probabilityPercent%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12343B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.confidence ?? 0.0).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFDDF4EE),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Patient & Examination Details Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0612343B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: Color(0xFF12343B), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Examination Record',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF12343B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFFDCE8E5), height: 1),
                    const SizedBox(height: 10),
                    _buildInfoRow('Patient Name', widget.patientName ?? 'Not Specified'),
                    _buildInfoRow('Screening Date', _formatDate(widget.date)),
                    if (widget.patientId != null)
                      _buildInfoRow('Record ID', widget.patientId!),

                    if (hasImage) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFDCE8E5), height: 1),
                      const SizedBox(height: 12),
                      const Text(
                        'Captured Retinal Image',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF68777B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.file(
                              File(widget.imagePath),
                              height: 140,
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Clinical Recommendations Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF4EE), // Soft Mint
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_information_outlined, color: Color(0xFF12343B), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CLINICAL RECOMMENDATION',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12343B),
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildUiRecommendation(displayDisease, statusColor),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Pre-Screening Medical Disclaimer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'This result is for pre-screening purposes only and is not a definitive clinical diagnosis. Please consult an Ophthalmologist for comprehensive examination.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF68777B),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Export PDF Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF12343B), size: 20),
                  label: Text(
                    _isExporting ? 'EXPORTING REPORT...' : 'EXPORT CLINICAL REPORT (PDF)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF12343B),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF63C7B2), // Medical Mint
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Return to Dashboard Button
              TextButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                  (route) => false,
                ),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF12343B), size: 18),
                label: const Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    color: Color(0xFF12343B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUiRecommendation(String disease, Color color) {
    final normalized = disease.toLowerCase();
    String body;

    if (normalized.contains('normal')) {
      body = "No significant signs of retinopathy were detected. It is recommended to maintain regular annual eye screenings and continue standard glycemic management as advised by physician.";
    } else if (normalized.contains('mild')) {
      body = "Early retinal microaneurysms or vascular changes detected. A comprehensive dilated ophthalmologic exam within 3 to 6 months is recommended for staging and baseline tracking.";
    } else if (normalized.contains('severe')) {
      body = "Urgent clinical verification required. Prominent signs of proliferative or severe diabetic retinopathy detected. Immediate specialist ophthalmological consultation and optical coherence tomography (OCT) recommended.";
    } else {
      body = "The screening result is inconclusive. For patient safety, a clinical examination by an Ophthalmologist is advised.";
    }

    return Text(
      body,
      style: const TextStyle(
        color: Color(0xFF203238),
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF68777B), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFF203238), fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

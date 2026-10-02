import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import 'package:open_file/open_file.dart';
import '../utils/date_format_utils.dart';

class ExportReport extends StatefulWidget {
  const ExportReport({Key? key}) : super(key: key);

  @override
  State<ExportReport> createState() => _ExportReportState();
}

class _ExportReportState extends State<ExportReport> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _lastExportedFilePath;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _openExportedFile() async {
    if (_lastExportedFilePath != null) {
      final file = File(_lastExportedFilePath!);
      if (await file.exists()) {
        final result = await OpenFile.open(_lastExportedFilePath!);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
          }
        }
      }
    }
  }

  pw.Widget _buildDistributionChart(Map<String, int> diseaseCount, double total) {
    final List<pw.TableRow> rows = [];
    
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Condition',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Count',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Percentage',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Distribution',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Add data rows
    diseaseCount.forEach((disease, count) {
      final percentage = (count / total * 100).toStringAsFixed(1);
      final barWidth = (count / total * 50).round(); // Max 50 characters for the bar
      final bar = '█' * barWidth;
      
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(disease),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(count.toString()),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('$percentage%'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(bar),
            ),
          ],
        ),
      );
    });

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Condition
        1: const pw.FlexColumnWidth(1), // Count
        2: const pw.FlexColumnWidth(1), // Percentage
        3: const pw.FlexColumnWidth(3), // Distribution bar
      },
      children: rows,
    );
  }

  pw.Widget _buildPieChart(Map<String, int> diseaseCount, double total) {
    // Create a simple visual representation using colored boxes
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: diseaseCount.entries.toList().asMap().entries.map((entry) {
        final disease = entry.value.key;
        final count = entry.value.value;
        final percentage = (count / total * 100).toStringAsFixed(1);
        
        // Use different colors for each condition
        final colors = [
          PdfColors.blue300,
          PdfColors.green300,
          PdfColors.amber300,
          PdfColors.pink300,
          PdfColors.purple300,
          PdfColors.teal300,
          PdfColors.red300,
          PdfColors.indigo300,
        ];
        
        final color = colors[entry.key % colors.length];
        final barWidth = (double.parse(percentage) * 2).round(); // Scale the bar width
        
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                color: color,
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                flex: 3,
                child: pw.Text('$disease: $count ($percentage%)'),
              ),
              pw.Expanded(
                flex: 7,
                child: pw.Container(
                  height: 15,
                  width: barWidth.toDouble(),
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildTrendChart(List<Map<String, dynamic>> scans) {
    // Group scans by date
    final Map<String, Map<String, int>> dateData = {};
  
    // Process last 7 days of data
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM/dd').format(date);
      dateData[dateStr] = {};
    }
  
    // Count scans by date and condition
    for (final scan in scans) {
      final date = DateTime.parse(scan['date']);
      final dateStr = DateFormat('MM/dd').format(date);
      final disease = scan['disease'] as String;
    
      if (dateData.containsKey(dateStr)) {
        dateData[dateStr]![disease] = (dateData[dateStr]![disease] ?? 0) + 1;
      }
    }
  
    // Create a simpler bar chart using a table with visual bars
    final List<pw.TableRow> rows = [];
  
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Date',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...dateData.keys.map((date) => 
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                date,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )
          ).toList(),
        ],
      ),
    );
  
    // Get all unique conditions
    final allConditions = <String>{};
    for (final dateEntry in dateData.entries) {
      allConditions.addAll(dateEntry.value.keys);
    }
  
    // Add data rows for each condition
    for (final disease in allConditions) {
      final List<pw.Widget> cells = [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(disease),
        ),
      ];
    
      for (final dateStr in dateData.keys) {
        final count = dateData[dateStr]![disease] ?? 0;
        final bar = '█' * count; // Simple visual bar
        
        cells.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('$count $bar'),
          ),
        );
      }
    
      rows.add(pw.TableRow(children: cells));
    }
  
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: rows,
    );
  }

  Future<void> _exportToPDF() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scans = await _databaseHelper.getDiagnoses();
      final filteredScans = scans.where((scan) {
        final scanDate = DateTime.parse(scan['date']);
        return scanDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               scanDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      if (filteredScans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_diagnoses_found'.tr())),
        );
        return;
      }

      final String currentLocale = context.locale.languageCode;

      // ── Colour palette ──────────────────────────────────────────────
      const PdfColor brandDeepTeal   = PdfColor.fromInt(0xFF1A5F7A);
      const PdfColor brandLightTeal  = PdfColor.fromInt(0xFF63C7B2);
      const PdfColor brandText       = PdfColor.fromInt(0xFF12343B);
      const PdfColor brandAltRow     = PdfColor.fromInt(0xFFF2F8F7);
      const PdfColor brandBorder     = PdfColor.fromInt(0xFFCFE3DF);

      // ── Load logo ────────────────────────────────────────────────────
      pw.MemoryImage? logoImage;
      try {
        final Uint8List logoBytes = await rootBundle
            .load('Assets/images/Logo.png')
            .then((data) => data.buffer.asUint8List());
        logoImage = pw.MemoryImage(logoBytes);
      } catch (_) {}

      // ── Condition distribution ───────────────────────────────────────
      final Map<String, int> conditionCount = {};
      for (var scan in filteredScans) {
        final disease = scan['disease'] as String;
        conditionCount[disease] = (conditionCount[disease] ?? 0) + 1;
      }
      final total = filteredScans.length.toDouble();

      // ── Helper: section heading with teal accent bar ─────────────────
      pw.Widget _sectionHeading(String title) => pw.Row(
        children: [
          pw.Container(width: 4, height: 22, color: brandLightTeal),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: brandDeepTeal,
            ),
          ),
        ],
      );

      // ── Helper: styled table header cell ─────────────────────────────
      pw.Widget _headerCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        color: brandDeepTeal,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

      // ── Helper: styled data cell ──────────────────────────────────────
      pw.Widget _dataCell(String text, {bool alt = false}) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: alt ? brandAltRow : PdfColors.white,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: brandText)),
      );

      // ── Build PDF ─────────────────────────────────────────────────────
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 52),

          // ── Page footer ──────────────────────────────────────────────
          footer: (pw.Context ctx) => pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(color: brandLightTeal, thickness: 0.8),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'VisionCare Clinical  —  Confidential',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),

          build: (pw.Context pdfContext) {
            return [

              // ── HEADER ───────────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: logoImage != null
                        ? pw.Image(logoImage)
                        : pw.Container(
                            color: brandDeepTeal,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'VC',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VisionCare Clinical',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: brandDeepTeal,
                          ),
                        ),
                        pw.Text(
                          'Diabetic Retinopathy Screening Report',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Generated: ${DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'MMMM d, yyyy')}  •  ${DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'h:mm a')}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: brandLightTeal,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Divider(color: brandLightTeal, thickness: 1.5),
              pw.SizedBox(height: 10),

              // ── Report period banner ─────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: pw.BoxDecoration(
                  color: brandAltRow,
                  border: pw.Border(
                    left: pw.BorderSide(color: brandLightTeal, width: 4),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Report Period:  ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: brandDeepTeal,
                      ),
                    ),
                    pw.Text(
                      '${DateFormatUtils.formatDate(_startDate!, currentLocale, 'MMMM d, yyyy')}  –  ${DateFormatUtils.formatDate(_endDate!, currentLocale, 'MMMM d, yyyy')}',
                      style: const pw.TextStyle(fontSize: 10, color: brandText),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 22),

              // ── SECTION 1: Summary Statistics ────────────────────────
              _sectionHeading('1.  Summary Statistics'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: brandBorder, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(children: [
                    _headerCell('Metric'),
                    _headerCell('Value'),
                  ]),
                  pw.TableRow(children: [
                    _dataCell('Total Screenings in Period'),
                    _dataCell('${filteredScans.length}'),
                  ]),
                  ...conditionCount.entries.toList().asMap().entries.map((e) {
                    final entry = e.value;
                    final alt = e.key.isEven;
                    return pw.TableRow(children: [
                      _dataCell('${entry.key} Cases', alt: alt),
                      _dataCell(
                        '${entry.value}  (${(entry.value / total * 100).toStringAsFixed(1)}%)',
                        alt: alt,
                      ),
                    ]);
                  }),
                ],
              ),

              pw.SizedBox(height: 22),

              // ── SECTION 2: Condition Distribution ────────────────────
              _sectionHeading('2.  Condition Distribution'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: brandBorder, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(children: [
                    _headerCell('Condition'),
                    _headerCell('Count'),
                    _headerCell('Percentage'),
                    _headerCell('Distribution'),
                  ]),
                  ...conditionCount.entries.toList().asMap().entries.map((e) {
                    final entry = e.value;
                    final alt = e.key.isEven;
                    final pct = (entry.value / total * 100);
                    final bar = '█' * (pct / 5).round();
                    return pw.TableRow(children: [
                      _dataCell(entry.key, alt: alt),
                      _dataCell('${entry.value}', alt: alt),
                      _dataCell('${pct.toStringAsFixed(1)}%', alt: alt),
                      _dataCell(bar, alt: alt),
                    ]);
                  }),
                ],
              ),

              pw.SizedBox(height: 22),

              // ── SECTION 3: Detailed Screening Records ────────────────
              _sectionHeading('3.  Detailed Screening Records'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: brandBorder, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(children: [
                    _headerCell('Date & Time'),
                    _headerCell('Patient Name'),
                    _headerCell('Condition'),
                    _headerCell('Confidence'),
                  ]),
                  ...filteredScans.asMap().entries.map((e) {
                    final i    = e.key;
                    final scan = e.value;
                    final alt  = i.isEven;
                    final conf = scan['confidence'] != null
                        ? '${(scan['confidence'] as num).toStringAsFixed(1)}%'
                        : '—';
                    return pw.TableRow(children: [
                      _dataCell(
                        DateFormatUtils.formatDate(
                          DateTime.parse(scan['date']), currentLocale, 'MMM d, yyyy  HH:mm'),
                        alt: alt,
                      ),
                      _dataCell(scan['patientName'] ?? 'N/A', alt: alt),
                      _dataCell(scan['disease'] ?? '—', alt: alt),
                      _dataCell(conf, alt: alt),
                    ]);
                  }),
                ],
              ),

              pw.SizedBox(height: 30),

              // ── CLINICIAN CERTIFICATION ──────────────────────────────
              pw.Divider(color: brandDeepTeal, thickness: 1),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'CLINICIAN CERTIFICATION',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: brandDeepTeal,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: brandDeepTeal, thickness: 0.5),
              pw.SizedBox(height: 14),

              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: brandBorder, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'This report was generated by the VisionCare Clinical Diabetic Retinopathy Screening System. '
                      'AI-assisted findings should be reviewed and validated by a qualified ophthalmologist or clinician '
                      'before being used as a basis for clinical decisions.',
                      style: const pw.TextStyle(fontSize: 9, color: brandText),
                    ),

                    pw.SizedBox(height: 18),

                    // Signature fields
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Reviewed by:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              pw.SizedBox(height: 18),
                              pw.Divider(color: brandBorder, thickness: 0.8),
                              pw.Text('Clinician Name & Designation', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 24),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Date:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              pw.SizedBox(height: 18),
                              pw.Divider(color: brandBorder, thickness: 0.8),
                              pw.Text('dd / mm / yyyy', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 18),

                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Facility / Clinic:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              pw.SizedBox(height: 18),
                              pw.Divider(color: brandBorder, thickness: 0.8),
                              pw.Text('Institution Name', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 24),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Signature:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              pw.SizedBox(height: 18),
                              pw.Divider(color: brandBorder, thickness: 0.8),
                              pw.Text('(Authorised Signature)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 14),

                    pw.Container(
                      padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
                      color: const PdfColor.fromInt(0xFFFFF8E1),
                      child: pw.Row(
                        children: [
                          pw.Text('⚠  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.orange700)),
                          pw.Expanded(
                            child: pw.Text(
                              'DISCLAIMER: This report is intended for clinical use only. Results generated by AI-assisted '
                              'screening must be interpreted in conjunction with the assessment of a qualified ophthalmologist.',
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.orange900, fontStyle: pw.FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(color: brandDeepTeal, thickness: 1),

            ];
          },
        ),
      );


      // Save to Downloads directory
      final output = await getExternalStorageDirectory();
      final fileName = 'diabetic_retinopathy_report_${DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'yyyyMMdd_HHmmss')}.pdf';
      final filePath = '${output?.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _lastExportedFilePath = filePath;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Report Exported Successfully'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File saved as:'),
                  const SizedBox(height: 8),
                  Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Location:'),
                  const SizedBox(height: 8),
                  Text(
                    output?.path ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _openExportedFile();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Text(
          'export_report'.tr(),
          style: const TextStyle(
            color: Color(0xFF12343B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF12343B)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFDCE8E5)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Text(
              'select_date_range'.tr(),
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF12343B),
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: width * 0.05),

            // Date pickers row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'start_date'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF68777B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: width * 0.02),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                            vertical: width * 0.035,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDCE8E5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _startDate != null
                                      ? DateFormatUtils.formatDate(
                                          _startDate!,
                                          context.locale.languageCode,
                                          'MMM d, yyyy',
                                        )
                                      : 'select_date'.tr(),
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? const Color(0xFF203238)
                                        : const Color(0xFF68777B),
                                    fontSize: width * 0.035,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF63C7B2),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'end_date'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF68777B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: width * 0.02),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                            vertical: width * 0.035,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDCE8E5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _endDate != null
                                      ? DateFormatUtils.formatDate(
                                          _endDate!,
                                          context.locale.languageCode,
                                          'MMM d, yyyy',
                                        )
                                      : 'select_date'.tr(),
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? const Color(0xFF203238)
                                        : const Color(0xFF68777B),
                                    fontSize: width * 0.035,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF63C7B2),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: width * 0.08),

            // Open last exported file link
            if (_lastExportedFilePath != null)
              Padding(
                padding: EdgeInsets.only(bottom: width * 0.04),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _openExportedFile,
                    icon: const Icon(
                      Icons.file_open_outlined,
                      color: Color(0xFF12343B),
                      size: 18,
                    ),
                    label: const Text(
                      'Open Last Exported Report',
                      style: TextStyle(
                        color: Color(0xFF12343B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _exportToPDF,
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF12343B),
                  backgroundColor: const Color(0xFF63C7B2),
                  disabledBackgroundColor: const Color(0xFFDCE8E5),
                  padding: EdgeInsets.symmetric(vertical: width * 0.042),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF12343B),
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                            color: Color(0xFF12343B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'export_to_pdf'.tr().toUpperCase(),
                            style: TextStyle(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF12343B),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

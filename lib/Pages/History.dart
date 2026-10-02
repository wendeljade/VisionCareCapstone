import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../database/database_helper.dart';
import 'Results.dart';
import 'Dashboard.dart';
import 'ExportReport.dart';
import '../widgets/custom_bottom_nav.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteScreening(Map<String, dynamic> screening) async {
    try {
      if (screening['imagePath'] != null && screening['imagePath'].isNotEmpty) {
        final file = File(screening['imagePath']);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _databaseHelper.deleteDiagnosis(screening['id']);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_deleting_diagnosis'.tr())),
        );
      }
    }
  }

  /// Safe date parsing to handle multiple formats
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No date available';
    try {
      // Try ISO format first
      return DateFormat('MMM d, yyyy - HH:mm').format(DateTime.parse(dateStr));
    } catch (e) {
      // Fallback for older entries already in the DB
      return dateStr;
    }
  }

  Color _getStatusColor(String disease) {
    final normalized = disease.toLowerCase();
    if (normalized.contains('normal')) {
      return const Color(0xFF3E9B78);
    } else if (normalized.contains('mild')) {
      return const Color(0xFFD49A38);
    } else if (normalized.contains('severe')) {
      return const Color(0xFFC95757);
    }
    return const Color(0xFF12343B);
  }

  Widget _buildSearchBar(double width) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE8E5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0612343B),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF63C7B2),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Color(0xFF203238), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'search_disease'.tr(),
                hintStyle: const TextStyle(color: Color(0xFF68777B), fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF68777B), size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScreeningList(double width) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getDiagnoses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF63C7B2)),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_edu_outlined, size: 50, color: Color(0xFF68777B)),
                  const SizedBox(height: 16),
                  Text(
                    'no_matching_diagnoses'.tr(),
                    style: const TextStyle(color: Color(0xFF68777B), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredScreenings = snapshot.data!.where((screening) {
          final disease = screening['disease'].toString().toLowerCase();
          final patient = (screening['patientName'] ?? '').toString().toLowerCase();
          return disease.contains(_searchQuery) || patient.contains(_searchQuery);
        }).toList();

        if (filteredScreenings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF68777B)),
                  const SizedBox(height: 14),
                  Text(
                    'no_matching_diagnoses'.tr(),
                    style: const TextStyle(color: Color(0xFF68777B), fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredScreenings.length,
          itemBuilder: (context, index) {
            final screening = filteredScreenings[index];
            final disease = screening['disease'] ?? 'Unknown';
            final double confidence = (screening['confidence'] ?? 0.0) as double;
            final Color statusColor = _getStatusColor(disease);

            return _buildScreeningCard(width, screening, disease, confidence, statusColor);
          },
        );
      },
    );
  }

  Widget _buildScreeningCard(double width, Map<String, dynamic> screening, String disease, double confidence, Color statusColor) {
    final patientName = screening['patientName'] ?? 'Unknown Patient';
    final hasImage = screening['imagePath'] != null && screening['imagePath'].isNotEmpty && File(screening['imagePath']).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => Results(
            disease: disease,
            date: screening['date'],
            imagePath: screening['imagePath'] ?? '',
            confidence: confidence,
            patientName: screening['patientName'],
            patientId: screening['patientId'],
            address: screening['address'],
            contactNumber: screening['contactNumber'],
            dateOfBirth: screening['dateOfBirth'],
            age: screening['age'],
            gender: screening['gender'],
          ),
        )),
        onLongPress: () => _showDeleteDialog(screening),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Retinal Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4EE),
                    border: Border.all(color: const Color(0xFFDCE8E5), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: hasImage
                      ? Image.file(
                          File(screening['imagePath']),
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(Icons.remove_red_eye_outlined, color: Color(0xFF12343B), size: 28),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Patient & Assessment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF203238),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            border: Border.all(color: statusColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            disease,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(confidence * 100).toStringAsFixed(0)}% conf',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF68777B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 12, color: Color(0xFF68777B)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(screening['date']),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF68777B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF68777B), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> screening) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDCE8E5)),
        ),
        title: Text(
          'confirm_delete'.tr(),
          style: const TextStyle(color: Color(0xFF12343B), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'delete_diagnosis_confirmation'.tr(),
          style: const TextStyle(color: Color(0xFF203238), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: const TextStyle(color: Color(0xFF68777B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScreening(screening);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC95757),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('delete'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'recent_results'.tr(),
          style: const TextStyle(
            color: Color(0xFF12343B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFDCE8E5), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF12343B)),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF12343B)),
            tooltip: 'Export Reports',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExportReport()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(width),
            _buildScreeningList(width),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}

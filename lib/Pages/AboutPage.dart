import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  /// Shows the About content as a scrollable modal bottom sheet.
  static void showAsModal(BuildContext context) {
    final aboutPage = const AboutPage();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final Size screenSize = MediaQuery.of(context).size;
            final double titleSize = screenSize.width * 0.06;
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAF9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCC8C3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header with title and close button
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.05,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            'About Vision Care',
                            style: TextStyle(
                              color: const Color(0xFF12343B),
                              fontWeight: FontWeight.bold,
                              fontSize: titleSize,
                            ),
                            maxLines: 1,
                            minFontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF12343B)),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFDCE8E5)),
                  // Scrollable content
                  Expanded(
                    child: aboutPage._buildBodyContent(context,
                        scrollController: scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the scrollable body content, reused by both the full page and modal.
  Widget _buildBodyContent(BuildContext context,
      {ScrollController? scrollController}) {
    final Size screenSize = MediaQuery.of(context).size;
    final double subtitleSize = screenSize.width * 0.05;
    final double bodySize = screenSize.width * 0.04;
    final double smallSize = screenSize.width * 0.035;

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner card
          Container(
            height: screenSize.height * 0.22,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: screenSize.height * 0.025),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE8E5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.asset(
                    'Assets/images/DashboardBanner.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC12343B),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    left: 20,
                    right: 20,
                    child: AutoSizeText(
                      'Empowering Eye Health\nwith AI Technology',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      minFontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // What is Diabetic Retinopathy Section
          _buildSectionCard(
            screenSize: screenSize,
            title: 'What is Diabetic Retinopathy?',
            subtitleSize: subtitleSize,
            child: AutoSizeText(
              'Diabetic Retinopathy is a diabetes complication that affects eyes. It is caused by damage to the blood vessels of the light-sensitive tissue at the back of the eye (retina).\n\nVisionCare is an innovative AI-powered application designed to help healthcare professionals and patients identify and manage Diabetic Retinopathy effectively.',
              style: TextStyle(
                fontSize: bodySize,
                height: 1.65,
                color: const Color(0xFF203238),
              ),
              minFontSize: 12,
              maxLines: 10,
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),

          // Key Features Section
          _buildSectionCard(
            screenSize: screenSize,
            title: 'Key Features',
            subtitleSize: subtitleSize,
            child: Column(
              children: [
                _buildFeatureItem(
                  context: context,
                  icon: Icons.camera_alt_outlined,
                  title: 'Real-time Detection',
                  description:
                      'Instantly analyze retinal images using our AI model',
                  featureTitleSize: smallSize * 1.28,
                  featureDescSize: smallSize,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Severity Classification',
                  description:
                      'Accurate classification of Mild, Severe, or No DR',
                  featureTitleSize: smallSize * 1.28,
                  featureDescSize: smallSize,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.history_rounded,
                  title: 'Patient History',
                  description:
                      'Keep track of all previous diagnoses and patients',
                  featureTitleSize: smallSize * 1.28,
                  featureDescSize: smallSize,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Export Reports',
                  description: 'Generate PDF reports of patient diagnoses',
                  featureTitleSize: smallSize * 1.28,
                  featureDescSize: smallSize,
                  isLast: true,
                ),
              ],
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),

          // How to Use Section
          _buildSectionCard(
            screenSize: screenSize,
            title: 'How to Use',
            subtitleSize: subtitleSize,
            child: Column(
              children: [
                _buildStepItem(
                    context, '1', 'Open the app and tap on "Scan"', smallSize),
                _buildStepItem(
                    context, '2', 'Enter the Patient Details', smallSize),
                _buildStepItem(
                    context,
                    '3',
                    'Take a clear photo of the retina or pick from gallery',
                    smallSize),
                _buildStepItem(
                    context,
                    '4',
                    'Wait for AI analysis and view detailed results',
                    smallSize,
                    isLast: true),
              ],
            ),
          ),
          SizedBox(height: screenSize.height * 0.02),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate responsive text sizes
    final double titleSize = screenSize.width * 0.06; // 6% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF12343B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: AutoSizeText(
          'About Vision Care',
          style: TextStyle(
            color: const Color(0xFF12343B),
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
          ),
          maxLines: 1,
          minFontSize: 16,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFDCE8E5)),
        ),
      ),
      body: _buildBodyContent(context),
    );
  }

  Widget _buildSectionCard({
    required Size screenSize,
    required String title,
    required double subtitleSize,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF12343B),
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: screenSize.height * 0.018),
          child,
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required double featureTitleSize,
    required double featureDescSize,
    bool isLast = false,
  }) {
    final Size screenSize = MediaQuery.of(context).size;

    return Padding(
      padding:
          EdgeInsets.only(bottom: isLast ? 0 : screenSize.height * 0.018),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.028),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: screenSize.width * 0.055,
              color: const Color(0xFF63C7B2),
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: featureTitleSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF203238),
                  ),
                  maxLines: 2,
                  minFontSize: 12,
                ),
                SizedBox(height: screenSize.height * 0.006),
                AutoSizeText(
                  description,
                  style: TextStyle(
                    fontSize: featureDescSize,
                    height: 1.5,
                    color: const Color(0xFF68777B),
                  ),
                  maxLines: 4,
                  minFontSize: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    String number,
    String description,
    double textSize, {
    bool isLast = false,
  }) {
    final Size screenSize = MediaQuery.of(context).size;

    return Padding(
      padding:
          EdgeInsets.only(bottom: isLast ? 0 : screenSize.height * 0.018),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenSize.width * 0.08,
            height: screenSize.width * 0.08,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: const Color(0xFF12343B),
                  fontWeight: FontWeight.w800,
                  fontSize: textSize * 1.05,
                ),
              ),
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: screenSize.width * 0.012),
              child: AutoSizeText(
                description,
                style: TextStyle(
                  fontSize: textSize,
                  color: const Color(0xFF203238),
                  height: 1.5,
                ),
                maxLines: 3,
                minFontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../Pages/Dashboard.dart';
import '../Pages/PatientDetails.dart';
import '../Pages/History.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  static const Color _deepNavy = Color(0xFF12343B);
  static const Color _softMint = Color(0xFFDDF4EE);
  static const Color _slateGray = Color(0xFF68777B);
  static const Color _paleGrayMint = Color(0xFFDCE8E5);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _paleGrayMint, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A12343B),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == currentIndex) return; // Do nothing if tapping the same tab

            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PatientDetails()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const History()),
              );
            }
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: _deepNavy,
          unselectedItemColor: _slateGray,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            _buildNavigationBarItem(Icons.home_outlined, Icons.home_rounded, 'Home', width, currentIndex == 0),
            _buildNavigationBarItem(Icons.document_scanner_outlined, Icons.document_scanner_rounded, 'Scan', width, currentIndex == 1),
            _buildNavigationBarItem(Icons.history_edu_outlined, Icons.history_edu_rounded, 'History', width, currentIndex == 2),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      IconData icon, IconData activeIcon, String label, double width, bool isSelected) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Icon(icon, size: 22, color: _slateGray),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          decoration: BoxDecoration(
            color: _softMint,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Icon(activeIcon, size: 22, color: _deepNavy),
        ),
      ),
      label: label,
    );
  }
}

// Cleaned LoginPage.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'Dashboard.dart';
import 'RegisterPage.dart';

class LoginPage extends StatefulWidget {
  final String? prefilledUsername;
  final String? prefilledDoctorName;

  const LoginPage({
    super.key,
    this.prefilledUsername,
    this.prefilledDoctorName,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _loggedInDoctorName;

  // Clinical color palette (consistent with VisionCare theme)
  static const Color _deepNavy = Color(0xFF12343B);
  static const Color _medicalMint = Color(0xFF63C7B2);
  static const Color _softMint = Color(0xFFDDF4EE);
  static const Color _coolOffWhite = Color(0xFFF7FAF9);
  static const Color _slateGray = Color(0xFF68777B);
  static const Color _paleGrayMint = Color(0xFFDCE8E5);
  static const Color _charcoalNavy = Color(0xFF203238);
  static const Color _errorRed = Color(0xFFC95757);

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.prefilledUsername ?? '',
    );
    _loggedInDoctorName = widget.prefilledDoctorName;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _headerDoctorTitle {
    if (_loggedInDoctorName != null && _loggedInDoctorName!.trim().isNotEmpty) {
      return _loggedInDoctorName!;
    }
    return 'Doctor Login';
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    final doctor = await AuthService().login(
      emailOrUsername: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (doctor != null) {
      setState(() {
        _loggedInDoctorName = doctor.fullName;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Invalid credentials. Please check your username/email and password, or register a new account.';
      });
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: _deepNavy, size: 24),
            SizedBox(width: 8),
            Text(
              'Reset Password',
              style: TextStyle(
                color: _deepNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For healthcare security compliance, password resets must be authorized by your hospital or clinic system administrator.',
              style: TextStyle(
                color: _charcoalNavy,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please contact:\n• Clinical Support: admin@visioncare.org\n• Internal IT Hotline: Ext. 4102',
              style: TextStyle(
                color: _slateGray,
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _deepNavy,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return Scaffold(
      backgroundColor: _coolOffWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.07,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _paleGrayMint, width: 1.5),
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
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'VisionCare',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _deepNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _softMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CLINICAL RETINOPATHY SUITE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _deepNavy,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _paleGrayMint, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A12343B),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _deepNavy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _softMint,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFE9DF), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.medical_services_outlined, size: 13, color: _deepNavy),
                                  SizedBox(width: 4),
                                  Text('Clinician Portal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _deepNavy)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in with your registered credentials to access patient screening tools.',
                          style: TextStyle(fontSize: 12.5, color: _slateGray, height: 1.35),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Email or Username',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _charcoalNavy),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 14, color: _charcoalNavy, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _coolOffWhite,
                            hintText: 'e.g. dr.smith or doctor@hospital.org',
                            hintStyle: const TextStyle(color: Color(0xFF9EA9AC), fontSize: 13, fontWeight: FontWeight.w400),
                            prefixIcon: const Icon(Icons.badge_outlined, color: _slateGray, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _paleGrayMint, width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _medicalMint, width: 1.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _errorRed, width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _errorRed, width: 1.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email or username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _charcoalNavy),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: const TextStyle(fontSize: 14, color: _charcoalNavy, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _coolOffWhite,
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(color: Color(0xFF9EA9AC), fontSize: 13, fontWeight: FontWeight.w400),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: _slateGray, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: _slateGray,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _paleGrayMint, width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _medicalMint, width: 1.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _errorRed, width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: _errorRed, width: 1.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _medicalMint,
                              foregroundColor: _deepNavy,
                              disabledBackgroundColor: _paleGrayMint,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: _deepNavy, strokeWidth: 2.2))
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.login_rounded, size: 18, color: _deepNavy),
                                    SizedBox(width: 8),
                                    Text('LOGIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: _deepNavy)),
                                  ]),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(fontSize: 13, color: _slateGray)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                              },
                              child: const Text('Register', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _deepNavy, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: _slateGray),
                            SizedBox(width: 6),
                            Text('Authorized Clinical Personnel Only', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: _slateGray)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text('Protected Health Information • HIPAA Compliant Session', style: TextStyle(fontSize: 10, color: Color(0xFF9EA9AC))),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

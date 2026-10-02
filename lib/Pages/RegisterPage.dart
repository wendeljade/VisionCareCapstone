import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'LoginPage.dart';
import 'AboutPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _clinicLocationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

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
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _licenseController.dispose();
    _clinicLocationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await AuthService().register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      licenseNumber: _licenseController.text.trim(),
      clinicLocation: _clinicLocationController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Registration successful! Please login with your credentials.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF3E9B78),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to Login screen with pre-filled username
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            prefilledUsername: _usernameController.text.trim(),
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage =
            'An account with this email or username already exists. Please login instead.';
      });
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _coolOffWhite,
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9EA9AC),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(prefixIcon, color: _slateGray, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: _paleGrayMint,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: _medicalMint,
          width: 1.8,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: _errorRed,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: _errorRed,
          width: 1.8,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _charcoalNavy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: _coolOffWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: height * 0.02,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height * 0.035),

                // ── Clinical Header (Consistent with Dashboard) ───────
                Column(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
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
    const SizedBox(height: 12),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor Registration',
          style: TextStyle(
            fontSize: width * 0.046,
            fontWeight: FontWeight.w800,
            color: _deepNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Diabetic Retinopathy Screening',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _slateGray,
          ),
        ),
      ],
    ),
    IconButton(
      icon: const Icon(
        Icons.info_outline_rounded,
        color: _deepNavy,
        size: 24,
      ),
      onPressed: () => AboutPage.showAsModal(context),
      tooltip: 'About VisionCare',
    ),
  ],
),
  ],
),

                SizedBox(height: height * 0.035),

                // ── Registration Card ───────────────────────────────
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
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: _deepNavy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _softMint,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBFE9DF),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Step 1 of 2',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _deepNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create your verified healthcare provider profile to begin screening.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _slateGray,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF8B4B4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: _errorRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: _errorRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 1. Full Name ──────────────────────────────
                      _buildFieldLabel('Full Name'),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. Dr. Juan Dela Cruz, MD',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── 2. Email Address ──────────────────────────
                      _buildFieldLabel('Email Address'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'doctor@hospital.org',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── 3. Username ───────────────────────────────
                      _buildFieldLabel('Username'),
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. dr.juandelacruz',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please choose a username';
                          }
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── 4. Professional License Number / PRC ──────
                      _buildFieldLabel('Professional License Number / PRC License Number'),
                      TextFormField(
                        controller: _licenseController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. PRC-0148291',
                          prefixIcon: Icons.assignment_ind_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your professional license number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── 5. Clinic/Hospital & Location (ONE field only) ──
                      _buildFieldLabel('Clinic/Hospital & Location'),
                      TextFormField(
                        controller: _clinicLocationController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. Bukidnon Provincial Hospital – Malaybalay City, Bukidnon',
                          prefixIcon: Icons.local_hospital_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your clinic/hospital & location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── 6. Password ───────────────────────────────
                      _buildFieldLabel('Password'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'At least 6 characters',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _slateGray,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── 7. Confirm Password ───────────────────────
                      _buildFieldLabel('Confirm Password'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _charcoalNavy,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Re-enter your password',
                          prefixIcon: Icons.lock_reset_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _slateGray,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            tooltip: _obscureConfirmPassword
                                ? 'Show password'
                                : 'Hide password',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Register Button ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _medicalMint,
                            foregroundColor: _deepNavy,
                            disabledBackgroundColor: _paleGrayMint,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: _deepNavy,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.how_to_reg_rounded,
                                      size: 19,
                                      color: _deepNavy,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'REGISTER ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: _deepNavy,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Already have an account? Login ────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(
                              fontSize: 13,
                              color: _slateGray,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _deepNavy,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Security Note ───────────────────────────────────
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 14,
                      color: _slateGray,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Credentials stored securely on device',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _slateGray,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

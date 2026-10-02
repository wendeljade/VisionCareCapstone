import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import './Scan.dart';
import './Dashboard.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/standardized_form_fields.dart';
import '../utils/form_theme_constants.dart';

class PatientDetails extends StatefulWidget {
  const PatientDetails({super.key});

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String _selectedGender = 'Male';

  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    setState(() {
      _ageController.text = age.toString();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FormThemeConstants.deepNavy),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          },
        ),
        title: const Text(
          'Patient Registration',
          style: TextStyle(
            color: FormThemeConstants.deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: FormThemeConstants.paleGrayMint, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clinical Information Card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FormThemeConstants.paleGrayMint, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0612343B),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FormThemeConstants.softMint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: FormThemeConstants.deepNavy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Demographics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: FormThemeConstants.deepNavy,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Please record official patient details',
                              style: TextStyle(
                                fontSize: 11,
                                color: FormThemeConstants.slateGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: FormThemeConstants.paleGrayMint, height: 1),
                    const SizedBox(height: 20),

                    // Full Name
                    StandardizedTextFormField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: FormValidators.validateFullName,
                      hintText: 'e.g. Maria Santos',
                    ),
                    const SizedBox(height: FormThemeConstants.fieldSpacing),

                    // Address
                    StandardizedTextFormField(
                      controller: _addressController,
                      labelText: 'Residential Address',
                      prefixIcon: Icons.home_outlined,
                      validator: FormValidators.validateAddress,
                      hintText: 'Enter complete residential address',
                      maxLines: 2,
                    ),
                    const SizedBox(height: FormThemeConstants.fieldSpacing),

                    // Contact Number
                    StandardizedTextFormField(
                      controller: _contactController,
                      labelText: 'Contact Number',
                      prefixIcon: Icons.phone_outlined,
                      validator: FormValidators.validateContactNumber,
                      keyboardType: TextInputType.phone,
                      hintText: 'e.g., +63 912 345 6789 or 09123456789',
                    ),
                    const SizedBox(height: FormThemeConstants.fieldSpacing),

                    // Birthday
                    StandardizedTextFormField(
                      controller: _birthdayController,
                      labelText: 'Date of Birth',
                      prefixIcon: Icons.calendar_today_outlined,
                      validator: FormValidators.validateBirthday,
                      hintText: 'MM/DD/YYYY',
                      readOnly: true,
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: FormThemeConstants.deepNavy,
                                  onPrimary: Colors.white,
                                  secondary: FormThemeConstants.medicalMint,
                                  onSurface: FormThemeConstants.charcoalNavy,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: FormThemeConstants.deepNavy,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          _birthdayController.text =
                              DateFormat('MM/dd/yyyy').format(pickedDate);
                          _calculateAge(pickedDate);
                        }
                      },
                    ),
                    const SizedBox(height: FormThemeConstants.fieldSpacing),

                    Row(
                      children: [
                        // Age
                        Expanded(
                          child: StandardizedTextFormField(
                            controller: _ageController,
                            labelText: 'Calculated Age',
                            prefixIcon: Icons.schedule_outlined,
                            keyboardType: TextInputType.number,
                            validator: FormValidators.validateAge,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Gender Dropdown
                        Expanded(
                          child: StandardizedDropdownFormField(
                            value: _selectedGender,
                            items: const ['Male', 'Female', 'Other'],
                            labelText: 'Gender',
                            prefixIcon: Icons.wc_outlined,
                            validator: FormValidators.validateGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value ?? 'Male';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Proceed Button
              StandardizedFormButton(
                label: 'PROCEED TO RETINA SCAN',

                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scan(
                          patientName: _nameController.text,
                          address: _addressController.text,
                          contactNumber: _contactController.text,
                          dateOfBirth: _birthdayController.text,
                          age: _ageController.text,
                          gender: _selectedGender,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}

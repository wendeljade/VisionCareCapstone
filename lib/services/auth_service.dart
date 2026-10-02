import '../database/database_helper.dart';

class DoctorUser {
  final int? id;
  final String fullName;
  final String email;
  final String username;
  final String licenseNumber;
  final String clinicLocation;

  DoctorUser({
    this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.licenseNumber,
    required this.clinicLocation,
  });

  factory DoctorUser.fromMap(Map<String, dynamic> map) {
    return DoctorUser(
      id: map['id'] is int ? map['id'] : null,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      clinicLocation: map['clinicLocation'] ?? '',
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // In-memory fallback for speed and resilience
  static final List<Map<String, String>> _inMemoryDoctors = [];
  static DoctorUser? currentDoctor;

  /// Register a doctor and save credentials locally
  Future<bool> register({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String licenseNumber,
    required String clinicLocation,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();
    final cleanFullName = fullName.trim();
    final cleanLicense = licenseNumber.trim();
    final cleanClinicLocation = clinicLocation.trim();

    try {
      final success = await _dbHelper.registerDoctor(
        fullName: cleanFullName,
        email: cleanEmail,
        username: cleanUsername,
        password: password,
        licenseNumber: cleanLicense,
        clinicLocation: cleanClinicLocation,
      );

      if (success) {
        _inMemoryDoctors.removeWhere(
          (d) => d['email'] == cleanEmail || d['username'] == cleanUsername,
        );
        _inMemoryDoctors.add({
          'fullName': cleanFullName,
          'email': cleanEmail,
          'username': cleanUsername,
          'password': password,
          'licenseNumber': cleanLicense,
          'clinicLocation': cleanClinicLocation,
        });
        return true;
      }
      return false;
    } catch (_) {
      // In-memory fallback
      final exists = _inMemoryDoctors.any(
        (d) => d['email'] == cleanEmail || d['username'] == cleanUsername,
      );
      if (exists) return false;

      _inMemoryDoctors.add({
        'fullName': cleanFullName,
        'email': cleanEmail,
        'username': cleanUsername,
        'password': password,
        'licenseNumber': cleanLicense,
        'clinicLocation': cleanClinicLocation,
      });
      return true;
    }
  }

  /// Authenticate doctor with email or username + password
  Future<DoctorUser?> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final cleanInput = emailOrUsername.trim().toLowerCase();

    try {
      final record = await _dbHelper.loginDoctor(
        emailOrUsername: cleanInput,
        password: password,
      );
      if (record != null) {
        currentDoctor = DoctorUser.fromMap(record);
        return currentDoctor;
      }
    } catch (_) {}

    // Check in-memory fallback
    for (final d in _inMemoryDoctors) {
      if ((d['email'] == cleanInput || d['username'] == cleanInput) &&
          d['password'] == password) {
        currentDoctor = DoctorUser.fromMap(d);
        return currentDoctor;
      }
    }

    return null;
  }

  /// Clear the current logged in session
  void logout() {
    currentDoctor = null;
  }

  /// Check if there are any registered doctors
  Future<bool> hasRegisteredDoctors() async {
    try {
      if (await _dbHelper.hasAnyDoctor()) return true;
    } catch (_) {}
    return _inMemoryDoctors.isNotEmpty;
  }
}

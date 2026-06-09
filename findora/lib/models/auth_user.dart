class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String cityOrUniversity;
  final String role;
  final bool isEmailVerified;
  final String avatarUrl;
  final bool notifications;
  final bool darkMode;
  final bool twoFactor;
  final bool biometric;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.cityOrUniversity,
    required this.role,
    required this.isEmailVerified,
    required this.avatarUrl,
    required this.notifications,
    required this.darkMode,
    required this.twoFactor,
    required this.biometric,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'] is Map<String, dynamic>
        ? json['preferences'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AuthUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      cityOrUniversity: json['cityOrUniversity']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isEmailVerified: json['isEmailVerified'] == true,
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      notifications: preferences['notifications'] != false,
      darkMode: preferences['darkMode'] == true,
      twoFactor: preferences['twoFactor'] == true,
      biometric: preferences['biometric'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'cityOrUniversity': cityOrUniversity,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'avatarUrl': avatarUrl,
      'preferences': {
        'notifications': notifications,
        'darkMode': darkMode,
        'twoFactor': twoFactor,
        'biometric': biometric,
      },
    };
  }
}

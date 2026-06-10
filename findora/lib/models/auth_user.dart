class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String cityOrUniversity;
  final String role;
  final bool isEmailVerified;
  final String avatarUrl;
  final String about;
  final bool notifications;
  final bool darkMode;
  final bool twoFactor;
  final bool biometric;
  final bool banned;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.cityOrUniversity,
    required this.role,
    required this.isEmailVerified,
    required this.avatarUrl,
    required this.about,
    required this.notifications,
    required this.darkMode,
    required this.twoFactor,
    required this.biometric,
    this.banned = false,
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
      about: json['about']?.toString() ?? '',
      notifications: preferences['notifications'] != false,
      darkMode: preferences['darkMode'] == true,
      twoFactor: preferences['twoFactor'] == true,
      biometric: preferences['biometric'] == true,
      banned: json['banned'] == true,
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
      'about': about,
      'preferences': {
        'notifications': notifications,
        'darkMode': darkMode,
        'twoFactor': twoFactor,
        'biometric': biometric,
      },
    };
  }
}

class ProfileStats {
  final int posts;
  final int claims;
  final int matches;

  const ProfileStats({
    required this.posts,
    required this.claims,
    required this.matches,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      posts: _toInt(json['posts']),
      claims: _toInt(json['claims']),
      matches: _toInt(json['matches']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

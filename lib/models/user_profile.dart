class UserProfile {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String location;
  final String role;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.location,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone': phone,
      'location': location,
    };
  }
}

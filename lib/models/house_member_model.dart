class HouseMember {
  final int userId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role; // "ADMIN", "MEMBER"

  HouseMember({
    required this.userId,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory HouseMember.fromJson(Map<String, dynamic> json) {
    return HouseMember(
      userId: json['userId'],
      email: json['email'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      role: json['role'],
    );
  }

  String get displayRole {
    if (role == 'ADMIN') return 'Admin'; 
    if (role == 'OWNER') return 'Owner';
    return 'Member';
  }
}
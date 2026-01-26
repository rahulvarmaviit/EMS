class User {
  final String id;
  final String mobileNumber;
  final String fullName;
  final String role;
  final String? email;
  final String? teamId;
  final String? teamName;

  User({
    required this.id,
    required this.mobileNumber,
    required this.fullName,
    required this.role,
    this.email,
    this.teamId,
    this.teamName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      mobileNumber: json['mobile_number'],
      fullName: json['full_name'],
      role: json['role'],
      email: json['email'],
      teamId: json['team_id'],
      teamName: json['team_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile_number': mobileNumber,
      'full_name': fullName,
      'role': role,
      'email': email,
      'team_id': teamId,
      'team_name': teamName,
    };
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isLead => role == 'LEAD';
  bool get isEmployee => role == 'EMPLOYEE';
}

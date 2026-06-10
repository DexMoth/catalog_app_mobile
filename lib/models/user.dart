class User {
  final int id;
  final String username;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;
  final bool requiresVerification;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.requiresVerification = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      user: json['userId'] != null ? User(
        id: json['userId'],
        username: json['username'],
        email: json['email'],
      ) : null,
      token: json['token'],
      requiresVerification: json['message']?.contains('код') ?? false,
    );
  }
}
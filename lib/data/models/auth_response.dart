class AuthResponse {
  final String accessToken;
  final String tokenType;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      user: json['user'],
    );
  }
}
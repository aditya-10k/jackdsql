// Auth Models with type safety

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
    };
  }
}

class GoogleAuthRequest {
  final String idToken;

  GoogleAuthRequest({required this.idToken});

  factory GoogleAuthRequest.fromJson(Map<String, dynamic> json) {
    return GoogleAuthRequest(
      idToken: (json['idToken'] ?? json['id_token'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
    };
  }
}

class AuthResponse {
  final String? message;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    this.message,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String?,
      accessToken: (json['access_token'] ?? json['accessToken'] ?? json['token'] ?? '') as String,
      refreshToken: (json['refresh_token'] ?? json['refreshToken'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

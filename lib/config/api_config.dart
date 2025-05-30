class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const int timeoutDuration = 30; // en secondes

  // URLs spécifiques
  static const String loginUrl = '$baseUrl/auth/login';
  static const String logoutUrl = '$baseUrl/auth/logout';
  static const String refreshTokenUrl = '$baseUrl/auth/refresh';

  // Headers par défaut
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers avec authentification
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
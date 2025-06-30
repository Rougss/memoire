class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const int timeoutDuration = 30; // en secondes

  // URLs spécifiques
  static const String loginUrl = '$baseUrl/login';        // ← Supprimé /auth
  static const String logoutUrl = '$baseUrl/logout';      // ← Supprimé /auth
  static const String refreshTokenUrl = '$baseUrl/refresh'; // ← Supprimé /auth
  static const String meUrl = '$baseUrl/me';

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
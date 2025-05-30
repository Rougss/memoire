import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/metier.dart';
import 'auth_service.dart';


class MetierService {
  static Future<List<Metier>> getAllMetiers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/common/metiers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> metiersJson = jsonResponse['data'];
          return metiersJson.map((json) => Metier.fromJson(json)).toList();
        } else {
          throw Exception('Format de réponse invalide');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des métiers: $e');
    }
  }
}
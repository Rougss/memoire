import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmploiDuTempsService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer le token d'authentification
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('user_token');

    print('🔑 Token trouvé: ${token ?? "AUCUN"}');
    print('🔑 Toutes les clés: ${prefs.getKeys()}');

    return token;
  }

  static Future<List<Map<String, dynamic>>> getMetiersAvecCompetences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/metiers-avec-competences'),
        headers: headers,
      );

      print('🎯 Réponse métiers avec compétences: ${response.statusCode}');
      print('🎯 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des métiers');
      }
    } catch (e) {
      print('❌ Erreur getMetiersAvecCompetences: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCompetencesAvecQuotaByMetier(int metierId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/competences-avec-quota-metier/$metierId'),
        headers: headers,
      );

      print('📚 Réponse compétences du métier $metierId: ${response.statusCode}');
      print('📚 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des compétences du métier');
      }
    } catch (e) {
      print('❌ Erreur getCompetencesAvecQuotaByMetier: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCompetencesMetier(int metierId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers/$metierId/competences'),
        headers: headers,
      );

      print('📚 Réponse toutes compétences du métier $metierId: ${response.statusCode}');
      print('📚 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des compétences');
      }
    } catch (e) {
      print('❌ Erreur getCompetencesMetier: $e');
      throw Exception('Erreur: $e');
    }
  }



  // Headers avec authentification
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========================================
  // MÉTHODES DE RÉCUPÉRATION
  // ========================================

  // 🎓 RÉCUPÉRER L'EMPLOI DU TEMPS SPÉCIFIQUE À L'ÉLÈVE
  static Future<List<Map<String, dynamic>>> getEmploisEleve() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/eleve/mon-emploi-du-temps'),
        headers: headers,
      );

      print('📅 Réponse getEmploisEleve: ${response.statusCode}');
      print('📅 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la récupération');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getEmploisEleve: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 📅 RÉCUPÉRER TOUS LES EMPLOIS DU TEMPS (ADMIN)
  static Future<List<Map<String, dynamic>>> getAllEmplois() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps'),
        headers: headers,
      );

      print('📅 Réponse getAllEmplois: ${response.statusCode}');

      // 🔧 AJOUT : Vérifier la taille de la réponse
      print('📅 Taille réponse: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        try {
          // 🔧 AJOUT : Nettoyer la réponse avant parsing
          String cleanBody = response.body.trim();

          // Vérifier si le JSON est complet (doit finir par '}' ou ']')
          if (!cleanBody.endsWith('}') && !cleanBody.endsWith(']')) {
            print('⚠️ JSON incomplet détecté, tentative de correction...');

            // Essayer de trouver la dernière structure complète
            int lastCompleteIndex = cleanBody.lastIndexOf('}}');
            if (lastCompleteIndex > 0) {
              cleanBody = cleanBody.substring(0, lastCompleteIndex + 2) + ']}';
            }
          }

          final data = json.decode(cleanBody);
          if (data['success'] == true) {
            return List<Map<String, dynamic>>.from(data['data'] ?? []);
          } else {
            throw Exception(data['message'] ?? 'Erreur lors de la récupération');
          }
        } catch (jsonError) {
          print('❌ Erreur JSON: $jsonError');
          print('📄 Body problématique (100 derniers caractères): ${response.body.substring(response.body.length - 100)}');

          // Essayer une récupération partielle
          return _tryPartialJsonRecovery(response.body);
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getAllEmplois: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 🆘 RÉCUPÉRATION PARTIELLE DU JSON
  static List<Map<String, dynamic>> _tryPartialJsonRecovery(String brokenJson) {
    try {
      print('🛠️ Tentative de récupération partielle du JSON...');

      // Chercher le début des données
      int dataStartIndex = brokenJson.indexOf('"data":[');
      if (dataStartIndex == -1) {
        print('❌ Impossible de trouver le début des données');
        return [];
      }

      // Essayer de trouver des emplois complets
      List<Map<String, dynamic>> partialEmplois = [];
      String dataSection = brokenJson.substring(dataStartIndex + 8); // Après '"data":['

      // Parser manuellement les emplois complets
      List<String> emploiStrings = dataSection.split('{"id":');

      for (int i = 1; i < emploiStrings.length; i++) {
        try {
          String emploiJson = '{"id":' + emploiStrings[i];

          // Essayer de trouver la fin de cet emploi
          int nextEmploiIndex = emploiJson.indexOf(',{"id":');
          if (nextEmploiIndex > 0) {
            emploiJson = emploiJson.substring(0, nextEmploiIndex);
          } else {
            // Dernier emploi, chercher la fin
            int endIndex = emploiJson.lastIndexOf('}');
            if (endIndex > 0) {
              emploiJson = emploiJson.substring(0, endIndex + 1);
            }
          }

          // Tenter de parser cet emploi
          final emploi = json.decode(emploiJson);
          partialEmplois.add(Map<String, dynamic>.from(emploi));

        } catch (e) {
          print('⚠️ Emploi $i non récupérable: $e');
          continue;
        }

        // Limiter pour éviter trop de traitements
        if (partialEmplois.length >= 20) break;
      }

      print('✅ Récupération partielle: ${partialEmplois.length} emplois sauvés');
      return partialEmplois;

    } catch (e) {
      print('❌ Échec récupération partielle: $e');
      return [];
    }
  }

  // 🗓️ RÉCUPÉRER L'EMPLOI DU TEMPS D'UN FORMATEUR
  static Future<List<Map<String, dynamic>>> getEmploiFormateur({
    required int formateurId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/formateur/$formateurId?date_debut=$dateDebut&date_fin=$dateFin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération de l\'emploi du formateur');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // 🎓 RÉCUPÉRER L'EMPLOI DU TEMPS D'UNE ANNÉE
  static Future<List<Map<String, dynamic>>> getEmploiAnnee({
    required int anneeId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/annee/$anneeId?date_debut=$dateDebut&date_fin=$dateFin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération de l\'emploi de l\'année');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Récupérer toutes les années
  static Future<List<Map<String, dynamic>>> getAllAnnees() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/annees'),
        headers: headers,
      );

      print('📚 Réponse getAllAnnees: ${response.statusCode}');
      print('📚 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Erreur lors de la récupération des années');
      }
    } catch (e) {
      print('❌ Erreur getAllAnnees: $e');
      throw Exception('Erreur: $e');
    }
  }

  // 📚 RÉCUPÉRER TOUTES LES COMPÉTENCES
  static Future<List<Map<String, dynamic>>> getCompetences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/competences'),
        headers: headers,
      );

      print('📚 Réponse getCompetences: ${response.statusCode}');
      print('📚 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Erreur lors de la récupération des compétences');
      }
    } catch (e) {
      print('❌ Erreur getCompetences: $e');
      throw Exception('Erreur: $e');
    }
  }

  // 🎯 RÉCUPÉRER LES COMPÉTENCES AVEC QUOTA RESTANT
  static Future<List<Map<String, dynamic>>> getCompetencesAvecQuota({int? metierId}) async {
    try {
      final headers = await _getHeaders();

      // 🆕 Construire l'URL avec le paramètre métier si fourni
      String url = '$baseUrl/admin/emploi-du-temps/competences-avec-quota';
      if (metierId != null) {
        url += '?metier_id=$metierId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🎯 Réponse compétences avec quota${metierId != null ? " (métier $metierId)" : ""}: ${response.statusCode}');
      print('🎯 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des compétences avec quota');
      }
    } catch (e) {
      print('❌ Erreur getCompetencesAvecQuota: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>> getResumeMetier(int metierId) async {
    try {
      final results = await Future.wait([
        getCompetencesAvecQuotaByMetier(metierId),

      ]);

      final competences = results[0] as List<Map<String, dynamic>>;
      final statistiques = results[1] as Map<String, dynamic>;

      return {
        'metier_id': metierId,
        'competences_disponibles': competences.length,
        'total_quota_restant': competences.fold<double>(
            0, (sum, comp) => sum + (comp['heures_restantes'] ?? 0.0)
        ),
        'statistiques': statistiques,
        'competences': competences,
      };
    } catch (e) {
      print('❌ Erreur getResumeMétier: $e');
      throw Exception('Erreur: $e');
    }
  }
  // Récupérer les années d'un département
  static Future<List<Map<String, dynamic>>> getAnneesByDepartement(int departementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/annees?departement_id=$departementId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des années');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Récupérer les infos utilisateur
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      print('👤 Réponse getUserInfo: ${response.statusCode}');
      print('👤 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getUserInfo: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getQuotasStatut() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/quotas-statut'),
        headers: headers,
      );

      print('📊 Réponse quotas statut: ${response.statusCode}');
      print('📊 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des quotas');
      }
    } catch (e) {
      print('❌ Erreur getQuotasStatut: $e');
      throw Exception('Erreur: $e');
    }
  }

  // ========================================
  // MÉTHODES DE CRÉATION
  // ========================================

  // ➕ CRÉER UN NOUVEAU CRÉNEAU
  static Future<Map<String, dynamic>> creerCreneau({
    required int anneeId,
    required String heureDebut,
    required String heureFin,
    required String dateDebut,
    required String dateFin,
    List<int>? competences,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'heure_debut': heureDebut,
        'heure_fin': heureFin,
        'date_debut': dateDebut,
        'date_fin': dateFin,
        if (competences != null && competences.isNotEmpty)
          'competences': competences,
      };

      print('➕ Création créneau: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps'),
        headers: headers,
        body: json.encode(body),
      );

      print('➕ Réponse création: ${response.statusCode}');
      print('➕ Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur creerCreneau: $e');
      throw Exception('Erreur de création: $e');
    }
  }

  // ========================================
  // MÉTHODES DE PLANIFICATION
  // ========================================

  // 🆕 PLANIFICATION INTELLIGENTE LIMITÉE
  static Future<Map<String, dynamic>> planifierCompetencesLimitees({
    required int anneeId,
    required String dateDebut,
    required List<Map<String, dynamic>> competences,
    required int maxSeancesParCompetence,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'date_debut': dateDebut,
        'competences': competences,
        'max_seances_par_competence': maxSeancesParCompetence,
        'mode': 'intelligent_limite',
      };

      print('🎯 Planification limitée: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/planifier-intelligent'),
        headers: headers,
        body: json.encode(body),
      );

      print('🎯 Réponse planification limitée: ${response.statusCode}');
      print('🎯 Body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la planification');
      }
    } catch (e) {
      print('❌ Erreur planifierCompetencesLimitees: $e');
      throw Exception('Erreur de planification: $e');
    }
  }

  // 🆕 ANCIENNE MÉTHODE (pour compatibilité)
  static Future<Map<String, dynamic>> planifierCompetences({
    required int anneeId,
    required String dateDebut,
    required List<Map<String, dynamic>> competences,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'date_debut': dateDebut,
        'competences': competences,
      };

      print('🎯 Planification compétences: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/planifier-competences'),
        headers: headers,
        body: json.encode(body),
      );

      print('🎯 Réponse planification: ${response.statusCode}');
      print('🎯 Body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la planification');
      }
    } catch (e) {
      print('❌ Erreur planifierCompetences: $e');
      throw Exception('Erreur de planification: $e');
    }
  }

  // ========================================
  // MÉTHODES D'ANALYSE ET PREVIEW
  // ========================================

  // 🆕 OBTENIR LE STATUT DES QUOTAS APRÈS PLANIFICATION
  static Future<Map<String, dynamic>> getQuotasApresLimitation({
    required List<Map<String, dynamic>> competences,
    required int maxSeancesParCompetence,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'competences': competences,
        'max_seances_par_competence': maxSeancesParCompetence,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/preview-limitation'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du calcul');
      }
    } catch (e) {
      print('❌ Erreur getQuotasApresLimitation: $e');
      throw Exception('Erreur de calcul: $e');
    }
  }

  // 🆕 VÉRIFIER LA DISPONIBILITÉ DES FORMATEURS
  static Future<Map<String, dynamic>> verifierDisponibiliteFormateurs({
    required List<int> formateurIds,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'formateur_ids': formateurIds,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/verifier-disponibilite'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la vérification');
      }
    } catch (e) {
      print('❌ Erreur verifierDisponibiliteFormateurs: $e');
      throw Exception('Erreur de vérification: $e');
    }
  }

  // ========================================
  // MÉTHODES D'ANALYSE ET RAPPORTS
  // ========================================

  // 🤖 GÉNÉRATION AUTOMATIQUE (ANCIENNE MÉTHODE)
  static Future<Map<String, dynamic>> genererAutomatique({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      print('🤖 Génération auto: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/generer-auto'),
        headers: headers,
        body: json.encode(body),
      );

      print('🤖 Réponse génération: ${response.statusCode}');
      print('🤖 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la génération');
      }
    } catch (e) {
      print('❌ Erreur génération auto: $e');
      throw Exception('Erreur de génération: $e');
    }
  }

  // 📊 ANALYSER L'EMPLOI DU TEMPS
  static Future<Map<String, dynamic>> analyserEmploi({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/analyser'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'analyse');
      }
    } catch (e) {
      print('❌ Erreur analyse: $e');
      throw Exception('Erreur d\'analyse: $e');
    }
  }

  // 📈 GÉNÉRER UN RAPPORT
  static Future<Map<String, dynamic>> genererRapport({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/rapport'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du rapport');
      }
    } catch (e) {
      print('❌ Erreur rapport: $e');
      throw Exception('Erreur de rapport: $e');
    }
  }

  // 🔄 PROPOSER UNE RÉORGANISATION
  static Future<Map<String, dynamic>> proposerReorganisation({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/reorganiser'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la réorganisation');
      }
    } catch (e) {
      print('❌ Erreur réorganisation: $e');
      throw Exception('Erreur de réorganisation: $e');
    }
  }

  // 🆕 OPTIMISER LA RÉPARTITION DES CRÉNEAUX
  static Future<Map<String, dynamic>> optimiserRepartition({
    required int anneeId,
    required String dateDebut,
    required List<Map<String, dynamic>> competences,
    required int maxSeancesParCompetence,
    String? algorithme, // 'equilibre', 'chrono', 'formateur'
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'date_debut': dateDebut,
        'competences': competences,
        'max_seances_par_competence': maxSeancesParCompetence,
        'algorithme': algorithme ?? 'equilibre',
        'options': {
          'eviter_conflits': true,
          'respecter_pauses': true,
          'equilibrer_charges': true,
        }
      };

      print('🔀 Optimisation répartition: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/optimiser-repartition'),
        headers: headers,
        body: json.encode(body),
      );

      print('🔀 Réponse optimisation: ${response.statusCode}');
      print('🔀 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'optimisation');
      }
    } catch (e) {
      print('❌ Erreur optimiserRepartition: $e');
      throw Exception('Erreur d\'optimisation: $e');
    }
  }
  static Future<Map<String, dynamic>> deplacerCours(
      int emploiId,
      String nouvelleDate,
      String nouvelleHeureDebut,
      String nouvelleHeureFin,
      String raisonDeplacement,
      ) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'nouvelle_date': nouvelleDate,
        'nouvelle_heure_debut': nouvelleHeureDebut,
        'nouvelle_heure_fin': nouvelleHeureFin,
        'raison_deplacement': raisonDeplacement,
      };

      print('🎯 Déplacement cours $emploiId: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/emploi-du-temps/$emploiId/deplacer'),
        headers: headers,
        body: json.encode(body),
      );

      print('🎯 Réponse déplacement: ${response.statusCode}');
      print('🎯 Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        // Retourner les conflits et suggestions s'il y en a
        return data;
      }
    } catch (e) {
      print('❌ Erreur deplacerCours: $e');
      throw Exception('Erreur de déplacement: $e');
    }
  }
}
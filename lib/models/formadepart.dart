import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;


class Formateur {
  final int id;
  final String nom;
  final String email;
  final String telephone;
  final int? idSpecialite;
  final bool estChef;
  final int? departementChefId; // Département qu'il dirige (si chef)
  final List<int> departementsIds; // Départements où il enseigne
  final String? specialiteNom;

  Formateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    this.idSpecialite,
    this.estChef = false,
    this.departementChefId,
    this.departementsIds = const [],
    this.specialiteNom,
  });

  factory Formateur.fromJson(Map<String, dynamic> json) {
    return Formateur(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      telephone: json['telephone'],
      idSpecialite: json['id_specialite'],
      estChef: json['est_chef'] ?? false,
      departementChefId: json['departement_chef_id'],
      departementsIds: json['departements_ids'] != null
          ? List<int>.from(json['departements_ids'])
          : [],
      specialiteNom: json['specialite_nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'id_specialite': idSpecialite,
      'est_chef': estChef,
      'departement_chef_id': departementChefId,
      'departements_ids': departementsIds,
    };
  }

  // Méthodes utiles
  bool estChefDe(int departementId) => departementChefId == departementId;
  bool appartientA(int departementId) => departementsIds.contains(departementId);
}

class Departement {
  final int id;
  final String nomDepartement;
  final int? idChef;
  final String? nomChef;
  final List<int> formateursIds;

  Departement({
    required this.id,
    required this.nomDepartement,
    this.idChef,
    this.nomChef,
    this.formateursIds = const [],
  });

  factory Departement.fromJson(Map<String, dynamic> json) {
    return Departement(
      id: json['id'],
      nomDepartement: json['nom_departement'],
      idChef: json['id_chef'],
      nomChef: json['nom_chef'],
      formateursIds: json['formateurs_ids'] != null
          ? List<int>.from(json['formateurs_ids'])
          : [],
    );
  }

  bool aChef() => idChef != null;
  bool aFormateur(int formateurId) => formateursIds.contains(formateurId);
}

class CreneauDisponible {
  final DateTime debut;
  final DateTime fin;
  final List<int> formateursDisponibles;
  final String description;

  CreneauDisponible({
    required this.debut,
    required this.fin,
    required this.formateursDisponibles,
    required this.description,
  });
}

// 2. SERVICE API AMÉLIORÉ

class FormateurDepartementService {
  static const String baseUrl = 'http://your-api-url/api';

  // Connexion et récupération du profil formateur
  static Future<Map<String, dynamic>?> connexionFormateur(String email, String motDePasse) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/formateur'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'mot_de_passe': motDePasse,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer le profil complet d'un formateur
  static Future<Formateur?> getProfilFormateur(int idFormateur) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/formateurs/$idFormateur/profil-complet'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Formateur.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Récupérer les créneaux disponibles pour planifier
  static Future<List<CreneauDisponible>> getCreneauxDisponibles(
      List<int> formateursIds,
      DateTime dateDebut,
      DateTime dateFin,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/creneaux-disponibles'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'formateurs_ids': formateursIds,
          'date_debut': dateDebut.toIso8601String(),
          'date_fin': dateFin.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => CreneauDisponible(
          debut: DateTime.parse(item['debut']),
          fin: DateTime.parse(item['fin']),
          formateursDisponibles: List<int>.from(item['formateurs_disponibles']),
          description: item['description'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Planifier une séance
  static Future<bool> planifierSeance({
    required int idFormateur,
    required int idDepartement,
    required DateTime debut,
    required DateTime fin,
    required String titre,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emploi-du-temps/planifier'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_formateur': idFormateur,
          'id_departement': idDepartement,
          'heure_debut': debut.toIso8601String(),
          'heure_fin': fin.toIso8601String(),
          'titre': titre,
          'description': description,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

// 3. PROVIDER POUR LA GESTION D'ÉTAT

class FormateurDepartementProvider extends ChangeNotifier {
  Formateur? _formateurConnecte;
  List<Departement> _departements = [];
  List<Formateur> _formateurs = [];
  List<CreneauDisponible> _creneauxDisponibles = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Formateur? get formateurConnecte => _formateurConnecte;
  List<Departement> get departements => _departements;
  List<Formateur> get formateurs => _formateurs;
  List<CreneauDisponible> get creneauxDisponibles => _creneauxDisponibles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Connexion
  Future<bool> seConnecter(String email, String motDePasse) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authData = await FormateurDepartementService.connexionFormateur(email, motDePasse);

      if (authData != null) {
        final profil = await FormateurDepartementService.getProfilFormateur(authData['id']);

        if (profil != null) {
          _formateurConnecte = profil;
          await _chargerDonneesFormateur();
          return true;
        }
      }

      _error = 'Échec de la connexion';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les données du formateur connecté
  Future<void> _chargerDonneesFormateur() async {
    if (_formateurConnecte == null) return;

    try {
      // Charger les départements où il enseigne
      _departements = await _getDepartementsFormateur(_formateurConnecte!.id);

      // Si c'est un chef, charger aussi son département
      if (_formateurConnecte!.estChef && _formateurConnecte!.departementChefId != null) {
        // Charger les formateurs de son département
        _formateurs = await _getFormateurs; DuDepartement(_formateurConnecte!.departementChefId!);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Obtenir les départements d'un formateur
  Future<List<Departement>> _getDepartementsFormateur(int idFormateur) async {
    // Implémentation API call
    return [];
  }

  // Obtenir les formateurs d'un département
  late Future<List<Formateur>> _getFormateurs; DuDepartement(int idDepartement) async {
    // Implémentation API call
    return [];
  }

  // Fonctionnalités selon le rôle du formateur

  // Pour un formateur normal : voir ses créneaux
  Future<void> chargerMesCreneaux() async {
    if (_formateurConnecte == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      DateTime maintenant = DateTime.now();
      DateTime finSemaine = maintenant.add(Duration(days: 7));

      _creneauxDisponibles = await FormateurDepartementService.getCreneauxDisponibles(
        [_formateurConnecte!.id],
        maintenant,
        finSemaine,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pour un chef de département : planifier avec son équipe
  Future<void> planifierAvecEquipe({
    required List<int> formateursIds,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    if (_formateurConnecte == null || !_formateurConnecte!.estChef) return;

    _isLoading = true;
    notifyListeners();

    try {
      _creneauxDisponibles = await FormateurDepartementService.getCreneauxDisponibles(
        formateursIds,
        dateDebut,
        dateFin,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Planifier une séance
  Future<bool> planifierSeance({
    required DateTime debut,
    required DateTime fin,
    required String titre,
    String? description,
    int? departementId,
  }) async {
    if (_formateurConnecte == null) return false;

    final success = await FormateurDepartementService.planifierSeance(
      idFormateur: _formateurConnecte!.id,
      idDepartement: departementId ?? _formateurConnecte!.departementsIds.first,
      debut: debut,
      fin: fin,
      titre: titre,
      description: description,
    );

    if (success) {
      await chargerMesCreneaux();
    }

    return success;
  }

  // Vérifications utiles
  bool peutPlanifierPour(int formateurId) {
    if (_formateurConnecte == null) return false;

    // Peut planifier pour lui-même
    if (_formateurConnecte!.id == formateurId) return true;

    // S'il est chef, peut planifier pour son équipe
    if (_formateurConnecte!.estChef) {
      return _formateurs.any((f) => f.id == formateurId);
    }

    return false;
  }

  bool estDansMemeDepartement(int formateurId) {
    if (_formateurConnecte == null) return false;

    final autreFormateur = _formateurs.firstWhere(
          (f) => f.id == formateurId,
      orElse: () => Formateur(id: -1, nom: '', email: '', telephone: ''),
    );

    if (autreFormateur.id == -1) return false;

    // Vérifier s'ils partagent au moins un département
    return _formateurConnecte!.departementsIds.any(
            (deptId) => autreFormateur.departementsIds.contains(deptId)
    );
  }

  void deconnecter() {
    _formateurConnecte = null;
    _departements.clear();
    _formateurs.clear();
    _creneauxDisponibles.clear();
    _error = null;
    notifyListeners();
  }
}

// 4. ALGORITHME INTELLIGENT POUR L'EMPLOI DU TEMPS

class EmploiDuTempsAlgorithme {

  // Analyser les disponibilités communes
  static Map<String, dynamic> analyserDisponibilites(
      List<Formateur> formateurs,
      DateTime dateDebut,
      DateTime dateFin,
      List<Map<String, dynamic>> planningsExistants,
      ) {
    Map<String, List<int>> creneauxCommuns = {};
    Map<String, int> scoreDisponibilite = {};

    // Pour chaque jour de la période
    DateTime dateActuelle = dateDebut;
    while (dateActuelle.isBefore(dateFin)) {
      if (dateActuelle.weekday < 6) { // Lundi à Vendredi

        // Créneaux de 2h de 8h à 18h
        for (int heure = 8; heure < 18; heure += 2) {
          DateTime debutCreneau = DateTime(
            dateActuelle.year,
            dateActuelle.month,
            dateActuelle.day,
            heure,
          );
          DateTime finCreneau = debutCreneau.add(Duration(hours: 2));

          String cleCreneau = '${debutCreneau.millisecondsSinceEpoch}';
          List<int> formateursDisponibles = [];

          // Vérifier chaque formateur
          for (Formateur formateur in formateurs) {
            if (!_aConflitHoraire(formateur.id, debutCreneau, finCreneau, planningsExistants)) {
              formateursDisponibles.add(formateur.id);
            }
          }

          if (formateursDisponibles.isNotEmpty) {
            creneauxCommuns[cleCreneau] = formateursDisponibles;
            scoreDisponibilite[cleCreneau] = formateursDisponibles.length;
          }
        }
      }
      dateActuelle = dateActuelle.add(Duration(days: 1));
    }

    return {
      'creneaux_communs': creneauxCommuns,
      'scores': scoreDisponibilite,
    };
  }

  // Suggérer les meilleurs créneaux
  static List<CreneauDisponible> suggererMeilleursCreneaux(
      List<Formateur> formateurs,
      DateTime dateDebut,
      DateTime dateFin,
      List<Map<String, dynamic>> planningsExistants, {
        int nombreSuggestions = 5,
      }) {
    final analyse = analyserDisponibilites(formateurs, dateDebut, dateFin, planningsExistants);

    Map<String, List<int>> creneauxCommuns = analyse['creneaux_communs'];
    Map<String, int> scores = analyse['scores'];

    // Trier par score décroissant
    List<MapEntry<String, int>> creneauxTries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<CreneauDisponible> suggestions = [];

    for (int i = 0; i < math.min(nombreSuggestions, creneauxTries.length); i++) {
      String cle = creneauxTries[i].key;
      DateTime debut = DateTime.fromMillisecondsSinceEpoch(int.parse(cle));
      DateTime fin = debut.add(Duration(hours: 2));

      List<int> formateursDisponibles = creneauxCommuns[cle] ?? [];

      suggestions.add(CreneauDisponible(
        debut: debut,
        fin: fin,
        formateursDisponibles: formateursDisponibles,
        description: _genererDescriptionCreneau(debut, formateursDisponibles.length, formateurs.length),
      ));
    }

    return suggestions;
  }

  // Optimiser l'emploi du temps d'un département
  static Map<String, dynamic> optimiserEmploiDuTemps({
    required List<Formateur> formateurs,
    required List<Map<String, dynamic>> seancesAPlanifier,
    required DateTime dateDebut,
    required DateTime dateFin,
    required List<Map<String, dynamic>> planningsExistants,
  }) {
    List<Map<String, dynamic>> planningOptimise = [];
    List<Map<String, dynamic>> conflitsDetectes = [];

    // Trier les séances par priorité (nombre de formateurs requis)
    seancesAPlanifier.sort((a, b) {
      List<int> formateursA = List<int>.from(a['formateurs_requis'] ?? []);
      List<int> formateursB = List<int>.from(b['formateurs_requis'] ?? []);
      return formateursB.length.compareTo(formateursA.length);
    });

    // Planifier chaque séance
    for (var seance in seancesAPlanifier) {
      List<int> formateursRequis = List<int>.from(seance['formateurs_requis'] ?? []);
      List<Formateur> formateursSeance = formateurs.where(
              (f) => formateursRequis.contains(f.id)
      ).toList();

      List<CreneauDisponible> creneauxPossibles = suggererMeilleursCreneaux(
        formateursSeance,
        dateDebut,
        dateFin,
        [...planningsExistants, ...planningOptimise],
        nombreSuggestions: 1,
      );

      if (creneauxPossibles.isNotEmpty) {
        CreneauDisponible meilleurCreneau = creneauxPossibles.first;

        planningOptimise.add({
          'id_seance': seance['id'],
          'titre': seance['titre'],
          'debut': meilleurCreneau.debut.toIso8601String(),
          'fin': meilleurCreneau.fin.toIso8601String(),
          'formateurs': formateursRequis,
        });
      } else {
        conflitsDetectes.add({
          'seance': seance,
          'probleme': 'Aucun créneau disponible pour tous les formateurs requis',
        });
      }
    }

    return {
      'planning_optimise': planningOptimise,
      'conflits': conflitsDetectes,
      'taux_reussite': planningOptimise.length / seancesAPlanifier.length,
    };
  }

  // Méthodes utilitaires privées
  static bool _aConflitHoraire(
      int idFormateur,
      DateTime debut,
      DateTime fin,
      List<Map<String, dynamic>> plannings,
      ) {
    for (var planning in plannings) {
      if (planning['id_formateur'] == idFormateur) {
        DateTime debutExistant = DateTime.parse(planning['heure_debut']);
        DateTime finExistante = DateTime.parse(planning['heure_fin']);

        if (debut.isBefore(finExistante) && fin.isAfter(debutExistant)) {
          return true;
        }
      }
    }
    return false;
  }

  static String _genererDescriptionCreneau(DateTime debut, int disponibles, int total) {
    String jour = _getJourSemaine(debut.weekday);
    String heure = '${debut.hour}h${debut.minute.toString().padLeft(2, '0')}';

    return '$jour $heure - $disponibles/$total formateurs disponibles';
  }

  static String _getJourSemaine(int weekday) {
    const jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return jours[weekday];
  }
}
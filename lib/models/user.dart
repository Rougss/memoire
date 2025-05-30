import '../models/role.dart';

class User {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? adresse;
  final String? matricule;
  final DateTime? dateNaissance;
  final String? genre;
  final String? lieuNaissance;
  final String? photo;
  final int roleId;
  final Role? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? motDePasse;

  // Champs spécifiques selon le rôle
  final int? specialiteId; // Pour formateur
  final int? metierId; // Pour élève
  final String? contactUrgence; // Pour élève

  User({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.adresse,
    this.matricule,
    this.dateNaissance,
    this.genre,
    this.lieuNaissance,
    this.photo,
    required this.roleId,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.motDePasse,
    this.specialiteId,
    this.metierId,
    this.contactUrgence,
  });

  String get nomComplet => '$prenom $nom';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      adresse: json['adresse'],
      matricule: json['matricule'],
      dateNaissance: json['date_naissance'] != null
          ? DateTime.parse(json['date_naissance'])
          : null,
      genre: json['genre'],
      lieuNaissance: json['lieu_naissance'],
      photo: json['photo'],
      roleId: json['role_id'] ?? 0,
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      motDePasse: json['mot_de_passe'],
      specialiteId: json['specialite_id'],
      metierId: json['metier_id'],
      contactUrgence: json['contact_urgence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'matricule': matricule,
      'date_naissance': dateNaissance?.toIso8601String(),
      'genre': genre,
      'lieu_naissance': lieuNaissance,
      'photo': photo,
      'role_id': roleId,
      'role': role?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'mot_de_passe': motDePasse,
      'specialite_id': specialiteId,
      'metier_id': metierId,
      'contact_urgence': contactUrgence,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'matricule': matricule,
      'date_naissance': dateNaissance?.toIso8601String(),
      'genre': genre,
      'lieu_naissance': lieuNaissance,
      'photo': photo,
      'role_id': roleId,
      'mot_de_passe': motDePasse,
      'specialite_id': specialiteId,
      'metier_id': metierId,
      'contact_urgence': contactUrgence,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{};

    if (nom.isNotEmpty) data['nom'] = nom;
    if (prenom.isNotEmpty) data['prenom'] = prenom;
    if (email.isNotEmpty) data['email'] = email;
    if (telephone != null) data['telephone'] = telephone;
    if (adresse != null) data['adresse'] = adresse;
    if (matricule != null) data['matricule'] = matricule;
    if (dateNaissance != null) data['date_naissance'] = dateNaissance!.toIso8601String();
    if (genre != null) data['genre'] = genre;
    if (lieuNaissance != null) data['lieu_naissance'] = lieuNaissance;
    if (photo != null) data['photo'] = photo;
    data['role_id'] = roleId;
    if (motDePasse != null) data['mot_de_passe'] = motDePasse;
    if (specialiteId != null) data['specialite_id'] = specialiteId;
    if (metierId != null) data['metier_id'] = metierId;
    if (contactUrgence != null) data['contact_urgence'] = contactUrgence;

    return data;
  }

  User copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? matricule,
    DateTime? dateNaissance,
    String? genre,
    String? lieuNaissance,
    String? photo,
    int? roleId,
    Role? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? motDePasse,
    int? specialiteId,
    int? metierId,
    String? contactUrgence,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      matricule: matricule ?? this.matricule,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      genre: genre ?? this.genre,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      photo: photo ?? this.photo,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      motDePasse: motDePasse ?? this.motDePasse,
      specialiteId: specialiteId ?? this.specialiteId,
      metierId: metierId ?? this.metierId,
      contactUrgence: contactUrgence ?? this.contactUrgence,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.nom == nom &&
        other.prenom == prenom &&
        other.email == email &&
        other.telephone == telephone &&
        other.adresse == adresse &&
        other.matricule == matricule &&
        other.dateNaissance == dateNaissance &&
        other.genre == genre &&
        other.lieuNaissance == lieuNaissance &&
        other.photo == photo &&
        other.roleId == roleId &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.motDePasse == motDePasse &&
        other.specialiteId == specialiteId &&
        other.metierId == metierId &&
        other.contactUrgence == contactUrgence;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      nom,
      prenom,
      email,
      telephone,
      adresse,
      matricule,
      dateNaissance,
      genre,
      lieuNaissance,
      photo,
      roleId,
      role,
      createdAt,
      updatedAt,
      motDePasse,
      specialiteId,
      metierId,
      contactUrgence,
    ]);
  }

  @override
  String toString() {
    return 'User(id: $id, nom: $nom, prenom: $prenom, email: $email, roleId: $roleId)';
  }

  // Méthodes utilitaires

  int get age {
    if (dateNaissance == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateNaissance!.year;
    if (now.month < dateNaissance!.month ||
        (now.month == dateNaissance!.month && now.day < dateNaissance!.day)) {
      age--;
    }
    return age;
  }
}
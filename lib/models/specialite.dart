class Specialite {
  final int? id;
  final String nom;
  final String? description;

  Specialite({
    this.id,
    required this.nom,
    this.description,
  });

  factory Specialite.fromJson(Map<String, dynamic> json) {
    return Specialite(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
    };
  }
}
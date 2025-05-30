class Metier {
  final int? id;
  final String nom;
  final String? description;

  Metier({
    this.id,
    required this.nom,
    this.description,
  });

  factory Metier.fromJson(Map<String, dynamic> json) {
    return Metier(
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
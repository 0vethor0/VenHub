class Perfil {
  final String id;
  final String email;
  final String nombre;

  Perfil({required this.id, required this.email, required this.nombre});

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id']?.toString() ?? '',
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'nombre': nombre};
  }
}

// lib/models/usuario.dart

import '../services/api_service.dart'; // Import necessário para pegar o ID do negócio

class Usuario {
  final String id;
  final String firebaseUid;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoPerfil;
  final String role;
  final bool ativo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Usuario({
    required this.id,
    required this.firebaseUid,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoPerfil,
    required this.role,
    required this.ativo,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===================================================================
  // FÁBRICA CORRIGIDA PARA LER A ROLE DO MAPA "roles"
  // ===================================================================
  factory Usuario.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTime(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      return DateTime.parse(dateStr);
    }

    String _extractRole(Map<String, dynamic> json) {
      // Primeiro, tenta pegar de um campo simples 'role', se existir
      if (json['role'] is String) {
        return json['role'];
      }
      // Se não, procura no mapa 'roles' usando o ID do negócio
      if (json['roles'] is Map) {
        final rolesMap = json['roles'] as Map<String, dynamic>;
        // Acessa a role usando o ID do negócio estático do ApiService
        if (rolesMap.containsKey(ApiService.negocioId)) {
          return rolesMap[ApiService.negocioId];
        }
      }
      // Se não encontrar de nenhuma forma, retorna 'cliente'
      return 'cliente';
    }

    return Usuario(
      id: json['id'] ?? '',
      firebaseUid: json['firebase_uid'] ?? '',
      nome: json['nome'] ?? 'Nome não informado',
      email: json['email'] ?? 'email@naoinformado.com',
      telefone: json['telefone'],
      fotoPerfil: json['foto_perfil'],
      role: _extractRole(json), // Usa a nova função para extrair a role
      ativo: json['ativo'] ?? false,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'foto_perfil': fotoPerfil,
      'role': role,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
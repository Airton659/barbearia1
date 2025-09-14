import '../utils/app_constants.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String firebaseUid;
  final Map<String, String> roles;
  final String? telefone;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.firebaseUid,
    required this.roles,
    this.telefone,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    print('🔥 Usuario.fromJson recebido: $json');

    Map<String, String> roles = {};

    if (json['roles'] != null && json['roles'] is Map) {
      final rolesData = json['roles'] as Map<String, dynamic>;
      roles = rolesData.map((key, value) => MapEntry(key, value.toString()));
    } else if (json['role'] != null) {
      // Formato antigo da API - usar o role como padrão para o negócio atual
      roles = {AppConstants.negocioId: json['role'].toString()};
    }

    final telefone = json['telefone'];
    print('🔥 Telefone extraído do JSON: $telefone');

    String? profileImage = json['profile_image_url'] ?? json['profile_image'];
    print('🔥 Profile image extraída do JSON: $profileImage');

    // Verificar se há fotos no campo 'fotos' caso profile_image esteja vazio
    if ((profileImage == null || profileImage.isEmpty) &&
        json['fotos'] != null && json['fotos'] is Map) {
      final fotos = json['fotos'] as Map<String, dynamic>;
      print('🔥 Campo fotos encontrado: $fotos');

      // Procurar por qualquer URL de foto nos campos do map fotos
      fotos.forEach((key, value) {
        print('🔥 Foto $key: $value');
        if (value != null && value.toString().isNotEmpty && (profileImage == null || profileImage!.isEmpty)) {
          // Usar a primeira foto encontrada
          profileImage = value.toString();
          print('🔥 Usando foto do campo $key como profile image: $profileImage');
        }
      });
    }

    // Tentar outros campos comuns para foto se ainda não encontrou
    if (profileImage == null || profileImage!.isEmpty) {
      final alternativeFields = ['avatar', 'picture', 'photo', 'image', 'profile_picture'];
      for (final field in alternativeFields) {
        final value = json[field];
        if (value != null && value.toString().isNotEmpty) {
          profileImage = value.toString();
          print('🔥 Usando foto do campo alternativo $field: $profileImage');
          break;
        }
      }
    }

    // Se não encontrou nenhuma foto, gerar um avatar baseado no nome
    if (profileImage == null || profileImage!.isEmpty) {
      final nomeEncoded = Uri.encodeComponent(json['nome'] ?? 'User');
      profileImage = 'https://api.dicebear.com/7.x/initials/png?seed=$nomeEncoded&backgroundColor=8B4513,D2B48C,CD853F&fontSize=50';
      print('🔥 Usando avatar gerado para ${json['nome']}: $profileImage');
    }

    print('🔥 Profile image final: $profileImage');

    final usuario = Usuario(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      firebaseUid: json['firebase_uid'] ?? '',
      roles: roles,
      telefone: telefone,
      profileImage: profileImage,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );

    print('🔥 Usuario criado: ${usuario.toJson()}');
    return usuario;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'firebase_uid': firebaseUid,
      'roles': roles,
      'telefone': telefone,
      'profile_image': profileImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSyncProfileJson() {
    return {
      'nome': nome,
      'email': email,
      'firebase_uid': firebaseUid,
      'negocio_id': AppConstants.negocioId,
    };
  }

  // Métodos para verificar roles baseado no negócio atual
  String get roleForCurrentBusiness => roles[AppConstants.negocioId] ?? 'cliente';
  bool get isCliente => roleForCurrentBusiness == 'cliente';
  bool get isProfissional => roleForCurrentBusiness == 'profissional';
  bool get isAdmin => roleForCurrentBusiness == 'admin';
}
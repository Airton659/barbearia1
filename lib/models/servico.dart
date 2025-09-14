class Servico {
  final String id;
  final String nome;
  final String? descricao;
  final int duracao; // em minutos
  final double preco;
  final String profissionalId;
  final String negocioId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Servico({
    required this.id,
    required this.nome,
    this.descricao,
    required this.duracao,
    required this.preco,
    required this.profissionalId,
    required this.negocioId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      duracao: json['duracao'] ?? json['duracao_minutos'] ?? 0, // Tentar ambos os nomes
      preco: (json['preco'] as num?)?.toDouble() ?? 0.0,
      profissionalId: json['profissional_id'] ?? '',
      negocioId: json['negocio_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      'preco': preco,
      'profissional_id': profissionalId,
      'negocio_id': negocioId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'duracao_minutos': duracao, // API espera 'duracao_minutos'
      'preco': preco,
      // Estes campos serão preenchidos automaticamente pela API ou adicionados no service
      // 'negocio_id': negocioId,
      // 'profissional_id': profissionalId,
    };
  }
}
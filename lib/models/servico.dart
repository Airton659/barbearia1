class Servico {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final int duracaoMinutos;
  final String? imagemUrl;
  final bool ativo;
  final String profissionalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Servico({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.duracaoMinutos,
    this.imagemUrl,
    required this.ativo,
    required this.profissionalId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      preco: json['preco'].toDouble(),
      duracaoMinutos: json['duracao_minutos'],
      imagemUrl: json['imagem_url'],
      ativo: json['ativo'],
      profissionalId: json['profissional_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'duracao_minutos': duracaoMinutos,
      'imagem_url': imagemUrl,
      'ativo': ativo,
      'profissional_id': profissionalId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get precoFormatado => 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  String get duracaoFormatada => '${duracaoMinutos}min';
}
class Notificacao {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensagem;
  final String tipo; // 'agendamento', 'cancelamento', 'lembrete', etc.
  final bool lida;
  final Map<String, dynamic>? dadosAdicionais;
  final String negocioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Notificacao({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.lida,
    this.dadosAdicionais,
    required this.negocioId,
    this.createdAt,
    this.updatedAt,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      usuarioId: json['usuario_id'] ?? json['id'], // fallback para o id
      titulo: json['titulo'] ?? json['title'] ?? 'Notificação', // ✅ mapear title para titulo
      mensagem: json['mensagem'] ?? json['body'] ?? '', // ✅ mapear body para mensagem
      tipo: json['tipo'] ?? 'notificacao',
      lida: json['lida'] ?? false,
      dadosAdicionais: json['dados_adicionais'] ?? json['relacionado'], // pode vir como relacionado
      negocioId: json['negocio_id'] ?? '', // pode vir vazio
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) :
                 (json['data_criacao'] != null ? DateTime.parse(json['data_criacao']) : null), // ✅ mapear data_criacao
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
      'lida': lida,
      'dados_adicionais': dadosAdicionais,
      'negocio_id': negocioId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get tempoRelativo {
    if (createdAt == null) return 'Sem data';

    final agora = DateTime.now();
    final diferenca = agora.difference(createdAt!);

    if (diferenca.inMinutes < 1) {
      return 'Agora';
    } else if (diferenca.inMinutes < 60) {
      return '${diferenca.inMinutes}m atrás';
    } else if (diferenca.inHours < 24) {
      return '${diferenca.inHours}h atrás';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays}d atrás';
    } else {
      return '${diferenca.inDays ~/ 7}sem atrás';
    }
  }
}
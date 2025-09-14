class Bloqueio {
  final String id;
  final String profissionalId;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final String? motivo;
  final String negocioId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bloqueio({
    required this.id,
    required this.profissionalId,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    this.motivo,
    required this.negocioId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bloqueio.fromJson(Map<String, dynamic> json) {
    return Bloqueio(
      id: json['id'],
      profissionalId: json['profissional_id'],
      dataHoraInicio: DateTime.parse(json['data_hora_inicio']),
      dataHoraFim: DateTime.parse(json['data_hora_fim']),
      motivo: json['motivo'],
      negocioId: json['negocio_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profissional_id': profissionalId,
      'data_hora_inicio': dataHoraInicio.toIso8601String(),
      'data_hora_fim': dataHoraFim.toIso8601String(),
      'motivo': motivo,
      'negocio_id': negocioId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'data_hora_inicio': dataHoraInicio.toIso8601String(),
      'data_hora_fim': dataHoraFim.toIso8601String(),
      'motivo': motivo,
    };
  }

  Duration get duracao => dataHoraFim.difference(dataHoraInicio);
  bool get isAtivo => DateTime.now().isBefore(dataHoraFim) && DateTime.now().isAfter(dataHoraInicio);
}
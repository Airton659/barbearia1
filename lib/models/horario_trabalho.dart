class HorarioTrabalho {
  final String id;
  final String profissionalId;
  final int diaSemana; // 1 = segunda, 7 = domingo
  final String? horaInicio;
  final String? horaFim;
  final bool trabalhaNesteDia;
  final String negocioId;
  final DateTime createdAt;
  final DateTime updatedAt;

  HorarioTrabalho({
    required this.id,
    required this.profissionalId,
    required this.diaSemana,
    this.horaInicio,
    this.horaFim,
    required this.trabalhaNesteDia,
    required this.negocioId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HorarioTrabalho.fromJson(Map<String, dynamic> json) {
    // Lógica de prioridade para trabalha_neste_dia:
    // 1. Se existe explicitamente na resposta, usar esse valor
    // 2. Se não existe mas há horários válidos (não nulos e não vazios), considerar true
    // 3. Caso contrário, false
    bool trabalhaNesteDia = false;

    if (json.containsKey('trabalha_neste_dia')) {
      trabalhaNesteDia = json['trabalha_neste_dia'] == true;
    } else {
      final horaInicio = json['hora_inicio'];
      final horaFim = json['hora_fim'];
      trabalhaNesteDia = horaInicio != null &&
          horaFim != null &&
          horaInicio.toString().isNotEmpty &&
          horaFim.toString().isNotEmpty;
    }

    return HorarioTrabalho(
      id: json['id'] ?? '',
      profissionalId: json['profissional_id'] ?? '',
      diaSemana: json['dia_semana'] ?? 0,
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      trabalhaNesteDia: trabalhaNesteDia,
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
      'profissional_id': profissionalId,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'trabalha_neste_dia': trabalhaNesteDia,
      'negocio_id': negocioId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    // Só deve ser chamado para dias onde trabalha_neste_dia = true
    return {
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'trabalha_neste_dia': true,
    };
  }

  String get nomeDia {
    switch (diaSemana) {
      case 1: return 'Segunda-feira';
      case 2: return 'Terça-feira';
      case 3: return 'Quarta-feira';
      case 4: return 'Quinta-feira';
      case 5: return 'Sexta-feira';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Dia inválido';
    }
  }
}
class HorarioTrabalho {
  final String profissionalId;
  final int diaSemana; // 0 = domingo, 1 = segunda, etc.
  final String? horaInicio;
  final String? horaFim;
  final bool disponivel;
  final String? intervaloInicio;
  final String? intervaloFim;

  HorarioTrabalho({
    required this.profissionalId,
    required this.diaSemana,
    this.horaInicio,
    this.horaFim,
    required this.disponivel,
    this.intervaloInicio,
    this.intervaloFim,
  });

  factory HorarioTrabalho.fromJson(Map<String, dynamic> json) {
    return HorarioTrabalho(
      profissionalId: json['profissional_id'],
      diaSemana: json['dia_semana'],
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      disponivel: json['disponivel'],
      intervaloInicio: json['intervalo_inicio'],
      intervaloFim: json['intervalo_fim'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profissional_id': profissionalId,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'disponivel': disponivel,
      'intervalo_inicio': intervaloInicio,
      'intervalo_fim': intervaloFim,
    };
  }

  String get nomeDiaSemana {
    const dias = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    return dias[diaSemana];
  }

  String get horarioFormatado {
    if (!disponivel) return 'Fechado';
    if (horaInicio == null || horaFim == null) return 'Não definido';
    
    String resultado = '$horaInicio - $horaFim';
    if (intervaloInicio != null && intervaloFim != null) {
      resultado += ' (Intervalo: $intervaloInicio - $intervaloFim)';
    }
    return resultado;
  }
}
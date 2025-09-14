class HorarioDisponivel {
  final DateTime dataHora;
  final bool disponivel;

  HorarioDisponivel({
    required this.dataHora,
    required this.disponivel,
  });

  factory HorarioDisponivel.fromJson(Map<String, dynamic> json) {
    return HorarioDisponivel(
      dataHora: DateTime.parse(json['data_hora']),
      disponivel: json['disponivel'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data_hora': dataHora.toIso8601String(),
      'disponivel': disponivel,
    };
  }

  String get horaFormatada {
    return '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
  }
}
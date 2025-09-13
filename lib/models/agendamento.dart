class Agendamento {
  final String id;
  final String clienteId;
  final String profissionalId;
  final String servicoId;
  final DateTime dataHora;
  final String status;
  final double? preco;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Dados desnormalizados
  final String? clienteNome;
  final String? profissionalNome;
  final String? servicoNome;
  final int? servicoDuracao;

  Agendamento({
    required this.id,
    required this.clienteId,
    required this.profissionalId,
    required this.servicoId,
    required this.dataHora,
    required this.status,
    this.preco,
    this.observacoes,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNome,
    this.profissionalNome,
    this.servicoNome,
    this.servicoDuracao,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'],
      clienteId: json['cliente_id'],
      profissionalId: json['profissional_id'],
      servicoId: json['servico_id'],
      dataHora: DateTime.parse(json['data_hora']),
      status: json['status'],
      preco: json['preco']?.toDouble(),
      observacoes: json['observacoes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      clienteNome: json['cliente_nome'],
      profissionalNome: json['profissional_nome'],
      servicoNome: json['servico_nome'],
      servicoDuracao: json['servico_duracao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'profissional_id': profissionalId,
      'servico_id': servicoId,
      'data_hora': dataHora.toIso8601String(),
      'status': status,
      'preco': preco,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cliente_nome': clienteNome,
      'profissional_nome': profissionalNome,
      'servico_nome': servicoNome,
      'servico_duracao': servicoDuracao,
    };
  }

  String get precoFormatado => preco != null 
      ? 'R\$ ${preco!.toStringAsFixed(2).replaceAll('.', ',')}'
      : 'A definir';
      
  bool get podeSerCancelado => status == 'agendado' && dataHora.isAfter(DateTime.now());
}
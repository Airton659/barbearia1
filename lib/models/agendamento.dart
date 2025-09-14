import 'usuario.dart';
import 'servico.dart';

class Agendamento {
  final String id;
  final String clienteId;
  final String profissionalId;
  final String servicoId;
  final DateTime dataHora;
  final String status; // 'agendado', 'confirmado', 'cancelado', 'realizado'
  final String? motivoCancelamento;
  final String negocioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Dados relacionados (podem ser nulos dependendo da consulta)
  final Usuario? cliente;
  final Usuario? profissional;
  final Servico? servico;

  Agendamento({
    required this.id,
    required this.clienteId,
    required this.profissionalId,
    required this.servicoId,
    required this.dataHora,
    required this.status,
    this.motivoCancelamento,
    required this.negocioId,
    this.createdAt,
    this.updatedAt,
    this.cliente,
    this.profissional,
    this.servico,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    // Detectar se o formato é do backend expandido (com nomes diretos)
    if (json.containsKey('cliente_nome') || json.containsKey('profissional_nome') || json.containsKey('servico_nome')) {
      return Agendamento(
        id: json['id'],
        clienteId: json['cliente_id'],
        profissionalId: json['profissional_id'],
        servicoId: json['servico_id'],
        dataHora: DateTime.parse(json['data_hora']),
        status: json['status'],
        motivoCancelamento: json['motivo_cancelamento'],
        negocioId: json['negocio_id'],
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        // Criar objetos simples baseados nos nomes diretos
        cliente: json['cliente_nome'] != null ? Usuario(
          id: json['cliente_id'] ?? '',
          nome: json['cliente_nome'] == '[Erro na descriptografia]'
              ? 'Cliente'
              : (json['cliente_nome'] ?? 'Cliente'),
          email: '',
          firebaseUid: '',
          roles: {},
        ) : null,
        profissional: json['profissional_nome'] != null ? Usuario(
          id: json['profissional_id'] ?? '',
          nome: json['profissional_nome'] ?? '',
          email: '',
          firebaseUid: '',
          roles: {},
          profileImage: json['profissional_foto_thumbnail'],
        ) : null,
        servico: json['servico_nome'] != null ? Servico(
          id: json['servico_id'] ?? '',
          nome: json['servico_nome'] ?? '',
          preco: (json['servico_preco'] ?? 0).toDouble(),
          duracao: json['servico_duracao_minutos'] ?? 0,
          profissionalId: '',
          negocioId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ) : null,
      );
    }

    // Formato original (com objetos completos)
    return Agendamento(
      id: json['id'],
      clienteId: json['cliente_id'],
      profissionalId: json['profissional_id'],
      servicoId: json['servico_id'],
      dataHora: DateTime.parse(json['data_hora']),
      status: json['status'],
      motivoCancelamento: json['motivo_cancelamento'],
      negocioId: json['negocio_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      cliente: json['cliente'] != null ? Usuario.fromJson(json['cliente']) : null,
      profissional: json['profissional'] != null ? Usuario.fromJson(json['profissional']) : null,
      servico: json['servico'] != null ? Servico.fromJson(json['servico']) : null,
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
      'motivo_cancelamento': motivoCancelamento,
      'negocio_id': negocioId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'negocio_id': negocioId,
      'profissional_id': profissionalId,
      'servico_id': servicoId,
      'data_hora': dataHora.toIso8601String(),
    };
  }

  bool get isProximo => dataHora.isAfter(DateTime.now());
  bool get isAgendado => status == 'agendado' || status == 'pendente';
  bool get isCancelado => status == 'cancelado' || status == 'cancelado_pelo_cliente' || status == 'cancelado_pelo_profissional';
  bool get isRealizado => status == 'realizado';

  // Status display helpers
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'agendado':
        return 'Agendado';
      case 'pendente':
        return 'Pendente';
      case 'confirmado':
        return 'Confirmado';
      case 'cancelado':
      case 'cancelado_pelo_cliente':
      case 'cancelado_pelo_profissional':
        return 'Cancelado';
      case 'realizado':
        return 'Realizado';
      default:
        return status; // Retorna o status original se não reconhecido
    }
  }

}
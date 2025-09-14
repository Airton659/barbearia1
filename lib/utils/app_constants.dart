class AppConstants {
  static const String baseUrl = 'https://barbearia-backend-service-862082955632.southamerica-east1.run.app';
  static const String negocioId = 'YXcwY5rHdXBNRm4BtsP1';
  static const String negocioIdHeader = 'negocio-id';

  // Endpoints
  static const String syncProfile = '/users/sync-profile';
  static const String updateProfile = '/me/profile'; // ✅ Endpoint correto para atualizar perfil
  static const String profissionais = '/profissionais';
  static const String agendamentos = '/agendamentos';
  static const String agendamentosMe = '/agendamentos/me';
  static const String notificacoes = '/notificacoes';
  static const String notificacoesNaoLidas = '/notificacoes/nao-lidas/contagem';
  static const String marcarComoLida = '/notificacoes/marcar-como-lida';
  static const String lerTodas = '/notificacoes/ler-todas';
  static const String registerFcmToken = '/me/register-fcm-token';
  static const String meAgendamentos = '/me/agendamentos';
  static const String meHorariosTrabalho = '/me/horarios-trabalho';
  static const String meBloqueios = '/me/bloqueios';
  static const String meServicos = '/me/servicos';

  // Status de agendamento
  static const String statusAgendado = 'agendado';
  static const String statusConfirmado = 'confirmado';
  static const String statusCancelado = 'cancelado';
  static const String statusRealizado = 'realizado';

  // Roles de usuário
  static const String roleCliente = 'cliente';
  static const String roleProfissional = 'profissional';
  static const String roleAdmin = 'admin';
}
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_constants.dart';
import '../models/usuario.dart';
import '../models/agendamento.dart';
import '../models/servico.dart';
import '../models/horario_trabalho.dart';
import '../models/bloqueio.dart';
import '../models/notificacao.dart';
import '../models/horario_disponivel.dart';

class ApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    final token = user != null ? await user.getIdToken() : '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      AppConstants.negocioIdHeader: AppConstants.negocioId,
    };
  }

  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final uriWithQuery = queryParams != null
        ? uri.replace(queryParameters: queryParams)
        : uri;

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uriWithQuery, headers: headers);
      case 'POST':
        return await http.post(
          uriWithQuery,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uriWithQuery,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PATCH':
        return await http.patch(
          uriWithQuery,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uriWithQuery, headers: headers);
      default:
        throw ArgumentError('Método HTTP não suportado: $method');
    }
  }

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      try {
        return fromJson(data);
      } catch (e) {
        rethrow;
      }
    } else {
      throw HttpException(
        'Erro na requisição: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<T>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      try {
        return data.map((item) => fromJson(item)).toList();
      } catch (e) {
        rethrow;
      }
    } else {
      throw HttpException(
        'Erro na requisição: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Autenticação e perfil
  Future<Usuario> syncProfile(Usuario usuario) async {
    final response = await _makeRequest(
      'POST',
      AppConstants.syncProfile,
      body: usuario.toSyncProfileJson(),
    );
    return _handleResponse(response, Usuario.fromJson);
  }

  // ✅ Método para obter perfil atualizado
  Future<Usuario> getMyProfile() async {
    print('🔥 getMyProfile chamado - buscando perfil atualizado');

    final response = await _makeRequest(
      'GET',
      AppConstants.updateProfile, // /me/profile
    );

    print('🔥 getMyProfile resposta: ${response.statusCode}');
    print('🔥 getMyProfile body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      print('🔥 getMyProfile parsing: $data');

      // Pode vir direto o usuário ou dentro de { "user": {...} }
      if (data['user'] != null) {
        return Usuario.fromJson(data['user']);
      } else {
        return Usuario.fromJson(data);
      }
    } else {
      throw HttpException(
        'Erro ao buscar perfil: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Profissionais
  Future<List<Usuario>> getProfissionais() async {
    print('🔥 API: Buscando profissionais...');
    print('🔥 API: URL: ${AppConstants.profissionais}');
    print('🔥 API: negocio_id: ${AppConstants.negocioId}');

    final response = await _makeRequest(
      'GET',
      AppConstants.profissionais,
      queryParams: {'negocio_id': AppConstants.negocioId},
    );

    print('🔥 API: Response status: ${response.statusCode}');
    print('🔥 API: Response body: ${response.body}');

    return _handleListResponse(response, Usuario.fromJson);
  }

  Future<Usuario> getProfissional(String id) async {
    final response = await _makeRequest(
      'GET',
      '${AppConstants.profissionais}/$id',
      queryParams: {'negocio_id': AppConstants.negocioId},
    );
    return _handleResponse(response, Usuario.fromJson);
  }

  Future<List<Servico>> getServicosProfissional(String profissionalId) async {
    print('🔥 Buscando serviços do profissional: $profissionalId');

    final response = await _makeRequest(
      'GET',
      '${AppConstants.profissionais}/$profissionalId',
      queryParams: {'negocio_id': AppConstants.negocioId},
    );

    print('🔥 Status da resposta serviços: ${response.statusCode}');
    print('🔥 Body da resposta serviços: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      print('🔥 Data parsed serviços: $data');

      // Os serviços vêm dentro do campo 'servicos'
      if (data['servicos'] != null && data['servicos'] is List) {
        final List<dynamic> servicosData = data['servicos'];
        print('🔥 Serviços encontrados: ${servicosData.length}');
        print('🔥 Dados dos serviços: $servicosData');

        final servicos = servicosData.map((item) => Servico.fromJson(item)).toList();
        print('🔥 Serviços convertidos: ${servicos.length}');
        return servicos;
      } else {
        print('🔥 Campo servicos não encontrado ou não é lista');
      }

      return [];
    } else {
      print('🔥 Erro na requisição de serviços: ${response.statusCode}');
      throw HttpException(
        'Erro na requisição: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Servico>> getAllServicosUnicos() async {
    try {
      // Buscar todos os profissionais
      final profissionais = await getProfissionais();

      Set<String> servicosAdicionados = {};
      List<Servico> servicosUnicos = [];

      // Para cada profissional, buscar seus serviços
      for (final profissional in profissionais) {
        try {
          final servicos = await getServicosProfissional(profissional.id);

          for (final servico in servicos) {
            // Usar nome como chave única (pode ajustar conforme necessário)
            if (!servicosAdicionados.contains(servico.nome)) {
              servicosAdicionados.add(servico.nome);
              servicosUnicos.add(servico);
            }
          }
        } catch (e) {
          // Ignorar erros individuais de profissionais
          print('Erro ao carregar serviços do profissional ${profissional.id}: $e');
        }
      }

      return servicosUnicos;
    } catch (e) {
      throw HttpException('Erro ao carregar serviços únicos: $e');
    }
  }

  Future<List<HorarioDisponivel>> getHorariosDisponiveis(
    String profissionalId,
    String dia,
    int duracaoServico,
  ) async {
    print('🔥 API: getHorariosDisponiveis chamada');
    print('🔥 API: profissionalId: $profissionalId');
    print('🔥 API: dia: $dia');
    print('🔥 API: duracaoServico: $duracaoServico');
    print('🔥 API: negocio_id: ${AppConstants.negocioId}');
    print('🔥 API: URL: ${AppConstants.profissionais}/$profissionalId/horarios-disponiveis');

    final response = await _makeRequest(
      'GET',
      '${AppConstants.profissionais}/$profissionalId/horarios-disponiveis',
      queryParams: {
        'dia': dia,
        'duracao_servico': duracaoServico.toString(),
        'negocio_id': AppConstants.negocioId,
      },
    );

    print('🔥 API: Response status: ${response.statusCode}');
    print('🔥 API: Response body: ${response.body}');

    // Verificar se a resposta é um array de strings simples (formato atual do backend)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic data = jsonDecode(response.body);
      print('🔥 API: Data decoded: $data');

      if (data is List) {
        // Se é uma lista de strings (formato atual)
        if (data.isNotEmpty && data.first is String) {
          print('🔥 API: Detectado formato de strings simples, convertendo...');

          // Converter strings para objetos HorarioDisponivel
          final List<HorarioDisponivel> horarios = [];
          for (final String horarioStr in data) {
            try {
              // Parse da string de horário (ex: "10:00:00")
              final parts = horarioStr.split(':');
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);

              // Criar DateTime combinando a data selecionada com o horário
              final dataHoraParsed = dia.split('-'); // "2025-09-16"
              final dataHora = DateTime(
                int.parse(dataHoraParsed[0]), // ano
                int.parse(dataHoraParsed[1]), // mês
                int.parse(dataHoraParsed[2]), // dia
                hour,
                minute,
              );

              horarios.add(HorarioDisponivel(
                dataHora: dataHora,
                disponivel: true, // Assumir que todos são disponíveis
              ));

              print('🔥 API: Horário convertido: ${horarios.last.horaFormatada}');
            } catch (e) {
              print('🔥 API: Erro ao converter horário $horarioStr: $e');
            }
          }

          print('🔥 API: Total de horários convertidos: ${horarios.length}');
          return horarios;
        }
        // Se é uma lista de objetos (formato esperado)
        else {
          print('🔥 API: Detectado formato de objetos, usando parser normal...');
          return data.map((item) => HorarioDisponivel.fromJson(item)).toList();
        }
      }

      return [];
    } else {
      throw HttpException(
        'Erro na requisição: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Agendamentos
  Future<Agendamento> createAgendamento(Agendamento agendamento) async {
    print('🔥 API: createAgendamento chamada');
    print('🔥 API: URL: ${AppConstants.agendamentos}');

    final bodyData = agendamento.toCreateJson();
    print('🔥 API: Body data: $bodyData');

    final response = await _makeRequest(
      'POST',
      AppConstants.agendamentos,
      body: bodyData,
    );

    print('🔥 API: Response status: ${response.statusCode}');
    print('🔥 API: Response body: ${response.body}');

    return _handleResponse(response, Agendamento.fromJson);
  }

  Future<List<Agendamento>> getMyAgendamentos() async {
    print('🔥 API: getMyAgendamentos chamada');
    final response = await _makeRequest('GET', AppConstants.agendamentosMe);
    print('🔥 API: getMyAgendamentos response status: ${response.statusCode}');
    print('🔥 API: getMyAgendamentos response body: ${response.body}');
    return _handleListResponse(response, Agendamento.fromJson);
  }

  Future<void> cancelAgendamento(String agendamentoId) async {
    print('🔥 API: cancelAgendamento chamada para ID: $agendamentoId');
    final response = await _makeRequest('DELETE', '${AppConstants.agendamentos}/$agendamentoId');
    print('🔥 API: cancelAgendamento resposta: ${response.statusCode}');
  }

  Future<void> cancelAgendamentoProfissional(String agendamentoId, String motivo) async {
    print('🔥 API: cancelAgendamentoProfissional chamada para ID: $agendamentoId com motivo: $motivo');
    final response = await _makeRequest(
      'DELETE',
      '${AppConstants.agendamentos}/$agendamentoId/profissional',
      body: {'motivo_cancelamento': motivo},
    );
    print('🔥 API: cancelAgendamentoProfissional resposta: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Falha ao cancelar agendamento: ${response.body}');
    }
  }

  Future<void> updateAgendamentoStatus(String agendamentoId, String status) async {
    print('🔥 API: updateAgendamentoStatus chamada para ID: $agendamentoId, status: $status');

    // ENDPOINT CORRETO FORNECIDO PELO BACKEND:
    // PATCH /me/agendamentos/{agendamento_id}/confirmar
    String endpoint = '/me/agendamentos/$agendamentoId/confirmar';

    final response = await _makeRequest(
      'PATCH', // Método correto fornecido pelo backend
      endpoint,
      // SEM BODY - backend confirmou que não precisa
    );
    print('🔥 API: updateAgendamentoStatus resposta: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Falha ao confirmar agendamento: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<Agendamento>> getAgendamentosProfissional() async {
    print('🔥 API: getAgendamentosProfissional chamada');
    final response = await _makeRequest('GET', '${AppConstants.agendamentos}/profissional');
    print('🔥 API: getAgendamentosProfissional resposta: ${response.statusCode}');
    return _handleListResponse(response, Agendamento.fromJson);
  }

  // Métodos de Notificações - Baseado na documentação do backend
  Future<List<Notificacao>> getNotificacoes() async {
    print('🔥 API: getNotificacoes chamada');
    final response = await _makeRequest('GET', AppConstants.notificacoes);
    print('🔥 API: getNotificacoes resposta: ${response.statusCode}');

    if (response.statusCode == 200) {
      // DEBUG: Verificar dados brutos das notificações
      final String body = response.body;
      print('🔥 API: getNotificacoes body raw: $body');

      try {
        final List<dynamic> data = jsonDecode(body);
        print('🔥 API: getNotificacoes parsed data: $data');

        for (int i = 0; i < data.length && i < 2; i++) {
          final item = data[i];
          print('🔥 API: Notificacao $i: $item');
          print('🔥 API: Notificacao $i - id: ${item['id']}');
          print('🔥 API: Notificacao $i - titulo: ${item['titulo']}');
          print('🔥 API: Notificacao $i - mensagem: ${item['mensagem']}');
          print('🔥 API: Notificacao $i - tipo: ${item['tipo']}');
          print('🔥 API: Notificacao $i - created_at: ${item['created_at']}');
        }

        return _handleListResponse(response, Notificacao.fromJson);
      } catch (e) {
        print('🔥 API: ERRO ao fazer parse das notificações: $e');
        throw e;
      }
    } else {
      throw Exception('Falha ao buscar notificações: ${response.body}');
    }
  }

  Future<void> markNotificationAsRead(String notificacaoId) async {
    print('🔥 API: markNotificationAsRead chamada para ID: $notificacaoId');
    final response = await _makeRequest(
      'POST',
      AppConstants.marcarComoLida,
      body: {'notificacao_id': notificacaoId},
    );
    print('🔥 API: markNotificationAsRead resposta: ${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao marcar notificação como lida: ${response.body}');
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    print('🔥 API: getUnreadNotificationsCount chamada');
    final response = await _makeRequest('GET', AppConstants.notificacoesNaoLidas);
    print('🔥 API: getUnreadNotificationsCount resposta: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Falha ao buscar contagem de notificações: ${response.body}');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    print('🔥 API: markAllNotificationsAsRead chamada');
    final response = await _makeRequest('POST', AppConstants.lerTodas);
    print('🔥 API: markAllNotificationsAsRead resposta: ${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao marcar todas notificações como lidas: ${response.body}');
    }
  }

  Future<void> registerFcmToken(String token) async {
    print('🔥 API: registerFcmToken chamada');
    final response = await _makeRequest(
      'POST',
      AppConstants.registerFcmToken,
      body: {'token': token},
    );
    print('🔥 API: registerFcmToken resposta: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Falha ao registrar token FCM: ${response.body}');
    }
  }

  // Serviços do profissional
  Future<List<Servico>> getMyServicos() async {
    final response = await _makeRequest('GET', AppConstants.meServicos);
    return _handleListResponse(response, Servico.fromJson);
  }

  Future<Servico> createServico(Servico servico, String profissionalId) async {
    final servicoData = servico.toCreateJson();
    // Adicionar negocio_id e profissional_id que são obrigatórios
    servicoData['negocio_id'] = AppConstants.negocioId;
    servicoData['profissional_id'] = profissionalId;


    final response = await _makeRequest(
      'POST',
      AppConstants.meServicos,
      body: servicoData,
    );


    return _handleResponse(response, Servico.fromJson);
  }

  Future<Servico> updateServico(String servicoId, Servico servico) async {
    final response = await _makeRequest(
      'PUT',
      '${AppConstants.meServicos}/$servicoId',
      body: servico.toCreateJson(),
    );
    return _handleResponse(response, Servico.fromJson);
  }

  Future<void> deleteServico(String servicoId) async {
    final response = await _makeRequest('DELETE', '${AppConstants.meServicos}/$servicoId');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Erro ao deletar serviço: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Horários de trabalho do profissional
  Future<List<HorarioTrabalho>> getMyHorariosTrabalho() async {
    final response = await _makeRequest('GET', AppConstants.meHorariosTrabalho);
    return _handleListResponse(response, HorarioTrabalho.fromJson);
  }

  Future<List<HorarioTrabalho>> updateHorariosTrabalho(
    List<HorarioTrabalho> horarios,
  ) async {
    final horariosJson = horarios.map((h) => h.toCreateJson()).toList();


    final response = await _makeRequest(
      'POST',
      AppConstants.meHorariosTrabalho,
      body: horariosJson, // Enviar diretamente a lista, não um objeto
    );
    return _handleListResponse(response, HorarioTrabalho.fromJson);
  }

  // Bloqueios do profissional
  Future<List<Bloqueio>> getMyBloqueios() async {
    final response = await _makeRequest('GET', AppConstants.meBloqueios);
    return _handleListResponse(response, Bloqueio.fromJson);
  }

  Future<Bloqueio> createBloqueio(Bloqueio bloqueio) async {
    final response = await _makeRequest(
      'POST',
      AppConstants.meBloqueios,
      body: bloqueio.toCreateJson(),
    );
    return _handleResponse(response, Bloqueio.fromJson);
  }

  Future<void> deleteBloqueio(String bloqueioId) async {
    await _makeRequest('DELETE', '${AppConstants.meBloqueios}/$bloqueioId');
  }

  // Agendamentos do profissional
  Future<List<Agendamento>> getMyProfissionalAgendamentos() async {
    final response = await _makeRequest('GET', AppConstants.meAgendamentos);
    return _handleListResponse(response, Agendamento.fromJson);
  }

  Future<void> cancelProfissionalAgendamento(
    String agendamentoId,
    String motivo,
  ) async {
    await _makeRequest(
      'PATCH',
      '${AppConstants.meAgendamentos}/$agendamentoId/cancelar',
      body: {'motivo': motivo},
    );
  }

  // Notificações (métodos já implementados acima)

  Future<int> getNotificacoesNaoLidasCount() async {
    final response = await _makeRequest('GET', AppConstants.notificacoesNaoLidas);
    final data = jsonDecode(response.body);
    return data['count'] as int;
  }

  Future<void> marcarNotificacaoComoLida(String notificacaoId) async {
    await _makeRequest(
      'POST',
      AppConstants.marcarComoLida,
      body: {'notificacao_id': notificacaoId},
    );
  }

  // Profile update usando o endpoint correto
  Future<Usuario> updateUserProfile(
    Map<String, dynamic> updateData, {
    dynamic imageBytes,
  }) async {
    print('🔥 updateUserProfile chamado com dados: $updateData');

    if (imageBytes != null) {
      print('🔥 Imagem fornecida, convertendo para base64...');
      // Convert image bytes to base64 for API
      final base64Image = base64Encode(imageBytes);
      updateData['profile_image'] = 'data:image/jpeg;base64,$base64Image';
      print('🔥 Imagem base64 adicionada aos dados');
    }

    // ✅ REMOVIDO negocio_id - não é necessário para /me/profile
    // updateData['negocio_id'] = AppConstants.negocioId;

    print('🔥 Dados finais para enviar: $updateData');
    print('🔥 Endpoint: ${AppConstants.updateProfile}');
    print('🔥 Método: PUT');

    final response = await _makeRequest(
      'PUT', // ✅ Método correto: PUT
      AppConstants.updateProfile, // ✅ Endpoint correto: /me/profile
      body: updateData,
    );

    print('🔥 Status da resposta: ${response.statusCode}');
    print('🔥 Body da resposta: ${response.body}');

    // ✅ Parse da resposta seguindo o formato documentado
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      print('🔥 Parsing resposta do /me/profile: $data');

      // A resposta vem com estrutura: { "success": true, "user": {...} }
      if (data['user'] != null) {
        return Usuario.fromJson(data['user']);
      } else {
        // Fallback se vier direto o usuário
        return Usuario.fromJson(data);
      }
    } else {
      throw HttpException(
        'Erro na requisição: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Admin
  Future<List<Usuario>> getNegocioUsuarios() async {
    final response = await _makeRequest(
      'GET',
      '/negocios/${AppConstants.negocioId}/usuarios',
    );
    return _handleListResponse(response, Usuario.fromJson);
  }

  Future<Usuario> updateUsuarioRole(String userId, String role) async {
    final response = await _makeRequest(
      'PATCH',
      '/negocios/${AppConstants.negocioId}/usuarios/$userId/role',
      body: {'role': role},
    );
    return _handleResponse(response, Usuario.fromJson);
  }
}
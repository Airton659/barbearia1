import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../models/servico.dart';
import '../models/agendamento.dart';

// Estrutura de cache com TTL
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.ttl) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://barbearia-backend-service-862082955632.southamerica-east1.run.app';
  
  final AuthService authService;

  ApiService({required this.authService});

  // Cache interno com TTL
  final Map<String, CacheEntry> _cache = {};
  final Duration _defaultTtl = const Duration(minutes: 5);

  // Métodos de cache
  String _getCacheKey(String endpoint, [Map<String, dynamic>? params]) {
    final userId = authService.currentUser?.firebaseUid ?? 'anonymous';
    final negocioId = authService.negocioId;
    final paramString = params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '${userId}_${negocioId}_${endpoint}_$paramString';
  }

  T? _getFromCache<T>(String cacheKey) {
    final entry = _cache[cacheKey] as CacheEntry<T>?;
    if (entry != null && !entry.isExpired) {
      debugPrint('🔍 [CACHE] Hit: $cacheKey');
      return entry.data;
    }
    if (entry != null && entry.isExpired) {
      _cache.remove(cacheKey);
      debugPrint('🔍 [CACHE] Expired: $cacheKey');
    }
    return null;
  }

  void _setCache<T>(String cacheKey, T data, {Duration? ttl}) {
    _cache[cacheKey] = CacheEntry<T>(data, ttl ?? _defaultTtl);
    debugPrint('🔍 [CACHE] Set: $cacheKey');
  }

  void clearCache([String? pattern]) {
    if (pattern != null) {
      final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      debugPrint('🔍 [CACHE] Cleared pattern: $pattern');
    } else {
      _cache.clear();
      debugPrint('🔍 [CACHE] Cleared all');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await authService.getIdToken();
    if (token == null) throw Exception('Usuário não autenticado ou token inválido');

    final negocioId = authService.negocioId;

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
      'negocio-id': negocioId,
    };

    debugPrint('🔍 [HEADERS] negocio-id: $negocioId');
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint('🔍 [API] ${response.request?.method} ${response.request?.url} - ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      final errorMessage = 'Erro na API: ${response.statusCode} - ${response.body}';
      debugPrint('🔍 [API ERROR] $errorMessage');
      throw Exception(errorMessage);
    }
  }

  Future<dynamic> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> _patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // ==================== PERFIL E AUTENTICAÇÃO ====================

  Future<Usuario> syncProfile(Map<String, dynamic> data) async {
    debugPrint('🔍 [SYNC] Dados: ${data.keys.toList()}');
    final response = await _post('/users/sync-profile', data);
    return Usuario.fromJson(response as Map<String, dynamic>);
  }

  Future<Usuario> getProfile() async {
    final cacheKey = _getCacheKey('getProfile');

    final cached = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      return Usuario.fromJson(cached);
    }

    final data = await _get('/me/profile') as Map<String, dynamic>;
    _setCache(cacheKey, data, ttl: const Duration(minutes: 10));
    return Usuario.fromJson(data);
  }

  Future<bool> verificarNecessidadeCodigoConvite() async {
    try {
      final data = await _get('/negocios/$negocioId/admin-status') as Map<String, dynamic>;
      return !(data['tem_admin'] ?? true);
    } catch (e) {
      debugPrint('🔍 [CONVITE] Erro ao verificar: $e');
      return true;
    }
  }

  // ==================== USUÁRIOS ====================

  Future<List<Usuario>> getTodosUsuarios({bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey('getTodosUsuarios');
    
    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        return cached.map((json) => Usuario.fromJson(json)).toList();
      }
    }

    try {
      // Primeiro tenta endpoint para todos os usuários
      debugPrint('🔍 [USUARIOS] Tentando /negocios/$negocioId/usuarios');
      final data = await _get('/negocios/$negocioId/usuarios');
      
      List<Map<String, dynamic>> usuarios;
      if (data is List) {
        usuarios = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('usuarios')) {
        usuarios = (data['usuarios'] as List).cast<Map<String, dynamic>>();
      } else {
        usuarios = [];
      }

      _setCache(cacheKey, usuarios, ttl: const Duration(minutes: 5));
      debugPrint('🔍 [USUARIOS] Sucesso: ${usuarios.length} usuários em /negocios/$negocioId/usuarios');
      return usuarios.map((json) => Usuario.fromJson(json)).toList();

    } catch (e) {
      debugPrint('🔍 [USUARIOS] Fallback para /profissionais - Erro: $e');
      return await getProfissionais();
    }
  }

  Future<List<Usuario>> getProfissionais({bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey('getProfissionais');

    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        return cached.map((json) => Usuario.fromJson(json)).toList();
      }
    }

    debugPrint('🔍 [PROFISSIONAIS] Tentando /profissionais?negocio_id=$negocioId');
    final data = await _get('/profissionais', queryParams: {'negocio_id': negocioId});

    List<Map<String, dynamic>> profissionais;
    if (data is List) {
      profissionais = data.cast<Map<String, dynamic>>();
    } else if (data is Map && data.containsKey('profissionais')) {
      profissionais = (data['profissionais'] as List).cast<Map<String, dynamic>>();
    } else {
      profissionais = [];
    }

    _setCache(cacheKey, profissionais, ttl: const Duration(minutes: 5));
    debugPrint('🔍 [PROFISSIONAIS] Sucesso: ${profissionais.length} profissionais');
    return profissionais.map((json) => Usuario.fromJson(json)).toList();
  }

  Future<Usuario> adminCreateUser(Map<String, dynamic> userData) async {
    debugPrint('🔍 [CREATE_USER] Dados: ${userData.keys.toList()}');
    final data = await _post('/negocios/$negocioId/pacientes', userData);
    clearCache('getTodosUsuarios');
    clearCache('getProfissionais');
    return Usuario.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final negocioId = authService.negocioId;
    await _patch('/negocios/$negocioId/usuarios/$userId/role', {'role': newRole});
    clearCache('getTodosUsuarios');
  }

  // ==================== SERVIÇOS ====================

  Future<List<Servico>> getMeusServicos({bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey('getMeusServicos');

    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        return cached.map((json) => Servico.fromJson(json)).toList();
      }
    }

    try {
      // Primeiro tenta endpoint específico do profissional
      debugPrint('🔍 [SERVICOS] Tentando /me/servicos');
      final data = await _get('/me/servicos');
      
      List<Map<String, dynamic>> servicos;
      if (data is List) {
        servicos = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('servicos')) {
        servicos = (data['servicos'] as List).cast<Map<String, dynamic>>();
      } else {
        servicos = [];
      }

      _setCache(cacheKey, servicos, ttl: const Duration(minutes: 5));
      debugPrint('🔍 [SERVICOS] Sucesso: ${servicos.length} serviços em /me/servicos');
      return servicos.map((json) => Servico.fromJson(json)).toList();

    } catch (e) {
      debugPrint('🔍 [SERVICOS] Erro em /me/servicos: $e');

      try {
        // Fallback para endpoint administrativo
        debugPrint('🔍 [SERVICOS] Tentando /negocios/$negocioId/servicos');
        final data = await _get('/negocios/$negocioId/servicos');

        List<Map<String, dynamic>> servicos;
        if (data is List) {
          servicos = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data.containsKey('servicos')) {
          servicos = (data['servicos'] as List).cast<Map<String, dynamic>>();
        } else {
          servicos = [];
        }

        _setCache(cacheKey, servicos, ttl: const Duration(minutes: 5));
        debugPrint('🔍 [SERVICOS] Sucesso: ${servicos.length} serviços em /negocios/$negocioId/servicos');
        return servicos.map((json) => Servico.fromJson(json)).toList();

      } catch (e2) {
        debugPrint('🔍 [SERVICOS] Ambos endpoints falharam: /me/servicos e /negocios/$negocioId/servicos');
        return [];
      }
    }
  }

  Future<Servico> createServico(Map<String, dynamic> servicoData) async {
    debugPrint('🔍 [CREATE_SERVICO] Dados: $servicoData');
    final data = await _post('/me/servicos', servicoData);
    clearCache('getMeusServicos');
    return Servico.fromJson(data as Map<String, dynamic>);
  }

  Future<Servico> updateServico(String servicoId, Map<String, dynamic> servicoData) async {
    debugPrint('🔍 [UPDATE_SERVICO] ID: $servicoId, Dados: $servicoData');
    final data = await _put('/me/servicos/$servicoId', servicoData);
    clearCache('getMeusServicos');
    return Servico.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteServico(String servicoId) async {
    debugPrint('🔍 [DELETE_SERVICO] ID: $servicoId');
    await _delete('/me/servicos/$servicoId');
    clearCache('getMeusServicos');
  }

  // ==================== AGENDAMENTOS ====================

  Future<List<Agendamento>> getAgendamentosProfissional({bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey('getAgendamentosProfissional');

    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        return cached.map((json) => Agendamento.fromJson(json)).toList();
      }
    }

    try {
      // Primeiro tenta endpoint específico do profissional
      debugPrint('🔍 [AGENDAMENTOS] Tentando /me/agendamentos');
      final data = await _get('/me/agendamentos');
      
      List<Map<String, dynamic>> agendamentos;
      if (data is List) {
        agendamentos = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('agendamentos')) {
        agendamentos = (data['agendamentos'] as List).cast<Map<String, dynamic>>();
      } else {
        agendamentos = [];
      }

      _setCache(cacheKey, agendamentos, ttl: const Duration(minutes: 5));
      debugPrint('🔍 [AGENDAMENTOS] Sucesso: ${agendamentos.length} agendamentos em /me/agendamentos');
      return agendamentos.map((json) => Agendamento.fromJson(json)).toList();

    } catch (e) {
      debugPrint('🔍 [AGENDAMENTOS] Erro em /me/agendamentos: $e');

      try {
        // Fallback para endpoint administrativo
        debugPrint('🔍 [AGENDAMENTOS] Tentando /negocios/$negocioId/agendamentos');
        final data = await _get('/negocios/$negocioId/agendamentos');

        List<Map<String, dynamic>> agendamentos;
        if (data is List) {
          agendamentos = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data.containsKey('agendamentos')) {
          agendamentos = (data['agendamentos'] as List).cast<Map<String, dynamic>>();
        } else {
          agendamentos = [];
        }

        _setCache(cacheKey, agendamentos, ttl: const Duration(minutes: 5));
        debugPrint('🔍 [AGENDAMENTOS] Sucesso: ${agendamentos.length} agendamentos em /negocios/$negocioId/agendamentos');
        return agendamentos.map((json) => Agendamento.fromJson(json)).toList();

      } catch (e2) {
        debugPrint('🔍 [AGENDAMENTOS] Ambos endpoints falharam: /me/agendamentos e /negocios/$negocioId/agendamentos');
        return [];
      }
    }
  }

  Future<void> cancelarAgendamentoProfissional(String agendamentoId) async {
    debugPrint('🔍 [CANCEL_AGENDAMENTO] ID: $agendamentoId');
    await _delete('/agendamentos/$agendamentoId');
    clearCache('getAgendamentosProfissional');
  }

  // ==================== AGENDAMENTOS CLIENTE ====================

  Future<List<Agendamento>> getAgendamentosCliente({bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey('getAgendamentosCliente');

    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        return cached.map((json) => Agendamento.fromJson(json)).toList();
      }
    }

    debugPrint('🔍 [AGENDAMENTOS_CLIENTE] Tentando /agendamentos/me');
    final data = await _get('/agendamentos/me');

    List<Map<String, dynamic>> agendamentos;
    if (data is List) {
      agendamentos = data.cast<Map<String, dynamic>>();
    } else if (data is Map && data.containsKey('agendamentos')) {
      agendamentos = (data['agendamentos'] as List).cast<Map<String, dynamic>>();
    } else {
      agendamentos = [];
    }

    _setCache(cacheKey, agendamentos, ttl: const Duration(minutes: 5));
    debugPrint('🔍 [AGENDAMENTOS_CLIENTE] Sucesso: ${agendamentos.length} agendamentos');
    return agendamentos.map((json) => Agendamento.fromJson(json)).toList();
  }

  Future<Agendamento> criarAgendamento(Map<String, dynamic> agendamentoData) async {
    debugPrint('🔍 [CREATE_AGENDAMENTO] Dados: $agendamentoData');
    final data = await _post('/agendamentos', agendamentoData);
    clearCache('getAgendamentosCliente');
    clearCache('getAgendamentosProfissional');
    return Agendamento.fromJson(data as Map<String, dynamic>);
  }

  Future<void> cancelarAgendamento(String agendamentoId) async {
    debugPrint('🔍 [CANCEL_AGENDAMENTO_CLIENTE] ID: $agendamentoId');
    await _delete('/agendamentos/$agendamentoId');
    clearCache('getAgendamentosCliente');
    clearCache('getAgendamentosProfissional');
  }

  // ==================== HORÁRIOS DE TRABALHO ====================

import '../models/horario_trabalho.dart';

  Future<List<HorarioTrabalho>> getHorariosTrabalho() async {
    final data = await _get('/me/horarios-trabalho');
    return (data['horarios'] as List).map((json) => HorarioTrabalho.fromJson(json)).toList();
  }

  Future<List<HorarioTrabalho>> setHorariosTrabalho(List<Map<String, dynamic>> horarios) async {
    final data = await _post('/me/horarios-trabalho', {'horarios': horarios});
    return (data['horarios'] as List).map((json) => HorarioTrabalho.fromJson(json)).toList();
  }

  Future<List<DateTime>> getHorariosDisponiveis(String profissionalId, String servicoId, DateTime data) async {
    final dataFormatada = data.toIso8601String().split('T')[0];
    final cacheKey = _getCacheKey('getHorariosDisponiveis', {'profissionalId': profissionalId, 'servicoId': servicoId, 'data': dataFormatada});

    final cached = _getFromCache<List<DateTime>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    debugPrint('🔍 [HORARIOS] Tentando /profissionais/$profissionalId/horarios-disponiveis?servico_id=$servicoId&data=$dataFormatada');
    final response = await _get('/profissionais/$profissionalId/horarios-disponiveis', queryParams: {'servico_id': servicoId, 'data': dataFormatada});

    final horarios = (response['horarios_disponiveis'] as List)
        .map((horario) => DateTime.parse(horario))
        .toList();

    _setCache(cacheKey, horarios, ttl: const Duration(minutes: 2));
    debugPrint('🔍 [HORARIOS] Sucesso: ${horarios.length} horários disponíveis');
    return horarios;
  }
}

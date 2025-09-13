import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../models/servico.dart';
import '../models/agendamento.dart';
import '../models/horario_trabalho.dart';

class ApiService {
  static const String baseUrl = "https://barbearia-backend-service-862082955632.southamerica-east1.run.app";
  static const String negocioId = "YXcwY5rHdXBNRm4BtsP1";
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'negocio-id': negocioId,
    };
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(data));
    return _handleResponse(response);
  }
  
  // Outros métodos genéricos (_get, _put, _delete...)
  Future<dynamic> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(data));
    return _handleResponse(response);
  }

  Future<dynamic> _delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro na API: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Usuario> syncProfile(Map<String, dynamic> syncData) async {
    final data = await _post('/users/sync-profile', syncData);
    return Usuario.fromJson(data as Map<String, dynamic>);
  }

  // ===================================================================
  // FUNÇÃO FINALMENTE CORRIGIDA
  // ===================================================================
  Future<Usuario> validarCodigoConvite(String codigo, {String? nome, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Usuário não está logado para sincronizar o perfil.");
    }

    final data = <String, dynamic>{
      'codigo_convite': codigo,
      'nome': nome ?? user.displayName ?? 'Usuário sem nome',
      'email': email ?? user.email!,
      'firebase_uid': user.uid,
      // LINHA ADICIONADA PARA RESOLVER O ERRO 400
      'negocio_id': negocioId, 
    };

    final result = await _post('/users/sync-profile', data);
    return Usuario.fromJson(result as Map<String, dynamic>);
  }

  Future<bool> verificarNecessidadeCodigoConvite() async {
    try {
      final data = await _get('/negocios/$negocioId/admin-status');
      return !(data['tem_admin'] ?? true);
    } catch (e) {
      return true;
    }
  }

  Future<Usuario> getProfile() async {
    final data = await _get('/me/profile') as Map<String, dynamic>;
    return Usuario.fromJson(data);
  }

  Future<List<Usuario>> getProfissionais() async {
    final data = await _get('/profissionais', queryParams: {'negocio_id': negocioId});
    
    // A API pode retornar uma lista diretamente ou um objeto com 'profissionais'
    if (data is List) {
      return (data as List).map((json) => Usuario.fromJson(json as Map<String, dynamic>)).toList();
    } else if (data is Map && data.containsKey('profissionais')) {
      return (data['profissionais'] as List).map((json) => Usuario.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Formato de resposta inesperado da API');
    }
  }

  // Novo método para buscar TODOS os usuários do negócio (não só profissionais)
  Future<List<Usuario>> getTodosUsuarios() async {
    try {
      // Primeiro tenta endpoint para todos os usuários
      final data = await _get('/negocios/$negocioId/usuarios');
      
      if (data is List) {
        return (data as List).map((json) => Usuario.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map && data.containsKey('usuarios')) {
        return (data['usuarios'] as List).map((json) => Usuario.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // Se não funcionar, usa o endpoint de profissionais como fallback
        return await getProfissionais();
      }
    } catch (e) {
      // Fallback para profissionais se der erro
      print('🔍 [USUARIOS] Endpoint /negocios/$negocioId/usuarios falhou, tentando /profissionais...');
      return await getProfissionais();
    }
  }
  
  Future<Usuario> adminCreateUser(Map<String, dynamic> userData) async {
    final data = await _post('/negocios/$negocioId/pacientes', userData);
    return Usuario.fromJson(data);
  }

  // O resto do seu arquivo continua aqui...
  Future<Usuario> getProfissional(String id) async {
    final data = await _get('/profissionais/$id');
    return Usuario.fromJson(data);
  }

  Future<Usuario> updateProfissionalProfile(Map<String, dynamic> profileData) async {
    final data = await _put('/me/profissional', profileData);
    return Usuario.fromJson(data);
  }

  Future<List<Servico>> getServicos() async {
    final data = await _get('/servicos');
    return (data['servicos'] as List).map((json) => Servico.fromJson(json)).toList();
  }

  Future<List<Servico>> getMeusServicos() async {
    try {
      // Primeiro tenta endpoint específico do profissional
      final data = await _get('/me/servicos');
      
      if (data is List) {
        return (data as List).map((json) => Servico.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map && data.containsKey('servicos')) {
        return (data['servicos'] as List).map((json) => Servico.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        // Se der 404, tenta endpoint administrativo por negócio
        try {
          final data = await _get('/negocios/$negocioId/servicos');
          
          if (data is List) {
            return (data as List).map((json) => Servico.fromJson(json as Map<String, dynamic>)).toList();
          } else if (data is Map && data.containsKey('servicos')) {
            return (data['servicos'] as List).map((json) => Servico.fromJson(json as Map<String, dynamic>)).toList();
          } else {
            return [];
          }
        } catch (e2) {
          // Se ambos falharem, retorna lista vazia
          print('🔍 [SERVICOS] Ambos endpoints falharam: /me/servicos e /negocios/$negocioId/servicos');
          return [];
        }
      } else {
        rethrow;
      }
    }
  }

  Future<Servico> createServico(Map<String, dynamic> servicoData) async {
    final data = await _post('/me/servicos', servicoData);
    return Servico.fromJson(data);
  }

  Future<Servico> updateServico(String servicoId, Map<String, dynamic> servicoData) async {
    final data = await _put('/me/servicos/$servicoId', servicoData);
    return Servico.fromJson(data);
  }

  Future<void> deleteServico(String servicoId) async {
    await _delete('/me/servicos/$servicoId');
  }

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
    final endpoint = '/profissionais/$profissionalId/horarios-disponiveis?servico_id=$servicoId&data=$dataFormatada';
    final response = await _get(endpoint);
    return (response['horarios_disponiveis'] as List)
        .map((horario) => DateTime.parse(horario))
        .toList();
  }

  Future<Agendamento> createAgendamento(Map<String, dynamic> agendamentoData) async {
    final data = await _post('/agendamentos', agendamentoData);
    return Agendamento.fromJson(data);
  }

  Future<List<Agendamento>> getMeusAgendamentos() async {
    final data = await _get('/agendamentos/me');
    return (data['agendamentos'] as List).map((json) => Agendamento.fromJson(json)).toList();
  }

  Future<List<Agendamento>> getAgendamentosProfissional() async {
    try {
      // Primeiro tenta endpoint específico do profissional
      final data = await _get('/me/agendamentos');
      
      if (data is List) {
        return (data as List).map((json) => Agendamento.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map && data.containsKey('agendamentos')) {
        return (data['agendamentos'] as List).map((json) => Agendamento.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        // Se der 404, tenta endpoint administrativo por negócio
        try {
          final data = await _get('/negocios/$negocioId/agendamentos');
          
          if (data is List) {
            return (data as List).map((json) => Agendamento.fromJson(json as Map<String, dynamic>)).toList();
          } else if (data is Map && data.containsKey('agendamentos')) {
            return (data['agendamentos'] as List).map((json) => Agendamento.fromJson(json as Map<String, dynamic>)).toList();
          } else {
            return [];
          }
        } catch (e2) {
          // Se ambos falharem, retorna lista vazia
          print('🔍 [AGENDAMENTOS] Ambos endpoints falharam: /me/agendamentos e /negocios/$negocioId/agendamentos');
          return [];
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelarAgendamento(String agendamentoId) async {
    await _delete('/agendamentos/$agendamentoId');
  }

  Future<void> cancelarAgendamentoProfissional(String agendamentoId) async {
    await _post('/me/agendamentos/$agendamentoId/cancelar', {});
  }

  Future<String> uploadFoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    final token = await user.getIdToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-foto'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['negocio-id'] = negocioId;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    var response = await request.send();
    var responseData = await response.stream.transform(utf8.decoder).join();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(responseData);
      return data['foto_url'];
    } else {
      throw Exception('Erro ao fazer upload: $responseData');
    }
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/usuario.dart';
import '../utils/app_colors.dart';
import 'user_create_screen.dart'; // IMPORTA A NOVA TELA

class ProfissionaisScreen extends StatefulWidget {
  const ProfissionaisScreen({super.key});

  @override
  State<ProfissionaisScreen> createState() => _ProfissionaisScreenState();
}

class _ProfissionaisScreenState extends State<ProfissionaisScreen> {
  final ApiService _apiService = ApiService();
  List<Usuario> _usuarios = []; // Mudou de _profissionais para _usuarios
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    print('🔍 [USUARIOS] Iniciando carregamento...');
    setState(() { _isLoading = true; });
    try {
      final usuarios = await _apiService.getTodosUsuarios();
      print('🔍 [USUARIOS] Sucesso: ${usuarios.length} usuários carregados');
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      print('🔍 [USUARIOS] ERRO: $e');
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar usuários: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarUsuarios,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarUsuarios,
              child: _usuarios.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _usuarios.length,
                      itemBuilder: (context, index) {
                        final usuario = _usuarios[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: usuario.fotoPerfil != null
                                  ? NetworkImage(usuario.fotoPerfil!)
                                  : null,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: usuario.fotoPerfil == null
                                  ? const Icon(Icons.person, color: AppColors.primary)
                                  : null,
                            ),
                            title: Text(
                              usuario.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(usuario.email),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: usuario.ativo
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        usuario.ativo ? 'Ativo' : 'Inativo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: usuario.ativo
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(usuario.role).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getRoleText(usuario.role),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getRoleColor(usuario.role),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Editar'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'services',
                                  child: ListTile(
                                    leading: Icon(Icons.room_service),
                                    title: Text('Serviços'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'schedule',
                                  child: ListTile(
                                    leading: Icon(Icons.schedule),
                                    title: Text('Horários'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: usuario.ativo ? 'deactivate' : 'activate',
                                  child: ListTile(
                                    leading: Icon(
                                      usuario.ativo ? Icons.block : Icons.check_circle,
                                      color: usuario.ativo ? AppColors.error : AppColors.success,
                                    ),
                                    title: Text(usuario.ativo ? 'Desativar' : 'Ativar'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Edição em desenvolvimento')),
                                    );
                                    break;
                                  case 'services':
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gestão de serviços em desenvolvimento')),
                                    );
                                    break;
                                  case 'schedule':
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gestão de horários em desenvolvimento')),
                                    );
                                    break;
                                  case 'activate':
                                  case 'deactivate':
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Alteração de status em desenvolvimento')),
                                    );
                                    break;
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'profissional':
        return AppColors.info;
      case 'paciente':
      case 'cliente':
        return AppColors.success;
      default:
        return AppColors.textMedium;
    }
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'ADMIN';
      case 'profissional':
        return 'PROFISSIONAL';
      case 'paciente':
        return 'PACIENTE';
      case 'cliente':
        return 'CLIENTE';
      default:
        return role.toUpperCase();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum usuário encontrado',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Os usuários aparecerão aqui conforme se cadastrarem',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
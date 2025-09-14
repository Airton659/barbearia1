import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _isChangingPassword = false;

  Usuario? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      _currentUser = authService.currentUser;

      if (_currentUser != null) {
        _nomeController.text = _currentUser!.nome;
        _telefoneController.text = _currentUser!.telefone ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isFormValid() {
    if (!_formKey.currentState!.validate()) return false;

    if (_isChangingPassword) {
      return _senhaAtualController.text.isNotEmpty &&
             _novaSenhaController.text.isNotEmpty &&
             _confirmarSenhaController.text.isNotEmpty &&
             _novaSenhaController.text == _confirmarSenhaController.text;
    }

    return true;
  }

  Future<void> _saveChanges() async {
    if (!_isFormValid()) return;

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Atualizar dados do perfil (nome e telefone)
      if (_nomeController.text != _currentUser?.nome ||
          _telefoneController.text != (_currentUser?.telefone ?? '')) {

        final updateData = {
          'nome': _nomeController.text.trim(),
          'telefone': _telefoneController.text.trim().isEmpty ? null : _telefoneController.text.trim(),
        };

        await apiService.updateUserProfile(updateData);
      }

      // Alterar senha se solicitado
      if (_isChangingPassword) {
        await authService.changePassword(
          _senhaAtualController.text,
          _novaSenhaController.text,
        );

        // Limpar campos de senha após sucesso
        _senhaAtualController.clear();
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
        setState(() => _isChangingPassword = false);
      }

      // Recarregar dados do usuário
      await authService.refreshUser();
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alterações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Configurações'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Configurações'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção Meus Dados
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meus Dados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Seção Segurança
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Segurança',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = !_isChangingPassword;
                                if (!_isChangingPassword) {
                                  _senhaAtualController.clear();
                                  _novaSenhaController.clear();
                                  _confirmarSenhaController.clear();
                                }
                              });
                            },
                            child: Text(_isChangingPassword ? 'Cancelar' : 'Alterar Senha'),
                          ),
                        ],
                      ),

                      if (_isChangingPassword) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaAtualController,
                          decoration: InputDecoration(
                            labelText: 'Senha Atual',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureSenhaAtual ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscureSenhaAtual = !_obscureSenhaAtual);
                              },
                            ),
                          ),
                          obscureText: _obscureSenhaAtual,
                          validator: _isChangingPassword ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Senha atual é obrigatória';
                            }
                            return null;
                          } : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _novaSenhaController,
                          decoration: InputDecoration(
                            labelText: 'Nova Senha',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNovaSenha ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscureNovaSenha = !_obscureNovaSenha);
                              },
                            ),
                          ),
                          obscureText: _obscureNovaSenha,
                          validator: _isChangingPassword ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nova senha é obrigatória';
                            }
                            if (value.length < 6) {
                              return 'Senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          } : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmarSenhaController,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Nova Senha',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmarSenha ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscureConfirmarSenha = !_obscureConfirmarSenha);
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmarSenha,
                          validator: _isChangingPassword ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirmação de senha é obrigatória';
                            }
                            if (value != _novaSenhaController.text) {
                              return 'Senhas não coincidem';
                            }
                            return null;
                          } : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Salvar Alterações',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
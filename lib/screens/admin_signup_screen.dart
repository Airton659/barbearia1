import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';

class AdminSignUpScreen extends StatefulWidget {
  const AdminSignUpScreen({super.key});

  @override
  State<AdminSignUpScreen> createState() => _AdminSignUpScreenState();
}

class _AdminSignUpScreenState extends State<AdminSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _auth = FirebaseAuth.instance;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codigoController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _signUpAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    User? userToDeleteOnError;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      userToDeleteOnError = credential.user;
      
      await credential.user?.updateDisplayName(_nomeController.text.trim());

      // ===================================================================
      // CHAMADA CORRIGIDA PARA USAR PARÂMETROS NOMEADOS
      // ===================================================================
      final usuario = await _apiService.validarCodigoConvite(
        _codigoController.text.trim(),
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        if (usuario.role == 'admin') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bem-vindo, ${usuario.nome}! Sua conta de administrador foi criada.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          throw Exception('O código é válido, mas não concedeu permissão de administrador.');
        }
      }
    } catch (e) {
      if(userToDeleteOnError != null){
        await userToDeleteOnError.delete();
      }
      
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          errorMessage = 'Este email já está cadastrado. Tente fazer login.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primeiro Administrador'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 60, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cadastro do Admin',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Preencha seus dados e o código de convite para se tornar o administrador do negócio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMedium),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Seu Nome Completo', prefixIcon: Icon(Icons.person)),
                      validator: (v) => v!.isEmpty ? 'O nome é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Seu Email', prefixIcon: Icon(Icons.email)),
                      validator: (v) => v!.isEmpty ? 'O email é obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Crie uma Senha', prefixIcon: Icon(Icons.lock)),
                      validator: (v) => (v?.length ?? 0) < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codigoController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'Código de Convite', prefixIcon: Icon(Icons.vpn_key)),
                       validator: (v) => v!.isEmpty ? 'O código de convite é obrigatório' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUpAdmin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Criar Conta de Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
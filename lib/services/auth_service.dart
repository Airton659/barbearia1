import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  Usuario? _currentUser;
  bool _isLoading = false;

  Usuario? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      print('🔥 _onAuthStateChanged - usuário logado, buscando perfil atualizado');
      // ✅ Usar getMyProfile em vez de syncProfile para dados atualizados
      try {
        final updatedUser = await _apiService.getMyProfile();
        print('🔥 _onAuthStateChanged perfil obtido: ${updatedUser.toJson()}');
        _currentUser = updatedUser;
        await _saveUserToLocalStorage(updatedUser);
      } catch (e) {
        print('🔥 Erro ao obter perfil no login, fazendo fallback para syncProfile: $e');
        // Fallback para sync se getMyProfile falhar
        await _syncUserProfile(firebaseUser);
      }
    } else {
      _currentUser = null;
      await _clearLocalStorage();
    }
    notifyListeners();
  }

  Future<void> _loadUserFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(
          jsonDecode(userJson),
        );
        // Verificar se tem a estrutura antiga e limpar se necessário
        if (userData['role'] != null && userData['roles'] == null) {
          debugPrint('Limpando dados antigos do localStorage');
          await prefs.remove('current_user');
          return;
        }
        _currentUser = Usuario.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário do storage local: $e');
      // Em caso de erro, limpar o localStorage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    }
  }

  Future<void> _saveUserToLocalStorage(Usuario user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Erro ao salvar usuário no storage local: $e');
    }
  }

  Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      debugPrint('Erro ao limpar storage local: $e');
    }
  }

  Future<void> _syncUserProfile(User firebaseUser) async {
    try {
      final usuario = Usuario(
        id: '',
        nome: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Usuário',
        email: firebaseUser.email ?? '',
        firebaseUid: firebaseUser.uid,
        roles: {AppConstants.negocioId: AppConstants.roleCliente},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final syncedUser = await _apiService.syncProfile(usuario);
        _currentUser = syncedUser;
        await _saveUserToLocalStorage(syncedUser);
      } catch (apiError) {
        // Se a API falhar, usar os dados do Firebase
        _currentUser = usuario;
        await _saveUserToLocalStorage(usuario);
      }
    } catch (e) {
      // Em caso de erro, criar usuário local temporário
      _currentUser = Usuario(
        id: firebaseUser.uid,
        nome: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Usuário',
        email: firebaseUser.email ?? '',
        firebaseUid: firebaseUser.uid,
        roles: {AppConstants.negocioId: AppConstants.roleCliente},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(nome);
        await _syncUserProfile(credential.user!);
      }

      return credential;
    } catch (e) {
      debugPrint('Erro no cadastro: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } catch (e) {
      debugPrint('Erro no login: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Limpar dados primeiro
      _currentUser = null;
      await _clearLocalStorage();

      // Depois fazer logout do Firebase
      await _auth.signOut();
    } catch (e) {
      debugPrint('Erro no logout: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Erro ao enviar email de reset: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Usuário não está logado ou não possui um email.');
    }

    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      // Re-lançar a exceção para que a UI possa tratá-la
      throw e;
    } catch (e) {
      debugPrint('Erro ao alterar a senha: $e');
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    print('🔥 refreshUser chamado - buscando dados atualizados');
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final updatedUser = await _apiService.getMyProfile();
        print('🔥 refreshUser recebeu usuário atualizado: ${updatedUser.toJson()}');
        _currentUser = updatedUser;
        await _saveUserToLocalStorage(updatedUser);
        notifyListeners();
        print('🔥 refreshUser concluído - UI será atualizada');
      }
    } catch (e) {
      print('🔥 Erro ao atualizar usuário: $e');
      debugPrint('Erro ao atualizar usuário: $e');
      rethrow;
    }
  }

  String? getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
          return 'Senha incorreta.';
        case 'email-already-in-use':
          return 'Este email já está em uso.';
        case 'weak-password':
          return 'A senha é muito fraca.';
        case 'invalid-email':
          return 'Email inválido.';
        case 'operation-not-allowed':
          return 'Operação não permitida.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente novamente mais tarde.';
        case 'requires-recent-login':
          return 'Esta operação requer autenticação recente. Faça login novamente.';
        default:
          return 'Erro de autenticação: ${error.message}';
      }
    }
    return 'Erro inesperado: $error';
  }
}
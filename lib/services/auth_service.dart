import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Usuario? _currentUser;
  bool _hasServerError = false;
  bool _isSyncing = false;

  Usuario? get currentUser => _currentUser;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  bool get hasServerError => _hasServerError;
  bool get isSyncing => _isSyncing;

  // Método para atualizar o usuário atual (ex: após consentimento LGPD)
  void updateCurrentUser(Usuario updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  AuthService() {
    try {
      _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
    } catch (e) {
      // Continua funcionando mesmo com erro do Firebase
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      await _fetchAndSetUser(firebaseUser);
    }
    notifyListeners();
  }

  Future<void> _fetchAndSetUser(User firebaseUser) async {
    // Prevent multiple simultaneous sync calls
    if (_isSyncing) {
      return;
    }
    
    _isSyncing = true;
    notifyListeners(); // Notifica que começou a sincronizar
    try {
      final apiService = ApiService(authService: this);
      
      // Tenta primeiro buscar o perfil existente
      try {
        final usuario = await apiService.getProfile();
        _currentUser = usuario;
        _hasServerError = false;
      } catch (e) {
        // Se não conseguir buscar, tenta fazer sync
        final syncData = {
          'nome': firebaseUser.displayName ?? firebaseUser.email ?? 'Usuário Sem Nome',
          'email': firebaseUser.email,
          'firebase_uid': firebaseUser.uid,
          'negocio_id': negocioId,
        };

        final responseBody = await apiService.syncProfile(syncData);
        _currentUser = responseBody;
        _hasServerError = false;
      }
    } catch (e) {
      // Marcar que há erro no servidor
      _hasServerError = true;
      
      // Criar usuário básico temporário para evitar crash
      _currentUser = Usuario(
        id: firebaseUser.uid,
        firebaseUid: firebaseUser.uid,
        nome: firebaseUser.displayName ?? firebaseUser.email ?? 'Usuário',
        email: firebaseUser.email ?? '',
        telefone: null,
        fotoPerfil: null,
        role: 'admin', // Role temporária para admin
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } finally {
      _isSyncing = false;
      notifyListeners(); // Notifica que terminou a sincronização
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }
  
  Future<void> updateFirebaseProfile({String? displayName, String? photoURL}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateProfile(displayName: displayName, photoURL: photoURL);
      await user.reload(); 
    }
  }

  // NOVA FUNÇÃO PARA ALTERAR A SENHA DENTRO DO APP
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _firebaseAuth.currentUser;
    final userEmail = user?.email;

    if (user != null && userEmail != null) {
      // Reautentica o usuário para garantir que ele é o dono da conta
      AuthCredential credential = EmailAuthProvider.credential(
        email: userEmail, 
        password: currentPassword
      );
      await user.reauthenticateWithCredential(credential);
      
      // Se a reautenticação for bem-sucedida, atualiza a senha
      await user.updatePassword(newPassword);
    } else {
      throw Exception('Nenhum usuário logado para alterar a senha.');
    }
  }

  Future<void> storeNegocioId(String negocioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('negocioId', negocioId);
  }

  String get negocioId => "YXcwY5rHdXBNRm4BtsP1"; // ID do negócio da barbearia

  void updateCurrentUserData(Usuario updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    // Prevent multiple simultaneous refresh calls
    if (_isSyncing) {
      return;
    }
    
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      _isSyncing = true;
      try {
        // Usar getProfile diretamente para pegar dados atualizados do banco
        final apiService = ApiService(authService: this);
        final responseBody = await apiService.getProfile();
        
        if (responseBody != null) {
          _currentUser = responseBody;
        } else {
          await _fetchAndSetUser(firebaseUser);
        }
      } catch (e) {
        await _fetchAndSetUser(firebaseUser);
      } finally {
        _isSyncing = false;
      }
      
      notifyListeners();
    }
  }

  Future<String?> getIdToken() async {
    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return token;
    }
    return null;
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _firebaseAuth.signOut();
    notifyListeners();
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
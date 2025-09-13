import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/codigo_convite_screen.dart';
import 'screens/demo_login_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'utils/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase inicializado com sucesso!');
    } else {
      print('✅ Firebase já estava inicializado!');
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      print('⚠️ ERRO FIREBASE: $e');
      print('📋 INSTRUÇÕES ANDROID: ...');
      print('🔄 Continuando sem Firebase (use código de convite)...');
    } else {
      print('✅ Firebase já configurado (app existia)!');
    }
  }
  
  await initializeDateFormatting('pt_BR', null);
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BarbeariaApp());
}

class BarbeariaApp extends StatelessWidget {
  const BarbeariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Barbearia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.brown,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
        ),
        home: Firebase.apps.isNotEmpty ? const AuthWrapper() : const DemoLoginScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Mostra loading enquanto está sincronizando
        if (authService.isSyncing) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...'),
                ],
              ),
            ),
          );
        }

        // Se tem usuário logado, navega baseado no role
        if (authService.currentUser != null) {
          final user = authService.currentUser!;
          if (user.role == 'admin' || user.role == 'profissional') {
            return const DashboardScreen();
          } else {
            return const ClientHomeScreen();
          }
        }

        // Se não tem usuário, mostra login
        return const LoginScreen();
      },
    );
  }
}


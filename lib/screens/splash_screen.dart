import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isLoggedIn) {
      _navigateToHomeScreen(authService.currentUser!.roleForCurrentBusiness);
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _navigateToHomeScreen(String role) {
    String route;
    switch (role) {
      case AppConstants.roleAdmin:
        route = '/admin-home';
        break;
      case AppConstants.roleProfissional:
        route = '/profissional-home';
        break;
      default:
        route = '/client-home';
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cut,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Barbearia',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
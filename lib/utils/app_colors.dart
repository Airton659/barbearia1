import 'package:flutter/material.dart';

class AppColors {
  // Cores primárias da barbearia
  static const Color primary = Color(0xFF8B4513); // Marrom escuro
  static const Color primaryLight = Color(0xFFA0522D); // Marrom claro
  static const Color primaryDark = Color(0xFF5D2F0A); // Marrom muito escuro
  
  // Cores de apoio
  static const Color secondary = Color(0xFFFFD700); // Dourado
  static const Color accent = Color(0xFF2C3E50); // Azul escuro
  
  // Cores neutras
  static const Color background = Color(0xFFF5F5F5); // Cinza muito claro
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFFFAFAFA);
  
  // Cores de texto
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFFBDC3C7);
  
  // Cores de status
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [secondary, Color(0xFFFFE55C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
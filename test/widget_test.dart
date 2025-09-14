// Teste básico do App de Barbearia
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbearia1/main.dart';

void main() {
  testWidgets('App inicializa corretamente', (WidgetTester tester) async {
    // Constrói o app e aguarda o primeiro frame
    await tester.pumpWidget(const MyApp());

    // Verifica se o app foi construído corretamente
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

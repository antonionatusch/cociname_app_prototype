import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cociname_app/src/features/auth/views/widgets/auth_shell.dart';

void main() {
  testWidgets('renders auth shell scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthShell(
          title: 'Titulo de prueba',
          subtitle: 'Subtitulo de prueba',
          child: Text('Contenido interno'),
        ),
      ),
    );

    expect(find.text('CocinaME'), findsOneWidget);
    expect(find.text('Titulo de prueba'), findsOneWidget);
    expect(find.text('Contenido interno'), findsOneWidget);
  });
}

import 'package:director_ejecutor_test/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('El contador aumenta al pulsar Incrementar', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Prueba Director/Ejecutor'), findsOneWidget);
    expect(find.text('Claude Code ejecuta. ChatGPT decide.'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Incrementar'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Reiniciar devuelve el contador a 0', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Incrementar'));
    await tester.tap(find.text('Incrementar'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Reiniciar'));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('2'), findsNothing);
  });
}

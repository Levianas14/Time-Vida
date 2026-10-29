import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_vivo/main.dart';

void main() {
  testWidgets(
    'event form explains missing name and preserves selected date and notes',
    (tester) async {
      CalendarEvent? saved;
      final date = DateTime(2027, 2, 12);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Abrir'),
                onPressed: () async {
                  saved = await showDialog<CalendarEvent>(
                    context: context,
                    builder: (_) => EventDialog(initialDate: date),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Data: 12/02/2027'), findsOneWidget);
      expect(find.textContaining('Horário:'), findsOneWidget);
      await tester.tap(find.text('Salvar evento'));
      await tester.pumpAndSettle();
      expect(find.text('Escreva um nome para o evento.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Aula de inglês');
      await tester.enterText(find.byType(TextField).last, 'Levar o caderno');
      await tester.tap(find.text('Salvar evento'));
      await tester.pumpAndSettle();
      expect(saved?.title, 'Aula de inglês');
      expect(saved?.note, 'Levar o caderno');
      expect(DateUtils.dateOnly(saved!.startsAt), date);
      expect(tester.takeException(), isNull);
    },
  );
}

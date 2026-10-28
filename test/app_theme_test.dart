import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_vivo/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('$brightness: readable text, selections, controls and buttons', () {
      final theme = AppTheme.build(brightness);
      final c = theme.colorScheme;
      for (final background in [
        theme.scaffoldBackgroundColor,
        c.surface,
        c.surfaceContainerHigh,
      ]) {
        for (final foreground in [
          c.onSurface,
          c.onSurfaceVariant,
          c.primary,
          c.secondary,
          c.tertiary,
          c.error,
        ]) {
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(c.outline, background), greaterThanOrEqualTo(3));
      }
      expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      expect(
        contrast(c.onPrimaryContainer, c.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      final style = theme.filledButtonTheme.style!;
      expect(
        contrast(
          style.foregroundColor!.resolve({WidgetState.hovered})!,
          style.backgroundColor!.resolve({WidgetState.hovered})!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(style.side!.resolve({WidgetState.focused})!.width, 2);
      expect(theme.inputDecorationTheme.focusedBorder!.borderSide.width, 2);
    });
  }

  test('reduced motion disables button and route transitions', () {
    final theme = AppTheme.build(Brightness.dark, reduceMotion: true);
    expect(theme.filledButtonTheme.style!.animationDuration, Duration.zero);
    for (final builder in theme.pageTransitionsTheme.builders.values) {
      expect(builder.transitionDuration, Duration.zero);
    }
  });

  testWidgets('forms and dialogs follow a theme change without losing input', (
    tester,
  ) async {
    final dark = ValueNotifier(false);
    final input = TextEditingController();
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: dark,
        builder: (_, enabled, __) => MaterialApp(
          theme: AppTheme.build(Brightness.light),
          darkTheme: AppTheme.build(Brightness.dark),
          themeMode: enabled ? ThemeMode.dark : ThemeMode.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextField(controller: input),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(title: Text('Evento')),
                    ),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Minha anotação');
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    dark.value = true;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AlertDialog))).brightness,
      Brightness.dark,
    );
    expect(input.text, 'Minha anotação');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    input.dispose();
    dark.dispose();
  });
}

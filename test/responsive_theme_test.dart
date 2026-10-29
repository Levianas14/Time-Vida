import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo_vivo/main.dart';
import 'package:tempo_vivo/theme/app_theme.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    tz_data.initializeTimeZones();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({'tempo_vivo_dark': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (_) async => true,
        );
  });

  testWidgets(
    'timer ticks update focus without rebuilding dashboard statistics',
    (tester) async {
      await tester.pumpWidget(const TempoVivoApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Iniciar'));
      await tester.tap(find.text('Iniciar'));
      await tester.pump();
      final stats = tester.widget<Text>(find.text('Tempo planejado'));
      expect(find.text('25:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('24:59'), findsOneWidget);
      expect(
        identical(stats, tester.widget<Text>(find.text('Tempo planejado'))),
        isTrue,
      );
      await tester.tap(find.text('Pausar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('24:59'), findsOneWidget);
      await tester.tap(find.text('Reiniciar'));
      await tester.pump();
      expect(find.text('25:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('system theme, saved override and reset persist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const TempoVivoApp());
    await tester.pumpAndSettle();
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(brightness(), Brightness.dark);
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    await tester.tap(find.byTooltip('Usar tema escuro'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('tempo_vivo_dark'), true);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const TempoVivoApp());
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    await tester.tap(find.byTooltip('Preferências'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    expect(prefs.containsKey('tempo_vivo_dark'), false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final size in [
    const Size(320, 640),
    const Size(768, 1024),
    const Size(1024, 600),
    const Size(1440, 900),
  ]) {
    testWidgets('dashboard, calendar, methods and preferences at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const TempoVivoApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).colorScheme.surface,
        AppPalette.dark.surface,
      );
      expect(
        find.byType(NavigationRail),
        size.width >= 900 ? findsOneWidget : findsNothing,
      );
      for (final label in ['Agenda', 'Métodos', 'Ajuda']) {
        await tester.tap(find.text(label).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('Abrir agenda'));
      await tester.tap(find.text('Abrir agenda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amanhã'));
      await tester.pumpAndSettle();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(
        tester
            .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
            .initialDate,
        DateUtils.dateOnly(tomorrow),
      );
      await tester.tap(find.text('Rotina semanal'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.text('Adicionar bloco'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Preferências'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Claro').last);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Aparência e foco'))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo_vivo/main.dart';
import 'package:tempo_vivo/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'tempo_vivo_dark': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (_) async => true,
        );
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
        Theme.of(tester.element(find.byType(Scaffold).first))
            .colorScheme
            .surface,
        AppPalette.dark.surface,
      );
      expect(
        find.byType(NavigationRail),
        size.width >= 900 ? findsOneWidget : findsNothing,
      );
      for (final label in ['Agenda', 'Métodos']) {
        await tester.tap(find.text(label).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
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

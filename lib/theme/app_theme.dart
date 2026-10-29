import 'package:flutter/material.dart';

/// Shared semantic tokens. Layout, typography and states are identical in both modes.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.navigation,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.primary,
    required this.primaryHover,
    required this.secondary,
    required this.text,
    required this.muted,
    required this.warning,
    required this.error,
    required this.onAccent,
    required this.control,
  });

  final Color background, navigation, surface, elevated, border, primary;
  final Color primaryHover, secondary, text, muted, warning, error, onAccent;
  // Functional outlines need more contrast than decorative card borders.
  final Color control;

  static const dark = AppPalette(
    background: Color(0xFF0D1420),
    navigation: Color(0xFF111B29),
    surface: Color(0xFF151F2D),
    elevated: Color(0xFF1B293B),
    border: Color(0xFF2B3A4E),
    primary: Color(0xFF62CBB6),
    primaryHover: Color(0xFF7DD9C6),
    secondary: Color(0xFF8CB8FF),
    text: Color(0xFFF4F7FB),
    muted: Color(0xFFA6B5C6),
    warning: Color(0xFFF0BA6B),
    error: Color(0xFFE88992),
    onAccent: Color(0xFF0D1420),
    control: Color(0xFF71869F),
  );

  static const light = AppPalette(
    background: Color(0xFFF7F9FC),
    navigation: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF0F5F9),
    border: Color(0xFFDCE4ED),
    primary: Color(0xFF087D6F),
    primaryHover: Color(0xFF086456),
    secondary: Color(0xFF3975D7),
    text: Color(0xFF1C2938),
    muted: Color(0xFF586779),
    warning: Color(0xFFB77122),
    error: Color(0xFFC54755),
    onAccent: Color(0xFFFFFFFF),
    control: Color(0xFF6A7D8C),
  );
}

class AppTheme {
  // Keep brand tokens intact; derive text inks that meet AA on each surface.
  static Color readableInk(Color color, Color background) {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
    }

    final target = background.computeLuminance() > .5
        ? Colors.black
        : Colors.white;
    for (var step = 0; step <= 100; step++) {
      final ink = Color.lerp(color, target, step / 100)!;
      if (ratio(ink, background) >= 4.5) return ink;
    }
    return target;
  }

  static const radius = 14.0;
  static const transition = Duration(milliseconds: 180);

  static AnimationStyle motion(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return AnimationStyle(
      duration: reduced ? Duration.zero : transition,
      reverseDuration: reduced ? Duration.zero : transition,
    );
  }

  static ThemeData build(Brightness brightness, {bool reduceMotion = false}) {
    final dark = brightness == Brightness.dark;
    final p = dark ? AppPalette.dark : AppPalette.light;
    final duration = reduceMotion ? Duration.zero : transition;
    final selected = Color.alphaBlend(
      p.primary.withValues(alpha: .13),
      p.surface,
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onAccent,
          primaryContainer: selected,
          onPrimaryContainer: readableInk(p.primary, selected),
          secondary: readableInk(p.secondary, p.elevated),
          onSecondary: p.onAccent,
          secondaryContainer: p.elevated,
          onSecondaryContainer: p.text,
          tertiary: readableInk(p.warning, p.elevated),
          onTertiary: p.onAccent,
          error: readableInk(p.error, p.elevated),
          onError: p.onAccent,
          surface: p.surface,
          onSurface: p.text,
          onSurfaceVariant: p.muted,
          surfaceDim: p.background,
          surfaceBright: p.elevated,
          surfaceContainerLowest: p.background,
          surfaceContainerLow: p.navigation,
          surfaceContainer: p.surface,
          surfaceContainerHigh: p.elevated,
          surfaceContainerHighest: p.elevated,
          outline: p.control,
          outlineVariant: p.border,
          surfaceTint: Colors.transparent,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final borderedShape = shape.copyWith(side: BorderSide(color: p.border));
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
    );
    final text = base.textTheme
        .copyWith(
          displaySmall: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.5,
            color: p.text,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -.7,
            color: p.text,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
            color: p.text,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -.3,
            color: p.text,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: p.text,
          ),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: p.text),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: p.text),
          bodySmall: TextStyle(fontSize: 12, height: 1.5, color: p.muted),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: p.text,
          ),
        )
        .apply(fontFamily: 'Inter');

    Color? overlay(Set<WidgetState> states) {
      if (states.contains(WidgetState.focused)) {
        return p.primary.withValues(alpha: .18);
      }
      if (states.contains(WidgetState.pressed)) {
        return p.primary.withValues(alpha: .14);
      }
      if (states.contains(WidgetState.hovered)) {
        return p.primary.withValues(alpha: .08);
      }
      return null;
    }

    final button = ButtonStyle(
      animationDuration: duration,
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      overlayColor: WidgetStateProperty.resolveWith(overlay),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: p.secondary, width: 2)
            : BorderSide.none,
      ),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      dividerColor: p.border,
      shadowColor: const Color(0x18000000),
      disabledColor: p.muted.withValues(alpha: .45),
      hoverColor: p.primary.withValues(alpha: .08),
      focusColor: p.primary.withValues(alpha: .18),
      splashFactory: reduceMotion
          ? NoSplash.splashFactory
          : InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: _QuietPageTransition(reduceMotion),
        },
      ),
      iconTheme: IconThemeData(color: p.muted, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        toolbarHeight: 72,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: .5,
        shadowColor: const Color(0x18000000),
        shape: borderedShape,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 24),
      filledButtonTheme: FilledButtonThemeData(
        style: button.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return p.elevated;
            return states.contains(WidgetState.hovered)
                ? p.primaryHover
                : p.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? p.muted : p.onAccent,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? p.muted.withValues(alpha: .45)
                : p.text,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? p.border
                  : states.contains(WidgetState.focused)
                  ? p.primary
                  : p.control,
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: button),
      iconButtonTheme: IconButtonThemeData(
        style: button.copyWith(
          padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? p.muted.withValues(alpha: .45)
                : p.muted,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: button.copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? selected : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? p.muted.withValues(alpha: .45)
                : states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : p.muted,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? p.primary
                  : p.border,
            ),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: p.control, width: 1.5),
        checkColor: WidgetStatePropertyAll(p.onAccent),
        overlayColor: WidgetStateProperty.resolveWith(overlay),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: selected,
        labelStyle: text.labelLarge?.copyWith(color: p.text),
        checkmarkColor: p.primary,
        side: BorderSide(color: p.control),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? p.navigation : p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.control),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.error, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: .25),
        selectionHandleColor: p.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        shape: borderedShape,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.muted,
        shape: borderedShape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.elevated,
        headerForegroundColor: p.text,
        weekdayStyle: text.bodySmall,
        shape: borderedShape,
        todayBorder: BorderSide(color: p.primary),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.onAccent
              : states.contains(WidgetState.disabled)
              ? p.muted.withValues(alpha: .45)
              : p.text,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : null,
        ),
        dayOverlayColor: WidgetStateProperty.resolveWith(overlay),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.elevated,
        shape: borderedShape,
        dialBackgroundColor: p.surface,
        dialHandColor: p.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.navigation,
        surfaceTintColor: Colors.transparent,
        indicatorColor: selected,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : p.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.primary : p.muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.navigation,
        indicatorColor: selected,
        selectedIconTheme: IconThemeData(color: p.primary),
        unselectedIconTheme: IconThemeData(color: p.muted),
        selectedLabelTextStyle: text.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(color: p.muted),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onAccent,
        elevation: 2,
        shape: shape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.elevated,
        circularTrackColor: p.elevated,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.border,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: .12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.elevated,
        contentTextStyle: text.bodyMedium,
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
        shape: borderedShape,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.elevated,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(color: p.text),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.control),
        radius: const Radius.circular(8),
      ),
    );
  }
}

class _QuietPageTransition extends PageTransitionsBuilder {
  const _QuietPageTransition(this.reduceMotion);
  final bool reduceMotion;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : AppTheme.transition;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return reduceMotion
        ? child
        : FadeTransition(opacity: animation, child: child);
  }
}

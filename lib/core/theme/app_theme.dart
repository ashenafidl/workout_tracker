import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";

class AppTheme {
  // Brand palette.
  static const Color volt = Color(0xFFD4FF3A);
  static const Color voltDeep = Color(0xFF5C7A00);
  static const Color carbon = Color(0xFF0D0E10);
  static const Color ember = Color(0xFFFF7A3D);

  // Bundled font families (see pubspec.yaml).
  static const String displayFont = "SpaceGrotesk";
  static const String bodyFont = "Inter";

  ThemeData get light {
    return _buildTheme(_lightScheme);
  }

  ThemeData get dark {
    return _buildTheme(_darkScheme);
  }

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: .dark,
    primary: volt,
    onPrimary: carbon,
    primaryContainer: volt,
    onPrimaryContainer: carbon,
    secondary: Color(0xFFB9DD2E),
    onSecondary: carbon,
    secondaryContainer: Color(0xFF2E3417),
    onSecondaryContainer: volt,
    tertiary: ember,
    onTertiary: carbon,
    tertiaryContainer: Color(0xFF3D2216),
    onTertiaryContainer: Color(0xFFFFB896),
    error: Color(0xFFFF6B6B),
    onError: carbon,
    errorContainer: Color(0xFF4A1C1C),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: carbon,
    onSurface: Color(0xFFF4F5F6),
    onSurfaceVariant: Color(0xFF8B8E94),
    surfaceDim: Color(0xFF09090B),
    surfaceBright: Color(0xFF34363B),
    surfaceContainerLowest: Color(0xFF08090A),
    surfaceContainerLow: Color(0xFF141518),
    surfaceContainer: Color(0xFF1A1B1F),
    surfaceContainerHigh: Color(0xFF222328),
    surfaceContainerHighest: Color(0xFF2B2D32),
    outline: Color(0xFF45474D),
    outlineVariant: Color(0xFF26282C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF4F5F6),
    onInverseSurface: carbon,
    inversePrimary: voltDeep,
    surfaceTint: Color(0x00000000),
  );

  // Same volt + carbon identity as dark. Neon volt is unreadable as text on a
  // light surface, so `primary` (text/icons on surfaces) is a deep volt while
  // containers, FABs and filled buttons use the neon itself.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: .light,
    primary: voltDeep,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: volt,
    onPrimaryContainer: carbon,
    secondary: Color(0xFF4A6300),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDF8C4),
    onSecondaryContainer: Color(0xFF283600),
    tertiary: Color(0xFFC2501A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFE2D4),
    onTertiaryContainer: Color(0xFF4A1A00),
    error: Color(0xFFC62828),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF4F5F2),
    onSurface: carbon,
    onSurfaceVariant: Color(0xFF63666C),
    surfaceDim: Color(0xFFDFE0DC),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFBF8),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFEBECE8),
    surfaceContainerHighest: Color(0xFFE2E3DF),
    outline: Color(0xFFBFC1BC),
    outlineVariant: Color(0xFFE2E3DF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: carbon,
    onInverseSurface: Color(0xFFF4F5F6),
    inversePrimary: volt,
    surfaceTint: Color(0x00000000),
  );

  ThemeData _buildTheme(ColorScheme cs) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: bodyFont,
    );
    final textTheme = _buildTextTheme(base.textTheme, cs);
    final buttonTextStyle = textTheme.labelLarge?.copyWith(
      fontWeight: .w700,
      letterSpacing: 0.3,
    );

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      dividerColor: cs.outlineVariant,
      textTheme: textTheme,

      iconTheme: IconThemeData(color: cs.onSurface),

      // Swap Material's built-in back / close / menu glyphs for Phosphor.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) =>
            const PhosphorIcon(PhosphorIconsDuotone.arrowLeft),
        closeButtonIconBuilder: (context) =>
            const PhosphorIcon(PhosphorIconsDuotone.x),
        drawerButtonIconBuilder: (context) =>
            const PhosphorIcon(PhosphorIconsDuotone.list),
        endDrawerButtonIconBuilder: (context) =>
            const PhosphorIcon(PhosphorIconsDuotone.list),
      ),

      appBarTheme: AppBarThemeData(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: .w500),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),

      dividerTheme: DividerThemeData(color: cs.outlineVariant),

      // Neon volt buttons with carbon text, in both brightnesses.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: .circular(8)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: cs.surfaceContainerHigh,
          foregroundColor: cs.onSurface,
          textStyle: buttonTextStyle,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          textStyle: buttonTextStyle,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: buttonTextStyle,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: buttonTextStyle,
      ),

      chipTheme: ChipThemeData(
        side: BorderSide(color: cs.outline),
        labelStyle: textTheme.labelLarge,
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLow,
        elevation: 0,
        type: .fixed,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: cs.primaryContainer,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        modalBackgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: cs.outline,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: .floating,
        dismissDirection: .horizontal,
        backgroundColor: cs.brightness == .dark
            ? cs.surfaceContainerHighest
            : cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.brightness == .dark ? cs.onSurface : cs.onInverseSurface,
          fontWeight: .w500,
        ),
        actionTextColor: volt,
        closeIconColor: cs.brightness == .dark
            ? cs.onSurfaceVariant
            : cs.onInverseSurface,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: .circular(8),
          side: BorderSide(
            color: cs.brightness == .dark
                ? cs.outlineVariant
                : Colors.transparent,
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? cs.onPrimaryContainer
              : cs.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  /// Space Grotesk (bold, tight) for numbers, headings and labels; Inter for
  /// body copy. Small labels are tracked out like "WEEKLY VOLUME" captions.
  TextTheme _buildTextTheme(TextTheme base, ColorScheme cs) {
    TextStyle? display(TextStyle? style, FontWeight weight, double tracking) {
      return style?.copyWith(
        fontFamily: displayFont,
        fontWeight: weight,
        letterSpacing: tracking,
      );
    }

    return base
        .copyWith(
          displayLarge: display(base.displayLarge, .w700, -2),
          displayMedium: display(base.displayMedium, .w700, -1.5),
          displaySmall: display(base.displaySmall, .w700, -1),
          headlineLarge: display(base.headlineLarge, .w700, -0.8),
          headlineMedium: display(base.headlineMedium, .w700, -0.6),
          headlineSmall: display(base.headlineSmall, .w700, -0.4),
          titleLarge: display(base.titleLarge, .w700, -0.2),
          titleMedium: display(base.titleMedium, .w600, 0),
          titleSmall: display(base.titleSmall, .w600, 0),
          labelLarge: display(base.labelLarge, .w600, 0.2),
          labelMedium: display(base.labelMedium, .w600, 0.8),
          labelSmall: display(base.labelSmall, .w600, 1.2),
        )
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
  }
}

/// Bouncing scroll physics for every scrollable in the app, registered once on
/// `MaterialApp.scrollBehavior`. Scrollables that pass their own `physics`
/// (e.g. `NeverScrollableScrollPhysics`) keep it.
class AppScrollBehavior extends MaterialScrollBehavior {
  const new();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());
  }

  // The bounce is the overscroll feedback, so drop Android's stretch effect.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

import 'package:flutter/material.dart';

// Design tokens read off the client's Figma (app/design/figma/*.png).
const Color kMaroon = Color(0xFF7B2437); // primary: buttons, banners, active icons
const Color kMaroonDark = Color(0xFF42302A); // dark end of the splash gradient
const Color kCream = Color(0xFFF6F0E6); // page background
const Color kSurface = Color(0xFFFFFFFF); // cards
const Color kGold = Color(0xFFC39A4B); // eyebrow labels, thin borders
const Color kInk = Color(0xFF3A2A22); // main text
const Color kMuted = Color(0xFF8A7A72); // secondary text
const Color kBlush = Color(0xFFF3E3E1); // soft fill behind line icons
const Color kLine = Color(0xFFE9DFD0); // hairlines and field borders

/// Demo stand-ins (mock OTP, mock payment, quick demo logins) show their notes and shortcuts
/// only while this is on. Ship without them: flutter build --dart-define=DEMO=false
const bool kDemoMode = bool.fromEnvironment('DEMO', defaultValue: true);

const LinearGradient kSplashGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF86283E), Color(0xFF6A2A36), kMaroonDark],
  stops: [0.0, 0.45, 1.0],
);

// Both bundled fonts are variable, so a weight has to be set twice: fontWeight and the
// 'wght' axis. These lists are the axis half, for use next to an explicit fontWeight.
const List<FontVariation> kW4 = [FontVariation('wght', 400)];
const List<FontVariation> kW5 = [FontVariation('wght', 500)];
const List<FontVariation> kW6 = [FontVariation('wght', 600)];
const List<FontVariation> kW7 = [FontVariation('wght', 700)];

const String kDisplayFont = 'Playfair';
const String kBodyFont = 'Inter';

FontWeight _fw(int weight) => FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)];

/// Playfair Display, for screen titles and headings.
TextStyle display(double size, {int weight = 700, Color? color}) => TextStyle(
      fontFamily: kDisplayFont,
      fontSize: size,
      fontWeight: _fw(weight),
      fontVariations: [FontVariation('wght', weight.toDouble())],
      color: color ?? kInk,
      height: 1.15,
    );

/// Inter, for everything else.
TextStyle body(double size, {int weight = 400, Color? color}) => TextStyle(
      fontFamily: kBodyFont,
      fontSize: size,
      fontWeight: _fw(weight),
      fontVariations: [FontVariation('wght', weight.toDouble())],
      color: color ?? kInk,
    );

/// Small letter-spaced uppercase label, gold by default.
TextStyle eyebrow({double size = 11, Color color = kGold}) =>
    body(size, weight: 700, color: color).copyWith(letterSpacing: 1.1);

/// Soft shadow under white cards.
final List<BoxShadow> kCardShadow = [
  BoxShadow(color: const Color(0xFF6B4A2B).withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 6)),
];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kMaroon,
    primary: kMaroon,
    onPrimary: Colors.white,
    secondary: kGold,
    surface: kSurface,
    onSurface: kInk,
  );
  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: kLine),
  );
  final textTheme = TextTheme(
    displayLarge: display(44),
    displayMedium: display(38),
    displaySmall: display(32),
    headlineLarge: display(30),
    headlineMedium: display(26),
    headlineSmall: display(22),
    titleLarge: display(20),
    titleMedium: body(16, weight: 600),
    titleSmall: body(14, weight: 600),
    bodyLarge: body(16),
    bodyMedium: body(14.5),
    bodySmall: body(12.5, color: kMuted),
    labelLarge: body(14.5, weight: 600),
    labelMedium: body(12.5, weight: 600),
    labelSmall: body(11.5, weight: 600),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kBodyFont,
    textTheme: textTheme,
    scaffoldBackgroundColor: kCream,
    appBarTheme: AppBarTheme(
      backgroundColor: kCream,
      foregroundColor: kInk,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: display(22),
      iconTheme: const IconThemeData(color: kInk),
      actionsIconTheme: const IconThemeData(color: kMaroon),
    ),
    // cardColor, not cardTheme: the cardTheme type changed name across Flutter versions.
    cardColor: kSurface,
    dividerColor: kLine,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kMaroon,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB9A4A8),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: body(15.5, weight: 600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kMaroon,
        backgroundColor: kSurface,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        side: const BorderSide(color: kMaroon, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: body(15.5, weight: 600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kMaroon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: body(14.5, weight: 600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kMaroon,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      border: field,
      enabledBorder: field,
      focusedBorder: field.copyWith(borderSide: const BorderSide(color: kMaroon, width: 1.6)),
      labelStyle: body(15, color: kMuted),
      floatingLabelStyle: body(15, weight: 600, color: kMaroon),
      hintStyle: body(15, color: const Color(0xFFA89C94)),
      helperStyle: body(12.5, color: kMuted),
      prefixIconColor: kMaroon,
      suffixIconColor: kMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurface,
      selectedColor: kBlush,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: kLine),
      labelStyle: body(13.5, weight: 500),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: body(14, weight: 500, color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: display(22),
      contentTextStyle: body(14.5, color: kMuted).copyWith(height: 1.45),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: body(15.5, weight: 600),
      subtitleTextStyle: body(13, color: kMuted),
      iconColor: kMaroon,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kMaroon),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kMaroon : kLine,
      ),
      thumbColor: WidgetStateProperty.all(Colors.white),
    ),
  );
}

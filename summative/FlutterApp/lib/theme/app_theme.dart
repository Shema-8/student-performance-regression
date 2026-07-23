import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central place for the app's visual identity — a deep indigo/violet
/// "night study" gradient with frosted glass cards and a warm amber
/// accent for calls to action and the result gauge.
class AppColors {
  static const Color bgTop = Color(0xFF0F0C29);
  static const Color bgMid = Color(0xFF302B63);
  static const Color bgBottom = Color(0xFF24243E);

  static const Color accent = Color(0xFFFFB648); // amber — CTA + highlights
  static const Color accentSoft = Color(0xFFFFD98E);

  static const Color good = Color(0xFF4ADE80); // on track
  static const Color warn = Color(0xFFFACC15); // monitor
  static const Color risk = Color(0xFFF87171); // at risk

  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textMuted = Color(0xFFB8B3D9);
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accentSoft,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.glassFill,
        thumbColor: AppColors.accentSoft,
        overlayColor: AppColors.accent.withOpacity(0.2),
        valueIndicatorColor: AppColors.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent.withOpacity(0.4)
              : AppColors.glassFill,
        ),
      ),
    );
  }
}

/// Full-bleed animated-feeling background gradient used behind everything.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

/// A frosted "glassmorphism" container: blurred, translucent, soft border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

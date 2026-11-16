import 'package:flutter/material.dart';

/// Design Tokens & Palette Santé UI/UX Pro Max pour MedMate (Afya-Health)
class AppColors {
  const AppColors._();

  // Couleurs Officielles Afya-Health (Charte validée)
  static const Color primary = Color(0xFF075B55); // Vert profond officiel
  static const Color primaryLight = Color(0xFF0A756D);
  static const Color primaryDark = Color(0xFF043834);
  static const Color primarySoft = Color(0xFFDDF2EF); // Vert clair officiel

  // Couleurs Secondaires (Bleu-vert officiel)
  static const Color secondary = Color(0xFF087E83); // Bleu-vert officiel
  static const Color secondaryLight = Color(0xFF149E9E);
  static const Color secondarySoft = Color(0xFFE2F4F4);

  // Couleurs Sémantiques & Alertes (Rouge réservé aux alertes et refus critiques)
  static const Color success = Color(0xFF075B55);
  static const Color successSoft = Color(0xFFDDF2EF);
  static const Color alert = Color(0xFFE11D48); // Rouge alerte officiel
  static const Color alertSoft = Color(0xFFFFE4E6);
  static const Color emergency = alert;
  static const Color emergencySoft = alertSoft;
  static const Color error = alert;
  static const Color errorSoft = alertSoft;
  static const Color warning = Color(0xFF087E83); // Info/conditionnel conforme
  static const Color warningSoft = Color(0xFFE2F4F4);

  // Surfaces & Fonds (Thème Clair Maquette Afya-Health)
  static const Color background = Color(0xFFF5F7F6); // Gris très clair officiel
  static const Color surface = Color(0xFFFFFFFF); // Blanc officiel
  static const Color surfaceVariant = Color(0xFFEDF3F1);
  static const Color border = Color(0xFFE0E7E5);
  static const Color borderSubtle = Color(0xFFEBF1EF);
  static const Color divider = Color(0xFFEAEFEB);

  // Typographie & Textes (Charte Afya-Health)
  static const Color textPrimary = Color(0xFF263238); // Gris foncé officiel
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textTertiary = Color(0xFF90A4AE);

  // Surfaces Thème Sombre (Étagées sans noir pur #000000)
  static const Color darkBackground = Color(0xFF09090B); // Zinc-950
  static const Color darkSurface = Color(0xFF18181B); // Zinc-900
  static const Color darkBorder = Color(0xFF27272A); // Zinc-800
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
}

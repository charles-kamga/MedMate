import 'package:flutter/material.dart';

/// Design Tokens & Palette Santé UI/UX Pro Max pour MedMate
class AppColors {
  const AppColors._();

  // Couleurs Officielles Afya Santé (Vert médical)
  static const Color primary = Color(0xFF16835D); // --green
  static const Color primaryLight = Color(0xFF26A674);
  static const Color primaryDark = Color(0xFF123B30); // --dark
  static const Color primarySoft = Color(0xFFEAF7F0); // --pale

  // Couleurs Secondaires & Cartographie (Bleu soignant)
  static const Color secondary = Color(0xFF0284C7); // Sky-600
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky-400
  static const Color secondarySoft = Color(0xFFE0F2FE); // Sky-100

  // Couleurs Sémantiques & Alertes (Rouge réservé aux alertes et refus critiques)
  static const Color success = Color(0xFF16835D);
  static const Color successSoft = Color(0xFFEAF7F0);
  static const Color alert = Color(0xFFE11D48); // Rouge alerte officiel
  static const Color alertSoft = Color(0xFFFFE4E6);
  static const Color emergency = alert;
  static const Color emergencySoft = alertSoft;
  static const Color error = alert;
  static const Color errorSoft = alertSoft;
  static const Color warning = Color(0xFF0284C7); // Info/conditionnel en bleu conforme
  static const Color warningSoft = Color(0xFFE0F2FE);

  // Surfaces & Fonds (Thème Clair Maquette)
  static const Color background = Color(0xFFF7FAF8); // --bg
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F7F3);
  static const Color border = Color(0xFFE4EEE7);
  static const Color borderSubtle = Color(0xFFDBE9E0);
  static const Color divider = Color(0xFFEDF2EE);

  // Typographie & Textes (Maquette)
  static const Color textPrimary = Color(0xFF123B30); // --dark
  static const Color textSecondary = Color(0xFF73827C); // --muted
  static const Color textTertiary = Color(0xFF9EABA5);

  // Surfaces Thème Sombre (Étagées sans noir pur #000000)
  static const Color darkBackground = Color(0xFF09090B); // Zinc-950
  static const Color darkSurface = Color(0xFF18181B); // Zinc-900
  static const Color darkBorder = Color(0xFF27272A); // Zinc-800
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
}

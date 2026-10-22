import 'package:flutter/material.dart';

/// Design Tokens & Palette Santé UI/UX Pro Max pour MedMate
class AppColors {
  const AppColors._();

  // Couleurs Primaires Médicales (Confiance & Sérénité)
  static const Color primary = Color(0xFF0D9488); // Teal-600
  static const Color primaryLight = Color(0xFF14B8A6); // Teal-500
  static const Color primaryDark = Color(0xFF0F766E); // Teal-700
  static const Color primarySoft = Color(0xFFCCFBF1); // Teal-100

  // Couleurs Secondaires (Cartographie & Actions)
  static const Color secondary = Color(0xFF0284C7); // Sky-600
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky-400
  static const Color secondarySoft = Color(0xFFE0F2FE); // Sky-100

  // Couleurs Sémantiques d'Urgence et de Disponibilité
  static const Color success = Color(0xFF059669); // Emerald-600 (Ouvert / En stock)
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706); // Amber-600 (Stock faible / Bientôt fermé)
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color emergency = Color(0xFFE11D48); // Rose-600 (Urgence vitale)
  static const Color emergencySoft = Color(0xFFFFE4E6);
  static const Color error = emergency; // Alias pour erreurs et indisponibilités
  static const Color errorSoft = emergencySoft;

  // Surfaces & Fonds (Thème Clair)
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color divider = Color(0xFFCBD5E1); // Slate-300

  // Typographie & Textes (Contraste WCAG 2.2 AA/AAA)
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900 (Contraste 14.8:1)
  static const Color textSecondary = Color(0xFF475569); // Slate-600 (Contraste 5.5:1)
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400

  // Surfaces Thème Sombre (Étagées sans noir pur #000000)
  static const Color darkBackground = Color(0xFF09090B); // Zinc-950
  static const Color darkSurface = Color(0xFF18181B); // Zinc-900
  static const Color darkBorder = Color(0xFF27272A); // Zinc-800
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
}

import 'package:flutter/material.dart';

/// Charte chromatique médicale Afya Santé conforme aux règles ONPC & Santé :
/// - Émeraude / Teal médical (#0D9488, #10B981)
/// - Bleu soignant (#0284C7)
/// - Ambre (#F59E0B) pour les gardes et alertes d'attention
/// - Zéro rouge vif anxiogène dans le branding et les indicateurs courants.
class AppColors {
  const AppColors._();

  // Couleurs Primaires (Teal & Émeraude médical)
  static const Color primary = Color(0xFF0D9488); // Teal-600
  static const Color primaryLight = Color(0xFF10B981); // Emerald-500
  static const Color primaryDark = Color(0xFF115E59); // Teal-800
  static const Color primarySoft = Color(0xFFCCFBF1); // Teal-100

  // Couleurs Secondaires (Bleu soignant & Cartographie)
  static const Color secondary = Color(0xFF0284C7); // Sky-600
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky-400
  static const Color secondarySoft = Color(0xFFE0F2FE); // Sky-100

  // Couleurs de Garde & Alertes (Ambre médical non anxiogène)
  static const Color dutyAmber = Color(0xFFF59E0B); // Amber-500
  static const Color dutyAmberDark = Color(0xFFB45309); // Amber-700
  static const Color dutyAmberSoft = Color(0xFFFEF3C7); // Amber-100

  // États Sémantiques
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successSoft = Color(0xFFD1FAE5); // Emerald-100
  static const Color warning = dutyAmber;
  static const Color warningSoft = dutyAmberSoft;
  static const Color error = Color(0xFFD97706); // Amber-600 (sobre, sans rouge vif)
  static const Color errorSoft = Color(0xFFFEF3C7);

  // Surfaces & Fonds (Thème Clair Haute Lisibilité)
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color borderSubtle = Color(0xFFCBD5E1); // Slate-300
  static const Color divider = Color(0xFFE2E8F0);

  // Typographie & Textes
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF475569); // Slate-600
  static const Color textTertiary = Color(0xFF64748B); // Slate-500
}

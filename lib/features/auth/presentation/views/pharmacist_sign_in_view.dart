import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/core/widgets/bento_card.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_cubit.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_state.dart';
import 'package:medmate/features/auth/presentation/views/authenticated_pharmacist_card.dart';

/// Vue d'authentification professionnelle pour les pharmaciens d'officine (ONPC Yaoundé).
class PharmacistSignInView extends StatefulWidget {
  const PharmacistSignInView({super.key});

  @override
  State<PharmacistSignInView> createState() => _PharmacistSignInViewState();
}

class _PharmacistSignInViewState extends State<PharmacistSignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signInPharmacist(
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        if (state is AuthenticatedPharmacist) {
          return AuthenticatedPharmacistCard(profile: state.pharmacist);
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: BentoCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      if (state is AuthError) ...[
                        _buildErrorBanner(state.message),
                        const SizedBox(height: 16),
                      ],
                      _buildEmailField(isLoading),
                      const SizedBox(height: 16),
                      _buildPasswordField(isLoading),
                      const SizedBox(height: 24),
                      _buildSubmitButton(isLoading),
                      const SizedBox(height: 20),
                      _buildReferenceHint(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() => const Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.local_pharmacy_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Espace Pro Pharmacien',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Connexion d’officine homologuée ONPC · Yaoundé',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );

  Widget _buildErrorBanner(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmailField(bool isLoading) => TextFormField(
        key: const Key('pharmacist_email_field'),
        controller: _emailController,
        enabled: !isLoading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Email professionnel ou ID ONPC',
          hintText: 'pharmacist@afya.cm',
          prefixIcon: Icon(Icons.badge_outlined, size: 20),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Veuillez saisir votre identifiant ou email'
            : null,
      );

  Widget _buildPasswordField(bool isLoading) => TextFormField(
        key: const Key('pharmacist_password_field'),
        controller: _passwordController,
        enabled: !isLoading,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Mot de passe sécurisé',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: IconButton(
            key: const Key('password_visibility_toggle'),
            iconSize: 22,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Veuillez saisir votre mot de passe' : null,
      );

  Widget _buildSubmitButton(bool isLoading) => SizedBox(
        height: 48,
        child: ElevatedButton(
          key: const Key('pharmacist_sign_in_button'),
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Se connecter au comptoir',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
        ),
      );

  Widget _buildReferenceHint() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Comptes de test : pharmacist@afya.cm / Afya2026!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}

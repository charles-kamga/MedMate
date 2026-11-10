import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import '../controllers/flash_reservation_cubit.dart';
import '../controllers/flash_reservation_state.dart';
import '../widgets/patient_basket_composer_card.dart';
import '../widgets/pharmacy_offers_comparison_list.dart';
import '../widgets/reservation_otp_ticket_card.dart';
import '../widgets/wave_dispatch_progress_card.dart';
import '../widgets/yango_pulse_flash_button.dart';

/// Vue principale responsive du parcours patient inversé « Style Yango » (< 320 lignes).
class PatientFlashFlowView extends StatelessWidget {
  const PatientFlashFlowView({
    super.key,
    this.flashCubit,
    this.catalogCubit,
    this.enablePulseAnimation = true,
  });

  final FlashReservationCubit? flashCubit;
  final MedicationCatalogCubit? catalogCubit;
  final bool enablePulseAnimation;

  FlashReservationCubit _resolveFlashCubit(BuildContext context) {
    if (flashCubit != null) return flashCubit!;
    return context.read<FlashReservationCubit>();
  }

  Widget _buildErrorBanner(String message, VoidCallback onDismiss) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.alertSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alert.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.alert),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.alert),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Comment fonctionne la recherche Flash ?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildIntroStep('1', 'Constituez votre panier', 'Ajoutez un ou plusieurs médicaments homologués.'),
          _buildIntroStep('2', 'Sélectionnez votre repère', 'Indiquez votre carrefour ou quartier à Yaoundé.'),
          _buildIntroStep('3', 'Diffusion par vagues', 'Afya Santé interroge 2 officines les plus proches toutes les 2 min.'),
          _buildIntroStep('4', 'Comparaison & Retrait OTP', 'Choisissez la meilleure offre et retirez avec le code à 6 chiffres.'),
        ],
      ),
    );
  }

  Widget _buildIntroStep(String step, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Text(step, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveFlashCubit(context);

    return BlocBuilder<FlashReservationCubit, FlashReservationState>(
      bloc: cubit,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return Container(
              color: AppColors.background,
              child: isDesktop
                  ? _buildDesktopLayout(context, cubit, state)
                  : _buildMobileLayout(context, cubit, state),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, FlashReservationCubit cubit, FlashReservationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.errorMessage != null)
            _buildErrorBanner(state.errorMessage!, () => cubit.refreshFlashRequest()),
          if (state.isConfirmed) ...[
            ReservationOtpTicketCard(cubit: cubit, reservation: state.confirmedReservation, order: state.currentOrder),
          ] else ...[
            PatientBasketComposerCard(
              flashCubit: cubit,
              catalogCubit: catalogCubit,
              basketItems: state.basketItems,
              selectedLandmark: state.selectedLandmark,
            ),
            const SizedBox(height: 14),
            YangoPulseFlashButton(
              itemCount: state.totalItemCount,
              landmark: state.selectedLandmark,
              isLoading: state.isLoading,
              enableAnimation: enablePulseAnimation,
              onPressed: state.canSubmit ? () => cubit.submitFlashRequest() : null,
            ),
            if (state.isWaveActive || state.hasActiveOrder) ...[
              const SizedBox(height: 16),
              WaveDispatchProgressCard(cubit: cubit, order: state.currentOrder, isLoading: state.isLoading),
            ],
            if (state.hasOffers) ...[
              const SizedBox(height: 16),
              PharmacyOffersComparisonList(
                cubit: cubit,
                offers: state.currentOrder?.offers,
                isLoading: state.isLoading,
              ),
            ],
            if (!state.hasActiveOrder && state.basketItems.isEmpty) ...[
              const SizedBox(height: 16),
              _buildIntroCard(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, FlashReservationCubit cubit, FlashReservationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.errorMessage != null)
            _buildErrorBanner(state.errorMessage!, () => cubit.refreshFlashRequest()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PatientBasketComposerCard(
                      flashCubit: cubit,
                      catalogCubit: catalogCubit,
                      basketItems: state.basketItems,
                      selectedLandmark: state.selectedLandmark,
                    ),
                    const SizedBox(height: 16),
                    YangoPulseFlashButton(
                      itemCount: state.totalItemCount,
                      landmark: state.selectedLandmark,
                      isLoading: state.isLoading,
                      enableAnimation: enablePulseAnimation,
                      onPressed: state.canSubmit ? () => cubit.submitFlashRequest() : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.isConfirmed) ...[
                      ReservationOtpTicketCard(cubit: cubit, reservation: state.confirmedReservation, order: state.currentOrder),
                    ] else if (state.hasOffers) ...[
                      WaveDispatchProgressCard(cubit: cubit, order: state.currentOrder, isLoading: state.isLoading),
                      const SizedBox(height: 16),
                      PharmacyOffersComparisonList(cubit: cubit, offers: state.currentOrder?.offers, isLoading: state.isLoading),
                    ] else if (state.isWaveActive || state.hasActiveOrder) ...[
                      WaveDispatchProgressCard(cubit: cubit, order: state.currentOrder, isLoading: state.isLoading),
                    ] else ...[
                      _buildIntroCard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

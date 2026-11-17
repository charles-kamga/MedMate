import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/flash_order.dart';
import '../cubit/flash_order_cubit.dart';

/// Étape 4 du wizard V2 : choix du mode de règlement et affichage du code OTP.
class WizardStep4Confirmation extends StatelessWidget {
  const WizardStep4Confirmation({
    required this.order,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.phoneNumber,
    super.key,
  });

  final FlashOrder order;
  final FlashPaymentMethod selectedPaymentMethod;
  final ValueChanged<FlashPaymentMethod> onPaymentMethodChanged;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final offer = order.selectedOffer;
    final isReady = order.status == FlashOrderStatus.readyForPickup ||
        order.status == FlashOrderStatus.delivered;

    if (!isReady) {
      return _buildPaymentSelection(
        context,
        offer?.pharmacyName,
        offer?.grandTotalCfa,
      );
    }

    final isDelivered =
        order.status == FlashOrderStatus.delivered || order.isPickedUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isDelivered ? AppColors.primary : AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isDelivered ? Icons.check_circle : Icons.qr_code_scanner_rounded,
            color: isDelivered ? Colors.white : AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isDelivered
              ? 'Médicaments retirés avec succès !'
              : 'Réservation confirmée !',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isDelivered
              ? 'Délivrance effectuée par ${offer?.pharmacyName ?? "la pharmacie"}.'
              : 'Présentez ce code unique au comptoir de ${offer?.pharmacyName ?? "la pharmacie"}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        BentoCard(
          backgroundColor: isDelivered ? AppColors.primarySoft : Colors.white,
          borderColor: isDelivered ? AppColors.primary : AppColors.border,
          child: Column(
            children: [
              const Text(
                'CODE DE RETRAIT UNIQUE (OTP)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  order.reservationOtpCode ?? 'RET-000000',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDelivered
                        ? 'Retrait validé au comptoir'
                        : 'Validité : ${AppConfig.otpValidityLabel} au comptoir',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        BentoCard(
          backgroundColor: Colors.white,
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Détails de la réservation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Divider(height: 20),
              _detailRow(
                'Pharmacie :',
                offer?.pharmacyName ?? '',
                isBold: true,
              ),
              const SizedBox(height: 8),
              _detailRow('Localisation :', offer?.quarter ?? ''),
              const SizedBox(height: 8),
              _detailRow('Téléphone :', offer?.phone ?? '', isPrimary: true),
              const SizedBox(height: 8),
              _detailRow(
                'Montant total :',
                '${offer?.grandTotalCfa ?? 0} FCFA',
                isBold: true,
                isPrimary: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              context.read<FlashOrderCubit>().resetOrder();
            },
            child: const Text(
              'Nouvelle recherche',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isPrimary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary && isBold ? 14 : 13,
            fontWeight: isBold || isPrimary ? FontWeight.w700 : FontWeight.w600,
            color: isPrimary ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelection(
    BuildContext context,
    String? pharmacyName,
    int? totalCfa,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Validation de votre réservation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Officine sélectionnée : ${pharmacyName ?? "Pharmacie"}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        BentoCard(
          backgroundColor: AppColors.primarySoft,
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Montant à régler',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Devis pharmacien validé',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                '${totalCfa ?? 0} FCFA',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mode de règlement :',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...FlashPaymentMethod.values.map((method) {
          final isSelected = selectedPaymentMethod == method;
          final (title, subtitle, icon) = switch (method) {
            FlashPaymentMethod.cashCounter => (
                'Paiement au comptoir (Espèces ou Mobile Money sur place)',
                'Réservation bloquée ${AppConfig.otpValidityShortLabel} avec code de retrait OTP officiel',
                Icons.storefront_rounded,
              ),
            FlashPaymentMethod.orangeMoney => (
                'Orange Money Cameroun (+237)',
                'Règlement direct in-app sécurisé',
                Icons.phone_android_rounded,
              ),
            FlashPaymentMethod.mtnMoMo => (
                'MTN Mobile Money (+237)',
                'Règlement direct in-app sécurisé',
                Icons.account_balance_wallet_rounded,
              ),
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            color: isSelected ? AppColors.primarySoft : Colors.white,
            child: ListTile(
              leading: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              onTap: () => onPaymentMethodChanged(method),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              context.read<FlashOrderCubit>().confirmPayment(
                    method: selectedPaymentMethod,
                    phoneNumber: phoneNumber,
                  );
            },
            child: const Text(
              'Confirmer la réservation & Obtenir le code OTP →',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/reservation.dart';

/// Bloc visuel encadrant le QR Code et le code OTP à 6 chiffres pour le retrait au comptoir
class ReservationQrCodeBox extends StatelessWidget {
  const ReservationQrCodeBox({
    required this.reservation,
    required this.onCopyOtp,
    super.key,
  });

  final Reservation reservation;
  final VoidCallback onCopyOtp;

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Text(
            'CODE DE RETRAIT AU COMPTOIR',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: QrImageView(
              key: const ValueKey('qr_code_otp_ticket'),
              data:
                  '{"otp":"${reservation.codeRetraitOtp}","reservationId":"${reservation.id}","pharmacyId":"${reservation.pharmacyId}"}',
              size: 100,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primaryDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  reservation.codeRetraitOtp,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'Copier le code OTP',
                onPressed: onCopyOtp,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Valable jusqu'à ${_formatTime(reservation.expiresAt)} (2 heures)",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

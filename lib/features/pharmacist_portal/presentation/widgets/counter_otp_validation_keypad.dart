import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/pharmacist_counter_cubit.dart';
import '../controllers/pharmacist_counter_state.dart';

/// Pavé tactile rapide de saisie et validation du code OTP au comptoir (< 400 lignes).
class CounterOtpValidationKeypad extends StatefulWidget {
  const CounterOtpValidationKeypad({
    required this.orderId,
    required this.pharmacyId,
    super.key,
    this.onSuccess,
    this.isCompact = false,
  });

  final String orderId;
  final String pharmacyId;
  final VoidCallback? onSuccess;
  final bool isCompact;

  static const Color emerald = Color(0xFF10B981);

  @override
  State<CounterOtpValidationKeypad> createState() => _CounterOtpValidationKeypadState();
}

class _CounterOtpValidationKeypadState extends State<CounterOtpValidationKeypad> {
  String _otp = '';

  void _onDigit(String d) {
    if (_otp.length < 6) {
      setState(() => _otp += d);
    }
  }

  void _onBackspace() {
    if (_otp.isNotEmpty) {
      setState(() => _otp = _otp.substring(0, _otp.length - 1));
    }
  }

  void _onClear() {
    if (_otp.isNotEmpty) {
      setState(() => _otp = '');
    }
  }

  void _submit() {
    if (_otp.length == 6) {
      context.read<PharmacistCounterCubit>().validateOtpAtCounter(
            orderId: widget.orderId,
            pharmacyId: widget.pharmacyId,
            otpCode: _otp,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PharmacistCounterCubit, PharmacistCounterState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.isOtpSuccess) {
          widget.onSuccess?.call();
        }
      },
      builder: (context, state) {
        final isLoading = state.isValidatingOtp;
        final isSuccess = state.isOtpSuccess &&
            (state.lastValidatedOrder == null ||
                state.lastValidatedOrder?.id == widget.orderId);
        final hasError = state.isFailure && state.errorMessage != null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildOtpDisplay(),
              const SizedBox(height: 14),
              if (isSuccess) ...[
                _buildSuccessBanner(state.successMessage ?? 'Retrait validé avec succès !'),
                const SizedBox(height: 12),
              ] else if (hasError) ...[
                _buildErrorBanner(state.errorMessage!),
                const SizedBox(height: 12),
              ],
              _buildKeypadGrid(isLoading || isSuccess),
              const SizedBox(height: 14),
              _buildValidateButton(isLoading, isSuccess),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.dialpad_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation Retrait OTP — #${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const Text(
              'Saisir les 6 chiffres présentés par le patient',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final hasChar = index < _otp.length;
        final isCurrent = index == _otp.length;
        final char = hasChar ? _otp[index] : '';

        return Container(
          key: ValueKey('otp_box_$index'),
          width: widget.isCompact ? 38 : 44,
          height: widget.isCompact ? 46 : 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: hasChar ? const Color(0xFFEAF7F0) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasChar
                  ? CounterOtpValidationKeypad.emerald
                  : (isCurrent ? AppColors.secondary : AppColors.border),
              width: hasChar || isCurrent ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            char.isNotEmpty ? char : '•',
            style: TextStyle(
              fontSize: hasChar ? 22 : 16,
              fontWeight: FontWeight.w900,
              color: hasChar ? AppColors.primaryDark : AppColors.textTertiary,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuccessBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CounterOtpValidationKeypad.emerald),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: CounterOtpValidationKeypad.emerald, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.alert.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: AppColors.alert,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadGrid(bool disabled) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildKeyButton(key, disabled),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton(String key, bool disabled) {
    final isClear = key == 'C';
    final isBack = key == '⌫';
    final isSpecial = isClear || isBack;

    return SizedBox(
      width: widget.isCompact ? 60 : 68,
      height: widget.isCompact ? 46 : 52,
      child: Material(
        color: isSpecial ? AppColors.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled
              ? null
              : () {
                  if (isClear) {
                    _onClear();
                  } else if (isBack) {
                    _onBackspace();
                  } else {
                    _onDigit(key);
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: isBack
                ? const Icon(Icons.backspace_outlined, size: 18, color: AppColors.textPrimary)
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isClear ? AppColors.alert : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidateButton(bool isLoading, bool isSuccess) {
    final canSubmit = _otp.length == 6 && !isLoading && !isSuccess;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
        key: const ValueKey('btn_confirm_counter_otp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: CounterOtpValidationKeypad.emerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: canSubmit ? _submit : null,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.verified_rounded, size: 18),
        label: Text(
          isSuccess ? 'Retrait validé au comptoir' : 'Confirmer le retrait au comptoir',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    ),
  );
}
}

import 'package:flutter/material.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';

/// Bouton d'action principal « Style Yango » avec animation de halo/pulsation
/// en Teal/Émeraude médical (#0D9488 / #10B981) et cible tactile >= 56px.
class YangoPulseFlashButton extends StatefulWidget {
  const YangoPulseFlashButton({
    required this.itemCount,
    required this.landmark,
    required this.onPressed,
    this.isLoading = false,
    this.enableAnimation = true,
    this.label = 'Lancer la recherche Flash',
    super.key,
  });

  final int itemCount;
  final YaoundeLandmark? landmark;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enableAnimation;
  final String label;

  bool get isActionable =>
      onPressed != null && !isLoading && itemCount > 0 && landmark != null;

  @override
  State<YangoPulseFlashButton> createState() => _YangoPulseFlashButtonState();
}

class _YangoPulseFlashButtonState extends State<YangoPulseFlashButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.enableAnimation && widget.isActionable) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant YangoPulseFlashButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation && widget.isActionable) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _buildSubtitle() {
    if (widget.itemCount <= 0) return 'Ajoutez au moins 1 médicament au panier';
    if (widget.landmark == null) return 'Sélectionnez un carrefour ou quartier';
    final s = widget.itemCount > 1 ? 's' : '';
    return '${widget.itemCount} médicament$s • ${widget.landmark!.nom}';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isActionable;
    final tickerEnabled = TickerMode.of(context);
    if (!tickerEnabled && _controller.isAnimating) _controller.stop();

    final buttonContent = Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: enabled ? null : AppColors.borderSubtle,
      ),
      child: widget.isLoading
          ? const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.white.withValues(alpha: 0.2) : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: enabled ? Colors.white : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: enabled ? Colors.white : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled ? Colors.white.withValues(alpha: 0.9) : AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: enabled ? Colors.white : AppColors.textTertiary, size: 20),
              ],
            ),
    );

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = (enabled && widget.enableAnimation && tickerEnabled) ? _pulseAnimation.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25 + (0.25 * pulseValue)),
                      blurRadius: 12 + (10 * pulseValue),
                      spreadRadius: 1 + (3 * pulseValue),
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(18),
              child: child,
            ),
          ),
        );
      },
      child: buttonContent,
    );
  }
}

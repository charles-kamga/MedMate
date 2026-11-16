import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../data/repositories/pharmacist_portal_repository_impl.dart';
import '../../domain/usecases/get_pending_counter_orders.dart';
import '../../domain/usecases/submit_counter_quote.dart';
import '../../domain/usecases/validate_counter_otp.dart';
import '../controllers/pharmacist_counter_cubit.dart';
import '../controllers/pharmacist_counter_state.dart';
import '../widgets/counter_otp_validation_keypad.dart';
import '../widgets/pharmacist_portal_top_bar.dart';
import '../widgets/pharmacist_quote_reply_sheet.dart';
import '../widgets/pharmacist_request_inbox_card.dart';
import '../widgets/pharmacist_urgent_alert_banner.dart';

/// Vue principale responsive du portail comptoir pharmacien (< 400 lignes).
class PharmacistPortalView extends StatelessWidget {
  const PharmacistPortalView({
    super.key,
    this.initialPharmacyId = 'pharma-soleil',
    this.enableAlertCycle = true,
    this.onPlayAlertSound,
  });

  final String initialPharmacyId;
  final bool enableAlertCycle;
  final VoidCallback? onPlayAlertSound;

  @override
  Widget build(BuildContext context) {
    try {
      BlocProvider.of<PharmacistCounterCubit>(context);
      return _PharmacistPortalViewContent(initialPharmacyId: initialPharmacyId, enableAlertCycle: enableAlertCycle, onPlayAlertSound: onPlayAlertSound);
    } catch (_) {
      final repo = PharmacistPortalRepositoryImpl();
      return BlocProvider<PharmacistCounterCubit>(
        create: (_) => PharmacistCounterCubit(
          getPendingOrders: GetPendingCounterOrdersUseCase(repo),
          submitQuoteUseCase: SubmitCounterQuoteUseCase(repo),
          validateOtpUseCase: ValidateCounterOtpUseCase(repo),
        )..loadPendingOrders(initialPharmacyId),
        child: _PharmacistPortalViewContent(initialPharmacyId: initialPharmacyId, enableAlertCycle: enableAlertCycle, onPlayAlertSound: onPlayAlertSound),
      );
    }
  }
}

class _PharmacistPortalViewContent extends StatefulWidget {
  const _PharmacistPortalViewContent({
    required this.initialPharmacyId,
    required this.enableAlertCycle,
    this.onPlayAlertSound,
  });

  final String initialPharmacyId;
  final bool enableAlertCycle;
  final VoidCallback? onPlayAlertSound;

  @override
  State<_PharmacistPortalViewContent> createState() =>
      _PharmacistPortalViewContentState();
}

class _PharmacistPortalViewContentState
    extends State<_PharmacistPortalViewContent>
    with SingleTickerProviderStateMixin {
  late String _activePharmacyId;
  TabController? _tabController;
  Timer? _alertTimer;
  int _alertCycleCount = 0;
  bool _isUrgentAlertActive = false;
  final Set<String> _acknowledgedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _activePharmacyId = widget.initialPharmacyId;
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<PharmacistCounterCubit>();
      if (cubit.state.isInitial) {
        cubit.loadPendingOrders(_activePharmacyId);
      } else {
        _checkUrgentOrders(cubit.state);
      }
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _alertTimer = null;
    _tabController?.dispose();
    super.dispose();
  }

  void _checkUrgentOrders(PharmacistCounterState state) {
    final hasUnack = state.orders.any(
      (o) =>
          o.status == FlashOrderStatus.dispatchingWave &&
          !_acknowledgedOrderIds.contains(o.id),
    );
    if (hasUnack && !_isUrgentAlertActive) {
      _triggerUrgentAlert();
    } else if (!hasUnack && _isUrgentAlertActive) {
      _stopUrgentAlert();
    }
  }

  void _playAlert() {
    if (widget.onPlayAlertSound != null) {
      widget.onPlayAlertSound!();
    } else {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _triggerUrgentAlert() {
    _alertTimer?.cancel();
    setState(() {
      _isUrgentAlertActive = true;
      _alertCycleCount = 0;
    });
    _playAlert();
    if (widget.enableAlertCycle) {
      _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _alertCycleCount++;
        if (_alertCycleCount >= 4) {
          timer.cancel();
          _alertTimer = null;
        } else {
          _playAlert();
        }
      });
    }
  }

  void _stopUrgentAlert() {
    _alertTimer?.cancel();
    _alertTimer = null;
    if (_isUrgentAlertActive) {
      setState(() => _isUrgentAlertActive = false);
    }
  }

  void _acknowledgeAlert(List<FlashOrder> orders) {
    for (final o in orders) {
      if (o.status == FlashOrderStatus.dispatchingWave) {
        _acknowledgedOrderIds.add(o.id);
      }
    }
    _stopUrgentAlert();
  }

  void _onPharmacyChanged(String? newId) {
    if (newId != null && newId != _activePharmacyId) {
      setState(() => _activePharmacyId = newId);
      context.read<PharmacistCounterCubit>().loadPendingOrders(newId);
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PharmacistCounterCubit, PharmacistCounterState>(
      listener: (context, state) {
        _checkUrgentOrders(state);

        if (state.isFailure && state.errorMessage != null) {
          _showSnackBar(context, state.errorMessage!, AppColors.alert);
        } else if (state.isQuoteSubmitted && state.successMessage != null) {
          _showSnackBar(context, state.successMessage!, const Color(0xFF10B981));
        } else if (state.isOtpSuccess && state.successMessage != null) {
          _showSnackBar(context, state.successMessage!, const Color(0xFF10B981));
        }
      },
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return Scaffold(
              backgroundColor: AppColors.background,
              body: isDesktop ? _buildSplitDesktop(state) : _buildMobileTabs(state),
            );
          },
        );
      },
    );
  }

  Widget _buildSplitDesktop(PharmacistCounterState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 420,
          child: Column(
            children: [
              _buildTopBar(state),
              Expanded(child: _buildInboxList(state, isDesktop: true)),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: _buildActionPanel(state.selectedOrder),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabs(PharmacistCounterState state) {
    return Column(
      children: [
        _buildTopBar(state),
        ColoredBox(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: const Icon(Icons.inbox_rounded, size: 18), text: 'Demandes (${state.filteredOrders.length})'),
              const Tab(icon: Icon(Icons.touch_app_rounded, size: 18), text: 'Traitement & Retrait'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInboxList(state, isDesktop: false),
              _buildActionPanel(state.selectedOrder),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(PharmacistCounterState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PharmacistPortalTopBar(
          activePharmacyId: _activePharmacyId,
          onPharmacyChanged: _onPharmacyChanged,
          onRefresh: () => context
              .read<PharmacistCounterCubit>()
              .loadPendingOrders(_activePharmacyId),
          onFilterChanged: (status) =>
              context.read<PharmacistCounterCubit>().setFilterStatus(status),
          state: state,
        ),
        if (_isUrgentAlertActive)
          PharmacistUrgentAlertBanner(
            onAcknowledge: () => _acknowledgeAlert(state.orders),
          ),
      ],
    );
  }

  Widget _buildInboxList(PharmacistCounterState state, {required bool isDesktop}) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = state.filteredOrders;
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: AppColors.textTertiary),
              SizedBox(height: 8),
              Text(
                'Aucune demande dans cette file.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = list[index];
        final isSelected = state.selectedOrder?.id == order.id;

        return PharmacistRequestInboxCard(
          order: order,
          isSelected: isSelected,
          currentPharmacyId: _activePharmacyId,
          onSelect: () {
            context.read<PharmacistCounterCubit>().selectOrder(order);
            if (!isDesktop) _tabController?.animateTo(1);
          },
          onQuotePressed: () {
            context.read<PharmacistCounterCubit>().selectOrder(order);
            if (!isDesktop) _tabController?.animateTo(1);
          },
          onValidateOtpPressed: () {
            context.read<PharmacistCounterCubit>().selectOrder(order);
            if (!isDesktop) _tabController?.animateTo(1);
          },
        );
      },
    );
  }

  Widget _buildActionPanel(FlashOrder? order) {
    if (order == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 48, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text('Sélectionnez une commande dans la file', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('Vous pourrez émettre votre offre chiffrée ou valider le retrait OTP.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (order.status == FlashOrderStatus.cancelled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_outlined, size: 48, color: AppColors.alert),
              SizedBox(height: 12),
              Text('Cette commande a été annulée par le patient.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.alert)),
            ],
          ),
        ),
      );
    }

    final isReadyOrAccepted = order.status == FlashOrderStatus.readyForPickup ||
        order.status == FlashOrderStatus.accepted;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (isReadyOrAccepted)
            CounterOtpValidationKeypad(
              orderId: order.id,
              pharmacyId: _activePharmacyId,
            )
          else
            PharmacistQuoteReplySheet(
              order: order,
              pharmacyId: _activePharmacyId,
              isEmbedded: true,
            ),
        ],
      ),
    );
  }
}

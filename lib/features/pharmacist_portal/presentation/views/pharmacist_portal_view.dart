import 'package:flutter/material.dart';
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
import '../widgets/pharmacist_quote_reply_sheet.dart';
import '../widgets/pharmacist_request_inbox_card.dart';

/// Vue principale responsive du portail comptoir pharmacien (< 400 lignes).
class PharmacistPortalView extends StatelessWidget {
  const PharmacistPortalView({
    super.key,
    this.initialPharmacyId = 'pharma-soleil',
  });

  final String initialPharmacyId;

  @override
  Widget build(BuildContext context) {
    try {
      BlocProvider.of<PharmacistCounterCubit>(context);
      return _PharmacistPortalViewContent(initialPharmacyId: initialPharmacyId);
    } catch (_) {
      final repo = PharmacistPortalRepositoryImpl();
      return BlocProvider<PharmacistCounterCubit>(
        create: (_) => PharmacistCounterCubit(
          getPendingOrders: GetPendingCounterOrdersUseCase(repo),
          submitQuoteUseCase: SubmitCounterQuoteUseCase(repo),
          validateOtpUseCase: ValidateCounterOtpUseCase(repo),
        )..loadPendingOrders(initialPharmacyId),
        child: _PharmacistPortalViewContent(initialPharmacyId: initialPharmacyId),
      );
    }
  }
}

class _PharmacistPortalViewContent extends StatefulWidget {
  const _PharmacistPortalViewContent({required this.initialPharmacyId});
  final String initialPharmacyId;

  @override
  State<_PharmacistPortalViewContent> createState() => _PharmacistPortalViewContentState();
}

class _PharmacistPortalViewContentState extends State<_PharmacistPortalViewContent>
    with SingleTickerProviderStateMixin {
  late String _activePharmacyId;
  TabController? _tabController;

  static const List<Map<String, String>> _demoPharmacies = [
    {'id': 'pharma-soleil', 'name': 'Pharmacie du Soleil', 'quarter': 'Carrefour Warda'},
    {'id': 'pharma-centre', 'name': 'Grande Pharmacie du Centre', 'quarter': 'Poste Centrale'},
    {'id': 'pharma-obili', 'name': "Pharmacie d'Obili", 'quarter': 'Carrefour Obili'},
  ];

  @override
  void initState() {
    super.initState();
    _activePharmacyId = widget.initialPharmacyId;
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PharmacistCounterCubit>();
      if (cubit.state.isInitial) {
        cubit.loadPendingOrders(_activePharmacyId);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onPharmacyChanged(String? newId) {
    if (newId != null && newId != _activePharmacyId) {
      setState(() => _activePharmacyId = newId);
      context.read<PharmacistCounterCubit>().loadPendingOrders(newId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PharmacistCounterCubit, PharmacistCounterState>(
      listener: (context, state) {
        if (state.isFailure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.alert,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.isQuoteSubmitted && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.isOtpSuccess && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
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
              Tab(
                icon: const Icon(Icons.inbox_rounded, size: 18),
                text: 'Demandes (${state.filteredOrders.length})',
              ),
              const Tab(
                icon: Icon(Icons.touch_app_rounded, size: 18),
                text: 'Traitement & Retrait',
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _activePharmacyId,
                    isExpanded: true,
                    items: _demoPharmacies.map((p) {
                      return DropdownMenuItem(
                        value: p['id'],
                        child: Text(
                          '${p['name']} (${p['quarter']})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onPharmacyChanged,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                tooltip: 'Actualiser la file',
                onPressed: () => context.read<PharmacistCounterCubit>().loadPendingOrders(_activePharmacyId),
              ),
            ],
          ),
          _buildFilterChips(state),
        ],
      ),
    );
  }

  Widget _buildFilterChips(PharmacistCounterState state) {
    final filters = [
      {'label': 'Toutes', 'status': null},
      {'label': 'Vague active', 'status': 'dispatchingWave'},
      {'label': 'À retirer', 'status': 'readyForPickup'},
      {'label': 'Délivrées', 'status': 'delivered'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSel = state.filterStatus == f['status'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(f['label']!, style: const TextStyle(fontSize: 11)),
              selected: isSel,
              selectedColor: AppColors.primarySoft,
              labelStyle: TextStyle(
                color: isSel ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
              ),
              onSelected: (_) => context.read<PharmacistCounterCubit>().setFilterStatus(f['status']),
            ),
          );
        }).toList(),
      ),
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
              Text(
                'Sélectionnez une commande dans la file',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'Vous pourrez émettre votre offre chiffrée ou valider le retrait OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
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

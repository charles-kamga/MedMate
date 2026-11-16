import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/basket_item.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../../pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import '../../../pharmacy_search/presentation/controllers/medication_catalog_state.dart';
import '../controllers/flash_reservation_cubit.dart';
import 'patient_basket_item_tile.dart';

/// Carte de composition du panier multi-médicaments et choix du quartier à Yaoundé (< 300 lignes).
class PatientBasketComposerCard extends StatefulWidget {
  const PatientBasketComposerCard({
    super.key,
    this.basketItems,
    this.selectedLandmark,
    this.onAddMedication,
    this.onRemoveItem,
    this.onUpdateQuantity,
    this.onSelectLandmark,
    this.catalogCubit,
    this.flashCubit,
  });

  final List<BasketItem>? basketItems;
  final YaoundeLandmark? selectedLandmark;
  final ValueChanged<Medication>? onAddMedication;
  final ValueChanged<String>? onRemoveItem;
  final void Function(String itemId, int newQuantity)? onUpdateQuantity;
  final ValueChanged<YaoundeLandmark>? onSelectLandmark;
  final MedicationCatalogCubit? catalogCubit;
  final FlashReservationCubit? flashCubit;

  @override
  State<PatientBasketComposerCard> createState() =>
      _PatientBasketComposerCardState();
}

class _PatientBasketComposerCardState extends State<PatientBasketComposerCard> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _requiresPrescription = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  FlashReservationCubit? _flashCubit(BuildContext c) {
    if (widget.flashCubit != null) return widget.flashCubit;
    try {
      return c.read<FlashReservationCubit>();
    } catch (_) {
      return null;
    }
  }

  MedicationCatalogCubit? _catalogCubit(BuildContext c) {
    if (widget.catalogCubit != null) return widget.catalogCubit;
    try {
      return c.read<MedicationCatalogCubit>();
    } catch (_) {
      return null;
    }
  }

  void _addMed(Medication m, BuildContext c) {
    widget.onAddMedication != null ? widget.onAddMedication!(m) : _flashCubit(c)?.addItem(m);
    _searchController.clear();
    _searchFocusNode.unfocus();
    _catalogCubit(c)?.clear();
    setState(() => _requiresPrescription = false);
  }

  void _addCustomMedication(BuildContext c) {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    final m = Medication(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      dci: text,
      nomCommercial: text,
      forme: 'Saisie libre',
      dosage: 'Demande libre',
      classeTherapeutique: 'Demande patient',
      prixHomologueCfa: 0,
      necessiteOrdonnance: _requiresPrescription,
    );
    _addMed(m, c);
  }

  void _remove(String id, BuildContext c) {
    widget.onRemoveItem != null ? widget.onRemoveItem!(id) : _flashCubit(c)?.removeItem(id);
    setState(() {});
  }

  void _updateQty(String id, int q, BuildContext c) {
    widget.onUpdateQuantity != null ? widget.onUpdateQuantity!(id, q) : _flashCubit(c)?.updateQuantity(id, q);
    setState(() {});
  }

  void _onLandmark(YaoundeLandmark? lm, BuildContext c) {
    if (lm == null) return;
    widget.onSelectLandmark != null ? widget.onSelectLandmark!(lm) : _flashCubit(c)?.selectLandmark(lm);
    setState(() {});
  }

  Widget _buildCustomMedicationTile(BuildContext context, String query) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _requiresPrescription = !_requiresPrescription),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _requiresPrescription,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _requiresPrescription = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ordonnance à présenter au comptoir',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            key: const ValueKey('btn_add_custom_medication'),
            onPressed: () => _addCustomMedication(context),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'Ajouter « $query » à ma demande',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(MedicationCatalogCubit? cubit) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    if (cubit == null) {
      return _buildCustomMedicationTile(context, query);
    }

    return BlocBuilder<MedicationCatalogCubit, MedicationCatalogState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final hasMatches =
            state is MedicationCatalogLoaded && state.medications.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasMatches)
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: state.medications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.borderSubtle),
                    itemBuilder: (context, index) {
                      final med = state.medications[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.medication_outlined,
                            color: AppColors.primary, size: 20,),
                        title: Text(med.nomCommercial,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13,),),
                        subtitle: Text(
                            '${med.dci} • ${med.forme} (${med.dosage})',
                            style: const TextStyle(fontSize: 11),),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary, size: 20,),
                        onTap: () => _addMed(med, context),
                      );
                    },
                  ),
                ),
              )
            else if (state is MedicationCatalogLoaded)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text('Aucun médicament homologué trouvé.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),),
              ),
            _buildCustomMedicationTile(context, query),
          ],
        );
      },
    );
  }

  Widget _buildItem(BasketItem item, BuildContext context) {
    return PatientBasketItemTile(
      item: item,
      onIncrement: () => _updateQty(item.id, item.quantity + 1, context),
      onDecrement: () => _updateQty(item.id, item.quantity - 1, context),
      onRemove: () => _remove(item.id, context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fc = _flashCubit(context);
    final cc = _catalogCubit(context);
    final items = widget.basketItems ?? fc?.state.basketItems ?? const <BasketItem>[];
    final landmark = widget.selectedLandmark ?? fc?.state.selectedLandmark;
    final b = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<YaoundeLandmark>(
            initialValue: landmark,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Carrefour ou quartier repère',
              hintText: 'Choisir votre position à Yaoundé',
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: b,
              enabledBorder: b,
            ),
            items: YaoundeLandmarks.list
                .map(
                  (lm) => DropdownMenuItem<YaoundeLandmark>(
                    value: lm,
                    child: Text(
                      '${lm.nom} (${lm.quartier})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: (lm) => _onLandmark(lm, context),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              labelText: 'Rechercher un médicament homologué',
              hintText: 'Ex: Paracétamol, Amoxicilline...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        cc?.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: b,
              enabledBorder: b,
            ),
            onChanged: (q) {
              cc?.search(q);
              setState(() {});
            },
          ),
          _buildSearchResults(cc),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Médicaments demandés (${items.length})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.fold<int>(0, (s, i) => s + i.quantity)} unité(s)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                "Votre panier est vide. Recherchez un médicament pour l'ajouter.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            ...items.map((item) => _buildItem(item, context)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConfig.pricePolicyNotice,
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primaryDark, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/basket_item.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../../pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import '../controllers/flash_reservation_cubit.dart';
import 'patient_basket_item_tile.dart';
import 'patient_basket_policy_notice.dart';
import 'patient_basket_search_results.dart';

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
    widget.onAddMedication != null
        ? widget.onAddMedication!(m)
        : _flashCubit(c)?.addItem(m);
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
    widget.onRemoveItem != null
        ? widget.onRemoveItem!(id)
        : _flashCubit(c)?.removeItem(id);
    setState(() {});
  }

  void _updateQty(String id, int q, BuildContext c) {
    widget.onUpdateQuantity != null
        ? widget.onUpdateQuantity!(id, q)
        : _flashCubit(c)?.updateQuantity(id, q);
    setState(() {});
  }

  void _onLandmark(YaoundeLandmark? lm, BuildContext c) {
    if (lm == null) return;
    widget.onSelectLandmark != null
        ? widget.onSelectLandmark!(lm)
        : _flashCubit(c)?.selectLandmark(lm);
    setState(() {});
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
    final items =
        widget.basketItems ?? fc?.state.basketItems ?? const <BasketItem>[];
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
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.primary),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: b,
              enabledBorder: b,
            ),
            onChanged: (q) {
              cc?.search(q);
              setState(() {});
            },
          ),
          PatientBasketSearchResults(
            query: _searchController.text,
            catalogCubit: cc,
            requiresPrescription: _requiresPrescription,
            onTogglePrescription: () => setState(
              () => _requiresPrescription = !_requiresPrescription,
            ),
            onAddCatalogMedication: (med) => _addMed(med, context),
            onAddCustomMedication: () => _addCustomMedication(context),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Médicaments demandés (${items.length})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.fold<int>(0, (s, i) => s + i.quantity)} unité(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Votre panier est vide. Recherchez un médicament pour l'ajouter.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            ...items.map((item) => _buildItem(item, context)),
          const SizedBox(height: 14),
          const PatientBasketPolicyNotice(),
        ],
      ),
    );
  }
}

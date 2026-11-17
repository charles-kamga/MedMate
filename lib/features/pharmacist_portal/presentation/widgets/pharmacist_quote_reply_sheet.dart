import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../controllers/pharmacist_counter_cubit.dart';
import 'pharmacist_quote_delivery_box.dart';
import 'pharmacist_quote_header_and_tabs.dart';

/// Formulaire ergonomique de devis officine (< 400 lignes).
class PharmacistQuoteReplySheet extends StatefulWidget {
  const PharmacistQuoteReplySheet({
    required this.order,
    required this.pharmacyId,
    super.key,
    this.onQuoteSubmitted,
    this.isEmbedded = false,
    this.enableDeliveryOption = AppConfig.enableDeliveryInV1,
  });

  final FlashOrder order;
  final String pharmacyId;
  final VoidCallback? onQuoteSubmitted;
  final bool isEmbedded;
  final bool enableDeliveryOption;
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);

  @override
  State<PharmacistQuoteReplySheet> createState() =>
      _PharmacistQuoteReplySheetState();
}

class _PharmacistQuoteReplySheetState extends State<PharmacistQuoteReplySheet> {
  late PharmacyAvailabilityType _availability;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _minsCtrl;
  bool _reqPrescription = true;
  bool _dciSub = false;
  bool _reqMajority = false;
  bool _delivery = false;
  String _unavReason = 'Rupture de stock temporaire';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final ex = widget.order.offers.cast<PharmacyOffer?>().firstWhere(
          (o) => o?.pharmacyId == widget.pharmacyId,
          orElse: () => null,
        );
    _availability =
        ex?.availabilityType ?? PharmacyAvailabilityType.fullyAvailable;
    _priceCtrl = TextEditingController(
      text: ex != null && ex.quotedPriceCfa > 0 ? '${ex.quotedPriceCfa}' : '',
    );
    _noteCtrl = TextEditingController(text: ex?.conditionNote ?? '');
    _delivery = ex?.proposesDelivery ?? false;
    _feeCtrl = TextEditingController(text: '${ex?.deliveryFeeCfa ?? 1000}');
    _minsCtrl =
        TextEditingController(text: '${ex?.estimatedDeliveryMinutes ?? 30}');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _feeCtrl.dispose();
    _minsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_availability != PharmacyAvailabilityType.unavailable &&
        !_formKey.currentState!.validate()) {
      return;
    }
    final price = _availability == PharmacyAvailabilityType.unavailable
        ? 0
        : (int.tryParse(_priceCtrl.text.trim()) ?? 0);
    final conditions = <String>[];
    if (_availability == PharmacyAvailabilityType.conditional ||
        _availability == PharmacyAvailabilityType.partiallyAvailable) {
      if (_reqPrescription) conditions.add('Ordonnance originale requise');
      if (_dciSub) {
        conditions
            .add('Substitution équivalente DCI homologuée / dosage alternatif');
      }
      if (_reqMajority) conditions.add("Pièce d'identité / Majorité requise");
    }
    final note = _availability == PharmacyAvailabilityType.unavailable
        ? _unavReason
        : (_noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null);

    final deliveryActive = widget.enableDeliveryOption && _delivery;

    context.read<PharmacistCounterCubit>().submitQuote(
          orderId: widget.order.id,
          pharmacyId: widget.pharmacyId,
          availability: _availability,
          quotedPriceCfa: price,
          conditionRequirements: conditions,
          conditionNote: note,
          proposesDelivery: deliveryActive,
          deliveryFeeCfa:
              deliveryActive ? (int.tryParse(_feeCtrl.text) ?? 1000) : 0,
          estimatedDeliveryMinutes:
              deliveryActive ? (int.tryParse(_minsCtrl.text) ?? 30) : null,
        );
    widget.onQuoteSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final body = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PharmacistQuoteHeaderAndTabs(
            order: widget.order,
            selectedAvailability: _availability,
            onAvailabilityChanged: (type) =>
                setState(() => _availability = type),
          ),
          const SizedBox(height: 12),
          if (_availability == PharmacyAvailabilityType.conditional ||
              _availability == PharmacyAvailabilityType.partiallyAvailable)
            _buildConditionalBox(),
          if (_availability == PharmacyAvailabilityType.unavailable)
            _buildUnavailableBox(),
          if (_availability != PharmacyAvailabilityType.unavailable) ...[
            _buildPriceField(),
            const SizedBox(height: 12),
            PharmacistQuoteDeliveryBox(
              enableDeliveryOption: widget.enableDeliveryOption,
              deliveryEnabled: _delivery,
              feeController: _feeCtrl,
              minsController: _minsCtrl,
              onDeliveryChanged: (v) => setState(() => _delivery = v),
            ),
          ],
          const SizedBox(height: 16),
          _buildSubmitButton(),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: body,
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(child: body),
    );
  }

  Widget _buildConditionalBox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: PharmacistQuoteReplySheet.amber.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conditions exigées :',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: PharmacistQuoteReplySheet.amber,
                title: const Text(
                  'Ordonnance originale requise',
                  style: TextStyle(fontSize: 11),
                ),
                value: _reqPrescription,
                onChanged: (v) => setState(() => _reqPrescription = v ?? false),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: PharmacistQuoteReplySheet.amber,
                title: const Text(
                  'Substitution DCI homologuée / dosage alternatif',
                  style: TextStyle(fontSize: 11),
                ),
                value: _dciSub,
                onChanged: (v) => setState(() => _dciSub = v ?? false),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: PharmacistQuoteReplySheet.amber,
                title: const Text(
                  "Pièce d'identité / Majorité requise",
                  style: TextStyle(fontSize: 11),
                ),
                value: _reqMajority,
                onChanged: (v) => setState(() => _reqMajority = v ?? false),
              ),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Note explicative pour le patient',
                  labelStyle: const TextStyle(fontSize: 11),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _unavReason,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Motif d'indisponibilité (prix fixé à 0 FCFA)",
          labelStyle: const TextStyle(fontSize: 11),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Rupture de stock temporaire',
            child: Text(
              'Rupture de stock temporaire',
              style: TextStyle(fontSize: 12),
            ),
          ),
          DropdownMenuItem(
            value: 'Produit déréférencé / non disponible',
            child: Text(
              'Produit déréférencé / non disponible',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
        onChanged: (v) => setState(() => _unavReason = v ?? _unavReason),
      ),
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prix total proposé au comptoir (FCFA)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: const ValueKey('input_quoted_price'),
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Veuillez saisir un montant';
            }
            final n = int.tryParse(v.trim());
            return (n == null || n <= 0) ? 'Montant invalide' : null;
          },
          decoration: InputDecoration(
            suffixText: 'FCFA',
            hintText: 'Ex: 3200',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isUnav = _availability == PharmacyAvailabilityType.unavailable;
    final color = isUnav
        ? AppColors.textSecondary
        : (_availability == PharmacyAvailabilityType.conditional
            ? PharmacistQuoteReplySheet.amber
            : PharmacistQuoteReplySheet.emerald);
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        key: const ValueKey('btn_submit_counter_quote'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: _submit,
        icon:
            Icon(isUnav ? Icons.cancel_outlined : Icons.send_rounded, size: 16),
        label: Text(
          isUnav
              ? "Notifier l'indisponibilité"
              : "Transmettre l'offre chiffrée",
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}

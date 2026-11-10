import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/realtime_dispatch/data/models/flash_order_dto.dart';
import 'package:medmate/features/realtime_dispatch/data/models/pharmacy_offer_dto.dart';

void main() {
  group('DTO Mappers & Serialization Suite', () {
    const medication = Medication(
      id: 'med-1',
      dci: 'Paracétamol',
      nomCommercial: 'Doliprane',
      forme: 'Comprimé',
      dosage: '1000mg',
      classeTherapeutique: 'Antalgique',
      prixHomologueCfa: 1500,
      necessiteOrdonnance: false,
    );

    const basketItem = BasketItem(
      id: 'item-1',
      medication: medication,
      quantity: 2,
      hasPrescription: true,
      prescriptionNote: 'Prendre 1 comprimé 3x/jour',
    );

    const dispatchedPharmacy = DispatchedPharmacy(
      id: 'pharma-1',
      name: 'Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 1.2,
      phone: '+237 671234567',
      waveIndex: 1,
      status: PharmacistReplyType.available,
      quotedPriceCfa: 3000,
    );

    final pharmacyOffer = PharmacyOffer(
      id: 'offer-1',
      pharmacyId: 'pharma-1',
      pharmacyName: 'Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 1.2,
      phone: '+237 671234567',
      availabilityType: PharmacyAvailabilityType.fullyAvailable,
      quotedPriceCfa: 3000,
      availableItemIds: const ['item-1'],
      proposesDelivery: true,
      deliveryFeeCfa: 1000,
      estimatedDeliveryMinutes: 25,
      submittedAt: DateTime(2026, 11, 10, 8, 30),
    );

    final flashOrder = FlashOrder(
      id: 'order-123',
      items: const [basketItem],
      quarter: 'Poste Centrale',
      targets: const [dispatchedPharmacy],
      createdAt: DateTime(2026, 11, 10, 8, 0),
      expiresAt: DateTime(2026, 11, 10, 10, 0),
      currentWave: 1,
      waveTimeRemainingSeconds: 120,
      offers: [pharmacyOffer],
      selectedOffer: pharmacyOffer,
      status: FlashOrderStatus.offersReceived,
      paymentMethod: FlashPaymentMethod.cashCounter,
      paymentStatus: FlashPaymentStatus.pending,
      phoneNumber: '+237 699887766',
      reservationOtpCode: '458921',
    );

    test('FlashOrderDto should round-trip serialize accurately', () {
      final json = FlashOrderDto.toJson(flashOrder);
      final deserialized = FlashOrderDto.fromJson(json);

      expect(deserialized.id, equals(flashOrder.id));
      expect(deserialized.quarter, equals(flashOrder.quarter));
      expect(deserialized.currentWave, equals(1));
      expect(deserialized.status, equals(FlashOrderStatus.offersReceived));
      expect(deserialized.items.length, equals(1));
      expect(deserialized.items.first.medication.nomCommercial, equals('Doliprane'));
      expect(deserialized.targets.first.name, equals('Pharmacie du Centre'));
      expect(deserialized.offers.first.quotedPriceCfa, equals(3000));
      expect(deserialized.selectedOffer?.id, equals('offer-1'));
      expect(deserialized.reservationOtpCode, equals('458921'));
    });

    test('FlashOrderDto should handle snake_case Supabase CDC json payload', () {
      final supabaseRow = {
        'id': 'order-supabase-1',
        'quarter': 'Bastos',
        'current_wave': 2,
        'wave_time_remaining_seconds': 90,
        'status': 'dispatchingWave',
        'payment_method': 'orangeMoney',
        'payment_status': 'confirmed',
        'phone_number': '+237 655443322',
        'reservation_otp_code': '123456',
        'is_picked_up': false,
        'created_at': '2026-11-10T08:00:00.000Z',
        'expires_at': '2026-11-10T10:00:00.000Z',
        'items': [
          {
            'id': 'item-sub-1',
            'quantity': 1,
            'has_prescription': false,
            'medication': {
              'id': 'med-sub-1',
              'dci': 'Amoxicilline',
              'nom_commercial': 'Clamoxyl',
              'forme': 'Gélule',
              'dosage': '500mg',
              'classe_therapeutique': 'Antibiotique',
              'prix_homologue_cfa': 2500,
              'necessite_ordonnance': true,
            },
          }
        ],
        'targets': <dynamic>[],
        'offers': <dynamic>[],
      };

      final order = FlashOrderDto.fromJson(supabaseRow);
      expect(order.id, equals('order-supabase-1'));
      expect(order.quarter, equals('Bastos'));
      expect(order.currentWave, equals(2));
      expect(order.paymentMethod, equals(FlashPaymentMethod.orangeMoney));
      expect(order.paymentStatus, equals(FlashPaymentStatus.confirmed));
      expect(order.items.first.medication.dci, equals('Amoxicilline'));
    });

    test('PharmacyOfferDto should round-trip serialize accurately', () {
      final json = PharmacyOfferDto.toJson(pharmacyOffer);
      final deserialized = PharmacyOfferDto.fromJson(json);

      expect(deserialized.id, equals(pharmacyOffer.id));
      expect(deserialized.pharmacyName, equals('Pharmacie du Centre'));
      expect(deserialized.quotedPriceCfa, equals(3000));
      expect(deserialized.deliveryFeeCfa, equals(1000));
      expect(deserialized.grandTotalCfa, equals(4000));
      expect(deserialized.proposesDelivery, isTrue);
      expect(deserialized.availabilityType, equals(PharmacyAvailabilityType.fullyAvailable));
    });

    test('PharmacyOfferDto should parse conditional and unavailable statuses', () {
      final conditionalJson = {
        'id': 'offer-cond',
        'pharmacy_id': 'pharma-2',
        'pharmacy_name': 'Pharmacie Bastos',
        'quarter': 'Bastos',
        'distance_km': 2.5,
        'phone': '+237 688990011',
        'availability_type': 'conditional',
        'quoted_price_cfa': 3500,
        'condition_requirements': ['Ordonnance physique originale requise'],
        'condition_note': 'Condition spéciale',
        'proposes_delivery': false,
      };

      final offer = PharmacyOfferDto.fromJson(conditionalJson);
      expect(offer.availabilityType, equals(PharmacyAvailabilityType.conditional));
      expect(offer.conditionRequirements, contains('Ordonnance physique originale requise'));
      expect(offer.conditionNote, equals('Condition spéciale'));
      expect(offer.grandTotalCfa, equals(3500));
    });
  });
}

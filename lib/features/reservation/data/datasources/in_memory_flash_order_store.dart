import 'dart:math';

import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacist_portal/data/models/incoming_demand_model.dart';
import 'package:medmate/features/pharmacist_portal/data/models/pharmacy_daily_analytics_model.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/pharmacy_offer_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:uuid/uuid.dart';

/// Exception levée lors d'un échec de validation des données d'une réservation.
class ValidationException implements Exception {
  const ValidationException([this.message = 'Données invalides']);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception levée lors d'un échec d'exécution du flux de réservation (ex: TTL expiré).
class ReservationException implements Exception {
  const ReservationException([this.message = 'Erreur de réservation']);
  final String message;

  @override
  String toString() => 'ReservationException: $message';
}

/// Coordinateur en mémoire partagé (Single Source of Truth)
/// reliant le flux Patient et le portail Pharmacien d'officine.
///
/// Garantit la synchronisation stricte et bidirectionnelle sans aucun mock UI.
class InMemoryFlashOrderStore {
  InMemoryFlashOrderStore({
    List<Pharmacy>? partnerPharmacies,
    Uuid? uuid,
    Random? random,
  })  : _uuid = uuid ?? const Uuid(),
        _random = random ?? Random() {
    if (partnerPharmacies != null) {
      _partnerPharmacies.addAll(partnerPharmacies);
    } else {
      _seedDefaultPartnerPharmacies();
    }
  }

  /// Instance singleton partagée par défaut.
  static InMemoryFlashOrderStore instance = InMemoryFlashOrderStore();

  final Uuid _uuid;
  final Random _random;

  final Map<String, FlashRequestModel> _flashRequests = {};
  final Map<String, List<IncomingDemandModel>> _demandsPerPharmacy = {};
  final Map<String, ReservationModel> _reservations = {};
  final Map<String, PharmacyDailyAnalyticsModel> _analyticsPerPharmacy = {};
  final List<Pharmacy> _partnerPharmacies = [];

  /// Réinitialise l'état complet du coordinateur en mémoire (utile entre tests).
  void reset() {
    _flashRequests.clear();
    _demandsPerPharmacy.clear();
    _reservations.clear();
    _analyticsPerPharmacy.clear();
    _partnerPharmacies.clear();
    _seedDefaultPartnerPharmacies();
  }

  /// Ajoute une officine partenaire au référentiel du coordinateur.
  void addPartnerPharmacy(Pharmacy pharmacy) {
    final index = _partnerPharmacies.indexWhere((p) => p.id == pharmacy.id);
    if (index >= 0) {
      _partnerPharmacies[index] = pharmacy;
    } else {
      _partnerPharmacies.add(pharmacy);
    }
  }

  /// Initialise les officines partenaires de référence à Yaoundé.
  void _seedDefaultPartnerPharmacies() {
    _partnerPharmacies.addAll(const [
      Pharmacy(
        id: 'pharma-bastos-01',
        nom: 'Pharmacie Bastos',
        licenceOnpc: 'ONPC-CMR-1001',
        quartier: 'Bastos',
        carrefourRepere: 'Carrefour Warda',
        latitude: 3.8812,
        longitude: 11.5173,
        telephoneGarde: '+237699001122',
        estOuverte: true,
        estDeGarde: true,
        estPartenaire: true,
        distanceMetres: 350,
      ),
      Pharmacy(
        id: 'pharma-nlongkak-01',
        nom: 'Pharmacie de Nlongkak',
        licenceOnpc: 'ONPC-CMR-1002',
        quartier: 'Nlongkak',
        carrefourRepere: 'Carrefour Nlongkak',
        latitude: 3.8833,
        longitude: 11.5250,
        telephoneGarde: '+237677334455',
        estOuverte: true,
        estDeGarde: true,
        estPartenaire: true,
        distanceMetres: 600,
      ),
      Pharmacy(
        id: 'pharma-mokolo-01',
        nom: 'Pharmacie Marché Mokolo',
        licenceOnpc: 'ONPC-CMR-2001',
        quartier: 'Mokolo',
        carrefourRepere: 'Marché Mokolo',
        latitude: 3.8740,
        longitude: 11.5020,
        telephoneGarde: '+237699223344',
        estOuverte: true,
        estDeGarde: false,
        estPartenaire: true,
        distanceMetres: 1200,
      ),
      Pharmacy(
        id: 'pharma-tsinga-01',
        nom: 'Pharmacie du Soleil Tsinga',
        licenceOnpc: 'ONPC-CMR-2002',
        quartier: 'Tsinga',
        carrefourRepere: 'Carrefour MEEC',
        latitude: 3.8810,
        longitude: 11.4960,
        telephoneGarde: '+237677445566',
        estOuverte: true,
        estDeGarde: false,
        estPartenaire: true,
        distanceMetres: 1500,
      ),
      Pharmacy(
        id: 'pharma-obili-01',
        nom: 'Pharmacie Universitaire Obili',
        licenceOnpc: 'ONPC-CMR-3001',
        quartier: 'Obili',
        carrefourRepere: 'Carrefour Obili',
        latitude: 3.8540,
        longitude: 11.4920,
        telephoneGarde: '+237699334455',
        estOuverte: true,
        estDeGarde: true,
        estPartenaire: true,
        distanceMetres: 1800,
      ),
      Pharmacy(
        id: 'pharma-essos-01',
        nom: "Pharmacie d'Essos",
        licenceOnpc: 'ONPC-CMR-5001',
        quartier: 'Essos',
        carrefourRepere: 'Carrefour Essos (Hôpital de la Caisse)',
        latitude: 3.8720,
        longitude: 11.5410,
        telephoneGarde: '+237677556677',
        estOuverte: true,
        estDeGarde: true,
        estPartenaire: true,
        distanceMetres: 2100,
      ),
      Pharmacy(
        id: 'pharma-biyemassi-01',
        nom: "Pharmacie de l'Acacia",
        licenceOnpc: 'ONPC-CMR-6001',
        quartier: 'Biyem-Assi',
        carrefourRepere: 'Carrefour Biyem-Assi (Acacia)',
        latitude: 3.8375,
        longitude: 11.4880,
        telephoneGarde: '+237699445566',
        estOuverte: true,
        estDeGarde: false,
        estPartenaire: true,
        distanceMetres: 2400,
      ),
      Pharmacy(
        id: 'pharma-mendong-01',
        nom: 'Pharmacie Simbock Mendong',
        licenceOnpc: 'ONPC-CMR-6002',
        quartier: 'Mendong',
        carrefourRepere: 'Entrée Simbock / Mendong',
        latitude: 3.8290,
        longitude: 11.4710,
        telephoneGarde: '+237677667788',
        estOuverte: true,
        estDeGarde: false,
        estPartenaire: true,
        distanceMetres: 2800,
      ),
    ]);
  }

  /// 1. Soumission d'une demande flash par le patient.
  /// Notifie la première vague de 2 officines partenaires en rotation équitable (ONPC).
  Future<FlashRequestModel> submitFlashRequest(
    FlashRequestModel request,
  ) async {
    // Sélection des 2 premières officines partenaires éligibles (vague 1)
    final candidatePharmacies = _selectCandidatePharmacies(
      quartierOuCarrefour: request.quartierOuCarrefour,
      alreadyNotifiedIds: request.pharmaciesNotifieesIds,
      limit: 2,
    );

    final notifiedIds = <String>[
      ...request.pharmaciesNotifieesIds,
      ...candidatePharmacies.map((p) => p.id),
    ];

    final updatedRequest = FlashRequestModel(
      id: request.id,
      clientRequestId: request.clientRequestId,
      items: request.items,
      quartierOuCarrefour: request.quartierOuCarrefour,
      statut: FlashRequestStatus.active,
      vagueActuelle: 1,
      pharmaciesNotifieesIds: notifiedIds,
      offresRecues: request.offresRecues,
      createdAt: request.createdAt,
      expiresAt: request.expiresAt,
    );

    _flashRequests[request.id] = updatedRequest;

    // Création des demandes entrantes pour chaque pharmacie notifiée
    final now = DateTime.now();
    for (final pharma in candidatePharmacies) {
      final incomingDemand = IncomingDemandModel(
        id: _uuid.v4(),
        flashRequest: updatedRequest,
        receivedAt: now,
        isResponded: false,
        distanceMetres: pharma.distanceMetres ?? 500,
      );

      _demandsPerPharmacy
          .putIfAbsent(pharma.id, () => [])
          .add(incomingDemand);

      // Incrémentation des statistiques journalières
      _recordDemandReceived(pharma.id, now);
    }

    return updatedRequest;
  }

  /// 2. Escalade de diffusion de la demande vers une nouvelle vague de 2 officines.
  Future<FlashRequestModel> escalateDispatchWave({
    required String demandeId,
    required int nextWaveNumber,
    required List<String> eligiblePharmacyIds,
  }) async {
    final existingRequest = _flashRequests[demandeId];
    if (existingRequest == null) {
      throw const NotFoundException('Demande flash introuvable.');
    }

    final newNotified = <Pharmacy>[];
    for (final pid in eligiblePharmacyIds) {
      if (!existingRequest.pharmaciesNotifieesIds.contains(pid)) {
        final pharma = _findPharmacyById(pid);
        if (pharma != null) {
          newNotified.add(pharma);
        }
      }
    }

    final updatedNotifiedIds = <String>[
      ...existingRequest.pharmaciesNotifieesIds,
      ...newNotified.map((p) => p.id),
    ];

    final updatedRequest = FlashRequestModel(
      id: existingRequest.id,
      clientRequestId: existingRequest.clientRequestId,
      items: existingRequest.items,
      quartierOuCarrefour: existingRequest.quartierOuCarrefour,
      statut: existingRequest.hasOffers
          ? FlashRequestStatus.partiallyAnswered
          : FlashRequestStatus.active,
      vagueActuelle: nextWaveNumber,
      pharmaciesNotifieesIds: updatedNotifiedIds,
      offresRecues: existingRequest.offresRecues,
      createdAt: existingRequest.createdAt,
      expiresAt: existingRequest.expiresAt,
    );

    _flashRequests[demandeId] = updatedRequest;

    final now = DateTime.now();
    for (final pharma in newNotified) {
      final incomingDemand = IncomingDemandModel(
        id: _uuid.v4(),
        flashRequest: updatedRequest,
        receivedAt: now,
        isResponded: false,
        distanceMetres: pharma.distanceMetres ?? 750,
      );

      _demandsPerPharmacy
          .putIfAbsent(pharma.id, () => [])
          .add(incomingDemand);

      _recordDemandReceived(pharma.id, now);
    }

    return updatedRequest;
  }

  /// 3. Récupère la liste des demandes entrantes reçues par une officine.
  Future<List<IncomingDemandModel>> getIncomingDemands(
    String pharmacyId,
  ) async {
    final demands = _demandsPerPharmacy[pharmacyId] ?? <IncomingDemandModel>[];

    // Synchronisation avec l'état courant des FlashRequests
    return demands.map((demand) {
      final currentFlash = _flashRequests[demand.demandeId];
      if (currentFlash != null) {
        return IncomingDemandModel(
          id: demand.id,
          flashRequest: currentFlash,
          receivedAt: demand.receivedAt,
          isResponded: demand.isResponded,
          distanceMetres: demand.distanceMetres,
        );
      }
      return demand;
    }).toList();
  }

  /// 4. Soumission d'un devis comptoir formulé par le pharmacien.
  /// Convertit le devis en PharmacyOfferModel et l'ajoute à la demande flash du patient.
  Future<PharmacyOfferModel> submitCounterQuote(
    CounterQuoteSubmissionModel submission,
  ) async {
    final flashRequest = _flashRequests[submission.demandId];
    if (flashRequest == null) {
      throw const NotFoundException('Demande flash introuvable.');
    }

    final pharmacy = _findPharmacyById(submission.pharmacyId);
    final pharmacyNom = pharmacy?.nom ?? 'Pharmacie Partenaire';
    final quartier = pharmacy?.quartier ?? 'Yaoundé';
    final distance = pharmacy?.distanceMetres;

    final now = DateTime.now();
    final offer = PharmacyOfferModel(
      id: _uuid.v4(),
      demandeId: submission.demandId,
      pharmacyId: submission.pharmacyId,
      pharmacyNom: pharmacyNom,
      quartier: quartier,
      distanceMetres: distance,
      items: submission.itemResponses,
      montantTotalPropose: submission.montantTotal,
      livraisonDisponible: submission.livraisonPossible,
      fraisLivraison: submission.fraisLivraison,
      delaiLivraisonMinutes: submission.delaiMinutes,
      createdAt: now,
    );

    final updatedOffers = <PharmacyOffer>[
      ...flashRequest.offresRecues,
      offer,
    ];

    final updatedRequest = FlashRequestModel(
      id: flashRequest.id,
      clientRequestId: flashRequest.clientRequestId,
      items: flashRequest.items,
      quartierOuCarrefour: flashRequest.quartierOuCarrefour,
      statut: FlashRequestStatus.partiallyAnswered,
      vagueActuelle: flashRequest.vagueActuelle,
      pharmaciesNotifieesIds: flashRequest.pharmaciesNotifieesIds,
      offresRecues: updatedOffers,
      createdAt: flashRequest.createdAt,
      expiresAt: flashRequest.expiresAt,
    );

    _flashRequests[submission.demandId] = updatedRequest;

    // Marquage de la demande entrante comme répondue
    final demands = _demandsPerPharmacy[submission.pharmacyId];
    if (demands != null) {
      final index = demands.indexWhere((d) => d.demandeId == submission.demandId);
      if (index >= 0) {
        demands[index] = IncomingDemandModel(
          id: demands[index].id,
          flashRequest: updatedRequest,
          receivedAt: demands[index].receivedAt,
          isResponded: true,
          distanceMetres: demands[index].distanceMetres,
        );
      }
    }

    // Mise à jour des statistiques journalières de l'officine
    _recordQuoteSubmitted(submission.pharmacyId, now);

    return offer;
  }

  /// 5. Sélection d'une offre officine par le patient.
  /// Génère un code OTP à 6 chiffres et une validité TTL stricte de 2 heures.
  Future<ReservationModel> selectPharmacyOffer({
    required String clientReservationId,
    required String demandeId,
    required String offreId,
    required String patientPhone,
  }) async {
    final flashRequest = _flashRequests[demandeId];
    if (flashRequest == null) {
      throw const NotFoundException('Demande flash introuvable.');
    }

    if (flashRequest.isExpired) {
      throw const ReservationException('La demande flash a expiré.');
    }

    final offer = flashRequest.offresRecues.firstWhere(
      (o) => o.id == offreId,
      orElse: () => throw const NotFoundException('Offre officine introuvable.'),
    );

    // Génération du code OTP strictement composé de 6 chiffres décimaux
    final otpCode = (100000 + _random.nextInt(900000)).toString();

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 2));

    final reservation = ReservationModel(
      id: _uuid.v4(),
      clientReservationId: clientReservationId,
      demandeId: demandeId,
      offreId: offreId,
      pharmacyId: offer.pharmacyId,
      codeRetraitOtp6Chiffres: otpCode,
      statut: ReservationStatus.pending,
      createdAt: now,
      expiresAt: expiresAt,
    );

    _reservations[reservation.id] = reservation;

    // Mise à jour du statut de la demande flash en fulfilled
    final updatedRequest = FlashRequestModel(
      id: flashRequest.id,
      clientRequestId: flashRequest.clientRequestId,
      items: flashRequest.items,
      quartierOuCarrefour: flashRequest.quartierOuCarrefour,
      statut: FlashRequestStatus.fulfilled,
      vagueActuelle: flashRequest.vagueActuelle,
      pharmaciesNotifieesIds: flashRequest.pharmaciesNotifieesIds,
      offresRecues: flashRequest.offresRecues,
      createdAt: flashRequest.createdAt,
      expiresAt: flashRequest.expiresAt,
    );
    _flashRequests[demandeId] = updatedRequest;

    return reservation;
  }

  /// 6. Validation du code OTP au comptoir par le pharmacien.
  Future<ReservationModel> validatePickupOtp({
    required String pharmacyId,
    required String reservationId,
    required String otpCode,
  }) async {
    final reservation = _reservations[reservationId];
    if (reservation == null) {
      throw const NotFoundException('Réservation introuvable.');
    }

    if (reservation.pharmacyId != pharmacyId) {
      throw const AuthException(
        "Cette réservation n'appartient pas à cette officine.",
      );
    }

    if (reservation.isExpired) {
      final expired = ReservationModel.fromDomain(
        reservation.copyWith(statut: ReservationStatus.expired),
      );
      _reservations[reservationId] = expired;
      throw const ReservationException(
        'La réservation a expiré (délai de 2h dépassé).',
      );
    }

    if (reservation.codeRetraitOtp6Chiffres != otpCode.trim()) {
      throw const ValidationException('Code OTP invalide.');
    }

    final confirmed = ReservationModel.fromDomain(
      reservation.copyWith(statut: ReservationStatus.confirmedAtCounter),
    );
    _reservations[reservationId] = confirmed;

    // Mise à jour des statistiques journalières
    _recordReservationConfirmed(pharmacyId, DateTime.now());

    return confirmed;
  }

  /// Confirmation directe par le patient ou coordinateur lors de la saisie OTP.
  Future<ReservationModel> confirmReservationOtp({
    required String reservationId,
    required String otpCode,
  }) async {
    final reservation = _reservations[reservationId];
    if (reservation == null) {
      throw const NotFoundException('Réservation introuvable.');
    }

    if (reservation.isExpired) {
      final expired = ReservationModel.fromDomain(
        reservation.copyWith(statut: ReservationStatus.expired),
      );
      _reservations[reservationId] = expired;
      throw const ReservationException(
        'La réservation a expiré (délai de 2h dépassé).',
      );
    }

    if (reservation.codeRetraitOtp6Chiffres != otpCode.trim()) {
      throw const ValidationException('Code OTP invalide.');
    }

    final confirmed = ReservationModel.fromDomain(
      reservation.copyWith(statut: ReservationStatus.confirmedAtCounter),
    );
    _reservations[reservationId] = confirmed;

    _recordReservationConfirmed(reservation.pharmacyId, DateTime.now());

    return confirmed;
  }

  /// 7. Consultation des statistiques journalières anonymisées de l'officine.
  Future<PharmacyDailyAnalyticsModel> getPharmacyAnalytics({
    required String pharmacyId,
    required DateTime date,
  }) async {
    final existing = _analyticsPerPharmacy[pharmacyId];
    if (existing != null) {
      return existing;
    }

    final initial = PharmacyDailyAnalyticsModel(
      id: _uuid.v4(),
      pharmacyId: pharmacyId,
      date: DateTime(date.year, date.month, date.day),
      totalDemandsReceived: 0,
      totalQuotesSubmitted: 0,
      totalReservationsConfirmed: 0,
      conversionRate: 0,
    );
    _analyticsPerPharmacy[pharmacyId] = initial;
    return initial;
  }

  /// Récupère une demande flash par son identifiant unique.
  Future<FlashRequestModel> getFlashRequestById(String demandeId) async {
    final req = _flashRequests[demandeId];
    if (req == null) {
      throw const NotFoundException('Demande flash introuvable.');
    }
    return req;
  }

  /// Récupère une réservation par son identifiant unique.
  Future<ReservationModel> getReservationById(String reservationId) async {
    final res = _reservations[reservationId];
    if (res == null) {
      throw const NotFoundException('Réservation introuvable.');
    }
    return res;
  }

  // --- Méthodes privées d'aide opérationnelle ---

  Pharmacy? _findPharmacyById(String id) {
    try {
      return _partnerPharmacies.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Pharmacy> _selectCandidatePharmacies({
    required String quartierOuCarrefour,
    required List<String> alreadyNotifiedIds,
    required int limit,
  }) {
    final unnotified = _partnerPharmacies
        .where((p) => p.estPartenaire && !alreadyNotifiedIds.contains(p.id))
        .toList();

    // Priorise d'abord les officines correspondant au quartier ou repère
    final qLower = quartierOuCarrefour.toLowerCase();
    unnotified.sort((a, b) {
      final aMatch = a.quartier.toLowerCase().contains(qLower) ||
          a.carrefourRepere.toLowerCase().contains(qLower);
      final bMatch = b.quartier.toLowerCase().contains(qLower) ||
          b.carrefourRepere.toLowerCase().contains(qLower);

      if (aMatch && !bMatch) return -1;
      if (!aMatch && bMatch) return 1;
      return (a.distanceMetres ?? 99999).compareTo(b.distanceMetres ?? 99999);
    });

    return unnotified.take(limit).toList();
  }

  void _recordDemandReceived(String pharmacyId, DateTime date) {
    final current = _analyticsPerPharmacy[pharmacyId];
    final received = (current?.totalDemandsReceived ?? 0) + 1;
    final quotes = current?.totalQuotesSubmitted ?? 0;
    final confirmed = current?.totalReservationsConfirmed ?? 0;
    final conversion = quotes > 0 ? (confirmed / quotes) : 0;

    _analyticsPerPharmacy[pharmacyId] = PharmacyDailyAnalyticsModel(
      id: current?.id ?? _uuid.v4(),
      pharmacyId: pharmacyId,
      date: DateTime(date.year, date.month, date.day),
      totalDemandsReceived: received,
      totalQuotesSubmitted: quotes,
      totalReservationsConfirmed: confirmed,
      conversionRate: conversion.toDouble(),
    );
  }

  void _recordQuoteSubmitted(String pharmacyId, DateTime date) {
    final current = _analyticsPerPharmacy[pharmacyId];
    final received = current?.totalDemandsReceived ?? 1;
    final quotes = (current?.totalQuotesSubmitted ?? 0) + 1;
    final confirmed = current?.totalReservationsConfirmed ?? 0;
    final conversion = quotes > 0 ? (confirmed / quotes) : 0;

    _analyticsPerPharmacy[pharmacyId] = PharmacyDailyAnalyticsModel(
      id: current?.id ?? _uuid.v4(),
      pharmacyId: pharmacyId,
      date: DateTime(date.year, date.month, date.day),
      totalDemandsReceived: received,
      totalQuotesSubmitted: quotes,
      totalReservationsConfirmed: confirmed,
      conversionRate: conversion.toDouble(),
    );
  }

  void _recordReservationConfirmed(String pharmacyId, DateTime date) {
    final current = _analyticsPerPharmacy[pharmacyId];
    final received = current?.totalDemandsReceived ?? 1;
    final quotes = current?.totalQuotesSubmitted ?? 1;
    final confirmed = (current?.totalReservationsConfirmed ?? 0) + 1;
    final conversion = quotes > 0 ? (confirmed / quotes) : 0;

    _analyticsPerPharmacy[pharmacyId] = PharmacyDailyAnalyticsModel(
      id: current?.id ?? _uuid.v4(),
      pharmacyId: pharmacyId,
      date: DateTime(date.year, date.month, date.day),
      totalDemandsReceived: received,
      totalQuotesSubmitted: quotes,
      totalReservationsConfirmed: confirmed,
      conversionRate: conversion.toDouble(),
    );
  }
}

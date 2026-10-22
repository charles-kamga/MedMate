import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../models/medication_model.dart';
import '../models/pharmacy_model.dart';
import '../models/reservation_model.dart';

class PharmacyRepositoryImpl implements PharmacyRepository {
  PharmacyRepositoryImpl({
    required this.supabaseClient,
    required this.networkInfo,
  });

  final SupabaseClient supabaseClient;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<Pharmacy>>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double maxRadiusMeters = 3500,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        // Mode dégradé offline : renvoi des repères locaux de Yaoundé
        return Right(_getOfflineFallbackPharmacies(latitude, longitude));
      }

      // Appel de la procédure stockée RPC de dispatch équitable (Round-Robin ONPC)
      final List<dynamic> response = await supabaseClient.rpc(
        'calculate_fair_dispatch',
        params: {
          'p_demande_id': '00000000-0000-0000-0000-000000000000',
          'p_patient_lat': latitude,
          'p_patient_lon': longitude,
          'p_max_distance_meters': maxRadiusMeters.toInt(),
          'p_target_officines_count': 5,
        },
      );

      final pharmacies = response
          .map((item) => PharmacyModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return Right(pharmacies);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return const Left(ServerFailure('Erreur inattendue lors de la recherche des officines.'));
    }
  }

  @override
  Future<Either<Failure, List<Medication>>> searchMedications(String query) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('La recherche du catalogue requiert une connexion internet.'));
      }

      // Recherche optimisée par l'index trigramme pg_trgm
      final response = await supabaseClient
          .from('medicaments')
          .select()
          .or('nom_commercial.ilike.%$query%,dci.ilike.%$query%')
          .limit(20);

      final medications = (response as List<dynamic>)
          .map((item) => MedicationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return Right(medications);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return const Left(ServerFailure('Erreur lors de la consultation du catalogue.'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> requestReservation({
    required String clientReservationId,
    required String pharmacyId,
    required String medicationId,
    required String patientPhone,
    required int quantite,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('Impossible de réserver sans connexion internet active.'));
      }

      // Génération sécurisée d'un code de retrait OTP à 6 chiffres
      final otp = (100000 + Random().nextInt(900000)).toString();

      final response = await supabaseClient
          .from('reservations')
          .insert({
            'client_reservation_id': clientReservationId,
            'pharmacy_id': pharmacyId,
            'medication_id': medicationId,
            'patient_phone_contact': patientPhone,
            'quantite': quantite,
            'code_retrait_otp': otp,
            'statut': 'pending',
          })
          .select('*, pharmacies(nom), medicaments(nom_commercial)')
          .single();

      final json = response;
      final pharmacyData = json['pharmacies'] as Map<String, dynamic>?;
      final medicationData = json['medicaments'] as Map<String, dynamic>?;

      final model = ReservationModel.fromJson({
        ...json,
        'pharmacy_name': pharmacyData?['nom'] ?? 'Pharmacie',
        'medication_name': medicationData?['nom_commercial'] ?? 'Médicament',
      });

      return Right(model);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return const Left(ReservationFailure('Échec de la validation de la réservation.'));
    }
  }

  /// Fournit des données de secours depuis les repères de Yaoundé si le réseau est coupé
  List<Pharmacy> _getOfflineFallbackPharmacies(double lat, double lon) {
    return YaoundeLandmarks.list.map((landmark) {
      return Pharmacy(
        id: landmark.id,
        nom: 'Officine de Repère - ${landmark.nom}',
        licenceOnpc: 'ONPC-OFFLINE',
        quartier: landmark.quartier,
        carrefourRepere: landmark.nom,
        latitude: landmark.latitude,
        longitude: landmark.longitude,
        telephoneGarde: '+237222000000',
        estOuverte: true,
        estDeGarde: true,
        distanceMetres: 1200,
      );
    }).toList();
  }
}

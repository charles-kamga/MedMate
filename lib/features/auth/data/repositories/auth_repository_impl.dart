import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';

/// Implémentation concrète du contrat AuthRepository pour Afya Santé.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.localDataSource});

  final AuthLocalDataSource localDataSource;

  @override
  Future<Either<Failure, UserSession>> getCurrentSession() async {
    try {
      final sessionModel = await localDataSource.getCurrentSession();
      return Right(sessionModel.toDomain());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PharmacistProfile>> signInPharmacist({
    required String email,
    required String password,
  }) async {
    try {
      final sessionModel = await localDataSource.signInPharmacist(email, password);
      final profile = sessionModel.pharmacistProfile;
      if (profile == null) {
        return const Left(
          AuthFailure('Profil pharmacien introuvable dans la session.'),
        );
      }
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await localDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PatientSession>> getOrCreatePatientSession({
    String? phoneNumber,
  }) async {
    try {
      final patientModel = await localDataSource.getOrCreatePatientSession(
        phoneNumber: phoneNumber,
      );
      return Right(patientModel.toDomain());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

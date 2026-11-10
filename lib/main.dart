import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/navigation/afya_app_shell.dart';
import 'package:medmate/core/theme/app_theme.dart';
import 'package:medmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:medmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_cubit.dart';
import 'package:medmate/features/duty_pharmacy/data/datasources/duty_pharmacy_data_source.dart';
import 'package:medmate/features/duty_pharmacy/data/repositories/duty_pharmacy_repository_impl.dart';
import 'package:medmate/features/duty_pharmacy/domain/repositories/duty_pharmacy_repository.dart';
import 'package:medmate/features/pharmacist_portal/data/datasources/pharmacist_portal_data_source.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/pharmacy_search/data/datasources/yaounde_pharmacy_data_source.dart';
import 'package:medmate/features/pharmacy_search/data/repositories/pharmacy_search_repository_impl.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_search_repository.dart';
import 'package:medmate/features/reservation/data/datasources/flash_order_data_source.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AfyaSanteApp());
}

/// Point d'entrée racine d'Afya Santé.
class AfyaSanteApp extends StatelessWidget {
  const AfyaSanteApp({
    super.key,
    this.authRepository,
    this.pharmacySearchRepository,
    this.dutyPharmacyRepository,
    this.reservationRepository,
    this.pharmacistPortalRepository,
    this.authCubit,
  });

  final AuthRepository? authRepository;
  final PharmacySearchRepository? pharmacySearchRepository;
  final DutyPharmacyRepository? dutyPharmacyRepository;
  final ReservationRepository? reservationRepository;
  final PharmacistPortalRepository? pharmacistPortalRepository;
  final AuthCubit? authCubit;

  @override
  Widget build(BuildContext context) {
    final effectiveAuthRepo = authRepository ??
        AuthRepositoryImpl(localDataSource: AuthLocalDataSourceImpl());
    final effectiveSearchRepo = pharmacySearchRepository ??
        const PharmacySearchRepositoryImpl(
          dataSource: YaoundePharmacyDataSourceImpl(),
        );
    final effectiveDutyRepo = dutyPharmacyRepository ??
        const DutyPharmacyRepositoryImpl(
          dataSource: DutyPharmacyDataSourceImpl(),
        );
    final effectiveStore = InMemoryFlashOrderStore.instance;
    final effectiveReservationRepo = reservationRepository ??
        ReservationRepositoryImpl(
          dataSource: FlashOrderDataSourceImpl(store: effectiveStore),
        );
    final effectivePortalRepo = pharmacistPortalRepository ??
        PharmacistPortalRepositoryImpl(
          dataSource: PharmacistPortalDataSourceImpl(store: effectiveStore),
        );

    final appContent = MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AfyaAppShell(),
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: effectiveAuthRepo),
        RepositoryProvider<PharmacySearchRepository>.value(
          value: effectiveSearchRepo,
        ),
        RepositoryProvider<DutyPharmacyRepository>.value(
          value: effectiveDutyRepo,
        ),
        RepositoryProvider<ReservationRepository>.value(
          value: effectiveReservationRepo,
        ),
        RepositoryProvider<PharmacistPortalRepository>.value(
          value: effectivePortalRepo,
        ),
      ],
      child: authCubit != null
          ? BlocProvider<AuthCubit>.value(
              value: authCubit!,
              child: appContent,
            )
          : BlocProvider<AuthCubit>(
              create: (_) => AuthCubit(authRepository: effectiveAuthRepo)
                ..checkCurrentSession(),
              child: appContent,
            ),
    );
  }
}

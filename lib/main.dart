import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/navigation/afya_app_shell.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/flash_order/domain/entities/flash_order.dart';
import 'features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'features/home/presentation/views/main_navigation_screen.dart';
import 'features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'features/pharmacist_portal/domain/usecases/get_pending_counter_orders.dart';
import 'features/pharmacist_portal/domain/usecases/submit_counter_quote.dart';
import 'features/pharmacist_portal/domain/usecases/validate_counter_otp.dart';
import 'features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'features/pharmacy_search/data/repositories/pharmacy_repository_impl.dart';
import 'features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'features/pharmacy_search/domain/usecases/request_reservation.dart';
import 'features/pharmacy_search/domain/usecases/search_medications.dart';
import 'features/pharmacy_search/domain/usecases/search_pharmacies.dart';
import 'features/pharmacy_search/presentation/bloc/pharmacy_search_bloc.dart';
import 'features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'features/realtime_dispatch/data/datasources/adaptive_polling_fallback_manager.dart';
import 'features/realtime_dispatch/data/datasources/supabase_realtime_datasource.dart';
import 'features/realtime_dispatch/data/datasources/yaounde_topological_router.dart';
import 'features/realtime_dispatch/data/repositories/realtime_dispatch_repository_impl.dart';
import 'features/realtime_dispatch/domain/repositories/realtime_dispatch_repository.dart';
import 'features/reservation/data/repositories/reservation_repository_impl.dart';
import 'features/reservation/domain/repositories/reservation_repository.dart';
import 'features/reservation/domain/usecases/escalate_dispatch_wave.dart';
import 'features/reservation/domain/usecases/select_pharmacy_offer.dart';
import 'features/reservation/domain/usecases/submit_flash_request.dart';
import 'features/reservation/presentation/controllers/flash_reservation_cubit.dart';

/// Conteneur des dépendances racine de l'application
class AppDependencies {
  const AppDependencies({
    required this.pharmacyRepository,
    required this.reservationRepository,
    required this.pharmacistPortalRepository,
    this.realtimeRepository,
  });

  factory AppDependencies.build({
    PharmacyRepository? pharmacyRepository,
    ReservationRepository? reservationRepository,
    PharmacistPortalRepository? pharmacistPortalRepository,
  }) {
    final repo = pharmacyRepository ??
        PharmacyRepositoryImpl(
          supabaseClient: SupabaseClient(
            AppConfig.supabaseUrl,
            AppConfig.supabaseAnonKey,
          ),
          networkInfo: const NetworkInfoImpl(),
        );

    final ReservationRepository resRepo;
    final PharmacistPortalRepository pharmaRepo;
    RealtimeDispatchRepository? realtimeRepo;

    if (AppConfig.useRealtimeBackend) {
      final client = SupabaseClient(
        AppConfig.supabaseUrl,
        AppConfig.supabaseAnonKey,
      );
      final realtime = RealtimeDispatchRepositoryImpl(
        realtimeDataSource: SupabaseRealtimeDataSourceImpl(
          supabaseClient: client,
          fallbackManager: AdaptivePollingFallbackManager(),
        ),
        router: YaoundeTopologicalRouter(),
      );
      realtimeRepo = realtime;
      resRepo = reservationRepository ?? realtime;
      pharmaRepo = pharmacistPortalRepository ?? realtime;
    } else {
      // Magasin de commandes partagé : Patient <-> Pharmacien (démo locale E2E)
      final sharedOrders = <String, FlashOrder>{};
      resRepo = reservationRepository ??
          ReservationRepositoryImpl(sharedOrders: sharedOrders);
      pharmaRepo = pharmacistPortalRepository ??
          PharmacistPortalRepositoryImpl(sharedOrders: sharedOrders);
    }

    return AppDependencies(
      pharmacyRepository: repo,
      reservationRepository: resRepo,
      pharmacistPortalRepository: pharmaRepo,
      realtimeRepository: realtimeRepo,
    );
  }

  final PharmacyRepository pharmacyRepository;
  final ReservationRepository reservationRepository;
  final PharmacistPortalRepository pharmacistPortalRepository;
  final RealtimeDispatchRepository? realtimeRepository;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.useRealtimeBackend) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  final dependencies = AppDependencies.build();
  runApp(MedMateApp(dependencies: dependencies));
}

class MedMateApp extends StatefulWidget {
  const MedMateApp({
    super.key,
    this.enableNetworkTiles = true,
    this.dependencies,
    this.pharmacyRepository,
    this.reservationRepository,
    this.pharmacistPortalRepository,
    this.useAfyaAppShell = true,
  });

  final bool enableNetworkTiles;
  final AppDependencies? dependencies;
  final PharmacyRepository? pharmacyRepository;
  final ReservationRepository? reservationRepository;
  final PharmacistPortalRepository? pharmacistPortalRepository;
  final bool useAfyaAppShell;

  @override
  State<MedMateApp> createState() => _MedMateAppState();
}

class _MedMateAppState extends State<MedMateApp> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ??
        AppDependencies.build(
          pharmacyRepository: widget.pharmacyRepository,
          reservationRepository: widget.reservationRepository,
          pharmacistPortalRepository: widget.pharmacistPortalRepository,
        );
  }

  @override
  Widget build(BuildContext context) {
    final repo = _dependencies.pharmacyRepository;
    final resRepo = _dependencies.reservationRepository;
    final pharmaRepo = _dependencies.pharmacistPortalRepository;
    final realtimeRepo = _dependencies.realtimeRepository;

    final searchMedsUseCase = SearchMedicationsUseCase(repo);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
        BlocProvider<FlashOrderCubit>(
          create: (_) => FlashOrderCubit(),
        ),
        BlocProvider<PharmacySearchBloc>(
          create: (_) => PharmacySearchBloc(
            searchPharmaciesUseCase: SearchPharmaciesUseCase(repo),
            searchMedicationsUseCase: searchMedsUseCase,
            requestReservationUseCase: RequestReservationUseCase(repo),
          ),
        ),
        BlocProvider<MedicationCatalogCubit>(
          create: (_) => MedicationCatalogCubit(
            searchMedicationsUseCase: searchMedsUseCase,
          ),
        ),
        BlocProvider<FlashReservationCubit>(
          create: (_) => FlashReservationCubit(
            submitFlashRequestUseCase: SubmitFlashRequestUseCase(resRepo),
            escalateDispatchWaveUseCase: EscalateDispatchWaveUseCase(resRepo),
            selectPharmacyOfferUseCase: SelectPharmacyOfferUseCase(resRepo),
            reservationRepository: resRepo,
            realtimeRepository: realtimeRepo,
          ),
        ),
        BlocProvider<PharmacistCounterCubit>(
          create: (_) => PharmacistCounterCubit(
            getPendingOrders: GetPendingCounterOrdersUseCase(pharmaRepo),
            submitQuoteUseCase: SubmitCounterQuoteUseCase(pharmaRepo),
            validateOtpUseCase: ValidateCounterOtpUseCase(pharmaRepo),
            realtimeRepository: realtimeRepo,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: widget.useAfyaAppShell
            ? AfyaAppShell(enableNetworkTiles: widget.enableNetworkTiles)
            : MainNavigationScreen(enableNetworkTiles: widget.enableNetworkTiles),
      ),
    );
  }
}

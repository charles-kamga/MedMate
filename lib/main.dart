import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/navigation/afya_app_shell.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'features/home/presentation/views/main_navigation_screen.dart';
import 'features/pharmacy_search/data/repositories/pharmacy_repository_impl.dart';
import 'features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'features/pharmacy_search/domain/usecases/request_reservation.dart';
import 'features/pharmacy_search/domain/usecases/search_medications.dart';
import 'features/pharmacy_search/domain/usecases/search_pharmacies.dart';
import 'features/pharmacy_search/presentation/bloc/pharmacy_search_bloc.dart';
import 'features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'features/reservation/data/repositories/reservation_repository_impl.dart';
import 'features/reservation/domain/repositories/reservation_repository.dart';
import 'features/reservation/domain/usecases/escalate_dispatch_wave.dart';
import 'features/reservation/domain/usecases/select_pharmacy_offer.dart';
import 'features/reservation/domain/usecases/submit_flash_request.dart';
import 'features/reservation/presentation/controllers/flash_reservation_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedMateApp());
}

class MedMateApp extends StatelessWidget {
  const MedMateApp({
    super.key,
    this.enableNetworkTiles = true,
    this.pharmacyRepository,
    this.reservationRepository,
    this.useAfyaAppShell = false,
  });

  final bool enableNetworkTiles;
  final PharmacyRepository? pharmacyRepository;
  final ReservationRepository? reservationRepository;
  final bool useAfyaAppShell;

  @override
  Widget build(BuildContext context) {
    final repo = pharmacyRepository ??
        PharmacyRepositoryImpl(
          supabaseClient: SupabaseClient('http://localhost:54321', 'anon-dummy-key'),
          networkInfo: const NetworkInfoImpl(),
        );

    final resRepo = reservationRepository ?? ReservationRepositoryImpl();
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
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MedMate Yaoundé',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: useAfyaAppShell
            ? AfyaAppShell(enableNetworkTiles: enableNetworkTiles)
            : MainNavigationScreen(enableNetworkTiles: enableNetworkTiles),
      ),
    );
  }
}

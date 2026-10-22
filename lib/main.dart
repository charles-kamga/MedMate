import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedMateApp());
}

class MedMateApp extends StatelessWidget {
  const MedMateApp({
    super.key,
    this.enableNetworkTiles = true,
    this.pharmacyRepository,
  });

  final bool enableNetworkTiles;
  final PharmacyRepository? pharmacyRepository;

  @override
  Widget build(BuildContext context) {
    final repo = pharmacyRepository ??
        PharmacyRepositoryImpl(
          supabaseClient: SupabaseClient('http://localhost:54321', 'anon-dummy-key'),
          networkInfo: const NetworkInfoImpl(),
        );

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
            searchMedicationsUseCase: SearchMedicationsUseCase(repo),
            requestReservationUseCase: RequestReservationUseCase(repo),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MedMate Yaoundé',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: MainNavigationScreen(enableNetworkTiles: enableNetworkTiles),
      ),
    );
  }
}

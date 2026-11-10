import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/adaptive_polling_fallback_manager.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/supabase_realtime_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder(this._value);
  final T _value;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future<T>.value(_value).then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  FakePostgrestFilterBuilder(this._value);
  final T _value;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> inFilter(String column, List<dynamic> values) => this;

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return FakePostgrestTransformBuilder<T>(_value);
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    final val = _value is List && (_value as List).isNotEmpty
        ? (_value as List).first as PostgrestMap?
        : (_value is Map ? _value as PostgrestMap? : null);
    return FakePostgrestTransformBuilder<PostgrestMap?>(val);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future<T>.value(_value).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockRealtimeChannel mockChannel;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late AdaptivePollingFallbackManager fallbackManager;
  late SupabaseRealtimeDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(MockRealtimeChannel());
    registerFallbackValue(
      const PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: 'dummy',
      ),
    );
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockChannel = MockRealtimeChannel();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    fallbackManager = AdaptivePollingFallbackManager(
      defaultPollingInterval: const Duration(milliseconds: 50),
    );

    when(() => mockSupabase.channel(any())).thenReturn(mockChannel);
    when(() => mockSupabase.removeChannel(any())).thenAnswer((_) async => 'ok');
    when(
      () => mockChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(mockChannel);
    when(() => mockChannel.subscribe(any())).thenReturn(mockChannel);

    dataSource = SupabaseRealtimeDataSourceImpl(
      supabaseClient: mockSupabase,
      fallbackManager: fallbackManager,
    );
  });

  tearDown(() {
    dataSource.dispose();
  });

  group('SupabaseRealtimeDataSource Tests', () {
    test(
      'watchFlashOrder sets up stream, executes initial fetch, and registers fallback',
      () async {
        final sampleOrderJson = <String, dynamic>{
          'id': 'order-test-123',
          'quarter': 'Carrefour Warda',
          'current_wave': 1,
          'wave_time_remaining_seconds': 120,
          'status': 'dispatchingWave',
          'payment_method': 'cashCounter',
          'payment_status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
          'expires_at':
              DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'items': <dynamic>[],
          'targets': <dynamic>[],
          'offers': <dynamic>[],
        };

        when(() => mockSupabase.from('flash_orders')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenAnswer(
          (_) => FakePostgrestFilterBuilder<PostgrestList>(<PostgrestMap>[sampleOrderJson]),
        );

        final stream = dataSource.watchFlashOrder('order-test-123');

        expect(fallbackManager.activeTaskCount, equals(1));

        final emittedOrder = await stream.first;
        expect(emittedOrder.id, equals('order-test-123'));
        expect(emittedOrder.quarter, equals('Carrefour Warda'));
        expect(
          fallbackManager.currentStatus,
          equals(RealtimeConnectionStatus.connected),
        );
      },
    );

    test('watchOffersForOrder fetches offers and maps them cleanly', () async {
      final sampleOffersJson = <Map<String, dynamic>>[
        {
          'id': 'offer-99',
          'pharmacy_id': 'pharma-1',
          'pharmacy_name': 'Pharmacie du Warda',
          'quarter': 'Carrefour Warda',
          'distance_km': 0.8,
          'phone': '+237 670000000',
          'availability_type': 'fullyAvailable',
          'quoted_price_cfa': 2500,
          'submitted_at': DateTime.now().toIso8601String(),
          'available_item_ids': <String>['item-1'],
          'proposes_delivery': false,
        },
      ];

      when(() => mockSupabase.from('pharmacy_quotes')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenAnswer(
        (_) => FakePostgrestFilterBuilder<PostgrestList>(sampleOffersJson),
      );

      final stream = dataSource.watchOffersForOrder('order-test-123');
      final emittedOffers = await stream.first;

      expect(emittedOffers.length, equals(1));
      expect(emittedOffers.first.id, equals('offer-99'));
      expect(emittedOffers.first.quotedPriceCfa, equals(2500));
    });

    test('submitQuote inserts payload to pharmacy_quotes table', () async {
      final offer = PharmacyOffer(
        id: 'offer-1',
        pharmacyId: 'pharma-soleil',
        pharmacyName: 'Pharmacie du Soleil',
        quarter: 'Warda',
        distanceKm: 0.5,
        phone: '+237 671112233',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 3200,
        submittedAt: DateTime.now(),
      );

      when(() => mockSupabase.from('pharmacy_quotes')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any<Map<String, dynamic>>())).thenAnswer(
        (_) => FakePostgrestFilterBuilder<dynamic>(<String, dynamic>{}),
      );

      await expectLater(
        dataSource.submitQuote(offer, 'order-target-1'),
        completes,
      );

      verify(() => mockQueryBuilder.insert(any<Map<String, dynamic>>())).called(1);
    });

    test(
      'updateOrderStatus updates flash_orders table with status and selected offer',
      () async {
        when(() => mockSupabase.from('flash_orders')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any<Map<String, dynamic>>())).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(<dynamic>[]),
        );

        await expectLater(
          dataSource.updateOrderStatus(
            'order-123',
            FlashOrderStatus.accepted,
          ),
          completes,
        );

        verify(() => mockQueryBuilder.update(any<Map<String, dynamic>>())).called(1);
      },
    );
  });
}

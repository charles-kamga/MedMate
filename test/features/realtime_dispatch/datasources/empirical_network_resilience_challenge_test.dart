import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/adaptive_polling_fallback_manager.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/supabase_realtime_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  MockPostgrestFilterBuilder(this._data);
  final dynamic _data;

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
    return MockPostgrestTransformBuilder<T>(_data);
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    final val = _data is List && _data.isNotEmpty
        ? _data.first as PostgrestMap?
        : (_data is Map ? _data as PostgrestMap? : null);
    return MockPostgrestTransformBuilder<PostgrestMap?>(val);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future<T>.value(_data as T).then(onValue, onError: onError);
  }
}

class MockPostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  MockPostgrestTransformBuilder(this._data);
  final dynamic _data;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future<T>.value(_data as T).then(onValue, onError: onError);
  }
}

class FailingPostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
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
    return FailingPostgrestTransformBuilder<T>();
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return FailingPostgrestTransformBuilder<PostgrestMap?>();
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future<T>.error(const SocketException('3G connection lost in Yaoundé')).then(onValue, onError: onError);
  }
}

class FailingPostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return Future<T>.error(const SocketException('3G connection lost in Yaoundé')).then(onValue, onError: onError);
  }
}

class SocketException implements Exception {
  const SocketException(this.message);
  final String message;
  @override
  String toString() => 'SocketException: $message';
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockRealtimeChannel mockChannel;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late AdaptivePollingFallbackManager fallbackManager;
  late SupabaseRealtimeDataSourceImpl dataSource;
  void Function(RealtimeSubscribeStatus status, [Object? error])? subscribeCallback;

  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(MockRealtimeChannel());
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockChannel = MockRealtimeChannel();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    fallbackManager = AdaptivePollingFallbackManager(
      defaultPollingInterval: const Duration(seconds: 10),
      maxPollingInterval: const Duration(seconds: 60),
      backoffMultiplier: 1.5,
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
    when(() => mockChannel.subscribe(any())).thenAnswer((invocation) {
      subscribeCallback = invocation.positionalArguments[0] as void Function(RealtimeSubscribeStatus, [Object?])?;
      return mockChannel;
    });

    when(() => mockSupabase.from(any())).thenAnswer((_) => mockQueryBuilder);

    dataSource = SupabaseRealtimeDataSourceImpl(
      supabaseClient: mockSupabase,
      fallbackManager: fallbackManager,
    );
  });

  tearDown(() {
    dataSource.dispose();
  });

  group('Empirical Challenge - Network Resilience & Offline Polling', () {
    test('CHALLENGE 1 [VERIFIED]: executeAllPollingTasks applies exponential backoff on pollAction error', () async {
      when(() => mockQueryBuilder.select()).thenAnswer(
        (_) => FailingPostgrestFilterBuilder<PostgrestList>(),
      );

      final stream = dataSource.watchPendingOrdersForPharmacy('pharma_obili');
      final sub = stream.listen((_) {});
      
      expect(fallbackManager.currentPollingInterval, equals(const Duration(seconds: 10)));
      expect(fallbackManager.activeTaskCount, equals(1));

      // Network drops
      fallbackManager.markDisconnected();
      expect(fallbackManager.currentStatus, equals(RealtimeConnectionStatus.offlinePolling));

      // Polling task runs and network throws
      await fallbackManager.executeAllPollingTasks();

      // Expected exponential backoff: 10s * 1.5 = 15s.
      final actualInterval = fallbackManager.currentPollingInterval;
      
      expect(
        actualInterval,
        equals(const Duration(seconds: 15)),
        reason: 'Confirmed fix: backoff advances to 15s when polling fails',
      );

      await sub.cancel();
    });

    test('CHALLENGE 2 [VERIFIED]: Reconnection via RealtimeSubscribeStatus.subscribed triggers resync fetch', () async {
      var fetchCount = 0;
      when(() => mockQueryBuilder.select()).thenAnswer((_) {
        fetchCount++;
        return MockPostgrestFilterBuilder<PostgrestList>(<PostgrestMap>[]);
      });

      final stream = dataSource.watchPendingOrdersForPharmacy('pharma_warda');
      final sub = stream.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // Initial fetch occurred
      expect(fetchCount, equals(1));

      // Simulate network disconnect
      subscribeCallback?.call(RealtimeSubscribeStatus.channelError, 'Connection reset');
      expect(fallbackManager.currentStatus, equals(RealtimeConnectionStatus.offlinePolling));

      // Now network is restored and WebSocket reconnects
      subscribeCallback?.call(RealtimeSubscribeStatus.subscribed);
      expect(fallbackManager.currentStatus, equals(RealtimeConnectionStatus.connected));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Resync fetch was triggered on reconnection
      expect(
        fetchCount,
        equals(2),
        reason: 'Confirmed fix: on reconnection, fresh resync fetch is triggered',
      );

      await sub.cancel();
    });

    test('CHALLENGE 3 [VERIFIED]: Cancelling stream unsubscribes and removes RealtimeChannel', () async {
      when(() => mockQueryBuilder.select()).thenAnswer(
        (_) => MockPostgrestFilterBuilder<PostgrestList>(<PostgrestMap>[]),
      );

      final sub1 = dataSource.watchPendingOrdersForPharmacy('pharma_bastos').listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Cancel subscription
      await sub1.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Channel was properly removed from Supabase client
      verify(() => mockSupabase.removeChannel(any())).called(1);

      // Listening again creates a clean new channel
      final sub2 = dataSource.watchPendingOrdersForPharmacy('pharma_bastos').listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => mockSupabase.channel('public:flash_orders:pharma_bastos')).called(2);

      await sub2.cancel();
    });

    test('VERIFICATION OF BACKOFF SPEC: 10s default with 1.5x backoff capped at 60s when reportPollingError is called', () {
      final mgr = AdaptivePollingFallbackManager(
        defaultPollingInterval: const Duration(seconds: 10),
        maxPollingInterval: const Duration(seconds: 60),
        backoffMultiplier: 1.5,
      );

      expect(mgr.currentPollingInterval, equals(const Duration(seconds: 10)));

      // Step 1: 10 * 1.5 = 15s
      mgr.reportPollingError();
      expect(mgr.currentPollingInterval, equals(const Duration(seconds: 15)));

      // Step 2: 15 * 1.5 = 22.5s
      mgr.reportPollingError();
      expect(mgr.currentPollingInterval, equals(const Duration(milliseconds: 22500)));

      // Step 3: 22.5 * 1.5 = 33.75s
      mgr.reportPollingError();
      expect(mgr.currentPollingInterval, equals(const Duration(milliseconds: 33750)));

      // Step 4: 33.75 * 1.5 = 50.625s
      mgr.reportPollingError();
      expect(mgr.currentPollingInterval, equals(const Duration(milliseconds: 50625)));

      // Step 5: 50.625 * 1.5 = 75.9375s -> capped at 60s
      mgr.reportPollingError();
      expect(mgr.currentPollingInterval, equals(const Duration(seconds: 60)));

      // Success resets to 10s
      mgr.reportPollingSuccess();
      expect(mgr.currentPollingInterval, equals(const Duration(seconds: 10)));

      mgr.dispose();
    });
  });
}

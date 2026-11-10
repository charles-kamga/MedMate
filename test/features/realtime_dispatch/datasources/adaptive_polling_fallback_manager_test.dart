import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/adaptive_polling_fallback_manager.dart';

void main() {
  late AdaptivePollingFallbackManager manager;

  setUp(() {
    manager = AdaptivePollingFallbackManager(
      defaultPollingInterval: const Duration(seconds: 10),
      maxPollingInterval: const Duration(seconds: 60),
      backoffMultiplier: 1.5,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  group('AdaptivePollingFallbackManager Tests', () {
    test('Initial state is connected with default interval', () {
      expect(manager.currentStatus, equals(RealtimeConnectionStatus.connected));
      expect(manager.currentPollingInterval, equals(const Duration(seconds: 10)));
      expect(manager.activeTaskCount, equals(0));
    });

    test('Status stream reflects transitions to reconnecting and offlinePolling', () async {
      final statuses = <RealtimeConnectionStatus>[];
      final sub = manager.statusStream.listen(statuses.add);

      manager
        ..markReconnecting()
        ..markDisconnected()
        ..markConnected();

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(statuses, contains(RealtimeConnectionStatus.reconnecting));
      expect(statuses, contains(RealtimeConnectionStatus.offlinePolling));
      expect(statuses, contains(RealtimeConnectionStatus.connected));
      expect(manager.currentStatus, equals(RealtimeConnectionStatus.connected));

      await sub.cancel();
    });

    test('Exponential backoff increases interval up to maxPollingInterval on errors', () {
      expect(manager.currentPollingInterval, equals(const Duration(seconds: 10)));

      manager
        ..reportPollingError()
        ..reportPollingError();
      expect(manager.currentPollingInterval, equals(const Duration(milliseconds: 22500)));

      // Répéter jusqu'à saturation au max (60s)
      for (var i = 0; i < 10; i++) {
        manager.reportPollingError();
      }
      expect(manager.currentPollingInterval, equals(const Duration(seconds: 60)));

      // Succès réinitialise immédiatement au default (10s)
      manager.reportPollingSuccess();
      expect(manager.currentPollingInterval, equals(const Duration(seconds: 10)));
    });

    test('registerPollingTask and unregisterPollingTask manage task registry', () {
      var polled = false;
      manager.registerPollingTask(
        id: 'test_task',
        pollAction: () async {
          polled = true;
        },
      );

      expect(manager.activeTaskCount, equals(1));

      manager.unregisterPollingTask('test_task');
      expect(manager.activeTaskCount, equals(0));
      expect(polled, isFalse);
    });

    test('executeAllPollingTasks runs registered tasks and catches exceptions gracefully', () async {
      var task1Ran = false;
      var task2Ran = false;

      manager
        ..registerPollingTask(
          id: 'task1',
          pollAction: () async {
            task1Ran = true;
          },
        )
        ..registerPollingTask(
          id: 'task2_with_error',
          pollAction: () async {
            task2Ran = true;
            throw Exception('3G EDGE Network loss in Yaoundé');
          },
        );

      // Ne doit lancer AUCUN crash
      await expectLater(manager.executeAllPollingTasks(), completes);

      expect(task1Ran, isTrue);
      expect(task2Ran, isTrue);
    });
  });
}

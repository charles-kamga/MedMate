import 'dart:async';

/// Statuts possibles de connectivité pour le gestionnaire de synchronisation
enum RealtimeConnectionStatus {
  /// Connecté en temps réel via WebSocket (Supabase Realtime)
  connected,

  /// En cours de reconnexion / négociation de socket
  reconnecting,

  /// Déconnecté - Mode dégradé actif avec polling périodique (3G/EDGE Yaoundé)
  offlinePolling,
}

/// Gestionnaire de résilience réseau et de bascule adaptative en polling (Fallback 3G/EDGE)
/// Détecte les ruptures de socket WebSocket et enclenche un polling périodique
/// avec backoff exponentiel pour garantir la continuité de service sans crash.
class AdaptivePollingFallbackManager {
  AdaptivePollingFallbackManager({
    this.defaultPollingInterval = const Duration(seconds: 10),
    this.maxPollingInterval = const Duration(seconds: 60),
    this.backoffMultiplier = 1.5,
  }) {
    _currentPollingInterval = defaultPollingInterval;
    _statusController = StreamController<RealtimeConnectionStatus>.broadcast();
    _statusController.add(_currentStatus);
  }

  final Duration defaultPollingInterval;
  final Duration maxPollingInterval;
  final double backoffMultiplier;

  late final StreamController<RealtimeConnectionStatus> _statusController;
  RealtimeConnectionStatus _currentStatus = RealtimeConnectionStatus.connected;
  late Duration _currentPollingInterval;
  Timer? _pollingTimer;

  final Map<String, Future<void> Function()> _activePollingTasks = {};

  /// Flux diffusant les transitions d'état de connectivité
  Stream<RealtimeConnectionStatus> get statusStream => _statusController.stream;

  /// Statut courant de la connexion
  RealtimeConnectionStatus get currentStatus => _currentStatus;

  /// Intervalle actuel appliqué au polling
  Duration get currentPollingInterval => _currentPollingInterval;

  /// Nombre de tâches de polling actives
  int get activeTaskCount => _activePollingTasks.length;

  /// Enregistre une tâche périodique de secours
  void registerPollingTask({
    required String id,
    required Future<void> Function() pollAction,
  }) {
    _activePollingTasks[id] = pollAction;
    if (_currentStatus == RealtimeConnectionStatus.offlinePolling &&
        (_pollingTimer == null || !_pollingTimer!.isActive)) {
      _scheduleNextPoll();
    }
  }

  /// Retire une tâche de polling
  void unregisterPollingTask(String id) {
    _activePollingTasks.remove(id);
    if (_activePollingTasks.isEmpty) {
      _stopPollingTimer();
    }
  }

  /// Signale que le WebSocket est connecté et opérationnel
  void markConnected() {
    _currentStatus = RealtimeConnectionStatus.connected;
    _currentPollingInterval = defaultPollingInterval;
    _stopPollingTimer();
    _notifyStatus();
  }

  /// Signale une perte momentanée de socket et une tentative de reconnexion
  void markReconnecting() {
    if (_currentStatus != RealtimeConnectionStatus.reconnecting) {
      _currentStatus = RealtimeConnectionStatus.reconnecting;
      _notifyStatus();
    }
  }

  /// Signale un échec de connexion ou une déconnexion prolongée (bascule en polling)
  void markDisconnected() {
    if (_currentStatus != RealtimeConnectionStatus.offlinePolling) {
      _currentStatus = RealtimeConnectionStatus.offlinePolling;
      _notifyStatus();
      _scheduleNextPoll();
    }
  }

  /// Notifie un succès lors d'un tour de polling (réinitialise le backoff)
  void reportPollingSuccess() {
    _currentPollingInterval = defaultPollingInterval;
  }

  /// Notifie un échec lors d'un tour de polling (applique le backoff exponentiel)
  void reportPollingError() {
    final nextMs = (_currentPollingInterval.inMilliseconds * backoffMultiplier).round();
    if (nextMs >= maxPollingInterval.inMilliseconds) {
      _currentPollingInterval = maxPollingInterval;
    } else {
      _currentPollingInterval = Duration(milliseconds: nextMs);
    }
  }

  /// Force l'exécution immédiate de toutes les tâches de polling enregistrées
  Future<void> executeAllPollingTasks() async {
    for (final action in _activePollingTasks.values) {
      try {
        await action();
        reportPollingSuccess();
      } catch (_) {
        reportPollingError();
      }
    }
  }

  void _scheduleNextPoll() {
    _stopPollingTimer();
    if (_activePollingTasks.isEmpty) return;

    _pollingTimer = Timer(_currentPollingInterval, () async {
      await executeAllPollingTasks();
      if (_currentStatus == RealtimeConnectionStatus.offlinePolling) {
        _scheduleNextPoll();
      }
    });
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _notifyStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
  }

  /// Libère les ressources
  void dispose() {
    _stopPollingTimer();
    _activePollingTasks.clear();
    _statusController.close();
  }
}

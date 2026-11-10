import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../features/flash_order/domain/entities/flash_order.dart';
import '../../../../features/flash_order/domain/entities/pharmacy_offer.dart';
import '../models/flash_order_dto.dart';
import '../models/pharmacy_offer_dto.dart';
import 'adaptive_polling_fallback_manager.dart';

/// Contrat de la datasource temps réel Supabase avec résilience offline
abstract class SupabaseRealtimeDataSource {
  /// Écoute en continu les commandes en attente assignées ou éligibles pour l'officine
  Stream<List<FlashOrder>> watchPendingOrdersForPharmacy(String pharmacyId);

  /// Écoute en direct l'évolution d'une commande flash (vagues, devis, sélection, statut)
  Stream<FlashOrder> watchFlashOrder(String orderId);

  /// Écoute en direct l'arrivée des devis officinaux pour une commande donnée
  Stream<List<PharmacyOffer>> watchOffersForOrder(String orderId);

  /// Soumet une offre officielle de prix et disponibilité au nom d'une officine
  Future<void> submitQuote(PharmacyOffer offer, String orderId);

  /// Met à jour le statut global d'une commande flash
  Future<void> updateOrderStatus(
    String orderId,
    FlashOrderStatus status, {
    PharmacyOffer? selectedOffer,
  });

  /// Accès au gestionnaire de bascule adaptative
  AdaptivePollingFallbackManager get fallbackManager;

  /// Libère les souscriptions et ressources
  void dispose();
}

/// Implémentation concrète de [SupabaseRealtimeDataSource] connectée à Supabase
class SupabaseRealtimeDataSourceImpl implements SupabaseRealtimeDataSource {
  SupabaseRealtimeDataSourceImpl({
    required this.supabaseClient,
    required this.fallbackManager,
  });

  final SupabaseClient supabaseClient;
  @override
  final AdaptivePollingFallbackManager fallbackManager;

  final Map<String, StreamController<dynamic>> _streamControllers = {};
  final List<RealtimeChannel> _activeChannels = [];

  @override
  Stream<List<FlashOrder>> watchPendingOrdersForPharmacy(String pharmacyId) {
    final key = 'pharmacy_inbox_$pharmacyId';
    if (_streamControllers.containsKey(key)) {
      return (_streamControllers[key]! as StreamController<List<FlashOrder>>).stream;
    }

    final controller = StreamController<List<FlashOrder>>.broadcast();
    _streamControllers[key] = controller;

    // Récupération initiale et polling fallback
    Future<void> fetchPending() async {
      try {
        final data = await supabaseClient
            .from('flash_orders')
            .select()
            .inFilter('status', [
              FlashOrderStatus.dispatchingWave.name,
              FlashOrderStatus.offersReceived.name,
            ])
            .order('created_at', ascending: false);

        final orders = (data as List<dynamic>)
            .map((e) => FlashOrderDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((order) {
              if (order.targets.isEmpty) return true;
              return order.targets.any((t) => t.id == pharmacyId);
            })
            .toList();

        if (!controller.isClosed) controller.add(orders);
      } catch (e) {
        rethrow;
      }
    }

    fallbackManager.registerPollingTask(id: key, pollAction: fetchPending);
    fetchPending().ignore();

    RealtimeChannel? channel;
    // Écoute Supabase Realtime Channel
    try {
      final chan = supabaseClient.channel('public:flash_orders:$pharmacyId');
      chan
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'flash_orders',
            callback: (payload) {
              fallbackManager.markConnected();
              fetchPending().ignore();
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              fallbackManager.markConnected();
              fetchPending().ignore();
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              fallbackManager.markDisconnected();
            }
          });
      _activeChannels.add(chan);
      channel = chan;
    } catch (_) {
      fallbackManager.markDisconnected();
    }

    controller.onCancel = () {
      fallbackManager.unregisterPollingTask(key);
      _streamControllers.remove(key);
      if (channel != null) {
        _activeChannels.remove(channel);
        try {
          supabaseClient.removeChannel(channel);
        } catch (_) {}
      }
      controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<FlashOrder> watchFlashOrder(String orderId) {
    final key = 'order_$orderId';
    if (_streamControllers.containsKey(key)) {
      return (_streamControllers[key]! as StreamController<FlashOrder>).stream;
    }

    final controller = StreamController<FlashOrder>.broadcast();
    _streamControllers[key] = controller;

    Future<void> fetchOrder() async {
      try {
        final data = await supabaseClient
            .from('flash_orders')
            .select()
            .eq('id', orderId)
            .maybeSingle();

        if (data != null) {
          final order = FlashOrderDto.fromJson(Map<String, dynamic>.from(data));
          if (!controller.isClosed) controller.add(order);
        }
      } catch (e) {
        rethrow;
      }
    }

    fallbackManager.registerPollingTask(id: key, pollAction: fetchOrder);
    fetchOrder().ignore();

    RealtimeChannel? channel;
    try {
      final chan = supabaseClient.channel('public:flash_orders:id=eq.$orderId');
      chan
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'flash_orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: orderId,
            ),
            callback: (payload) {
              fallbackManager.markConnected();
              fetchOrder().ignore();
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              fallbackManager.markConnected();
              fetchOrder().ignore();
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              fallbackManager.markDisconnected();
            }
          });
      _activeChannels.add(chan);
      channel = chan;
    } catch (_) {
      fallbackManager.markDisconnected();
    }

    controller.onCancel = () {
      fallbackManager.unregisterPollingTask(key);
      _streamControllers.remove(key);
      if (channel != null) {
        _activeChannels.remove(channel);
        try {
          supabaseClient.removeChannel(channel);
        } catch (_) {}
      }
      controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<List<PharmacyOffer>> watchOffersForOrder(String orderId) {
    final key = 'offers_$orderId';
    if (_streamControllers.containsKey(key)) {
      return (_streamControllers[key]! as StreamController<List<PharmacyOffer>>).stream;
    }

    final controller = StreamController<List<PharmacyOffer>>.broadcast();
    _streamControllers[key] = controller;

    Future<void> fetchOffers() async {
      try {
        final data = await supabaseClient
            .from('pharmacy_quotes')
            .select()
            .eq('order_id', orderId)
            .order('submitted_at', ascending: false);

        final offers = (data as List<dynamic>)
            .map((e) => PharmacyOfferDto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        if (!controller.isClosed) controller.add(offers);
      } catch (e) {
        rethrow;
      }
    }

    fallbackManager.registerPollingTask(id: key, pollAction: fetchOffers);
    fetchOffers().ignore();

    RealtimeChannel? channel;
    try {
      final chan = supabaseClient.channel('public:pharmacy_quotes:order_id=eq.$orderId');
      chan
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'pharmacy_quotes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'order_id',
              value: orderId,
            ),
            callback: (payload) {
              fallbackManager.markConnected();
              fetchOffers().ignore();
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              fallbackManager.markConnected();
              fetchOffers().ignore();
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              fallbackManager.markDisconnected();
            }
          });
      _activeChannels.add(chan);
      channel = chan;
    } catch (_) {
      fallbackManager.markDisconnected();
    }

    controller.onCancel = () {
      fallbackManager.unregisterPollingTask(key);
      _streamControllers.remove(key);
      if (channel != null) {
        _activeChannels.remove(channel);
        try {
          supabaseClient.removeChannel(channel);
        } catch (_) {}
      }
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> submitQuote(PharmacyOffer offer, String orderId) async {
    try {
      final payload = PharmacyOfferDto.toJson(offer);
      payload['order_id'] = orderId;
      await supabaseClient.from('pharmacy_quotes').insert(payload);
    } catch (e) {
      throw ServerException('Échec lors de la soumission du devis: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    FlashOrderStatus status, {
    PharmacyOffer? selectedOffer,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status.name,
      };
      if (selectedOffer != null) {
        payload['selected_offer_id'] = selectedOffer.id;
        payload['selected_offer'] = PharmacyOfferDto.toJson(selectedOffer);
      }
      await supabaseClient
          .from('flash_orders')
          .update(payload)
          .eq('id', orderId);
    } catch (e) {
      throw ServerException('Échec de mise à jour du statut de commande: $e');
    }
  }

  @override
  void dispose() {
    for (final channel in _activeChannels) {
      try {
        supabaseClient.removeChannel(channel);
      } catch (_) {}
    }
    _activeChannels.clear();

    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _streamControllers.clear();
    fallbackManager.dispose();
  }
}

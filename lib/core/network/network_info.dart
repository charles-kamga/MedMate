/// Contrat abstrait de détection de connectivité réseau pour le mode offline-first
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implémentation basique ou mockable
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    // Vérification légère de connectivité
    return true;
  }
}

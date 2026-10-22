# Coding Standards & Rigueur Technique (MedMate)

Ce document dicte les standards de programmation non négociables pour l'ensemble du code de l'application MedMate (Flutter / Dart / Supabase).

---

## 1. Typage & Null-Safety Absolue

### 1.1 Règle du Zéro `dynamic`
- **Interdiction formelle** de `dynamic`, `Object?` non casté et de toute forme de typage lâche.
- Tous les types de retour, paramètres de fonctions et variables d'état doivent être explicitement annotés ou déduits avec certitude par le compilateur.
- Lors de la désérialisation de données JSON brutes, valider immédiatement la structure via des DTOs typés ; ne jamais propager de `Map<String, dynamic>` dans le domaine ou la présentation.

```dart
// ❌ INTERDIT
Future<dynamic> fetchStock(id) async { ... }
final data = jsonDecode(response.body);
print(data['price']);

// ✅ OBLIGATOIRE
Future<Result<PharmacyStock, StockFailure>> fetchStock(PharmacyId id) async { ... }
final json = jsonDecode(response.body) as Map<String, dynamic>;
final dto = PharmacyStockDto.fromJson(json);
```

### 1.2 Modèles Immuables (Freezed)
- Toute entité de domaine, DTO et état d'interface doit être une classe immuable générée via `freezed` et `json_serializable`.
- Pas de mutation d'état en place (`x.property = value` banni). Utiliser exclusivement `.copyWith(...)`.

```dart
@freezed
class PharmacyStock with _$PharmacyStock {
  const factory PharmacyStock({
    required StockId id,
    required MedicationId medicationId,
    required PharmacyId pharmacyId,
    required int availableUnits,
    required Money unitPrice,
    required DateTime updatedAt,
  }) = _PharmacyStock;

  factory PharmacyStock.fromJson(Map<String, dynamic> json) =>
      _$PharmacyStockFromJson(json);
}
```

---

## 2. Gestion des Erreurs et Traitement Explicite

### 2.1 Pattern `Result` / `Either`
- Toute fonction pouvant échouer (accès réseau, base de données, capteur GPS, parsing) DOIT renvoyer un type explicite encapsulant le succès ou l'échec : `Either<Failure, T>` (via `fpdart`) ou un type scellé `Result<T, Failure>`.
- Ne jamais utiliser d'exceptions non gérées pour contrôler le flux métier. Les exceptions techniques doivent être capturées au niveau de la source de données (`data layer`) et traduites en `Failure` du domaine.

```dart
// Définition scellée des échecs du domaine
sealed class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure() : super('Stock insuffisant dans cette officine.');
}
```

### 2.2 Proscription des `catch` Silencieux
- **Interdiction totale** des blocs `catch (e) {}` vides ou qui se contentent d'un `print()`.
- Tout échec technique doit être :
  1. Journalisé avec un logger structuré (sans exposer de PII / données de santé).
  2. Mappé vers une `Failure` explicite.
  3. Propagé pour informer l'utilisateur avec un message clair et exploitable.

---

## 3. Résilience Réseau & Stratégie Offline-First (Contexte Cameroun / 3G)

### 3.1 Cache Local SQLite Chiffré (SQLCipher)
- Le stockage local (pharmacies de garde, repères de Yaoundé, historique des consultations récentes) s'effectue dans une base SQLite chiffrée via `SQLCipher` (`sqflite_sqlcipher` ou `drift` avec backend chiffré).
- La clé de déchiffrement locale est conservée dans le secure storage de l'OS (`flutter_secure_storage` avec Keystore Android / Keychain iOS).

### 3.2 File d'Attente Sortante Idempotente (Outbox Pattern)
- En cas de déconnexion ou de basculement sur réseau dégradé (2G/3G instable à Yaoundé) :
  - Les requêtes d'action (ex: réservation de médicament) reçoivent un `client_generated_id` (UUID v4).
  - L'action est persistée dans une table locale `outbox_mutations` avec état `pending`.
  - Un gestionnaire de synchronisation en arrière-plan dépile la file d'attente dès le rétablissement de la connectivité.
  - Supabase gère l'idempotence via contrainte d'unicité sur `client_generated_id`.

### 3.3 Timeouts Ajustés et Exponential Backoff avec Jitter
- Configurer les timeouts HTTP/WebSocket à **10 secondes maximum** (au lieu des 30 à 60 secondes par défaut) pour éviter le blocage des threads UI et libérer rapidement les sockets sur réseau instable.
- En cas d'échec de connectivité, appliquer un réessai avec backoff exponentiel et gigue aléatoire (*jitter*) :
  $$\text{Delay} = \min(30s, 2^{\text{attempt}} \times 1s + \text{random}(0, 1s))$$
- Ne jamais déclencher de boucles de rafraîchissement agressives qui satureraient la bande passante du patient.

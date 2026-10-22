# Stratégie de Tests & Contrôle Continu (MedMate)

Ce document formalise les critères d'exigence relatifs aux tests automatisés et à la validation continue de la qualité logicielle pour MedMate.

---

## 1. Pyramide des Tests

```text
       /\
      /  \     10% Tests UI / Widgets (Vérification des flux critiques)
     /----\
    /      \   20% Tests d'Intégration (Supabase, RLS, Cache SQLite)
   /--------\
  /          \ 70% Tests Unitaires (Domain, UseCases, Mappers, Round-Robin)
 /------------\
```

### 1.1 Tests Unitaires (Cœur Métier & Domaine) — Priorité 1
- **100% de couverture obligatoire** sur la couche `domain/` :
  - Tous les `UseCases` (ex. `SearchMedicationUseCase`, `RequestReservationUseCase`, `CalculateFairDispatchUseCase`).
  - L'algorithme de dispatch équitable (*Round-Robin* des officines).
  - Le calcul des distances topologiques et affectations de quartiers.
  - La sérialisation/désérialisation des entités `freezed`.
- Les tests unitaires doivent s'exécuter en moins de quelques secondes, en isolation totale de toute base de données ou réseau réel.

```dart
// Exemple de test unitaire sur un UseCase avec mocktail
void main() {
  late MockPharmacyRepository mockRepository;
  late RequestReservationUseCase useCase;

  setUp(() {
    mockRepository = MockPharmacyRepository();
    useCase = RequestReservationUseCase(mockRepository);
  });

  test('doit retourner une Reservation valide lorsque le stock est disponible', () async {
    // Arrange
    when(() => mockRepository.reserveMedication(any(), any()))
        .thenAnswer((_) async => Right(tReservation));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, Right(tReservation));
    verify(() => mockRepository.reserveMedication(any(), any())).called(1);
  });
}
```

### 1.2 Tests d'Intégration (Supabase & RLS) — Priorité 2
- Chaque politique RLS sensible doit posséder un test d'intégration automatisé vérifiant :
  1. Qu'un utilisateur non authentifié (`anon`) se voit refuser l'accès aux données privées.
  2. Qu'un patient A ne peut pas lire ou modifier les réservations d'un patient B.
  3. Qu'une officine ne peut modifier que ses propres stocks et commandes.
- Tester la persistance et la réconciliation du cache local SQLite chiffré en simulant une coupure réseau puis une reconnexion.

### 1.3 Mocks Stricts des Services Tiers
- **Interdiction formelle** d'appeler des APIs externes payantes ou à effet de bord lors des tests automatisés :
  - Passerelle SMS locale camerounaise (ex. SMS Gateway / Campay / CinetPay) : utiliser une interface `SmsService` mockée.
  - Notifications Push (Firebase Cloud Messaging) : mockée via `NotificationService`.
  - Fournisseur de cartographie (Google Maps / OpenStreetMap) : mocké avec des coordonnées déterministes de Yaoundé.

---

## 2. Portes de Contrôle Continu (Quality Gates)

Avant de valider ou de soumettre toute modification de code :

### 2.1 Analyse Statique Zéro-Tolérance
- Exécuter impérativement :
  ```bash
  dart analyze --fatal-infos --fatal-warnings
  ```
- **Zéro avertissement (0 warning, 0 info)** toléré. Tout code provoquant un avertissement de linter doit être corrigé avant validation.

### 2.2 Exécution de la Suite de Tests
- Exécuter la suite complète de tests :
  ```bash
  flutter test --coverage
  ```
- Aucun test en échec n'est toléré. Les régressions doivent être traitées immédiatement.

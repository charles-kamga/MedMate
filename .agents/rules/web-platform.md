---
trigger: always_on
description: "Standards d'architecture, responsive design, routage URL, compatibilité navigateur et performance pour Flutter Web (Afya Santé / MedMate)"
---

# Plateforme Flutter Web & Responsive Design (Afya Santé / MedMate)

Ce document définit les règles techniques obligatoires pour garantir que **Afya Santé** fonctionne de manière irréprochable sur **Flutter Web** (navigateurs mobiles Android/iOS et postes de travail Desktop en pharmacie).

---

## 1. Responsive Design & Points de Rupture (Breakpoints)

L'application Web est utilisée dans deux contextes physiques distincts :
1. **Patient en mobilité à Yaoundé** : Smartphone (écran étroit `360px – 430px`, réseau 3G/4G variable).
2. **Pharmacien d'officine au comptoir** : Ordinateur portable ou poste fixe Desktop (`1280px – 1920px`).

### 1.1 Grille de Breakpoints Officielle
- **Compact (Mobile)** : `width < 600px` — Navigation par barre inférieure (`NavigationBar` à 4 onglets), affichage en colonne unique.
- **Medium (Tablette / Petit Laptop)** : `600px <= width < 1024px` — Conteneur centré contraint (`ConstrainedBox(maxWidth: 720)`) ou mise en page maître-détail à 2 colonnes.
- **Expanded (Desktop Comptoir)** : `width >= 1024px` — Mise en page multi-colonnes (liste des demandes + détail/carte côte à côte) ou centrage élégant avec largeur maximale contrôlée pour les flux de formulaire patient.

### 1.2 Interdiction des Dimensions Rigides
- Ne jamais coder de largeurs fixes (`width: 400`) susceptibles de provoquer un `RenderFlex overflowed` sur un écran de `320px` ou un étirement illisible sur un moniteur `1920px`.
- Utiliser `LayoutBuilder`, `MediaQuery.sizeOf(context)` (préféré à `MediaQuery.of(context).size` pour éviter les rebuilds inutiles), `Flexible`, `Expanded` et `Wrap`.

---

## 2. Isolation Plateforme & Interdiction de `dart:io`

### 2.1 Zéro `dart:io` Non Protégé
- **Règle absolue** : L'import direct de `dart:io` (`File`, `Directory`, `Platform.isAndroid`, `Socket`, `HttpClient`) fait planter la compilation **Flutter Web** (JS / WASM).
- Utiliser systématiquement `kIsWeb` (depuis `package:flutter/foundation.dart`) ou `defaultTargetPlatform` pour la détection de plateforme.
- Pour la sélection de photos d'ordonnances sur le Web et le Mobile, manipuler les fichiers sous forme d'octets en mémoire (`Uint8List` / `XFile.readAsBytes()`) et non via `io.File(path)`.

### 2.2 Permissions Navigateur & Géolocalisation Web
- Sur le Web, l'API Geolocation HTML5 exige un contexte sécurisé (**HTTPS** en production ou `localhost` en développement).
- L'utilisateur peut refuser ou bloquer la permission GPS dans son navigateur :
  - Tout appel à `geolocator` doit gérer explicitement le refus ou le timeout (`10s`) et basculer sans erreur bloquante vers le **sélecteur manuel de Quartier / Carrefour de Yaoundé** (*Bastos, Biyem-Assi, Essos, Mokolo, Nlongkak, Obili, Omnisports, Mendong...*).

---

## 3. Navigation Web, Historique & Liens Externes

- Respecter le comportement du bouton **Retour** du navigateur et la persistance d'état minimale lors du redimensionnement de la fenêtre.
- Pour les appels téléphoniques (`tel:+237...`) et l'ouverture d'itinéraires OpenStreetMap (`AppConfig.buildOsmSearchUrl(...)`) via `url_launcher` :
  - Utiliser `LaunchMode.platformDefault` sur le Web (ouvre un nouvel onglet pour les liens `https://` et délègue `tel:` au gestionnaire système) et vérifier systématiquement `canLaunchUrl` avec un `SnackBar` de repli affichant le numéro ou l'adresse copiables.

---

## 4. Performance Web, Bundle Size & Accessibilité

### 4.1 Optimisation Réseau (Contexte Cameroun)
- Éviter les dépendances lourdes inutiles qui gonflent `main.dart.js` / `main.dart.wasm`.
- Compresser tous les assets statiques et privilégier les icônes vectorielles (`Icons.*` Material) plutôt que des images matricielles lourdes.
- Configurer un `User-Agent` explicite (`AppConfig.osmUserAgent`) et le cache des tuiles sur `FlutterMap` pour éviter de re-télécharger les mêmes tuiles OpenStreetMap France.

### 4.2 Accessibilité Web (WCAG 2.2 AA)
- Les boutons d'action critiques (recherche de médicament, filtre pharmacie de garde, appel d'urgence, confirmation au comptoir) doivent :
  - Avoir une zone cliquable minimale de **48x48 px**.
  - Être navigables au clavier (`Tab`, `Enter`, `FocusNode`).
  - Fournir des labels sémantiques clairs pour les lecteurs d'écran et l'arbre d'accessibilité DOM.

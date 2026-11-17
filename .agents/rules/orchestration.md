# Orchestration Multi-Agents & Allocation des Modèles

Cette règle s'applique uniquement lorsqu'un agent orchestre une tâche complexe en déléguant à des sous-agents (`invoke_subagent`, y compris via `/teamwork`). Elle n'affecte pas les tâches simples exécutées par un agent unique et reste subordonnée à toute demande explicite de l'utilisateur dans son prompt.

---

## 1. Principe : Modèle Fort en Orchestration, Paliers Légers en Exécution

L'agent principal (orchestrateur) garde la responsabilité du cadrage, de l'architecture, du découpage en chantiers indépendants et de la validation finale. Il ne doit **pas** laisser `Model: "inherit"` par défaut sur tous les sous-agents lorsque cela n'est pas nécessaire.

## 2. Matrice de Sélection du Paramètre `Model` (`invoke_subagent`)

Lors de chaque appel à `invoke_subagent`, choisir explicitement le palier adapté au sous-objectif :

| Type de sous-tâche | Valeur `Model` à passer | Usage typique |
| :--- | :--- | :--- |
| **Exploration rapide & vérifications simples** | `flash_lite` | Recherche ciblée (`rg`, lecture de fichiers), inventaire de symboles, contrôles mécaniques (`wc -l`, grep de conformité). |
| **Implémentation & tests bien spécifiés** | `flash` | Écriture/édition de code à partir d'un plan clair, extraction de widgets, rédaction de tests unitaires/widgets, recherche approfondie. |
| **Raisonnement critique ou arbitrage complexe** | `inherit` (ou `pro`) | Décisions d'architecture ambiguës, audit sécurité/RLS sensible, débogage multi-couches difficile. |

## 3. Règles d'Hygiène d'Orchestration

- **Prompts autonomes** : Fournir à chaque sous-agent le périmètre exact de fichiers, les invariants (ex. `< 400` lignes, Clean Architecture, souveraineté OSM) et la commande de vérification attendue.
- **Zéro conflit d'écriture** : Attribuer des fichiers disjoints aux sous-agents parallèles, ou utiliser `Workspace: "branch"` / `"share"` lorsqu'ils modifient des zones qui peuvent se chevaucher.
- **Validation centrale** : L'orchestrateur vérifie lui-même les résultats agrégés avant de conclure (`dart analyze`, `flutter test`).

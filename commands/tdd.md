---
description: Délègue au sous-agent tdd-clean-coder pour écrire/modifier du code en TDD Uncle Bob strict (red → green → refactor) en respectant les boundaries de la clean architecture définies dans le CLAUDE.md du projet courant.
argument-hint: <ce qu'il faut implémenter ou modifier>
---

Délègue la tâche suivante au sous-agent `tdd-clean-coder` via le tool `Agent` (`subagent_type: "tdd-clean-coder"`).

## Tâche

$ARGUMENTS

## Rappels au sous-agent (à inclure dans le prompt de délégation)

1. **Lire d'abord `CLAUDE.md`** à la racine du projet pour connaître :
   - les boundaries de la clean architecture (quelles couches ne peuvent importer quoi),
   - la stack de test et la commande à exécuter (`npm run test`, `pnpm test`, autre),
   - toute autre convention spécifique au projet.
2. **Baseline** : lancer la suite de tests complète et capturer les tests actuellement verts. Refuser de travailler sur une base déjà rouge (signaler à l'utilisateur et stopper).
3. **Boucle** rouge → vert → refactor. Ce qui compte n'est pas l'ordre mais la **confrontation** : tout test doit avoir été vu échouer face à une implémentation fausse.
   - `[RED]` — écrire le ou les tests, les exécuter, **confirmer qu'ils échouent sur leur assertion** (pas sur un import manquant, qui ne prouve rien). **Batching recommandé** pour un ensemble cohérent : tous les tests rouges d'abord, rouge observé en bloc, puis l'implémentation.
   - `[GREEN]` — impl minimale qui rend vert. Relancer la suite complète.
   - `[REFACTOR]` — refactor si utile, suite doit rester verte. Sinon `[REFACTOR skipped]`.
   - Si un test **ne peut pas** naître rouge (filet sur du code déjà correct, réponse à un mutant) : le confronter par **sabotage** de la ligne que son nom désigne, observer le rouge, restaurer, et le déclarer. Saboter une ligne quelconque ne suffit pas.
4. **Anti test-tampering** : si un test hors périmètre passe de vert à rouge → **STOP**, sortir `[REGRESSION DETECTED] <test> — analyse : <hypothèse>` et demander à l'utilisateur (régression involontaire à réparer, ou rupture volontaire à formaliser). Jamais modifier de sa propre initiative un test qui était vert — sauf classe de rupture explicitement pré-autorisée par le `CLAUDE.md` du projet, auquel cas appliquer **et rapporter**.
5. **Frontières** : avant de fermer le cycle, grep les imports du fichier créé/modifié pour vérifier qu'aucune boundary déclarée dans `CLAUDE.md` n'est violée.

## Ton attendu

Sorties structurées, concises, avec les tags `[RED]`, `[GREEN]`, `[REFACTOR]`, `[REGRESSION DETECTED]`. Français si le projet est en français, anglais sinon. Pas de narration interne.

## Après le retour du sous-agent — vérification navigateur (features UI uniquement)

**Si la tâche a touché la couche UI du projet** (typiquement `src/ui/`, mais lire le `CLAUDE.md` pour la nomenclature locale), l'agent principal doit **impérativement** enchaîner sur une vérification navigateur via Chrome DevTools MCP :

1. S'assurer que le serveur de dev tourne (`npm run dev` en background sinon).
2. `mcp__chrome-devtools__navigate_page` vers la route concernée par la feature.
3. `mcp__chrome-devtools__take_screenshot` (résolution mobile si l'app est mobile-first — voir `CLAUDE.md`).
4. `mcp__chrome-devtools__list_console_messages` — aucune erreur autre que HMR/dev.
5. Si interaction requise (submit, click, navigation, drag) : `click` / `fill` / `press_key` puis re-screenshot pour valider l'état d'après.
6. **États non-nominaux** : le chemin nominal ne suffit pas. Vérifier explicitement les états pertinents — vide, erreur, chargement. Un état non pertinent est écarté explicitement, pas oublié.
7. **Sortie de chaque état non-nominal** : vérifier l'**entrée** dans un état ne suffit pas, il faut vérifier qu'on en **sort**. Rejouer le retour au nominal (rétablir le réseau, corriger la saisie, refermer/rouvrir, recharger) et confirmer que l'écran ne garde aucune trace : message résiduel, bouton verrouillé, liste périmée. Une liste d'états est un instantané ; les défauts vivent dans les **séquences**.
8. Screenshot final joint au report utilisateur.

**Si la tâche n'a touché que `domain/` ou `data/`** : pas de vérif Chrome (rien à afficher). Report des tests verts suffit.

## Si la vérif Chrome révèle un bug

Le bug est **une spec absente**, pas un accident. Cycle de recovery obligatoire :

1. **INTERDICTION** de cowboy fix (éditer le code sans passer par un test).
2. Formuler le bug comme un **nouveau test rouge** qui capture le comportement attendu (ex. *"le bouton X doit dispatcher Y quand cliqué"*, *"le composant Z doit afficher A quand l'état est B"*).
3. Redéléguer à `tdd-clean-coder` avec cette nouvelle spec (nouvelle invocation `/tdd` ou nouvel `Agent(subagent_type: "tdd-clean-coder")`).
4. Cycle TDD complet sur le nouveau test : baseline → RED → GREEN → REFACTOR.
5. Si un ancien test devient rouge : appliquer le protocole anti test-tampering.
6. Re-vérification Chrome. Boucler tant que Chrome n'est pas OK.

La Definition of Done n'est **pas** un état figé : la case "vérif Chrome OK" ne peut être cochée définitivement que sur le dernier état du code. Si Chrome décoche, la feature est ré-ouverte et les cases précédentes sont re-visitées.

## Rappel de gouvernance

Cette délégation est **obligatoire** pour toute écriture/modification de code productif dès lors que le projet déclare des boundaries clean archi + TDD dans son `CLAUDE.md`. Ne pas chercher de raccourci. La vérif Chrome post-TDD est **obligatoire** pour toute feature UI, sans exception.

# claude-tdd-kit

Un agent de discipline et trois slash commands pour [Claude Code](https://claude.com/claude-code), qui imposent le **TDD strict (Uncle Bob)** et des **frontières de clean architecture** sur tes projets.

L'idée : Claude code vite, et cède facilement à la facilité quand on lui demande une feature. Ce kit lui retire cette liberté. Aucune ligne d'implémentation n'est écrite sans un test rouge **observé** au préalable, et aucun test vert n'est modifié sans validation explicite.

## Ce que contient le kit

| | Rôle |
|---|---|
| **`tdd-clean-coder`** (agent) | Écrit le code productif. Boucle `[RED]` → `[GREEN]` → `[REFACTOR]` sans exception. Refuse d'implémenter avant un rouge observé, refuse le test-tampering, vérifie les imports contre les boundaries. |
| **`/tdd <tâche>`** | Délègue une tâche à l'agent, puis enchaîne sur une vérification navigateur si la tâche a touché l'UI. |
| **`/tdd-init`** | Bootstrappe la gouvernance dans un projet : audit de la stack, génération d'un `CLAUDE.md` (boundaries + règles TDD + anti test-tampering + Definition of Done), proposition des garde-fous techniques. |
| **`/verify <route>`** | Vérification navigateur ciblée via Chrome DevTools MCP : navigate + screenshot + erreurs console + interactions. Observation pure, aucune modification de code. |

## Les règles imposées

- **Ce qui compte n'est pas l'ordre, c'est la confrontation.** Un test n'a de valeur que s'il a été **vu échouer face à une implémentation fausse**. Écrire le test en premier est la façon la moins chère de l'obtenir — l'implémentation fausse est gratuite, c'est l'absence de code. Ce n'est pas la seule.
- **Batching recommandé.** Tous les tests rouges d'un ensemble cohérent, rouge observé en bloc, puis l'implémentation. Un cycle unitaire par comportement rejoue la suite complète à chaque pas sans rien apporter.
- **Quand un test ne peut pas naître rouge** (filet sur du code déjà correct, réponse à un mutant survivant), la confrontation se fait par **sabotage** : casser la ligne que le *nom* du test désigne, observer le rouge, restaurer. Saboter une ligne quelconque ne suffit pas — un test nommé « ne déverrouille pas le bouton » qui ne casse que sur une régression d'affichage est un faux filet.
- **Baseline obligatoire.** L'agent refuse de travailler sur une suite déjà rouge.
- **Anti test-tampering.** Un test vert qui devient rouge déclenche un `[REGRESSION DETECTED]` et un STOP. L'agent n'a jamais le droit de « réparer » le test de sa propre initiative — il te présente l'analyse et attend que tu tranches : régression involontaire, ou rupture volontaire à formaliser ? Un projet peut pré-autoriser une **classe précise** de rupture répétitive dans son `CLAUDE.md` (typiquement : ajouter un champ à un état casse tout `toEqual` exhaustif) ; l'agent applique alors **et rapporte**, au lieu de forcer un aller-retour dont l'arbitrage est toujours le même.
- **Un double ne promet jamais plus que son port.** Là où un port déclare une garantie *absente*, le test-double doit exercer activement cette absence. Un double plus aimable que son contrat est un faux vert qu'aucun test ne peut attraper.
- **Boundaries vérifiées par grep** avant de fermer chaque cycle, en plus du linter.
- **Un bug trouvé en vérif navigateur est une spec absente**, pas un accident : interdiction de cowboy fix, il repart en cycle TDD complet.

## Prérequis

- Claude Code.
- Pour `/verify` et la vérification UI de `/tdd` : le MCP [Chrome DevTools](https://github.com/ChromeDevTools/chrome-devtools-mcp). Sans lui, le reste du kit fonctionne, seule la partie navigateur est indisponible.

## Installation

```bash
git clone https://github.com/yasakura/claude-tdd-kit.git
cd claude-tdd-kit
./install.sh
```

Le script pose des **symlinks** dans `~/.claude/agents/` et `~/.claude/commands/` : un `git pull` suffit ensuite à mettre à jour toutes tes machines. Tout fichier de même nom déjà présent est sauvegardé en `.bak-<date>` avant d'être remplacé.

```bash
./install.sh --copy       # copies indépendantes plutôt que symlinks
./install.sh --uninstall  # retire uniquement ce que le kit a posé
```

Relance Claude Code après l'installation pour que `/tdd`, `/tdd-init` et `/verify` apparaissent.

## Utilisation

Dans un projet neuf ou existant :

```
/tdd-init
```

La commande audite la stack, te propose une architecture cible et écrit un `CLAUDE.md` — que tu valides avant écriture. C'est ce fichier qui devient la source de vérité : l'agent le relit à chaque invocation pour connaître tes couches, ta commande de test et tes interdits d'import.

Ensuite, pour tout code productif :

```
/tdd ajoute la validation du formulaire d'inscription
/verify /signup
```

## Agnostique de la stack

Rien n'est câblé sur un framework. `/tdd-init` détecte la stack et adapte le vocabulaire et les outils :

- **JS/TS** — `eslint-plugin-boundaries`, test d'archi Vitest/Jest, husky + lint-staged, seuils coverage, Stryker
- **Python** — `import-linter`, `pre-commit`, `pytest --cov-fail-under`, mutmut / cosmic-ray
- **Go** — `depguard`, targets Makefile, gremlins
- **Autre** — la commande te demande tes habitudes et s'y adapte

Les exemples d'imports interdits dans l'agent (React, Redux, Firebase, styled-components) sont des illustrations : c'est le `CLAUDE.md` de ton projet qui fait autorité, et l'agent le dit explicitement.

## Langue

Les prompts sont rédigés en français, et l'agent répond en français si le `CLAUDE.md` du projet est en français, en anglais sinon.

## Licence

MIT

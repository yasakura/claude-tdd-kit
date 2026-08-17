---
description: Bootstrap TDD strict + clean archi light dans un projet (nouveau ou existant). Audit du projet, génération d'un CLAUDE.md avec boundaries + règles TDD + anti test-tampering, proposition des garde-fous techniques (lint boundaries, seuils, test archi).
argument-hint: [optionnel : notes contextuelles ou chemin]
---

Tu bootstrappes la gouvernance **TDD strict + clean archi light** dans le projet courant. Cette commande est portable : elle doit s'adapter à toute stack (JS/TS, Python, Go, Rust, autre) et à tout état de projet (vierge, en cours, mature).

## Contexte optionnel fourni par l'utilisateur

$ARGUMENTS

## Workflow

### 1. Audit du projet (silencieux, en parallèle si possible)

- Manifest à la racine : `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / autre → identifie la stack, le framework UI éventuel, le test runner, la commande de test standard.
- `ls` racine + dossier source principal (`src/`, `lib/`, `app/`, module Python, …) → détecte la structure actuelle.
- Vérifie s'il existe déjà un `CLAUDE.md`.
- Vérifie s'il y a déjà un `.eslintrc*`, `import-linter.cfg`, ou équivalent.

### 2. Classification & décision (à valider avec l'utilisateur avant d'écrire)

Résume ta lecture à l'utilisateur puis identifie le cas :

- **Cas A — projet vierge ou sans structure claire** : le `CLAUDE.md` décrit l'archi **cible** (domain/data/ui ou équivalent), à respecter dès le premier code.
- **Cas B — projet existant avec structure déjà en place** : adapte les boundaries à la structure trouvée (ex. `packages/core`, `apps/web`, `myapp/models`). Le `CLAUDE.md` documente les règles pour **les futures modifications**, pas un refactor rétroactif immédiat.
- **Cas C — projet existant avec `CLAUDE.md`** : proposer un **merge ciblé** (jamais d'écrasement). Ajouter/mettre à jour les sections "Architecture" et "TDD" sans toucher au reste.

**Ne pas écrire tant que l'utilisateur n'a pas validé le cas identifié et l'archi cible.**

### 3. Rédaction du `CLAUDE.md`

Le fichier doit tenir sur un écran (au-delà = ignoré par le LLM). Ton impératif, non-négociable. Adapter les termes à la stack (ex. "modules" en Python, "packages" en Go).

Template à adapter :

```markdown
# <Nom du projet> — invariants projet

## Architecture (clean archi light)
- Couches : <couche métier pure> / <couche adaptateurs infra> / <couche UI ou API>.
  Exemple JS/TS : domain / data / ui.
  Exemple Python : domain / infrastructure / presentation.
- Interdits durs (enforced par <linter boundaries>) :
  - <couche pure>/ → <libs UI, DB, HTTP, ORM, framework>
  - <couche adaptateurs>/ → <libs UI, framework présentation>
- Tout contrat entre couches = un port (interface) dans <couche pure>/.

## TDD Uncle Bob (règle absolue)
- Toute ligne d'implémentation naît d'un test rouge. Jamais l'inverse.
- Pour toute écriture ou modification de code productif dans <dossier source>/,
  DÉLÉGUER au sous-agent `tdd-clean-coder` (`~/.claude/agents/`) ou utiliser
  la slash command `/tdd <tâche>`.

Ce qui compte n'est pas l'ORDRE, c'est la CONFRONTATION : un test n'a de valeur
que s'il a été vu échouer face à une implémentation fausse. Écrire le test en
premier est la façon la moins chère de l'obtenir, pas la seule.

- Batching autorisé et recommandé : tous les tests rouges d'un ensemble cohérent,
  rouge observé en bloc, puis l'implémentation.
- PAS D'ÉMERGENCE PAS À PAS. Faire naître le code par micro-cycles est une
  discipline humaine — elle empêche d'écrire plus vite qu'on ne réfléchit. Un
  agent écrit l'implémentation complète d'un seul tenant, puis refactore si utile.
  La contrainte n'est pas la TAILLE du pas, c'est que RIEN NE DÉPASSE LA SPEC :
  aucune ligne qu'aucun test du lot n'exige. Pas de garde défensif « au cas où »,
  pas de généralisation anticipée. Ce qu'aucun test ne demande est du code mort en
  puissance ; la mutation le révèle, et la réponse est de le supprimer, pas
  d'écrire un test pour le justifier.
- Quand un test ne peut pas naître rouge (filet sur du code correct, réponse à un
  mutant survivant) : confrontation par SABOTAGE de la ligne que le NOM du test
  désigne, rouge observé, restauration. Saboter une ligne quelconque ne suffit pas.

## Convention Test Doubles
Un double ne promet jamais plus que son port. Là où un port déclare une garantie
ABSENTE (ordre non garanti, unicité non garantie), le double doit exercer
activement cette absence — ordre délibérément différent de l'insertion, jamais
"par gentillesse". Un double plus aimable que son contrat est un faux vert
structurel : aucun test ne peut l'attraper, puisque c'est le référentiel qui ment.

## Tests
- <Couche pure> : <test runner> + adaptateurs in-memory.
- <Couche adaptateurs> : <test runner> + <émulateur / fixtures / testcontainers>.
- UI/API : <test lib> + <politique>.
- Mutation score sur <couche pure> ≥ <seuil> %.

## Anti test-tampering
Un test qui passe de vert à rouge suite à une modif de code productif n'est
JAMAIS modifié dans la même étape. Cycle obligatoire :
STOP → diagnostiquer → classifier (régression involontaire vs rupture volontaire)
→ présenter impact → décider avec l'utilisateur → agir. Toute modif de test
hors périmètre requiert une justification dans le message de commit.

## Definition of Done (checklist par feature)
- [ ] Tests rouges écrits en premier (vérifié : ils échouent)
- [ ] Impl minimale → vert
- [ ] Refactor si utile
- [ ] `<commande lint>` OK (boundaries)
- [ ] `<commande test>` OK (seuils coverage)
- [ ] `<commande mutation test>` OK (seuil mutation)
```

Remplacer chaque `<…>` par la valeur concrète du projet (détectée à l'étape 1 ou décidée avec l'utilisateur à l'étape 2).

### 4. Proposition des garde-fous techniques (couche 1, mécaniques)

Après avoir écrit le `CLAUDE.md`, propose (sans installer) les outils adaptés à la stack, un par un, avec validation utilisateur pour chacun :

- **JS/TS** :
  - `eslint-plugin-boundaries` (config + intégration ESLint).
  - Test d'architecture (script Vitest/Jest qui parcourt les fichiers de la couche pure et échoue si un import interdit apparaît — ceinture + bretelles avec ESLint).
  - `husky` + `lint-staged` pre-commit.
  - Seuils coverage dans la config du runner (Vitest / Jest).
  - `@stryker-mutator/core` si mutation testing souhaité.
- **Python** :
  - `import-linter` (équivalent boundaries).
  - `pre-commit` framework (hooks).
  - `pytest --cov-fail-under=<seuil>` dans `pyproject.toml`.
  - `mutmut` ou `cosmic-ray` pour mutation testing.
- **Go** :
  - `depguard` (linter d'imports).
  - Makefile targets pour tests + coverage floor.
  - `gremlins` pour mutation testing.
- **Autre stack** : demander à l'utilisateur ce qu'il a l'habitude d'utiliser et adapter.

Ne rien installer sans validation explicite pour chaque item.

### 5. Confirmation finale & prochaine étape

Récapitule :
- Ce qui a été écrit (`CLAUDE.md` créé/mis à jour, sections concernées).
- Ce qui reste à faire (installations, config lint, hooks, CI).

Propose la prochaine étape concrète :
> *Veux-tu qu'on écrive maintenant le premier test qui valide les boundaries elles-mêmes ? Ce test devient le canari : il échoue si un import interdit est introduit. Je délègue à `tdd-clean-coder`.*

## Règles générales

- **Ne pas écraser** un `CLAUDE.md` existant sans validation. Merger ciblément.
- **Ne pas installer** de dépendances sans validation utilisateur pour chaque item.
- **Ne pas modifier** le code source à ce stade : cette commande pose la GOUVERNANCE, pas le code. Le refactor rétroactif (si nécessaire) est un travail à part, à faire ensuite avec `/tdd`.
- **Si le projet a déjà des tests rouges** avant l'intervention : signaler à l'utilisateur avant d'écrire le `CLAUDE.md`. On ne bootstrappe pas la gouvernance sur une base rouge.
- **Adapter la terminologie** à la stack : le concept "clean archi" existe dans tous les langages, mais les noms de couches et les libs changent. Ne pas parachuter du vocabulaire React/Redux dans un projet Python.

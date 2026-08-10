---
description: Vérifie une route/page dans Chrome DevTools MCP (navigate + screenshot + console errors + interactions optionnelles). À utiliser à la demande pour vérifier une régression visuelle, valider un état après modif, ou tester un scénario user sans passer par un cycle TDD.
argument-hint: <route ou description de ce qu'il faut vérifier>
---

Vérification navigateur ciblée via Chrome DevTools MCP.

## Tâche

$ARGUMENTS

## Workflow

1. **Lire `CLAUDE.md`** à la racine du projet pour connaître :
   - la stack et l'URL/port du serveur de dev (par défaut Vite = `http://localhost:5173`),
   - si l'app est mobile-first (adapter la résolution du screenshot),
   - toute convention de vérification spécifique.

2. **S'assurer que le serveur de dev tourne** :
   - Si `npm run dev` (ou équivalent) ne tourne pas déjà en background dans cette session, le démarrer.
   - Attendre qu'il soit prêt (`until grep -q "ready" logfile; do sleep 0.3; done`).

3. **Naviguer et vérifier** :
   - `mcp__chrome-devtools__resize_page` si l'app est mobile-first (iPhone 393×852 portrait recommandé).
   - `mcp__chrome-devtools__navigate_page` vers la route demandée (ou racine si non précisée).
   - `mcp__chrome-devtools__take_screenshot` — attacher au report.
   - `mcp__chrome-devtools__list_console_messages` — signaler toute erreur autre que HMR/dev standard.
   - Si interaction demandée (submit, click, fill, navigation) : exécuter via `click` / `fill` / `press_key`, puis re-screenshot pour valider l'état après.

4. **Report structuré** :
   - Ce qui a été vérifié (route, résolution, interactions).
   - Screenshot final.
   - Statut console (OK / erreurs listées).
   - Verdict : conforme aux attentes ou non. Si non, décrire précisément ce qui cloche.

## Si la vérif révèle un bug

Le bug est **une spec absente**, pas un accident. **INTERDICTION** de le fixer directement dans le code.

1. Reformuler le bug comme un nouveau test rouge (ex. *"le bouton X doit dispatcher Y quand cliqué"*).
2. Déléguer à `tdd-clean-coder` via `/tdd <nouvelle spec>` ou `Agent(subagent_type: "tdd-clean-coder")`.
3. Cycle TDD complet : baseline → RED → GREEN → REFACTOR.
4. Re-vérification via `/verify` sur la même route.
5. Boucler tant que la vérif n'est pas OK.

## Règles

- **Pas de modification de code source** depuis cette commande — c'est une vérification pure.
- **Pas de commit** — c'est un outil d'observation.
- Si le serveur ne peut pas démarrer, signaler et stopper (ne pas essayer de fixer sans validation utilisateur).
- Si l'utilisateur demande une route qui n'existe pas dans le projet, signaler et lister les routes existantes.

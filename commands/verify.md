---
description: Vérifie une route/page dans Chrome DevTools MCP — nominal, états non-nominaux ET leurs sorties, console, mesures. Observation pure, aucune modification de code.
argument-hint: <route ou description de ce qu'il faut vérifier>
---

Vérification navigateur via Chrome DevTools MCP.

## Tâche

$ARGUMENTS

## Ce que cette vérification garantit

Les tests unitaires garantissent que **le code fait ce que le test dit**. Cette vérification garantit que **la feature fait ce que l'utilisateur voit**. Les deux sont requis, aucun ne remplace l'autre.

## Workflow

### 1. Cadrage

Lis `CLAUDE.md` : stack, URL du serveur de dev, résolution cible, conventions de vérification. **Si le projet déclare une cible mobile, la résolution n'est pas une recommandation** — vérifier une app mobile-only en 1280 px ne prouve rien de ce que l'utilisateur voit.

### 2. Serveur de dev

S'assurer qu'il tourne, le démarrer en background sinon, attendre qu'il soit prêt.

### 3. Chemin nominal

`resize_page` à la résolution cible, `navigate_page`, `take_screenshot`, `list_console_messages`. Aucune erreur console autre que HMR/dev.

### 4. États non-nominaux — le screenshot du chemin heureux ne suffit pas

Vérifier explicitement ceux qui sont pertinents pour l'écran : **vide** (collection sans données), **erreur** (échec de chargement ou de validation), **chargement** (indicateur d'attente). Un état non pertinent est **écarté explicitement dans le report**, pas oublié en silence.

### 5. Sortie de chaque état non-nominal — l'étape qu'on oublie

Vérifier l'**entrée** dans un état ne suffit pas : il faut vérifier qu'on en **sort**. Pour chaque état atteint, rejouer le retour au nominal — rétablir le réseau, corriger la saisie, refermer/rouvrir, recharger — et confirmer que l'écran ne garde **aucune trace** : message résiduel, bouton verrouillé, liste périmée, formulaire figé.

Une liste d'états est un instantané. **Les défauts vivent dans les séquences.**

### 6. Report

Ce qui a été vérifié (route, résolution, états, séquences de sortie), screenshot final, statut console, verdict. Si un état a été écarté, dire lequel et pourquoi.

## Techniques — apprises en se trompant

**Mesurer, pas regarder.** Un chevauchement de texte ou un débordement ne se prouve pas sur une capture. Comparer `scrollWidth` à `clientWidth`, lire les `getBoundingClientRect()`. Un défaut de mise en page trouvé à l'œil est une intuition ; mesuré, c'est un fait.

**Échantillonner, pas parier sur le timing.** Un état de chargement dure quelques centaines de millisecondes : une capture le rate presque toujours. Lire le DOM en boucle sur plusieurs frames et rapporter la transition observée.

**Ne pas contourner ce que l'utilisateur ne peut pas contourner.** Écrire dans un `<input disabled>` via le setter natif de `HTMLInputElement` *fonctionne* — et ne prouve rien, puisqu'un vrai utilisateur en est incapable. Si le test passe par un chemin qu'aucun humain ne peut emprunter, il ne teste rien. Préférer les outils d'interaction (`click`, `fill`, `press_key`) ; quand un script est nécessaire, se demander si le geste simulé est réellement possible.

**Choisir des données qui discriminent.** Vérifier un tri avec des noms déjà triés, une mise en page avec des libellés courts, une élision avec un mot qui commence par une consonne — autant de vérifications qui passent sans rien prouver. Choisir l'entrée qui *casserait* si le comportement était faux.

**Nettoyer derrière soi.** Une vérification qui écrit dans une base de dev doit supprimer ce qu'elle a créé, et le report doit le confirmer. Un jeu de données pollué fausse la vérification suivante.

## Si la vérification révèle un bug

C'est **une spec absente**, pas un accident. **INTERDICTION** de le corriger directement.

1. Reformuler le bug comme un **test rouge** qui capture le comportement attendu.
2. Déléguer à `tdd-clean-coder` (`/tdd <spec>`).
3. Cycle complet, puis **re-vérifier via `/verify`** sur la même route.
4. Boucler tant que la vérification n'est pas conforme.

La Definition of Done n'est pas un état figé : la case « vérif navigateur » ne se coche que sur le **dernier** état du code. Si elle se décoche, la feature est rouverte et les cases précédentes sont à revisiter.

## Règles

- **Aucune modification de code source** — c'est une observation.
- **Aucun commit.**
- Si le serveur ne démarre pas, signaler et stopper.
- Si la route demandée n'existe pas, signaler et lister celles qui existent.

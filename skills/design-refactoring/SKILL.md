---
name: design-refactoring
description: Simplifier la STRUCTURE d'un code qui marche : nommer le défaut avant la solution, chercher le motif connu, retirer plutôt qu'ajouter. Utiliser quand un code résiste, quand la même règle est écrite à plusieurs endroits, quand une machinerie maison entoure un outil tiers, ou avant de poser un design pattern.
---

# Simplifier par la structure, pas par le pattern

C'est le **refactor** du cycle TDD, et cette skill ne produit rien : toute écriture part en
délégation à l'agent TDD du projet. La porte ordinaire est la suite existante rejouée **entière** et
restée verte — un refactor à comportement constant n'a besoin ni de rouge ni de sabotage. L'un ou
l'autre redevient obligatoire dès qu'un test naît ou qu'un comportement change.

Pas la clarté **locale** d'un fichier — c'est `/simplify` — mais **où le code vit, qui décide quoi,
ce que le programme fait exister**.

## La règle qui commande toutes les autres

**Nommer le défaut avant de nommer la solution.** Un pattern posé sans défaut nommé n'est pas une
simplification, c'est de la machinerie de plus. Strategy, Factory, Observer se méritent : ils
répondent à un problème qu'on sait énoncer sans eux. L'ordre : *le défaut, mesuré* → *la solution
déjà connue* → *ce qu'elle retire*.

## Nommer le défaut

Un défaut se dit en une phrase et se mesure :

- **La même règle écrite à plusieurs endroits.** Le coût n'est pas la longueur : les copies peuvent
  diverger **sans qu'aucun test ne rougisse**, chacune ayant les siens. Ce n'est pas le **compte** qui
  déclenche, c'est la divergence — possible, ou déjà arrivée : cas mesuré, un même code écrit trois
  fois et **faux les trois fois**.
- **Une machinerie maison autour d'un outil tiers** — bornes d'attente, arbitrage de course, états de
  repli, un chargeur par écran.
- **Une décision logée là où rien ne la surveille** : hors du périmètre de mutation, dans une vue,
  dans un script.
- **Un cycle entre modules**, souvent tenu par une seule arête posée par accident.
- **Un invariant réparti sur deux champs** que rien n'oblige à rester cohérents.
- **Une branche que rien ne peut atteindre**, avec son message à l'écran et son test vert.

## Aller voir dehors avant d'inventer

Chercher **qui l'a déjà résolu** : un motif du GoF, une API native de la bibliothèque utilisée, une
forme qui marche ailleurs dans le projet. Inventer vient en dernier.

**Un outil qui résiste indique souvent qu'on lui demande l'inverse de ce pour quoi il est fait.** Cas
mesuré : six chargeurs, quatre machines à cinq états et huit gardes anti-course écrits contre un SDK
qui offrait nativement un abonnement — un rappel qui pousse, au lieu de lectures répétées qui tirent.
Le bug que personne n'arrivait à corriger est parti avec : les courses se jouaient **entre** écrans.
Pas une soustraction en ligne droite pour autant : trois commits, la moitié des gardes au premier,
qui a figé un écran en silence — trouvé en revue, réparé en **ajoutant** un bandeau.

## La simplification qui retire

- **Un garde défensif appartient à la frontière, pas au cœur.** Valider des données brutes est le
  travail de la couche qui les reçoit ; le refaire au centre fait croire le cas traité.
- **Une branche inatteignable se supprime, pas se teste — après avoir nommé qui tient
  l'inatteignabilité.** Notre code : supprimer. Du code qu'on ne possède pas, navigateur ou SDK :
  supprimer **et** poser un filet qui asserte le résultat, jamais le mécanisme — mesuré, sans lui, le
  jour où la contrainte saute, le formulaire reste verrouillé toute la session. Cas mesuré : six
  branches de rejet aux tests **verts**, mortes chacune pour sa propre raison ; ce qui a débloqué le
  lot est ailleurs — des doubles rendus fidèles à leur port ont montré que le dépôt ne rejette
  jamais.
- **Un champ en écriture seule se supprime** : personne ne le lit, tout le monde l'entretient.
- **Un contrôle qui ne peut pas être faux ne protège pas, il ressemble à une protection.**

## Déplacer plutôt qu'abstraire

Beaucoup de défauts se règlent en remettant le code là où il appartient, sans indirection nouvelle :
un calcul dupliqué descend dans **l'entité dont il est une propriété** ; une décision qui vivait dans
une vue non surveillée rejoint un module surveillé — la vue lit, câble, **ne décide pas** ; un module
partagé par deux features va chez celle dont il dépend déjà, ce qui casse le cycle. Vérifier que le
module d'accueil ne ment pas : un prédicat qui parle d'autre chose que son nom le fait mentir.

**Un déplacement ne change pas que l'adresse.** Atterrir hors du périmètre muté garde le score vert
en supprimant la surveillance — cas mesuré, sur le fichier le plus subtil d'un lot. Le **dénominateur
de couverture** bouge, donc les seuils. Et la **légalité des imports** change : un import légal sous
l'UI devient une violation de frontière une fois le fichier déplacé. Chaque garde-fou qui bouge se
confronte : injecter l'import interdit, voir le rouge, retirer.

## Porter l'invariant par la forme

Quand deux champs doivent rester cohérents, le meilleur refactor rend l'incohérence
**inexprimable** : un seul champ, un type somme, une union fermée. Cas mesuré : deux champs dont le
second n'était vivant que si le premier l'était ; fusionnés, la ligne morte disparaît sans qu'aucun
test n'ait à la justifier. Côté outillage : un type refermé fait disparaître le garde qu'un typage
trop large exigeait. **Une forme permanente vaut mieux qu'un sabotage** — le lint la rejoue à chaque
fois.

## Ce qui prouve que c'est plus simple

**Le critère « moins de code » se juge sur le code final, pas sur le diff.** Trois choses : le
**compte avant / après** du défaut nommé, le **comportement observé** sur le scénario qui motivait le
geste **et** ses états non nominaux, et le **score de mutation isolé** des fichiers touchés, qui **ne
doit pas baisser**.

Lire un score et instruire un survivant n'est pas propre au refactor : voir la skill
`mutation-testing` et l'agent `mutation-auditor`. Ce qu'il ajoute :

- **Sur du code neuf, un survivant n'est pas forcément une indirection de trop.** Verdict « vrai
  trou » : changer la forme jusqu'à ce que le mutant n'existe plus vaut souvent mieux qu'un test de
  plus. Verdict « équivalent » : du code neuf y a droit aussi — cas mesuré, une borne d'algorithme à
  93 %, instruite et tolérée.
- **Un score qui ne bouge pas ne dit pas que rien n'a changé** : retirer une branche morte peut
  laisser le pourcentage identique et retirer du dénominateur un mutant menteur.

## Les tests pendant un refactor

« Un vrai refactor ne touche à aucun test » ne survit pas aux cas réels. Ce qui tient :

- **Aucune assertion supprimée ni relâchée sans arbitrage.** Déplacer un test, en ajouter un dédié au
  module extrait : normal. Relâcher une assertion, en retirer une, changer une intention, **changer un
  jeu de données** : **STOP**, l'utilisateur tranche. Une exception de forme pré-autorisée par le
  projet ne couvre jamais des données modifiées.
- **Supprimer du code inatteignable emporte des tests verts.** Leur sujet n'existe plus, mais ni le
  compilateur ni la suite ne le disent : ça se cherche exprès, ça se liste, ça se décide.
- **Quand la structure change le comportement observable, ce n'est plus un refactor.** Les tests qui
  épinglaient le défaut — le bug tenu pour une spécification — ne se réparent pas en silence :
  présenter l'impact, et chaque intention qui **survit** repart dans un test neuf confronté.
- **Un test resté vert n'est pas une preuve de neutralité.** Le déplacement est l'occasion de relire
  un nom contre ses données : cas mesuré, un jeu `[0, 3, 1]` a trois éléments *et* un maximum de
  trois, donc ne distingue pas « le plus grand » de « combien ». Corriger ce jeu s'arbitre et se paie
  d'une mesure — le nouveau fait tomber un sabotage que l'ancien laissait passer. Le littéral attendu
  suit, nom inchangé.

## Quand ne pas le faire

- **Un pattern qu'aucune divergence possible ne réclame.** Le compte de copies ne déclenche rien.
- **Un défaut qu'on n'a pas mesuré.** Une odeur supposée n'est pas une odeur.
- **Le code adjacent qu'on croise.** Un périmètre plus large se propose, il ne se prend pas.
- **Un défaut préexistant et non bloquant** pendant un cycle en cours. Il devient le suivant, et part
  en trace écrite.

## Ce que le projet doit déclarer

Lire dans son `CLAUDE.md` : les couches et leurs imports autorisés, le périmètre surveillé par la
mutation, comment tracer un défaut reporté, l'arbitrage des tests qui changent.

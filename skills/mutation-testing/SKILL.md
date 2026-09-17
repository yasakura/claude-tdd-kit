---
name: mutation-testing
description: Lancer et lire un run de mutation (Stryker) sans se faire mentir par l'instrument. Utiliser avant de rapporter un score de mutation, d'instruire un survivant, ou de décider qu'un fichier est couvert.
---

# Lire un run de mutation sans se faire mentir

La mutation prouve que les tests sont **serrés**. Elle ne prouve jamais qu'ils testent la **bonne
chose** : un mutant tué par un test faux est un mutant tué. Un score de mutation ne remplace donc ni
une revue, ni la validation de l'intention d'un test.

## La règle qui commande toutes les autres

**Stryker compte un timeout comme un mutant tué.** L'erreur va donc toujours dans le sens dangereux :
un survivant réel se cache derrière un score parfait. Tout ce qui suit découle de là.

Un score **ne se rapporte jamais nu**. Il se rapporte avec son **nombre de timeouts**. Un score
assorti de timeouts inattendus se rejoue avant d'être rapporté.

## Avant de lancer

1. **Machine au repos.** Pas de suite de tests, pas de build, pas de serveur de dev, pas d'autre
   agent. Sous charge, les timeouts explosent et le score ment.
2. **Concurrence déclarée.** Sans plafond, Stryker lance `n-1` workers (`n` = cœurs logiques) et se
   met en concurrence avec lui-même. Vérifier que la config du projet déclare `concurrency` ; si elle
   ne le déclare pas, le signaler avant de rapporter quoi que ce soit.
3. **Confronter l'instrument** à un cas dont la réponse est connue d'avance, et le re-confronter
   **après toute modification de la configuration**. Un instrument non confronté ne rend pas une
   mesure, il rend un chiffre.

## Le run isolé fait foi

Le score **global n'est pas reproductible**. Il ne vaut que comme signal de fumée.

Pour tout fichier modifié dans un cycle, rejouer un run isolé et **rapporter ce chiffre-là**.

**Piège** : `npx stryker run --mutate '<fichier>'` seul **n'isole pas**. Avec `incremental: true`,
Stryker relit son cache et **fusionne les résultats de tous les autres fichiers** dans le tableau et
dans le score. Le chiffre affiché reste plausible, mais ce n'est pas celui du fichier demandé.

L'isolation demande de détourner le cache vers un fichier jetable **et de le supprimer avant chaque
run** — sans cette suppression, le fichier jetable redevient un cache. Vérifier que le projet expose
un script qui fait les deux.

`--no-incremental` n'existe pas. `--force` reconstruirait le cache réel en le limitant au fichier
ciblé, détruisant l'incrémental des autres.

**Le run isolé règle la fusion, pas les timeouts.** Un fichier peut sortir à 100 % avec des timeouts.

## Ce que le cache incrémental mémorise

`incremental: true` mémorise le statut de chaque mutant, **`Timeout` compris**. Un mutant expiré une
fois reste crédité tant que son fichier ne bouge pas. Seul un rejeu à froid lui rend sa chance.

## Les mutants qui coûtent cher

Un mutant **`static`** — porté par du code exécuté au chargement du module, donc hors de tout test —
est joué contre **tous les tests de tous les fichiers qui importent ce module**. Il coûte plusieurs
fois un mutant ordinaire et **expire le premier sous charge**.

Construire des instances au niveau module plutôt qu'à l'intérieur de fonctions augmente cette part.
Un fichier qui flanche systématiquement en mutation est souvent un fichier riche en mutants `static`.

## Instruire un survivant

Tout survivant demande une **explication écrite**, en deux verdicts possibles :

- **équivalent** — le mutant ne change aucun comportement observable. Dire pourquoi, précisément.
  « Boilerplate » n'est pas une explication ; « les reducers matchent sur l'objet thunk, jamais sur
  la chaîne du type d'action » en est une.
- **vrai trou** — nommer le **scénario non couvert**, pas seulement la ligne.

Quand un survivant révèle du code **qu'aucun test n'exige**, supprimer le code plutôt qu'écrire un
test pour le justifier.

**Un survivant qui entraîne un changement — test ajouté, code supprimé, directive posée — part en
issue**, même corrigé dans le cycle, avec son verdict. Sans cette trace, ce que la mutation attrape
se referme dans le cycle et son rendement devient impossible à mesurer.

## Ce que la mutation ne voit pas

- **Les fichiers hors périmètre `mutate`.** Vérifier le périmètre avant de conclure qu'un fichier est
  gardé. Un chiffre de mutation ne dit rien d'un fichier qui n'est pas muté.
- **Un test dont le nom désigne un chemin que ses données n'empruntent pas.** Le test est vert, ses
  mutants meurent, et le défaut qu'il prétend garder passe.
- **Un garde défensif qu'un test atteint artificiellement.** Dès qu'un test atteint un garde
  impossible, tous ses mutants meurent et le score **récompense** du code mort. C'est le rôle des
  règles de lint type-aware, pas de la mutation.

## Déclencher, ou pas

Lancer la mutation **si le diff croise le périmètre `mutate`**, mécaniquement — `git diff --name-only`
croisé avec le périmètre. Pas sur un jugement : « ce lot ne touche pas la logique » est une
affirmation de complétude, et ces affirmations-là sont fausses bien plus souvent qu'on ne le croit.

## Ce que le projet doit déclarer

Cette skill ne connaît pas les valeurs d'un projet donné. Lire dans son `CLAUDE.md` ou sa config :
le périmètre `mutate`, le seuil de gate, la valeur de `concurrency`, le nom du script de run isolé,
et si la mutation tourne en intégration continue ou seulement en local.

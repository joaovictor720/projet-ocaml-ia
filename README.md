# Akleenator

## Implémentation de l’algorithme L*

Akleenator est un projet académique implémentant en **OCaml** l’algorithme d’apprentissage actif **L*** proposé par Dana Angluin (1987), destiné à l’inférence automatique d’automates finis déterministes (**DFA**). Le projet inclut également l’optimisation classique introduite par **Rivest & Schapire**, visant à réduire le nombre de requêtes nécessaires à l’apprentissage.

L’algorithme interagit avec un **oracle** — simulé ou humain — afin de reconstruire un langage régulier inconnu à partir de requêtes d’appartenance et d’équivalence, en s’appuyant sur la construction et le raffinement progressif d’une **table d’observation**.

---

## Objectifs du projet

* Implémenter fidèlement l’algorithme L* d’Angluin.
* Étudier et intégrer l’optimisation de Rivest–Schapire.
* Comparer empiriquement différentes configurations (avec/sans cache, Angluin vs RS).
* Produire des artefacts exploitables pour l’analyse (automates, traces, benchmarks).
* Fournir une base de code claire et modulaire, adaptée à un contexte académique.

---

## Fonctionnalités

### Algorithmes d’apprentissage

* **Angluin (L*)**
  Implémentation standard de l’algorithme L*, où l’ensemble des préfixes des contre-exemples est ajouté aux lignes de la table d’observation.

* **Rivest–Schapire (RS)**
  Version optimisée exploitant une recherche binaire sur les contre-exemples afin d’identifier un suffixe distinctif minimal à ajouter aux colonnes, réduisant ainsi la taille de la table et le nombre de requêtes.

### Optimisations et instrumentation

* **Mémoïsation des requêtes** : cache évitant les appels redondants à l’oracle.
* **Export Graphviz** : génération automatique des automates appris aux formats `.dot` et `.png`.
* **Traçage détaillé** : production de rapports HTML retraçant l’évolution de la table d’observation à chaque itération.

---

## Prérequis

* **OCaml** (incluant `ocamlc`)
* **Graphviz** (outil `dot`)
* **Make**

### Installation (Debian / Ubuntu)

```bash
sudo apt install ocaml graphviz make
```

---

## Compilation

Le projet est fourni avec un **Makefile** assurant la compilation et l’exécution.

Compiler l’ensemble du projet et des tests :

```bash
make
```

Nettoyer les fichiers objets et les résultats générés :

```bash
make clean
```

---

## Utilisation

Tous les fichiers générés (logs, automates, images, traces HTML) sont placés dans le répertoire `results/`.

### Exécution standard

Lance l’apprentissage sur l’ensemble des scénarios définis, avec la configuration par défaut (Rivest–Schapire avec cache activé).

```bash
make run
```

---

### Exécution sur une cible spécifique

Il est possible de lancer l’apprentissage sur un langage cible particulier à l’aide de la variable `T`.

```bash
make run-only T=div_by_5
```

La liste des scénarios disponibles peut être affichée via :

```bash
make list-scenarios
```

---

### Configuration de l’algorithme

Le comportement de l’outil peut être ajusté à l’aide de variables d’environnement :

* `ALGO` : `rs` ou `angluin`
* `CACHE` : `1` (activé) ou `0` (désactivé)

Exemple : exécuter l’algorithme d’Angluin sans cache sur la cible `bit_4`.

```bash
make run-only T=bit_4 ALGO=angluin CACHE=0
```

---

### Mode interactif

Un mode interactif permet à l’utilisateur de jouer le rôle de l’oracle en répondant manuellement aux requêtes d’appartenance et d’équivalence.

```bash
make interactive
```

---

## Benchmarks

Le projet intègre des scripts de mesure permettant de comparer les performances selon plusieurs critères :

* temps d’exécution,
* nombre de requêtes à l’oracle,
* taille de la table d’observation.

Benchmark comparatif sur une cible donnée (4 configurations : RS / Angluin × Cache / Sans cache) :

```bash
make benchmark T=div_by_25
```

Exécution de l’ensemble des benchmarks sur toutes les cibles :

```bash
make benchmark-all
```

---

## Structure du projet

```text
.
├── src/
│   ├── lStar.ml              # Implémentation du cœur de l’algorithme L*
│   ├── observationTable.ml   # Gestion de la table d’observation (S, E, fermeture, consistance)
│   ├── dfa.ml                # Structures de données et opérations sur les DFA
│   ├── targets.ml            # Définition des oracles et des langages cibles
│   └── main.ml               # Point d’entrée du programme
│
├── tests/                     # Tests unitaires
├── results/                   # Résultats générés (automates, logs, traces)
├── bin/                       # Exécutables compilés
└── Makefile
```

---

## Remarques

Ce projet est principalement destiné à un usage pédagogique et expérimental. Il constitue une base solide pour l’étude des algorithmes d’apprentissage actif de langages réguliers et peut être étendu vers d’autres variantes ou optimisations de L*.

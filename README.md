# 🧠 Reconstruction d’un Automate par l’Algorithme L\*

## 🎯 Objectif du Projet

L’objectif de ce projet est de **reconstruire automatiquement le comportement d’un système considéré comme une boîte noire (black-box oracle)**.

Ce système :

- ne révèle **aucune information interne** (ni logique, ni règles),
- répond uniquement par **"oui"** ou **"non"** lorsqu’on lui présente un mot,
- reconnaît un **langage régulier**, mais dont la structure est totalement inconnue.

---

## 🔍 Principe Général

Le projet implémente l’**algorithme L\***, une méthode d’apprentissage actif permettant de :

1. **Interroger progressivement l’oracle** avec des mots générés.
2. **Analyser les réponses** ("oui"/"non").
3. **Construire et compléter une table d’observation**.
4. **Formuler des hypothèses d’automate**.
5. **Détecter les erreurs** dans ces hypothèses via des contre-exemples.
6. **Corriger et affiner le modèle**.
7. **Converger vers l’automate fini minimal** acceptant exactement les mêmes mots que l’oracle.

---

## 🧩 Résultat Final

Au terme du processus :

- le programme **découvre automatiquement la structure cachée** du langage,
- il génère un **automate fini déterministe (AFD) minimal**,  
- cet automate **décrit exactement** le langage reconnu par l’oracle black-box.

---

## 📌 Importance du Projet

Ce projet démontre comment un système logiciel peut :

- **apprendre un langage régulier** sans avoir accès au code source,
- **déduire une grammaire minimale** à partir d'exemples "oui/non",
- **modéliser un comportement inconnu** avec une précision mathématiquement garantie.

Il s’agit d’un exemple concret de **learning by queries**, un paradigme central en vérification formelle, intelligence artificielle symbolique et ingénierie des systèmes critiques.

---

## 📁 Contenu du Projet

- Implémentation complète de l’algorithme L\*
- Interface d’oracle black‑box
- Construction dynamique de la table d’observation
- Génération de l’automate minimal
- Outils de test et visualisation de l’automate


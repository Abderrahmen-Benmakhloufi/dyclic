# Justifications Pédagogiques & Scientifiques — docs/PEDAGOGY.md

> **Cadre Universitaire :** Mémoire de recherche sur les technologies d'assistance pour apprenants francophones présentant des difficultés d'apprentissage de la lecture et de l'écriture.  
> **Objet :** Explicitation des fondements théoriques, psycholinguistiques et didactiques sous-tendant chaque choix d'architecture logicielle et de design d'interaction.

---

## 1. Fondements Théoriques de la Production Écrite Guidée (F4)

### 1.1 Théorie de l'Étayage et Zone Proximale de Développement (ZPD)
*Références : Vygotski (1934), Bruner (1983).*
- **Problématique didactique :** Les apprenants en difficulté d'apprentissage (dyslexiques / dysorthographiques) sont souvent submergés par la tâche d'écriture d'une « situation d'intégration » en raison de la multiplicité des sous-tâches simultanées (planification des idées, mise en mots syntaxique, orthographe lexicale et grammaticale, calligraphie/saisie). C'est le phénomène de *surcharge cognitive*.
- **Réponse applicative :** 
  - Découpage en 5 étapes séquentielles : (1) Comprendre la consigne, (2) Organiser les idées par questionnement, (3) Plan d'action, (4) Rédaction avec amorces, (5) Évaluation formative.
  - L'IA n'écrit jamais à la place de l'élève : elle fournit un étayage (*scaffolding*) qui soutient l'apprenant dans sa ZPD, puis s'efface pour laisser place à la production autonome.
  - Les **amorces de phrases** (*sentence starters*) débloquent la formulation sans imposer le contenu sémantique.

### 1.2 Métacognition et Rétroaction Formative (Hint-First)
*Références : Flavell (1979), Gombert (1990) sur la conscience métalinguistique, Hattie & Timperley (2007).*
- **Problématique didactique :** La correction automatique directe (comme celle des traitements de texte classiques) installe l'apprenant dans une posture passive d'acceptation aveugle. Elle ne génère aucun apprentissage durable.
- **Réponse applicative :**
  - **Priorité à l'indice (*Hint-First*) :** Le système identifie l'erreur, la catégorise (ex. *Accord sujet-verbe*), formule la règle sous forme interrogative ou simplifiée (ex. *« Regarde le sujet : qui fait l'action ? »*), et propose un indice de résolution.
  - La correction directe n'est accessible que sur sollicitation volontaire (*« Voir la correction »*). Ce délai cognitif stimule la réflexion métalinguistique de l'élève.

---

## 2. Fondements de la Simplification et de l'Accès au Sens (F1 & F2)

### 2.1 Allègement Syntaxique vs Appauvrissement Lexical
*Références : Baccino & Colé (1995), Rayner (1998) sur les mouvements oculaires et la compréhension en lecture.*
- **Problématique didactique :** Simplifier un texte en remplaçant tous les termes spécifiques par un vocabulaire enfantin prive l'apprenant de l'accès aux concepts scolaires et au vocabulaire disciplinaire nécessaire aux cycles primaire, moyen et secondaire.
- **Réponse applicative :**
  - La simplification porte sur l'architecture syntaxique : réduction des propositions subordonnées enchâssées, rétablissement de l'ordre canonique canonique Sujet-Verbe-Objet (SVO), élimination des doubles négations et des voix passives complexes.
  - Les mots thématiques riches et nécessaires sont conservés, mais enrichis d'une **glose contextuelle immédiate** (définition brève et accessible).

### 2.2 Désambiguïsation des Consignes Scolaires (F2)
*Références : Meirieu (1987), Perrenoud (1995).*
- **Problématique didactique :** Les consignes d'exercices constituent souvent un « obstacle invisible ». L'élève échoue fréquemment non pas par manque de compétence disciplinaire, mais parce qu'il n'a pas décodé les implicites de la consigne.
- **Réponse applicative :**
  - Décomposition explicite : Tâche attendue (*Qu'est-ce qu'on me demande de faire ?*), mots-clés, séquence chronologique d'actions, et contre-exemple/exemple illustratif analogique (sans dévoiler la réponse à l'exercice).

---

## 3. Ergonomie Visuelle & Théorie de la Charge Cognitive (F5)

### 3.1 Réduction de l'Encombrement Visuel (*Visual Crowding*)
*Références : Zorzi et al. (2012) — PNAS, Schneps et al. (2013) — PLOS ONE.*
- **Problématique psychophysique :** Chez les lecteurs dyslexiques, le phénomène de crowding (interférence spatiale entre lettres adjacentes et lignes voisines) dégrade considérablement la vitesse et la précision de reconnaissance des mots.
- **Réponse applicative :**
  - **Typographies spécialisées :** Intégration de polices à empattements asymétriques et bas alourdis (OpenDyslexic, Lexend, Atkinson Hyperlegible) pour éviter les confusions miroirs ($b/d$, $p/q$).
  - **Espacements personnalisables :** Découplage et réglage de l'espacement inter-lettres, inter-mots et interlignage.
  - **Règle de lecture (*Focus Ruler*) :** Masquage partiel du texte environnant pour supprimer les saccades oculaires parasites et éviter la perte de ligne.

### 3.2 Confort Visuel et Contraste Chromatique
*Références : Wilkins (2003) sur le stress visuel (Syndrome de Meares-Irlen).*
- **Problématique :** Le contraste brutal noir sur blanc pur peut induire des distorsions visuelles (éblouissement, scotomes de fatigue).
- **Réponse applicative :**
  - Proposition de fonds adoucis : crème/sépia, gris doux, bleu pastel, et mode sombre à faible contraste agressif.

---

## 4. Modalités Sensorielles Multiples : Théorie du Double Codage (F3)

### 4.1 Synchronisation Audio-Visuelle (Text-to-Speech & Surlignage)
*Références : Paivio (1986, 1991), Mayer (2001) — Théorie cognitive de l'apprentissage multimédia.*
- **Problématique didactique :** Le décodage grapho-phonémique laborieux absorbe la totalité des ressources d'attention de travail de l'apprenant dyslexique, ne lui laissant aucune ressource disponible pour l'accès au sens.
- **Réponse applicative :**
  - La synthèse vocale prend en charge le décodage phonologique externe, libérant la mémoire de travail pour la compréhension macro-structurelle.
  - Le surlignage synchronisé (mot à mot ou segment par segment) maintient l'association entre la forme orthographique et l'image acoustique (effet de bimodalité), renforçant l'automatisation de la lecture.

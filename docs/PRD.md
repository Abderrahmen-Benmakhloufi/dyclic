# Product Requirements Document (PRD) — Outil d'Aide à la Lecture et à l'Écriture (Français)

> **Document Status:** Active / Updated with Change Request #1  
> **Academic Context:** Mémoire de recherche universitaire (Master / Thèse)  
> **Primary Goal:** Prototype opérationnel (Gate 1) pour démonstration devant un comité d'évaluation scientifique et technique afin d'obtenir l'accord de financement pour le produit complet (Gate 2).

---

## 1. Vision, Positionnement & Public Cible

### 1.1 Positionnement Déontologique
L'application est un **outil d'aide à la lecture et à la production écrite** destiné aux apprenants francophones rencontrant des difficultés d'apprentissage de la lecture (notamment les apprenants dyslexiques, qu'ils disposent ou non d'un diagnostic médical officiel).
- **Avertissement éthique :** L'application n'est **en aucun cas** un dispositif médical, diagnostique ou thérapeutique. Aucune allégation médicale (« guérir la dyslexie », « diagnostic ») n'apparaît dans l'interface, les prompts ou les documents de présentation.
- **Principe pédagogique fondamental :** L'IA n'écrit **JAMAIS** à la place de l'apprenant. Elle agit comme un tuteur bienveillant qui guide la réflexion, décompose les tâches complexes (étayage / scaffolding) et fournit des indices métalinguistiques.

### 1.2 Public Cible (Système Éducatif Algérien & Francophonie)
L'application prend en charge les trois cycles d'enseignement :
1. **Primaire** (notamment 5e Année Primaire / 5e AP) : Vocabulaire simple, phrases très courtes, consignes imagées et ultra-guidées.
2. **Moyen** (Collège / 1e à 4e Année Moyenne - 1e–4e AM) : Situations d'intégration narratives, descriptives et explicatives.
3. **Secondaire** (Lycée / 1e à 3e Année Secondaire - 1e–3e AS) : Situations argumentatives, textes plus denses, analyse réflexive plus poussée.

*Règle d'accès :* La sélection du niveau est **obligatoire dès le premier lancement** (aucun bouton « Passer » ou « Ignorer »). L'apprenant doit choisir son niveau pour accéder à l'application. Il peut le modifier ultérieurement à tout moment dans les paramètres.

### 1.3 Cas d'Usage
- **En classe (avec l'enseignant) :** Résolution guidée d'une situation d'intégration, simplification de textes de lecture support, décorticage de consignes d'exercices.
- **À la maison (en autonomie) :** Écoute immersive des leçons et des devoirs (TTS), compréhension autonome des consignes de travail, aide à la relecture et à la détection d'erreurs d'écriture.

---

## 2. Spécifications Détaillées des Fonctionnalités (Gate 1)

Par ordre de priorité décroissante :

### P1 — F4 : Accompagnement de la Production Écrite (Situation d'Intégration)
*Priorité absolue du prototype — Le tuteur d'écriture autonome.*
Le système met en œuvre un parcours guidé en 5 étapes successives :
1. **Comprendre la tâche :** L'apprenant colle la consigne ou la situation d'intégration. Le système décompose l'objectif (qui parle ? à qui ? pour quoi faire ? type de texte attendu).
2. **Organiser ses idées :** Le système propose un questionnaire d'amorçage guidé (ex. *« De quel lieu veux-tu parler ? »*, *« Que s'est-il passé au début ? »*) et génère une structure/plan personnalisée que l'apprenant complète.
3. **Étapes concrètes de réalisation :** Une checklist séquentielle claire (1 à 4 étapes maximum) pour éviter la surcharge cognitive.
4. **Rédiger avec amorces de phrases :** L'apprenant rédige dans l'éditeur intégré. En cas de blocage (« panne de la page blanche »), l'outil propose des amorces syntaxiques (ex. *« Tout d'abord, nous avons observé... »*), sans jamais rédiger un paragraphe complet.
5. **Évaluation formative & indices d'abord (Hint-First) :** L'outil analyse la production de l'apprenant et catégorise les erreurs selon une taxonomie stricte :
   - `orthographe_lexicale`
   - `orthographe_grammaticale` (accords sujet-verbe, accords en genre et en nombre)
   - `conjugaison`
   - `grammaire_syntaxe`
   - `ponctuation`
   - `homophones`
   - `autre`
   *Règle pédagogique stricte :* L'interface affiche l'erreur en surbrillance, la catégorie, la règle simplifiée et un **indice de recherche**. La correction exacte reste cachée derrière un bouton explicite *« Voir la correction »*.

### P2 — F1 : Simplification et Résumé de Textes
*Rendre le texte accessible sans appauvrissement intellectuel.*
- **Entrée :** Texte copié/collé + niveau sélectionné (`primaire` | `moyen` | `secondaire`).
- **Sortie :**
  - `summary` : Résumé condensé en 2 à 4 phrases claires.
  - `simplified_text` : Version allégée au plan syntaxique (découpage des phrases longues en phrases courtes, mise en ordre Sujet-Verbe-Complément, élimination des doubles négations). **Le vocabulaire thématique riche est préservé**.
  - `key_vocabulary_with_glosses` : Liste des mots complexes conservés dans le texte avec une courte glose/définition accessible entre parenthèses ou cliquable.

### P3 — F2 : Explication des Consignes
*Désamorcer l'ambiguïté des consignes scolaires.*
- Analyse la consigne et génère :
  1. `what_is_asked` : Ce qu'il faut faire concrètement (l'action principale).
  2. `key_words` : Les mots-clés sémantiques indispensables.
  3. `steps` : Les étapes ordonnées à suivre.
  4. `simple_rewrite` : Reformulation directe et simple.
  5. `example` : Un exemple analogue qui illustre la méthode **sans jamais résoudre l'exercice de l'élève**.

### P4 — F3 : Synthèse Vocale (Text-to-Speech)
*Double codage visuel et auditif pour réduire la fatigue de décodage.*
- Synthèse vocale française utilisant les moteurs TTS locaux / natifs (Web Speech API sur navigateur, Android TTS sur mobile).
- Surlignage synchronisé en temps réel mot-à-mot (ou segment/ligne selon la capacité de l'API web).
- Contrôle de vitesse de lecture (0.75x, 1.0x, 1.25x), mise en pause et reprise fluide.

### P5 — F5 : Aide Visuelle à la Lecture (Ergonomie Cognitive)
*Adapter la présentation du texte aux particularités visuo-attentionnelles.*
- **Découpage visuel :** Présentation en segments courts ou retours à la ligne facilités.
- **Règle de lecture / Masque de concentration (Focus Ruler) :** Bandeau horizontal isolant la ligne active pour limiter les sauts de ligne intempestifs.
- **Personnalisation typographique intégrale (Sauvegardée localement) :**
  - Police adaptée : Lexend, Atkinson Hyperlegible, OpenDyslexic, ou Système.
  - Taille de police dynamique (slider fluide).
  - Espacement des caractères (letter-spacing), des mots (word-spacing) et interlignage (line-height).
  - Thèmes de contraste anti-éblouissement : Noir sur Blanc, Nuit (Blanc sur Noir), Crème / Sépia (confort visuel), Pastel bleuté.

### Module Optionnel à Basse Priorité : Règles de Prononciation (F5b)
- Table statique JSON locale (15–20 règles types : lettre `s` entre deux voyelles $\to$ `/z/` dans *saisir*, `c` devant `e/i/y`, nasales).
- Développé en fin de Gate 1 uniquement si les 5 fonctionnalités clés sont stabilisées.
- **Exclusion formelle :** Pas d'enregistrement vocal ni de notation vocale de l'élève.

---

## 3. Matrice de Portée : Prototype (Gate 1) vs Produit Final (Gate 2)

| Composante / Fonctionnalité | Prototype (Gate 1) | Produit Final (Gate 2) |
| :--- | :--- | :--- |
| **F4 Production Écrite** | Workflow guidé 5 étapes, hint-first, amorces | Suivi longitudinal des erreurs, portfolio d'écriture |
| **F1 Simplification/Résumé** | Syntaxe allégée, gloses de vocabulaire | RAG sur manuels scolaires officiels, niveaux personnalisés |
| **F2 Consignes** | Décomposition, étapes, exemple non résolutif | Assistant interactif pas-à-pas |
| **F3 Synthèse Vocale** | TTS local (Web/Android) + surlignage mot/ligne | TTS Cloud neural haute fidélité avec cache audio |
| **F5 Aide Visuelle** | Règle de lecture, polices, espacements, thèmes | Coloration syllabique avancée, import photo OCR |
| **Distribution** | Lien Web (PWA hébergée) + APK Android | Google Play Store, Apple App Store, Portail PWA |
| **Gestion Utilisateur / Auth** | **Aucun compte** (Stockage local des réglages) | Authentification sécurisée, profils élèves/classes |
| **Données & Confidentialité** | Zéro texte élève stocké sur serveur | Conformité Loi 18-07 & RGPD, consentement parental |
| **Backend & IA** | Edge Function Supabase + Claude Haiku proxy | Supabase pgvector + RAG + Cache sémantique |

---

## 4. Scénario de Démonstration (5 Minutes — Comité d'Évaluation)

1. **Introduction (30s) :** Présentation du rôle de tuteur pédagogique (sans allégation médicale, respect des 3 cycles algériens).
2. **P1 — Démo Situation d'Intégration / F4 (2 min) :**
   - Collage d'une consigne de situation d'intégration de 4e AM.
   - Décomposition de la consigne (étape 1) $\to$ amorçage des idées (étape 2) $\to$ affichage d'une amorce de phrase (étape 4).
   - Saisie d'un court paragraphe contenant des erreurs typiques (accord, homophone `a/à`, conjugaison).
   - Analyse instantanée : l'erreur est catégorisée, la règle expliquée avec un indice réflexif ; le comité observe que la correction n'est révélée que sur clic volontaire.
3. **P2 — Simplification & Glossaire / F1 (45s) :**
   - Collage d'un texte littéraire complexe.
   - Génération du résumé et de la version simplifiée préservant les mots techniques avec leurs gloses explicatives.
4. **P4 & P5 — Lecture Multimodale / F3 & F5 (1 min) :**
   - Activation de la synthèse vocale avec surlignage synchronisé.
   - Démonstration de la règle de lecture (Focus Ruler).
   - Changement direct de typographie (OpenDyslexic / Lexend, espacements élargis, fond crème).
5. **Conclusion & Perspectives Gate 2 (45s) :**
   - Architecture modulaire prête pour le passage à l'échelle (RAG sur manuels scolaires, hébergement sécurisé, conformité réglementaire).

---

## 5. Exigences Non-Fonctionnelles & Sécurité

1. **Confidentialité Dès la Conception (Privacy-by-Design) :**
   - Aucune création de compte requise pour la démonstration.
   - Aucun texte rédigé par l'apprenant n'est enregistré de manière persistante sur la base de données distante.
2. **Performance Web & PWA :**
   - Chargement initial < 3 secondes sur connexion 4G standard.
   - Interface réactive testée spécifiquement sur Android Chrome et navigateurs de bureau.
3. **Résilience Réseau :**
   - En cas d'absence de connexion Internet, les réglages typographiques, la règle de lecture et le TTS local continuent de fonctionner. Les fonctionnalités IA affichent un message clair et bienveillant en français.
4. **Contrôle des Coûts :**
   - Utilisation du modèle Claude classe Haiku via Edge Function avec limitation de débit (rate limit) et validation stricte du schéma JSON de sortie.

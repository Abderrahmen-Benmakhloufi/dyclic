# Règles de Design UI/UX & Accessibilité (Guide Mandaté)

> **Projet :** LectureAide — Application d'aide à la lecture et à l'écriture pour apprenants avec difficultés / dyslexie.  
> **Auteur des directives :** Décisions de conception et retours d'expérience validés par l'utilisateur.  
> **Application obligatoire :** Ce document doit impérativement être consulté et appliqué lors de la création ou modification de toute interface utilisateur de l'application.

---

## 1. Philosophie Générale : Épuré, Respirant et Rassurant (Style Stitch)

1. **Jamais de texte miniature :**
   - Les apprenants avec difficultés de lecture ne doivent jamais plisser les yeux pour déchiffrer l'interface.
   - Taille minimale de texte pour les libellés et explications : **13.5px à 16px**.
   - Corps du texte de lecture : base par défaut de **18px**, ajustable par l'utilisateur.
   - Les polices recommandées sont adaptées aux troubles de lecture : `Atkinson Hyperlegible` et `Lexend`.
2. **Couleurs de fond douces et apaisantes :**
   - Éviter le blanc agressif pur (#FFFFFF) sur de grands espaces de lecture ; privilégier le fond crème (`#FFFDF8` ou `#FFFBEB`) ou pastel reposant.
   - En mode sombre, éviter le noir absolu (`#000000`) ; utiliser des gris anthracite profonds (`#1E293B`) avec texte crème clair pour un contraste doux sans éblouissement.
3. **Cartes aérées avec marges respiratoires :**
   - Coins arrondis généreux (`BorderRadius.circular(14)` à `16`).
   - Bordures légères et subtiles (`Border.all(color: palette.border)`).
   - Ombres très discrètes (`Color(0x0C000000)`) pour donner du relief sans surcharger la vision.

---

## 2. Règle des Réglages : Modal Mi-Écran avec Prévisualisation Directe (Half-Screen Live Preview)

1. **Hauteur à mi-écran (~50% à 52%) :**
   - Lorsque l'utilisateur clique sur **« Ajuster la police & taille »** (ou l'icône de réglages de l'AppBar), le panneau `ReadingSettingsSheet` s'ouvre en demi-écran.
   - Utiliser un voile de fond léger et translucide : `barrierColor: Colors.black.withValues(alpha: 0.15)`.
2. **Visibilité et défilement automatique du texte :**
   - Lors de l'ouverture du modal, le texte de lecture doit automatiquement défiler vers le haut (`_readingTextScrollController.animateTo(0.0, ...)`).
   - Les premières lignes du texte restent ainsi parfaitement visibles dans la moitié supérieure de l'écran, au-dessus du panneau de réglages.
3. **Mise à jour en temps réel (Live Preview) :**
   - Tout ajustement (`+` ou `−` sur la taille de police, l'interligne, l'espacement des lettres, le choix de police, le mode de contraste) doit répercuter son effet **immédiatement sur le texte en arrière-plan** via Riverpod sans nécessiter la fermeture du panneau.
4. **Fermeture rapide et intuitive :**
   - Inclure un bouton de fermeture croix `(X)` dans le bandeau supérieur de la feuille, un bouton « Rétablir » pour réinitialiser rapidement, ainsi qu'un bouton « Fermer » en bas.
   - Un clic sur la zone supérieure translucide ferme également le modal naturellement.

---

## 3. Règle d'Or des Syllabes : Distinction Non-Colorée (Anti-Conflit b, d, p)

1. **Principe fondamental :**
   - **La segmentation en syllabes ne doit JAMAIS colorer la police de caractères des lettres.**
2. **Raison pédagogique essentielle :**
   - Dans les approches orthophoniques et pédagogiques pour la dyslexie, certaines lettres clés possèdent des couleurs sémantiques réservées :
     - **b** = Bleu vif (`#1E88E5`)
     - **d** = Orange vif (`#F57C00`)
     - **p** = Rose / Violet (`#8E24AA`)
     - **Lettres muettes** = Gris italique souligné (`#9E9E9E`)
   - Si les syllabes alternent des couleurs de texte (ex: bleu puis violet), l'élève ne peut plus distinguer si une lettre est bleue parce qu'elle est un `b` ou simplement parce qu'elle fait partie de la première syllabe !
3. **Les deux modes autorisés pour distinguer les syllabes :**
   - **Mode A : Blocs translucides (`Blocs doux`) [Mode par défaut] :**
     - Les syllabes paires (`i % 2 == 0`) reçoivent un fond doux légèrement teinté et translucide (`palette.primary.withValues(alpha: 0.12)`).
     - Les syllabes impaires restent sur le fond naturel de la page.
     - **La couleur du texte reste la couleur normale contrastée.**
     - Les lettres spéciales (`b`, `d`, `p`, lettres muettes) conservent intégralement leurs couleurs et styles distinctifs au-dessus de ce fond doux.
   - **Mode B : Soulignement alterné (`Souligné`) :**
     - Les syllabes paires sont soulignées discrètement (`TextDecoration.underline`).
     - Les syllabes impaires ne sont pas soulignées.
     - La couleur du texte reste inchangée.
4. **Sélecteur de style et persistance :**
   - Dans la carte *« Découpage des syllabes »*, fournir un sélecteur à deux boutons `[ 🔲 Blocs ]` / `[ ➖ Souligné ]` avec aperçu dynamique du mot `cho · co · lat`.
   - L'état sélectionné doit être sauvegardé dans `SharedPreferences` (`reading_aid_syllable_visual_mode`).

---

## 4. Règle de la Charge Cognitive : Valeurs par Défaut Épurées

1. **État initial non surchargé :**
   - Par défaut, à l'affichage d'un nouveau texte, **seule l'aide des syllabes est activée** (`_showSyllables = true`).
   - Toutes les aides de coloration détaillée des lettres et sons (lettres miroirs b/d/p, lettres muettes, sons complexes, voyelle E, sons contextuels) doivent être **DÉSACTIVÉES par défaut** (`false`).
   - L'écran ne doit jamais ressembler à un "arc-en-ciel" chaotique sans accord préalable de l'utilisateur.
2. **Persistance des choix de l'élève :**
   - Dès que l'utilisateur active ou désactive une aide visuelle, son choix est sauvegardé immédiatement dans `SharedPreferences` :
     - `reading_aid_syllables`
     - `reading_aid_silent_letters`
     - `reading_aid_mirror_letters`
     - `reading_aid_complex_sounds`
     - `reading_aid_vowel_e`
     - `reading_aid_contextual_letters`
     - `reading_aid_syllable_visual_mode`
   - Lors de la prochaine utilisation, ses réglages personnels sont fidèlement restaurés.

---

## 5. Ergonomie des Boutons d'Action & Synthèse Vocale (TTS)

1. **Visibilité et affordance du bouton d'écoute audio :**
   - Le bouton TTS ne doit jamais être une simple petite icône perdue ou dissimulée.
   - Il doit s'agir d'un bouton généreux, avec icône et libellé explicite :
     - En arrêt : icône `volume_up_rounded`, texte « Écouter », couleur primaire.
     - En cours de lecture : icône `stop_circle_rounded`, texte « Arrêter », couleur rouge d'alerte (`AppColors.errorRed`).
2. **Prononciation au toucher du mot (Word Tap) :**
   - Chaque mot du texte adapté est cliquable individuellement via `TapGestureRecognizer`.
   - Au toucher, l'application prononce immédiatement le mot ciblé et applique un surlignage jaune doux (`AppColors.highlightYellow`) pour un repérage visuel instantané.
3. **Contrôle de vitesse de voix défensif :**
   - Les pilules de vitesse (`0.8x ralenti`, `1.0x normal`, `1.2x rapide`) doivent être disposées dans une rangée horizontale avec `Expanded` ou `Flexible` pour garantir qu'aucun libellé ne déborde de sa boîte ou de l'écran, quelle que soit la largeur du smartphone.

---

## 6. Zéro Débordement Visuel & Écran Sans Surcharge (Defensive UI)

1. **Interdiction formelle des dépassements (Pixel Overflow) :**
   - Toujours anticiper les textes plus longs que la moyenne.
   - Ne jamais fixer de largeurs rigides en pixels (`width: 320`) à l'intérieur de cartes scrollables.
   - Utiliser `Expanded`, `Flexible`, `SingleChildScrollView`, ou `Wrap`.
2. **AppBar minimaliste et sans doublon :**
   - Ne jamais empiler des icônes d'action les unes sous les autres.
   - Ne jamais dupliquer le bouton de retour : la flèche de retour standard de l'AppBar suffit.
   - L'icône de réglages (`Icons.tune_rounded`) et l'icône de décodage (`Icons.spellcheck_rounded`) occupent une place bien espacée dans la zone d'actions.
3. **Dock inférieur fixé (Sticky Bottom Dock) :**
   - Les raccourcis les plus fréquents pendant la lecture (ex: « Ajuster la police & taille », activation de la « Règle de lecture ») doivent être fixés en bas d'écran dans un bandeau toujours accessible sous le pouce sans avoir à faire défiler toute la page.

---

## 7. Règle Linguistique et Pédagogique

1. **Interface 100% en Français :**
   - Aucune chaîne de caractères en Arabe dans l'UI de l'application (l'application cible l'apprentissage du Français dans le système scolaire algérien).
2. **Vocabulaire pédagogique valorisant :**
   - Adapter les textes d'encouragement sans être infantilisant (« Chaque mot lu est une belle victoire ! »).
   - Niveaux scolaires clairement nommés : `Primaire (5e AP)`, `Moyen (Collège)`, `Secondaire (Lycée)`.

---

## 8. Intégrité des Versions et du Déploiement

1. **Incrémentation systématique à chaque export :**
   - Incrémenter `version: X.Y.Z+N` dans `app/pubspec.yaml`.
   - Mettre à jour la mention visible de version sur l'écran d'accueil (`home_screen.dart: vX.Y.Z`).
2. **Nettoyage pré-compilation :**
   - Vider l'ancien dossier `build/app/outputs/flutter-apk/` pour éviter toute confusion avec d'anciens fichiers APK.
   - Fournir l'APK Universel (`app-release.apk`) et l'APK optimisé (`app-arm64-v8a-release.apk`).

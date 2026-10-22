// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Aide à la Lecture et à l\'Écriture';

  @override
  String get appTagline =>
      'Ton compagnon pour lire, comprendre et rédiger avec confiance';

  @override
  String get onboardingTitle => 'Bienvenue !';

  @override
  String get onboardingSubtitle =>
      'Choisis ton niveau scolaire pour adapter tous les textes et conseils :';

  @override
  String get onboardingMandatoryNotice =>
      'Cette sélection est nécessaire pour préparer ton espace de travail.';

  @override
  String get onboardingConfirmButton => 'Commencer l\'aventure';

  @override
  String get levelPrimaireTitle => 'Primaire';

  @override
  String get levelPrimaireSubtitle => '5e Année Primaire (5e AP)';

  @override
  String get levelPrimaireDesc =>
      'Phrases très courtes, repères visuels clairs et vocabulaire guidé.';

  @override
  String get levelMoyenTitle => 'Moyen (Collège)';

  @override
  String get levelMoyenSubtitle => '1e à 4e Année Moyenne (1e-4e AM)';

  @override
  String get levelMoyenDesc =>
      'Situations d\'intégration, explications pas à pas et enrichissement du vocabulaire.';

  @override
  String get levelSecondaireTitle => 'Secondaire (Lycée)';

  @override
  String get levelSecondaireSubtitle => '1e à 3e Année Secondaire (1e-3e AS)';

  @override
  String get levelSecondaireDesc =>
      'Textes plus denses, démarche argumentative et réflexion méthodique.';

  @override
  String currentLevelBadge(String level) {
    return 'Niveau : $level';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navSettings => 'Réglages de lecture';

  @override
  String get navHelp => 'Aide';

  @override
  String get featureF4Title => 'Situation d\'Intégration';

  @override
  String get featureF4Badge => 'Production Écrite';

  @override
  String get featureF4Desc =>
      'Organise tes idées, utilise des amorces de phrases et progresse grâce à des indices.';

  @override
  String get featureF1Title => 'Simplifier un Texte';

  @override
  String get featureF1Badge => 'Compréhension';

  @override
  String get featureF1Desc =>
      'Allège les phrases complexes tout en conservant les mots importants et leurs explications.';

  @override
  String get featureF2Title => 'Expliquer une Consigne';

  @override
  String get featureF2Badge => 'Méthode';

  @override
  String get featureF2Desc =>
      'Découvre clairement ce qui t\'est demandé, les étapes à suivre et les mots-clés.';

  @override
  String get featureF3Title => 'Écouter la Lecture';

  @override
  String get featureF3Badge => 'Synthèse Vocale';

  @override
  String get featureF3Desc =>
      'Écoute n\'importe quel texte avec un surlignage synchronisé mot à mot.';

  @override
  String get featureF5Title => 'Confort Visuel';

  @override
  String get featureF5Badge => 'Aide à la Lecture';

  @override
  String get featureF5Desc =>
      'Personnalise la police, les espacements, les couleurs et active la règle de lecture.';

  @override
  String get btnContinue => 'Continuer';

  @override
  String get btnValidate => 'Valider';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnRetry => 'Réessayer';

  @override
  String get btnCopy => 'Copier';

  @override
  String get btnListen => 'Écouter';

  @override
  String get btnPause => 'Pause';

  @override
  String get btnStop => 'Arrêter';

  @override
  String get btnSettings => 'Paramètres';

  @override
  String get btnClose => 'Fermer';

  @override
  String get btnSeeHint => 'Voir l\'indice';

  @override
  String get btnSeeRule => 'Comprendre la règle';

  @override
  String get btnSeeCorrection => 'Voir la correction';

  @override
  String get offlineTitle => 'Mode hors-ligne';

  @override
  String get offlineBanner =>
      'Pas de connexion Internet. Tes réglages et tes textes récents restent accessibles !';

  @override
  String get errorGeneric =>
      'Une erreur est survenue. N\'hésite pas à réessayer.';

  @override
  String get errorRateLimit =>
      'Tu as fait plusieurs demandes rapidement. Prends une courte pause et réessaie dans quelques instants.';
}

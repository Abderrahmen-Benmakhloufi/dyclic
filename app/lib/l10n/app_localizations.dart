import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Titre principal de l'application
  ///
  /// In fr, this message translates to:
  /// **'AideLecture'**
  String get appTitle;

  /// Slogan bienveillant de l'application
  ///
  /// In fr, this message translates to:
  /// **'Ton compagnon pour lire, comprendre et rédiger avec confiance'**
  String get appTagline;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton niveau scolaire pour adapter tous les textes et conseils :'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingMandatoryNotice.
  ///
  /// In fr, this message translates to:
  /// **'Cette sélection est nécessaire pour préparer ton espace de travail.'**
  String get onboardingMandatoryNotice;

  /// No description provided for @onboardingConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'aventure'**
  String get onboardingConfirmButton;

  /// No description provided for @levelPrimaireTitle.
  ///
  /// In fr, this message translates to:
  /// **'Primaire'**
  String get levelPrimaireTitle;

  /// No description provided for @levelPrimaireSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'École primaire (Consolidation)'**
  String get levelPrimaireSubtitle;

  /// No description provided for @levelPrimaireDesc.
  ///
  /// In fr, this message translates to:
  /// **'Phrases courtes, repères visuels clairs et vocabulaire guidé.'**
  String get levelPrimaireDesc;

  /// No description provided for @levelMoyenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get levelMoyenTitle;

  /// No description provided for @levelMoyenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Collège / Enseignement moyen (BEM / Brevet)'**
  String get levelMoyenSubtitle;

  /// No description provided for @levelMoyenDesc.
  ///
  /// In fr, this message translates to:
  /// **'Situations complexes, explications pas à pas et préparation au Brevet.'**
  String get levelMoyenDesc;

  /// No description provided for @levelSecondaireTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lycée'**
  String get levelSecondaireTitle;

  /// No description provided for @levelSecondaireSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'2nde – 1ère – Terminale (Bac)'**
  String get levelSecondaireSubtitle;

  /// No description provided for @levelSecondaireDesc.
  ///
  /// In fr, this message translates to:
  /// **'Textes denses et argumentatifs, démarche réflexive et préparation au Bac.'**
  String get levelSecondaireDesc;

  /// No description provided for @currentLevelBadge.
  ///
  /// In fr, this message translates to:
  /// **'Niveau : {level}'**
  String currentLevelBadge(String level);

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de lecture'**
  String get navSettings;

  /// No description provided for @navHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get navHelp;

  /// No description provided for @featureF4Title.
  ///
  /// In fr, this message translates to:
  /// **'Situation d\'Intégration'**
  String get featureF4Title;

  /// No description provided for @featureF4Badge.
  ///
  /// In fr, this message translates to:
  /// **'Production Écrite'**
  String get featureF4Badge;

  /// No description provided for @featureF4Desc.
  ///
  /// In fr, this message translates to:
  /// **'Organise tes idées, utilise des amorces de phrases et progresse grâce à des indices.'**
  String get featureF4Desc;

  /// No description provided for @featureF1Title.
  ///
  /// In fr, this message translates to:
  /// **'Simplifier un Texte'**
  String get featureF1Title;

  /// No description provided for @featureF1Badge.
  ///
  /// In fr, this message translates to:
  /// **'Compréhension'**
  String get featureF1Badge;

  /// No description provided for @featureF1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Allège les phrases complexes tout en conservant les mots importants et leurs explications.'**
  String get featureF1Desc;

  /// No description provided for @featureF2Title.
  ///
  /// In fr, this message translates to:
  /// **'Expliquer une Consigne'**
  String get featureF2Title;

  /// No description provided for @featureF2Badge.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get featureF2Badge;

  /// No description provided for @featureF2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Découvre clairement ce qui t\'est demandé, les étapes à suivre et les mots-clés.'**
  String get featureF2Desc;

  /// No description provided for @featureF3Title.
  ///
  /// In fr, this message translates to:
  /// **'Écouter la Lecture'**
  String get featureF3Title;

  /// No description provided for @featureF3Badge.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse Vocale'**
  String get featureF3Badge;

  /// No description provided for @featureF3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Écoute n\'importe quel texte avec un surlignage synchronisé mot à mot.'**
  String get featureF3Desc;

  /// No description provided for @featureF5Title.
  ///
  /// In fr, this message translates to:
  /// **'Confort Visuel'**
  String get featureF5Title;

  /// No description provided for @featureF5Badge.
  ///
  /// In fr, this message translates to:
  /// **'Aide à la Lecture'**
  String get featureF5Badge;

  /// No description provided for @featureF5Desc.
  ///
  /// In fr, this message translates to:
  /// **'Personnalise la police, les espacements, les couleurs et active la règle de lecture.'**
  String get featureF5Desc;

  /// No description provided for @btnContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get btnContinue;

  /// No description provided for @btnValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get btnValidate;

  /// No description provided for @btnCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get btnCancel;

  /// No description provided for @btnRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get btnRetry;

  /// No description provided for @btnCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get btnCopy;

  /// No description provided for @btnListen.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get btnListen;

  /// No description provided for @btnPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get btnPause;

  /// No description provided for @btnStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get btnStop;

  /// No description provided for @btnSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get btnSettings;

  /// No description provided for @btnClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get btnClose;

  /// No description provided for @btnSeeHint.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'indice'**
  String get btnSeeHint;

  /// No description provided for @btnSeeRule.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre la règle'**
  String get btnSeeRule;

  /// No description provided for @btnSeeCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Voir la correction'**
  String get btnSeeCorrection;

  /// No description provided for @offlineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors-ligne'**
  String get offlineTitle;

  /// No description provided for @offlineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion Internet. Tes réglages et tes textes récents restent accessibles !'**
  String get offlineBanner;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. N\'hésite pas à réessayer.'**
  String get errorGeneric;

  /// No description provided for @errorRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Tu as fait plusieurs demandes rapidement. Prends une courte pause et réessaie dans quelques instants.'**
  String get errorRateLimit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

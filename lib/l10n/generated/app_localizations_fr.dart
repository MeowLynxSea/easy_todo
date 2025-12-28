// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get preferences => 'Préférences';

  @override
  String get appSettings => 'Paramètres de l\'application';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Gérer les préférences de notification';

  @override
  String get theme => 'Thème';

  @override
  String get lightTheme => 'Clair';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get systemTheme => 'Système';

  @override
  String get language => 'Langue';

  @override
  String get languageSettings =>
      'Les paramètres de langue vous permettent de changer la langue d\'affichage de l\'application. Sélectionnez votre langue préférée dans la liste ci-dessus.';

  @override
  String get dataStorage => 'Données et stockage';

  @override
  String get dataAndSync => 'Données et synchronisation';

  @override
  String get cloudSync => 'Sync cloud';

  @override
  String get cloudSyncSubtitle => 'Chiffré de bout en bout (manuel)';

  @override
  String get cloudSyncOverviewTitle => 'Synchronisation E2EE manuelle';

  @override
  String get cloudSyncOverviewSubtitle =>
      'Le serveur ne stocke que du chiffré ; déverrouillez avec votre phrase secrète sur cet appareil.';

  @override
  String get cloudSyncConfigSaved => 'Configuration de sync enregistrée';

  @override
  String get cloudSyncServerOkSnack => 'Serveur joignable';

  @override
  String get cloudSyncServerCheckFailedSnack =>
      'Vérification du serveur échouée';

  @override
  String get cloudSyncDisabledSnack => 'Synchronisation désactivée';

  @override
  String get cloudSyncEnableSwitchTitle => 'Activer la synchro cloud';

  @override
  String get cloudSyncEnableSwitchSubtitle =>
      'Configuration guidée : serveur + phrase secrète';

  @override
  String get cloudSyncServerSection => 'Serveur';

  @override
  String get cloudSyncSetupTitle => '1) Configurer le serveur';

  @override
  String get cloudSyncSetupSubtitle =>
      'Définissez l’URL du serveur, choisissez un provider et connectez-vous.';

  @override
  String get cloudSyncSetupDialogTitle => 'Configuration du serveur';

  @override
  String get cloudSyncServerUrl => 'URL du serveur';

  @override
  String get cloudSyncServerUrlHint => 'http://127.0.0.1:8787';

  @override
  String get cloudSyncAuthProvider => 'Provider OAuth';

  @override
  String get cloudSyncAuthProviderHint => 'linuxdo';

  @override
  String get cloudSyncAuthMode => 'Authentification';

  @override
  String get cloudSyncAuthModeLoggedIn => 'Connecté';

  @override
  String get cloudSyncAuthModeLoggedOut => 'Non connecté';

  @override
  String get cloudSyncCheckServer => 'Vérifier le serveur';

  @override
  String get cloudSyncEditServerConfig => 'Modifier';

  @override
  String get cloudSyncLogin => 'Se connecter';

  @override
  String get cloudSyncLogout => 'Se déconnecter';

  @override
  String get cloudSyncLoggedInSnack => 'Connecté';

  @override
  String get cloudSyncLoggedOutSnack => 'Déconnecté';

  @override
  String get cloudSyncLoginRedirectedSnack =>
      'Continuez la connexion dans le navigateur';

  @override
  String get cloudSyncLoginFailedSnack => 'Échec de la connexion';

  @override
  String get cloudSyncNotSet => 'Non défini';

  @override
  String get cloudSyncTokenSet => 'Jeton défini';

  @override
  String get cloudSyncStatusSection => 'Statut';

  @override
  String get cloudSyncEnabled => 'Activé';

  @override
  String get cloudSyncUnlocked => 'Déverrouillé';

  @override
  String get cloudSyncEnabledOn => 'Activé : Oui';

  @override
  String get cloudSyncEnabledOff => 'Activé : Non';

  @override
  String get cloudSyncUnlockedYes => 'Déverrouillé : Oui';

  @override
  String get cloudSyncUnlockedNo => 'Déverrouillé : Non';

  @override
  String get cloudSyncConfiguredYes => 'Configuré : Oui';

  @override
  String get cloudSyncConfiguredNo => 'Configuré : Non';

  @override
  String get cloudSyncLastServerSeq => 'Dernier serverSeq';

  @override
  String get cloudSyncDekId => 'ID DEK';

  @override
  String get cloudSyncLastSyncAt => 'Dernière synchro';

  @override
  String get cloudSyncError => 'Erreur';

  @override
  String get cloudSyncDeviceId => 'ID de l’appareil';

  @override
  String get cloudSyncEnable => 'Activer';

  @override
  String get cloudSyncUnlock => 'Déverrouiller';

  @override
  String get cloudSyncSyncNow => 'Synchroniser';

  @override
  String get cloudSyncDisable => 'Désactiver';

  @override
  String get cloudSyncSecurityTitle => '2) Déverrouiller';

  @override
  String get cloudSyncSecuritySubtitle =>
      'Le déverrouillage utilise votre phrase secrète pour obtenir le DEK. Mobile/desktop peuvent le conserver en stockage sécurisé.';

  @override
  String get cloudSyncLockStateTitle => 'Clé de chiffrement';

  @override
  String get cloudSyncLockStateUnlocked => 'Déverrouillé sur cet appareil';

  @override
  String get cloudSyncLockStateLocked =>
      'Verrouillé — saisissez la phrase secrète';

  @override
  String get cloudSyncActionsTitle => '3) Synchroniser';

  @override
  String get cloudSyncActionsSubtitle =>
      'Envoyer les changements locaux puis récupérer les mises à jour.';

  @override
  String get cloudSyncAdvancedTitle => 'Avancé';

  @override
  String get cloudSyncAdvancedSubtitle => 'Infos de débogage (local)';

  @override
  String get cloudSyncEnableDialogTitle => 'Activer la synchronisation';

  @override
  String get cloudSyncUnlockDialogTitle => 'Déverrouiller la synchronisation';

  @override
  String get cloudSyncPassphraseDialogHint =>
      'Si vous avez déjà activé la synchronisation sur un autre appareil, saisissez la même phrase secrète deux fois.';

  @override
  String get cloudSyncPassphrase => 'Phrase secrète';

  @override
  String get cloudSyncConfirmPassphrase => 'Confirmer la phrase secrète';

  @override
  String get cloudSyncShowPassphrase => 'Afficher';

  @override
  String get cloudSyncEnabledSnack => 'Synchronisation activée';

  @override
  String get cloudSyncUnlockedSnack => 'Déverrouillé';

  @override
  String get cloudSyncSyncedSnack => 'Synchronisé';

  @override
  String get cloudSyncInvalidPassphrase => 'Phrase secrète invalide';

  @override
  String get cloudSyncRollbackTitle => 'Possible rollback du serveur';

  @override
  String get cloudSyncRollbackMessage =>
      'Le serveur a peut-être été restauré depuis une sauvegarde. Continuer peut entraîner une perte de données. Que souhaitez-vous faire ?';

  @override
  String get cloudSyncStopSync => 'Arrêter la synchro';

  @override
  String get cloudSyncContinue => 'Continuer';

  @override
  String get cloudSyncWebDekNote =>
      'Le Web met en cache le DEK uniquement pour la session. Un rechargement nécessite un nouveau déverrouillage.';

  @override
  String get cloudSyncStatusIdle => 'inactif';

  @override
  String get cloudSyncStatusRunning => 'en cours';

  @override
  String get cloudSyncStatusError => 'erreur';

  @override
  String get cloudSyncErrorPassphraseMismatch =>
      'Les phrases ne correspondent pas';

  @override
  String get cloudSyncErrorNotConfigured => 'Sync non configurée';

  @override
  String get cloudSyncErrorDisabled => 'La sync est désactivée';

  @override
  String get cloudSyncErrorLocked => 'La sync est verrouillée (DEK manquant)';

  @override
  String get cloudSyncErrorUnauthorized => 'Non autorisé (vérifiez le jeton)';

  @override
  String get cloudSyncErrorKeyBundleNotFound =>
      'Key bundle introuvable sur le serveur';

  @override
  String get cloudSyncErrorNetwork => 'Erreur réseau';

  @override
  String get cloudSyncErrorConflict => 'Conflit (version du bundle)';

  @override
  String get cloudSyncErrorQuotaExceeded =>
      'Server quota exceeded (some records were rejected)';

  @override
  String get cloudSyncErrorUnknown => 'Erreur inconnue';

  @override
  String get backupRestore => 'Sauvegarde et restauration';

  @override
  String get backupSubtitle => 'Sauvegarder vos données';

  @override
  String get storage => 'Stockage';

  @override
  String get storageSubtitle => 'Gérer l\'espace de stockage';

  @override
  String get about => 'À propos';

  @override
  String get aboutEasyTodo => 'À propos de Easy Todo';

  @override
  String get helpSupport => 'Aide et support';

  @override
  String get helpSubtitle => 'Obtenir de l\'aide avec l\'application';

  @override
  String get processingCategory => 'Traitement de la catégorie...';

  @override
  String get processingPriority => 'Traitement de la priorité...';

  @override
  String get processingAI => 'Traitement de l\'IA...';

  @override
  String get aiProcessingCompleted => 'Traitement de l\'IA terminé';

  @override
  String get categorizingTask => 'Catégorisation de la tâche...';

  @override
  String get processingAIStatus => 'Traitement de l\'IA...';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get clearAllData => 'Effacer toutes les données';

  @override
  String get clearDataSubtitle => 'Supprimer toutes les tâches et paramètres';

  @override
  String get version => 'Version';

  @override
  String get appDescription =>
      'Une application de liste de tâches propre et élégante conçue pour la simplicité et la productivité.';

  @override
  String get developer => 'Développeur';

  @override
  String get developerInfo => 'Informations sur le développeur';

  @override
  String get needHelp => 'Besoin d\'aide ?';

  @override
  String get helpDescription =>
      'Si vous rencontrez des problèmes ou avez des suggestions, n\'hésitez pas à nous contacter par l\'un des moyens ci-dessus.';

  @override
  String get close => 'Fermer';

  @override
  String get themeSettings => 'Paramètres du thème';

  @override
  String get themeMode => 'Mode thème';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get themeColors => 'Couleurs du thème';

  @override
  String get customTheme => 'Thème personnalisé';

  @override
  String get primaryColor => 'Couleur principale';

  @override
  String get secondaryColor => 'Couleur secondaire';

  @override
  String get selectPrimaryColor =>
      'Sélectionner la couleur principale de l\'application';

  @override
  String get selectSecondaryColor =>
      'Sélectionner la couleur secondaire de l\'application';

  @override
  String get selectColor => 'Sélectionner une couleur';

  @override
  String get hue => 'Teinte';

  @override
  String get saturation => 'Saturation';

  @override
  String get lightness => 'Luminosité';

  @override
  String get applyCustomTheme => 'Appliquer le thème personnalisé';

  @override
  String get customThemeApplied => 'Thème personnalisé appliqué avec succès';

  @override
  String get themeColorApplied => 'Couleur du thème appliquée';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get repeat => 'Répéter';

  @override
  String get repeatTask => 'Tâche répétitive';

  @override
  String get repeatType => 'Type de répétition';

  @override
  String get daily => 'Quotidien';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get monthly => 'Mensuel';

  @override
  String get weekdays => 'Jours de semaine';

  @override
  String get selectDays => 'Sélectionner les jours';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get everyDay => 'Tous les jours';

  @override
  String get everyWeek => 'Toutes les semaines';

  @override
  String get everyMonth => 'Tous les mois';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get startDate => 'Date de début';

  @override
  String get endDate => 'Date de fin';

  @override
  String get noEndDate => 'Pas de date de fin';

  @override
  String get timeRange => 'Plage horaire';

  @override
  String get startTime => 'Heure de début';

  @override
  String get endTime => 'Heure de fin';

  @override
  String get noStartTimeSet => 'Aucune heure de début';

  @override
  String get noEndTimeSet => 'Aucune heure de fin';

  @override
  String get invalidTimeRange =>
      'L\'heure de fin doit être après l\'heure de début';

  @override
  String get repeatEnabled => 'Répétition activée';

  @override
  String get repeatDescription =>
      'Créer automatiquement des tâches récurrentes';

  @override
  String get backfillMode => 'Mode de rattrapage';

  @override
  String get backfillModeDescription =>
      'Crée les tâches récurrentes manquées pour les jours précédents';

  @override
  String get backfillDays => 'Jours à remonter';

  @override
  String get backfillDaysDescription =>
      'Nombre maximal de jours à remonter (1–365, sans inclure aujourd\'hui)';

  @override
  String get backfillAutoComplete => 'Marquer automatiquement comme terminées';

  @override
  String get backfillDaysRangeError =>
      'Le nombre de jours doit être compris entre 1 et 365';

  @override
  String get backfillConflictTitle => 'Conflit de rattrapage';

  @override
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  ) {
    return 'La tâche \"$title\" commence le $startDate, mais le mode de rattrapage remonterait jusqu\'au $backfillStartDate. Quelle date doit être utilisée comme date la plus ancienne pour cette actualisation ?';
  }

  @override
  String get useStartDate => 'Utiliser la date de début';

  @override
  String get useBackfillDays => 'Utiliser la plage de rattrapage';

  @override
  String get activeRepeatTasks => 'Tâches répétitives actives';

  @override
  String get noRepeatTasks => 'Aucune tâche répétitive pour l\'instant';

  @override
  String get pauseRepeat => 'Pause';

  @override
  String get resumeRepeat => 'Reprendre';

  @override
  String get editRepeat => 'Modifier';

  @override
  String get deleteRepeat => 'Supprimer';

  @override
  String get repeatTaskConfirm => 'Supprimer la tâche répétitive';

  @override
  String get repeatTaskDeleteMessage =>
      'Cela supprimera toutes les tâches récurrentes générées à partir de ce modèle. Cette action ne peut être annulée.';

  @override
  String get manageRepeatTasks => 'Gérer les tâches répétitives';

  @override
  String get comingSoon => 'À venir !';

  @override
  String get todos => 'Tâches';

  @override
  String get schedule => 'Agenda';

  @override
  String get clearDataWarning =>
      'Cela supprimera définitivement toutes vos tâches et statistiques. Cette action ne peut être annulée.';

  @override
  String get dataClearedSuccess =>
      'Toutes les données ont été effacées avec succès';

  @override
  String get clearDataFailed => 'Échec de l\'effacement des données';

  @override
  String get history => 'Historique';

  @override
  String get stats => 'Statistiques';

  @override
  String get searchTodos => 'Rechercher des tâches';

  @override
  String get addTodo => 'Ajouter une tâche';

  @override
  String get addTodoHint => 'Quoi faire ?';

  @override
  String get todoTitle => 'Titre';

  @override
  String get todoDescription => 'Description';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get complete => 'Terminer';

  @override
  String get incomplete => 'Incomplet';

  @override
  String get allTodos => 'Toutes';

  @override
  String get activeTodos => 'Actives';

  @override
  String get completedTodos => 'Terminées';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get older => 'Plus ancien';

  @override
  String get totalTodos => 'Total des tâches';

  @override
  String get completedTodosCount => 'Terminées';

  @override
  String get activeTodosCount => 'Actives';

  @override
  String get completionRate => 'Taux de complétion';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get restore => 'Restauration';

  @override
  String get exportData => 'Exporter les données';

  @override
  String get importData => 'Importer les données';

  @override
  String get backupSuccess => 'Sauvegarde créée avec succès';

  @override
  String get backupFailed => 'Échec de la création de la sauvegarde';

  @override
  String get restoreSuccess => 'Données restaurées avec succès';

  @override
  String restoreFailed(Object error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get webBackupHint => 'Web: backups use download/upload.';

  @override
  String restoreWarning(Object fileName) {
    return 'Cela remplacera toutes les données actuelles par les données de \"$fileName\". Cette action ne peut être annulée. Continuer ?';
  }

  @override
  String get totalStorage => 'Stockage total';

  @override
  String get todosStorage => 'Tâches';

  @override
  String get cacheStorage => 'Cache';

  @override
  String get clearCache => 'Effacer le cache';

  @override
  String get cacheCleared => 'Cache effacé avec succès';

  @override
  String get filterByStatus => 'Filtrer par statut';

  @override
  String get sortBy => 'Trier par';

  @override
  String get newestFirst => 'Plus récent d\'abord';

  @override
  String get oldestFirst => 'Plus ancien d\'abord';

  @override
  String get alphabetical => 'Alphabétique';

  @override
  String get overview => 'Aperçu';

  @override
  String get weeklyProgress => 'Progression hebdomadaire';

  @override
  String get monthlyTrends => 'Tendances mensuelles';

  @override
  String get productivityOverview => 'Aperçu de la productivité';

  @override
  String get overallCompletionRate => 'Taux de complétion global';

  @override
  String get created => 'Créé';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get noRecentActivity => 'Aucune activité récente';

  @override
  String get todoDistribution => 'Distribution des tâches';

  @override
  String get bestPerformance => 'Meilleure performance';

  @override
  String get noCompletedTodosYet => 'Aucune tâche terminée pour l\'instant';

  @override
  String get completionRateDescription => 'de toutes les tâches terminées';

  @override
  String get fingerprintLock => 'Verrouillage par empreinte digitale';

  @override
  String get fingerprintLockSubtitle =>
      'Protéger la sécurité de l\'application avec empreinte digitale';

  @override
  String get fingerprintLockEnable =>
      'Activer le verrouillage par empreinte digitale';

  @override
  String get fingerprintLockDisable =>
      'Désactiver le verrouillage par empreinte digitale';

  @override
  String get fingerprintLockEnabled =>
      'Verrouillage par empreinte digitale activé';

  @override
  String get fingerprintLockDisabled =>
      'Verrouillage par empreinte digitale désactivé';

  @override
  String get fingerprintNotAvailable =>
      'Authentification par empreinte digitale non disponible';

  @override
  String get fingerprintNotEnrolled => 'Aucune empreinte digitale enregistrée';

  @override
  String get fingerprintAuthenticationFailed =>
      'Échec de l\'authentification par empreinte digitale';

  @override
  String get fingerprintAuthenticationSuccess =>
      'Authentification par empreinte digitale réussie';

  @override
  String get active => 'Actif';

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mer';

  @override
  String get thu => 'Jeu';

  @override
  String get fri => 'Ven';

  @override
  String get sat => 'Sam';

  @override
  String get sun => 'Dim';

  @override
  String get week1 => 'Semaine 1';

  @override
  String get week2 => 'Semaine 2';

  @override
  String get week3 => 'Semaine 3';

  @override
  String get week4 => 'Semaine 4';

  @override
  String withCompletedTodos(Object count) {
    return 'avec $count tâches terminées';
  }

  @override
  String get unableToLoadBackupStats =>
      'Impossible de charger les statistiques de sauvegarde';

  @override
  String get backupSummary => 'Résumé de la sauvegarde';

  @override
  String get itemsToBackup => 'Éléments à sauvegarder';

  @override
  String get dataSize => 'Taille des données';

  @override
  String get backupFiles => 'Fichiers de sauvegarde';

  @override
  String get backupSize => 'Taille de la sauvegarde';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get backupRestoreDescription =>
      'Créez une sauvegarde de vos données ou restaurez à partir d\'une sauvegarde précédente.';

  @override
  String get createBackup => 'Créer une sauvegarde';

  @override
  String get restoreBackup => 'Restaurer une sauvegarde';

  @override
  String get noBackupFilesFound => 'Aucun fichier de sauvegarde trouvé';

  @override
  String get createFirstBackup =>
      'Créez votre première sauvegarde pour commencer';

  @override
  String get refresh => 'Actualiser';

  @override
  String get restoreFromFile => 'Restaurer à partir de ce fichier';

  @override
  String get deleteFile => 'Supprimer le fichier';

  @override
  String get aboutBackups => 'À propos des sauvegardes';

  @override
  String get backupInfo1 =>
      '• Les sauvegardes contiennent toutes vos tâches et statistiques';

  @override
  String get backupInfo2 =>
      '• Stockez les fichiers de sauvegarde dans un endroit sûr';

  @override
  String get backupInfo3 =>
      '• Les sauvegardes régulières aident à prévenir la perte de données';

  @override
  String get backupInfo4 =>
      '• Vous pouvez restaurer à partir de n\'importe quel fichier de sauvegarde';

  @override
  String get backupCreatedSuccess => 'Sauvegarde créée avec succès';

  @override
  String get noBackupFilesAvailable =>
      'Aucun fichier de sauvegarde disponible pour la restauration';

  @override
  String get selectBackupFile => 'Sélectionner un fichier de sauvegarde';

  @override
  String get confirmRestore => 'Confirmer la restauration';

  @override
  String dataRestoredSuccess(Object fileName) {
    return 'Données restaurées avec succès à partir de \"$fileName\"';
  }

  @override
  String get deleteBackupFile => 'Supprimer le fichier de sauvegarde';

  @override
  String deleteBackupWarning(Object fileName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$fileName\" ? Cette action ne peut être annulée.';
  }

  @override
  String backupFileDeletedSuccess(Object fileName) {
    return 'Fichier de sauvegarde \"$fileName\" supprimé avec succès';
  }

  @override
  String get backupFileNotFound => 'Fichier de sauvegarde introuvable';

  @override
  String invalidFilePath(Object fileName) {
    return 'Chemin de fichier invalide pour \"$fileName\"';
  }

  @override
  String get failedToDeleteFile => 'Échec de la suppression du fichier';

  @override
  String get files => 'fichiers';

  @override
  String get storageManagement => 'Gestion du stockage';

  @override
  String get storageOverview => 'Aperçu du stockage';

  @override
  String get storageAnalytics => 'Analyse de stockage';

  @override
  String get noPendingRequests => 'Aucune demande en attente';

  @override
  String get request => 'Demande';

  @override
  String get unknown => 'Inconnu';

  @override
  String get waiting => 'En attente';

  @override
  String get noRecentRequests => 'Aucune demande récente';

  @override
  String get requestCompleted => 'Demande terminée';

  @override
  String get noTodosToDisplay => 'Aucune tâche à afficher';

  @override
  String get todoStatusDistribution => 'Distribution du statut des tâches';

  @override
  String get completed => 'Terminé';

  @override
  String get pending => 'En attente';

  @override
  String get dataStorageUsage => 'Utilisation du stockage de données';

  @override
  String get total => 'Total';

  @override
  String get storageCleanup => 'Nettoyage du stockage';

  @override
  String get cleanupDescription =>
      'Libérez de l\'espace de stockage en supprimant les données inutiles :';

  @override
  String get clearCompletedTodos => 'Effacer les tâches terminées';

  @override
  String get clearOldStatistics => 'Effacer les anciennes statistiques';

  @override
  String get clearBackupFiles => 'Effacer les fichiers de sauvegarde';

  @override
  String get cleanupCompleted => 'Nettoyage terminé';

  @override
  String todosDeleted(Object count) {
    return '$count tâches supprimées';
  }

  @override
  String statisticsDeleted(Object count) {
    return '$count statistiques supprimées';
  }

  @override
  String backupFilesDeleted(Object count) {
    return '$count fichiers de sauvegarde supprimés';
  }

  @override
  String get cleanupFailed => 'Échec du nettoyage';

  @override
  String get easyTodo => 'Easy Todo';

  @override
  String copiedToClipboard(Object url) {
    return 'Copié dans le presse-papiers : $url';
  }

  @override
  String cannotOpenLink(Object url) {
    return 'Impossible d\'ouvrir le lien, copié dans le presse-papiers : $url';
  }

  @override
  String get email => 'Email';

  @override
  String get github => 'GitHub';

  @override
  String get website => 'Site web';

  @override
  String get noTodosMatchSearch =>
      'Aucune tâche ne correspond à votre recherche';

  @override
  String get noCompletedTodos => 'Aucune tâche terminée';

  @override
  String get noActiveTodos => 'Aucune tâche active';

  @override
  String get noTodosYet => 'Aucune tâche pour l\'instant';

  @override
  String get deleteTodoConfirmation =>
      'Êtes-vous sûr de vouloir supprimer cette tâche ?';

  @override
  String get createdLabel => 'Créé : ';

  @override
  String get completedLabel => 'Terminé : ';

  @override
  String get filterByTime => 'Filtrer par temps';

  @override
  String get sortByTime => 'Trier par temps';

  @override
  String get ascending => 'Croissant';

  @override
  String get descending => 'Décroissant';

  @override
  String get threeDays => 'Trois jours';

  @override
  String minutesAgoWithCount(Object count) {
    return 'il y a $count minutes';
  }

  @override
  String hoursAgoWithCount(Object count) {
    return 'il y a $count heures';
  }

  @override
  String daysAgoWithCount(Object count) {
    return 'il y a $count jours';
  }

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get dailySummary => 'Résumé quotidien';

  @override
  String get dailySummaryTime => 'Heure du résumé quotidien';

  @override
  String get dailySummaryDescription =>
      'Recevoir un résumé quotidien des tâches en attente';

  @override
  String get defaultReminderSettings => 'Paramètres de rappel par défaut';

  @override
  String get enableDefaultReminders => 'Activer les rappels par défaut';

  @override
  String get reminderTimeBefore => 'Temps de rappel avant l\'échéance';

  @override
  String minutesBefore(Object count) {
    return '$count minutes avant';
  }

  @override
  String get notificationPermissions => 'Permissions de notification';

  @override
  String get grantPermissions => 'Accorder les permissions';

  @override
  String get permissionsGranted => 'Permissions accordées';

  @override
  String get permissionsDenied => 'Permissions refusées';

  @override
  String get testNotification => 'Tester les notifications';

  @override
  String get sendTestNotification => 'Envoyer une notification de test';

  @override
  String get notificationTestSent => 'Notification de test envoyée avec succès';

  @override
  String get reminderTime => 'Heure de rappel';

  @override
  String get setReminder => 'Définir un rappel';

  @override
  String reminderSet(Object time) {
    return 'Rappel défini pour $time';
  }

  @override
  String get cancelReminder => 'Annuler le rappel';

  @override
  String get noReminderSet => 'Aucun rappel défini';

  @override
  String get enableReminder => 'Activer le rappel';

  @override
  String get reminderOptions => 'Options de rappel';

  @override
  String get pomodoroTimer => 'Minuteur Pomodoro';

  @override
  String get pomodoroSettings => 'Paramètres Pomodoro';

  @override
  String get workDuration => 'Durée de travail';

  @override
  String get breakDuration => 'Durée de pause';

  @override
  String get longBreakDuration => 'Durée de longue pause';

  @override
  String get sessionsUntilLongBreak => 'Sessions jusqu\'à la longue pause';

  @override
  String get minutes => 'minutes';

  @override
  String get sessions => 'sessions';

  @override
  String get settingsSaved => 'Paramètres enregistrés avec succès';

  @override
  String get focusTime => 'Temps de concentration';

  @override
  String get clearOldPomodoroSessions =>
      'Effacer les anciennes sessions Pomodoro';

  @override
  String pomodoroSessionsDeleted(Object count) {
    return '$count sessions Pomodoro supprimées';
  }

  @override
  String get breakTime => 'Temps de pause';

  @override
  String get start => 'Démarrer';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get stop => 'Arrêter';

  @override
  String get timeSpent => 'Temps passé';

  @override
  String get pomodoroStats => 'Statistiques Pomodoro';

  @override
  String get sessionsCompleted => 'Sessions terminées';

  @override
  String get totalTime => 'Temps total';

  @override
  String get averageTime => 'Temps moyen';

  @override
  String get focusSessions => 'Sessions de concentration';

  @override
  String get pomodoroSessions => 'Sessions Pomodoro';

  @override
  String get totalFocusTime => 'Temps total de concentration';

  @override
  String get weeklyPomodoroStats => 'Statistiques Pomodoro hebdomadaires';

  @override
  String get totalSessions => 'Sessions totales';

  @override
  String get averageSessions => 'Sessions moyennes';

  @override
  String get monthlyPomodoroStats => 'Statistiques Pomodoro mensuelles';

  @override
  String get averagePerWeek => 'Moyenne par semaine';

  @override
  String get pomodoroOverview => 'Aperçu Pomodoro';

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get checkUpdatesSubtitle => 'Rechercher de nouvelles versions';

  @override
  String get checkingForUpdates => 'Vérification des mises à jour';

  @override
  String get pleaseWait =>
      'Veuillez patienter pendant que nous vérifions les mises à jour...';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get requiredUpdate => 'Mise à jour requise';

  @override
  String versionAvailable(Object version) {
    return 'La version $version est disponible !';
  }

  @override
  String get whatsNew => 'Quoi de neuf:';

  @override
  String get noUpdatesAvailable => 'Aucune mise à jour disponible';

  @override
  String get youHaveLatestVersion => 'Vous avez la dernière version';

  @override
  String get updateNow => 'Mettre à jour maintenant';

  @override
  String get later => 'Plus tard';

  @override
  String get downloadingUpdate => 'Téléchargement de la mise à jour';

  @override
  String get downloadUpdate => 'Télécharger la mise à jour';

  @override
  String get downloadFrom => 'Téléchargement de la mise à jour depuis :';

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String get couldNotOpenDownloadUrl =>
      'Impossible d\'ouvrir l\'URL de téléchargement';

  @override
  String get updateCheckFailed => 'Échec de la vérification des mises à jour';

  @override
  String get forceUpdateMessage =>
      'Cette mise à jour est requise pour continuer à utiliser l\'application';

  @override
  String get optionalUpdateMessage =>
      'Vous pouvez mettre à jour maintenant ou plus tard';

  @override
  String get storagePermissionDenied => 'Permission de stockage refusée';

  @override
  String get cannotAccessStorage => 'Impossible d\'accéder au stockage';

  @override
  String get updateDownloadSuccess => 'Mise à jour téléchargée avec succès';

  @override
  String get installUpdate => 'Installer la mise à jour';

  @override
  String get startingInstaller => 'Démarrage de l\'installateur...';

  @override
  String get updateFileNotFound =>
      'Fichier de mise à jour introuvable, veuillez télécharger à nouveau';

  @override
  String get installPermissionRequired => 'Permission d\'installation requise';

  @override
  String get installPermissionDescription =>
      'L\'installation des mises à jour d\'application nécessite la permission \"Installer des applications inconnues\". Veuillez activer cette permission pour Easy Todo dans les paramètres.';

  @override
  String get needInstallPermission =>
      'La permission d\'installation est requise pour mettre à jour l\'application';

  @override
  String installFailed(Object error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String installLaunchFailed(Object error) {
    return 'Échec du lancement de l\'installation : $error';
  }

  @override
  String get storagePermissionTitle => 'Permission de stockage requise';

  @override
  String get storagePermissionDescription =>
      'Pour télécharger et installer les mises à jour d\'application, Easy Todo a besoin d\'accéder au stockage de l\'appareil.';

  @override
  String get permissionNote =>
      'En cliquant sur \"Autoriser\", vous accorderez à l\'application les permissions suivantes :';

  @override
  String get accessDeviceStorage => '• Accéder au stockage de l\'appareil';

  @override
  String get downloadFilesToDevice =>
      '• Télécharger des fichiers sur l\'appareil';

  @override
  String get allow => 'Autoriser';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get permissionDeniedMessage =>
      'La permission de stockage a été refusée de manière permanente. Veuillez activer manuellement la permission dans les paramètres système et réessayer.';

  @override
  String get cannotOpenSettings =>
      'Impossible d\'ouvrir la page des paramètres';

  @override
  String get autoUpdate => 'Mise à jour automatique';

  @override
  String get autoUpdateSubtitle =>
      'Vérifier automatiquement les mises à jour au démarrage de l\'application';

  @override
  String get autoUpdateEnabled => 'Mise à jour automatique activée';

  @override
  String get autoUpdateDisabled => 'Mise à jour automatique désactivée';

  @override
  String get exitApp => 'Quitter l\'application';

  @override
  String get viewSettings => 'Paramètres d\'affichage';

  @override
  String get viewDisplay => 'Affichage';

  @override
  String get viewDisplaySubtitle => 'Configurer le contenu est affiché';

  @override
  String get todoViewSettings => 'Paramètres d\'affichage des tâches';

  @override
  String get historyViewSettings => 'Paramètres d\'affichage de l\'historique';

  @override
  String get scheduleLayoutSettings => 'Paramètres de disposition du planning';

  @override
  String get scheduleLayoutSettingsSubtitle =>
      'Personnaliser la plage horaire et les jours';

  @override
  String get viewMode => 'Mode d\'affichage';

  @override
  String get listView => 'Vue en liste';

  @override
  String get stackingView => 'Vue en pile';

  @override
  String get calendarView => 'Vue calendrier';

  @override
  String get openInNewPage => 'Ouvrir dans une nouvelle page';

  @override
  String get openInNewPageSubtitle =>
      'Ouvrir les vues dans de nouvelles pages au lieu de popups';

  @override
  String get historyViewMode => 'Mode d\'affichage de l\'historique';

  @override
  String get scheduleTimeRange => 'Plage horaire';

  @override
  String get scheduleVisibleWeekdays => 'Jours affichés';

  @override
  String get scheduleLabelTextScale => 'Échelle du texte des étiquettes';

  @override
  String get scheduleAtLeastOneDay => 'Gardez au moins un jour sélectionné.';

  @override
  String get dayDetails => 'Détails du jour';

  @override
  String get todoCount => 'Nombre de tâches';

  @override
  String get completedCount => 'terminé';

  @override
  String get totalCount => 'total';

  @override
  String get appLongDescription =>
      'Easy Todo est une application de liste de tâches propre, élégante et puissante conçue pour vous aider à organiser vos tâches quotidiennes efficacement. Avec une belle conception d\'interface utilisateur, un suivi complet des statistiques, une intégration API transparente et une prise en charge de plusieurs langues, Easy Todo rend la gestion des tâches simple et agréable.';

  @override
  String get cannotDeleteRepeatTodo =>
      'Impossible de supprimer les tâches répétitives';

  @override
  String get appTitle => 'Easy Todo';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterTodayTodos => 'Tâches du jour';

  @override
  String get filterCompleted => 'Terminées';

  @override
  String get filterThisWeek => 'Cette semaine';

  @override
  String get resetButton => 'Réinitialiser';

  @override
  String get applyButton => 'Appliquer';

  @override
  String get repeatTaskWarning =>
      'Cette tâche est générée automatiquement à partir d\'une tâche répétitive et sera régénérée demain après suppression.';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get repeatTaskDialogTitle => 'Élément de tâche répétitive';

  @override
  String get repeatTaskExplanation =>
      'Cette tâche est créée automatiquement à partir d\'un modèle de tâche répétitive. La supprimer n\'affectera pas la tâche répétitive elle-même - une nouvelle tâche sera générée demain selon le calendrier de répétition. Si vous voulez arrêter la génération de ces tâches, vous devez modifier ou supprimer le modèle de tâche répétitive dans la section de gestion des tâches répétitives.';

  @override
  String get iUnderstand => 'Je comprends';

  @override
  String get authenticateToContinue =>
      'Veuillez vous authentifier pour continuer à utiliser l\'application';

  @override
  String get retry => 'Réessayer';

  @override
  String get biometricReason =>
      'Veuillez utiliser l\'authentification biométrique pour vérifier votre identité';

  @override
  String get biometricHint => 'Utiliser l\'authentification biométrique';

  @override
  String get biometricNotRecognized =>
      'Biométrie non reconnue, veuillez réessayer';

  @override
  String get biometricSuccess => 'Authentification biométrique réussie';

  @override
  String get biometricVerificationTitle => 'Vérification biométrique';

  @override
  String addTodoError(Object error) {
    return 'Échec de l\'ajout de la tâche : $error';
  }

  @override
  String get titleRequired => 'Veuillez entrer un titre';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get japanese => '日本語';

  @override
  String get korean => '한국어';

  @override
  String repeatTaskCreateError(Object error) {
    return 'Échec de la création de la tâche répétitive : $error';
  }

  @override
  String get repeatTaskTitleRequired => 'Veuillez entrer un titre';

  @override
  String get importBackup => 'Importer la sauvegarde';

  @override
  String get shareBackup => 'Partager la sauvegarde';

  @override
  String get cannotAccessFile => 'Impossible d\'accéder au fichier sélectionné';

  @override
  String get invalidBackupFormat => 'Format de sauvegarde invalide';

  @override
  String get importBackupTitle => 'Importer la sauvegarde';

  @override
  String get import => 'Importer';

  @override
  String get backupShareSuccess => 'Fichier de sauvegarde partagé avec succès';

  @override
  String get requiredUpdateAvailable =>
      'Une mise à jour requise est disponible. Veuillez mettre à jour pour continuer à utiliser l\'application.';

  @override
  String updateCheckError(Object error) {
    return 'Erreur lors de la vérification des mises à jour : $error';
  }

  @override
  String importingBackupFile(Object fileName) {
    return 'Sur le point d\'importer le fichier de sauvegarde \"$fileName\", cela écrasera toutes les données actuelles. Continuer ?';
  }

  @override
  String hardcodedStringFound(Object fileName) {
    return '即将导入备份文件 \"$fileName\"，这将覆盖当前的所有数据。确定继续吗？';
  }

  @override
  String get testNotifications => 'Tester les notifications';

  @override
  String get testNotificationChannel => 'Canal de notification de test';

  @override
  String get testNotificationContent =>
      'Ceci est une notification de test pour vérifier que les notifications fonctionnent correctement.';

  @override
  String get failedToSendTestNotification =>
      'Échec de l\'envoi de la notification de test : ';

  @override
  String get failedToCheckForUpdates =>
      'Échec de la vérification des mises à jour';

  @override
  String get errorCheckingForUpdates =>
      'Erreur lors de la vérification des mises à jour : ';

  @override
  String get updateFileName => 'easy_todo_update.apk';

  @override
  String get unknownDate => 'Date inconnue';

  @override
  String get restoreSuccessPrefix => 'Restauré ';

  @override
  String get restoreSuccessSuffix => ' tâches';

  @override
  String get importSuccessPrefix =>
      'Fichier de sauvegarde importé avec succès, restauré ';

  @override
  String get importFailedPrefix => 'Échec de l\'importation : ';

  @override
  String get cleanupFailedPrefix => 'Échec du nettoyage : ';

  @override
  String get developerName => '梦凌汐 (MeowLynxSea)';

  @override
  String get createYourFirstRepeatTask =>
      'Créez votre première tâche répétitive pour commencer';

  @override
  String get rate => 'Évaluer';

  @override
  String get openSource => 'Open Source';

  @override
  String get repeatTodoTest => 'Test de tâche répétitive';

  @override
  String get repeatTodos => 'Tâches répétitives';

  @override
  String get addRepeatTodo => 'Ajouter une tâche répétitive';

  @override
  String get checkRepeatTodos => 'Vérifier les tâches répétitives';

  @override
  String get authenticateToAccessApp =>
      'Veuillez vous authentifier pour continuer à utiliser l\'application';

  @override
  String get backupFileSubject => 'Fichier de sauvegarde Easy Todo';

  @override
  String get shareFailedPrefix => 'Échec du partage : ';

  @override
  String get schedulingTodoReminder => 'Planification du rappel de tâche \"';

  @override
  String get todoReminderTimerScheduled =>
      'Minuteur de rappel de tâche planifié avec succès';

  @override
  String get allRemindersRescheduled =>
      'Tous les rappels replanifiés avec succès';

  @override
  String get allTimersCleared => 'Tous les minuteurs effacés';

  @override
  String get allNotificationChannelsCreated =>
      'Tous les canaux de notification créés avec succès';

  @override
  String get utc => 'UTC';

  @override
  String get gmt => 'GMT';

  @override
  String get authenticateToEnableFingerprint =>
      'Veuillez vous authentifier pour activer le verrouillage par empreinte digitale';

  @override
  String get authenticateToDisableFingerprint =>
      'Veuillez vous authentifier pour désactiver le verrouillage par empreinte digitale';

  @override
  String get authenticateToAccessWithFingerprint =>
      'Veuillez utiliser la vérification par empreinte digitale pour accéder à l\'application';

  @override
  String get authenticateToAccessWithBiometric =>
      'Veuillez utiliser la vérification biométrique pour vérifier votre identité pour continuer';

  @override
  String get authenticateToClearData =>
      'Veuillez utiliser la vérification biométrique pour effacer toutes les données';

  @override
  String get clearDataFailedPrefix => 'Échec de l\'effacement des données : ';

  @override
  String progressFormat(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String timeFormat(Object hour, Object minute) {
    return '$hour:$minute';
  }

  @override
  String completedFormat(Object completed, Object total) {
    return '$completed/$total';
  }

  @override
  String countFormat(Object count) {
    return '$count ';
  }

  @override
  String get deleteAction => 'supprimer';

  @override
  String get toggleReminderAction => 'toggle_reminder';

  @override
  String get pomodoroAction => 'pomodoro';

  @override
  String get completedKey => 'terminé';

  @override
  String get totalKey => 'total';

  @override
  String get zh => 'zh';

  @override
  String get en => 'en';

  @override
  String everyNDays(Object count) {
    return 'Tous les $count jours';
  }

  @override
  String get dataStatistics => 'Statistiques de données';

  @override
  String get dataStatisticsDescription =>
      'Nombre de tâches répétitives avec statistiques de données activées';

  @override
  String get statisticsModes => 'Modes de statistiques';

  @override
  String get statisticsModesDescription =>
      'Sélectionner les méthodes d\'analyse statistiques à appliquer';

  @override
  String get dataUnit => 'Unité de données';

  @override
  String get dataUnitHint => 'ex: kg, km, \$, %';

  @override
  String get statisticsModeAverage => 'Moyenne';

  @override
  String get statisticsModeGrowth => 'Croissance';

  @override
  String get statisticsModeExtremum => 'Extrême';

  @override
  String get statisticsModeTrend => 'Tendance';

  @override
  String get enterDataToComplete => 'Entrer les données pour terminer';

  @override
  String get enterDataDescription =>
      'Cette tâche répétitive nécessite une saisie de données avant complétion';

  @override
  String get dataValue => 'Valeur des données';

  @override
  String get dataValueHint => 'Entrer une valeur numérique';

  @override
  String get dataValueRequired =>
      'Veuillez entrer une valeur de données pour terminer cette tâche';

  @override
  String get invalidDataValue => 'Veuillez entrer un nombre valide';

  @override
  String get dataStatisticsTab => 'Statistiques de données';

  @override
  String get selectRepeatTask => 'Sélectionner une tâche répétitive';

  @override
  String get selectRepeatTaskHint =>
      'Choisir une tâche répétitive pour voir ses statistiques';

  @override
  String get timePeriod => 'Période de temps';

  @override
  String get timePeriodToday => 'Aujourd\'hui';

  @override
  String get timePeriodThisWeek => 'Cette semaine';

  @override
  String get timePeriodThisMonth => 'Ce mois';

  @override
  String get timePeriodOverview => 'Aperçu';

  @override
  String get timePeriodCustom => 'Plage personnalisée';

  @override
  String get selectCustomRange => 'Sélectionner une plage de dates';

  @override
  String get noRepeatTasksWithStats =>
      'Aucune tâche répétitive avec statistiques activées';

  @override
  String get noDataAvailable =>
      'Aucune donnée disponible pour la période sélectionnée';

  @override
  String get dataProgressToday => 'Progression d\'aujourd\'hui';

  @override
  String get averageValue => 'Valeur moyenne';

  @override
  String get totalValue => 'Valeur totale';

  @override
  String get dataPoints => 'Points de données';

  @override
  String get growthRate => 'Taux de croissance';

  @override
  String get trendAnalysis => 'Analyse de tendance';

  @override
  String get maximumValue => 'Maximum';

  @override
  String get minimumValue => 'Minimum';

  @override
  String get extremumAnalysis => 'Analyse d\'extrême';

  @override
  String get statisticsSummary => 'Résumé des statistiques';

  @override
  String get dataVisualization => 'Visualisation des données';

  @override
  String get chartTitle => 'Tendances des données';

  @override
  String get lineChart => 'Graphique en ligne';

  @override
  String get barChart => 'Graphique en barres';

  @override
  String get showValueOnDrag =>
      'Afficher la valeur lors du glissement sur le graphique';

  @override
  String get dragToShowValue =>
      'Glisser sur le graphique pour voir les valeurs détaillées';

  @override
  String get analytics => 'Analytique';

  @override
  String get dataEntry => 'Saisie de données';

  @override
  String get statisticsEnabled => 'Statistiques activées';

  @override
  String get dataCollection => 'Collecte de données';

  @override
  String repeatTodoWithStats(Object count) {
    return 'Tâches répétitives avec statistiques : $count';
  }

  @override
  String dataEntries(Object count) {
    return 'Entrées de données : $count';
  }

  @override
  String withDataValues(Object count) {
    return 'avec valeurs : $count';
  }

  @override
  String totalDataSize(Object size) {
    return 'Taille totale des données : $size';
  }

  @override
  String get dataBackupSupported =>
      'Sauvegarde et restauration de données prises en charge';

  @override
  String get repeatTasks => 'Tâches répétitives';

  @override
  String get dataStatisticsEnabled => 'Statistiques de données activées';

  @override
  String get statisticsData => 'Données de statistiques';

  @override
  String get dataStatisticsEnabledShort => 'Stats de données';

  @override
  String get dataWithValue => 'Avec valeurs';

  @override
  String get noDataStatisticsEnabled => 'Aucune statistique de données activée';

  @override
  String get enableDataStatisticsHint =>
      'Activer les statistiques de données pour les tâches répétitives pour voir l\'analytique';

  @override
  String get selectTimePeriod => 'Sélectionner une période de temps';

  @override
  String get customRange => 'Plage personnalisée';

  @override
  String get selectRepeatTaskToViewData =>
      'Sélectionner une tâche répétitive pour voir ses statistiques de données';

  @override
  String get noStatisticsData => 'Aucune donnée de statistiques disponible';

  @override
  String get completeSomeTodosToSeeData =>
      'Terminez quelques tâches avec des données pour voir les statistiques';

  @override
  String get totalEntries => 'Entrées totales';

  @override
  String get average => 'Moyenne';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get totalGrowth => 'Croissance totale';

  @override
  String get notEnoughDataForCharts =>
      'Pas assez de données pour les graphiques';

  @override
  String get averageTrend => 'Tendance moyenne';

  @override
  String get averageChartDescription =>
      'Montre les valeurs moyennes au fil du temps avec analyse de tendance';

  @override
  String get trendDirection => 'Direction de la tendance';

  @override
  String get trendStrength => 'Force de la tendance';

  @override
  String get growthAnalysis => 'Analyse de croissance';

  @override
  String get range => 'Plage';

  @override
  String get stableTrendDescription =>
      'Tendance stable avec variation minimale';

  @override
  String get weakTrendDescription =>
      'Tendance faible avec certaines variations';

  @override
  String get moderateTrendDescription =>
      'Tendance modérée avec direction claire';

  @override
  String get strongTrendDescription =>
      'Tendance forte avec variation significative';

  @override
  String get invalidNumberFormat => 'Format de nombre invalide';

  @override
  String get dataUnitRequired =>
      'L\'unité de données est requise lorsque les statistiques de données sont activées';

  @override
  String get growth => 'Croissance';

  @override
  String get extremum => 'Extrême';

  @override
  String get trend => 'Tendance';

  @override
  String get dataInputRequired =>
      'La saisie de données est requise pour terminer cette tâche';

  @override
  String get todayProgress => 'Progression d\'aujourd\'hui';

  @override
  String get dataProgress => 'Progression des données';

  @override
  String get noDataForToday => 'Aucune donnée pour aujourd\'hui';

  @override
  String get weeklyDataStats => 'Statistiques de données hebdomadaires';

  @override
  String get noDataForThisWeek => 'Aucune donnée pour cette semaine';

  @override
  String get daysTracked => 'Jours suivis';

  @override
  String get monthlyDataStats => 'Statistiques de données mensuelles';

  @override
  String get noDataForThisMonth => 'Aucune donnée pour ce mois';

  @override
  String get customDateRange => 'Plage de dates personnalisée';

  @override
  String get allData => 'Toutes les données';

  @override
  String get breakdownByTask => 'Répartition par tâche';

  @override
  String get clear => 'Effacer';

  @override
  String get trendUp => 'Tendance à la hausse';

  @override
  String get trendDown => 'Tendance à la baisse';

  @override
  String get trendStable => 'Tendance stable';

  @override
  String get needMoreDataToAnalyze =>
      'Besoin de collecter plus de données pour analyser';

  @override
  String get taskCompleted => 'Tâche terminée';

  @override
  String get taskWithdrawn => 'Tâche retirée';

  @override
  String get noDefaultSettings =>
      'Aucun paramètre par défaut trouvé, création des paramètres par défaut';

  @override
  String get authenticateForSensitiveOperation =>
      'Veuillez utiliser l\'authentification biométrique pour vérifier votre identité';

  @override
  String get insufficientData => 'Données insuffisantes';

  @override
  String get stable => 'Stable';

  @override
  String get strongUpward => 'Forte hausse';

  @override
  String get upward => 'À la hausse';

  @override
  String get strongDownward => 'Forte baisse';

  @override
  String get downward => 'À la baisse';

  @override
  String get repeatTasksRefreshedSuccessfully =>
      'Tâches répétitives actualisées avec succès';

  @override
  String get errorRefreshingRepeatTasks =>
      'Erreur lors de l\'actualisation des tâches répétitives';

  @override
  String get forceRefresh => 'Forcer l\'actualisation';

  @override
  String get errorLoadingRepeatTasks =>
      'Erreur lors du chargement des tâches répétitives';

  @override
  String get pleaseCheckStoragePermissions =>
      'Veuillez vérifier vos permissions de stockage et réessayer';

  @override
  String get todoReminders => 'Rappels de tâches';

  @override
  String get notificationsForIndividualTodoReminders =>
      'Notifications pour les rappels de tâches individuels';

  @override
  String get notificationsForDailySummary =>
      'Résumé quotidien des tâches en attente';

  @override
  String get pomodoroComplete => 'Pomodoro terminé';

  @override
  String get notificationsForPomodoroSessions =>
      'Notifications lorsque les sessions pomodoro sont terminées';

  @override
  String get dailyTodoSummary => 'Résumé quotidien des tâches';

  @override
  String youHavePendingTodos(Object count, Object n, Object s) {
    return 'Vous avez $count tâche$s en attente à terminer';
  }

  @override
  String greatJobTimeForBreak(Object breakType) {
    return 'Excellent travail ! Temps pour une pause $breakType';
  }

  @override
  String get shortBreak => 'courte';

  @override
  String get longBreak => 'longue';

  @override
  String get themeColorMysteriousPurple => 'Pourpre mystérieux';

  @override
  String get themeColorSkyBlue => 'Bleu ciel';

  @override
  String get themeColorGemGreen => 'Vert émeraude';

  @override
  String get themeColorLemonYellow => 'Jaune citron';

  @override
  String get themeColorFlameRed => 'Rouge flamme';

  @override
  String get themeColorElegantPurple => 'Pourpre élégant';

  @override
  String get themeColorCherryPink => 'Rose cerise';

  @override
  String get themeColorForestCyan => 'Cyan forestier';

  @override
  String get aiSettings => 'Paramètres IA';

  @override
  String get aiFeatures => 'Fonctionnalités IA';

  @override
  String get aiEnabled => 'Fonctionnalités IA activées';

  @override
  String get aiDisabled => 'Fonctionnalités IA désactivées';

  @override
  String get enableAIFeatures => 'Activer les Fonctionnalités IA';

  @override
  String get enableAIFeaturesSubtitle =>
      'Utilisez l\'intelligence artificielle pour améliorer votre expérience de tâches';

  @override
  String get apiConfiguration => 'Configuration API';

  @override
  String get apiEndpoint => 'Point de terminaison API';

  @override
  String get pleaseEnterApiEndpoint =>
      'Veuillez entrer le point de terminaison API';

  @override
  String get invalidApiEndpoint =>
      'Veuillez entrer un point de terminaison API valide';

  @override
  String get apiKey => 'Clé API';

  @override
  String get pleaseEnterApiKey => 'Veuillez entrer la clé API';

  @override
  String get modelName => 'Nom du modèle';

  @override
  String get pleaseEnterModelName => 'Veuillez entrer le nom du modèle';

  @override
  String get advancedSettings => 'Paramètres avancés';

  @override
  String get timeout => 'Délai d\'attente (ms)';

  @override
  String get pleaseEnterTimeout => 'Veuillez entrer le délai d\'attente';

  @override
  String get invalidTimeout =>
      'Veuillez entrer un délai d\'attente valide (minimum 1000ms)';

  @override
  String get temperature => 'Température';

  @override
  String get pleaseEnterTemperature => 'Veuillez entrer la température';

  @override
  String get invalidTemperature =>
      'Veuillez entrer une température valide (0.0 - 2.0)';

  @override
  String get maxTokens => 'Tokens maximum';

  @override
  String get pleaseEnterMaxTokens => 'Veuillez entrer les tokens maximum';

  @override
  String get invalidMaxTokens =>
      'Veuillez entrer des tokens maximum valides (minimum 1)';

  @override
  String get rateLimit => 'Limite de Débit';

  @override
  String get rateLimitSubtitle => 'Nombre maximum de requêtes par minute';

  @override
  String get pleaseEnterRateLimit => 'Veuillez entrer la limite de débit';

  @override
  String get invalidRateLimit =>
      'La limite de débit doit être comprise entre 1 et 100';

  @override
  String get rateAndTokenLimits => 'Limites de Débit et de Tokens';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get connectionSuccessful => 'Connexion réussie !';

  @override
  String get connectionFailed => 'Échec de la connexion';

  @override
  String get aiFeaturesToggle => 'Basculer les fonctionnalités IA';

  @override
  String get autoCategorization => 'Catégorisation automatique';

  @override
  String get autoCategorizationSubtitle =>
      'Catégorisez automatiquement vos tâches';

  @override
  String get prioritySorting => 'Tri par priorité';

  @override
  String get prioritySortingSubtitle =>
      'Évaluez l\'importance et la priorité des tâches';

  @override
  String get motivationalMessages => 'Messages motivationnels';

  @override
  String get motivationalMessagesSubtitle =>
      'Générez des messages encourageants basés sur votre progression';

  @override
  String get smartNotifications => 'Notifications intelligentes';

  @override
  String get smartNotificationsSubtitle =>
      'Créez un contenu de notification personnalisé';

  @override
  String get completionMotivation => 'Motivation de complétion';

  @override
  String get completionMotivationSubtitle =>
      'Affichez la motivation basée sur le taux de complétion quotidien';

  @override
  String get aiCategoryWork => 'Travail';

  @override
  String get aiCategoryPersonal => 'Personnel';

  @override
  String get aiCategoryStudy => 'Étude';

  @override
  String get aiCategoryHealth => 'Santé';

  @override
  String get aiCategoryFitness => 'Fitness';

  @override
  String get aiCategoryFinance => 'Finances';

  @override
  String get aiCategoryShopping => 'Shopping';

  @override
  String get aiCategoryFamily => 'Famille';

  @override
  String get aiCategorySocial => 'Social';

  @override
  String get aiCategoryHobby => 'Loisirs';

  @override
  String get aiCategoryTravel => 'Voyage';

  @override
  String get aiCategoryOther => 'Autre';

  @override
  String get aiPriorityHigh => 'Haute priorité';

  @override
  String get aiPriorityMedium => 'Priorité moyenne';

  @override
  String get aiPriorityLow => 'Basse priorité';

  @override
  String get aiPriorityUrgent => 'Urgent';

  @override
  String get aiPriorityImportant => 'Important';

  @override
  String get aiPriorityNormal => 'Normal';

  @override
  String get selectTodoForPomodoro => 'Sélectionner une tâche';

  @override
  String get pomodoroDescription =>
      'Choisissez une tâche pour commencer votre session de concentration Pomodoro';

  @override
  String get noTodosForPomodoro => 'Aucune tâche disponible';

  @override
  String get createTodoForPomodoro => 'Veuillez d\'abord créer quelques tâches';

  @override
  String get todaySessions => 'Sessions d\'aujourd\'hui';

  @override
  String get startPomodoro => 'Démarrer Pomodoro';

  @override
  String get aiDebugInfo => 'Informations de Débogage IA';

  @override
  String get processingUnprocessedTodos =>
      'Traitement des tâches non traitées avec IA';

  @override
  String get processAllTodosWithAI => 'Traiter Toutes les Tâches avec IA';

  @override
  String todayTimeFormat(Object time) {
    return 'Aujourd\'hui $time';
  }

  @override
  String tomorrowTimeFormat(Object time) {
    return 'Demain $time';
  }

  @override
  String get deleteTodoDialogTitle => 'Supprimer';

  @override
  String get deleteTodoDialogMessage =>
      'Êtes-vous sûr de vouloir supprimer cette tâche ?';

  @override
  String get deleteTodoDialogCancel => 'Annuler';

  @override
  String get deleteTodoDialogDelete => 'Supprimer';

  @override
  String get customPersona => 'Persona personnalisée';

  @override
  String get personaPrompt => 'Invite de persona';

  @override
  String get personaPromptHint =>
      'ex., Vous êtes un assistant amical qui utilise l\'humour et les emojis...';

  @override
  String get personaPromptDescription =>
      'Personnalisez la personnalité de l\'IA pour les notifications. Ceci sera appliqué aux rappels de tâches et aux résumés quotidiens.';

  @override
  String get personaExample1 =>
      'Vous êtes un entraîneur motivant qui encourage avec un renforcement positif';

  @override
  String get personaExample2 =>
      'Vous êtes un assistant humoristique qui utilise de l\'humour léger et des emojis';

  @override
  String get personaExample3 =>
      'Vous êtes un expert en productivité professionnel qui donne des conseils concis';

  @override
  String get personaExample4 =>
      'Vous êtes un ami de soutien qui rappelle avec chaleur et soin';

  @override
  String get aiDebugInfoTitle => 'Informations de Débogage IA';

  @override
  String get aiDebugInfoSubtitle =>
      'Vérifier l\'état de fonctionnalité de l\'IA';

  @override
  String get aiSettingsStatus => 'État des Paramètres IA';

  @override
  String get aiFeatureToggles => 'Interrupteurs de Fonctionnalités IA';

  @override
  String get aiTodoProviderConnection => 'Connexion du Fournisseur de Tâches';

  @override
  String get aiMessages => 'Messages IA';

  @override
  String get aiApiRequestManager => 'Gestionnaire de Requêtes API';

  @override
  String get aiCurrentRequestQueue => 'File d\'Attente de Requêtes Actuelle';

  @override
  String get aiRecentRequests => 'Requêtes Récentes';

  @override
  String get aiPermissionRequestMessage =>
      'Veuillez activer l\'autorisation \"Alarmes et Rappels\" pour \"Easy Todo\" dans les paramètres système.';

  @override
  String get developerNameMeowLynxSea => '梦凌汐 (MeowLynxSea)';

  @override
  String get developerEmail => 'mew@meowdream.cn';

  @override
  String get developerGithub => 'github.com/MeowLynxSea';

  @override
  String get developerWebsite => 'www.meowdream.cn';

  @override
  String get backupFileShareSubject => 'Fichier de Sauvegarde Easy Todo';

  @override
  String shareFailed(Object error) {
    return 'Échec du partage : $error';
  }

  @override
  String get authenticateToAccessAppMessage =>
      'Veuillez utiliser l\'empreinte digitale pour accéder à l\'application';

  @override
  String get aiFeaturesEnabled => 'Fonctionnalités IA Activées';

  @override
  String get aiServiceValid => 'Service IA Valide';

  @override
  String get notConfigured => 'Non configuré';

  @override
  String configured(Object count) {
    return 'Configuré ($count caractères)';
  }

  @override
  String get aiProviderConnected => 'Fournisseur IA Connecté';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get aiProcessedTodos => 'Tâches Traitées par IA';

  @override
  String get todosWithAICategory => 'Tâches avec Catégorie IA';

  @override
  String get todosWithAIPriority => 'Tâches avec Priorité IA';

  @override
  String get lastError => 'Dernière Erreur';

  @override
  String get pendingRequests => 'Requêtes en Attente';

  @override
  String get currentWindowRequests => 'Requêtes de Fenêtre Actuelle';

  @override
  String get maxRequestsPerMinute => 'Max. Requêtes/Minute';

  @override
  String get status => 'Statut';

  @override
  String get aiServiceNotAvailable => 'Service IA non disponible';

  @override
  String get completionMessages => 'Messages de Complétion';

  @override
  String get exactAlarmPermission => 'Autorisation d\'Alarme Exacte';

  @override
  String get exactAlarmPermissionContent =>
      'Pour assurer que les fonctions pomodoro et rappels fonctionnent avec précision, l\'application a besoin de l\'autorisation d\'alarme exacte.\n\nVeuillez activer l\'autorisation \"Alarmes et Rappels\" pour \"Easy Todo\" dans les paramètres système.';

  @override
  String get setLater => 'Définir Plus Tard';

  @override
  String get goToSettings => 'Aller aux Paramètres';

  @override
  String get batteryOptimizationSettings =>
      'Paramètres d\'Optimisation de Batterie';

  @override
  String get batteryOptimizationContent =>
      'Pour assurer que les fonctions pomodoro et rappels fonctionnent correctement en arrière-plan, veuillez désactiver l\'optimisation de batterie pour cette application.\n\nCela peut augmenter la consommation de batterie, mais assure que les fonctions de minuteur et rappels fonctionnent avec précision.';

  @override
  String get breakTimeComplete => 'Pause terminée !';

  @override
  String get timeToGetBackToWork => 'Retour au travail !';

  @override
  String get aiServiceReturnedEmptyMessage =>
      'Le service IA a retourné un message vide';

  @override
  String errorGeneratingMotivationalMessage(Object error) {
    return 'Erreur lors de la génération du message motivationnel : $error';
  }

  @override
  String get aiServiceNotAvailableCheckSettings =>
      'Service IA non disponible, veuillez vérifier les paramètres IA';

  @override
  String get filterByCategory => 'Filtrer par Catégorie';

  @override
  String get importance => 'Importance';

  @override
  String get noCategoriesAvailable => 'Aucune catégorie disponible';

  @override
  String get aiWillCategorizeTasks =>
      'L\'IA catégorisera automatiquement les tâches, veuillez réessayer plus tard';

  @override
  String get selectCategories => 'Sélectionner des Catégories';

  @override
  String get selectedCategories => 'Sélectionné';

  @override
  String get categories => 'catégories';

  @override
  String get apiFormat => 'Format API';

  @override
  String get apiFormatDescription =>
      'Choisissez votre fournisseur de services IA. Les différents fournisseurs peuvent nécessiter des points de terminaison API et des méthodes d\'authentification différents.';

  @override
  String get openaiFormat => 'OpenAI';

  @override
  String get anthropicFormat => 'Anthropic';

  @override
  String aiPromptCategorization(Object description, Object title) {
    return 'Classez cette tâche à faire dans l\'une de ces catégories:\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n\n      Tâche: \"$title\"\n      Description: \"$description\"\n\n      Répondez uniquement avec le nom de la catégorie en minuscules.';
  }

  @override
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  ) {
    return 'Évaluez la priorité de cette tâche de 0-100, en considérant:\n      - Urgence: Quand est-ce nécessaire ? (date limite: $deadline)\n      - Impact: Quelles sont les conséquences de ne pas la terminer ?\n      - Effort: Combien de temps/ressources sont nécessaires ?\n      - Importance personnelle: Quelle est sa valeur pour vous ?\n\n      Tâche: \"$title\"\n      Description: \"$description\"\n      A une date limite: $hasDeadline\n      Date limite: $deadline\n\n      Directives:\n      - 0-20: Priorité faible, peut être reportée\n      - 21-40: Priorité modérée, devrait être faite bientôt\n      - 41-70: Priorité élevée, importante à compléter\n      - 71-100: Priorité critique, complétion urgente nécessaire\n\n      Répondez uniquement avec un nombre de 0-100.';
  }

  @override
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  ) {
    return 'Générez un message motivant basé sur ces données statistiques:\n      Nom: \"$name\"\n      Description: \"$description\"\n      Valeur: $value\n      Unité: \"$unit\"\n      Date: $date\n\n      Exigences:\n      - Rendez-le encourageant et spécifique aux données\n      - Gardez-le sous 25 caractères\n      - Concentrez-vous sur les réalisations et le progrès\n      - Utilisez un langage positif et orienté action\n      - Exemple: \"Excellent progrès aujourd\'hui ! 🎯\" ou \"Continuez ! 💪\"\n      - Répondez uniquement avec le message, sans explications';
  }

  @override
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  ) {
    return 'Créez un rappel de notification personnalisé pour cette tâche:\n      Tâche: \"$title\"\n      Description: \"$description\"\n      Catégorie: $category\n      Priorité: $priority\n\n      Exigences:\n      - Créez à la fois un titre et un message\n      - Titre: Moins de 20 caractères, accrocheur\n      - Message: Moins de 50 caractères, motivant et actionnable\n      - Utilisez des emojis quand approprié pour l\'engagement\n      - Incluez l\'urgence basée sur le niveau de priorité\n      - Rendez-le personnel et encourageant\n      - Répondez uniquement avec le titre et message dans le format spécifié, sans explications\n\n      Formattez votre réponse comme:\n      TITLE: [titre]\n      MESSAGE: [message]';
  }

  @override
  String aiPromptCompletion(Object completed, Object percentage, Object total) {
    return 'Générez un message encourageant basé sur le completion des tâches d\'aujourd\'hui:\n      Complétées: $completed sur $total tâches\n      Taux de completion: $percentage%\n\n      Exigences:\n      - Rendez-le positif et motivant\n      - Gardez-le sous 25 caractères\n      - Célébrez les réalisations et le progrès\n      - Utilisez un langage encourageant et/ou des emojis\n      - Exemple: \"Excellent travail ! 🌟\" ou \"Progrès ! 👍\"\n      - Répondez uniquement avec le message, sans explications';
  }

  @override
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  ) {
    return 'Créez une notification de résumé quotidien pour les tâches en attente.\n\nNombre de tâches en attente: $pendingCount\nCatégories: $categories\nPriorité moyenne: $avgPriority/100\n\nCréez un résumé personnalisé avec :\n1. Un titre accrocheur (première ligne)\n2. Un message encourageant qui DOIT inclure le nombre de tâches non terminées ($pendingCount)\n3. Gardez le contenu du message sous 50 caractères. Rendez-le motivant et actionnable.\n4. Répondez uniquement avec le titre et message, sans explications';
  }

  @override
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  ) {
    return 'Créez une notification personnalisée pour une session de $sessionType terminée.\n\nDétails de la session :\n- Tâche : \"$taskTitle\"\n- Type de session : $sessionType\n- Durée : $duration minutes\n- Terminée : $isCompleted\n\nIMPORTANT : Répondez dans la même langue que ce message (français).\n\nCréez un titre et un message :\n1. Titre : Moins de 20 caractères, accrocheur et célébratoire\n2. Message : Moins de 50 caractères, encourageant et pertinent pour la session terminée\n3. Pour les sessions de concentration (travail terminé) : Mettez l\'accent sur les réalisations du travail et qu\'il est temps d\'une pause bien méritée\n4. Pour les sessions de pause (pause terminée) : Concentrez-vous sur la fin de la pause et qu\'il est temps de retourner au travail concentré\n5. Utilisez des emojis si approprié pour l\'engagement\n6. Rendez-le personnel et motivant\n7. Répondez uniquement avec le titre et le message dans le format spécifié, sans explications\n\nFormatez votre réponse comme :\nTITLE: [titre]\nMESSAGE: [message]';
  }
}

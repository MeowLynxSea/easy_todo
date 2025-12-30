// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get preferences => 'Einstellungen';

  @override
  String get appSettings => 'App-Einstellungen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsSubtitle =>
      'Benachrichtigungseinstellungen verwalten';

  @override
  String get theme => 'Design';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get systemTheme => 'System';

  @override
  String get language => 'Sprache';

  @override
  String get languageSettings =>
      'Spracheinstellungen ermöglichen es Ihnen, die Anzeigesprache der App zu ändern. Wählen Sie Ihre bevorzugte Sprache aus der obigen Liste.';

  @override
  String get dataStorage => 'Daten & Speicher';

  @override
  String get dataAndSync => 'Daten & Sync';

  @override
  String get cloudSync => 'Cloud-Synchronisierung';

  @override
  String get cloudSyncSubtitle => 'Ende-zu-Ende-verschlüsselt';

  @override
  String get cloudSyncOverviewTitle => 'E2EE-Synchronisierung';

  @override
  String get cloudSyncOverviewSubtitle =>
      'Der Server speichert nur Ciphertext; entsperren Sie mit Ihrer Passphrase auf diesem Gerät.';

  @override
  String get cloudSyncConfigSaved => 'Sync-Konfiguration gespeichert';

  @override
  String get cloudSyncServerOkSnack => 'Server erreichbar';

  @override
  String get cloudSyncServerCheckFailedSnack => 'Serverprüfung fehlgeschlagen';

  @override
  String get cloudSyncDisabledSnack => 'Sync deaktiviert';

  @override
  String get cloudSyncEnableSwitchTitle => 'Cloud-Sync aktivieren';

  @override
  String get cloudSyncEnableSwitchSubtitle =>
      'Geführte Einrichtung: Server + Passphrase';

  @override
  String get cloudSyncServerSection => 'Server';

  @override
  String get cloudSyncSetupTitle => '1) Server einrichten';

  @override
  String get cloudSyncSetupSubtitle =>
      'Server-URL festlegen, dann Provider wählen und anmelden.';

  @override
  String get cloudSyncSetupDialogTitle => 'Server-Konfiguration';

  @override
  String get cloudSyncServerUrl => 'Server-URL';

  @override
  String get cloudSyncServerUrlHint => 'http://127.0.0.1:8787';

  @override
  String get cloudSyncAuthProvider => 'OAuth-Provider';

  @override
  String get cloudSyncAuthProviderHint => 'linuxdo';

  @override
  String get cloudSyncAuthMode => 'Anmeldung';

  @override
  String get cloudSyncAuthModeLoggedIn => 'Angemeldet';

  @override
  String get cloudSyncAuthModeLoggedOut => 'Nicht angemeldet';

  @override
  String get cloudSyncCheckServer => 'Server prüfen';

  @override
  String get cloudSyncEditServerConfig => 'Bearbeiten';

  @override
  String get cloudSyncLogin => 'Anmelden';

  @override
  String get cloudSyncLogout => 'Abmelden';

  @override
  String get cloudSyncLoggedInSnack => 'Angemeldet';

  @override
  String get cloudSyncLoggedOutSnack => 'Abgemeldet';

  @override
  String get cloudSyncLoginRedirectedSnack =>
      'Bitte im Browser weiter anmelden';

  @override
  String get cloudSyncLoginFailedSnack => 'Anmeldung fehlgeschlagen';

  @override
  String get cloudSyncNotSet => 'Nicht festgelegt';

  @override
  String get cloudSyncTokenSet => 'Token ist gesetzt';

  @override
  String get cloudSyncStatusSection => 'Status';

  @override
  String get cloudSyncEnabled => 'Aktiviert';

  @override
  String get cloudSyncUnlocked => 'Entsperrt';

  @override
  String get cloudSyncEnabledOn => 'Aktiviert: An';

  @override
  String get cloudSyncEnabledOff => 'Aktiviert: Aus';

  @override
  String get cloudSyncUnlockedYes => 'Entsperrt: Ja';

  @override
  String get cloudSyncUnlockedNo => 'Entsperrt: Nein';

  @override
  String get cloudSyncConfiguredYes => 'Konfiguriert: Ja';

  @override
  String get cloudSyncConfiguredNo => 'Konfiguriert: Nein';

  @override
  String get cloudSyncLastServerSeq => 'Letzter serverSeq';

  @override
  String get cloudSyncDekId => 'DEK-ID';

  @override
  String get cloudSyncLastSyncAt => 'Letzte Synchronisierung';

  @override
  String get cloudSyncError => 'Fehler';

  @override
  String get cloudSyncDeviceId => 'Geräte-ID';

  @override
  String get cloudSyncEnable => 'Aktivieren';

  @override
  String get cloudSyncUnlock => 'Entsperren';

  @override
  String get cloudSyncSyncNow => 'Jetzt synchronisieren';

  @override
  String get cloudSyncDisable => 'Deaktivieren';

  @override
  String get cloudSyncSecurityTitle => '2) Entsperren';

  @override
  String get cloudSyncSecuritySubtitle =>
      'Zum Entsperren wird Ihre Passphrase verwendet, um den DEK zu erhalten. Mobile/Desktop können ihn sicher speichern.';

  @override
  String get cloudSyncLockStateTitle => 'Verschlüsselungsschlüssel';

  @override
  String get cloudSyncLockStateUnlocked => 'Auf diesem Gerät entsperrt';

  @override
  String get cloudSyncLockStateLocked => 'Gesperrt — Passphrase eingeben';

  @override
  String get cloudSyncActionsTitle => '3) Synchronisieren';

  @override
  String get cloudSyncActionsSubtitle =>
      'Lokale Änderungen senden, dann Updates abrufen.';

  @override
  String get cloudSyncAdvancedTitle => 'Erweitert';

  @override
  String get cloudSyncAdvancedSubtitle => 'Debug-Infos (nur Gerät)';

  @override
  String get cloudSyncEnableDialogTitle => 'Sync aktivieren';

  @override
  String get cloudSyncUnlockDialogTitle => 'Sync entsperren';

  @override
  String get cloudSyncPassphraseDialogHint =>
      'Wenn Sie die Synchronisierung bereits auf einem anderen Gerät aktiviert haben, geben Sie dieselbe Passphrase zweimal ein.';

  @override
  String get cloudSyncPassphrase => 'Passphrase';

  @override
  String get cloudSyncConfirmPassphrase => 'Passphrase bestätigen';

  @override
  String get cloudSyncShowPassphrase => 'Anzeigen';

  @override
  String get cloudSyncEnabledSnack => 'Sync aktiviert';

  @override
  String get cloudSyncUnlockedSnack => 'Entsperrt';

  @override
  String get cloudSyncSyncedSnack => 'Synchronisiert';

  @override
  String get cloudSyncInvalidPassphrase => 'Ungültige Passphrase';

  @override
  String get cloudSyncRollbackTitle => 'Möglicher Server-Rollback';

  @override
  String get cloudSyncRollbackMessage =>
      'Der Server wurde möglicherweise zurückgesetzt oder aus einem Backup wiederhergestellt. Fortfahren kann zu Datenverlust führen. Was möchten Sie tun?';

  @override
  String get cloudSyncStopSync => 'Sync stoppen';

  @override
  String get cloudSyncContinue => 'Fortfahren';

  @override
  String get cloudSyncWebDekNote =>
      'Web speichert den DEK nur für die Sitzung. Nach dem Neuladen ist erneut entsperren erforderlich.';

  @override
  String get cloudSyncStatusIdle => 'bereit';

  @override
  String get cloudSyncStatusRunning => 'läuft';

  @override
  String get cloudSyncStatusError => 'Fehler';

  @override
  String get cloudSyncErrorPassphraseMismatch =>
      'Passphrasen stimmen nicht überein';

  @override
  String get cloudSyncErrorNotConfigured => 'Sync nicht konfiguriert';

  @override
  String get cloudSyncErrorDisabled => 'Sync ist deaktiviert';

  @override
  String get cloudSyncErrorLocked => 'Sync ist gesperrt (DEK fehlt)';

  @override
  String get cloudSyncErrorAccountChanged =>
      'Konto gewechselt – bitte Sync erneut aktivieren';

  @override
  String get cloudSyncErrorUnauthorized => 'Nicht autorisiert (Token prüfen)';

  @override
  String get cloudSyncErrorKeyBundleNotFound =>
      'Key-Bundle auf dem Server nicht gefunden';

  @override
  String get cloudSyncErrorNetwork => 'Netzwerkfehler';

  @override
  String get cloudSyncErrorConflict =>
      'Konflikt (Bundle-Version stimmt nicht überein)';

  @override
  String get cloudSyncErrorQuotaExceeded =>
      'Serverkontingent überschritten (einige Datensätze wurden abgelehnt)';

  @override
  String get cloudSyncErrorUnknown => 'Unbekannter Fehler';

  @override
  String get backupRestore => 'Sichern & Wiederherstellen';

  @override
  String get backupSubtitle => 'Ihre Daten sichern';

  @override
  String get storage => 'Speicher';

  @override
  String get storageSubtitle => 'Speicherplatz verwalten';

  @override
  String get about => 'Über';

  @override
  String get aboutEasyTodo => 'Über Easy Todo';

  @override
  String get helpSupport => 'Hilfe & Support';

  @override
  String get helpSubtitle => 'Hilfe zur App erhalten';

  @override
  String get processingCategory => 'Kategorie wird verarbeitet...';

  @override
  String get processingPriority => 'Priorität wird verarbeitet...';

  @override
  String get processingAI => 'KI wird verarbeitet...';

  @override
  String get aiProcessingCompleted => 'KI-Verarbeitung abgeschlossen';

  @override
  String get categorizingTask => 'Aufgabe wird kategorisiert...';

  @override
  String get processingAIStatus => 'KI wird verarbeitet...';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get clearDataSubtitle => 'Alle Aufgaben und Einstellungen löschen';

  @override
  String get version => 'Version';

  @override
  String get appDescription =>
      'Eine saubere, elegante Aufgabenlisten-Anwendung, die für Einfachheit und Produktivität konzipiert wurde.';

  @override
  String get developer => 'Entwickler';

  @override
  String get developerInfo => 'Entwicklerinformationen';

  @override
  String get needHelp => 'Hilfe benötigt?';

  @override
  String get helpDescription =>
      'Wenn Sie auf Probleme stoßen oder Vorschläge haben, können Sie uns gerne über eine der oben genannten Kontaktmöglichkeiten erreichen.';

  @override
  String get close => 'Schließen';

  @override
  String get themeSettings => 'Design-Einstellungen';

  @override
  String get themeMode => 'Design-Modus';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get system => 'System';

  @override
  String get themeColors => 'Design-Farben';

  @override
  String get customTheme => 'Benutzerdefiniertes Design';

  @override
  String get primaryColor => 'Primärfarbe';

  @override
  String get secondaryColor => 'Sekundärfarbe';

  @override
  String get selectPrimaryColor => 'Primärfarbe für die App auswählen';

  @override
  String get selectSecondaryColor => 'Sekundärfarbe für die App auswählen';

  @override
  String get selectColor => 'Farbe auswählen';

  @override
  String get hue => 'Farbton';

  @override
  String get saturation => 'Sättigung';

  @override
  String get lightness => 'Helligkeit';

  @override
  String get applyCustomTheme => 'Benutzerdefiniertes Design anwenden';

  @override
  String get customThemeApplied =>
      'Benutzerdefiniertes Design erfolgreich angewendet';

  @override
  String get themeColorApplied => 'Design-Farbe angewendet';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get repeatTask => 'Wiederkehrende Aufgabe';

  @override
  String get repeatType => 'Wiederholungstyp';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get weekdays => 'Wochentage';

  @override
  String get selectDays => 'Tage auswählen';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get everyDay => 'Jeden Tag';

  @override
  String get everyWeek => 'Jede Woche';

  @override
  String get everyMonth => 'Jeden Monat';

  @override
  String get monday => 'Montag';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get friday => 'Freitag';

  @override
  String get saturday => 'Samstag';

  @override
  String get sunday => 'Sonntag';

  @override
  String get startDate => 'Startdatum';

  @override
  String get endDate => 'Enddatum';

  @override
  String get noEndDate => 'Kein Enddatum';

  @override
  String get timeRange => 'Zeitbereich';

  @override
  String get startTime => 'Startzeit';

  @override
  String get endTime => 'Endzeit';

  @override
  String get noStartTimeSet => 'Keine Startzeit festgelegt';

  @override
  String get noEndTimeSet => 'Keine Endzeit festgelegt';

  @override
  String get invalidTimeRange => 'Endzeit muss nach der Startzeit liegen';

  @override
  String get repeatEnabled => 'Wiederholung aktiviert';

  @override
  String get repeatDescription =>
      'Automatisch wiederkehrende Aufgaben erstellen';

  @override
  String get backfillMode => 'Nachholmodus';

  @override
  String get backfillModeDescription =>
      'Erstellt verpasste wiederkehrende Aufgaben für vergangene Tage';

  @override
  String get backfillDays => 'Zurückliegende Tage';

  @override
  String get backfillDaysDescription =>
      'Maximale Anzahl zurückliegender Tage (1–365, ohne heute)';

  @override
  String get backfillAutoComplete =>
      'Nachgeholte Aufgaben automatisch abschließen';

  @override
  String get backfillDaysRangeError =>
      'Die Anzahl der Tage muss zwischen 1 und 365 liegen';

  @override
  String get backfillConflictTitle => 'Konflikt beim Nachholen';

  @override
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  ) {
    return 'Die Aufgabe „$title“ beginnt am $startDate, aber der Nachholmodus würde bis $backfillStartDate zurückgehen. Welches Datum soll für diese Aktualisierung als frühestes Erstellungsdatum verwendet werden?';
  }

  @override
  String get useStartDate => 'Startdatum verwenden';

  @override
  String get useBackfillDays => 'Nachholbereich verwenden';

  @override
  String get activeRepeatTasks => 'Aktive wiederkehrende Aufgaben';

  @override
  String get noRepeatTasks => 'Noch keine wiederkehrenden Aufgaben';

  @override
  String get pauseRepeat => 'Pausieren';

  @override
  String get resumeRepeat => 'Fortsetzen';

  @override
  String get editRepeat => 'Bearbeiten';

  @override
  String get deleteRepeat => 'Löschen';

  @override
  String get repeatTaskConfirm => 'Wiederkehrende Aufgabe löschen';

  @override
  String get repeatTaskDeleteMessage =>
      'Dies löscht alle wiederkehrenden Aufgaben, die aus dieser Vorlage generiert wurden. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get manageRepeatTasks => 'Wiederkehrende Aufgaben verwalten';

  @override
  String get comingSoon => 'Demnächst!';

  @override
  String get todos => 'Aufgaben';

  @override
  String get schedule => 'Zeitplan';

  @override
  String get clearDataWarning =>
      'Dies löscht dauerhaft alle Ihre Aufgaben und Statistiken. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get dataClearedSuccess => 'Alle Daten wurden erfolgreich gelöscht';

  @override
  String get clearDataFailed => 'Löschen der Daten fehlgeschlagen';

  @override
  String get history => 'Verlauf';

  @override
  String get stats => 'Statistiken';

  @override
  String get searchTodos => 'Aufgaben suchen';

  @override
  String get addTodo => 'Aufgabe hinzufügen';

  @override
  String get addTodoHint => 'Was muss erledigt werden?';

  @override
  String get todoTitle => 'Titel';

  @override
  String get todoDescription => 'Beschreibung';

  @override
  String get save => 'Speichern';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get complete => 'Abschließen';

  @override
  String get incomplete => 'Unvollständig';

  @override
  String get allTodos => 'Alle';

  @override
  String get activeTodos => 'Aktiv';

  @override
  String get completedTodos => 'Abgeschlossen';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Diesen Monat';

  @override
  String get older => 'Älter';

  @override
  String get totalTodos => 'Gesamte Aufgaben';

  @override
  String get completedTodosCount => 'Abgeschlossen';

  @override
  String get activeTodosCount => 'Aktiv';

  @override
  String get completionRate => 'Abschlussrate';

  @override
  String get backup => 'Sichern';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get importData => 'Daten importieren';

  @override
  String get backupSuccess => 'Sicherung erfolgreich erstellt';

  @override
  String get backupFailed => 'Erstellung der Sicherung fehlgeschlagen';

  @override
  String get restoreSuccess => 'Daten erfolgreich wiederhergestellt';

  @override
  String restoreFailed(Object error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get webBackupHint => 'Web: Backups erfolgen per Download/Upload.';

  @override
  String restoreWarning(Object fileName) {
    return 'Dies ersetzt alle aktuellen Daten durch Daten aus \"$fileName\". Diese Aktion kann nicht rückgängig gemacht werden. Fortfahren?';
  }

  @override
  String get totalStorage => 'Gesamtspeicher';

  @override
  String get todosStorage => 'Aufgaben';

  @override
  String get cacheStorage => 'Cache';

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get cacheCleared => 'Cache erfolgreich geleert';

  @override
  String get filterByStatus => 'Nach Status filtern';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get newestFirst => 'Neueste zuerst';

  @override
  String get oldestFirst => 'Älteste zuerst';

  @override
  String get alphabetical => 'Alphabetisch';

  @override
  String get overview => 'Übersicht';

  @override
  String get weeklyProgress => 'Wöchentlicher Fortschritt';

  @override
  String get monthlyTrends => 'Monatliche Trends';

  @override
  String get productivityOverview => 'Produktivitätsübersicht';

  @override
  String get overallCompletionRate => 'Gesamtabschlussrate';

  @override
  String get created => 'Erstellt';

  @override
  String get recentActivity => 'Letzte Aktivität';

  @override
  String get noRecentActivity => 'Keine recente Aktivität';

  @override
  String get todoDistribution => 'Aufgabenverteilung';

  @override
  String get bestPerformance => 'Beste Leistung';

  @override
  String get noCompletedTodosYet => 'Noch keine abgeschlossenen Aufgaben';

  @override
  String get completionRateDescription => 'aller Aufgaben abgeschlossen';

  @override
  String get fingerprintLock => 'Fingerabdruck-Sperre';

  @override
  String get fingerprintLockSubtitle =>
      'App-Sicherheit mit Fingerabdruck schützen';

  @override
  String get fingerprintLockEnable => 'Fingerabdruck-Sperre aktivieren';

  @override
  String get fingerprintLockDisable => 'Fingerabdruck-Sperre deaktivieren';

  @override
  String get fingerprintLockEnabled => 'Fingerabdruck-Sperre aktiviert';

  @override
  String get fingerprintLockDisabled => 'Fingerabdruck-Sperre deaktiviert';

  @override
  String get fingerprintNotAvailable =>
      'Fingerabdruck-Authentifizierung nicht verfügbar';

  @override
  String get fingerprintNotEnrolled => 'Kein Fingerabdruck registriert';

  @override
  String get fingerprintAuthenticationFailed =>
      'Fingerabdruck-Authentifizierung fehlgeschlagen';

  @override
  String get fingerprintAuthenticationSuccess =>
      'Fingerabdruck-Authentifizierung erfolgreich';

  @override
  String get active => 'Aktiv';

  @override
  String get mon => 'Mo';

  @override
  String get tue => 'Di';

  @override
  String get wed => 'Mi';

  @override
  String get thu => 'Do';

  @override
  String get fri => 'Fr';

  @override
  String get sat => 'Sa';

  @override
  String get sun => 'So';

  @override
  String get week1 => 'Woche 1';

  @override
  String get week2 => 'Woche 2';

  @override
  String get week3 => 'Woche 3';

  @override
  String get week4 => 'Woche 4';

  @override
  String withCompletedTodos(Object count) {
    return 'mit $count abgeschlossenen Aufgaben';
  }

  @override
  String get unableToLoadBackupStats =>
      'Sicherungsstatistiken können nicht geladen werden';

  @override
  String get backupSummary => 'Sicherungszusammenfassung';

  @override
  String get itemsToBackup => 'Zu sichernde Elemente';

  @override
  String get dataSize => 'Datengröße';

  @override
  String get backupFiles => 'Sicherungsdateien';

  @override
  String get backupSize => 'Sicherungsgröße';

  @override
  String get quickActions => 'Schnellaktionen';

  @override
  String get backupRestoreDescription =>
      'Erstellen Sie eine Sicherung Ihrer Daten oder stellen Sie aus einer vorherigen Sicherung wieder her.';

  @override
  String get createBackup => 'Sicherung erstellen';

  @override
  String get restoreBackup => 'Sicherung wiederherstellen';

  @override
  String get noBackupFilesFound => 'Keine Sicherungsdateien gefunden';

  @override
  String get createFirstBackup =>
      'Erstellen Sie Ihre erste Sicherung, um zu beginnen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get restoreFromFile => 'Aus dieser Datei wiederherstellen';

  @override
  String get deleteFile => 'Datei löschen';

  @override
  String get aboutBackups => 'Über Sicherungen';

  @override
  String get backupInfo1 =>
      '• Sicherungen enthalten alle Ihre Aufgaben und Statistiken';

  @override
  String get backupInfo2 =>
      '• Bewahren Sie Sicherungsdateien an einem sicheren Ort auf';

  @override
  String get backupInfo3 =>
      '• Regelmäßige Sicherungen helfen, Datenverlust zu vermeiden';

  @override
  String get backupInfo4 =>
      '• Sie können aus jeder Sicherungsdatei wiederherstellen';

  @override
  String get backupCreatedSuccess => 'Sicherung erfolgreich erstellt';

  @override
  String get noBackupFilesAvailable =>
      'Keine Sicherungsdateien für die Wiederherstellung verfügbar';

  @override
  String get selectBackupFile => 'Sicherungsdatei auswählen';

  @override
  String get confirmRestore => 'Wiederherstellung bestätigen';

  @override
  String dataRestoredSuccess(Object fileName) {
    return 'Daten erfolgreich aus \"$fileName\" wiederhergestellt';
  }

  @override
  String get deleteBackupFile => 'Sicherungsdatei löschen';

  @override
  String deleteBackupWarning(Object fileName) {
    return 'Sind Sie sicher, dass Sie \"$fileName\" löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String backupFileDeletedSuccess(Object fileName) {
    return 'Sicherungsdatei \"$fileName\" erfolgreich gelöscht';
  }

  @override
  String get backupFileNotFound => 'Sicherungsdatei nicht gefunden';

  @override
  String invalidFilePath(Object fileName) {
    return 'Ungültiger Dateipfad für \"$fileName\"';
  }

  @override
  String get failedToDeleteFile => 'Löschen der Datei fehlgeschlagen';

  @override
  String get files => 'Dateien';

  @override
  String get storageManagement => 'Speicherverwaltung';

  @override
  String get storageOverview => 'Speicherübersicht';

  @override
  String get storageAnalytics => 'Speicher-Analyse';

  @override
  String get noPendingRequests => 'Keine ausstehenden Anfragen';

  @override
  String get request => 'Anfrage';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get waiting => 'Warten';

  @override
  String get noRecentRequests => 'Keine recenten Anfragen';

  @override
  String get requestCompleted => 'Anfrage abgeschlossen';

  @override
  String get noTodosToDisplay => 'Keine Aufgaben zum Anzeigen';

  @override
  String get todoStatusDistribution => 'Aufgabenstatus-Verteilung';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get pending => 'Ausstehend';

  @override
  String get dataStorageUsage => 'Datenspeichernutzung';

  @override
  String get total => 'Gesamt';

  @override
  String get storageCleanup => 'Speicherbereinigung';

  @override
  String get cleanupDescription =>
      'Speicherplatz freigeben durch Entfernen unnötiger Daten:';

  @override
  String get clearCompletedTodos => 'Abgeschlossene Aufgaben löschen';

  @override
  String get clearOldStatistics => 'Alte Statistiken löschen';

  @override
  String get clearBackupFiles => 'Sicherungsdateien löschen';

  @override
  String get cleanupCompleted => 'Bereinigung abgeschlossen';

  @override
  String todosDeleted(Object count) {
    return '$count Aufgaben gelöscht';
  }

  @override
  String statisticsDeleted(Object count) {
    return '$count Statistiken gelöscht';
  }

  @override
  String backupFilesDeleted(Object count) {
    return '$count Sicherungsdateien gelöscht';
  }

  @override
  String get cleanupFailed => 'Bereinigung fehlgeschlagen';

  @override
  String get easyTodo => 'Easy Todo';

  @override
  String copiedToClipboard(Object url) {
    return 'In Zwischenablage kopiert: $url';
  }

  @override
  String cannotOpenLink(Object url) {
    return 'Link kann nicht geöffnet werden, in Zwischenablage kopiert: $url';
  }

  @override
  String get email => 'E-Mail';

  @override
  String get github => 'GitHub';

  @override
  String get website => 'Website';

  @override
  String get noTodosMatchSearch => 'Keine Aufgaben entsprechen Ihrer Suche';

  @override
  String get noCompletedTodos => 'Keine abgeschlossenen Aufgaben';

  @override
  String get noActiveTodos => 'Keine aktiven Aufgaben';

  @override
  String get noTodosYet => 'Noch keine Aufgaben';

  @override
  String get deleteTodoConfirmation =>
      'Sind Sie sicher, dass Sie diese Aufgabe löschen möchten?';

  @override
  String get createdLabel => 'Erstellt: ';

  @override
  String get completedLabel => 'Abgeschlossen: ';

  @override
  String get filterByTime => 'Nach Zeit filtern';

  @override
  String get sortByTime => 'Nach Zeit sortieren';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get descending => 'Absteigend';

  @override
  String get threeDays => 'Drei Tage';

  @override
  String minutesAgoWithCount(Object count) {
    return 'vor $count Minuten';
  }

  @override
  String hoursAgoWithCount(Object count) {
    return 'vor $count Stunden';
  }

  @override
  String daysAgoWithCount(Object count) {
    return 'vor $count Tagen';
  }

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get dailySummary => 'Tägliche Zusammenfassung';

  @override
  String get dailySummaryTime => 'Zeit der täglichen Zusammenfassung';

  @override
  String get dailySummaryDescription =>
      'Tägliche Zusammenfassung ausstehender Aufgaben erhalten';

  @override
  String get defaultReminderSettings => 'Standard-Erinnerungseinstellungen';

  @override
  String get enableDefaultReminders => 'Standard-Erinnerungen aktivieren';

  @override
  String get reminderTimeBefore => 'Erinnerungszeit vor Fälligkeit';

  @override
  String minutesBefore(Object count) {
    return '$count Minuten vorher';
  }

  @override
  String get notificationPermissions => 'Benachrichtigungsberechtigungen';

  @override
  String get grantPermissions => 'Berechtigungen erteilen';

  @override
  String get permissionsGranted => 'Berechtigungen erteilt';

  @override
  String get permissionsDenied => 'Berechtigungen verweigert';

  @override
  String get testNotification => 'Testbenachrichtigung';

  @override
  String get sendTestNotification => 'Testbenachrichtigung senden';

  @override
  String get notificationTestSent =>
      'Testbenachrichtigung erfolgreich gesendet';

  @override
  String get reminderTime => 'Erinnerungszeit';

  @override
  String get setReminder => 'Erinnerung festlegen';

  @override
  String reminderSet(Object time) {
    return 'Erinnerung festgelegt für $time';
  }

  @override
  String get cancelReminder => 'Erinnerung abbrechen';

  @override
  String get noReminderSet => 'Keine Erinnerung festgelegt';

  @override
  String get enableReminder => 'Erinnerung aktivieren';

  @override
  String get reminderOptions => 'Erinnerungsoptionen';

  @override
  String get pomodoroTimer => 'Pomodoro-Timer';

  @override
  String get pomodoroSettings => 'Pomodoro-Einstellungen';

  @override
  String get workDuration => 'Arbeitsdauer';

  @override
  String get breakDuration => 'Pausendauer';

  @override
  String get longBreakDuration => 'Lange Pausendauer';

  @override
  String get sessionsUntilLongBreak => 'Sitzungen bis zur langen Pause';

  @override
  String get minutes => 'Minuten';

  @override
  String get sessions => 'Sitzungen';

  @override
  String get settingsSaved => 'Einstellungen erfolgreich gespeichert';

  @override
  String get focusTime => 'Fokuszeit';

  @override
  String get clearOldPomodoroSessions => 'Alte Pomodoro-Sitzungen löschen';

  @override
  String pomodoroSessionsDeleted(Object count) {
    return '$count Pomodoro-Sitzungen gelöscht';
  }

  @override
  String get breakTime => 'Pausenzeit';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get stop => 'Stop';

  @override
  String get timeSpent => 'Verbrachte Zeit';

  @override
  String get pomodoroStats => 'Pomodoro-Statistiken';

  @override
  String get sessionsCompleted => 'Abgeschlossene Sitzungen';

  @override
  String get totalTime => 'Gesamtzeit';

  @override
  String get averageTime => 'Durchschnittszeit';

  @override
  String get focusSessions => 'Fokussitzungen';

  @override
  String get pomodoroSessions => 'Pomodoro-Sitzungen';

  @override
  String get totalFocusTime => 'Gesamtfokuszeit';

  @override
  String get weeklyPomodoroStats => 'Wöchentliche Pomodoro-Statistiken';

  @override
  String get totalSessions => 'Gesamtsitzungen';

  @override
  String get averageSessions => 'Durchschnittssitzungen';

  @override
  String get monthlyPomodoroStats => 'Monatliche Pomodoro-Statistiken';

  @override
  String get averagePerWeek => 'Durchschnitt pro Woche';

  @override
  String get pomodoroOverview => 'Pomodoro-Übersicht';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checkUpdatesSubtitle => 'Nach neuen Versionen suchen';

  @override
  String get checkingForUpdates => 'Nach Updates suchen';

  @override
  String get pleaseWait =>
      'Bitte warten Sie, während wir nach Updates suchen...';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get requiredUpdate => 'Erforderliches Update';

  @override
  String versionAvailable(Object version) {
    return 'Version $version ist verfügbar!';
  }

  @override
  String get whatsNew => 'Was ist neu:';

  @override
  String get noUpdatesAvailable => 'Keine Updates verfügbar';

  @override
  String get youHaveLatestVersion => 'Sie haben die neueste Version';

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String get later => 'Später';

  @override
  String get downloadingUpdate => 'Update wird heruntergeladen';

  @override
  String get downloadUpdate => 'Update herunterladen';

  @override
  String get downloadFrom => 'Update wird heruntergeladen von:';

  @override
  String get downloadFailed => 'Herunterladen fehlgeschlagen';

  @override
  String get couldNotOpenDownloadUrl =>
      'Download-URL konnte nicht geöffnet werden';

  @override
  String get updateCheckFailed => 'Überprüfung auf Updates fehlgeschlagen';

  @override
  String get forceUpdateMessage =>
      'Dieses Update ist erforderlich, um die App weiter zu verwenden';

  @override
  String get optionalUpdateMessage =>
      'Sie können jetzt oder später aktualisieren';

  @override
  String get storagePermissionDenied => 'Speicherberechtigung verweigert';

  @override
  String get cannotAccessStorage => 'Kein Zugriff auf Speicher';

  @override
  String get updateDownloadSuccess => 'Update erfolgreich heruntergeladen';

  @override
  String get installUpdate => 'Update installieren';

  @override
  String get startingInstaller => 'Installationsprogramm wird gestartet...';

  @override
  String get updateFileNotFound =>
      'Update-Datei nicht gefunden, bitte erneut herunterladen';

  @override
  String get installPermissionRequired =>
      'Installationsberechtigung erforderlich';

  @override
  String get installPermissionDescription =>
      'Die Installation von App-Updates erfordert die Berechtigung \"Unbekannte Apps installieren\". Bitte aktivieren Sie diese Berechtigung für Easy Todo in den Einstellungen.';

  @override
  String get needInstallPermission =>
      'Installationsberechtigung ist erforderlich, um die App zu aktualisieren';

  @override
  String installFailed(Object error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String installLaunchFailed(Object error) {
    return 'Start der Installation fehlgeschlagen: $error';
  }

  @override
  String get storagePermissionTitle => 'Speicherberechtigung erforderlich';

  @override
  String get storagePermissionDescription =>
      'Um App-Updates herunterzuladen und zu installieren, benötigt Easy Todo Zugriff auf den Gerätespeicher.';

  @override
  String get permissionNote =>
      'Durch Klicken auf \"Zulassen\" erteilen Sie der App die folgenden Berechtigungen:';

  @override
  String get accessDeviceStorage => '• Auf Gerätespeicher zugreifen';

  @override
  String get downloadFilesToDevice => '• Dateien auf Gerät herunterladen';

  @override
  String get allow => 'Zulassen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get permissionDenied => 'Berechtigung verweigert';

  @override
  String get permissionDeniedMessage =>
      'Speicherberechtigung wurde dauerhaft verweigert. Bitte aktivieren Sie die Berechtigung manuell in den Systemeinstellungen und versuchen Sie es erneut.';

  @override
  String get cannotOpenSettings =>
      'Einstellungsseite kann nicht geöffnet werden';

  @override
  String get autoUpdate => 'Automatisches Update';

  @override
  String get autoUpdateSubtitle =>
      'Automatisch nach Updates suchen, wenn die App startet';

  @override
  String get autoUpdateEnabled => 'Automatisches Update aktiviert';

  @override
  String get autoUpdateDisabled => 'Automatisches Update deaktiviert';

  @override
  String get exitApp => 'App beenden';

  @override
  String get viewSettings => 'Ansichtseinstellungen';

  @override
  String get viewDisplay => 'Anzeige';

  @override
  String get viewDisplaySubtitle =>
      'Konfigurieren, wie Inhalte angezeigt werden';

  @override
  String get todoViewSettings => 'Aufgaben-Ansichtseinstellungen';

  @override
  String get historyViewSettings => 'Verlaufs-Ansichtseinstellungen';

  @override
  String get scheduleLayoutSettings => 'Zeitplan-Layout-Einstellungen';

  @override
  String get scheduleLayoutSettingsSubtitle =>
      'Zeitbereich und Wochentage anpassen';

  @override
  String get viewMode => 'Ansichtsmodus';

  @override
  String get listView => 'Listenansicht';

  @override
  String get stackingView => 'Stapelansicht';

  @override
  String get calendarView => 'Kalenderansicht';

  @override
  String get openInNewPage => 'In neuer Seite öffnen';

  @override
  String get openInNewPageSubtitle =>
      'Ansichten in neuen Seiten anstelle von Popups öffnen';

  @override
  String get historyViewMode => 'Verlaufs-Ansichtsmodus';

  @override
  String get scheduleTimeRange => 'Zeitbereich';

  @override
  String get scheduleVisibleWeekdays => 'Angezeigte Wochentage';

  @override
  String get scheduleLabelTextScale => 'Textskalierung der Labels';

  @override
  String get scheduleAtLeastOneDay => 'Bitte mindestens einen Tag auswählen.';

  @override
  String get dayDetails => 'Tagesdetails';

  @override
  String get todoCount => 'Anzahl der Aufgaben';

  @override
  String get completedCount => 'abgeschlossen';

  @override
  String get totalCount => 'gesamt';

  @override
  String get appLongDescription =>
      'Easy Todo ist eine saubere, elegante und leistungsstarke Aufgabenlisten-Anwendung, die Ihnen hilft, Ihre täglichen Aufgaben effizient zu organisieren. Mit schönem UI-Design, umfassender Statistikverfolgung, nahtloser API-Integration und Unterstützung für mehrere Sprachen macht Easy Todo die Aufgabenverwaltung einfach und angenehm.';

  @override
  String get cannotDeleteRepeatTodo =>
      'Wiederkehrende Aufgaben können nicht gelöscht werden';

  @override
  String get appTitle => 'Easy Todo';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterTodayTodos => 'Heutige Aufgaben';

  @override
  String get filterCompleted => 'Abgeschlossen';

  @override
  String get filterThisWeek => 'Diese Woche';

  @override
  String get resetButton => 'Zurücksetzen';

  @override
  String get applyButton => 'Anwenden';

  @override
  String get repeatTaskWarning =>
      'Diese Aufgabe wird automatisch aus einer wiederkehrenden Aufgabe generiert und wird nach dem Löschen morgen neu generiert.';

  @override
  String get learnMore => 'Mehr erfahren';

  @override
  String get repeatTaskDialogTitle => 'Wiederkehrende Aufgabenelement';

  @override
  String get repeatTaskExplanation =>
      'Diese Aufgabe wird automatisch aus einer wiederkehrenden Aufgabenvorlage erstellt. Das Löschen wirkt sich nicht auf die wiederkehrende Aufgabe selbst aus - eine neue Aufgabe wird morgen entsprechend dem Wiederholungszeitplan generiert. Wenn Sie die Generierung dieser Aufgaben stoppen möchten, müssen Sie die wiederkehrende Aufgabenvorlage im Abschnitt zur Verwaltung wiederkehrender Aufgaben bearbeiten oder löschen.';

  @override
  String get iUnderstand => 'Ich verstehe';

  @override
  String get authenticateToContinue =>
      'Bitte authentifizieren Sie sich, um die App weiter zu verwenden';

  @override
  String get retry => 'Wiederholen';

  @override
  String get biometricReason =>
      'Bitte verwenden Sie die biometrische Authentifizierung, um Ihre Identität zu überprüfen';

  @override
  String get biometricHint => 'Biometrische Authentifizierung verwenden';

  @override
  String get biometricNotRecognized =>
      'Biometrie nicht erkannt, bitte versuchen Sie es erneut';

  @override
  String get biometricSuccess => 'Biometrische Authentifizierung erfolgreich';

  @override
  String get biometricVerificationTitle => 'Biometrische Überprüfung';

  @override
  String addTodoError(Object error) {
    return 'Fehler beim Hinzufügen der Aufgabe: $error';
  }

  @override
  String get titleRequired => 'Bitte geben Sie einen Titel ein';

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
    return 'Fehler beim Erstellen der wiederkehrenden Aufgabe: $error';
  }

  @override
  String get repeatTaskTitleRequired => 'Bitte geben Sie einen Titel ein';

  @override
  String get importBackup => 'Sicherung importieren';

  @override
  String get shareBackup => 'Sicherung teilen';

  @override
  String get cannotAccessFile =>
      'Auf ausgewählte Datei kann nicht zugegriffen werden';

  @override
  String get invalidBackupFormat => 'Ungültiges Sicherungsformat';

  @override
  String get importBackupTitle => 'Sicherung importieren';

  @override
  String get import => 'Importieren';

  @override
  String get backupShareSuccess => 'Sicherungsdatei erfolgreich geteilt';

  @override
  String get requiredUpdateAvailable =>
      'Ein erforderliches Update ist verfügbar. Bitte aktualisieren Sie, um die App weiter zu verwenden.';

  @override
  String updateCheckError(Object error) {
    return 'Fehler beim Überprüfen auf Updates: $error';
  }

  @override
  String importingBackupFile(Object fileName) {
    return 'Sie sind dabei, die Sicherungsdatei \"$fileName\" zu importieren, dies wird alle aktuellen Daten überschreiben. Fortfahren?';
  }

  @override
  String hardcodedStringFound(Object fileName) {
    return '即将导入备份文件 \"$fileName\"，这将覆盖当前的所有数据。确定继续吗？';
  }

  @override
  String get testNotifications => 'Testbenachrichtigungen';

  @override
  String get testNotificationChannel => 'Testbenachrichtigungskanal';

  @override
  String get testNotificationContent =>
      'Dies ist eine Testbenachrichtigung, um zu überprüfen, ob Benachrichtigungen ordnungsgemäß funktionieren.';

  @override
  String get failedToSendTestNotification =>
      'Senden der Testbenachrichtigung fehlgeschlagen: ';

  @override
  String get failedToCheckForUpdates =>
      'Überprüfung auf Updates fehlgeschlagen';

  @override
  String get errorCheckingForUpdates => 'Fehler beim Überprüfen auf Updates: ';

  @override
  String get updateFileName => 'easy_todo_update.apk';

  @override
  String get unknownDate => 'Unbekanntes Datum';

  @override
  String get restoreSuccessPrefix => 'Wiederhergestellt ';

  @override
  String get restoreSuccessSuffix => ' Aufgaben';

  @override
  String get importSuccessPrefix =>
      'Sicherungsdatei erfolgreich importiert, wiederhergestellt ';

  @override
  String get importFailedPrefix => 'Import fehlgeschlagen: ';

  @override
  String get cleanupFailedPrefix => 'Bereinigung fehlgeschlagen: ';

  @override
  String get developerName => '梦凌汐 (MeowLynxSea)';

  @override
  String get createYourFirstRepeatTask =>
      'Erstellen Sie Ihre erste wiederkehrende Aufgabe, um zu beginnen';

  @override
  String get rate => 'Bewerten';

  @override
  String get openSource => 'Open Source';

  @override
  String get repeatTodoTest => 'Wiederkehrende Aufgabe testen';

  @override
  String get repeatTodos => 'Wiederkehrende Aufgaben';

  @override
  String get addRepeatTodo => 'Wiederkehrende Aufgabe hinzufügen';

  @override
  String get checkRepeatTodos => 'Wiederkehrende Aufgaben überprüfen';

  @override
  String get authenticateToAccessApp =>
      'Bitte authentifizieren Sie sich, um die App weiter zu verwenden';

  @override
  String get backupFileSubject => 'Easy Todo Sicherungsdatei';

  @override
  String get shareFailedPrefix => 'Teilen fehlgeschlagen: ';

  @override
  String get schedulingTodoReminder => 'Aufgabenerinnerung planen \"';

  @override
  String get todoReminderTimerScheduled =>
      'Aufgabenerinnerungs-Timer erfolgreich geplant';

  @override
  String get allRemindersRescheduled =>
      'Alle Erinnerungen erfolgreich neu geplant';

  @override
  String get allTimersCleared => 'Alle Timer gelöscht';

  @override
  String get allNotificationChannelsCreated =>
      'Alle Benachrichtigungskanäle erfolgreich erstellt';

  @override
  String get utc => 'UTC';

  @override
  String get gmt => 'GMT';

  @override
  String get authenticateToEnableFingerprint =>
      'Bitte authentifizieren Sie sich, um die Fingerabdruck-Sperre zu aktivieren';

  @override
  String get authenticateToDisableFingerprint =>
      'Bitte authentifizieren Sie sich, um die Fingerabdruck-Sperre zu deaktivieren';

  @override
  String get authenticateToAccessWithFingerprint =>
      'Bitte verwenden Sie die Fingerabdruck-Überprüfung, um auf die App zuzugreifen';

  @override
  String get authenticateToAccessWithBiometric =>
      'Bitte verwenden Sie die biometrische Überprüfung, um Ihre Identität zu überprüfen, um fortzufahren';

  @override
  String get authenticateToClearData =>
      'Bitte verwenden Sie die biometrische Überprüfung, um alle Daten zu löschen';

  @override
  String get clearDataFailedPrefix => 'Löschen der Daten fehlgeschlagen: ';

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
  String get deleteAction => 'löschen';

  @override
  String get toggleReminderAction => 'toggle_reminder';

  @override
  String get pomodoroAction => 'pomodoro';

  @override
  String get completedKey => 'abgeschlossen';

  @override
  String get totalKey => 'gesamt';

  @override
  String get zh => 'zh';

  @override
  String get en => 'en';

  @override
  String everyNDays(Object count) {
    return 'Alle $count Tage';
  }

  @override
  String get dataStatistics => 'Datenstatistiken';

  @override
  String get dataStatisticsDescription =>
      'Anzahl der wiederkehrenden Aufgaben mit aktivierten Datenstatistiken';

  @override
  String get statisticsModes => 'Statistikmodi';

  @override
  String get statisticsModesDescription =>
      'Die anzuwendenden statistischen Analysemethoden auswählen';

  @override
  String get dataUnit => 'Dateneinheit';

  @override
  String get dataUnitHint => 'z.B. kg, km, \$, %';

  @override
  String get statisticsModeAverage => 'Durchschnitt';

  @override
  String get statisticsModeGrowth => 'Wachstum';

  @override
  String get statisticsModeExtremum => 'Extremwert';

  @override
  String get statisticsModeTrend => 'Trend';

  @override
  String get enterDataToComplete => 'Daten eingeben zum Abschließen';

  @override
  String get enterDataDescription =>
      'Diese wiederkehrende Aufgabe erfordert Dateneingabe vor Abschluss';

  @override
  String get dataValue => 'Datenwert';

  @override
  String get dataValueHint => 'Einen numerischen Wert eingeben';

  @override
  String get dataValueRequired =>
      'Bitte geben Sie einen Datenwert ein, um diese Aufgabe abzuschließen';

  @override
  String get invalidDataValue => 'Bitte geben Sie eine gültige Zahl ein';

  @override
  String get dataStatisticsTab => 'Datenstatistiken';

  @override
  String get selectRepeatTask => 'Wiederkehrende Aufgabe auswählen';

  @override
  String get selectRepeatTaskHint =>
      'Wählen Sie eine wiederkehrende Aufgabe aus, um ihre Statistiken anzuzeigen';

  @override
  String get timePeriod => 'Zeitraum';

  @override
  String get timePeriodToday => 'Heute';

  @override
  String get timePeriodThisWeek => 'Diese Woche';

  @override
  String get timePeriodThisMonth => 'Diesen Monat';

  @override
  String get timePeriodOverview => 'Übersicht';

  @override
  String get timePeriodCustom => 'Benutzerdefinierter Bereich';

  @override
  String get selectCustomRange => 'Datumsbereich auswählen';

  @override
  String get noRepeatTasksWithStats =>
      'Keine wiederkehrenden Aufgaben mit aktivierten Statistiken';

  @override
  String get noDataAvailable =>
      'Keine Daten für den ausgewählten Zeitraum verfügbar';

  @override
  String get dataProgressToday => 'Heutiger Fortschritt';

  @override
  String get averageValue => 'Durchschnittswert';

  @override
  String get totalValue => 'Gesamtwert';

  @override
  String get dataPoints => 'Datenpunkte';

  @override
  String get growthRate => 'Wachstumsrate';

  @override
  String get trendAnalysis => 'Trendanalyse';

  @override
  String get maximumValue => 'Maximum';

  @override
  String get minimumValue => 'Minimum';

  @override
  String get extremumAnalysis => 'Extremwertanalyse';

  @override
  String get statisticsSummary => 'Statistikzusammenfassung';

  @override
  String get dataVisualization => 'Datenvisualisierung';

  @override
  String get chartTitle => 'Daten-Trends';

  @override
  String get lineChart => 'Liniendiagramm';

  @override
  String get barChart => 'Balkendiagramm';

  @override
  String get showValueOnDrag => 'Wert beim Ziehen auf Diagramm anzeigen';

  @override
  String get dragToShowValue =>
      'Auf Diagramm ziehen, um detaillierte Werte zu sehen';

  @override
  String get analytics => 'Analytik';

  @override
  String get dataEntry => 'Dateneingabe';

  @override
  String get statisticsEnabled => 'Statistiken aktiviert';

  @override
  String get dataCollection => 'Datensammlung';

  @override
  String repeatTodoWithStats(Object count) {
    return 'Wiederkehrende Aufgaben mit Statistiken: $count';
  }

  @override
  String dataEntries(Object count) {
    return 'Dateneinträge: $count';
  }

  @override
  String withDataValues(Object count) {
    return 'mit Werten: $count';
  }

  @override
  String totalDataSize(Object size) {
    return 'Gesamtdatengröße: $size';
  }

  @override
  String get dataBackupSupported =>
      'Datensicherung und -wiederherstellung unterstützt';

  @override
  String get repeatTasks => 'Wiederkehrende Aufgaben';

  @override
  String get dataStatisticsEnabled => 'Datenstatistiken aktiviert';

  @override
  String get statisticsData => 'Statistikdaten';

  @override
  String get dataStatisticsEnabledShort => 'Daten-Stat.';

  @override
  String get dataWithValue => 'Mit Werten';

  @override
  String get noDataStatisticsEnabled => 'Keine Datenstatistiken aktiviert';

  @override
  String get enableDataStatisticsHint =>
      'Aktivieren Sie Datenstatistiken für wiederkehrende Aufgaben, um Analysen zu sehen';

  @override
  String get selectTimePeriod => 'Zeitraum auswählen';

  @override
  String get customRange => 'Benutzerdefinierter Bereich';

  @override
  String get selectRepeatTaskToViewData =>
      'Wählen Sie eine wiederkehrende Aufgabe aus, um ihre Datenstatistiken anzuzeigen';

  @override
  String get noStatisticsData => 'Keine Statistikdaten verfügbar';

  @override
  String get completeSomeTodosToSeeData =>
      'Schließen Sie einige Aufgaben mit Daten ab, um Statistiken zu sehen';

  @override
  String get totalEntries => 'Gesamteinträge';

  @override
  String get average => 'Durchschnitt';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get totalGrowth => 'Gesamtwachstum';

  @override
  String get notEnoughDataForCharts => 'Nicht genug Daten für Diagramme';

  @override
  String get averageTrend => 'Durchschnittlicher Trend';

  @override
  String get averageChartDescription =>
      'Zeigt die Durchschnittswerte über die Zeit mit Trendanalyse';

  @override
  String get trendDirection => 'Trendrichtung';

  @override
  String get trendStrength => 'Trendstärke';

  @override
  String get growthAnalysis => 'Wachstumsanalyse';

  @override
  String get range => 'Bereich';

  @override
  String get stableTrendDescription => 'Stabiler Trend mit minimaler Variation';

  @override
  String get weakTrendDescription => 'Schwacher Trend mit einigen Variationen';

  @override
  String get moderateTrendDescription => 'Mäßiger Trend mit klarer Richtung';

  @override
  String get strongTrendDescription =>
      'Starker Trend mit signifikanter Variation';

  @override
  String get invalidNumberFormat => 'Ungültiges Zahlenformat';

  @override
  String get dataUnitRequired =>
      'Dateneinheit ist erforderlich, wenn Datenstatistiken aktiviert sind';

  @override
  String get growth => 'Wachstum';

  @override
  String get extremum => 'Extremwert';

  @override
  String get trend => 'Trend';

  @override
  String get dataInputRequired =>
      'Dateneingabe ist erforderlich, um diese Aufgabe abzuschließen';

  @override
  String get todayProgress => 'Heutiger Fortschritt';

  @override
  String get dataProgress => 'Datenfortschritt';

  @override
  String get noDataForToday => 'Keine Daten für heute';

  @override
  String get weeklyDataStats => 'Wöchentliche Datenstatistiken';

  @override
  String get noDataForThisWeek => 'Keine Daten für diese Woche';

  @override
  String get daysTracked => 'Verfolgte Tage';

  @override
  String get monthlyDataStats => 'Monatliche Datenstatistiken';

  @override
  String get noDataForThisMonth => 'Keine Daten für diesen Monat';

  @override
  String get customDateRange => 'Benutzerdefinierter Datumsbereich';

  @override
  String get allData => 'Alle Daten';

  @override
  String get breakdownByTask => 'Aufschlüsselung nach Aufgabe';

  @override
  String get clear => 'Löschen';

  @override
  String get trendUp => 'Aufwärtstrend';

  @override
  String get trendDown => 'Abwärtstrend';

  @override
  String get trendStable => 'Stabiler Trend';

  @override
  String get needMoreDataToAnalyze =>
      'Mehr Daten müssen zur Analyse gesammelt werden';

  @override
  String get taskCompleted => 'Aufgabe abgeschlossen';

  @override
  String get taskWithdrawn => 'Aufgabe zurückgezogen';

  @override
  String get noDefaultSettings =>
      'Keine Standardeinstellungen gefunden, Standardeinstellungen werden erstellt';

  @override
  String get authenticateForSensitiveOperation =>
      'Bitte verwenden Sie die biometrische Authentifizierung, um Ihre Identität zu überprüfen';

  @override
  String get insufficientData => 'Unzureichende Daten';

  @override
  String get stable => 'Stabil';

  @override
  String get strongUpward => 'Starker Aufwärtstrend';

  @override
  String get upward => 'Aufwärtstrend';

  @override
  String get strongDownward => 'Starker Abwärtstrend';

  @override
  String get downward => 'Abwärtstrend';

  @override
  String get repeatTasksRefreshedSuccessfully =>
      'Wiederkehrende Aufgaben erfolgreich aktualisiert';

  @override
  String get errorRefreshingRepeatTasks =>
      'Fehler beim Aktualisieren der wiederkehrenden Aufgaben';

  @override
  String get forceRefresh => 'Erzwinge Aktualisierung';

  @override
  String get errorLoadingRepeatTasks =>
      'Fehler beim Laden der wiederkehrenden Aufgaben';

  @override
  String get pleaseCheckStoragePermissions =>
      'Bitte überprüfen Sie Ihre Speicherberechtigungen und versuchen Sie es erneut';

  @override
  String get todoReminders => 'Aufgabenerinnerungen';

  @override
  String get notificationsForIndividualTodoReminders =>
      'Benachrichtigungen für einzelne Aufgabenerinnerungen';

  @override
  String get notificationsForDailySummary =>
      'Tägliche Zusammenfassung ausstehender Aufgaben';

  @override
  String get pomodoroComplete => 'Pomodoro abgeschlossen';

  @override
  String get notificationsForPomodoroSessions =>
      'Benachrichtigungen wenn Pomodoro-Sitzungen abgeschlossen werden';

  @override
  String get dailyTodoSummary => 'Tägliche Aufgabenzusammenfassung';

  @override
  String youHavePendingTodos(Object count, Object n, Object s) {
    return 'Sie haben $count ausstehende Aufgabe$n zu erledigen';
  }

  @override
  String greatJobTimeForBreak(Object breakType) {
    return 'Gute Arbeit! Zeit für eine $breakType Pause';
  }

  @override
  String get shortBreak => 'kurze';

  @override
  String get longBreak => 'lange';

  @override
  String get themeColorMysteriousPurple => 'Geheimnisvolles Lila';

  @override
  String get themeColorSkyBlue => 'Himmelblau';

  @override
  String get themeColorGemGreen => 'Edelstein Grün';

  @override
  String get themeColorLemonYellow => 'Zitronengelb';

  @override
  String get themeColorFlameRed => 'Flammenrot';

  @override
  String get themeColorElegantPurple => 'Elegantes Lila';

  @override
  String get themeColorCherryPink => 'Kirschpink';

  @override
  String get themeColorForestCyan => 'Waldcyan';

  @override
  String get aiSettings => 'KI-Einstellungen';

  @override
  String get aiFeatures => 'KI-Funktionen';

  @override
  String get aiEnabled => 'KI-Funktionen aktiviert';

  @override
  String get aiDisabled => 'KI-Funktionen deaktiviert';

  @override
  String get enableAIFeatures => 'KI-Funktionen aktivieren';

  @override
  String get enableAIFeaturesSubtitle =>
      'Verwenden Sie künstliche Intelligenz, um Ihre ToDo-Erfahrung zu verbessern';

  @override
  String get apiConfiguration => 'API-Konfiguration';

  @override
  String get apiEndpoint => 'API-Endpunkt';

  @override
  String get pleaseEnterApiEndpoint => 'Bitte geben Sie den API-Endpunkt ein';

  @override
  String get invalidApiEndpoint =>
      'Bitte geben Sie einen gültigen API-Endpunkt ein';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get pleaseEnterApiKey => 'Bitte geben Sie den API-Schlüssel ein';

  @override
  String get modelName => 'Modellname';

  @override
  String get pleaseEnterModelName => 'Bitte geben Sie den Modellnamen ein';

  @override
  String get advancedSettings => 'Erweiterte Einstellungen';

  @override
  String get timeout => 'Timeout (ms)';

  @override
  String get pleaseEnterTimeout => 'Bitte geben Sie den Timeout ein';

  @override
  String get invalidTimeout =>
      'Bitte geben Sie einen gültigen Timeout ein (mindestens 1000ms)';

  @override
  String get temperature => 'Temperatur';

  @override
  String get pleaseEnterTemperature => 'Bitte geben Sie die Temperatur ein';

  @override
  String get invalidTemperature =>
      'Bitte geben Sie eine gültige Temperatur ein (0.0 - 2.0)';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get pleaseEnterMaxTokens =>
      'Bitte geben Sie die maximale Token-Zahl ein';

  @override
  String get invalidMaxTokens =>
      'Bitte geben Sie gültige maximale Tokens ein (mindestens 1)';

  @override
  String get rateLimit => 'Rate Limit';

  @override
  String get rateLimitSubtitle => 'Maximale Anfragen pro Minute';

  @override
  String get pleaseEnterRateLimit => 'Bitte geben Sie das Rate Limit ein';

  @override
  String get invalidRateLimit => 'Rate Limit muss zwischen 1 und 100 liegen';

  @override
  String get rateAndTokenLimits => 'Rate- und Token-Limits';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get connectionSuccessful => 'Verbindung erfolgreich!';

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get aiFeaturesToggle => 'KI-Funktionen umschalten';

  @override
  String get autoCategorization => 'Automatische Kategorisierung';

  @override
  String get autoCategorizationSubtitle =>
      'Kategorisieren Sie Ihre Aufgaben automatisch';

  @override
  String get prioritySorting => 'Prioritätssortierung';

  @override
  String get prioritySortingSubtitle =>
      'Bewerten Sie die Wichtigkeit und Priorität von Aufgaben';

  @override
  String get motivationalMessages => 'Motivierende Nachrichten';

  @override
  String get motivationalMessagesSubtitle =>
      'Generieren Sie ermutigende Nachrichten basierend auf Ihrem Fortschritt';

  @override
  String get smartNotifications => 'Intelligente Benachrichtigungen';

  @override
  String get smartNotificationsSubtitle =>
      'Erstellen Sie personalisierten Benachrichtigungsinhalt';

  @override
  String get completionMotivation => 'Abschlussmotivation';

  @override
  String get completionMotivationSubtitle =>
      'Zeigen Sie Motivation basierend auf der täglichen Abschlussrate';

  @override
  String get aiCategoryWork => 'Arbeit';

  @override
  String get aiCategoryPersonal => 'Persönlich';

  @override
  String get aiCategoryStudy => 'Studium';

  @override
  String get aiCategoryHealth => 'Gesundheit';

  @override
  String get aiCategoryFitness => 'Fitness';

  @override
  String get aiCategoryFinance => 'Finanzen';

  @override
  String get aiCategoryShopping => 'Einkaufen';

  @override
  String get aiCategoryFamily => 'Familie';

  @override
  String get aiCategorySocial => 'Sozial';

  @override
  String get aiCategoryHobby => 'Hobbys';

  @override
  String get aiCategoryTravel => 'Reisen';

  @override
  String get aiCategoryOther => 'Andere';

  @override
  String get aiPriorityHigh => 'Hohe Priorität';

  @override
  String get aiPriorityMedium => 'Mittlere Priorität';

  @override
  String get aiPriorityLow => 'Niedrige Priorität';

  @override
  String get aiPriorityUrgent => 'Dringend';

  @override
  String get aiPriorityImportant => 'Wichtig';

  @override
  String get aiPriorityNormal => 'Normal';

  @override
  String get selectTodoForPomodoro => 'Eine Aufgabe auswählen';

  @override
  String get pomodoroDescription =>
      'Wählen Sie eine Aufgabe aus, um Ihre Pomodoro-Fokussitzung zu starten';

  @override
  String get noTodosForPomodoro => 'Keine verfügbaren Aufgaben';

  @override
  String get createTodoForPomodoro =>
      'Bitte erstellen Sie zuerst einige Aufgaben';

  @override
  String get todaySessions => 'Heutige Sitzungen';

  @override
  String get startPomodoro => 'Pomodoro starten';

  @override
  String get aiDebugInfo => 'AI Debug-Info';

  @override
  String get processingUnprocessedTodos =>
      'Verarbeite unverarbeitete Aufgaben mit KI';

  @override
  String get processAllTodosWithAI => 'Alle Aufgaben mit KI verarbeiten';

  @override
  String todayTimeFormat(Object time) {
    return 'Heute $time';
  }

  @override
  String tomorrowTimeFormat(Object time) {
    return 'Morgen $time';
  }

  @override
  String get deleteTodoDialogTitle => 'Löschen';

  @override
  String get deleteTodoDialogMessage =>
      'Möchten Sie diese Aufgabe wirklich löschen?';

  @override
  String get deleteTodoDialogCancel => 'Abbrechen';

  @override
  String get deleteTodoDialogDelete => 'Löschen';

  @override
  String get customPersona => 'Benutzerdefinierte Persona';

  @override
  String get personaPrompt => 'Persona-Aufforderung';

  @override
  String get personaPromptHint =>
      'z.B., Sie sind ein freundlicher Assistent, der Humor und Emojis verwendet...';

  @override
  String get personaPromptDescription =>
      'Passen Sie die KI-Persönlichkeit für Benachrichtigungen an. Dies wird sowohl auf ToDo-Erinnerungen als auch auf tägliche Zusammenfassungen angewendet.';

  @override
  String get personaExample1 =>
      'Sie sind ein motivierender Trainer, der mit positiver Verstärkung ermutigt';

  @override
  String get personaExample2 =>
      'Sie sind ein humorvoller Assistent, der leichten Humor und Emojis verwendet';

  @override
  String get personaExample3 =>
      'Sie sind ein professioneller Produktivitätsexperte, der prägnante Ratschläge gibt';

  @override
  String get personaExample4 =>
      'Sie sind ein unterstützender Freund, der mit Wärme und Fürsorge erinnert';

  @override
  String get aiDebugInfoTitle => 'KI Debug-Info';

  @override
  String get aiDebugInfoSubtitle => 'KI-Funktionalitätsstatus überprüfen';

  @override
  String get aiSettingsStatus => 'KI-Einstellungsstatus';

  @override
  String get aiFeatureToggles => 'KI-Funktionsumschalter';

  @override
  String get aiTodoProviderConnection => 'ToDo-Anbieterverbindung';

  @override
  String get aiMessages => 'KI-Nachrichten';

  @override
  String get aiApiRequestManager => 'API-Anforderungsmanager';

  @override
  String get aiCurrentRequestQueue => 'Aktuelle Anforderungswarteschlange';

  @override
  String get aiRecentRequests => 'Letzte Anforderungen';

  @override
  String get aiPermissionRequestMessage =>
      'Bitte aktivieren Sie die Berechtigung \"Alarme & Erinnerungen\" für \"Easy Todo\" in den Systemeinstellungen.';

  @override
  String get developerNameMeowLynxSea => '梦凌汐 (MeowLynxSea)';

  @override
  String get developerEmail => 'mew@meowdream.cn';

  @override
  String get developerGithub => 'github.com/MeowLynxSea';

  @override
  String get developerWebsite => 'www.meowdream.cn';

  @override
  String get backupFileShareSubject => 'Easy Todo Sicherungsdatei';

  @override
  String shareFailed(Object error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get authenticateToAccessAppMessage =>
      'Bitte verwenden Sie den Fingerabdruck, um auf die App zuzugreifen';

  @override
  String get aiFeaturesEnabled => 'KI-Funktionen aktiviert';

  @override
  String get aiServiceValid => 'KI-Dienst gültig';

  @override
  String get notConfigured => 'Nicht konfiguriert';

  @override
  String configured(Object count) {
    return 'Konfiguriert ($count Zeichen)';
  }

  @override
  String get aiProviderConnected => 'KI-Anbieter verbunden';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get aiProcessedTodos => 'KI-verarbeitete Aufgaben';

  @override
  String get todosWithAICategory => 'Aufgaben mit KI-Kategorie';

  @override
  String get todosWithAIPriority => 'Aufgaben mit KI-Priorität';

  @override
  String get lastError => 'Letzter Fehler';

  @override
  String get pendingRequests => 'Ausstehende Anforderungen';

  @override
  String get currentWindowRequests => 'Aktuelle Fensteranforderungen';

  @override
  String get maxRequestsPerMinute => 'Max. Anforderungen/Minute';

  @override
  String get status => 'Status';

  @override
  String get aiServiceNotAvailable => 'KI-Dienst nicht verfügbar';

  @override
  String get completionMessages => 'Abschlussnachrichten';

  @override
  String get exactAlarmPermission => 'Exakte Alarmberechtigung';

  @override
  String get exactAlarmPermissionContent =>
      'Um sicherzustellen, dass Pomodoro- und Erinnerungsfunktionen genau funktionieren, benötigt die App die exakte Alarmberechtigung.\n\nBitte aktivieren Sie die Berechtigung \"Alarme & Erinnerungen\" für \"Easy Todo\" in den Systemeinstellungen.';

  @override
  String get setLater => 'Später einstellen';

  @override
  String get goToSettings => 'Zu den Einstellungen gehen';

  @override
  String get batteryOptimizationSettings => 'Akku-Optimierungseinstellungen';

  @override
  String get batteryOptimizationContent =>
      'Um sicherzustellen, dass Pomodoro- und Erinnerungsfunktionen ordnungsgemäß im Hintergrund ausgeführt werden, deaktivieren Sie bitte die Akku-Optimierung für diese App.\n\nDies kann den Akkuverbrauch erhöhen, stellt jedoch sicher, dass Timer- und Erinnerungsfunktionen genau funktionieren.';

  @override
  String get breakTimeComplete => 'Pause beendet!';

  @override
  String get timeToGetBackToWork => 'Zeit, wieder an die Arbeit zu gehen!';

  @override
  String get aiServiceReturnedEmptyMessage =>
      'KI-Dienst hat leere Nachricht zurückgegeben';

  @override
  String errorGeneratingMotivationalMessage(Object error) {
    return 'Fehler beim Generieren der motivierenden Nachricht: $error';
  }

  @override
  String get aiServiceNotAvailableCheckSettings =>
      'KI-Dienst nicht verfügbar, bitte überprüfen Sie die KI-Einstellungen';

  @override
  String get filterByCategory => 'Nach Kategorie filtern';

  @override
  String get importance => 'Wichtigkeit';

  @override
  String get noCategoriesAvailable => 'Keine Kategorien verfügbar';

  @override
  String get aiWillCategorizeTasks =>
      'KI wird Aufgaben automatisch kategorisieren, bitte versuchen Sie es später erneut';

  @override
  String get selectCategories => 'Kategorien auswählen';

  @override
  String get selectedCategories => 'Ausgewählt';

  @override
  String get categories => 'Kategorien';

  @override
  String get apiFormat => 'API-Format';

  @override
  String get apiFormatDescription =>
      'Wählen Sie Ihren KI-Dienstanbieter. Verschiedene Anbieter erfordern möglicherweise unterschiedliche API-Endpunkte und Authentifizierungsmethoden.';

  @override
  String get openaiFormat => 'OpenAI';

  @override
  String get anthropicFormat => 'Anthropic';

  @override
  String aiPromptCategorization(Object description, Object title) {
    return 'Klassifizieren Sie diese Todo-Aufgabe in eine dieser Kategorien:\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n      \n      Aufgabe: \"$title\"\n      Beschreibung: \"$description\"\n\n      Antworten Sie nur mit dem Kategorienamen in Kleinbuchstaben. Wählen Sie die am besten geeignete Kategorie basierend auf dem Inhalt und Kontext der Aufgabe.';
  }

  @override
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  ) {
    return 'Bewerten Sie die Priorität dieser Todo-Aufgabe von 0-100, unter Berücksichtigung von:\n      - Dringlichkeit: Wie schnell wird es benötigt? (Frist: $deadline)\n      - Auswirkungen: Was sind die Konsequenzen des Nicht-Abschlusses?\n      - Aufwand: Wie viel Zeit/Ressourcen werden benötigt?\n      - Persönliche Wichtigkeit: Wie wertvoll ist dies für Sie?\n\n      Aufgabe: \"$title\"\n      Beschreibung: \"$description\"\n      Hat Frist: $hasDeadline\n      Frist: $deadline\n\n      Richtlinien:\n      - 0-20: Niedrige Priorität, kann verschoben werden\n      - 21-40: Mittlere Priorität, sollte bald erledigt werden\n      - 41-70: Hohe Priorität, wichtig zu vervollständigen\n      - 71-100: Kritische Priorität, dringender Abschluss erforderlich\n\n      Antworten Sie nur mit einer Zahl von 0-100.';
  }

  @override
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  ) {
    return 'Generieren Sie eine motivierende Nachricht basierend auf diesen statistischen Daten:\n      Name: \"$name\"\n      Beschreibung: \"$description\"\n      Wert: $value\n      Einheit: \"$unit\"\n      Datum: $date\n\n      Anforderungen:\n      - Machen Sie es ermutigend und datenspezifisch\n      - Halten Sie es unter 25 Zeichen\n      - Konzentrieren Sie sich auf Erfolge und Fortschritt\n      - Verwenden Sie positive, aktionsorientierte Sprache\n      - Beispiel: \"Großer Fortschritt heute! 🎯\" oder \"Weiter so! 💪\"\n      - Antworten Sie nur mit der Nachricht, ohne Erklärungen';
  }

  @override
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  ) {
    return 'Erstellen Sie eine personalisierte Benachrichtigungserinnerung für diese Aufgabe:\n      Aufgabe: \"$title\"\n      Beschreibung: \"$description\"\n      Kategorie: $category\n      Priorität: $priority\n\n      Anforderungen:\n      - Erstellen Sie sowohl einen Titel als auch eine Nachricht\n      - Titel: Weniger als 20 Zeichen, aufmerksamkeitsstark\n      - Nachricht: Weniger als 50 Zeichen, motivierend und umsetzbar\n      - Verwenden Sie Emojis wo angemessen für Engagement\n      - Inklusive Dringlichkeit basierend auf Prioritätsniveau\n      - Machen Sie es persönlich und ermutigend\n      - Antworten Sie nur mit Titel und Nachricht im angegebenen Format, ohne Erklärungen\n\n      Formatieren Sie Ihre Antwort wie folgt:\n      TITLE: [Titel]\n      MESSAGE: [Nachricht]';
  }

  @override
  String aiPromptCompletion(Object completed, Object percentage, Object total) {
    return 'Generieren Sie eine ermutigende Nachricht basierend auf dem heutigen Todo-Completion:\n      Abgeschlossen: $completed von $total Aufgaben\n      Completion-Rate: $percentage%\n\n      Anforderungen:\n      - Machen Sie es positiv und motivierend\n      - Halten Sie es unter 25 Zeichen\n      - Feiern Sie Erfolge und Fortschritt\n      - Verwenden Sie ermutigende Sprache und/oder Emojis\n      - Beispiel: \"Ausgezeichnete Arbeit! 🌟\" oder \"Fortschritt! 👍\"\n      - Antworten Sie nur mit der Nachricht, ohne Erklärungen';
  }

  @override
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  ) {
    return 'Erstellen Sie eine tägliche Zusammenfassungsbenachrichtigung für ausstehende Todos.\n\nAnzahl ausstehender Aufgaben: $pendingCount\nKategorien: $categories\n      Durchschnittliche Priorität: $avgPriority/100\n\nErstellen Sie eine persönliche Zusammenfassung mit:\n1. Einem ansprechenden Titel (erste Zeile)\n2. Einer ermutigenden Nachricht, die DIE Anzahl der unvollendeten Aufgaben ($pendingCount) enthalten MUSS\n3. Halten Sie den Nachrichteninhalt unter 50 Zeichen. Machen Sie es motivierend und umsetzbar.\n4. Antworten Sie nur mit Titel und Nachricht, ohne Erklärungen';
  }

  @override
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  ) {
    return 'Erstellen Sie eine personalisierte Benachrichtigung für eine abgeschlossene $sessionType-Sitzung.\n\nSitzungsdetails:\n- Aufgabe: \"$taskTitle\"\n- Sitzungstyp: $sessionType\n- Dauer: $duration Minuten\n- Abgeschlossen: $isCompleted\n\nWICHTIG: Antworten Sie auf Deutsch.\n\nErstellen Sie einen Titel und eine Nachricht:\n1. Titel: Weniger als 20 Zeichen, aufmerksamkeitsstark und feierlich\n2. Nachricht: Weniger als 50 Zeichen, ermutigend und relevant für die abgeschlossene Sitzung\n3. Für Fokussitzungen (Arbeit abgeschlossen): Betonen Sie Arbeitsleistungen und dass es Zeit für eine wohlverdiente Pause ist\n4. Für Pausensitzungen (Pause abgeschlossen): Konzentrieren Sie sich auf die Beendigung der Pause und dass es Zeit ist, zur konzentrierten Arbeit zurückzukehren\n5. Verwenden Sie Emojis wo angemessen für Engagement\n6. Machen Sie es persönlich und motivierend\n7. Antworten Sie nur mit Titel und Nachricht im angegebenen Format, ohne Erklärungen\n\nFormatieren Sie Ihre Antwort wie folgt:\nTITLE: [Titel]\nMESSAGE: [Nachricht]';
  }

  @override
  String get cloudSyncAuthProcessingTitle => 'Anmelden';

  @override
  String get cloudSyncAuthProcessingSubtitle =>
      'Login-Callback wird verarbeitet…';

  @override
  String get cloudSyncChangePassphraseTitle => 'Passphrase ändern';

  @override
  String get cloudSyncChangePassphraseSubtitle =>
      'Nur DEK neu verpacken (keine Neuübertragung des Verlaufs)';

  @override
  String get cloudSyncChangePassphraseAction => 'Ändern';

  @override
  String get cloudSyncChangePassphraseDialogTitle => 'Sync-Passphrase ändern';

  @override
  String get cloudSyncChangePassphraseDialogHint =>
      'Dies aktualisiert nur das Schlüsselbündel. Andere Geräte müssen ggf. die neue Passphrase eingeben, um zu entsperren.';

  @override
  String get cloudSyncCurrentPassphrase => 'Aktuelle Passphrase';

  @override
  String get cloudSyncNewPassphrase => 'Neue Passphrase';

  @override
  String get cloudSyncPassphraseChangedSnack => 'Passphrase aktualisiert';

  @override
  String get syncAiApiKeyTitle =>
      'API-Schlüssel synchronisieren (verschlüsselt)';

  @override
  String get syncAiApiKeySubtitle =>
      'Teilen Sie Ihren API-Schlüssel geräteübergreifend per Ende-zu-Ende-Verschlüsselung (optional)';

  @override
  String get syncAiApiKeyWarningTitle => 'API-Schlüssel synchronisieren?';

  @override
  String get syncAiApiKeyWarningMessage =>
      'Ihr API-Schlüssel wird als Chiffretext hochgeladen und kann von Geräten mit Ihrer Sync-Passphrase entschlüsselt werden. Aktivieren Sie dies nur, wenn Sie das Risiko verstehen.';

  @override
  String get cloudSyncAutoSyncIntervalTitle => 'Automatisches Sync-Intervall';

  @override
  String get cloudSyncAutoSyncIntervalHint =>
      'Polling ist gerätespezifisch. Wenn lokale Änderungen ausstehen, können sie ggf. früher über den Outbox-Trigger synchronisiert werden.';

  @override
  String get cloudSyncAutoSyncIntervalSecondsLabel => 'Sekunden';

  @override
  String get cloudSyncAutoSyncIntervalMinHint => 'Mindestens 30 Sekunden';

  @override
  String get cloudSyncAutoSyncIntervalSavedSnack =>
      'Auto-Sync-Intervall gespeichert';

  @override
  String cloudSyncAutoSyncIntervalSubtitle(Object interval) {
    return 'Aktuell: $interval';
  }

  @override
  String cloudSyncSecondsFormat(Object count) {
    return '${count}s';
  }

  @override
  String cloudSyncMinutesFormat(Object count) {
    return '${count}m';
  }

  @override
  String cloudSyncMinutesSecondsFormat(Object minutes, Object seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String get todoAttachments => 'Attachments';

  @override
  String get todoAttachmentsEmpty => 'No attachments yet';

  @override
  String get todoAttachmentAdd => 'Add file';

  @override
  String todoAttachmentAddFailed(Object error) {
    return 'Failed to add attachment: $error';
  }

  @override
  String get todoAttachmentExport => 'Export';

  @override
  String get todoAttachmentNotAvailable => 'File not available yet';

  @override
  String get todoAttachmentRemoveConfirmTitle => 'Remove attachment?';

  @override
  String get todoAttachmentRemoveConfirmMessage =>
      'This will remove the attachment from all devices after sync.';

  @override
  String get todoAttachmentUploading => 'Uploading';

  @override
  String get todoAttachmentDownloading => 'Downloading';

  @override
  String get todoAttachmentReady => 'Ready';

  @override
  String get todoAttachmentWebNotSupported =>
      'Attachments are not supported on web';
}

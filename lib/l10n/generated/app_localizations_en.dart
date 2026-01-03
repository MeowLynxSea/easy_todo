// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get preferences => 'Preferences';

  @override
  String get appSettings => 'App Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Manage notification preferences';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageSettings =>
      'Language settings allow you to change the display language of the app. Select your preferred language from the list above.';

  @override
  String get dataStorage => 'Data & Storage';

  @override
  String get dataAndSync => 'Data & Sync';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get cloudSyncSubtitle => 'End-to-end encrypted sync';

  @override
  String get cloudSyncOverviewTitle => 'End-to-end encrypted sync';

  @override
  String get cloudSyncOverviewSubtitle =>
      'Server stores only ciphertext; unlock with your passphrase on this device.';

  @override
  String get cloudSyncConfigSaved => 'Sync config saved';

  @override
  String get cloudSyncServerOkSnack => 'Server reachable';

  @override
  String get cloudSyncServerCheckFailedSnack => 'Server check failed';

  @override
  String get cloudSyncDisabledSnack => 'Sync disabled';

  @override
  String get cloudSyncEnableSwitchTitle => 'Enable cloud sync';

  @override
  String get cloudSyncEnableSwitchSubtitle =>
      'Sync your data across your devices';

  @override
  String get cloudSyncServerSection => 'Server';

  @override
  String get cloudSyncSetupTitle => '1) Configure server';

  @override
  String get cloudSyncSetupSubtitle =>
      'Set server URL, then choose a provider and login.';

  @override
  String get cloudSyncSetupDialogTitle => 'Server configuration';

  @override
  String get cloudSyncServerUrl => 'Server URL';

  @override
  String get cloudSyncServerUrlHint => 'http://127.0.0.1:8787';

  @override
  String get cloudSyncAuthProvider => 'OAuth provider';

  @override
  String get cloudSyncAuthProviderHint => 'linuxdo';

  @override
  String get cloudSyncAuthMode => 'Auth';

  @override
  String get cloudSyncAuthModeLoggedIn => 'Logged in';

  @override
  String get cloudSyncAuthModeLoggedOut => 'Not logged in';

  @override
  String get cloudSyncCheckServer => 'Check server';

  @override
  String get cloudSyncEditServerConfig => 'Edit';

  @override
  String get cloudSyncLogin => 'Login';

  @override
  String get cloudSyncLogout => 'Logout';

  @override
  String get cloudSyncLoggedInSnack => 'Logged in';

  @override
  String get cloudSyncLoggedOutSnack => 'Logged out';

  @override
  String get cloudSyncLoginRedirectedSnack => 'Continue login in your browser';

  @override
  String get cloudSyncLoginFailedSnack => 'Login failed';

  @override
  String get cloudSyncNotSet => 'Not set';

  @override
  String get cloudSyncTokenSet => 'Token is set';

  @override
  String get cloudSyncStatusSection => 'Status';

  @override
  String get cloudSyncEnabled => 'Enabled';

  @override
  String get cloudSyncUnlocked => 'Unlocked';

  @override
  String get cloudSyncEnabledOn => 'Enabled: On';

  @override
  String get cloudSyncEnabledOff => 'Enabled: Off';

  @override
  String get cloudSyncUnlockedYes => 'Unlocked: Yes';

  @override
  String get cloudSyncUnlockedNo => 'Unlocked: No';

  @override
  String get cloudSyncConfiguredYes => 'Configured: Yes';

  @override
  String get cloudSyncConfiguredNo => 'Configured: No';

  @override
  String get cloudSyncLastServerSeq => 'Last serverSeq';

  @override
  String get cloudSyncDekId => 'DEK ID';

  @override
  String get cloudSyncLastSyncAt => 'Last sync';

  @override
  String get cloudSyncError => 'Error';

  @override
  String get cloudSyncDeviceId => 'Device ID';

  @override
  String get cloudSyncEnable => 'Enable';

  @override
  String get cloudSyncUnlock => 'Unlock';

  @override
  String get cloudSyncSyncNow => 'Sync now';

  @override
  String get cloudSyncDisable => 'Disable';

  @override
  String get cloudSyncSecurityTitle => '2) Unlock';

  @override
  String get cloudSyncSecuritySubtitle =>
      'Unlock uses your passphrase to access the DEK. Mobile/desktop can cache it in secure storage.';

  @override
  String get cloudSyncLockStateTitle => 'Encryption key';

  @override
  String get cloudSyncLockStateUnlocked => 'Unlocked on this device';

  @override
  String get cloudSyncLockStateLocked => 'Locked — enter passphrase to unlock';

  @override
  String get cloudSyncActionsTitle => '3) Sync';

  @override
  String get cloudSyncActionsSubtitle =>
      'Push local changes then pull remote updates.';

  @override
  String get cloudSyncAdvancedTitle => 'Advanced';

  @override
  String get cloudSyncAdvancedSubtitle => 'Debug info (device-local)';

  @override
  String get cloudSyncEnableDialogTitle => 'Enable sync';

  @override
  String get cloudSyncUnlockDialogTitle => 'Unlock sync';

  @override
  String get cloudSyncPassphraseDialogHint =>
      'If you already enabled sync on another device, enter the same passphrase twice.';

  @override
  String get cloudSyncPassphrase => 'Passphrase';

  @override
  String get cloudSyncConfirmPassphrase => 'Confirm passphrase';

  @override
  String get cloudSyncShowPassphrase => 'Show';

  @override
  String get cloudSyncEnabledSnack => 'Sync enabled';

  @override
  String get cloudSyncUnlockedSnack => 'Unlocked';

  @override
  String get cloudSyncSyncedSnack => 'Synced';

  @override
  String get cloudSyncInvalidPassphrase => 'Invalid passphrase';

  @override
  String get cloudSyncRollbackTitle => 'Possible server rollback';

  @override
  String get cloudSyncRollbackMessage =>
      'The server may have rolled back or restored from a backup. Continuing may cause data loss. What do you want to do?';

  @override
  String get cloudSyncStopSync => 'Stop sync';

  @override
  String get cloudSyncContinue => 'Continue';

  @override
  String get cloudSyncWebDekNote =>
      'Web stores the key until the browser is closed. Restarting the browser requires unlocking again.';

  @override
  String get cloudSyncStatusIdle => 'idle';

  @override
  String get cloudSyncStatusRunning => 'running';

  @override
  String get cloudSyncStatusError => 'error';

  @override
  String get cloudSyncErrorPassphraseMismatch => 'Passphrase mismatch';

  @override
  String get cloudSyncErrorNotConfigured => 'Sync not configured';

  @override
  String get cloudSyncErrorDisabled => 'Sync is disabled';

  @override
  String get cloudSyncErrorLocked => 'Sync is locked (missing DEK)';

  @override
  String get cloudSyncErrorAccountChanged =>
      'Account changed — please re-enable sync';

  @override
  String get cloudSyncErrorUnauthorized => 'Unauthorized (check token)';

  @override
  String get cloudSyncErrorBanned => 'Account banned';

  @override
  String get cloudSyncErrorKeyBundleNotFound =>
      'Key bundle not found on server';

  @override
  String get cloudSyncErrorNetwork => 'Network error';

  @override
  String get cloudSyncErrorConflict => 'Conflict (bundle version mismatch)';

  @override
  String get cloudSyncErrorQuotaExceeded =>
      'Server quota exceeded (some records were rejected)';

  @override
  String get cloudSyncErrorUnknown => 'Unknown error';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get backupSubtitle => 'Backup your data';

  @override
  String get storage => 'Storage';

  @override
  String get storageSubtitle => 'Manage storage space';

  @override
  String get about => 'About';

  @override
  String get aboutEasyTodo => 'About Easy Todo';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSubtitle => 'Get help with the app';

  @override
  String get processingCategory => 'Processing category...';

  @override
  String get processingPriority => 'Processing priority...';

  @override
  String get processingAI => 'Processing AI...';

  @override
  String get aiProcessingCompleted => 'AI processing completed';

  @override
  String get categorizingTask => 'Categorizing task...';

  @override
  String get processingAIStatus => 'Processing AI...';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearDataSubtitle => 'Delete all todos and settings';

  @override
  String get version => 'Version';

  @override
  String get appDescription =>
      'A clean, elegant todo list application designed for simplicity and productivity.';

  @override
  String get developer => 'Developer';

  @override
  String get developerInfo => 'Developer Information';

  @override
  String get needHelp => 'Need Help?';

  @override
  String get helpDescription =>
      'If you encounter any issues or have suggestions, feel free to reach out through any of the contact methods above.';

  @override
  String get close => 'Close';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get themeColors => 'Theme Colors';

  @override
  String get customTheme => 'Custom Theme';

  @override
  String get primaryColor => 'Primary Color';

  @override
  String get secondaryColor => 'Secondary Color';

  @override
  String get selectPrimaryColor => 'Select primary color for the app';

  @override
  String get selectSecondaryColor => 'Select secondary color for the app';

  @override
  String get selectColor => 'Select Color';

  @override
  String get hue => 'Hue';

  @override
  String get saturation => 'Saturation';

  @override
  String get lightness => 'Lightness';

  @override
  String get applyCustomTheme => 'Apply Custom Theme';

  @override
  String get customThemeApplied => 'Custom theme applied successfully';

  @override
  String get themeColorApplied => 'Theme color applied';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatTask => 'Repeat Task';

  @override
  String get repeatType => 'Repeat Type';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get selectDays => 'Select Days';

  @override
  String get selectDate => 'Select Date';

  @override
  String get everyDay => 'Every day';

  @override
  String get everyWeek => 'Every week';

  @override
  String get everyMonth => 'Every month';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get noEndDate => 'No End Date';

  @override
  String get timeRange => 'Time Range';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get noStartTimeSet => 'No start time set';

  @override
  String get noEndTimeSet => 'No end time set';

  @override
  String get invalidTimeRange => 'End time must be after start time';

  @override
  String get repeatEnabled => 'Repeat Enabled';

  @override
  String get repeatDescription => 'Create recurring tasks automatically';

  @override
  String get backfillMode => 'Catch-up mode';

  @override
  String get backfillModeDescription =>
      'Create missed recurring todos for previous days';

  @override
  String get backfillDays => 'Look-back days';

  @override
  String get backfillDaysDescription =>
      'Max days to look back (1-365, not including today)';

  @override
  String get backfillAutoComplete => 'Auto-complete backfilled todos';

  @override
  String get backfillDaysRangeError =>
      'Look-back days must be between 1 and 365';

  @override
  String get backfillConflictTitle => 'Backfill conflict';

  @override
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  ) {
    return 'Task \"$title\" starts on $startDate, but catch-up would look back to $backfillStartDate. Which should be used as the earliest generation date for this refresh?';
  }

  @override
  String get useStartDate => 'Use start date';

  @override
  String get useBackfillDays => 'Use catch-up range';

  @override
  String get activeRepeatTasks => 'Active Repeat Tasks';

  @override
  String get noRepeatTasks => 'No repeat tasks yet';

  @override
  String get pauseRepeat => 'Pause';

  @override
  String get resumeRepeat => 'Resume';

  @override
  String get editRepeat => 'Edit';

  @override
  String get deleteRepeat => 'Delete';

  @override
  String get loading => 'Loading';

  @override
  String get repeatTaskConfirm => 'Delete Repeat Task';

  @override
  String get repeatTaskDeleteMessage =>
      'This will delete all recurring tasks generated from this template. This action cannot be undone.';

  @override
  String get manageRepeatTasks => 'Manage Repeat Tasks';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get todos => 'Todos';

  @override
  String get schedule => 'Schedule';

  @override
  String get clearDataWarning =>
      'This will permanently delete all your todos and statistics. This action cannot be undone.';

  @override
  String get dataClearedSuccess => 'All data has been cleared successfully';

  @override
  String get clearDataFailed => 'Failed to clear data';

  @override
  String get history => 'History';

  @override
  String get stats => 'Stats';

  @override
  String get searchTodos => 'Search todos';

  @override
  String get addTodo => 'Add Todo';

  @override
  String get addTodoHint => 'What needs to be done?';

  @override
  String get todoTitle => 'Title';

  @override
  String get todoDescription => 'Description';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get complete => 'Complete';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get allTodos => 'All';

  @override
  String get activeTodos => 'Active';

  @override
  String get completedTodos => 'Completed';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get older => 'Older';

  @override
  String get totalTodos => 'Total Todos';

  @override
  String get completedTodosCount => 'Completed';

  @override
  String get activeTodosCount => 'Active';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get backupSuccess => 'Backup created successfully';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get restoreSuccess => 'Data restored successfully';

  @override
  String restoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get webBackupHint => 'Web: backups use download/upload.';

  @override
  String restoreWarning(Object fileName) {
    return 'This will replace all current data with data from \"$fileName\". This action cannot be undone. Continue?';
  }

  @override
  String get totalStorage => 'Total Storage';

  @override
  String get todosStorage => 'Todos';

  @override
  String get cacheStorage => 'Cache';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get sortBy => 'Sort by';

  @override
  String get newestFirst => 'Newest First';

  @override
  String get oldestFirst => 'Oldest First';

  @override
  String get alphabetical => 'Alphabetical';

  @override
  String get overview => 'Overview';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String get monthlyTrends => 'Monthly Trends';

  @override
  String get productivityOverview => 'Productivity Overview';

  @override
  String get overallCompletionRate => 'Overall Completion Rate';

  @override
  String get created => 'Created';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get todoDistribution => 'Todo Distribution';

  @override
  String get bestPerformance => 'Best Performance';

  @override
  String get noCompletedTodosYet => 'No completed todos yet';

  @override
  String get completionRateDescription => 'of all todos completed';

  @override
  String get fingerprintLock => 'App Lock';

  @override
  String get fingerprintLockSubtitle =>
      'Protect the app with device authentication';

  @override
  String get fingerprintLockEnable => 'Enable app lock';

  @override
  String get fingerprintLockDisable => 'Disable app lock';

  @override
  String get fingerprintLockEnabled => 'App lock enabled';

  @override
  String get fingerprintLockDisabled => 'App lock disabled';

  @override
  String get fingerprintNotAvailable => 'Device authentication not available';

  @override
  String get fingerprintNotEnrolled =>
      'No biometrics or device passcode set up';

  @override
  String get fingerprintAuthenticationFailed => 'Authentication failed';

  @override
  String get fingerprintAuthenticationSuccess => 'Authentication successful';

  @override
  String get active => 'Active';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get week1 => 'Week 1';

  @override
  String get week2 => 'Week 2';

  @override
  String get week3 => 'Week 3';

  @override
  String get week4 => 'Week 4';

  @override
  String withCompletedTodos(Object count) {
    return 'with $count todos completed';
  }

  @override
  String get unableToLoadBackupStats => 'Unable to load backup statistics';

  @override
  String get backupSummary => 'Backup Summary';

  @override
  String get itemsToBackup => 'Items to Backup';

  @override
  String get dataSize => 'Data Size';

  @override
  String get backupFiles => 'Backup Files';

  @override
  String get backupSize => 'Backup Size';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get backupRestoreDescription =>
      'Create a backup of your data or restore from a previous backup.';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get noBackupFilesFound => 'No backup files found';

  @override
  String get createFirstBackup => 'Create your first backup to get started';

  @override
  String get refresh => 'Refresh';

  @override
  String get restoreFromFile => 'Restore from this file';

  @override
  String get deleteFile => 'Delete file';

  @override
  String get aboutBackups => 'About Backups';

  @override
  String get backupInfo1 => '• Backups contain all your todos and statistics';

  @override
  String get backupInfo2 => '• Store backup files in a safe location';

  @override
  String get backupInfo3 => '• Regular backups help prevent data loss';

  @override
  String get backupInfo4 => '• You can restore from any backup file';

  @override
  String get backupCreatedSuccess => 'Backup created successfully';

  @override
  String get noBackupFilesAvailable => 'No backup files available for restore';

  @override
  String get selectBackupFile => 'Select Backup File';

  @override
  String get confirmRestore => 'Confirm Restore';

  @override
  String dataRestoredSuccess(Object fileName) {
    return 'Data restored successfully from \"$fileName\"';
  }

  @override
  String get deleteBackupFile => 'Delete Backup File';

  @override
  String deleteBackupWarning(Object fileName) {
    return 'Are you sure you want to delete \"$fileName\"? This action cannot be undone.';
  }

  @override
  String backupFileDeletedSuccess(Object fileName) {
    return 'Backup file \"$fileName\" deleted successfully';
  }

  @override
  String get backupFileNotFound => 'Backup file not found';

  @override
  String invalidFilePath(Object fileName) {
    return 'Invalid file path for \"$fileName\"';
  }

  @override
  String get failedToDeleteFile => 'Failed to delete file';

  @override
  String get files => 'files';

  @override
  String get storageManagement => 'Storage Management';

  @override
  String get storageOverview => 'Storage Overview';

  @override
  String get storageAnalytics => 'Storage Analytics';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get request => 'Request';

  @override
  String get unknown => 'Unknown';

  @override
  String get waiting => 'Waiting';

  @override
  String get noRecentRequests => 'No recent requests';

  @override
  String get requestCompleted => 'Request completed';

  @override
  String get noTodosToDisplay => 'No todos to display';

  @override
  String get todoStatusDistribution => 'Todo Status Distribution';

  @override
  String get completed => 'Completed';

  @override
  String get pending => 'Pending';

  @override
  String get dataStorageUsage => 'Data Storage Usage';

  @override
  String get total => 'Total';

  @override
  String get storageCleanup => 'Storage Cleanup';

  @override
  String get cleanupDescription =>
      'Free up storage space by removing unnecessary data:';

  @override
  String get clearCompletedTodos => 'Clear Completed Todos';

  @override
  String get clearOldStatistics => 'Clear Old Statistics';

  @override
  String get clearBackupFiles => 'Clear Backup Files';

  @override
  String get cleanupCompleted => 'Cleanup completed';

  @override
  String todosDeleted(Object count) {
    return '$count todos deleted';
  }

  @override
  String statisticsDeleted(Object count) {
    return '$count statistics deleted';
  }

  @override
  String backupFilesDeleted(Object count) {
    return '$count backup files deleted';
  }

  @override
  String get cleanupFailed => 'Cleanup failed';

  @override
  String get easyTodo => 'Easy Todo';

  @override
  String copiedToClipboard(Object url) {
    return 'Copied to clipboard: $url';
  }

  @override
  String cannotOpenLink(Object url) {
    return 'Cannot open link, copied to clipboard: $url';
  }

  @override
  String get email => 'Email';

  @override
  String get github => 'GitHub';

  @override
  String get website => 'Website';

  @override
  String get noTodosMatchSearch => 'No todos match your search';

  @override
  String get noCompletedTodos => 'No completed todos';

  @override
  String get noActiveTodos => 'No active todos';

  @override
  String get noTodosYet => 'No todos yet';

  @override
  String get deleteTodoConfirmation =>
      'Are you sure you want to delete this todo?';

  @override
  String get createdLabel => 'Created: ';

  @override
  String get completedLabel => 'Completed: ';

  @override
  String get filterByTime => 'Filter by Time';

  @override
  String get sortByTime => 'Sort by Time';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get threeDays => 'Three Days';

  @override
  String minutesAgoWithCount(Object count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgoWithCount(Object count) {
    return '$count hours ago';
  }

  @override
  String daysAgoWithCount(Object count) {
    return '$count days ago';
  }

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get dailySummaryTime => 'Daily Summary Time';

  @override
  String get dailySummaryDescription =>
      'Receive a daily summary of pending todos';

  @override
  String get defaultReminderSettings => 'Default Reminder Settings';

  @override
  String get enableDefaultReminders => 'Enable Default Reminders';

  @override
  String get reminderTimeBefore => 'Reminder Time Before Due';

  @override
  String minutesBefore(Object count) {
    return '$count minutes before';
  }

  @override
  String get notificationPermissions => 'Notification Permissions';

  @override
  String get grantPermissions => 'Grant Permissions';

  @override
  String get permissionsGranted => 'Permissions Granted';

  @override
  String get permissionsDenied => 'Permissions Denied';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get notificationTestSent => 'Test notification sent successfully';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get setReminder => 'Set Reminder';

  @override
  String reminderSet(Object time) {
    return 'Reminder set for $time';
  }

  @override
  String get cancelReminder => 'Cancel Reminder';

  @override
  String get noReminderSet => 'No reminder set';

  @override
  String get enableReminder => 'Enable Reminder';

  @override
  String get reminderOptions => 'Reminder Options';

  @override
  String get pomodoroTimer => 'Pomodoro Timer';

  @override
  String get pomodoroSettings => 'Pomodoro Settings';

  @override
  String get workDuration => 'Work Duration';

  @override
  String get breakDuration => 'Break Duration';

  @override
  String get longBreakDuration => 'Long Break Duration';

  @override
  String get sessionsUntilLongBreak => 'Sessions until Long Break';

  @override
  String get minutes => 'minutes';

  @override
  String get sessions => 'sessions';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get focusTime => 'Focus Time';

  @override
  String get clearOldPomodoroSessions => 'Clear Old Pomodoro Sessions';

  @override
  String pomodoroSessionsDeleted(Object count) {
    return 'Deleted $count pomodoro sessions';
  }

  @override
  String get breakTime => 'Break Time';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stop => 'Stop';

  @override
  String get timeSpent => 'Time spent';

  @override
  String get pomodoroStats => 'Pomodoro Statistics';

  @override
  String get sessionsCompleted => 'Sessions Completed';

  @override
  String get totalTime => 'Total Time';

  @override
  String get averageTime => 'Average Time';

  @override
  String get focusSessions => 'Focus Sessions';

  @override
  String get pomodoroSessions => 'Pomodoro Sessions';

  @override
  String get totalFocusTime => 'Total Focus Time';

  @override
  String get weeklyPomodoroStats => 'Weekly Pomodoro Stats';

  @override
  String get totalSessions => 'Total Sessions';

  @override
  String get averageSessions => 'Average Sessions';

  @override
  String get monthlyPomodoroStats => 'Monthly Pomodoro Stats';

  @override
  String get averagePerWeek => 'Average per Week';

  @override
  String get pomodoroOverview => 'Pomodoro Overview';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get checkUpdatesSubtitle => 'Search for new versions';

  @override
  String get checkingForUpdates => 'Checking for Updates';

  @override
  String get pleaseWait => 'Please wait while we check for updates...';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get requiredUpdate => 'Required Update';

  @override
  String versionAvailable(Object version) {
    return 'Version $version is available!';
  }

  @override
  String get whatsNew => 'What\'s new:';

  @override
  String get noUpdatesAvailable => 'No updates available';

  @override
  String get youHaveLatestVersion => 'You have the latest version';

  @override
  String get updateNow => 'Update Now';

  @override
  String get later => 'Later';

  @override
  String get downloadingUpdate => 'Downloading Update';

  @override
  String get downloadUpdate => 'Download Update';

  @override
  String get downloadFrom => 'Downloading update from:';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get couldNotOpenDownloadUrl => 'Could not open download URL';

  @override
  String get updateCheckFailed => 'Failed to check for updates';

  @override
  String get forceUpdateMessage =>
      'A required update is available. Please update to continue using the app.';

  @override
  String get optionalUpdateMessage => 'You can update now or later';

  @override
  String get storagePermissionDenied => 'Storage permission denied';

  @override
  String get cannotAccessStorage => 'Cannot access storage';

  @override
  String get updateDownloadSuccess => 'Update downloaded successfully';

  @override
  String get installUpdate => 'Install Update';

  @override
  String get startingInstaller => 'Starting installer...';

  @override
  String get updateFileNotFound =>
      'Update file not found, please download again';

  @override
  String get installPermissionRequired => 'Install Permission Required';

  @override
  String get installPermissionDescription =>
      'Installing app updates requires \"Install unknown apps\" permission. Please enable this permission for Easy Todo in settings.';

  @override
  String get needInstallPermission =>
      'Install permission is required to update the app';

  @override
  String installFailed(Object error) {
    return 'Installation failed: $error';
  }

  @override
  String installLaunchFailed(Object error) {
    return 'Installation launch failed: $error';
  }

  @override
  String get storagePermissionTitle => 'Storage Permission Required';

  @override
  String get storagePermissionDescription =>
      'To download and install app updates, Easy Todo needs access to device storage.';

  @override
  String get permissionNote =>
      'Clicking \"Allow\" will grant the app the following permissions:';

  @override
  String get accessDeviceStorage => '• Access device storage';

  @override
  String get downloadFilesToDevice => '• Download files to device';

  @override
  String get allow => 'Allow';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionDeniedMessage =>
      'Storage permission has been permanently denied. Please manually enable the permission in system settings and try again.';

  @override
  String get cannotOpenSettings => 'Cannot open settings page';

  @override
  String get autoUpdate => 'Auto Update';

  @override
  String get autoUpdateSubtitle =>
      'Automatically check for updates when app starts';

  @override
  String get autoUpdateEnabled => 'Auto update enabled';

  @override
  String get autoUpdateDisabled => 'Auto update disabled';

  @override
  String get exitApp => 'Exit App';

  @override
  String get viewSettings => 'View Settings';

  @override
  String get viewDisplay => 'View Display';

  @override
  String get viewDisplaySubtitle => 'Configure how content is displayed';

  @override
  String get todoViewSettings => 'Todo View Settings';

  @override
  String get historyViewSettings => 'History View Settings';

  @override
  String get scheduleLayoutSettings => 'Schedule Layout Settings';

  @override
  String get scheduleLayoutSettingsSubtitle =>
      'Customize time range and weekdays';

  @override
  String get scheduleColorGroups => 'Schedule Color Groups';

  @override
  String get scheduleColorGroupsSubtitle =>
      'Customize colors for completed and incomplete tasks';

  @override
  String get scheduleColorGroupPresets => 'Presets';

  @override
  String get scheduleColorGroupMyGroups => 'My groups';

  @override
  String get scheduleColorGroupNoMyGroups => 'No custom color groups yet.';

  @override
  String get scheduleColorGroupCreate => 'Create';

  @override
  String get scheduleColorGroupName => 'Name';

  @override
  String get scheduleColorGroupAddColor => 'Add color';

  @override
  String get scheduleColorGroupNeedAtLeastOneColor =>
      'Please add at least one color for both groups.';

  @override
  String scheduleColorGroupDeleteMessage(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get scheduleColorPresetWarmCool => 'Warm & Cool';

  @override
  String get scheduleColorPresetForestLavender => 'Forest & Lavender';

  @override
  String get scheduleColorPresetSunsetOcean => 'Sunset & Ocean';

  @override
  String get scheduleColorPresetGrayscale => 'Grayscale';

  @override
  String get viewMode => 'View Mode';

  @override
  String get listView => 'List View';

  @override
  String get stackingView => 'Stacking View';

  @override
  String get calendarView => 'Calendar View';

  @override
  String get openInNewPage => 'Open in New Page';

  @override
  String get openInNewPageSubtitle =>
      'Open views in new pages instead of popups';

  @override
  String get historyViewMode => 'History View Mode';

  @override
  String get scheduleTimeRange => 'Time Range';

  @override
  String get scheduleVisibleDays => 'Days Visible';

  @override
  String scheduleVisibleDaysValue(Object count) {
    return '$count days';
  }

  @override
  String get scheduleVisibleWeekdays => 'Days Shown';

  @override
  String get scheduleLabelTextScale => 'Label Text Scale';

  @override
  String get scheduleAtLeastOneDay => 'Keep at least one day selected.';

  @override
  String get dayDetails => 'Day Details';

  @override
  String get todoCount => 'Todo Count';

  @override
  String get completedCount => 'completed';

  @override
  String get totalCount => 'total';

  @override
  String get appLongDescription =>
      'Easy Todo is a clean, elegant and powerful todo list application designed to help you organize your daily tasks efficiently. With beautiful UI design, comprehensive statistics tracking, seamless API integration, and support for multiple languages, Easy Todo makes task management simple and enjoyable. Features include calendar view, history tracking, backup & restore, biometric authentication, and customizable themes to match your personal style.';

  @override
  String get cannotDeleteRepeatTodo => 'Cannot delete repeat todos';

  @override
  String get appTitle => 'Easy Todo';

  @override
  String get filterAll => 'All';

  @override
  String get filterTodayTodos => 'Today\'s Todos';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get resetButton => 'Reset';

  @override
  String get applyButton => 'Apply';

  @override
  String get repeatTaskWarning =>
      'This todo item is automatically generated from a repeat task and will be regenerated tomorrow after deletion.';

  @override
  String get learnMore => 'Learn More';

  @override
  String get repeatTaskDialogTitle => 'Repeat Task Todo Item';

  @override
  String get repeatTaskExplanation =>
      'This todo is automatically created from a repeat task template. Deleting it will not affect the repeat task itself - a new todo will be generated tomorrow according to the repeat schedule. If you want to stop these todos from being generated, you need to edit or delete the repeat task template in the repeat tasks management section.';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get authenticateToContinue =>
      'Please authenticate to continue using the app';

  @override
  String get retry => 'Retry';

  @override
  String get biometricReason =>
      'Please use biometric authentication to verify your identity';

  @override
  String get biometricHint => 'Use biometric authentication';

  @override
  String get biometricNotRecognized =>
      'Biometric not recognized, please try again';

  @override
  String get biometricSuccess => 'Biometric authentication successful';

  @override
  String get biometricVerificationTitle => 'Biometric Verification';

  @override
  String addTodoError(Object error) {
    return 'Failed to add todo: $error';
  }

  @override
  String get titleRequired => 'Please enter a title';

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
    return 'Failed to create repeat task: $error';
  }

  @override
  String get repeatTaskTitleRequired => 'Please enter a title';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get shareBackup => 'Share Backup';

  @override
  String get cannotAccessFile => 'Cannot access selected file';

  @override
  String get invalidBackupFormat => 'Invalid backup format';

  @override
  String get importBackupTitle => 'Import Backup';

  @override
  String get import => 'Import';

  @override
  String get backupShareSuccess => 'Backup file shared successfully';

  @override
  String get requiredUpdateAvailable =>
      'A required update is available. Please update to continue using the app.';

  @override
  String updateCheckError(Object error) {
    return 'Error checking for updates: $error';
  }

  @override
  String importingBackupFile(Object fileName) {
    return 'About to import backup file \"$fileName\", this will overwrite all current data. Continue?';
  }

  @override
  String hardcodedStringFound(Object fileName) {
    return '即将导入备份文件 \"$fileName\"，这将覆盖当前的所有数据。确定继续吗？';
  }

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get testNotificationChannel => 'Test notification channel';

  @override
  String get testNotificationContent =>
      'This is a test notification to verify that notifications are working properly.';

  @override
  String get failedToSendTestNotification =>
      'Failed to send test notification: ';

  @override
  String get failedToCheckForUpdates => 'Failed to check for updates';

  @override
  String get errorCheckingForUpdates => 'Error checking for updates: ';

  @override
  String get updateFileName => 'easy_todo_update.apk';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get restoreSuccessPrefix => 'Restored ';

  @override
  String get restoreSuccessSuffix => ' todos';

  @override
  String get importSuccessPrefix =>
      'Backup file imported successfully, restored ';

  @override
  String get importFailedPrefix => 'Import failed: ';

  @override
  String get cleanupFailedPrefix => 'Cleanup failed: ';

  @override
  String get developerName => '梦凌汐 (MeowLynxSea)';

  @override
  String get createYourFirstRepeatTask =>
      'Create your first repeat task to get started';

  @override
  String get rate => 'Rate';

  @override
  String get openSource => 'Open Source';

  @override
  String get repeatTodoTest => 'Repeat Todo Test';

  @override
  String get repeatTodos => 'Repeat Todos';

  @override
  String get addRepeatTodo => 'Add Repeat Todo';

  @override
  String get checkRepeatTodos => 'Check Repeat Todos';

  @override
  String get authenticateToAccessApp => 'Please authenticate to access the app';

  @override
  String get backupFileSubject => 'Easy Todo Backup File';

  @override
  String get shareFailedPrefix => 'Share failed: ';

  @override
  String get schedulingTodoReminder => 'Scheduling todo reminder \"';

  @override
  String get todoReminderTimerScheduled =>
      'Todo reminder timer scheduled successfully';

  @override
  String get allRemindersRescheduled =>
      'All reminders rescheduled successfully';

  @override
  String get allTimersCleared => 'All timers cleared';

  @override
  String get allNotificationChannelsCreated =>
      'All notification channels created successfully';

  @override
  String get utc => 'UTC';

  @override
  String get gmt => 'GMT';

  @override
  String get authenticateToEnableFingerprint =>
      'Please authenticate to enable app lock';

  @override
  String get authenticateToDisableFingerprint =>
      'Please authenticate to disable app lock';

  @override
  String get authenticateToAccessWithFingerprint =>
      'Please authenticate to access the app';

  @override
  String get authenticateToAccessWithBiometric =>
      'Please use biometric verification to verify your identity to continue';

  @override
  String get authenticateToClearData =>
      'Please use biometric authentication to clear all data';

  @override
  String get clearDataFailedPrefix => 'Clear data failed: ';

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
  String get deleteAction => 'delete';

  @override
  String get toggleReminderAction => 'toggle_reminder';

  @override
  String get pomodoroAction => 'pomodoro';

  @override
  String get completedKey => 'completed';

  @override
  String get totalKey => 'total';

  @override
  String get zh => 'zh';

  @override
  String get en => 'en';

  @override
  String everyNDays(Object count) {
    return 'Every $count days';
  }

  @override
  String get dataStatistics => 'Data Statistics';

  @override
  String get dataStatisticsDescription =>
      'Number of repeat tasks with data statistics enabled';

  @override
  String get statisticsModes => 'Statistics Modes';

  @override
  String get statisticsModesDescription =>
      'Select the statistical analysis methods to apply';

  @override
  String get dataUnit => 'Data Unit';

  @override
  String get dataUnitHint => 'e.g., kg, km, \$, %';

  @override
  String get statisticsModeAverage => 'Average';

  @override
  String get statisticsModeGrowth => 'Growth';

  @override
  String get statisticsModeExtremum => 'Extremum';

  @override
  String get statisticsModeTrend => 'Trend';

  @override
  String get enterDataToComplete => 'Enter Data to Complete';

  @override
  String get enterDataDescription =>
      'This repeat task requires data input before completion';

  @override
  String get dataValue => 'Data Value';

  @override
  String get dataValueHint => 'Enter a numerical value';

  @override
  String get dataValueRequired =>
      'Please enter a data value to complete this task';

  @override
  String get invalidDataValue => 'Please enter a valid number';

  @override
  String get dataStatisticsTab => 'Data Statistics';

  @override
  String get selectRepeatTask => 'Select Repeat Task';

  @override
  String get selectRepeatTaskHint =>
      'Choose a repeat task to view its statistics';

  @override
  String get timePeriod => 'Time Period';

  @override
  String get timePeriodToday => 'Today';

  @override
  String get timePeriodThisWeek => 'This Week';

  @override
  String get timePeriodThisMonth => 'This Month';

  @override
  String get timePeriodOverview => 'Overview';

  @override
  String get timePeriodCustom => 'Custom Range';

  @override
  String get selectCustomRange => 'Select Date Range';

  @override
  String get noRepeatTasksWithStats =>
      'No repeat tasks with statistics enabled';

  @override
  String get noDataAvailable => 'No data available for the selected period';

  @override
  String get dataProgressToday => 'Today\'s Progress';

  @override
  String get averageValue => 'Average Value';

  @override
  String get totalValue => 'Total Value';

  @override
  String get dataPoints => 'Data Points';

  @override
  String get growthRate => 'Growth Rate';

  @override
  String get trendAnalysis => 'Trend Analysis';

  @override
  String get maximumValue => 'Maximum';

  @override
  String get minimumValue => 'Minimum';

  @override
  String get extremumAnalysis => 'Extremum Analysis';

  @override
  String get statisticsSummary => 'Statistics Summary';

  @override
  String get dataVisualization => 'Data Visualization';

  @override
  String get chartTitle => 'Data Trends';

  @override
  String get lineChart => 'Line Chart';

  @override
  String get barChart => 'Bar Chart';

  @override
  String get showValueOnDrag => 'Show value when dragging on chart';

  @override
  String get dragToShowValue => 'Drag on chart to see detailed values';

  @override
  String get analytics => 'Analytics';

  @override
  String get dataEntry => 'Data Entry';

  @override
  String get statisticsEnabled => 'Statistics Enabled';

  @override
  String get dataCollection => 'Data Collection';

  @override
  String repeatTodoWithStats(Object count) {
    return 'Repeat tasks with statistics: $count';
  }

  @override
  String dataEntries(Object count) {
    return 'Data entries: $count';
  }

  @override
  String withDataValues(Object count) {
    return 'with values: $count';
  }

  @override
  String totalDataSize(Object size) {
    return 'Total data size: $size';
  }

  @override
  String get dataBackupSupported => 'Data backup and restore supported';

  @override
  String get repeatTasks => 'Repeat Tasks';

  @override
  String get dataStatisticsEnabled => 'Data Statistics Enabled';

  @override
  String get statisticsData => 'Statistics Data';

  @override
  String get dataStatisticsEnabledShort => 'Data Stats';

  @override
  String get dataWithValue => 'With Values';

  @override
  String get noDataStatisticsEnabled => 'No data statistics enabled';

  @override
  String get enableDataStatisticsHint =>
      'Enable data statistics for repeat tasks to see analytics';

  @override
  String get selectTimePeriod => 'Select Time Period';

  @override
  String get customRange => 'Custom Range';

  @override
  String get selectRepeatTaskToViewData =>
      'Select a repeat task to view its data statistics';

  @override
  String get noStatisticsData => 'No statistics data available';

  @override
  String get completeSomeTodosToSeeData =>
      'Complete some todos with data to see statistics';

  @override
  String get totalEntries => 'Total Entries';

  @override
  String get average => 'Average';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get totalGrowth => 'Total Growth';

  @override
  String get notEnoughDataForCharts => 'Not enough data for charts';

  @override
  String get averageTrend => 'Average Trend';

  @override
  String get averageChartDescription =>
      'Shows the average values over time with trend analysis';

  @override
  String get trendDirection => 'Trend Direction';

  @override
  String get trendStrength => 'Trend Strength';

  @override
  String get growthAnalysis => 'Growth Analysis';

  @override
  String get range => 'Range';

  @override
  String get stableTrendDescription => 'Stable trend with minimal variation';

  @override
  String get weakTrendDescription => 'Weak trend with some variation';

  @override
  String get moderateTrendDescription => 'Moderate trend with clear direction';

  @override
  String get strongTrendDescription =>
      'Strong trend with significant variation';

  @override
  String get invalidNumberFormat => 'Invalid number format';

  @override
  String get dataUnitRequired =>
      'Data unit is required when data statistics is enabled';

  @override
  String get growth => 'Growth';

  @override
  String get extremum => 'Extremum';

  @override
  String get trend => 'Trend';

  @override
  String get dataInputRequired =>
      'Data input is required to complete this task';

  @override
  String get todayProgress => 'Today\'s Progress';

  @override
  String get dataProgress => 'Data Progress';

  @override
  String get noDataForToday => 'No data for today';

  @override
  String get weeklyDataStats => 'Weekly Data Statistics';

  @override
  String get noDataForThisWeek => 'No data for this week';

  @override
  String get daysTracked => 'Days tracked';

  @override
  String get monthlyDataStats => 'Monthly Data Statistics';

  @override
  String get noDataForThisMonth => 'No data for this month';

  @override
  String get customDateRange => 'Custom Date Range';

  @override
  String get allData => 'All Data';

  @override
  String get breakdownByTask => 'Breakdown by Task';

  @override
  String get clear => 'Clear';

  @override
  String get trendUp => 'Upward Trend';

  @override
  String get trendDown => 'Downward Trend';

  @override
  String get trendStable => 'Stable Trend';

  @override
  String get needMoreDataToAnalyze => 'Need to collect more data to analyze';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskWithdrawn => 'Task withdrawn';

  @override
  String get noDefaultSettings =>
      'No default settings found, creating defaults';

  @override
  String get authenticateForSensitiveOperation =>
      'Please use biometric authentication to verify your identity';

  @override
  String get insufficientData => 'Insufficient data';

  @override
  String get stable => 'Stable';

  @override
  String get strongUpward => 'Strong upward';

  @override
  String get upward => 'Upward';

  @override
  String get strongDownward => 'Strong downward';

  @override
  String get downward => 'Downward';

  @override
  String get repeatTasksRefreshedSuccessfully =>
      'Repeat tasks refreshed successfully';

  @override
  String get errorRefreshingRepeatTasks => 'Error refreshing repeat tasks';

  @override
  String get forceRefresh => 'Force refresh';

  @override
  String get errorLoadingRepeatTasks => 'Error loading repeat tasks';

  @override
  String get pleaseCheckStoragePermissions =>
      'Please check your storage permissions and try again';

  @override
  String get todoReminders => 'Todo Reminders';

  @override
  String get notificationsForIndividualTodoReminders =>
      'Notifications for individual todo reminders';

  @override
  String get notificationsForDailySummary => 'Daily summary of pending todos';

  @override
  String get pomodoroComplete => 'Pomodoro Complete';

  @override
  String get notificationsForPomodoroSessions =>
      'Notifications when pomodoro sessions are completed';

  @override
  String get dailyTodoSummary => 'Daily Todo Summary';

  @override
  String youHavePendingTodos(Object count, Object n, Object s) {
    return 'You have $count pending todo$s to complete';
  }

  @override
  String greatJobTimeForBreak(Object breakType) {
    return 'Great job! Time for a $breakType break';
  }

  @override
  String get shortBreak => 'short';

  @override
  String get longBreak => 'long';

  @override
  String get themeColorMysteriousPurple => 'Mysterious Purple';

  @override
  String get themeColorSkyBlue => 'Sky Blue';

  @override
  String get themeColorGemGreen => 'Gem Green';

  @override
  String get themeColorLemonYellow => 'Lemon Yellow';

  @override
  String get themeColorFlameRed => 'Flame Red';

  @override
  String get themeColorElegantPurple => 'Elegant Purple';

  @override
  String get themeColorCherryPink => 'Cherry Pink';

  @override
  String get themeColorForestCyan => 'Forest Cyan';

  @override
  String get aiSettings => 'AI Settings';

  @override
  String get aiFeatures => 'AI Features';

  @override
  String get aiEnabled => 'AI features enabled';

  @override
  String get aiDisabled => 'AI features disabled';

  @override
  String get enableAIFeatures => 'Enable AI Features';

  @override
  String get enableAIFeaturesSubtitle =>
      'Use artificial intelligence to enhance your todo experience';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get apiEndpoint => 'API Endpoint';

  @override
  String get pleaseEnterApiEndpoint => 'Please enter API endpoint';

  @override
  String get invalidApiEndpoint => 'Please enter a valid API endpoint';

  @override
  String get apiKey => 'API Key';

  @override
  String get pleaseEnterApiKey => 'Please enter API key';

  @override
  String get modelName => 'Model Name';

  @override
  String get pleaseEnterModelName => 'Please enter model name';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get timeout => 'Timeout (ms)';

  @override
  String get pleaseEnterTimeout => 'Please enter timeout';

  @override
  String get invalidTimeout => 'Please enter a valid timeout (minimum 1000ms)';

  @override
  String get temperature => 'Temperature';

  @override
  String get pleaseEnterTemperature => 'Please enter temperature';

  @override
  String get invalidTemperature =>
      'Please enter a valid temperature (0.0 - 2.0)';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get pleaseEnterMaxTokens => 'Please enter max tokens';

  @override
  String get invalidMaxTokens => 'Please enter valid max tokens (minimum 1)';

  @override
  String get rateLimit => 'Rate Limit';

  @override
  String get rateLimitSubtitle => 'Maximum requests per minute';

  @override
  String get pleaseEnterRateLimit => 'Please enter rate limit';

  @override
  String get invalidRateLimit => 'Rate limit must be between 1 and 100';

  @override
  String get rateAndTokenLimits => 'Rate & Token Limits';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get connectionSuccessful => 'Connection successful!';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get aiFeaturesToggle => 'AI Features Toggle';

  @override
  String get autoCategorization => 'Auto Categorization';

  @override
  String get autoCategorizationSubtitle =>
      'Automatically categorize your tasks';

  @override
  String get prioritySorting => 'Priority Sorting';

  @override
  String get importanceRating => 'Importance Rating';

  @override
  String get importanceRatingSubtitle =>
      'Assess task importance separately from priority';

  @override
  String get prioritySortingSubtitle => 'Assess task priority (urgency)';

  @override
  String get motivationalMessages => 'Motivational Messages';

  @override
  String get motivationalMessagesSubtitle =>
      'Generate encouraging messages based on your progress';

  @override
  String get smartNotifications => 'Smart Notifications';

  @override
  String get smartNotificationsSubtitle =>
      'Create personalized notification content';

  @override
  String get completionMotivation => 'Completion Motivation';

  @override
  String get completionMotivationSubtitle =>
      'Show motivation based on daily completion rate';

  @override
  String get aiCategoryWork => 'Work';

  @override
  String get aiCategoryPersonal => 'Personal';

  @override
  String get aiCategoryStudy => 'Study';

  @override
  String get aiCategoryHealth => 'Health';

  @override
  String get aiCategoryFitness => 'Fitness';

  @override
  String get aiCategoryFinance => 'Finance';

  @override
  String get aiCategoryShopping => 'Shopping';

  @override
  String get aiCategoryFamily => 'Family';

  @override
  String get aiCategorySocial => 'Social';

  @override
  String get aiCategoryHobby => 'Hobby';

  @override
  String get aiCategoryTravel => 'Travel';

  @override
  String get aiCategoryOther => 'Other';

  @override
  String get aiPriorityHigh => 'High Priority';

  @override
  String get aiPriorityMedium => 'Medium Priority';

  @override
  String get aiPriorityLow => 'Low Priority';

  @override
  String get aiPriorityUrgent => 'Urgent';

  @override
  String get aiPriorityImportant => 'Important';

  @override
  String get aiPriorityNormal => 'Normal';

  @override
  String get selectTodoForPomodoro => 'Select a Todo';

  @override
  String get pomodoroDescription =>
      'Choose a todo item to start your Pomodoro focus session';

  @override
  String get noTodosForPomodoro => 'No available todos';

  @override
  String get createTodoForPomodoro => 'Please create some todos first';

  @override
  String get todaySessions => 'Today\'s Sessions';

  @override
  String get startPomodoro => 'Start Pomodoro';

  @override
  String get aiDebugInfo => 'AI Debug Info';

  @override
  String get processingUnprocessedTodos =>
      'Processing unprocessed todos with AI';

  @override
  String get processAllTodosWithAI => 'Process All Todos with AI';

  @override
  String todayTimeFormat(Object time) {
    return 'Today $time';
  }

  @override
  String tomorrowTimeFormat(Object time) {
    return 'Tomorrow $time';
  }

  @override
  String get deleteTodoDialogTitle => 'Delete';

  @override
  String get deleteTodoDialogMessage =>
      'Are you sure you want to delete this todo?';

  @override
  String get deleteTodoDialogCancel => 'Cancel';

  @override
  String get deleteTodoDialogDelete => 'Delete';

  @override
  String get customPersona => 'Custom Persona';

  @override
  String get personaPrompt => 'Persona Prompt';

  @override
  String get personaPromptHint =>
      'e.g., You are a friendly assistant who uses humor and emojis...';

  @override
  String get personaPromptDescription =>
      'Customize the AI\'s personality for notifications. This will be applied to both todo reminders and daily summaries.';

  @override
  String get personaExample1 =>
      'You are a motivating coach who encourages with positive reinforcement';

  @override
  String get personaExample2 =>
      'You are a humorous assistant who uses light humor and emojis';

  @override
  String get personaExample3 =>
      'You are a professional productivity expert who gives concise advice';

  @override
  String get personaExample4 =>
      'You are a supportive friend who reminds with warmth and care';

  @override
  String get aiDebugInfoTitle => 'AI Debug Info';

  @override
  String get aiDebugInfoSubtitle => 'Check AI functionality status';

  @override
  String get aiSettingsStatus => 'AI Settings Status';

  @override
  String get aiFeatureToggles => 'AI Feature Toggles';

  @override
  String get aiTodoProviderConnection => 'Todo Provider Connection';

  @override
  String get aiMessages => 'AI Messages';

  @override
  String get aiApiRequestManager => 'API Request Manager';

  @override
  String get aiCurrentRequestQueue => 'Current Request Queue';

  @override
  String get aiRecentRequests => 'Recent Requests';

  @override
  String get aiPermissionRequestMessage =>
      'Please enable \"Alarms & Reminders\" permission for \"Easy Todo\" in system settings.';

  @override
  String get developerNameMeowLynxSea => '梦凌汐 (MeowLynxSea)';

  @override
  String get developerEmail => 'mew@meowdream.cn';

  @override
  String get developerGithub => 'github.com/MeowLynxSea';

  @override
  String get developerWebsite => 'www.meowdream.cn';

  @override
  String get backupFileShareSubject => 'Easy Todo Backup File';

  @override
  String shareFailed(Object error) {
    return 'Share failed: $error';
  }

  @override
  String get authenticateToAccessAppMessage =>
      'Please authenticate to access the app';

  @override
  String get aiFeaturesEnabled => 'AI Features Enabled';

  @override
  String get aiServiceValid => 'AI Service Valid';

  @override
  String get notConfigured => 'Not configured';

  @override
  String configured(Object count) {
    return 'Configured ($count chars)';
  }

  @override
  String get aiProviderConnected => 'AI Provider Connected';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get aiProcessedTodos => 'AI Processed Todos';

  @override
  String get todosWithAICategory => 'Todos with AI Category';

  @override
  String get todosWithAIPriority => 'Todos with AI Priority';

  @override
  String get lastError => 'Last Error';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get currentWindowRequests => 'Current Window Requests';

  @override
  String get maxRequestsPerMinute => 'Max Requests/Minute';

  @override
  String get status => 'Status';

  @override
  String get aiServiceNotAvailable => 'AI Service not available';

  @override
  String get completionMessages => 'Completion Messages';

  @override
  String get exactAlarmPermission => 'Exact Alarm Permission';

  @override
  String get exactAlarmPermissionContent =>
      'To ensure pomodoro and reminder functions work accurately, the app needs exact alarm permission.\n\nPlease enable \"Alarms & Reminders\" permission for \"Easy Todo\" in system settings.';

  @override
  String get setLater => 'Set Later';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get batteryOptimizationSettings => 'Battery Optimization Settings';

  @override
  String get batteryOptimizationContent =>
      'To ensure pomodoro and reminder functions run properly in the background, please disable battery optimization for this app.\n\nThis may increase some battery consumption, but ensures timers and reminder functions work accurately.';

  @override
  String get breakTimeComplete => 'Break Time Complete!';

  @override
  String get timeToGetBackToWork => 'Time to get back to work!';

  @override
  String get aiServiceReturnedEmptyMessage =>
      'AI service returned empty message';

  @override
  String errorGeneratingMotivationalMessage(Object error) {
    return 'Error generating motivational message: $error';
  }

  @override
  String get aiServiceNotAvailableCheckSettings =>
      'AI service not available, please check AI settings';

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get importance => 'Importance';

  @override
  String get importanceQuadrant => 'Quadrants';

  @override
  String get important => 'Important';

  @override
  String get notImportant => 'Not important';

  @override
  String get urgent => 'Urgent';

  @override
  String get notUrgent => 'Not urgent';

  @override
  String get noCategoriesAvailable => 'No categories available';

  @override
  String get aiWillCategorizeTasks =>
      'AI will automatically categorize tasks, please try again later';

  @override
  String get selectCategories => 'Select Categories';

  @override
  String get selectedCategories => 'Selected';

  @override
  String get categories => 'categories';

  @override
  String get apiFormat => 'API Format';

  @override
  String get apiFormatDescription =>
      'Choose your AI service provider. Different providers may require different API endpoints and authentication methods.';

  @override
  String get openaiFormat => 'OpenAI';

  @override
  String get anthropicFormat => 'Anthropic';

  @override
  String aiPromptCategorization(Object description, Object title) {
    return 'Categorize this todo task into one of these categories:\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n\n      Task: \"$title\"\n      Description: \"$description\"\n\n      Respond with only the category name in lowercase.';
  }

  @override
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  ) {
    return 'Rate the priority of this todo task from 0-100, considering:\n      - Urgency: How soon is it needed? (deadline: $deadline)\n      - Impact: What are the consequences of not completing it?\n      - Effort: How much time/resources will it require?\n      - Personal importance: How valuable is this to you?\n\n      Task: \"$title\"\n      Description: \"$description\"\n      Has deadline: $hasDeadline\n      Deadline: $deadline\n\n      Guidelines:\n      - 0-20: Low priority, can be postponed\n      - 21-40: Moderate priority, should be done soon\n      - 41-70: High priority, important to complete\n      - 71-100: Critical priority, urgent completion needed\n\n      Respond with only a number from 0-100.';
  }

  @override
  String aiPromptImportance(Object description, Object title) {
    return 'Rate the importance of this todo task from 0-100, focusing on long-term value and impact.\n\n      Consider:\n      - Impact: How much does this matter if completed?\n      - Long-term value: Will it benefit you later?\n      - Alignment: Does it support your goals/values?\n      - Consequences: What is lost if it is never done?\n\n      Task: \"$title\"\n      Description: \"$description\"\n\n      Guidelines:\n      - 0-20: Low importance\n      - 21-40: Some importance\n      - 41-70: Important\n      - 71-100: Extremely important\n\n      Respond with only a number from 0-100.';
  }

  @override
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  ) {
    return 'Generate a motivational message based on this statistics data:\n      Name: \"$name\"\n      Description: \"$description\"\n      Value: $value\n      Unit: \"$unit\"\n      Date: $date\n\n      Requirements:\n      - Make it encouraging and data-specific\n      - Keep it under 25 characters\n      - Focus on achievement and progress\n      - Use positive, action-oriented language\n      - Example: \"Great progress today! 🎯\" or \"Keep it up! 💪\"\n      - Respond with only the message, no explanations';
  }

  @override
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  ) {
    return 'Create a personalized notification reminder for this task:\n      Task: \"$title\"\n      Description: \"$description\"\n      Category: $category\n      Priority: $priority\n\n      Requirements:\n      - Create both a title and message\n      - Title: Must be under 20 characters, attention-grabbing\n      - Message: Must be under 50 characters, motivating and actionable\n      - Use emojis where appropriate for engagement\n      - Include urgency based on priority level\n      - Make it personal and encouraging\n      - Respond ONLY in this exact format:\nTITLE: [your title]\nMESSAGE: [your message]\n      - No explanations, no markdown formatting, just the two lines in the specified format';
  }

  @override
  String aiPromptCompletion(Object completed, Object percentage, Object total) {
    return 'Generate an encouraging message based on today\'s todo completion:\n      Completed: $completed out of $total tasks\n      Completion rate: $percentage%\n\n      Requirements:\n      - Make it positive and motivating\n      - Keep it under 25 characters\n      - Celebrate achievement and progress\n      - Use encouraging language and/or emojis\n      - Example: \"Awesome work! 🌟\" or \"Progress! 👍\"\n      - Respond with only the message, no explanations';
  }

  @override
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  ) {
    return 'Create a daily summary notification for pending todos.\n\nPending tasks count: $pendingCount\nCategories: $categories\nAverage priority: $avgPriority/100\n\nCreate a personalized summary with:\n1. A catchy title (first line)\n2. An encouraging message that MUST include the count of unfinished todos ($pendingCount)\n3. Keep the message content under 50 characters. Make it motivating and actionable.\n4. Respond ONLY in this exact format:\nTITLE: [your title]\nMESSAGE: [your message]\n5. No explanations, no markdown formatting, just the two lines in the specified format';
  }

  @override
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  ) {
    return 'Create a personalized notification for a completed $sessionType session.\n\nSession details:\n- Task: \"$taskTitle\"\n- Session type: $sessionType\n- Duration: $duration minutes\n- Completed: $isCompleted\n\nIMPORTANT: Respond in the same language as this prompt (English).\n\nCreate both a title and message:\n1. Title: Must be under 20 characters, attention-grabbing and celebratory\n2. Message: Must be under 50 characters, encouraging and relevant to the session completion\n3. For focus sessions (work completed): Emphasize work accomplishment and that it\'s time for a well-deserved break\n4. For break sessions (rest completed): Focus on rest completion and that it\'s time to get back to focused work\n5. Use emojis where appropriate for engagement\n6. Make it personal and motivating\n7. Respond with only the title and message in the specified format, no explanations\n\nFormat your response as:\nTITLE: [title]\nMESSAGE: [message]';
  }

  @override
  String get cloudSyncAuthProcessingTitle => 'Signing in';

  @override
  String get cloudSyncAuthProcessingSubtitle => 'Processing login callback…';

  @override
  String get cloudSyncChangePassphraseTitle => 'Change passphrase';

  @override
  String get cloudSyncChangePassphraseSubtitle =>
      'Re-wrap the DEK only (no re-upload of history)';

  @override
  String get cloudSyncChangePassphraseAction => 'Change';

  @override
  String get cloudSyncChangePassphraseDialogTitle => 'Change sync passphrase';

  @override
  String get cloudSyncChangePassphraseDialogHint =>
      'This only updates the key bundle. Other devices may need to enter the new passphrase to unlock.';

  @override
  String get cloudSyncCurrentPassphrase => 'Current passphrase';

  @override
  String get cloudSyncNewPassphrase => 'New passphrase';

  @override
  String get cloudSyncPassphraseChangedSnack => 'Passphrase updated';

  @override
  String get syncAiApiKeyTitle => 'Sync API key (encrypted)';

  @override
  String get syncAiApiKeySubtitle =>
      'Share your API key across devices via end-to-end encryption (optional)';

  @override
  String get syncAiApiKeyWarningTitle => 'Sync API key?';

  @override
  String get syncAiApiKeyWarningMessage =>
      'Your API key will be uploaded as ciphertext and can be decrypted by devices with your sync passphrase. Enable only if you understand the risk.';

  @override
  String get cloudSyncAutoSyncIntervalTitle => 'Auto sync interval';

  @override
  String get cloudSyncAutoSyncIntervalHint =>
      'Polling is device-specific. If there are pending local changes, they may sync sooner via the outbox trigger.';

  @override
  String get cloudSyncAutoSyncIntervalSecondsLabel => 'Seconds';

  @override
  String get cloudSyncAutoSyncIntervalMinHint => 'Minimum 30 seconds';

  @override
  String get cloudSyncAutoSyncIntervalSavedSnack => 'Auto sync interval saved';

  @override
  String cloudSyncAutoSyncIntervalSubtitle(Object interval) {
    return 'Current: $interval';
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
  String get todoAttachmentPreviewUnsupported =>
      'Preview is not available for this file type';

  @override
  String todoAttachmentPreviewTooLarge(Object maxSize) {
    return 'File is too large to preview (max: $maxSize)';
  }

  @override
  String get todoAttachmentMarkdownRendered => 'Rendered';

  @override
  String get todoAttachmentMarkdownSource => 'Source';

  @override
  String get todoAttachmentWebNotSupported =>
      'Attachments are not supported on web';
}

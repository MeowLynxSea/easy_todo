// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
      'La configuración de idioma le permite cambiar el idioma de visualización de la aplicación. Seleccione su idioma preferido de la lista anterior.';

  @override
  String get dataStorage => 'Data & Storage';

  @override
  String get dataAndSync => 'Datos y sincronización';

  @override
  String get cloudSync => 'Sincronización en la nube';

  @override
  String get cloudSyncSubtitle => 'Cifrado de extremo a extremo (manual)';

  @override
  String get cloudSyncOverviewTitle => 'Sync manual E2EE';

  @override
  String get cloudSyncOverviewSubtitle =>
      'El servidor almacena solo cifrado; desbloquee con su frase de acceso en este dispositivo.';

  @override
  String get cloudSyncConfigSaved => 'Configuración de sync guardada';

  @override
  String get cloudSyncServerOkSnack => 'Servidor accesible';

  @override
  String get cloudSyncServerCheckFailedSnack =>
      'Falló la verificación del servidor';

  @override
  String get cloudSyncDisabledSnack => 'Sync deshabilitado';

  @override
  String get cloudSyncEnableSwitchTitle => 'Habilitar sync en la nube';

  @override
  String get cloudSyncEnableSwitchSubtitle =>
      'Configuración guiada: servidor + frase de acceso';

  @override
  String get cloudSyncServerSection => 'Servidor';

  @override
  String get cloudSyncSetupTitle => '1) Configurar servidor';

  @override
  String get cloudSyncSetupSubtitle =>
      'Defina la URL del servidor, elija un proveedor e inicie sesión.';

  @override
  String get cloudSyncSetupDialogTitle => 'Configuración del servidor';

  @override
  String get cloudSyncServerUrl => 'URL del servidor';

  @override
  String get cloudSyncServerUrlHint => 'http://127.0.0.1:8787';

  @override
  String get cloudSyncAuthProvider => 'Proveedor OAuth';

  @override
  String get cloudSyncAuthProviderHint => 'linuxdo';

  @override
  String get cloudSyncAuthMode => 'Autenticación';

  @override
  String get cloudSyncAuthModeLoggedIn => 'Con sesión';

  @override
  String get cloudSyncAuthModeLoggedOut => 'Sin sesión';

  @override
  String get cloudSyncCheckServer => 'Verificar servidor';

  @override
  String get cloudSyncEditServerConfig => 'Editar';

  @override
  String get cloudSyncLogin => 'Iniciar sesión';

  @override
  String get cloudSyncLogout => 'Cerrar sesión';

  @override
  String get cloudSyncLoggedInSnack => 'Sesión iniciada';

  @override
  String get cloudSyncLoggedOutSnack => 'Sesión cerrada';

  @override
  String get cloudSyncLoginRedirectedSnack =>
      'Continúe el inicio de sesión en el navegador';

  @override
  String get cloudSyncLoginFailedSnack => 'Falló el inicio de sesión';

  @override
  String get cloudSyncNotSet => 'No configurado';

  @override
  String get cloudSyncTokenSet => 'Token configurado';

  @override
  String get cloudSyncStatusSection => 'Estado';

  @override
  String get cloudSyncEnabled => 'Habilitado';

  @override
  String get cloudSyncUnlocked => 'Desbloqueado';

  @override
  String get cloudSyncEnabledOn => 'Habilitado: Sí';

  @override
  String get cloudSyncEnabledOff => 'Habilitado: No';

  @override
  String get cloudSyncUnlockedYes => 'Desbloqueado: Sí';

  @override
  String get cloudSyncUnlockedNo => 'Desbloqueado: No';

  @override
  String get cloudSyncConfiguredYes => 'Configurado: Sí';

  @override
  String get cloudSyncConfiguredNo => 'Configurado: No';

  @override
  String get cloudSyncLastServerSeq => 'Último serverSeq';

  @override
  String get cloudSyncDekId => 'ID de DEK';

  @override
  String get cloudSyncLastSyncAt => 'Última sincronización';

  @override
  String get cloudSyncError => 'Error';

  @override
  String get cloudSyncDeviceId => 'ID del dispositivo';

  @override
  String get cloudSyncEnable => 'Habilitar';

  @override
  String get cloudSyncUnlock => 'Desbloquear';

  @override
  String get cloudSyncSyncNow => 'Sincronizar ahora';

  @override
  String get cloudSyncDisable => 'Deshabilitar';

  @override
  String get cloudSyncSecurityTitle => '2) Desbloquear';

  @override
  String get cloudSyncSecuritySubtitle =>
      'Desbloquear usa su frase de acceso para obtener el DEK. Móvil/escritorio pueden guardarlo de forma segura.';

  @override
  String get cloudSyncLockStateTitle => 'Clave de cifrado';

  @override
  String get cloudSyncLockStateUnlocked => 'Desbloqueado en este dispositivo';

  @override
  String get cloudSyncLockStateLocked =>
      'Bloqueado — ingrese la frase de acceso';

  @override
  String get cloudSyncActionsTitle => '3) Sincronizar';

  @override
  String get cloudSyncActionsSubtitle =>
      'Enviar cambios locales y luego recibir actualizaciones.';

  @override
  String get cloudSyncAdvancedTitle => 'Avanzado';

  @override
  String get cloudSyncAdvancedSubtitle => 'Información de depuración (local)';

  @override
  String get cloudSyncEnableDialogTitle => 'Habilitar sincronización';

  @override
  String get cloudSyncUnlockDialogTitle => 'Desbloquear sincronización';

  @override
  String get cloudSyncPassphraseDialogHint =>
      'Si ya habilitó la sincronización en otro dispositivo, ingrese la misma frase de acceso dos veces.';

  @override
  String get cloudSyncPassphrase => 'Frase de acceso';

  @override
  String get cloudSyncConfirmPassphrase => 'Confirmar frase de acceso';

  @override
  String get cloudSyncShowPassphrase => 'Mostrar';

  @override
  String get cloudSyncEnabledSnack => 'Sincronización habilitada';

  @override
  String get cloudSyncUnlockedSnack => 'Desbloqueado';

  @override
  String get cloudSyncSyncedSnack => 'Sincronizado';

  @override
  String get cloudSyncInvalidPassphrase => 'Frase de acceso inválida';

  @override
  String get cloudSyncRollbackTitle => 'Posible rollback del servidor';

  @override
  String get cloudSyncRollbackMessage =>
      'El servidor puede haber vuelto atrás o restaurado desde una copia de seguridad. Continuar puede causar pérdida de datos. ¿Qué desea hacer?';

  @override
  String get cloudSyncStopSync => 'Detener sync';

  @override
  String get cloudSyncContinue => 'Continuar';

  @override
  String get cloudSyncWebDekNote =>
      'Web usa caché de DEK solo por sesión. Al recargar se requiere desbloquear de nuevo.';

  @override
  String get cloudSyncStatusIdle => 'inactivo';

  @override
  String get cloudSyncStatusRunning => 'en curso';

  @override
  String get cloudSyncStatusError => 'error';

  @override
  String get cloudSyncErrorPassphraseMismatch => 'Las frases no coinciden';

  @override
  String get cloudSyncErrorNotConfigured => 'Sync no configurado';

  @override
  String get cloudSyncErrorDisabled => 'Sync está deshabilitado';

  @override
  String get cloudSyncErrorLocked => 'Sync está bloqueado (falta DEK)';

  @override
  String get cloudSyncErrorUnauthorized => 'No autorizado (verifique el token)';

  @override
  String get cloudSyncErrorKeyBundleNotFound =>
      'Key bundle no encontrado en el servidor';

  @override
  String get cloudSyncErrorNetwork => 'Error de red';

  @override
  String get cloudSyncErrorConflict => 'Conflicto (versiones no coinciden)';

  @override
  String get cloudSyncErrorQuotaExceeded =>
      'Cuota del servidor excedida (algunos registros fueron rechazados)';

  @override
  String get cloudSyncErrorUnknown => 'Error desconocido';

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
  String get processingCategory => 'Procesando categoría...';

  @override
  String get processingPriority => 'Procesando prioridad...';

  @override
  String get processingAI => 'Procesando IA...';

  @override
  String get aiProcessingCompleted => 'Procesamiento de IA completado';

  @override
  String get categorizingTask => 'Categorizando tarea...';

  @override
  String get processingAIStatus => 'Procesando IA...';

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
  String get timeRange => 'Rango de tiempo';

  @override
  String get startTime => 'Hora de inicio';

  @override
  String get endTime => 'Hora de fin';

  @override
  String get noStartTimeSet => 'Sin hora de inicio';

  @override
  String get noEndTimeSet => 'Sin hora de fin';

  @override
  String get invalidTimeRange =>
      'La hora de fin debe ser posterior a la hora de inicio';

  @override
  String get repeatEnabled => 'Repeat Enabled';

  @override
  String get repeatDescription => 'Create recurring tasks automatically';

  @override
  String get backfillMode => 'Modo de recuperación';

  @override
  String get backfillModeDescription =>
      'Crea tareas recurrentes perdidas de días anteriores';

  @override
  String get backfillDays => 'Días hacia atrás';

  @override
  String get backfillDaysDescription =>
      'Máximo de días hacia atrás (1-365, sin incluir hoy)';

  @override
  String get backfillAutoComplete =>
      'Completar automáticamente las tareas recuperadas';

  @override
  String get backfillDaysRangeError => 'Los días deben estar entre 1 y 365';

  @override
  String get backfillConflictTitle => 'Conflicto de recuperación';

  @override
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  ) {
    return 'La tarea \"$title\" comienza el $startDate, pero el modo de recuperación retrocedería hasta $backfillStartDate. ¿Cuál debe usarse como la fecha más temprana para generar en esta actualización?';
  }

  @override
  String get useStartDate => 'Usar fecha de inicio';

  @override
  String get useBackfillDays => 'Usar rango de recuperación';

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
  String get schedule => 'Agenda';

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
  String get backupFailed => 'Failed to create backup';

  @override
  String get restoreSuccess => 'Data restored successfully';

  @override
  String restoreFailed(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get webBackupHint =>
      'Web: las copias de seguridad usan descarga/carga.';

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
  String get fingerprintLock => 'Fingerprint Lock';

  @override
  String get fingerprintLockSubtitle => 'Protect app security with fingerprint';

  @override
  String get fingerprintLockEnable => 'Enable fingerprint lock';

  @override
  String get fingerprintLockDisable => 'Disable fingerprint lock';

  @override
  String get fingerprintLockEnabled => 'Fingerprint lock enabled';

  @override
  String get fingerprintLockDisabled => 'Fingerprint lock disabled';

  @override
  String get fingerprintNotAvailable =>
      'Fingerprint authentication not available';

  @override
  String get fingerprintNotEnrolled => 'No fingerprint enrolled';

  @override
  String get fingerprintAuthenticationFailed =>
      'Fingerprint authentication failed';

  @override
  String get fingerprintAuthenticationSuccess =>
      'Fingerprint authentication successful';

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
  String get storageAnalytics => 'Análisis de almacenamiento';

  @override
  String get noPendingRequests => 'No hay solicitudes pendientes';

  @override
  String get request => 'Solicitud';

  @override
  String get unknown => 'Unknown';

  @override
  String get waiting => 'Esperando';

  @override
  String get noRecentRequests => 'No hay solicitudes recientes';

  @override
  String get requestCompleted => 'Solicitud completada';

  @override
  String get noTodosToDisplay => 'No hay tareas para mostrar';

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
  String get cancelReminder => 'Cancel reminder';

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
  String get totalFocusTime => 'Tiempo Total de Enfoque';

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
  String get requiredUpdate => 'Actualización requerida';

  @override
  String versionAvailable(Object version) {
    return '¡La versión $version está disponible!';
  }

  @override
  String get whatsNew => 'Novedades:';

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
      'This update is required to continue using the app';

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
      'Easy Todo is a clean, elegant and powerful todo list application designed to help you organize your daily tasks efficiently. With beautiful UI design, comprehensive statistics tracking, seamless API integration, and support for multiple languages, Easy Todo makes task management simple and enjoyable.';

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
    return 'Error al buscar actualizaciones: $error';
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
  String get errorCheckingForUpdates => 'Error al buscar actualizaciones: ';

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
  String get authenticateToAccessApp =>
      'Please authenticate to continue using the app';

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
      'Please authenticate to enable fingerprint lock';

  @override
  String get authenticateToDisableFingerprint =>
      'Please authenticate to disable fingerprint lock';

  @override
  String get authenticateToAccessWithFingerprint =>
      'Please use fingerprint verification to access the app';

  @override
  String get authenticateToAccessWithBiometric =>
      'Please use biometric verification to verify your identity to continue';

  @override
  String get authenticateToClearData =>
      'Please use biometric verification to clear all data';

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
      'Por favor use autenticación biométrica para verificar su identidad';

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
  String get notificationsForDailySummary =>
      'Resumen diario de tareas pendientes';

  @override
  String get pomodoroComplete => 'Pomodoro completado';

  @override
  String get notificationsForPomodoroSessions =>
      'Notificaciones cuando se completan las sesiones de pomodoro';

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
  String get aiSettings => 'Configuración de IA';

  @override
  String get aiFeatures => 'Características de IA';

  @override
  String get aiEnabled => 'Características de IA habilitadas';

  @override
  String get aiDisabled => 'Características de IA deshabilitadas';

  @override
  String get enableAIFeatures => 'Habilitar Características de IA';

  @override
  String get enableAIFeaturesSubtitle =>
      'Use inteligencia artificial para mejorar su experiencia de tareas';

  @override
  String get apiConfiguration => 'Configuración de API';

  @override
  String get apiEndpoint => 'Punto Final de API';

  @override
  String get pleaseEnterApiEndpoint =>
      'Por favor ingrese el punto final de API';

  @override
  String get invalidApiEndpoint =>
      'Por favor ingrese un punto final de API válido';

  @override
  String get apiKey => 'Clave de API';

  @override
  String get pleaseEnterApiKey => 'Por favor ingrese la clave de API';

  @override
  String get modelName => 'Nombre del Modelo';

  @override
  String get pleaseEnterModelName => 'Por favor ingrese el nombre del modelo';

  @override
  String get advancedSettings => 'Configuración Avanzada';

  @override
  String get timeout => 'Tiempo de Espera (ms)';

  @override
  String get pleaseEnterTimeout => 'Por favor ingrese el tiempo de espera';

  @override
  String get invalidTimeout =>
      'Por favor ingrese un tiempo de espera válido (mínimo 1000ms)';

  @override
  String get temperature => 'Temperatura';

  @override
  String get pleaseEnterTemperature => 'Por favor ingrese la temperatura';

  @override
  String get invalidTemperature =>
      'Por favor ingrese una temperatura válida (0.0 - 2.0)';

  @override
  String get maxTokens => 'Tokens Máximos';

  @override
  String get pleaseEnterMaxTokens => 'Por favor ingrese los tokens máximos';

  @override
  String get invalidMaxTokens =>
      'Por favor ingrese tokens máximos válidos (mínimo 1)';

  @override
  String get rateLimit => 'Límite de Tasa';

  @override
  String get rateLimitSubtitle => 'Máximo de solicitudes por minuto';

  @override
  String get pleaseEnterRateLimit => 'Por favor ingrese el límite de tasa';

  @override
  String get invalidRateLimit => 'El límite de tasa debe estar entre 1 y 100';

  @override
  String get rateAndTokenLimits => 'Límites de Tasa y Tokens';

  @override
  String get testConnection => 'Probar Conexión';

  @override
  String get connectionSuccessful => '¡Conexión exitosa!';

  @override
  String get connectionFailed => 'Conexión fallida';

  @override
  String get aiFeaturesToggle => 'Alternar Características de IA';

  @override
  String get autoCategorization => 'Categorización Automática';

  @override
  String get autoCategorizationSubtitle =>
      'Categorice automáticamente sus tareas';

  @override
  String get prioritySorting => 'Ordenación por Prioridad';

  @override
  String get prioritySortingSubtitle =>
      'Evalúe la importancia y prioridad de las tareas';

  @override
  String get motivationalMessages => 'Mensajes Motivacionales';

  @override
  String get motivationalMessagesSubtitle =>
      'Genere mensajes alentadores basados en su progreso';

  @override
  String get smartNotifications => 'Notificaciones Inteligentes';

  @override
  String get smartNotificationsSubtitle =>
      'Cree contenido de notificaciones personalizado';

  @override
  String get completionMotivation => 'Motivación de Finalización';

  @override
  String get completionMotivationSubtitle =>
      'Muestre motivación basada en la tasa de finalización diaria';

  @override
  String get aiCategoryWork => 'Trabajo';

  @override
  String get aiCategoryPersonal => 'Personal';

  @override
  String get aiCategoryStudy => 'Estudio';

  @override
  String get aiCategoryHealth => 'Salud';

  @override
  String get aiCategoryFitness => 'Fitness';

  @override
  String get aiCategoryFinance => 'Finanzas';

  @override
  String get aiCategoryShopping => 'Compras';

  @override
  String get aiCategoryFamily => 'Familia';

  @override
  String get aiCategorySocial => 'Social';

  @override
  String get aiCategoryHobby => 'Aficiones';

  @override
  String get aiCategoryTravel => 'Viajes';

  @override
  String get aiCategoryOther => 'Otro';

  @override
  String get aiPriorityHigh => 'Alta Prioridad';

  @override
  String get aiPriorityMedium => 'Prioridad Media';

  @override
  String get aiPriorityLow => 'Baja Prioridad';

  @override
  String get aiPriorityUrgent => 'Urgente';

  @override
  String get aiPriorityImportant => 'Importante';

  @override
  String get aiPriorityNormal => 'Normal';

  @override
  String get selectTodoForPomodoro => 'Seleccionar una Tarea';

  @override
  String get pomodoroDescription =>
      'Elija una tarea para comenzar su sesión de enfoque Pomodoro';

  @override
  String get noTodosForPomodoro => 'No hay tareas disponibles';

  @override
  String get createTodoForPomodoro => 'Por favor cree algunas tareas primero';

  @override
  String get todaySessions => 'Sesiones de Hoy';

  @override
  String get startPomodoro => 'Iniciar Pomodoro';

  @override
  String get aiDebugInfo => 'Información de Depuración de IA';

  @override
  String get processingUnprocessedTodos =>
      'Procesando tareas no procesadas con IA';

  @override
  String get processAllTodosWithAI => 'Procesar Todas las Tareas con IA';

  @override
  String todayTimeFormat(Object time) {
    return 'Hoy $time';
  }

  @override
  String tomorrowTimeFormat(Object time) {
    return 'Mañana $time';
  }

  @override
  String get deleteTodoDialogTitle => 'Eliminar';

  @override
  String get deleteTodoDialogMessage =>
      '¿Está seguro de que desea eliminar esta tarea?';

  @override
  String get deleteTodoDialogCancel => 'Cancelar';

  @override
  String get deleteTodoDialogDelete => 'Eliminar';

  @override
  String get customPersona => 'Persona Personalizada';

  @override
  String get personaPrompt => 'Prompt de Persona';

  @override
  String get personaPromptHint =>
      'ej., Eres un asistente amigable que usa humor y emojis...';

  @override
  String get personaPromptDescription =>
      'Personalice la personalidad de la IA para las notificaciones. Esto se aplicará tanto a recordatorios de tareas como a resúmenes diarios.';

  @override
  String get personaExample1 =>
      'Eres un entrenador motivador que anima con refuerzo positivo';

  @override
  String get personaExample2 =>
      'Eres un asistente humorístico que usa humor ligero y emojis';

  @override
  String get personaExample3 =>
      'Eres un experto en productividad profesional que da consejos concisos';

  @override
  String get personaExample4 =>
      'Eres un amigo de apoyo que recuerda con calidez y cuidado';

  @override
  String get aiDebugInfoTitle => 'Información de Depuración de IA';

  @override
  String get aiDebugInfoSubtitle => 'Verificar estado de funcionalidad de IA';

  @override
  String get aiSettingsStatus => 'Estado de Configuración de IA';

  @override
  String get aiFeatureToggles => 'Interruptores de Características de IA';

  @override
  String get aiTodoProviderConnection => 'Conexión del Proveedor de Tareas';

  @override
  String get aiMessages => 'Mensajes de IA';

  @override
  String get aiApiRequestManager => 'Gestor de Solicitudes de API';

  @override
  String get aiCurrentRequestQueue => 'Cola de Solicitudes Actual';

  @override
  String get aiRecentRequests => 'Solicitudes Recientes';

  @override
  String get aiPermissionRequestMessage =>
      'Por favor habilite el permiso \"Alarmas y Recordatorios\" para \"Easy Todo\" en la configuración del sistema.';

  @override
  String get developerNameMeowLynxSea => '梦凌汐 (MeowLynxSea)';

  @override
  String get developerEmail => 'mew@meowdream.cn';

  @override
  String get developerGithub => 'github.com/MeowLynxSea';

  @override
  String get developerWebsite => 'www.meowdream.cn';

  @override
  String get backupFileShareSubject => 'Archivo de Respaldo de Easy Todo';

  @override
  String shareFailed(Object error) {
    return 'Error al compartir: $error';
  }

  @override
  String get authenticateToAccessAppMessage =>
      'Por favor use la huella digital para acceder a la aplicación';

  @override
  String get aiFeaturesEnabled => 'Características de IA Habilitadas';

  @override
  String get aiServiceValid => 'Servicio de IA Válido';

  @override
  String get notConfigured => 'No configurado';

  @override
  String configured(Object count) {
    return 'Configurado ($count caracteres)';
  }

  @override
  String get aiProviderConnected => 'Proveedor de IA Conectado';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get aiProcessedTodos => 'Tareas Procesadas por IA';

  @override
  String get todosWithAICategory => 'Tareas con Categoría de IA';

  @override
  String get todosWithAIPriority => 'Tareas con Prioridad de IA';

  @override
  String get lastError => 'Último Error';

  @override
  String get pendingRequests => 'Solicitudes Pendientes';

  @override
  String get currentWindowRequests => 'Solicitudes de Ventana Actual';

  @override
  String get maxRequestsPerMinute => 'Máx. Solicitudes/Minuto';

  @override
  String get status => 'Estado';

  @override
  String get aiServiceNotAvailable => 'Servicio de IA no disponible';

  @override
  String get completionMessages => 'Mensajes de Finalización';

  @override
  String get exactAlarmPermission => 'Permiso de Alarma Exacta';

  @override
  String get exactAlarmPermissionContent =>
      'Para asegurar que las funciones de pomodoro y recordatorios funcionen con precisión, la aplicación necesita permiso de alarma exacta.\n\nPor favor habilite el permiso \"Alarmas y Recordatorios\" para \"Easy Todo\" en la configuración del sistema.';

  @override
  String get setLater => 'Configurar Después';

  @override
  String get goToSettings => 'Ir a Configuración';

  @override
  String get batteryOptimizationSettings =>
      'Configuración de Optimización de Batería';

  @override
  String get batteryOptimizationContent =>
      'Para asegurar que las funciones de pomodoro y recordatorios funcionen correctamente en segundo plano, por favor deshabilite la optimización de batería para esta aplicación.\n\nEsto puede aumentar el consumo de batería, pero asegura que las funciones de temporizador y recordatorios funcionen con precisión.';

  @override
  String get breakTimeComplete => '¡Tiempo de descanso terminado!';

  @override
  String get timeToGetBackToWork => '¡Es hora de volver al trabajo!';

  @override
  String get aiServiceReturnedEmptyMessage =>
      'El servicio de IA devolvió un mensaje vacío';

  @override
  String errorGeneratingMotivationalMessage(Object error) {
    return 'Error al generar mensaje motivacional: $error';
  }

  @override
  String get aiServiceNotAvailableCheckSettings =>
      'Servicio de IA no disponible, por favor verifique la configuración de IA';

  @override
  String get filterByCategory => 'Filtrar por Categoría';

  @override
  String get importance => 'Importancia';

  @override
  String get noCategoriesAvailable => 'No hay categorías disponibles';

  @override
  String get aiWillCategorizeTasks =>
      'La IA categorizará tareas automáticamente, por favor intente nuevamente más tarde';

  @override
  String get selectCategories => 'Seleccionar Categorías';

  @override
  String get selectedCategories => 'Seleccionado';

  @override
  String get categories => 'categorías';

  @override
  String get apiFormat => 'Formato API';

  @override
  String get apiFormatDescription =>
      'Elige tu proveedor de servicios de IA. Los diferentes proveedores pueden requerir diferentes puntos finales de API y métodos de autenticación.';

  @override
  String get openaiFormat => 'OpenAI';

  @override
  String get anthropicFormat => 'Anthropic';

  @override
  String aiPromptCategorization(Object description, Object title) {
    return 'Clasifica esta tarea pendiente en una de estas categorías:\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n\n      Tarea: \"$title\"\n      Descripción: \"$description\"\n\n      Responde solo con el nombre de la categoría en minúsculas.';
  }

  @override
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  ) {
    return 'Califica la prioridad de esta tarea pendiente de 0-100, considerando:\n      - Urgencia: ¿Qué tan pronto se necesita? (fecha límite: $deadline)\n      - Impacto: ¿Cuáles son las consecuencias de no completarla?\n      - Esfuerzo: ¿Cuánto tiempo/recursos requerirá?\n      - Importancia personal: ¿Qué tan valiosa es para ti?\n\n      Tarea: \"$title\"\n      Descripción: \"$description\"\n      Tiene fecha límite: $hasDeadline\n      Fecha límite: $deadline\n\n      Directrices:\n      - 0-20: Prioridad baja, puede posponerse\n      - 21-40: Prioridad moderada, debe hacerse pronto\n      - 41-70: Prioridad alta, importante completar\n      - 71-100: Prioridad crítica, necesidad urgente de completar\n\n      Responde solo con un número de 0-100.';
  }

  @override
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  ) {
    return 'Genera un mensaje motivador basado en estos datos estadísticos:\n      Nombre: \"$name\"\n      Descripción: \"$description\"\n      Valor: $value\n      Unidad: \"$unit\"\n      Fecha: $date\n\n      Requisitos:\n      - Hazlo alentador y específico a los datos\n      - Manténlo bajo 25 caracteres\n      - Enfócate en logros y progreso\n      - Usa lenguaje positivo y orientado a la acción\n      - Ejemplo: \"¡Gran progreso hoy! 🎯\" o \"¡Sigue así! 💪\"\n      - Responde solo con el mensaje, sin explicaciones';
  }

  @override
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  ) {
    return 'Crea un recordatorio de notificación personalizado para esta tarea:\n      Tarea: \"$title\"\n      Descripción: \"$description\"\n      Categoría: $category\n      Prioridad: $priority\n\n      Requisitos:\n      - Crea tanto un título como un mensaje\n      - Título: Menos de 20 caracteres, llamativo\n      - Mensaje: Menos de 50 caracteres, motivador y accionable\n      - Usa emojis cuando sea apropiado para engagement\n      - Incluye urgencia basada en el nivel de prioridad\n      - Hazlo personal y alentador\n      - Responde solo con el título y mensaje en el formato especificado, sin explicaciones\n\n      Formato tu respuesta como:\n      TITLE: [título]\n      MESSAGE: [mensaje]';
  }

  @override
  String aiPromptCompletion(Object completed, Object percentage, Object total) {
    return 'Genera un mensaje alentador basado en el completion de tareas de hoy:\n      Completadas: $completed de $total tareas\n      Tasa de completion: $percentage%\n\n      Requisitos:\n      - Hazlo positivo y motivador\n      - Manténlo bajo 25 caracteres\n      - Celebra logros y progreso\n      - Usa lenguaje alentador y/o emojis\n      - Ejemplo: \"¡Excelente trabajo! 🌟\" o \"¡Progreso! 👍\"\n      - Responde solo con el mensaje, sin explicaciones';
  }

  @override
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  ) {
    return 'Crea una notificación de resumen diario para tareas pendientes.\n\nCantidad de tareas pendientes: $pendingCount\nCategorías: $categories\nPrioridad promedio: $avgPriority/100\n\nCrea un resumen personalizado con:\n1. Un título llamativo (primera línea)\n2. Un mensaje alentador que DEBE incluir la cantidad de tareas no completadas ($pendingCount)\n3. Mantén el contenido del mensaje bajo 50 caracteres. Hazlo motivador y accionable.\n4. Responde solo con el título y mensaje, sin explicaciones';
  }

  @override
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  ) {
    return 'Crea una notificación personalizada para una sesión de $sessionType completada.\n\nDetalles de la sesión:\n- Tarea: \"$taskTitle\"\n- Tipo de sesión: $sessionType\n- Duración: $duration minutos\n- Completada: $isCompleted\n\nIMPORTANTE: Responde en el mismo idioma que este mensaje (español).\n\nCrea un título y un mensaje:\n1. Título: Menos de 20 caracteres, llamativo y celebratorio\n2. Mensaje: Menos de 50 caracteres, alentador y relevante a la sesión completada\n3. Para sesiones de enfoque (trabajo completado): Enfatiza logros del trabajo y que es hora de un descanso merecido\n4. Para sesiones de descanso (descanso completado): Enfócate en la finalización del descanso y que es hora de volver al trabajo concentrado\n5. Usa emojis cuando sea apropiado para engagement\n6. Hazlo personal y motivador\n7. Responde solo con el título y mensaje en el formato especificado, sin explicaciones\n\nFormatea tu respuesta como:\nTITLE: [título]\nMESSAGE: [mensaje]';
  }

  @override
  String get cloudSyncAuthProcessingTitle => 'Iniciando sesión';

  @override
  String get cloudSyncAuthProcessingSubtitle =>
      'Procesando devolución de llamada de inicio de sesión…';

  @override
  String get cloudSyncChangePassphraseTitle => 'Cambiar frase de paso';

  @override
  String get cloudSyncChangePassphraseSubtitle =>
      'Solo reenvolver el DEK (sin volver a subir el historial)';

  @override
  String get cloudSyncChangePassphraseAction => 'Cambiar';

  @override
  String get cloudSyncChangePassphraseDialogTitle =>
      'Cambiar frase de paso de sincronización';

  @override
  String get cloudSyncChangePassphraseDialogHint =>
      'Esto solo actualiza el paquete de claves. Es posible que otros dispositivos deban introducir la nueva frase de paso para desbloquear.';

  @override
  String get cloudSyncCurrentPassphrase => 'Frase de paso actual';

  @override
  String get cloudSyncNewPassphrase => 'Nueva frase de paso';

  @override
  String get cloudSyncPassphraseChangedSnack => 'Frase de paso actualizada';

  @override
  String get syncAiApiKeyTitle => 'Sincronizar clave API (cifrada)';

  @override
  String get syncAiApiKeySubtitle =>
      'Comparte tu clave API entre dispositivos mediante cifrado de extremo a extremo (opcional)';

  @override
  String get syncAiApiKeyWarningTitle => '¿Sincronizar clave API?';

  @override
  String get syncAiApiKeyWarningMessage =>
      'Tu clave API se subirá como texto cifrado y puede ser descifrada por dispositivos con tu frase de paso de sincronización. Actívalo solo si entiendes el riesgo.';

  @override
  String get cloudSyncAutoSyncIntervalTitle =>
      'Intervalo de sincronización automática';

  @override
  String get cloudSyncAutoSyncIntervalHint =>
      'El sondeo es específico del dispositivo. Si hay cambios locales pendientes, podrían sincronizarse antes mediante el disparador del buzón de salida.';

  @override
  String get cloudSyncAutoSyncIntervalSecondsLabel => 'Segundos';

  @override
  String get cloudSyncAutoSyncIntervalMinHint => 'Mínimo 30 segundos';

  @override
  String get cloudSyncAutoSyncIntervalSavedSnack =>
      'Intervalo de sincronización automática guardado';

  @override
  String cloudSyncAutoSyncIntervalSubtitle(Object interval) {
    return 'Actual: $interval';
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
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language settings allow you to change the display language of the app. Select your preferred language from the list above.'**
  String get languageSettings;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorage;

  /// No description provided for @dataAndSync.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get dataAndSync;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted sync'**
  String get cloudSyncSubtitle;

  /// No description provided for @cloudSyncOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted sync'**
  String get cloudSyncOverviewTitle;

  /// No description provided for @cloudSyncOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Server stores only ciphertext; unlock with your passphrase on this device.'**
  String get cloudSyncOverviewSubtitle;

  /// No description provided for @cloudSyncConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Sync config saved'**
  String get cloudSyncConfigSaved;

  /// No description provided for @cloudSyncServerOkSnack.
  ///
  /// In en, this message translates to:
  /// **'Server reachable'**
  String get cloudSyncServerOkSnack;

  /// No description provided for @cloudSyncServerCheckFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Server check failed'**
  String get cloudSyncServerCheckFailedSnack;

  /// No description provided for @cloudSyncDisabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Sync disabled'**
  String get cloudSyncDisabledSnack;

  /// No description provided for @cloudSyncEnableSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable cloud sync'**
  String get cloudSyncEnableSwitchTitle;

  /// No description provided for @cloudSyncEnableSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync your data across your devices'**
  String get cloudSyncEnableSwitchSubtitle;

  /// No description provided for @cloudSyncServerSection.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get cloudSyncServerSection;

  /// No description provided for @cloudSyncSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'1) Configure server'**
  String get cloudSyncSetupTitle;

  /// No description provided for @cloudSyncSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set server URL, then choose a provider and login.'**
  String get cloudSyncSetupSubtitle;

  /// No description provided for @cloudSyncSetupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Server configuration'**
  String get cloudSyncSetupDialogTitle;

  /// No description provided for @cloudSyncServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get cloudSyncServerUrl;

  /// No description provided for @cloudSyncServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://127.0.0.1:8787'**
  String get cloudSyncServerUrlHint;

  /// No description provided for @cloudSyncAuthProvider.
  ///
  /// In en, this message translates to:
  /// **'OAuth provider'**
  String get cloudSyncAuthProvider;

  /// No description provided for @cloudSyncAuthProviderHint.
  ///
  /// In en, this message translates to:
  /// **'linuxdo'**
  String get cloudSyncAuthProviderHint;

  /// No description provided for @cloudSyncAuthMode.
  ///
  /// In en, this message translates to:
  /// **'Auth'**
  String get cloudSyncAuthMode;

  /// No description provided for @cloudSyncAuthModeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get cloudSyncAuthModeLoggedIn;

  /// No description provided for @cloudSyncAuthModeLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get cloudSyncAuthModeLoggedOut;

  /// No description provided for @cloudSyncCheckServer.
  ///
  /// In en, this message translates to:
  /// **'Check server'**
  String get cloudSyncCheckServer;

  /// No description provided for @cloudSyncEditServerConfig.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cloudSyncEditServerConfig;

  /// No description provided for @cloudSyncLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get cloudSyncLogin;

  /// No description provided for @cloudSyncLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get cloudSyncLogout;

  /// No description provided for @cloudSyncLoggedInSnack.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get cloudSyncLoggedInSnack;

  /// No description provided for @cloudSyncLoggedOutSnack.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get cloudSyncLoggedOutSnack;

  /// No description provided for @cloudSyncLoginRedirectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Continue login in your browser'**
  String get cloudSyncLoginRedirectedSnack;

  /// No description provided for @cloudSyncLoginFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get cloudSyncLoginFailedSnack;

  /// No description provided for @cloudSyncNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cloudSyncNotSet;

  /// No description provided for @cloudSyncTokenSet.
  ///
  /// In en, this message translates to:
  /// **'Token is set'**
  String get cloudSyncTokenSet;

  /// No description provided for @cloudSyncStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get cloudSyncStatusSection;

  /// No description provided for @cloudSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get cloudSyncEnabled;

  /// No description provided for @cloudSyncUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get cloudSyncUnlocked;

  /// No description provided for @cloudSyncEnabledOn.
  ///
  /// In en, this message translates to:
  /// **'Enabled: On'**
  String get cloudSyncEnabledOn;

  /// No description provided for @cloudSyncEnabledOff.
  ///
  /// In en, this message translates to:
  /// **'Enabled: Off'**
  String get cloudSyncEnabledOff;

  /// No description provided for @cloudSyncUnlockedYes.
  ///
  /// In en, this message translates to:
  /// **'Unlocked: Yes'**
  String get cloudSyncUnlockedYes;

  /// No description provided for @cloudSyncUnlockedNo.
  ///
  /// In en, this message translates to:
  /// **'Unlocked: No'**
  String get cloudSyncUnlockedNo;

  /// No description provided for @cloudSyncConfiguredYes.
  ///
  /// In en, this message translates to:
  /// **'Configured: Yes'**
  String get cloudSyncConfiguredYes;

  /// No description provided for @cloudSyncConfiguredNo.
  ///
  /// In en, this message translates to:
  /// **'Configured: No'**
  String get cloudSyncConfiguredNo;

  /// No description provided for @cloudSyncLastServerSeq.
  ///
  /// In en, this message translates to:
  /// **'Last serverSeq'**
  String get cloudSyncLastServerSeq;

  /// No description provided for @cloudSyncDekId.
  ///
  /// In en, this message translates to:
  /// **'DEK ID'**
  String get cloudSyncDekId;

  /// No description provided for @cloudSyncLastSyncAt.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get cloudSyncLastSyncAt;

  /// No description provided for @cloudSyncError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cloudSyncError;

  /// No description provided for @cloudSyncDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get cloudSyncDeviceId;

  /// No description provided for @cloudSyncEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get cloudSyncEnable;

  /// No description provided for @cloudSyncUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get cloudSyncUnlock;

  /// No description provided for @cloudSyncSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get cloudSyncSyncNow;

  /// No description provided for @cloudSyncDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get cloudSyncDisable;

  /// No description provided for @cloudSyncSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'2) Unlock'**
  String get cloudSyncSecurityTitle;

  /// No description provided for @cloudSyncSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock uses your passphrase to access the DEK. Mobile/desktop can cache it in secure storage.'**
  String get cloudSyncSecuritySubtitle;

  /// No description provided for @cloudSyncLockStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Encryption key'**
  String get cloudSyncLockStateTitle;

  /// No description provided for @cloudSyncLockStateUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on this device'**
  String get cloudSyncLockStateUnlocked;

  /// No description provided for @cloudSyncLockStateLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked — enter passphrase to unlock'**
  String get cloudSyncLockStateLocked;

  /// No description provided for @cloudSyncActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'3) Sync'**
  String get cloudSyncActionsTitle;

  /// No description provided for @cloudSyncActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push local changes then pull remote updates.'**
  String get cloudSyncActionsSubtitle;

  /// No description provided for @cloudSyncAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cloudSyncAdvancedTitle;

  /// No description provided for @cloudSyncAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Debug info (device-local)'**
  String get cloudSyncAdvancedSubtitle;

  /// No description provided for @cloudSyncEnableDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable sync'**
  String get cloudSyncEnableDialogTitle;

  /// No description provided for @cloudSyncUnlockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock sync'**
  String get cloudSyncUnlockDialogTitle;

  /// No description provided for @cloudSyncPassphraseDialogHint.
  ///
  /// In en, this message translates to:
  /// **'If you already enabled sync on another device, enter the same passphrase twice.'**
  String get cloudSyncPassphraseDialogHint;

  /// No description provided for @cloudSyncPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get cloudSyncPassphrase;

  /// No description provided for @cloudSyncConfirmPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Confirm passphrase'**
  String get cloudSyncConfirmPassphrase;

  /// No description provided for @cloudSyncShowPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get cloudSyncShowPassphrase;

  /// No description provided for @cloudSyncEnabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Sync enabled'**
  String get cloudSyncEnabledSnack;

  /// No description provided for @cloudSyncUnlockedSnack.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get cloudSyncUnlockedSnack;

  /// No description provided for @cloudSyncSyncedSnack.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get cloudSyncSyncedSnack;

  /// No description provided for @cloudSyncInvalidPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Invalid passphrase'**
  String get cloudSyncInvalidPassphrase;

  /// No description provided for @cloudSyncRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible server rollback'**
  String get cloudSyncRollbackTitle;

  /// No description provided for @cloudSyncRollbackMessage.
  ///
  /// In en, this message translates to:
  /// **'The server may have rolled back or restored from a backup. Continuing may cause data loss. What do you want to do?'**
  String get cloudSyncRollbackMessage;

  /// No description provided for @cloudSyncStopSync.
  ///
  /// In en, this message translates to:
  /// **'Stop sync'**
  String get cloudSyncStopSync;

  /// No description provided for @cloudSyncContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cloudSyncContinue;

  /// No description provided for @cloudSyncWebDekNote.
  ///
  /// In en, this message translates to:
  /// **'Web stores the key until the browser is closed. Restarting the browser requires unlocking again.'**
  String get cloudSyncWebDekNote;

  /// No description provided for @cloudSyncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'idle'**
  String get cloudSyncStatusIdle;

  /// No description provided for @cloudSyncStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get cloudSyncStatusRunning;

  /// No description provided for @cloudSyncStatusError.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get cloudSyncStatusError;

  /// No description provided for @cloudSyncErrorPassphraseMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passphrase mismatch'**
  String get cloudSyncErrorPassphraseMismatch;

  /// No description provided for @cloudSyncErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync not configured'**
  String get cloudSyncErrorNotConfigured;

  /// No description provided for @cloudSyncErrorDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sync is disabled'**
  String get cloudSyncErrorDisabled;

  /// No description provided for @cloudSyncErrorLocked.
  ///
  /// In en, this message translates to:
  /// **'Sync is locked (missing DEK)'**
  String get cloudSyncErrorLocked;

  /// No description provided for @cloudSyncErrorAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'Account changed — please re-enable sync'**
  String get cloudSyncErrorAccountChanged;

  /// No description provided for @cloudSyncErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized (check token)'**
  String get cloudSyncErrorUnauthorized;

  /// No description provided for @cloudSyncErrorBanned.
  ///
  /// In en, this message translates to:
  /// **'Account banned'**
  String get cloudSyncErrorBanned;

  /// No description provided for @cloudSyncErrorKeyBundleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Key bundle not found on server'**
  String get cloudSyncErrorKeyBundleNotFound;

  /// No description provided for @cloudSyncErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get cloudSyncErrorNetwork;

  /// No description provided for @cloudSyncErrorConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict (bundle version mismatch)'**
  String get cloudSyncErrorConflict;

  /// No description provided for @cloudSyncErrorQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Server quota exceeded (some records were rejected)'**
  String get cloudSyncErrorQuotaExceeded;

  /// No description provided for @cloudSyncErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get cloudSyncErrorUnknown;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup your data'**
  String get backupSubtitle;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage storage space'**
  String get storageSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutEasyTodo.
  ///
  /// In en, this message translates to:
  /// **'About Easy Todo'**
  String get aboutEasyTodo;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help with the app'**
  String get helpSubtitle;

  /// No description provided for @processingCategory.
  ///
  /// In en, this message translates to:
  /// **'Processing category...'**
  String get processingCategory;

  /// No description provided for @processingPriority.
  ///
  /// In en, this message translates to:
  /// **'Processing priority...'**
  String get processingPriority;

  /// No description provided for @processingAI.
  ///
  /// In en, this message translates to:
  /// **'Processing AI...'**
  String get processingAI;

  /// No description provided for @aiProcessingCompleted.
  ///
  /// In en, this message translates to:
  /// **'AI processing completed'**
  String get aiProcessingCompleted;

  /// No description provided for @categorizingTask.
  ///
  /// In en, this message translates to:
  /// **'Categorizing task...'**
  String get categorizingTask;

  /// No description provided for @processingAIStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing AI...'**
  String get processingAIStatus;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all todos and settings'**
  String get clearDataSubtitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A clean, elegant todo list application designed for simplicity and productivity.'**
  String get appDescription;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developerInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Information'**
  String get developerInfo;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'If you encounter any issues or have suggestions, feel free to reach out through any of the contact methods above.'**
  String get helpDescription;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @themeColors.
  ///
  /// In en, this message translates to:
  /// **'Theme Colors'**
  String get themeColors;

  /// No description provided for @customTheme.
  ///
  /// In en, this message translates to:
  /// **'Custom Theme'**
  String get customTheme;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get secondaryColor;

  /// No description provided for @selectPrimaryColor.
  ///
  /// In en, this message translates to:
  /// **'Select primary color for the app'**
  String get selectPrimaryColor;

  /// No description provided for @selectSecondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Select secondary color for the app'**
  String get selectSecondaryColor;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @lightness.
  ///
  /// In en, this message translates to:
  /// **'Lightness'**
  String get lightness;

  /// No description provided for @applyCustomTheme.
  ///
  /// In en, this message translates to:
  /// **'Apply Custom Theme'**
  String get applyCustomTheme;

  /// No description provided for @customThemeApplied.
  ///
  /// In en, this message translates to:
  /// **'Custom theme applied successfully'**
  String get customThemeApplied;

  /// No description provided for @themeColorApplied.
  ///
  /// In en, this message translates to:
  /// **'Theme color applied'**
  String get themeColorApplied;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatTask.
  ///
  /// In en, this message translates to:
  /// **'Repeat Task'**
  String get repeatTask;

  /// No description provided for @repeatType.
  ///
  /// In en, this message translates to:
  /// **'Repeat Type'**
  String get repeatType;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @selectDays.
  ///
  /// In en, this message translates to:
  /// **'Select Days'**
  String get selectDays;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @everyWeek.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get everyWeek;

  /// No description provided for @everyMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get everyMonth;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No End Date'**
  String get noEndDate;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get timeRange;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @noStartTimeSet.
  ///
  /// In en, this message translates to:
  /// **'No start time set'**
  String get noStartTimeSet;

  /// No description provided for @noEndTimeSet.
  ///
  /// In en, this message translates to:
  /// **'No end time set'**
  String get noEndTimeSet;

  /// No description provided for @invalidTimeRange.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get invalidTimeRange;

  /// No description provided for @repeatEnabled.
  ///
  /// In en, this message translates to:
  /// **'Repeat Enabled'**
  String get repeatEnabled;

  /// No description provided for @repeatDescription.
  ///
  /// In en, this message translates to:
  /// **'Create recurring tasks automatically'**
  String get repeatDescription;

  /// No description provided for @backfillMode.
  ///
  /// In en, this message translates to:
  /// **'Catch-up mode'**
  String get backfillMode;

  /// No description provided for @backfillModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Create missed recurring todos for previous days'**
  String get backfillModeDescription;

  /// No description provided for @backfillDays.
  ///
  /// In en, this message translates to:
  /// **'Look-back days'**
  String get backfillDays;

  /// No description provided for @backfillDaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Max days to look back (1-365, not including today)'**
  String get backfillDaysDescription;

  /// No description provided for @backfillAutoComplete.
  ///
  /// In en, this message translates to:
  /// **'Auto-complete backfilled todos'**
  String get backfillAutoComplete;

  /// No description provided for @backfillDaysRangeError.
  ///
  /// In en, this message translates to:
  /// **'Look-back days must be between 1 and 365'**
  String get backfillDaysRangeError;

  /// No description provided for @backfillConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Backfill conflict'**
  String get backfillConflictTitle;

  /// No description provided for @backfillConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'Task \"{title}\" starts on {startDate}, but catch-up would look back to {backfillStartDate}. Which should be used as the earliest generation date for this refresh?'**
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  );

  /// No description provided for @useStartDate.
  ///
  /// In en, this message translates to:
  /// **'Use start date'**
  String get useStartDate;

  /// No description provided for @useBackfillDays.
  ///
  /// In en, this message translates to:
  /// **'Use catch-up range'**
  String get useBackfillDays;

  /// No description provided for @activeRepeatTasks.
  ///
  /// In en, this message translates to:
  /// **'Active Repeat Tasks'**
  String get activeRepeatTasks;

  /// No description provided for @noRepeatTasks.
  ///
  /// In en, this message translates to:
  /// **'No repeat tasks yet'**
  String get noRepeatTasks;

  /// No description provided for @pauseRepeat.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseRepeat;

  /// No description provided for @resumeRepeat.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeRepeat;

  /// No description provided for @editRepeat.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editRepeat;

  /// No description provided for @deleteRepeat.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteRepeat;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @repeatTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Repeat Task'**
  String get repeatTaskConfirm;

  /// No description provided for @repeatTaskDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all recurring tasks generated from this template. This action cannot be undone.'**
  String get repeatTaskDeleteMessage;

  /// No description provided for @manageRepeatTasks.
  ///
  /// In en, this message translates to:
  /// **'Manage Repeat Tasks'**
  String get manageRepeatTasks;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @todos.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get todos;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your todos and statistics. This action cannot be undone.'**
  String get clearDataWarning;

  /// No description provided for @dataClearedSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data has been cleared successfully'**
  String get dataClearedSuccess;

  /// No description provided for @clearDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear data'**
  String get clearDataFailed;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @searchTodos.
  ///
  /// In en, this message translates to:
  /// **'Search todos'**
  String get searchTodos;

  /// No description provided for @addTodo.
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get addTodo;

  /// No description provided for @addTodoHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get addTodoHint;

  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get todoTitle;

  /// No description provided for @todoDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get todoDescription;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @allTodos.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTodos;

  /// No description provided for @activeTodos.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTodos;

  /// No description provided for @completedTodos.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTodos;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @totalTodos.
  ///
  /// In en, this message translates to:
  /// **'Total Todos'**
  String get totalTodos;

  /// No description provided for @completedTodosCount.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTodosCount;

  /// No description provided for @activeTodosCount.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTodosCount;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(Object error);

  /// No description provided for @webBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Web: backups use download/upload.'**
  String get webBackupHint;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data with data from \"{fileName}\". This action cannot be undone. Continue?'**
  String restoreWarning(Object fileName);

  /// No description provided for @totalStorage.
  ///
  /// In en, this message translates to:
  /// **'Total Storage'**
  String get totalStorage;

  /// No description provided for @todosStorage.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get todosStorage;

  /// No description provided for @cacheStorage.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cacheStorage;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgress;

  /// No description provided for @monthlyTrends.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trends'**
  String get monthlyTrends;

  /// No description provided for @productivityOverview.
  ///
  /// In en, this message translates to:
  /// **'Productivity Overview'**
  String get productivityOverview;

  /// No description provided for @overallCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Overall Completion Rate'**
  String get overallCompletionRate;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @todoDistribution.
  ///
  /// In en, this message translates to:
  /// **'Todo Distribution'**
  String get todoDistribution;

  /// No description provided for @bestPerformance.
  ///
  /// In en, this message translates to:
  /// **'Best Performance'**
  String get bestPerformance;

  /// No description provided for @noCompletedTodosYet.
  ///
  /// In en, this message translates to:
  /// **'No completed todos yet'**
  String get noCompletedTodosYet;

  /// No description provided for @completionRateDescription.
  ///
  /// In en, this message translates to:
  /// **'of all todos completed'**
  String get completionRateDescription;

  /// No description provided for @fingerprintLock.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint Lock'**
  String get fingerprintLock;

  /// No description provided for @fingerprintLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect app security with fingerprint'**
  String get fingerprintLockSubtitle;

  /// No description provided for @fingerprintLockEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable fingerprint lock'**
  String get fingerprintLockEnable;

  /// No description provided for @fingerprintLockDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable fingerprint lock'**
  String get fingerprintLockDisable;

  /// No description provided for @fingerprintLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint lock enabled'**
  String get fingerprintLockEnabled;

  /// No description provided for @fingerprintLockDisabled.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint lock disabled'**
  String get fingerprintLockDisabled;

  /// No description provided for @fingerprintNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint authentication not available'**
  String get fingerprintNotAvailable;

  /// No description provided for @fingerprintNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint enrolled'**
  String get fingerprintNotEnrolled;

  /// No description provided for @fingerprintAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint authentication failed'**
  String get fingerprintAuthenticationFailed;

  /// No description provided for @fingerprintAuthenticationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint authentication successful'**
  String get fingerprintAuthenticationSuccess;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @week1.
  ///
  /// In en, this message translates to:
  /// **'Week 1'**
  String get week1;

  /// No description provided for @week2.
  ///
  /// In en, this message translates to:
  /// **'Week 2'**
  String get week2;

  /// No description provided for @week3.
  ///
  /// In en, this message translates to:
  /// **'Week 3'**
  String get week3;

  /// No description provided for @week4.
  ///
  /// In en, this message translates to:
  /// **'Week 4'**
  String get week4;

  /// No description provided for @withCompletedTodos.
  ///
  /// In en, this message translates to:
  /// **'with {count} todos completed'**
  String withCompletedTodos(Object count);

  /// No description provided for @unableToLoadBackupStats.
  ///
  /// In en, this message translates to:
  /// **'Unable to load backup statistics'**
  String get unableToLoadBackupStats;

  /// No description provided for @backupSummary.
  ///
  /// In en, this message translates to:
  /// **'Backup Summary'**
  String get backupSummary;

  /// No description provided for @itemsToBackup.
  ///
  /// In en, this message translates to:
  /// **'Items to Backup'**
  String get itemsToBackup;

  /// No description provided for @dataSize.
  ///
  /// In en, this message translates to:
  /// **'Data Size'**
  String get dataSize;

  /// No description provided for @backupFiles.
  ///
  /// In en, this message translates to:
  /// **'Backup Files'**
  String get backupFiles;

  /// No description provided for @backupSize.
  ///
  /// In en, this message translates to:
  /// **'Backup Size'**
  String get backupSize;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @backupRestoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a backup of your data or restore from a previous backup.'**
  String get backupRestoreDescription;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @noBackupFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No backup files found'**
  String get noBackupFilesFound;

  /// No description provided for @createFirstBackup.
  ///
  /// In en, this message translates to:
  /// **'Create your first backup to get started'**
  String get createFirstBackup;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from this file'**
  String get restoreFromFile;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFile;

  /// No description provided for @aboutBackups.
  ///
  /// In en, this message translates to:
  /// **'About Backups'**
  String get aboutBackups;

  /// No description provided for @backupInfo1.
  ///
  /// In en, this message translates to:
  /// **'• Backups contain all your todos and statistics'**
  String get backupInfo1;

  /// No description provided for @backupInfo2.
  ///
  /// In en, this message translates to:
  /// **'• Store backup files in a safe location'**
  String get backupInfo2;

  /// No description provided for @backupInfo3.
  ///
  /// In en, this message translates to:
  /// **'• Regular backups help prevent data loss'**
  String get backupInfo3;

  /// No description provided for @backupInfo4.
  ///
  /// In en, this message translates to:
  /// **'• You can restore from any backup file'**
  String get backupInfo4;

  /// No description provided for @backupCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreatedSuccess;

  /// No description provided for @noBackupFilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No backup files available for restore'**
  String get noBackupFilesAvailable;

  /// No description provided for @selectBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Select Backup File'**
  String get selectBackupFile;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestore;

  /// No description provided for @dataRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully from \"{fileName}\"'**
  String dataRestoredSuccess(Object fileName);

  /// No description provided for @deleteBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup File'**
  String get deleteBackupFile;

  /// No description provided for @deleteBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"? This action cannot be undone.'**
  String deleteBackupWarning(Object fileName);

  /// No description provided for @backupFileDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file \"{fileName}\" deleted successfully'**
  String backupFileDeletedSuccess(Object fileName);

  /// No description provided for @backupFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Backup file not found'**
  String get backupFileNotFound;

  /// No description provided for @invalidFilePath.
  ///
  /// In en, this message translates to:
  /// **'Invalid file path for \"{fileName}\"'**
  String invalidFilePath(Object fileName);

  /// No description provided for @failedToDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file'**
  String get failedToDeleteFile;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get files;

  /// No description provided for @storageManagement.
  ///
  /// In en, this message translates to:
  /// **'Storage Management'**
  String get storageManagement;

  /// No description provided for @storageOverview.
  ///
  /// In en, this message translates to:
  /// **'Storage Overview'**
  String get storageOverview;

  /// No description provided for @storageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Storage Analytics'**
  String get storageAnalytics;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @noRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'No recent requests'**
  String get noRecentRequests;

  /// No description provided for @requestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Request completed'**
  String get requestCompleted;

  /// No description provided for @noTodosToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No todos to display'**
  String get noTodosToDisplay;

  /// No description provided for @todoStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Todo Status Distribution'**
  String get todoStatusDistribution;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @dataStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'Data Storage Usage'**
  String get dataStorageUsage;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @storageCleanup.
  ///
  /// In en, this message translates to:
  /// **'Storage Cleanup'**
  String get storageCleanup;

  /// No description provided for @cleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space by removing unnecessary data:'**
  String get cleanupDescription;

  /// No description provided for @clearCompletedTodos.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed Todos'**
  String get clearCompletedTodos;

  /// No description provided for @clearOldStatistics.
  ///
  /// In en, this message translates to:
  /// **'Clear Old Statistics'**
  String get clearOldStatistics;

  /// No description provided for @clearBackupFiles.
  ///
  /// In en, this message translates to:
  /// **'Clear Backup Files'**
  String get clearBackupFiles;

  /// No description provided for @cleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cleanup completed'**
  String get cleanupCompleted;

  /// No description provided for @todosDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} todos deleted'**
  String todosDeleted(Object count);

  /// No description provided for @statisticsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} statistics deleted'**
  String statisticsDeleted(Object count);

  /// No description provided for @backupFilesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} backup files deleted'**
  String backupFilesDeleted(Object count);

  /// No description provided for @cleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed'**
  String get cleanupFailed;

  /// No description provided for @easyTodo.
  ///
  /// In en, this message translates to:
  /// **'Easy Todo'**
  String get easyTodo;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard: {url}'**
  String copiedToClipboard(Object url);

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot open link, copied to clipboard: {url}'**
  String cannotOpenLink(Object url);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @noTodosMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No todos match your search'**
  String get noTodosMatchSearch;

  /// No description provided for @noCompletedTodos.
  ///
  /// In en, this message translates to:
  /// **'No completed todos'**
  String get noCompletedTodos;

  /// No description provided for @noActiveTodos.
  ///
  /// In en, this message translates to:
  /// **'No active todos'**
  String get noActiveTodos;

  /// No description provided for @noTodosYet.
  ///
  /// In en, this message translates to:
  /// **'No todos yet'**
  String get noTodosYet;

  /// No description provided for @deleteTodoConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this todo?'**
  String get deleteTodoConfirmation;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: '**
  String get createdLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed: '**
  String get completedLabel;

  /// No description provided for @filterByTime.
  ///
  /// In en, this message translates to:
  /// **'Filter by Time'**
  String get filterByTime;

  /// No description provided for @sortByTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by Time'**
  String get sortByTime;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @threeDays.
  ///
  /// In en, this message translates to:
  /// **'Three Days'**
  String get threeDays;

  /// No description provided for @minutesAgoWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgoWithCount(Object count);

  /// No description provided for @hoursAgoWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgoWithCount(Object count);

  /// No description provided for @daysAgoWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgoWithCount(Object count);

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @dailySummaryTime.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary Time'**
  String get dailySummaryTime;

  /// No description provided for @dailySummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive a daily summary of pending todos'**
  String get dailySummaryDescription;

  /// No description provided for @defaultReminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Default Reminder Settings'**
  String get defaultReminderSettings;

  /// No description provided for @enableDefaultReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Default Reminders'**
  String get enableDefaultReminders;

  /// No description provided for @reminderTimeBefore.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time Before Due'**
  String get reminderTimeBefore;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before'**
  String minutesBefore(Object count);

  /// No description provided for @notificationPermissions.
  ///
  /// In en, this message translates to:
  /// **'Notification Permissions'**
  String get notificationPermissions;

  /// No description provided for @grantPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Permissions'**
  String get grantPermissions;

  /// No description provided for @permissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'Permissions Granted'**
  String get permissionsGranted;

  /// No description provided for @permissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Permissions Denied'**
  String get permissionsDenied;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @notificationTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent successfully'**
  String get notificationTestSent;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {time}'**
  String reminderSet(Object time);

  /// No description provided for @cancelReminder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Reminder'**
  String get cancelReminder;

  /// No description provided for @noReminderSet.
  ///
  /// In en, this message translates to:
  /// **'No reminder set'**
  String get noReminderSet;

  /// No description provided for @enableReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminder'**
  String get enableReminder;

  /// No description provided for @reminderOptions.
  ///
  /// In en, this message translates to:
  /// **'Reminder Options'**
  String get reminderOptions;

  /// No description provided for @pomodoroTimer.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Timer'**
  String get pomodoroTimer;

  /// No description provided for @pomodoroSettings.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Settings'**
  String get pomodoroSettings;

  /// No description provided for @workDuration.
  ///
  /// In en, this message translates to:
  /// **'Work Duration'**
  String get workDuration;

  /// No description provided for @breakDuration.
  ///
  /// In en, this message translates to:
  /// **'Break Duration'**
  String get breakDuration;

  /// No description provided for @longBreakDuration.
  ///
  /// In en, this message translates to:
  /// **'Long Break Duration'**
  String get longBreakDuration;

  /// No description provided for @sessionsUntilLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Sessions until Long Break'**
  String get sessionsUntilLongBreak;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get sessions;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// No description provided for @clearOldPomodoroSessions.
  ///
  /// In en, this message translates to:
  /// **'Clear Old Pomodoro Sessions'**
  String get clearOldPomodoroSessions;

  /// No description provided for @pomodoroSessionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} pomodoro sessions'**
  String pomodoroSessionsDeleted(Object count);

  /// No description provided for @breakTime.
  ///
  /// In en, this message translates to:
  /// **'Break Time'**
  String get breakTime;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @timeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get timeSpent;

  /// No description provided for @pomodoroStats.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Statistics'**
  String get pomodoroStats;

  /// No description provided for @sessionsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sessions Completed'**
  String get sessionsCompleted;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @averageTime.
  ///
  /// In en, this message translates to:
  /// **'Average Time'**
  String get averageTime;

  /// No description provided for @focusSessions.
  ///
  /// In en, this message translates to:
  /// **'Focus Sessions'**
  String get focusSessions;

  /// No description provided for @pomodoroSessions.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Sessions'**
  String get pomodoroSessions;

  /// No description provided for @totalFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Total Focus Time'**
  String get totalFocusTime;

  /// No description provided for @weeklyPomodoroStats.
  ///
  /// In en, this message translates to:
  /// **'Weekly Pomodoro Stats'**
  String get weeklyPomodoroStats;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @averageSessions.
  ///
  /// In en, this message translates to:
  /// **'Average Sessions'**
  String get averageSessions;

  /// No description provided for @monthlyPomodoroStats.
  ///
  /// In en, this message translates to:
  /// **'Monthly Pomodoro Stats'**
  String get monthlyPomodoroStats;

  /// No description provided for @averagePerWeek.
  ///
  /// In en, this message translates to:
  /// **'Average per Week'**
  String get averagePerWeek;

  /// No description provided for @pomodoroOverview.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Overview'**
  String get pomodoroOverview;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @checkUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for new versions'**
  String get checkUpdatesSubtitle;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for Updates'**
  String get checkingForUpdates;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we check for updates...'**
  String get pleaseWait;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @requiredUpdate.
  ///
  /// In en, this message translates to:
  /// **'Required Update'**
  String get requiredUpdate;

  /// No description provided for @versionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available!'**
  String versionAvailable(Object version);

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new:'**
  String get whatsNew;

  /// No description provided for @noUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get noUpdatesAvailable;

  /// No description provided for @youHaveLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version'**
  String get youHaveLatestVersion;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading Update'**
  String get downloadingUpdate;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download Update'**
  String get downloadUpdate;

  /// No description provided for @downloadFrom.
  ///
  /// In en, this message translates to:
  /// **'Downloading update from:'**
  String get downloadFrom;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @couldNotOpenDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open download URL'**
  String get couldNotOpenDownloadUrl;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get updateCheckFailed;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A required update is available. Please update to continue using the app.'**
  String get forceUpdateMessage;

  /// No description provided for @optionalUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'You can update now or later'**
  String get optionalUpdateMessage;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get storagePermissionDenied;

  /// No description provided for @cannotAccessStorage.
  ///
  /// In en, this message translates to:
  /// **'Cannot access storage'**
  String get cannotAccessStorage;

  /// No description provided for @updateDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update downloaded successfully'**
  String get updateDownloadSuccess;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get installUpdate;

  /// No description provided for @startingInstaller.
  ///
  /// In en, this message translates to:
  /// **'Starting installer...'**
  String get startingInstaller;

  /// No description provided for @updateFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Update file not found, please download again'**
  String get updateFileNotFound;

  /// No description provided for @installPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Install Permission Required'**
  String get installPermissionRequired;

  /// No description provided for @installPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Installing app updates requires \"Install unknown apps\" permission. Please enable this permission for Easy Todo in settings.'**
  String get installPermissionDescription;

  /// No description provided for @needInstallPermission.
  ///
  /// In en, this message translates to:
  /// **'Install permission is required to update the app'**
  String get needInstallPermission;

  /// No description provided for @installFailed.
  ///
  /// In en, this message translates to:
  /// **'Installation failed: {error}'**
  String installFailed(Object error);

  /// No description provided for @installLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Installation launch failed: {error}'**
  String installLaunchFailed(Object error);

  /// No description provided for @storagePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get storagePermissionTitle;

  /// No description provided for @storagePermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To download and install app updates, Easy Todo needs access to device storage.'**
  String get storagePermissionDescription;

  /// No description provided for @permissionNote.
  ///
  /// In en, this message translates to:
  /// **'Clicking \"Allow\" will grant the app the following permissions:'**
  String get permissionNote;

  /// No description provided for @accessDeviceStorage.
  ///
  /// In en, this message translates to:
  /// **'• Access device storage'**
  String get accessDeviceStorage;

  /// No description provided for @downloadFilesToDevice.
  ///
  /// In en, this message translates to:
  /// **'• Download files to device'**
  String get downloadFilesToDevice;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Storage permission has been permanently denied. Please manually enable the permission in system settings and try again.'**
  String get permissionDeniedMessage;

  /// No description provided for @cannotOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Cannot open settings page'**
  String get cannotOpenSettings;

  /// No description provided for @autoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto Update'**
  String get autoUpdate;

  /// No description provided for @autoUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for updates when app starts'**
  String get autoUpdateSubtitle;

  /// No description provided for @autoUpdateEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto update enabled'**
  String get autoUpdateEnabled;

  /// No description provided for @autoUpdateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto update disabled'**
  String get autoUpdateDisabled;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @viewSettings.
  ///
  /// In en, this message translates to:
  /// **'View Settings'**
  String get viewSettings;

  /// No description provided for @viewDisplay.
  ///
  /// In en, this message translates to:
  /// **'View Display'**
  String get viewDisplay;

  /// No description provided for @viewDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure how content is displayed'**
  String get viewDisplaySubtitle;

  /// No description provided for @todoViewSettings.
  ///
  /// In en, this message translates to:
  /// **'Todo View Settings'**
  String get todoViewSettings;

  /// No description provided for @historyViewSettings.
  ///
  /// In en, this message translates to:
  /// **'History View Settings'**
  String get historyViewSettings;

  /// No description provided for @scheduleLayoutSettings.
  ///
  /// In en, this message translates to:
  /// **'Schedule Layout Settings'**
  String get scheduleLayoutSettings;

  /// No description provided for @scheduleLayoutSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize time range and weekdays'**
  String get scheduleLayoutSettingsSubtitle;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View Mode'**
  String get viewMode;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @stackingView.
  ///
  /// In en, this message translates to:
  /// **'Stacking View'**
  String get stackingView;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'Calendar View'**
  String get calendarView;

  /// No description provided for @openInNewPage.
  ///
  /// In en, this message translates to:
  /// **'Open in New Page'**
  String get openInNewPage;

  /// No description provided for @openInNewPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open views in new pages instead of popups'**
  String get openInNewPageSubtitle;

  /// No description provided for @historyViewMode.
  ///
  /// In en, this message translates to:
  /// **'History View Mode'**
  String get historyViewMode;

  /// No description provided for @scheduleTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get scheduleTimeRange;

  /// No description provided for @scheduleVisibleWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Days Shown'**
  String get scheduleVisibleWeekdays;

  /// No description provided for @scheduleLabelTextScale.
  ///
  /// In en, this message translates to:
  /// **'Label Text Scale'**
  String get scheduleLabelTextScale;

  /// No description provided for @scheduleAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one day selected.'**
  String get scheduleAtLeastOneDay;

  /// No description provided for @dayDetails.
  ///
  /// In en, this message translates to:
  /// **'Day Details'**
  String get dayDetails;

  /// No description provided for @todoCount.
  ///
  /// In en, this message translates to:
  /// **'Todo Count'**
  String get todoCount;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completedCount;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get totalCount;

  /// No description provided for @appLongDescription.
  ///
  /// In en, this message translates to:
  /// **'Easy Todo is a clean, elegant and powerful todo list application designed to help you organize your daily tasks efficiently. With beautiful UI design, comprehensive statistics tracking, seamless API integration, and support for multiple languages, Easy Todo makes task management simple and enjoyable. Features include calendar view, history tracking, backup & restore, biometric authentication, and customizable themes to match your personal style.'**
  String get appLongDescription;

  /// No description provided for @cannotDeleteRepeatTodo.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete repeat todos'**
  String get cannotDeleteRepeatTodo;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Easy Todo'**
  String get appTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterTodayTodos.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Todos'**
  String get filterTodayTodos;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get filterThisWeek;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @repeatTaskWarning.
  ///
  /// In en, this message translates to:
  /// **'This todo item is automatically generated from a repeat task and will be regenerated tomorrow after deletion.'**
  String get repeatTaskWarning;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @repeatTaskDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat Task Todo Item'**
  String get repeatTaskDialogTitle;

  /// No description provided for @repeatTaskExplanation.
  ///
  /// In en, this message translates to:
  /// **'This todo is automatically created from a repeat task template. Deleting it will not affect the repeat task itself - a new todo will be generated tomorrow according to the repeat schedule. If you want to stop these todos from being generated, you need to edit or delete the repeat task template in the repeat tasks management section.'**
  String get repeatTaskExplanation;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @authenticateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to continue using the app'**
  String get authenticateToContinue;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Please use biometric authentication to verify your identity'**
  String get biometricReason;

  /// No description provided for @biometricHint.
  ///
  /// In en, this message translates to:
  /// **'Use biometric authentication'**
  String get biometricHint;

  /// No description provided for @biometricNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'Biometric not recognized, please try again'**
  String get biometricNotRecognized;

  /// No description provided for @biometricSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication successful'**
  String get biometricSuccess;

  /// No description provided for @biometricVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Verification'**
  String get biometricVerificationTitle;

  /// No description provided for @addTodoError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add todo: {error}'**
  String addTodoError(Object error);

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleRequired;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @repeatTaskCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create repeat task: {error}'**
  String repeatTaskCreateError(Object error);

  /// No description provided for @repeatTaskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get repeatTaskTitleRequired;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @shareBackup.
  ///
  /// In en, this message translates to:
  /// **'Share Backup'**
  String get shareBackup;

  /// No description provided for @cannotAccessFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot access selected file'**
  String get cannotAccessFile;

  /// No description provided for @invalidBackupFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup format'**
  String get invalidBackupFormat;

  /// No description provided for @importBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackupTitle;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @backupShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file shared successfully'**
  String get backupShareSuccess;

  /// No description provided for @requiredUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A required update is available. Please update to continue using the app.'**
  String get requiredUpdateAvailable;

  /// No description provided for @updateCheckError.
  ///
  /// In en, this message translates to:
  /// **'Error checking for updates: {error}'**
  String updateCheckError(Object error);

  /// No description provided for @importingBackupFile.
  ///
  /// In en, this message translates to:
  /// **'About to import backup file \"{fileName}\", this will overwrite all current data. Continue?'**
  String importingBackupFile(Object fileName);

  /// No description provided for @hardcodedStringFound.
  ///
  /// In en, this message translates to:
  /// **'即将导入备份文件 \"{fileName}\"，这将覆盖当前的所有数据。确定继续吗？'**
  String hardcodedStringFound(Object fileName);

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @testNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Test notification channel'**
  String get testNotificationChannel;

  /// No description provided for @testNotificationContent.
  ///
  /// In en, this message translates to:
  /// **'This is a test notification to verify that notifications are working properly.'**
  String get testNotificationContent;

  /// No description provided for @failedToSendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send test notification: '**
  String get failedToSendTestNotification;

  /// No description provided for @failedToCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get failedToCheckForUpdates;

  /// No description provided for @errorCheckingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Error checking for updates: '**
  String get errorCheckingForUpdates;

  /// No description provided for @updateFileName.
  ///
  /// In en, this message translates to:
  /// **'easy_todo_update.apk'**
  String get updateFileName;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @restoreSuccessPrefix.
  ///
  /// In en, this message translates to:
  /// **'Restored '**
  String get restoreSuccessPrefix;

  /// No description provided for @restoreSuccessSuffix.
  ///
  /// In en, this message translates to:
  /// **' todos'**
  String get restoreSuccessSuffix;

  /// No description provided for @importSuccessPrefix.
  ///
  /// In en, this message translates to:
  /// **'Backup file imported successfully, restored '**
  String get importSuccessPrefix;

  /// No description provided for @importFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Import failed: '**
  String get importFailedPrefix;

  /// No description provided for @cleanupFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed: '**
  String get cleanupFailedPrefix;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'梦凌汐 (MeowLynxSea)'**
  String get developerName;

  /// No description provided for @createYourFirstRepeatTask.
  ///
  /// In en, this message translates to:
  /// **'Create your first repeat task to get started'**
  String get createYourFirstRepeatTask;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get openSource;

  /// No description provided for @repeatTodoTest.
  ///
  /// In en, this message translates to:
  /// **'Repeat Todo Test'**
  String get repeatTodoTest;

  /// No description provided for @repeatTodos.
  ///
  /// In en, this message translates to:
  /// **'Repeat Todos'**
  String get repeatTodos;

  /// No description provided for @addRepeatTodo.
  ///
  /// In en, this message translates to:
  /// **'Add Repeat Todo'**
  String get addRepeatTodo;

  /// No description provided for @checkRepeatTodos.
  ///
  /// In en, this message translates to:
  /// **'Check Repeat Todos'**
  String get checkRepeatTodos;

  /// No description provided for @authenticateToAccessApp.
  ///
  /// In en, this message translates to:
  /// **'Please use fingerprint to access app'**
  String get authenticateToAccessApp;

  /// No description provided for @backupFileSubject.
  ///
  /// In en, this message translates to:
  /// **'Easy Todo Backup File'**
  String get backupFileSubject;

  /// No description provided for @shareFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Share failed: '**
  String get shareFailedPrefix;

  /// No description provided for @schedulingTodoReminder.
  ///
  /// In en, this message translates to:
  /// **'Scheduling todo reminder \"'**
  String get schedulingTodoReminder;

  /// No description provided for @todoReminderTimerScheduled.
  ///
  /// In en, this message translates to:
  /// **'Todo reminder timer scheduled successfully'**
  String get todoReminderTimerScheduled;

  /// No description provided for @allRemindersRescheduled.
  ///
  /// In en, this message translates to:
  /// **'All reminders rescheduled successfully'**
  String get allRemindersRescheduled;

  /// No description provided for @allTimersCleared.
  ///
  /// In en, this message translates to:
  /// **'All timers cleared'**
  String get allTimersCleared;

  /// No description provided for @allNotificationChannelsCreated.
  ///
  /// In en, this message translates to:
  /// **'All notification channels created successfully'**
  String get allNotificationChannelsCreated;

  /// No description provided for @utc.
  ///
  /// In en, this message translates to:
  /// **'UTC'**
  String get utc;

  /// No description provided for @gmt.
  ///
  /// In en, this message translates to:
  /// **'GMT'**
  String get gmt;

  /// No description provided for @authenticateToEnableFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to enable fingerprint lock'**
  String get authenticateToEnableFingerprint;

  /// No description provided for @authenticateToDisableFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to disable fingerprint lock'**
  String get authenticateToDisableFingerprint;

  /// No description provided for @authenticateToAccessWithFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Please use fingerprint verification to access the app'**
  String get authenticateToAccessWithFingerprint;

  /// No description provided for @authenticateToAccessWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Please use biometric verification to verify your identity to continue'**
  String get authenticateToAccessWithBiometric;

  /// No description provided for @authenticateToClearData.
  ///
  /// In en, this message translates to:
  /// **'Please use biometric authentication to clear all data'**
  String get authenticateToClearData;

  /// No description provided for @clearDataFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Clear data failed: '**
  String get clearDataFailedPrefix;

  /// No description provided for @progressFormat.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String progressFormat(Object current, Object total);

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'{hour}:{minute}'**
  String timeFormat(Object hour, Object minute);

  /// No description provided for @completedFormat.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total}'**
  String completedFormat(Object completed, Object total);

  /// No description provided for @countFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} '**
  String countFormat(Object count);

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get deleteAction;

  /// No description provided for @toggleReminderAction.
  ///
  /// In en, this message translates to:
  /// **'toggle_reminder'**
  String get toggleReminderAction;

  /// No description provided for @pomodoroAction.
  ///
  /// In en, this message translates to:
  /// **'pomodoro'**
  String get pomodoroAction;

  /// No description provided for @completedKey.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completedKey;

  /// No description provided for @totalKey.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get totalKey;

  /// No description provided for @zh.
  ///
  /// In en, this message translates to:
  /// **'zh'**
  String get zh;

  /// No description provided for @en.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get en;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String everyNDays(Object count);

  /// No description provided for @dataStatistics.
  ///
  /// In en, this message translates to:
  /// **'Data Statistics'**
  String get dataStatistics;

  /// No description provided for @dataStatisticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of repeat tasks with data statistics enabled'**
  String get dataStatisticsDescription;

  /// No description provided for @statisticsModes.
  ///
  /// In en, this message translates to:
  /// **'Statistics Modes'**
  String get statisticsModes;

  /// No description provided for @statisticsModesDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the statistical analysis methods to apply'**
  String get statisticsModesDescription;

  /// No description provided for @dataUnit.
  ///
  /// In en, this message translates to:
  /// **'Data Unit'**
  String get dataUnit;

  /// No description provided for @dataUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., kg, km, \$, %'**
  String get dataUnitHint;

  /// No description provided for @statisticsModeAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statisticsModeAverage;

  /// No description provided for @statisticsModeGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get statisticsModeGrowth;

  /// No description provided for @statisticsModeExtremum.
  ///
  /// In en, this message translates to:
  /// **'Extremum'**
  String get statisticsModeExtremum;

  /// No description provided for @statisticsModeTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get statisticsModeTrend;

  /// No description provided for @enterDataToComplete.
  ///
  /// In en, this message translates to:
  /// **'Enter Data to Complete'**
  String get enterDataToComplete;

  /// No description provided for @enterDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This repeat task requires data input before completion'**
  String get enterDataDescription;

  /// No description provided for @dataValue.
  ///
  /// In en, this message translates to:
  /// **'Data Value'**
  String get dataValue;

  /// No description provided for @dataValueHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a numerical value'**
  String get dataValueHint;

  /// No description provided for @dataValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a data value to complete this task'**
  String get dataValueRequired;

  /// No description provided for @invalidDataValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidDataValue;

  /// No description provided for @dataStatisticsTab.
  ///
  /// In en, this message translates to:
  /// **'Data Statistics'**
  String get dataStatisticsTab;

  /// No description provided for @selectRepeatTask.
  ///
  /// In en, this message translates to:
  /// **'Select Repeat Task'**
  String get selectRepeatTask;

  /// No description provided for @selectRepeatTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a repeat task to view its statistics'**
  String get selectRepeatTaskHint;

  /// No description provided for @timePeriod.
  ///
  /// In en, this message translates to:
  /// **'Time Period'**
  String get timePeriod;

  /// No description provided for @timePeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timePeriodToday;

  /// No description provided for @timePeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get timePeriodThisWeek;

  /// No description provided for @timePeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get timePeriodThisMonth;

  /// No description provided for @timePeriodOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get timePeriodOverview;

  /// No description provided for @timePeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get timePeriodCustom;

  /// No description provided for @selectCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectCustomRange;

  /// No description provided for @noRepeatTasksWithStats.
  ///
  /// In en, this message translates to:
  /// **'No repeat tasks with statistics enabled'**
  String get noRepeatTasksWithStats;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available for the selected period'**
  String get noDataAvailable;

  /// No description provided for @dataProgressToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get dataProgressToday;

  /// No description provided for @averageValue.
  ///
  /// In en, this message translates to:
  /// **'Average Value'**
  String get averageValue;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @dataPoints.
  ///
  /// In en, this message translates to:
  /// **'Data Points'**
  String get dataPoints;

  /// No description provided for @growthRate.
  ///
  /// In en, this message translates to:
  /// **'Growth Rate'**
  String get growthRate;

  /// No description provided for @trendAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Trend Analysis'**
  String get trendAnalysis;

  /// No description provided for @maximumValue.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximumValue;

  /// No description provided for @minimumValue.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimumValue;

  /// No description provided for @extremumAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Extremum Analysis'**
  String get extremumAnalysis;

  /// No description provided for @statisticsSummary.
  ///
  /// In en, this message translates to:
  /// **'Statistics Summary'**
  String get statisticsSummary;

  /// No description provided for @dataVisualization.
  ///
  /// In en, this message translates to:
  /// **'Data Visualization'**
  String get dataVisualization;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Trends'**
  String get chartTitle;

  /// No description provided for @lineChart.
  ///
  /// In en, this message translates to:
  /// **'Line Chart'**
  String get lineChart;

  /// No description provided for @barChart.
  ///
  /// In en, this message translates to:
  /// **'Bar Chart'**
  String get barChart;

  /// No description provided for @showValueOnDrag.
  ///
  /// In en, this message translates to:
  /// **'Show value when dragging on chart'**
  String get showValueOnDrag;

  /// No description provided for @dragToShowValue.
  ///
  /// In en, this message translates to:
  /// **'Drag on chart to see detailed values'**
  String get dragToShowValue;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @dataEntry.
  ///
  /// In en, this message translates to:
  /// **'Data Entry'**
  String get dataEntry;

  /// No description provided for @statisticsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Statistics Enabled'**
  String get statisticsEnabled;

  /// No description provided for @dataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get dataCollection;

  /// No description provided for @repeatTodoWithStats.
  ///
  /// In en, this message translates to:
  /// **'Repeat tasks with statistics: {count}'**
  String repeatTodoWithStats(Object count);

  /// No description provided for @dataEntries.
  ///
  /// In en, this message translates to:
  /// **'Data entries: {count}'**
  String dataEntries(Object count);

  /// No description provided for @withDataValues.
  ///
  /// In en, this message translates to:
  /// **'with values: {count}'**
  String withDataValues(Object count);

  /// No description provided for @totalDataSize.
  ///
  /// In en, this message translates to:
  /// **'Total data size: {size}'**
  String totalDataSize(Object size);

  /// No description provided for @dataBackupSupported.
  ///
  /// In en, this message translates to:
  /// **'Data backup and restore supported'**
  String get dataBackupSupported;

  /// No description provided for @repeatTasks.
  ///
  /// In en, this message translates to:
  /// **'Repeat Tasks'**
  String get repeatTasks;

  /// No description provided for @dataStatisticsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Data Statistics Enabled'**
  String get dataStatisticsEnabled;

  /// No description provided for @statisticsData.
  ///
  /// In en, this message translates to:
  /// **'Statistics Data'**
  String get statisticsData;

  /// No description provided for @dataStatisticsEnabledShort.
  ///
  /// In en, this message translates to:
  /// **'Data Stats'**
  String get dataStatisticsEnabledShort;

  /// No description provided for @dataWithValue.
  ///
  /// In en, this message translates to:
  /// **'With Values'**
  String get dataWithValue;

  /// No description provided for @noDataStatisticsEnabled.
  ///
  /// In en, this message translates to:
  /// **'No data statistics enabled'**
  String get noDataStatisticsEnabled;

  /// No description provided for @enableDataStatisticsHint.
  ///
  /// In en, this message translates to:
  /// **'Enable data statistics for repeat tasks to see analytics'**
  String get enableDataStatisticsHint;

  /// No description provided for @selectTimePeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Time Period'**
  String get selectTimePeriod;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @selectRepeatTaskToViewData.
  ///
  /// In en, this message translates to:
  /// **'Select a repeat task to view its data statistics'**
  String get selectRepeatTaskToViewData;

  /// No description provided for @noStatisticsData.
  ///
  /// In en, this message translates to:
  /// **'No statistics data available'**
  String get noStatisticsData;

  /// No description provided for @completeSomeTodosToSeeData.
  ///
  /// In en, this message translates to:
  /// **'Complete some todos with data to see statistics'**
  String get completeSomeTodosToSeeData;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get totalEntries;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @totalGrowth.
  ///
  /// In en, this message translates to:
  /// **'Total Growth'**
  String get totalGrowth;

  /// No description provided for @notEnoughDataForCharts.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for charts'**
  String get notEnoughDataForCharts;

  /// No description provided for @averageTrend.
  ///
  /// In en, this message translates to:
  /// **'Average Trend'**
  String get averageTrend;

  /// No description provided for @averageChartDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows the average values over time with trend analysis'**
  String get averageChartDescription;

  /// No description provided for @trendDirection.
  ///
  /// In en, this message translates to:
  /// **'Trend Direction'**
  String get trendDirection;

  /// No description provided for @trendStrength.
  ///
  /// In en, this message translates to:
  /// **'Trend Strength'**
  String get trendStrength;

  /// No description provided for @growthAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Growth Analysis'**
  String get growthAnalysis;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @stableTrendDescription.
  ///
  /// In en, this message translates to:
  /// **'Stable trend with minimal variation'**
  String get stableTrendDescription;

  /// No description provided for @weakTrendDescription.
  ///
  /// In en, this message translates to:
  /// **'Weak trend with some variation'**
  String get weakTrendDescription;

  /// No description provided for @moderateTrendDescription.
  ///
  /// In en, this message translates to:
  /// **'Moderate trend with clear direction'**
  String get moderateTrendDescription;

  /// No description provided for @strongTrendDescription.
  ///
  /// In en, this message translates to:
  /// **'Strong trend with significant variation'**
  String get strongTrendDescription;

  /// No description provided for @invalidNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid number format'**
  String get invalidNumberFormat;

  /// No description provided for @dataUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Data unit is required when data statistics is enabled'**
  String get dataUnitRequired;

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growth;

  /// No description provided for @extremum.
  ///
  /// In en, this message translates to:
  /// **'Extremum'**
  String get extremum;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @dataInputRequired.
  ///
  /// In en, this message translates to:
  /// **'Data input is required to complete this task'**
  String get dataInputRequired;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todayProgress;

  /// No description provided for @dataProgress.
  ///
  /// In en, this message translates to:
  /// **'Data Progress'**
  String get dataProgress;

  /// No description provided for @noDataForToday.
  ///
  /// In en, this message translates to:
  /// **'No data for today'**
  String get noDataForToday;

  /// No description provided for @weeklyDataStats.
  ///
  /// In en, this message translates to:
  /// **'Weekly Data Statistics'**
  String get weeklyDataStats;

  /// No description provided for @noDataForThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No data for this week'**
  String get noDataForThisWeek;

  /// No description provided for @daysTracked.
  ///
  /// In en, this message translates to:
  /// **'Days tracked'**
  String get daysTracked;

  /// No description provided for @monthlyDataStats.
  ///
  /// In en, this message translates to:
  /// **'Monthly Data Statistics'**
  String get monthlyDataStats;

  /// No description provided for @noDataForThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No data for this month'**
  String get noDataForThisMonth;

  /// No description provided for @customDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get customDateRange;

  /// No description provided for @allData.
  ///
  /// In en, this message translates to:
  /// **'All Data'**
  String get allData;

  /// No description provided for @breakdownByTask.
  ///
  /// In en, this message translates to:
  /// **'Breakdown by Task'**
  String get breakdownByTask;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @trendUp.
  ///
  /// In en, this message translates to:
  /// **'Upward Trend'**
  String get trendUp;

  /// No description provided for @trendDown.
  ///
  /// In en, this message translates to:
  /// **'Downward Trend'**
  String get trendDown;

  /// No description provided for @trendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable Trend'**
  String get trendStable;

  /// No description provided for @needMoreDataToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Need to collect more data to analyze'**
  String get needMoreDataToAnalyze;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @taskWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Task withdrawn'**
  String get taskWithdrawn;

  /// No description provided for @noDefaultSettings.
  ///
  /// In en, this message translates to:
  /// **'No default settings found, creating defaults'**
  String get noDefaultSettings;

  /// No description provided for @authenticateForSensitiveOperation.
  ///
  /// In en, this message translates to:
  /// **'Please use biometric authentication to verify your identity'**
  String get authenticateForSensitiveOperation;

  /// No description provided for @insufficientData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get insufficientData;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @strongUpward.
  ///
  /// In en, this message translates to:
  /// **'Strong upward'**
  String get strongUpward;

  /// No description provided for @upward.
  ///
  /// In en, this message translates to:
  /// **'Upward'**
  String get upward;

  /// No description provided for @strongDownward.
  ///
  /// In en, this message translates to:
  /// **'Strong downward'**
  String get strongDownward;

  /// No description provided for @downward.
  ///
  /// In en, this message translates to:
  /// **'Downward'**
  String get downward;

  /// No description provided for @repeatTasksRefreshedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Repeat tasks refreshed successfully'**
  String get repeatTasksRefreshedSuccessfully;

  /// No description provided for @errorRefreshingRepeatTasks.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing repeat tasks'**
  String get errorRefreshingRepeatTasks;

  /// No description provided for @forceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Force refresh'**
  String get forceRefresh;

  /// No description provided for @errorLoadingRepeatTasks.
  ///
  /// In en, this message translates to:
  /// **'Error loading repeat tasks'**
  String get errorLoadingRepeatTasks;

  /// No description provided for @pleaseCheckStoragePermissions.
  ///
  /// In en, this message translates to:
  /// **'Please check your storage permissions and try again'**
  String get pleaseCheckStoragePermissions;

  /// No description provided for @todoReminders.
  ///
  /// In en, this message translates to:
  /// **'Todo Reminders'**
  String get todoReminders;

  /// No description provided for @notificationsForIndividualTodoReminders.
  ///
  /// In en, this message translates to:
  /// **'Notifications for individual todo reminders'**
  String get notificationsForIndividualTodoReminders;

  /// No description provided for @notificationsForDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily summary of pending todos'**
  String get notificationsForDailySummary;

  /// No description provided for @pomodoroComplete.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Complete'**
  String get pomodoroComplete;

  /// No description provided for @notificationsForPomodoroSessions.
  ///
  /// In en, this message translates to:
  /// **'Notifications when pomodoro sessions are completed'**
  String get notificationsForPomodoroSessions;

  /// No description provided for @dailyTodoSummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Todo Summary'**
  String get dailyTodoSummary;

  /// No description provided for @youHavePendingTodos.
  ///
  /// In en, this message translates to:
  /// **'You have {count} pending todo{s} to complete'**
  String youHavePendingTodos(Object count, Object n, Object s);

  /// No description provided for @greatJobTimeForBreak.
  ///
  /// In en, this message translates to:
  /// **'Great job! Time for a {breakType} break'**
  String greatJobTimeForBreak(Object breakType);

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'short'**
  String get shortBreak;

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'long'**
  String get longBreak;

  /// No description provided for @themeColorMysteriousPurple.
  ///
  /// In en, this message translates to:
  /// **'Mysterious Purple'**
  String get themeColorMysteriousPurple;

  /// No description provided for @themeColorSkyBlue.
  ///
  /// In en, this message translates to:
  /// **'Sky Blue'**
  String get themeColorSkyBlue;

  /// No description provided for @themeColorGemGreen.
  ///
  /// In en, this message translates to:
  /// **'Gem Green'**
  String get themeColorGemGreen;

  /// No description provided for @themeColorLemonYellow.
  ///
  /// In en, this message translates to:
  /// **'Lemon Yellow'**
  String get themeColorLemonYellow;

  /// No description provided for @themeColorFlameRed.
  ///
  /// In en, this message translates to:
  /// **'Flame Red'**
  String get themeColorFlameRed;

  /// No description provided for @themeColorElegantPurple.
  ///
  /// In en, this message translates to:
  /// **'Elegant Purple'**
  String get themeColorElegantPurple;

  /// No description provided for @themeColorCherryPink.
  ///
  /// In en, this message translates to:
  /// **'Cherry Pink'**
  String get themeColorCherryPink;

  /// No description provided for @themeColorForestCyan.
  ///
  /// In en, this message translates to:
  /// **'Forest Cyan'**
  String get themeColorForestCyan;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get aiSettings;

  /// No description provided for @aiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get aiFeatures;

  /// No description provided for @aiEnabled.
  ///
  /// In en, this message translates to:
  /// **'AI features enabled'**
  String get aiEnabled;

  /// No description provided for @aiDisabled.
  ///
  /// In en, this message translates to:
  /// **'AI features disabled'**
  String get aiDisabled;

  /// No description provided for @enableAIFeatures.
  ///
  /// In en, this message translates to:
  /// **'Enable AI Features'**
  String get enableAIFeatures;

  /// No description provided for @enableAIFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use artificial intelligence to enhance your todo experience'**
  String get enableAIFeaturesSubtitle;

  /// No description provided for @apiConfiguration.
  ///
  /// In en, this message translates to:
  /// **'API Configuration'**
  String get apiConfiguration;

  /// No description provided for @apiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'API Endpoint'**
  String get apiEndpoint;

  /// No description provided for @pleaseEnterApiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Please enter API endpoint'**
  String get pleaseEnterApiEndpoint;

  /// No description provided for @invalidApiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid API endpoint'**
  String get invalidApiEndpoint;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @pleaseEnterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter API key'**
  String get pleaseEnterApiKey;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// No description provided for @pleaseEnterModelName.
  ///
  /// In en, this message translates to:
  /// **'Please enter model name'**
  String get pleaseEnterModelName;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms)'**
  String get timeout;

  /// No description provided for @pleaseEnterTimeout.
  ///
  /// In en, this message translates to:
  /// **'Please enter timeout'**
  String get pleaseEnterTimeout;

  /// No description provided for @invalidTimeout.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid timeout (minimum 1000ms)'**
  String get invalidTimeout;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @pleaseEnterTemperature.
  ///
  /// In en, this message translates to:
  /// **'Please enter temperature'**
  String get pleaseEnterTemperature;

  /// No description provided for @invalidTemperature.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid temperature (0.0 - 2.0)'**
  String get invalidTemperature;

  /// No description provided for @maxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get maxTokens;

  /// No description provided for @pleaseEnterMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Please enter max tokens'**
  String get pleaseEnterMaxTokens;

  /// No description provided for @invalidMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid max tokens (minimum 1)'**
  String get invalidMaxTokens;

  /// No description provided for @rateLimit.
  ///
  /// In en, this message translates to:
  /// **'Rate Limit'**
  String get rateLimit;

  /// No description provided for @rateLimitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum requests per minute'**
  String get rateLimitSubtitle;

  /// No description provided for @pleaseEnterRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Please enter rate limit'**
  String get pleaseEnterRateLimit;

  /// No description provided for @invalidRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Rate limit must be between 1 and 100'**
  String get invalidRateLimit;

  /// No description provided for @rateAndTokenLimits.
  ///
  /// In en, this message translates to:
  /// **'Rate & Token Limits'**
  String get rateAndTokenLimits;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @aiFeaturesToggle.
  ///
  /// In en, this message translates to:
  /// **'AI Features Toggle'**
  String get aiFeaturesToggle;

  /// No description provided for @autoCategorization.
  ///
  /// In en, this message translates to:
  /// **'Auto Categorization'**
  String get autoCategorization;

  /// No description provided for @autoCategorizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically categorize your tasks'**
  String get autoCategorizationSubtitle;

  /// No description provided for @prioritySorting.
  ///
  /// In en, this message translates to:
  /// **'Priority Sorting'**
  String get prioritySorting;

  /// No description provided for @prioritySortingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assess task importance and priority'**
  String get prioritySortingSubtitle;

  /// No description provided for @motivationalMessages.
  ///
  /// In en, this message translates to:
  /// **'Motivational Messages'**
  String get motivationalMessages;

  /// No description provided for @motivationalMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate encouraging messages based on your progress'**
  String get motivationalMessagesSubtitle;

  /// No description provided for @smartNotifications.
  ///
  /// In en, this message translates to:
  /// **'Smart Notifications'**
  String get smartNotifications;

  /// No description provided for @smartNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create personalized notification content'**
  String get smartNotificationsSubtitle;

  /// No description provided for @completionMotivation.
  ///
  /// In en, this message translates to:
  /// **'Completion Motivation'**
  String get completionMotivation;

  /// No description provided for @completionMotivationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show motivation based on daily completion rate'**
  String get completionMotivationSubtitle;

  /// No description provided for @aiCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get aiCategoryWork;

  /// No description provided for @aiCategoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get aiCategoryPersonal;

  /// No description provided for @aiCategoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get aiCategoryStudy;

  /// No description provided for @aiCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get aiCategoryHealth;

  /// No description provided for @aiCategoryFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get aiCategoryFitness;

  /// No description provided for @aiCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get aiCategoryFinance;

  /// No description provided for @aiCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get aiCategoryShopping;

  /// No description provided for @aiCategoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get aiCategoryFamily;

  /// No description provided for @aiCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get aiCategorySocial;

  /// No description provided for @aiCategoryHobby.
  ///
  /// In en, this message translates to:
  /// **'Hobby'**
  String get aiCategoryHobby;

  /// No description provided for @aiCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get aiCategoryTravel;

  /// No description provided for @aiCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get aiCategoryOther;

  /// No description provided for @aiPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get aiPriorityHigh;

  /// No description provided for @aiPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get aiPriorityMedium;

  /// No description provided for @aiPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get aiPriorityLow;

  /// No description provided for @aiPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get aiPriorityUrgent;

  /// No description provided for @aiPriorityImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get aiPriorityImportant;

  /// No description provided for @aiPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get aiPriorityNormal;

  /// No description provided for @selectTodoForPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Select a Todo'**
  String get selectTodoForPomodoro;

  /// No description provided for @pomodoroDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a todo item to start your Pomodoro focus session'**
  String get pomodoroDescription;

  /// No description provided for @noTodosForPomodoro.
  ///
  /// In en, this message translates to:
  /// **'No available todos'**
  String get noTodosForPomodoro;

  /// No description provided for @createTodoForPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Please create some todos first'**
  String get createTodoForPomodoro;

  /// No description provided for @todaySessions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sessions'**
  String get todaySessions;

  /// No description provided for @startPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Start Pomodoro'**
  String get startPomodoro;

  /// No description provided for @aiDebugInfo.
  ///
  /// In en, this message translates to:
  /// **'AI Debug Info'**
  String get aiDebugInfo;

  /// No description provided for @processingUnprocessedTodos.
  ///
  /// In en, this message translates to:
  /// **'Processing unprocessed todos with AI'**
  String get processingUnprocessedTodos;

  /// No description provided for @processAllTodosWithAI.
  ///
  /// In en, this message translates to:
  /// **'Process All Todos with AI'**
  String get processAllTodosWithAI;

  /// No description provided for @todayTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayTimeFormat(Object time);

  /// No description provided for @tomorrowTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow {time}'**
  String tomorrowTimeFormat(Object time);

  /// No description provided for @deleteTodoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTodoDialogTitle;

  /// No description provided for @deleteTodoDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this todo?'**
  String get deleteTodoDialogMessage;

  /// No description provided for @deleteTodoDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteTodoDialogCancel;

  /// No description provided for @deleteTodoDialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTodoDialogDelete;

  /// No description provided for @customPersona.
  ///
  /// In en, this message translates to:
  /// **'Custom Persona'**
  String get customPersona;

  /// No description provided for @personaPrompt.
  ///
  /// In en, this message translates to:
  /// **'Persona Prompt'**
  String get personaPrompt;

  /// No description provided for @personaPromptHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., You are a friendly assistant who uses humor and emojis...'**
  String get personaPromptHint;

  /// No description provided for @personaPromptDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize the AI\'s personality for notifications. This will be applied to both todo reminders and daily summaries.'**
  String get personaPromptDescription;

  /// No description provided for @personaExample1.
  ///
  /// In en, this message translates to:
  /// **'You are a motivating coach who encourages with positive reinforcement'**
  String get personaExample1;

  /// No description provided for @personaExample2.
  ///
  /// In en, this message translates to:
  /// **'You are a humorous assistant who uses light humor and emojis'**
  String get personaExample2;

  /// No description provided for @personaExample3.
  ///
  /// In en, this message translates to:
  /// **'You are a professional productivity expert who gives concise advice'**
  String get personaExample3;

  /// No description provided for @personaExample4.
  ///
  /// In en, this message translates to:
  /// **'You are a supportive friend who reminds with warmth and care'**
  String get personaExample4;

  /// No description provided for @aiDebugInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Debug Info'**
  String get aiDebugInfoTitle;

  /// No description provided for @aiDebugInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check AI functionality status'**
  String get aiDebugInfoSubtitle;

  /// No description provided for @aiSettingsStatus.
  ///
  /// In en, this message translates to:
  /// **'AI Settings Status'**
  String get aiSettingsStatus;

  /// No description provided for @aiFeatureToggles.
  ///
  /// In en, this message translates to:
  /// **'AI Feature Toggles'**
  String get aiFeatureToggles;

  /// No description provided for @aiTodoProviderConnection.
  ///
  /// In en, this message translates to:
  /// **'Todo Provider Connection'**
  String get aiTodoProviderConnection;

  /// No description provided for @aiMessages.
  ///
  /// In en, this message translates to:
  /// **'AI Messages'**
  String get aiMessages;

  /// No description provided for @aiApiRequestManager.
  ///
  /// In en, this message translates to:
  /// **'API Request Manager'**
  String get aiApiRequestManager;

  /// No description provided for @aiCurrentRequestQueue.
  ///
  /// In en, this message translates to:
  /// **'Current Request Queue'**
  String get aiCurrentRequestQueue;

  /// No description provided for @aiRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent Requests'**
  String get aiRecentRequests;

  /// No description provided for @aiPermissionRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable \"Alarms & Reminders\" permission for \"Easy Todo\" in system settings.'**
  String get aiPermissionRequestMessage;

  /// No description provided for @developerNameMeowLynxSea.
  ///
  /// In en, this message translates to:
  /// **'梦凌汐 (MeowLynxSea)'**
  String get developerNameMeowLynxSea;

  /// No description provided for @developerEmail.
  ///
  /// In en, this message translates to:
  /// **'mew@meowdream.cn'**
  String get developerEmail;

  /// No description provided for @developerGithub.
  ///
  /// In en, this message translates to:
  /// **'github.com/MeowLynxSea'**
  String get developerGithub;

  /// No description provided for @developerWebsite.
  ///
  /// In en, this message translates to:
  /// **'www.meowdream.cn'**
  String get developerWebsite;

  /// No description provided for @backupFileShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Easy Todo Backup File'**
  String get backupFileShareSubject;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String shareFailed(Object error);

  /// No description provided for @authenticateToAccessAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Please use fingerprint to access app'**
  String get authenticateToAccessAppMessage;

  /// No description provided for @aiFeaturesEnabled.
  ///
  /// In en, this message translates to:
  /// **'AI Features Enabled'**
  String get aiFeaturesEnabled;

  /// No description provided for @aiServiceValid.
  ///
  /// In en, this message translates to:
  /// **'AI Service Valid'**
  String get aiServiceValid;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured ({count} chars)'**
  String configured(Object count);

  /// No description provided for @aiProviderConnected.
  ///
  /// In en, this message translates to:
  /// **'AI Provider Connected'**
  String get aiProviderConnected;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @aiProcessedTodos.
  ///
  /// In en, this message translates to:
  /// **'AI Processed Todos'**
  String get aiProcessedTodos;

  /// No description provided for @todosWithAICategory.
  ///
  /// In en, this message translates to:
  /// **'Todos with AI Category'**
  String get todosWithAICategory;

  /// No description provided for @todosWithAIPriority.
  ///
  /// In en, this message translates to:
  /// **'Todos with AI Priority'**
  String get todosWithAIPriority;

  /// No description provided for @lastError.
  ///
  /// In en, this message translates to:
  /// **'Last Error'**
  String get lastError;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @currentWindowRequests.
  ///
  /// In en, this message translates to:
  /// **'Current Window Requests'**
  String get currentWindowRequests;

  /// No description provided for @maxRequestsPerMinute.
  ///
  /// In en, this message translates to:
  /// **'Max Requests/Minute'**
  String get maxRequestsPerMinute;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @aiServiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'AI Service not available'**
  String get aiServiceNotAvailable;

  /// No description provided for @completionMessages.
  ///
  /// In en, this message translates to:
  /// **'Completion Messages'**
  String get completionMessages;

  /// No description provided for @exactAlarmPermission.
  ///
  /// In en, this message translates to:
  /// **'Exact Alarm Permission'**
  String get exactAlarmPermission;

  /// No description provided for @exactAlarmPermissionContent.
  ///
  /// In en, this message translates to:
  /// **'To ensure pomodoro and reminder functions work accurately, the app needs exact alarm permission.\n\nPlease enable \"Alarms & Reminders\" permission for \"Easy Todo\" in system settings.'**
  String get exactAlarmPermissionContent;

  /// No description provided for @setLater.
  ///
  /// In en, this message translates to:
  /// **'Set Later'**
  String get setLater;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @batteryOptimizationSettings.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization Settings'**
  String get batteryOptimizationSettings;

  /// No description provided for @batteryOptimizationContent.
  ///
  /// In en, this message translates to:
  /// **'To ensure pomodoro and reminder functions run properly in the background, please disable battery optimization for this app.\n\nThis may increase some battery consumption, but ensures timers and reminder functions work accurately.'**
  String get batteryOptimizationContent;

  /// No description provided for @breakTimeComplete.
  ///
  /// In en, this message translates to:
  /// **'Break Time Complete!'**
  String get breakTimeComplete;

  /// No description provided for @timeToGetBackToWork.
  ///
  /// In en, this message translates to:
  /// **'Time to get back to work!'**
  String get timeToGetBackToWork;

  /// No description provided for @aiServiceReturnedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'AI service returned empty message'**
  String get aiServiceReturnedEmptyMessage;

  /// No description provided for @errorGeneratingMotivationalMessage.
  ///
  /// In en, this message translates to:
  /// **'Error generating motivational message: {error}'**
  String errorGeneratingMotivationalMessage(Object error);

  /// No description provided for @aiServiceNotAvailableCheckSettings.
  ///
  /// In en, this message translates to:
  /// **'AI service not available, please check AI settings'**
  String get aiServiceNotAvailableCheckSettings;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// No description provided for @importance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importance;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @aiWillCategorizeTasks.
  ///
  /// In en, this message translates to:
  /// **'AI will automatically categorize tasks, please try again later'**
  String get aiWillCategorizeTasks;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategories;

  /// No description provided for @selectedCategories.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedCategories;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'categories'**
  String get categories;

  /// No description provided for @apiFormat.
  ///
  /// In en, this message translates to:
  /// **'API Format'**
  String get apiFormat;

  /// No description provided for @apiFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your AI service provider. Different providers may require different API endpoints and authentication methods.'**
  String get apiFormatDescription;

  /// No description provided for @openaiFormat.
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get openaiFormat;

  /// No description provided for @anthropicFormat.
  ///
  /// In en, this message translates to:
  /// **'Anthropic'**
  String get anthropicFormat;

  /// No description provided for @aiPromptCategorization.
  ///
  /// In en, this message translates to:
  /// **'Categorize this todo task into one of these categories:\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n\n      Task: \"{title}\"\n      Description: \"{description}\"\n\n      Respond with only the category name in lowercase.'**
  String aiPromptCategorization(Object description, Object title);

  /// No description provided for @aiPromptPriority.
  ///
  /// In en, this message translates to:
  /// **'Rate the priority of this todo task from 0-100, considering:\n      - Urgency: How soon is it needed? (deadline: {deadline})\n      - Impact: What are the consequences of not completing it?\n      - Effort: How much time/resources will it require?\n      - Personal importance: How valuable is this to you?\n\n      Task: \"{title}\"\n      Description: \"{description}\"\n      Has deadline: {hasDeadline}\n      Deadline: {deadline}\n\n      Guidelines:\n      - 0-20: Low priority, can be postponed\n      - 21-40: Moderate priority, should be done soon\n      - 41-70: High priority, important to complete\n      - 71-100: Critical priority, urgent completion needed\n\n      Respond with only a number from 0-100.'**
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  );

  /// No description provided for @aiPromptMotivation.
  ///
  /// In en, this message translates to:
  /// **'Generate a motivational message based on this statistics data:\n      Name: \"{name}\"\n      Description: \"{description}\"\n      Value: {value}\n      Unit: \"{unit}\"\n      Date: {date}\n\n      Requirements:\n      - Make it encouraging and data-specific\n      - Keep it under 25 characters\n      - Focus on achievement and progress\n      - Use positive, action-oriented language\n      - Example: \"Great progress today! 🎯\" or \"Keep it up! 💪\"\n      - Respond with only the message, no explanations'**
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  );

  /// No description provided for @aiPromptNotification.
  ///
  /// In en, this message translates to:
  /// **'Create a personalized notification reminder for this task:\n      Task: \"{title}\"\n      Description: \"{description}\"\n      Category: {category}\n      Priority: {priority}\n\n      Requirements:\n      - Create both a title and message\n      - Title: Must be under 20 characters, attention-grabbing\n      - Message: Must be under 50 characters, motivating and actionable\n      - Use emojis where appropriate for engagement\n      - Include urgency based on priority level\n      - Make it personal and encouraging\n      - Respond ONLY in this exact format:\nTITLE: [your title]\nMESSAGE: [your message]\n      - No explanations, no markdown formatting, just the two lines in the specified format'**
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  );

  /// No description provided for @aiPromptCompletion.
  ///
  /// In en, this message translates to:
  /// **'Generate an encouraging message based on today\'s todo completion:\n      Completed: {completed} out of {total} tasks\n      Completion rate: {percentage}%\n\n      Requirements:\n      - Make it positive and motivating\n      - Keep it under 25 characters\n      - Celebrate achievement and progress\n      - Use encouraging language and/or emojis\n      - Example: \"Awesome work! 🌟\" or \"Progress! 👍\"\n      - Respond with only the message, no explanations'**
  String aiPromptCompletion(Object completed, Object percentage, Object total);

  /// No description provided for @aiPromptDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Create a daily summary notification for pending todos.\n\nPending tasks count: {pendingCount}\nCategories: {categories}\nAverage priority: {avgPriority}/100\n\nCreate a personalized summary with:\n1. A catchy title (first line)\n2. An encouraging message that MUST include the count of unfinished todos ({pendingCount})\n3. Keep the message content under 50 characters. Make it motivating and actionable.\n4. Respond ONLY in this exact format:\nTITLE: [your title]\nMESSAGE: [your message]\n5. No explanations, no markdown formatting, just the two lines in the specified format'**
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  );

  /// No description provided for @aiPromptPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Create a personalized notification for a completed {sessionType} session.\n\nSession details:\n- Task: \"{taskTitle}\"\n- Session type: {sessionType}\n- Duration: {duration} minutes\n- Completed: {isCompleted}\n\nIMPORTANT: Respond in the same language as this prompt (English).\n\nCreate both a title and message:\n1. Title: Must be under 20 characters, attention-grabbing and celebratory\n2. Message: Must be under 50 characters, encouraging and relevant to the session completion\n3. For focus sessions (work completed): Emphasize work accomplishment and that it\'s time for a well-deserved break\n4. For break sessions (rest completed): Focus on rest completion and that it\'s time to get back to focused work\n5. Use emojis where appropriate for engagement\n6. Make it personal and motivating\n7. Respond with only the title and message in the specified format, no explanations\n\nFormat your response as:\nTITLE: [title]\nMESSAGE: [message]'**
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  );

  /// No description provided for @cloudSyncAuthProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get cloudSyncAuthProcessingTitle;

  /// No description provided for @cloudSyncAuthProcessingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Processing login callback…'**
  String get cloudSyncAuthProcessingSubtitle;

  /// No description provided for @cloudSyncChangePassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Change passphrase'**
  String get cloudSyncChangePassphraseTitle;

  /// No description provided for @cloudSyncChangePassphraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-wrap the DEK only (no re-upload of history)'**
  String get cloudSyncChangePassphraseSubtitle;

  /// No description provided for @cloudSyncChangePassphraseAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get cloudSyncChangePassphraseAction;

  /// No description provided for @cloudSyncChangePassphraseDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change sync passphrase'**
  String get cloudSyncChangePassphraseDialogTitle;

  /// No description provided for @cloudSyncChangePassphraseDialogHint.
  ///
  /// In en, this message translates to:
  /// **'This only updates the key bundle. Other devices may need to enter the new passphrase to unlock.'**
  String get cloudSyncChangePassphraseDialogHint;

  /// No description provided for @cloudSyncCurrentPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Current passphrase'**
  String get cloudSyncCurrentPassphrase;

  /// No description provided for @cloudSyncNewPassphrase.
  ///
  /// In en, this message translates to:
  /// **'New passphrase'**
  String get cloudSyncNewPassphrase;

  /// No description provided for @cloudSyncPassphraseChangedSnack.
  ///
  /// In en, this message translates to:
  /// **'Passphrase updated'**
  String get cloudSyncPassphraseChangedSnack;

  /// No description provided for @syncAiApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync API key (encrypted)'**
  String get syncAiApiKeyTitle;

  /// No description provided for @syncAiApiKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your API key across devices via end-to-end encryption (optional)'**
  String get syncAiApiKeySubtitle;

  /// No description provided for @syncAiApiKeyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync API key?'**
  String get syncAiApiKeyWarningTitle;

  /// No description provided for @syncAiApiKeyWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Your API key will be uploaded as ciphertext and can be decrypted by devices with your sync passphrase. Enable only if you understand the risk.'**
  String get syncAiApiKeyWarningMessage;

  /// No description provided for @cloudSyncAutoSyncIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto sync interval'**
  String get cloudSyncAutoSyncIntervalTitle;

  /// No description provided for @cloudSyncAutoSyncIntervalHint.
  ///
  /// In en, this message translates to:
  /// **'Polling is device-specific. If there are pending local changes, they may sync sooner via the outbox trigger.'**
  String get cloudSyncAutoSyncIntervalHint;

  /// No description provided for @cloudSyncAutoSyncIntervalSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get cloudSyncAutoSyncIntervalSecondsLabel;

  /// No description provided for @cloudSyncAutoSyncIntervalMinHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum 30 seconds'**
  String get cloudSyncAutoSyncIntervalMinHint;

  /// No description provided for @cloudSyncAutoSyncIntervalSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Auto sync interval saved'**
  String get cloudSyncAutoSyncIntervalSavedSnack;

  /// No description provided for @cloudSyncAutoSyncIntervalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current: {interval}'**
  String cloudSyncAutoSyncIntervalSubtitle(Object interval);

  /// No description provided for @cloudSyncSecondsFormat.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String cloudSyncSecondsFormat(Object count);

  /// No description provided for @cloudSyncMinutesFormat.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String cloudSyncMinutesFormat(Object count);

  /// No description provided for @cloudSyncMinutesSecondsFormat.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String cloudSyncMinutesSecondsFormat(Object minutes, Object seconds);

  /// No description provided for @todoAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get todoAttachments;

  /// No description provided for @todoAttachmentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get todoAttachmentsEmpty;

  /// No description provided for @todoAttachmentAdd.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get todoAttachmentAdd;

  /// No description provided for @todoAttachmentAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add attachment: {error}'**
  String todoAttachmentAddFailed(Object error);

  /// No description provided for @todoAttachmentExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get todoAttachmentExport;

  /// No description provided for @todoAttachmentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'File not available yet'**
  String get todoAttachmentNotAvailable;

  /// No description provided for @todoAttachmentRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment?'**
  String get todoAttachmentRemoveConfirmTitle;

  /// No description provided for @todoAttachmentRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the attachment from all devices after sync.'**
  String get todoAttachmentRemoveConfirmMessage;

  /// No description provided for @todoAttachmentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get todoAttachmentUploading;

  /// No description provided for @todoAttachmentDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get todoAttachmentDownloading;

  /// No description provided for @todoAttachmentReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get todoAttachmentReady;

  /// No description provided for @todoAttachmentPreviewUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Preview is not available for this file type'**
  String get todoAttachmentPreviewUnsupported;

  /// No description provided for @todoAttachmentPreviewTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large to preview (max: {maxSize})'**
  String todoAttachmentPreviewTooLarge(Object maxSize);

  /// No description provided for @todoAttachmentMarkdownRendered.
  ///
  /// In en, this message translates to:
  /// **'Rendered'**
  String get todoAttachmentMarkdownRendered;

  /// No description provided for @todoAttachmentMarkdownSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get todoAttachmentMarkdownSource;

  /// No description provided for @todoAttachmentWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Attachments are not supported on web'**
  String get todoAttachmentWebNotSupported;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

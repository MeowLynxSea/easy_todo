// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get preferences => '設定';

  @override
  String get appSettings => 'アプリ設定';

  @override
  String get notifications => '通知';

  @override
  String get notificationsSubtitle => '通知設定を管理';

  @override
  String get theme => 'テーマ';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get systemTheme => 'システム';

  @override
  String get language => '言語';

  @override
  String get languageSettings =>
      '言語設定では、アプリの表示言語を変更できます。上記のリストから希望する言語を選択してください。';

  @override
  String get dataStorage => 'データとストレージ';

  @override
  String get dataAndSync => 'データと同期';

  @override
  String get cloudSync => 'クラウド同期';

  @override
  String get cloudSyncSubtitle => 'エンドツーエンド暗号化';

  @override
  String get cloudSyncOverviewTitle => 'E2EE 同期';

  @override
  String get cloudSyncOverviewSubtitle =>
      'サーバーは暗号文のみ保存します。この端末でパスフレーズを使って解除してください。';

  @override
  String get cloudSyncConfigSaved => '同期設定を保存しました';

  @override
  String get cloudSyncServerOkSnack => 'サーバーに接続できました';

  @override
  String get cloudSyncServerCheckFailedSnack => 'サーバー確認に失敗しました';

  @override
  String get cloudSyncDisabledSnack => '同期を無効化しました';

  @override
  String get cloudSyncEnableSwitchTitle => 'クラウド同期を有効化';

  @override
  String get cloudSyncEnableSwitchSubtitle => 'ガイド付き設定：サーバー + パスフレーズ';

  @override
  String get cloudSyncServerSection => 'サーバー';

  @override
  String get cloudSyncSetupTitle => '1）サーバー設定';

  @override
  String get cloudSyncSetupSubtitle => 'サーバーURL を設定し、プロバイダーを選択してログインします。';

  @override
  String get cloudSyncSetupDialogTitle => 'サーバー設定';

  @override
  String get cloudSyncServerUrl => 'サーバーURL';

  @override
  String get cloudSyncServerUrlHint => 'http://127.0.0.1:8787';

  @override
  String get cloudSyncAuthProvider => 'OAuth プロバイダー';

  @override
  String get cloudSyncAuthProviderHint => 'linuxdo';

  @override
  String get cloudSyncAuthMode => '認証';

  @override
  String get cloudSyncAuthModeLoggedIn => 'ログイン済み';

  @override
  String get cloudSyncAuthModeLoggedOut => '未ログイン';

  @override
  String get cloudSyncCheckServer => 'サーバー確認';

  @override
  String get cloudSyncEditServerConfig => '編集';

  @override
  String get cloudSyncLogin => 'ログイン';

  @override
  String get cloudSyncLogout => 'ログアウト';

  @override
  String get cloudSyncLoggedInSnack => 'ログインしました';

  @override
  String get cloudSyncLoggedOutSnack => 'ログアウトしました';

  @override
  String get cloudSyncLoginRedirectedSnack => 'ブラウザでログインを続行してください';

  @override
  String get cloudSyncLoginFailedSnack => 'ログインに失敗しました';

  @override
  String get cloudSyncNotSet => '未設定';

  @override
  String get cloudSyncTokenSet => '設定済み';

  @override
  String get cloudSyncStatusSection => '状態';

  @override
  String get cloudSyncEnabled => '有効';

  @override
  String get cloudSyncUnlocked => 'ロック解除済み';

  @override
  String get cloudSyncEnabledOn => '有効：オン';

  @override
  String get cloudSyncEnabledOff => '有効：オフ';

  @override
  String get cloudSyncUnlockedYes => '解除：はい';

  @override
  String get cloudSyncUnlockedNo => '解除：いいえ';

  @override
  String get cloudSyncConfiguredYes => '設定済み：はい';

  @override
  String get cloudSyncConfiguredNo => '設定済み：いいえ';

  @override
  String get cloudSyncLastServerSeq => '前回の serverSeq';

  @override
  String get cloudSyncDekId => 'DEK ID';

  @override
  String get cloudSyncLastSyncAt => '前回の同期';

  @override
  String get cloudSyncError => 'エラー';

  @override
  String get cloudSyncDeviceId => '端末 ID';

  @override
  String get cloudSyncEnable => '有効化';

  @override
  String get cloudSyncUnlock => 'ロック解除';

  @override
  String get cloudSyncSyncNow => '今すぐ同期';

  @override
  String get cloudSyncDisable => '無効化';

  @override
  String get cloudSyncSecurityTitle => '2）ロック解除';

  @override
  String get cloudSyncSecuritySubtitle =>
      'ロック解除はパスフレーズで DEK を取得します。モバイル/デスクトップは安全に保存できます。';

  @override
  String get cloudSyncLockStateTitle => '暗号鍵';

  @override
  String get cloudSyncLockStateUnlocked => 'この端末で解除済み';

  @override
  String get cloudSyncLockStateLocked => 'ロック中 — パスフレーズを入力';

  @override
  String get cloudSyncActionsTitle => '3）同期';

  @override
  String get cloudSyncActionsSubtitle => 'ローカル変更を送信し、リモート更新を取得します。';

  @override
  String get cloudSyncAdvancedTitle => '詳細';

  @override
  String get cloudSyncAdvancedSubtitle => 'デバッグ情報（端末ローカル）';

  @override
  String get cloudSyncEnableDialogTitle => '同期を有効化';

  @override
  String get cloudSyncUnlockDialogTitle => '同期をロック解除';

  @override
  String get cloudSyncPassphraseDialogHint =>
      '他の端末で同期を有効化済みの場合は、同じパスフレーズを2回入力してください。';

  @override
  String get cloudSyncPassphrase => 'パスフレーズ';

  @override
  String get cloudSyncConfirmPassphrase => 'パスフレーズを確認';

  @override
  String get cloudSyncShowPassphrase => '表示';

  @override
  String get cloudSyncEnabledSnack => '同期を有効化しました';

  @override
  String get cloudSyncUnlockedSnack => 'ロック解除しました';

  @override
  String get cloudSyncSyncedSnack => '同期しました';

  @override
  String get cloudSyncInvalidPassphrase => 'パスフレーズが正しくありません';

  @override
  String get cloudSyncRollbackTitle => 'サーバーのロールバックの可能性';

  @override
  String get cloudSyncRollbackMessage =>
      'サーバーがロールバック、またはバックアップから復元された可能性があります。続行するとデータが失われる場合があります。どうしますか？';

  @override
  String get cloudSyncStopSync => '同期を停止';

  @override
  String get cloudSyncContinue => '続行';

  @override
  String get cloudSyncWebDekNote =>
      'Web は DEK をセッション内のみキャッシュします。再読み込み後は再度ロック解除が必要です。';

  @override
  String get cloudSyncStatusIdle => '待機中';

  @override
  String get cloudSyncStatusRunning => '同期中';

  @override
  String get cloudSyncStatusError => 'エラー';

  @override
  String get cloudSyncErrorPassphraseMismatch => 'パスフレーズが一致しません';

  @override
  String get cloudSyncErrorNotConfigured => '同期が設定されていません';

  @override
  String get cloudSyncErrorDisabled => '同期は無効です';

  @override
  String get cloudSyncErrorLocked => '同期がロックされています（DEK 不足）';

  @override
  String get cloudSyncErrorAccountChanged => 'アカウントが変更されました。同期を再度有効にしてください';

  @override
  String get cloudSyncErrorUnauthorized => '認証されていません（トークンを確認）';

  @override
  String get cloudSyncErrorBanned => 'アカウントが凍結されています';

  @override
  String get cloudSyncErrorKeyBundleNotFound => 'サーバーに keyBundle が見つかりません';

  @override
  String get cloudSyncErrorNetwork => 'ネットワークエラー';

  @override
  String get cloudSyncErrorConflict => '競合（bundleVersion 不一致）';

  @override
  String get cloudSyncErrorQuotaExceeded => 'サーバーのクォータを超えました（一部のレコードが拒否されました）';

  @override
  String get cloudSyncErrorUnknown => '不明なエラー';

  @override
  String get backupRestore => 'バックアップと復元';

  @override
  String get backupSubtitle => 'データをバックアップ';

  @override
  String get storage => 'ストレージ';

  @override
  String get storageSubtitle => 'ストレージ容量を管理';

  @override
  String get about => 'について';

  @override
  String get aboutEasyTodo => 'Easy Todo について';

  @override
  String get helpSupport => 'ヘルプとサポート';

  @override
  String get helpSubtitle => 'アプリのヘルプを取得';

  @override
  String get processingCategory => 'カテゴリーを処理中...';

  @override
  String get processingPriority => '優先度を処理中...';

  @override
  String get processingAI => 'AIを処理中...';

  @override
  String get aiProcessingCompleted => 'AI処理が完了しました';

  @override
  String get categorizingTask => 'タスクを分類中...';

  @override
  String get processingAIStatus => 'AIを処理中...';

  @override
  String get dangerZone => '危険な操作';

  @override
  String get clearAllData => 'すべてのデータを消去';

  @override
  String get clearDataSubtitle => 'すべてのToDoと設定を削除';

  @override
  String get version => 'バージョン';

  @override
  String get appDescription => 'シンプルさと生産性のために設計された、クリーンでエレガントなToDoリストアプリケーション。';

  @override
  String get developer => '開発者';

  @override
  String get developerInfo => '開発者情報';

  @override
  String get needHelp => 'ヘルプが必要ですか？';

  @override
  String get helpDescription => '問題が発生した場合や提案がある場合は、上記の連絡方法でお気軽にお問い合わせください。';

  @override
  String get close => '閉じる';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get system => 'システム';

  @override
  String get themeColors => 'テーマカラー';

  @override
  String get customTheme => 'カスタムテーマ';

  @override
  String get primaryColor => 'プライマリカラー';

  @override
  String get secondaryColor => 'セカンダリカラー';

  @override
  String get selectPrimaryColor => 'アプリのプライマリカラーを選択';

  @override
  String get selectSecondaryColor => 'アプリのセカンダリカラーを選択';

  @override
  String get selectColor => '色を選択';

  @override
  String get hue => '色相';

  @override
  String get saturation => '彩度';

  @override
  String get lightness => '明度';

  @override
  String get applyCustomTheme => 'カスタムテーマを適用';

  @override
  String get customThemeApplied => 'カスタムテーマが正常に適用されました';

  @override
  String get themeColorApplied => 'テーマカラーが適用されました';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get repeat => '繰り返し';

  @override
  String get repeatTask => '繰り返しタスク';

  @override
  String get repeatType => '繰り返しタイプ';

  @override
  String get daily => '毎日';

  @override
  String get weekly => '毎週';

  @override
  String get monthly => '毎月';

  @override
  String get weekdays => '平日';

  @override
  String get selectDays => '日付を選択';

  @override
  String get selectDate => '日付を選択';

  @override
  String get everyDay => '毎日';

  @override
  String get everyWeek => '毎週';

  @override
  String get everyMonth => '毎月';

  @override
  String get monday => '月曜日';

  @override
  String get tuesday => '火曜日';

  @override
  String get wednesday => '水曜日';

  @override
  String get thursday => '木曜日';

  @override
  String get friday => '金曜日';

  @override
  String get saturday => '土曜日';

  @override
  String get sunday => '日曜日';

  @override
  String get startDate => '開始日';

  @override
  String get endDate => '終了日';

  @override
  String get noEndDate => '終了日なし';

  @override
  String get timeRange => '時間範囲';

  @override
  String get startTime => '開始時刻';

  @override
  String get endTime => '終了時刻';

  @override
  String get noStartTimeSet => '開始時刻未設定';

  @override
  String get noEndTimeSet => '終了時刻未設定';

  @override
  String get invalidTimeRange => '終了時刻は開始時刻より後にしてください';

  @override
  String get repeatEnabled => '繰り返し有効';

  @override
  String get repeatDescription => '定期的なタスクを自動的に作成';

  @override
  String get backfillMode => '補完モード';

  @override
  String get backfillModeDescription => '過去に作成されなかった定期タスクを作成します';

  @override
  String get backfillDays => '遡る日数';

  @override
  String get backfillDaysDescription => '遡って確認する最大日数（1～365、今日を除く）';

  @override
  String get backfillAutoComplete => '補完したタスクを自動で完了にする';

  @override
  String get backfillDaysRangeError => '日数は1～365の間で指定してください';

  @override
  String get backfillConflictTitle => '補完範囲の競合';

  @override
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  ) {
    return '「$title」の開始日は $startDate ですが、補完モードでは $backfillStartDate まで遡ります。今回の強制更新で最も早い生成日としてどちらを使用しますか？';
  }

  @override
  String get useStartDate => '開始日を使用';

  @override
  String get useBackfillDays => '補完範囲を使用';

  @override
  String get activeRepeatTasks => 'アクティブな繰り返しタスク';

  @override
  String get noRepeatTasks => '繰り返しタスクはまだありません';

  @override
  String get pauseRepeat => '一時停止';

  @override
  String get resumeRepeat => '再開';

  @override
  String get editRepeat => '編集';

  @override
  String get deleteRepeat => '削除';

  @override
  String get repeatTaskConfirm => '繰り返しタスクを削除';

  @override
  String get repeatTaskDeleteMessage =>
      'これにより、このテンプレートから生成されたすべての定期的なタスクが削除されます。この操作は元に戻せません。';

  @override
  String get manageRepeatTasks => '繰り返しタスクを管理';

  @override
  String get comingSoon => '近日公開！';

  @override
  String get todos => 'ToDo';

  @override
  String get schedule => '予定';

  @override
  String get clearDataWarning => 'これにより、すべてのToDoと統計が永久に削除されます。この操作は元に戻せません。';

  @override
  String get dataClearedSuccess => 'すべてのデータが正常に消去されました';

  @override
  String get clearDataFailed => 'データの消去に失敗しました';

  @override
  String get history => '履歴';

  @override
  String get stats => '統計';

  @override
  String get searchTodos => 'ToDoを検索';

  @override
  String get addTodo => 'ToDoを追加';

  @override
  String get addTodoHint => '何をする必要がありますか？';

  @override
  String get todoTitle => 'タイトル';

  @override
  String get todoDescription => '説明';

  @override
  String get save => '保存';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get complete => '完了';

  @override
  String get incomplete => '未完了';

  @override
  String get allTodos => 'すべて';

  @override
  String get activeTodos => 'アクティブ';

  @override
  String get completedTodos => '完了済み';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get thisWeek => '今週';

  @override
  String get thisMonth => '今月';

  @override
  String get older => '以前';

  @override
  String get totalTodos => '合計ToDo';

  @override
  String get completedTodosCount => '完了済み';

  @override
  String get activeTodosCount => 'アクティブ';

  @override
  String get completionRate => '完了率';

  @override
  String get backup => 'バックアップ';

  @override
  String get restore => '復元';

  @override
  String get exportData => 'データをエクスポート';

  @override
  String get importData => 'データをインポート';

  @override
  String get backupSuccess => 'バックアップが正常に作成されました';

  @override
  String get backupFailed => 'バックアップの作成に失敗しました';

  @override
  String get restoreSuccess => 'データが正常に復元されました';

  @override
  String restoreFailed(Object error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get webBackupHint => 'Web：バックアップはダウンロード/アップロードで行います。';

  @override
  String restoreWarning(Object fileName) {
    return 'これにより、現在のすべてのデータが\"$fileName\"のデータに置き換えられます。この操作は元に戻せません。続行しますか？';
  }

  @override
  String get totalStorage => '合計ストレージ';

  @override
  String get todosStorage => 'ToDo';

  @override
  String get cacheStorage => 'キャッシュ';

  @override
  String get clearCache => 'キャッシュを消去';

  @override
  String get cacheCleared => 'キャッシュが正常に消去されました';

  @override
  String get filterByStatus => 'ステータスでフィルター';

  @override
  String get sortBy => '並び替え';

  @override
  String get newestFirst => '新しい順';

  @override
  String get oldestFirst => '古い順';

  @override
  String get alphabetical => 'アルファベット順';

  @override
  String get overview => '概要';

  @override
  String get weeklyProgress => '週間進捗';

  @override
  String get monthlyTrends => '月間トレンド';

  @override
  String get productivityOverview => '生産性概要';

  @override
  String get overallCompletionRate => '全体の完了率';

  @override
  String get created => '作成済み';

  @override
  String get recentActivity => '最近のアクティビティ';

  @override
  String get noRecentActivity => '最近のアクティビティはありません';

  @override
  String get todoDistribution => 'ToDo分布';

  @override
  String get bestPerformance => '最高のパフォーマンス';

  @override
  String get noCompletedTodosYet => 'まだ完了したToDoはありません';

  @override
  String get completionRateDescription => 'のToDoが完了';

  @override
  String get fingerprintLock => '指紋ロック';

  @override
  String get fingerprintLockSubtitle => '指紋でアプリのセキュリティを保護';

  @override
  String get fingerprintLockEnable => '指紋ロックを有効にする';

  @override
  String get fingerprintLockDisable => '指紋ロックを無効にする';

  @override
  String get fingerprintLockEnabled => '指紋ロックが有効になりました';

  @override
  String get fingerprintLockDisabled => '指紋ロックが無効になりました';

  @override
  String get fingerprintNotAvailable => '指紋認証が利用できません';

  @override
  String get fingerprintNotEnrolled => '登録された指紋がありません';

  @override
  String get fingerprintAuthenticationFailed => '指紋認証に失敗しました';

  @override
  String get fingerprintAuthenticationSuccess => '指紋認証に成功しました';

  @override
  String get active => 'アクティブ';

  @override
  String get mon => '月';

  @override
  String get tue => '火';

  @override
  String get wed => '水';

  @override
  String get thu => '木';

  @override
  String get fri => '金';

  @override
  String get sat => '土';

  @override
  String get sun => '日';

  @override
  String get week1 => '第1週';

  @override
  String get week2 => '第2週';

  @override
  String get week3 => '第3週';

  @override
  String get week4 => '第4週';

  @override
  String withCompletedTodos(Object count) {
    return '$count個のToDoが完了';
  }

  @override
  String get unableToLoadBackupStats => 'バックアップ統計を読み込めません';

  @override
  String get backupSummary => 'バックアップサマリー';

  @override
  String get itemsToBackup => 'バックアップ項目';

  @override
  String get dataSize => 'データサイズ';

  @override
  String get backupFiles => 'バックアップファイル';

  @override
  String get backupSize => 'バックアップサイズ';

  @override
  String get quickActions => 'クイックアクション';

  @override
  String get backupRestoreDescription => 'データのバックアップを作成するか、以前のバックアップから復元します。';

  @override
  String get createBackup => 'バックアップを作成';

  @override
  String get restoreBackup => 'バックアップを復元';

  @override
  String get noBackupFilesFound => 'バックアップファイルが見つかりません';

  @override
  String get createFirstBackup => '最初のバックアップを作成して開始';

  @override
  String get refresh => '更新';

  @override
  String get restoreFromFile => 'このファイルから復元';

  @override
  String get deleteFile => 'ファイルを削除';

  @override
  String get aboutBackups => 'バックアップについて';

  @override
  String get backupInfo1 => '• バックアップにはすべてのToDoと統計が含まれます';

  @override
  String get backupInfo2 => '• バックアップファイルを安全な場所に保存してください';

  @override
  String get backupInfo3 => '• 定期的なバックアップはデータ損失を防ぎます';

  @override
  String get backupInfo4 => '• 任意のバックアップファイルから復元できます';

  @override
  String get backupCreatedSuccess => 'バックアップが正常に作成されました';

  @override
  String get noBackupFilesAvailable => '復元可能なバックアップファイルがありません';

  @override
  String get selectBackupFile => 'バックアップファイルを選択';

  @override
  String get confirmRestore => '復元を確認';

  @override
  String dataRestoredSuccess(Object fileName) {
    return '\"$fileName\"からデータが正常に復元されました';
  }

  @override
  String get deleteBackupFile => 'バックアップファイルを削除';

  @override
  String deleteBackupWarning(Object fileName) {
    return '\"$fileName\"を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String backupFileDeletedSuccess(Object fileName) {
    return 'バックアップファイル\"$fileName\"が正常に削除されました';
  }

  @override
  String get backupFileNotFound => 'バックアップファイルが見つかりません';

  @override
  String invalidFilePath(Object fileName) {
    return '\"$fileName\"の無効なファイルパス';
  }

  @override
  String get failedToDeleteFile => 'ファイルの削除に失敗しました';

  @override
  String get files => 'ファイル';

  @override
  String get storageManagement => 'ストレージ管理';

  @override
  String get storageOverview => 'ストレージ概要';

  @override
  String get storageAnalytics => 'ストレージ分析';

  @override
  String get noPendingRequests => '保留中のリクエストはありません';

  @override
  String get request => 'リクエスト';

  @override
  String get unknown => '不明';

  @override
  String get waiting => '待機中';

  @override
  String get noRecentRequests => '最近のリクエストはありません';

  @override
  String get requestCompleted => 'リクエストが完了しました';

  @override
  String get noTodosToDisplay => '表示するToDoはありません';

  @override
  String get todoStatusDistribution => 'ToDoステータス分布';

  @override
  String get completed => '完了';

  @override
  String get pending => '保留中';

  @override
  String get dataStorageUsage => 'データストレージ使用量';

  @override
  String get total => '合計';

  @override
  String get storageCleanup => 'ストレージクリーニング';

  @override
  String get cleanupDescription => '不要なデータを削除してストレージ容量を解放：';

  @override
  String get clearCompletedTodos => '完了したToDoを消去';

  @override
  String get clearOldStatistics => '古い統計を消去';

  @override
  String get clearBackupFiles => 'バックアップファイルを消去';

  @override
  String get cleanupCompleted => 'クリーニングが完了';

  @override
  String todosDeleted(Object count) {
    return '$count個のToDoが削除されました';
  }

  @override
  String statisticsDeleted(Object count) {
    return '$count個の統計が削除されました';
  }

  @override
  String backupFilesDeleted(Object count) {
    return '$count個のバックアップファイルが削除されました';
  }

  @override
  String get cleanupFailed => 'クリーニングに失敗しました';

  @override
  String get easyTodo => 'Easy Todo';

  @override
  String copiedToClipboard(Object url) {
    return 'クリップボードにコピー：$url';
  }

  @override
  String cannotOpenLink(Object url) {
    return 'リンクを開けません、クリップボードにコピー：$url';
  }

  @override
  String get email => 'メール';

  @override
  String get github => 'GitHub';

  @override
  String get website => 'ウェブサイト';

  @override
  String get noTodosMatchSearch => '検索条件に一致するToDoがありません';

  @override
  String get noCompletedTodos => '完了したToDoはありません';

  @override
  String get noActiveTodos => 'アクティブなToDoはありません';

  @override
  String get noTodosYet => 'ToDoはまだありません';

  @override
  String get deleteTodoConfirmation => 'このToDoを削除してもよろしいですか？';

  @override
  String get createdLabel => '作成：';

  @override
  String get completedLabel => '完了：';

  @override
  String get filterByTime => '時間でフィルター';

  @override
  String get sortByTime => '時間で並び替え';

  @override
  String get ascending => '昇順';

  @override
  String get descending => '降順';

  @override
  String get threeDays => '3日間';

  @override
  String minutesAgoWithCount(Object count) {
    return '$count分前';
  }

  @override
  String hoursAgoWithCount(Object count) {
    return '$count時間前';
  }

  @override
  String daysAgoWithCount(Object count) {
    return '$count日前';
  }

  @override
  String get notificationSettings => '通知設定';

  @override
  String get enableNotifications => '通知を有効にする';

  @override
  String get dailySummary => ' dailyサマリー';

  @override
  String get dailySummaryTime => 'デイリーサマリー時間';

  @override
  String get dailySummaryDescription => '保留中のToDoの dailyサマリーを受け取る';

  @override
  String get defaultReminderSettings => 'デフォルトリマインダー設定';

  @override
  String get enableDefaultReminders => 'デフォルトリマインダーを有効にする';

  @override
  String get reminderTimeBefore => '期限前リマインダー時間';

  @override
  String minutesBefore(Object count) {
    return '$count分前';
  }

  @override
  String get notificationPermissions => '通知権限';

  @override
  String get grantPermissions => '権限を付与';

  @override
  String get permissionsGranted => '権限が付与されました';

  @override
  String get permissionsDenied => '権限が拒否されました';

  @override
  String get testNotification => 'テスト通知';

  @override
  String get sendTestNotification => 'テスト通知を送信';

  @override
  String get notificationTestSent => 'テスト通知が正常に送信されました';

  @override
  String get reminderTime => 'リマインダー時間';

  @override
  String get setReminder => 'リマインダーを設定';

  @override
  String reminderSet(Object time) {
    return '$timeにリマインダーが設定されました';
  }

  @override
  String get cancelReminder => 'リマインダーをキャンセル';

  @override
  String get noReminderSet => 'リマインダーは設定されていません';

  @override
  String get enableReminder => 'リマインダーを有効にする';

  @override
  String get reminderOptions => 'リマインダーオプション';

  @override
  String get pomodoroTimer => 'ポモドーロタイマー';

  @override
  String get pomodoroSettings => 'ポモドーロ設定';

  @override
  String get workDuration => '作業時間';

  @override
  String get breakDuration => '休憩時間';

  @override
  String get longBreakDuration => '長い休憩時間';

  @override
  String get sessionsUntilLongBreak => '長い休憩までのセッション';

  @override
  String get minutes => '分';

  @override
  String get sessions => 'セッション';

  @override
  String get settingsSaved => '設定が正常に保存されました';

  @override
  String get focusTime => '集中時間';

  @override
  String get clearOldPomodoroSessions => '古いポモドーロセッションを消去';

  @override
  String pomodoroSessionsDeleted(Object count) {
    return '$count個のポモドーロセッションが削除されました';
  }

  @override
  String get breakTime => '休憩時間';

  @override
  String get start => '開始';

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get stop => '停止';

  @override
  String get timeSpent => '経過時間';

  @override
  String get pomodoroStats => 'ポモドーロ統計';

  @override
  String get sessionsCompleted => '完了したセッション';

  @override
  String get totalTime => '合計時間';

  @override
  String get averageTime => '平均時間';

  @override
  String get focusSessions => '集中セッション';

  @override
  String get pomodoroSessions => 'ポモドーロセッション';

  @override
  String get totalFocusTime => '総集中時間';

  @override
  String get weeklyPomodoroStats => '週間ポモドーロ統計';

  @override
  String get totalSessions => '合計セッション';

  @override
  String get averageSessions => '平均セッション';

  @override
  String get monthlyPomodoroStats => '月間ポモドーロ統計';

  @override
  String get averagePerWeek => '週平均';

  @override
  String get pomodoroOverview => 'ポモドーロ概要';

  @override
  String get checkForUpdates => '更新をチェック';

  @override
  String get checkUpdatesSubtitle => '新しいバージョンを検索';

  @override
  String get checkingForUpdates => '更新をチェック中';

  @override
  String get pleaseWait => '更新をチェックしている間お待ちください...';

  @override
  String get updateAvailable => '更新利用可能';

  @override
  String get requiredUpdate => '必須アップデート';

  @override
  String versionAvailable(Object version) {
    return 'バージョン$versionが利用可能です！';
  }

  @override
  String get whatsNew => '新機能:';

  @override
  String get noUpdatesAvailable => '更新は利用できません';

  @override
  String get youHaveLatestVersion => '最新バージョンです';

  @override
  String get updateNow => '今すぐ更新';

  @override
  String get later => '後で';

  @override
  String get downloadingUpdate => '更新をダウンロード中';

  @override
  String get downloadUpdate => '更新をダウンロード';

  @override
  String get downloadFrom => '次の場所から更新をダウンロード中：';

  @override
  String get downloadFailed => 'ダウンロードに失敗しました';

  @override
  String get couldNotOpenDownloadUrl => 'ダウンロードURLを開けません';

  @override
  String get updateCheckFailed => '更新のチェックに失敗しました';

  @override
  String get forceUpdateMessage => 'この更新はアプリを引き続き使用するために必要です';

  @override
  String get optionalUpdateMessage => '今すぐまたは後で更新できます';

  @override
  String get storagePermissionDenied => 'ストレージ権限が拒否されました';

  @override
  String get cannotAccessStorage => 'ストレージにアクセスできません';

  @override
  String get updateDownloadSuccess => '更新が正常にダウンロードされました';

  @override
  String get installUpdate => '更新をインストール';

  @override
  String get startingInstaller => 'インストーラーを開始中...';

  @override
  String get updateFileNotFound => '更新ファイルが見つかりません、もう一度ダウンロードしてください';

  @override
  String get installPermissionRequired => 'インストール権限が必要';

  @override
  String get installPermissionDescription =>
      'アプリの更新をインストールするには、「不明なソースからのアプリをインストール」権限が必要です。設定でEasy Todoのこの権限を有効にしてください。';

  @override
  String get needInstallPermission => 'アプリを更新するにはインストール権限が必要です';

  @override
  String installFailed(Object error) {
    return 'インストールに失敗しました：$error';
  }

  @override
  String installLaunchFailed(Object error) {
    return 'インストールの起動に失敗しました：$error';
  }

  @override
  String get storagePermissionTitle => 'ストレージ権限が必要';

  @override
  String get storagePermissionDescription =>
      'アプリの更新をダウンロードしてインストールするには、Easy Todoがデバイスストレージにアクセスする必要があります。';

  @override
  String get permissionNote => '「許可」をクリックすると、アプリに以下の権限が付与されます：';

  @override
  String get accessDeviceStorage => '• デバイスストレージにアクセス';

  @override
  String get downloadFilesToDevice => '• デバイスにファイルをダウンロード';

  @override
  String get allow => '許可';

  @override
  String get openSettings => '設定を開く';

  @override
  String get permissionDenied => '権限が拒否されました';

  @override
  String get permissionDeniedMessage =>
      'ストレージ権限が永続的に拒否されました。システム設定で手動で権限を有効にして再試行してください。';

  @override
  String get cannotOpenSettings => '設定ページを開けません';

  @override
  String get autoUpdate => '自動更新';

  @override
  String get autoUpdateSubtitle => 'アプリ起動時に自動的に更新をチェック';

  @override
  String get autoUpdateEnabled => '自動更新が有効になりました';

  @override
  String get autoUpdateDisabled => '自動更新が無効になりました';

  @override
  String get exitApp => 'アプリを終了';

  @override
  String get viewSettings => '表示設定';

  @override
  String get viewDisplay => '表示';

  @override
  String get viewDisplaySubtitle => 'コンテンツの表示方法を設定';

  @override
  String get todoViewSettings => 'ToDo表示設定';

  @override
  String get historyViewSettings => '履歴表示設定';

  @override
  String get scheduleLayoutSettings => 'スケジュールレイアウト設定';

  @override
  String get scheduleLayoutSettingsSubtitle => '時間範囲と曜日をカスタマイズ';

  @override
  String get viewMode => '表示モード';

  @override
  String get listView => 'リストビュー';

  @override
  String get stackingView => 'スタッキングビュー';

  @override
  String get calendarView => 'カレンダービュー';

  @override
  String get openInNewPage => '新しいページで開く';

  @override
  String get openInNewPageSubtitle => 'ポップアップの代わりに新しいページでビューを開く';

  @override
  String get historyViewMode => '履歴表示モード';

  @override
  String get scheduleTimeRange => '時間範囲';

  @override
  String get scheduleVisibleWeekdays => '表示する曜日';

  @override
  String get scheduleLabelTextScale => 'ラベル文字の拡大率';

  @override
  String get scheduleAtLeastOneDay => '少なくとも1日を選択してください。';

  @override
  String get dayDetails => '日の詳細';

  @override
  String get todoCount => 'ToDo数';

  @override
  String get completedCount => '完了';

  @override
  String get totalCount => '合計';

  @override
  String get appLongDescription =>
      'Easy Todoは、日々のタスクを効率的に整理するのに役立つ、クリーンでエレガントかつ強力なToDoリストアプリケーションです。美しいUIデザイン、包括的な統計追跡、シームレスなAPI統合、多言語サポートにより、Easy Todoはタスク管理を簡単で楽しくします。';

  @override
  String get cannotDeleteRepeatTodo => '繰り返しToDoは削除できません';

  @override
  String get appTitle => 'Easy Todo';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterTodayTodos => '今日のToDo';

  @override
  String get filterCompleted => '完了済み';

  @override
  String get filterThisWeek => '今週';

  @override
  String get resetButton => 'リセット';

  @override
  String get applyButton => '適用';

  @override
  String get repeatTaskWarning => 'このToDoアイテムは繰り返しタスクから自動的に生成され、削除後も明日再生成されます。';

  @override
  String get learnMore => '詳細';

  @override
  String get repeatTaskDialogTitle => '繰り返しタスクToDoアイテム';

  @override
  String get repeatTaskExplanation =>
      'このToDoは繰り返しタスクテンプレートから自動的に作成されます。削除しても繰り返しタスク自体には影響しません - 新しいToDoは繰り返しスケジュールに従って明日生成されます。これらのToDoの生成を停止したい場合は、繰り返しタスク管理セクションで繰り返しタスクテンプレートを編集または削除する必要があります。';

  @override
  String get iUnderstand => '理解しました';

  @override
  String get authenticateToContinue => '続行するには認証してください';

  @override
  String get retry => '再試行';

  @override
  String get biometricReason => '生体認証を使用して身元を確認してください';

  @override
  String get biometricHint => '生体認証を使用';

  @override
  String get biometricNotRecognized => '生体認証が認識されませんでした、再試行してください';

  @override
  String get biometricSuccess => '生体認証が成功しました';

  @override
  String get biometricVerificationTitle => '生体認証';

  @override
  String addTodoError(Object error) {
    return 'ToDoの追加に失敗しました：$error';
  }

  @override
  String get titleRequired => 'タイトルを入力してください';

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
    return '繰り返しタスクの作成に失敗しました：$error';
  }

  @override
  String get repeatTaskTitleRequired => 'タイトルを入力してください';

  @override
  String get importBackup => 'バックアップをインポート';

  @override
  String get shareBackup => 'バックアップを共有';

  @override
  String get cannotAccessFile => '選択されたファイルにアクセスできません';

  @override
  String get invalidBackupFormat => '無効なバックアップ形式';

  @override
  String get importBackupTitle => 'バックアップをインポート';

  @override
  String get import => 'インポート';

  @override
  String get backupShareSuccess => 'バックアップファイルが正常に共有されました';

  @override
  String get requiredUpdateAvailable => '必須の更新が利用可能です。続行するには更新してください。';

  @override
  String updateCheckError(Object error) {
    return 'アップデートの確認中にエラーが発生しました: $error';
  }

  @override
  String importingBackupFile(Object fileName) {
    return 'バックアップファイル\"$fileName\"をインポートしようとしています。これにより現在のすべてのデータが上書きされます。続行しますか？';
  }

  @override
  String hardcodedStringFound(Object fileName) {
    return '即将导入备份文件 \"$fileName\"，这将覆盖当前的所有数据。确定继续吗？';
  }

  @override
  String get testNotifications => 'テスト通知';

  @override
  String get testNotificationChannel => 'テスト通知チャネル';

  @override
  String get testNotificationContent => '通知が正常に機能していることを確認するためのテスト通知です。';

  @override
  String get failedToSendTestNotification => 'テスト通知の送信に失敗しました：';

  @override
  String get failedToCheckForUpdates => '更新のチェックに失敗しました';

  @override
  String get errorCheckingForUpdates => 'アップデートの確認中にエラーが発生しました: ';

  @override
  String get updateFileName => 'easy_todo_update.apk';

  @override
  String get unknownDate => '不明な日付';

  @override
  String get restoreSuccessPrefix => '復元された ';

  @override
  String get restoreSuccessSuffix => ' ToDo';

  @override
  String get importSuccessPrefix => 'バックアップファイルが正常にインポートされ、復元された ';

  @override
  String get importFailedPrefix => 'インポートに失敗しました：';

  @override
  String get cleanupFailedPrefix => 'クリーニングに失敗しました：';

  @override
  String get developerName => '梦凌汐 (MeowLynxSea)';

  @override
  String get createYourFirstRepeatTask => '最初の繰り返しタスクを作成して開始';

  @override
  String get rate => '評価';

  @override
  String get openSource => 'オープンソース';

  @override
  String get repeatTodoTest => '繰り返しToDoテスト';

  @override
  String get repeatTodos => '繰り返しToDo';

  @override
  String get addRepeatTodo => '繰り返しToDoを追加';

  @override
  String get checkRepeatTodos => '繰り返しToDoを確認';

  @override
  String get authenticateToAccessApp => '続行するには認証してください';

  @override
  String get backupFileSubject => 'Easy Todo バックアップファイル';

  @override
  String get shareFailedPrefix => '共有に失敗しました：';

  @override
  String get schedulingTodoReminder => 'ToDoリマインダーをスケジュール中 \"';

  @override
  String get todoReminderTimerScheduled => 'ToDoリマインダータイマーが正常にスケジュールされました';

  @override
  String get allRemindersRescheduled => 'すべてのリマインダーが正常に再スケジュールされました';

  @override
  String get allTimersCleared => 'すべてのタイマーがクリアされました';

  @override
  String get allNotificationChannelsCreated => 'すべての通知チャネルが正常に作成されました';

  @override
  String get utc => 'UTC';

  @override
  String get gmt => 'GMT';

  @override
  String get authenticateToEnableFingerprint => '指紋ロックを有効にするには認証してください';

  @override
  String get authenticateToDisableFingerprint => '指紋ロックを無効にするには認証してください';

  @override
  String get authenticateToAccessWithFingerprint => '指紋認証を使用してアプリにアクセスしてください';

  @override
  String get authenticateToAccessWithBiometric => '続行するには生体認証を使用して身元を確認してください';

  @override
  String get authenticateToClearData => 'すべてのデータを消去するには生体認証を使用してください';

  @override
  String get clearDataFailedPrefix => 'データの消去に失敗しました：';

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
  String get deleteAction => '削除';

  @override
  String get toggleReminderAction => 'toggle_reminder';

  @override
  String get pomodoroAction => 'pomodoro';

  @override
  String get completedKey => '完了';

  @override
  String get totalKey => '合計';

  @override
  String get zh => 'zh';

  @override
  String get en => 'en';

  @override
  String everyNDays(Object count) {
    return '$count日ごと';
  }

  @override
  String get dataStatistics => 'データ統計';

  @override
  String get dataStatisticsDescription => 'データ統計が有効な繰り返しタスクの数';

  @override
  String get statisticsModes => '統計モード';

  @override
  String get statisticsModesDescription => '適用する統計分析方法を選択';

  @override
  String get dataUnit => 'データ単位';

  @override
  String get dataUnitHint => '例：kg、km、\$、%';

  @override
  String get statisticsModeAverage => '平均';

  @override
  String get statisticsModeGrowth => '成長';

  @override
  String get statisticsModeExtremum => '極値';

  @override
  String get statisticsModeTrend => 'トレンド';

  @override
  String get enterDataToComplete => '完了するデータを入力';

  @override
  String get enterDataDescription => 'この繰り返しタスクは完了前にデータ入力が必要です';

  @override
  String get dataValue => 'データ値';

  @override
  String get dataValueHint => '数値を入力';

  @override
  String get dataValueRequired => 'このタスクを完了するにはデータ値を入力してください';

  @override
  String get invalidDataValue => '有効な数値を入力してください';

  @override
  String get dataStatisticsTab => 'データ統計';

  @override
  String get selectRepeatTask => '繰り返しタスクを選択';

  @override
  String get selectRepeatTaskHint => '統計を表示する繰り返しタスクを選択';

  @override
  String get timePeriod => '期間';

  @override
  String get timePeriodToday => '今日';

  @override
  String get timePeriodThisWeek => '今週';

  @override
  String get timePeriodThisMonth => '今月';

  @override
  String get timePeriodOverview => '概要';

  @override
  String get timePeriodCustom => 'カスタム範囲';

  @override
  String get selectCustomRange => '日付範囲を選択';

  @override
  String get noRepeatTasksWithStats => '統計が有効な繰り返しタスクはありません';

  @override
  String get noDataAvailable => '選択された期間のデータはありません';

  @override
  String get dataProgressToday => '今日の進捗';

  @override
  String get averageValue => '平均値';

  @override
  String get totalValue => '合計値';

  @override
  String get dataPoints => 'データポイント';

  @override
  String get growthRate => '成長率';

  @override
  String get trendAnalysis => 'トレンド分析';

  @override
  String get maximumValue => '最大値';

  @override
  String get minimumValue => '最小値';

  @override
  String get extremumAnalysis => '極値分析';

  @override
  String get statisticsSummary => '統計サマリー';

  @override
  String get dataVisualization => 'データ視覚化';

  @override
  String get chartTitle => 'データトレンド';

  @override
  String get lineChart => '折れ線グラフ';

  @override
  String get barChart => '棒グラフ';

  @override
  String get showValueOnDrag => 'グラフ上でドラッグ時に値を表示';

  @override
  String get dragToShowValue => '詳細な値を表示するにはグラフ上でドラッグ';

  @override
  String get analytics => '分析';

  @override
  String get dataEntry => 'データ入力';

  @override
  String get statisticsEnabled => '統計有効';

  @override
  String get dataCollection => 'データ収集';

  @override
  String repeatTodoWithStats(Object count) {
    return '統計付き繰り返しタスク：$count';
  }

  @override
  String dataEntries(Object count) {
    return 'データエントリ：$count';
  }

  @override
  String withDataValues(Object count) {
    return '値付き：$count';
  }

  @override
  String totalDataSize(Object size) {
    return '合計データサイズ：$size';
  }

  @override
  String get dataBackupSupported => 'データバックアップと復元サポート';

  @override
  String get repeatTasks => '繰り返しタスク';

  @override
  String get dataStatisticsEnabled => 'データ統計有効';

  @override
  String get statisticsData => '統計データ';

  @override
  String get dataStatisticsEnabledShort => 'データ統計';

  @override
  String get dataWithValue => '値付き';

  @override
  String get noDataStatisticsEnabled => '有効なデータ統計はありません';

  @override
  String get enableDataStatisticsHint => '分析を見るには繰り返しタスクのデータ統計を有効にしてください';

  @override
  String get selectTimePeriod => '期間を選択';

  @override
  String get customRange => 'カスタム範囲';

  @override
  String get selectRepeatTaskToViewData => 'データ統計を表示する繰り返しタスクを選択';

  @override
  String get noStatisticsData => '利用可能な統計データはありません';

  @override
  String get completeSomeTodosToSeeData => 'データ付きのいくつかのToDoを完了して統計を確認';

  @override
  String get totalEntries => '合計エントリ';

  @override
  String get average => '平均';

  @override
  String get min => '最小';

  @override
  String get max => '最大';

  @override
  String get totalGrowth => '合計成長';

  @override
  String get notEnoughDataForCharts => 'グラフには十分なデータがありません';

  @override
  String get averageTrend => '平均トレンド';

  @override
  String get averageChartDescription => 'トレンド分析付きで時間経過に伴う平均値を表示';

  @override
  String get trendDirection => 'トレンド方向';

  @override
  String get trendStrength => 'トレンド強度';

  @override
  String get growthAnalysis => '成長分析';

  @override
  String get range => '範囲';

  @override
  String get stableTrendDescription => '最小の変動で安定したトレンド';

  @override
  String get weakTrendDescription => 'いくつかの変動で弱いトレンド';

  @override
  String get moderateTrendDescription => '明確な方向性で中程度のトレンド';

  @override
  String get strongTrendDescription => '著しい変動で強いトレンド';

  @override
  String get invalidNumberFormat => '無効な数値形式';

  @override
  String get dataUnitRequired => 'データ統計が有効な場合はデータ単位が必要です';

  @override
  String get growth => '成長';

  @override
  String get extremum => '極値';

  @override
  String get trend => 'トレンド';

  @override
  String get dataInputRequired => 'このタスクを完了するにはデータ入力が必要です';

  @override
  String get todayProgress => '今日の進捗';

  @override
  String get dataProgress => 'データ進捗';

  @override
  String get noDataForToday => '今日のデータはありません';

  @override
  String get weeklyDataStats => '週間データ統計';

  @override
  String get noDataForThisWeek => '今週のデータはありません';

  @override
  String get daysTracked => '追跡日数';

  @override
  String get monthlyDataStats => '月間データ統計';

  @override
  String get noDataForThisMonth => '今月のデータはありません';

  @override
  String get customDateRange => 'カスタム日付範囲';

  @override
  String get allData => 'すべてのデータ';

  @override
  String get breakdownByTask => 'タスク別内訳';

  @override
  String get clear => '消去';

  @override
  String get trendUp => '上昇トレンド';

  @override
  String get trendDown => '下降トレンド';

  @override
  String get trendStable => '安定トレンド';

  @override
  String get needMoreDataToAnalyze => '分析するにはもっとデータを収集する必要があります';

  @override
  String get taskCompleted => 'タスク完了';

  @override
  String get taskWithdrawn => 'タスク撤回';

  @override
  String get noDefaultSettings => 'デフォルト設定が見つかりません、デフォルトを作成中';

  @override
  String get authenticateForSensitiveOperation => '生体認証を使用して身元を確認してください';

  @override
  String get insufficientData => 'データ不足';

  @override
  String get stable => '安定';

  @override
  String get strongUpward => '強い上昇';

  @override
  String get upward => '上昇';

  @override
  String get strongDownward => '強い下降';

  @override
  String get downward => '下降';

  @override
  String get repeatTasksRefreshedSuccessfully => '繰り返しタスクが正常に更新されました';

  @override
  String get errorRefreshingRepeatTasks => '繰り返しタスクの更新中にエラー';

  @override
  String get forceRefresh => '強制更新';

  @override
  String get errorLoadingRepeatTasks => '繰り返しタスクの読み込み中にエラー';

  @override
  String get pleaseCheckStoragePermissions => 'ストレージ権限を確認して再試行してください';

  @override
  String get todoReminders => 'ToDoリマインダー';

  @override
  String get notificationsForIndividualTodoReminders => '個別のToDoリマインダー通知';

  @override
  String get notificationsForDailySummary => '保留中のToDoの dailyサマリー';

  @override
  String get pomodoroComplete => 'ポモドーロ完了';

  @override
  String get notificationsForPomodoroSessions => 'ポモドーロセッション完了時の通知';

  @override
  String get dailyTodoSummary => ' daily ToDoサマリー';

  @override
  String youHavePendingTodos(Object count, Object n, Object s) {
    return '$count件の保留中のToDoがあります';
  }

  @override
  String greatJobTimeForBreak(Object breakType) {
    return 'よくできました！$breakType休憩の時間です';
  }

  @override
  String get shortBreak => '短い';

  @override
  String get longBreak => '長い';

  @override
  String get themeColorMysteriousPurple => 'ミステリアスパープル';

  @override
  String get themeColorSkyBlue => 'スカイブルー';

  @override
  String get themeColorGemGreen => 'ジェムグリーン';

  @override
  String get themeColorLemonYellow => 'レモンイエロー';

  @override
  String get themeColorFlameRed => 'フレームレッド';

  @override
  String get themeColorElegantPurple => 'エレガントパープル';

  @override
  String get themeColorCherryPink => 'チェリーピンク';

  @override
  String get themeColorForestCyan => 'フォレストシアン';

  @override
  String get aiSettings => 'AI設定';

  @override
  String get aiFeatures => 'AI機能';

  @override
  String get aiEnabled => 'AI機能が有効';

  @override
  String get aiDisabled => 'AI機能が無効';

  @override
  String get enableAIFeatures => 'AI機能を有効にする';

  @override
  String get enableAIFeaturesSubtitle => '人工知能を使用してToDo体験を向上させる';

  @override
  String get apiConfiguration => 'API設定';

  @override
  String get apiEndpoint => 'APIエンドポイント';

  @override
  String get pleaseEnterApiEndpoint => 'APIエンドポイントを入力してください';

  @override
  String get invalidApiEndpoint => '有効なAPIエンドポイントを入力してください';

  @override
  String get apiKey => 'APIキー';

  @override
  String get pleaseEnterApiKey => 'APIキーを入力してください';

  @override
  String get modelName => 'モデル名';

  @override
  String get pleaseEnterModelName => 'モデル名を入力してください';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get timeout => 'タイムアウト (ms)';

  @override
  String get pleaseEnterTimeout => 'タイムアウトを入力してください';

  @override
  String get invalidTimeout => '有効なタイムアウトを入力してください（最小1000ms）';

  @override
  String get temperature => '温度';

  @override
  String get pleaseEnterTemperature => '温度を入力してください';

  @override
  String get invalidTemperature => '有効な温度を入力してください（0.0 - 2.0）';

  @override
  String get maxTokens => '最大トークン数';

  @override
  String get pleaseEnterMaxTokens => '最大トークン数を入力してください';

  @override
  String get invalidMaxTokens => '有効な最大トークン数を入力してください（最小1）';

  @override
  String get rateLimit => 'レート制限';

  @override
  String get rateLimitSubtitle => '1分あたりの最大リクエスト数';

  @override
  String get pleaseEnterRateLimit => 'レート制限を入力してください';

  @override
  String get invalidRateLimit => 'レート制限は1から100の間である必要があります';

  @override
  String get rateAndTokenLimits => 'レートとトークンの制限';

  @override
  String get testConnection => '接続テスト';

  @override
  String get connectionSuccessful => '接続成功！';

  @override
  String get connectionFailed => '接続失敗';

  @override
  String get aiFeaturesToggle => 'AI機能の切り替え';

  @override
  String get autoCategorization => '自動カテゴリー化';

  @override
  String get autoCategorizationSubtitle => 'タスクを自動的にカテゴリー分類する';

  @override
  String get prioritySorting => '優先度ソート';

  @override
  String get prioritySortingSubtitle => 'タスクの重要度と優先度を評価する';

  @override
  String get motivationalMessages => 'モチベーションメッセージ';

  @override
  String get motivationalMessagesSubtitle => '進捗に基づいて励ましのメッセージを生成する';

  @override
  String get smartNotifications => 'スマート通知';

  @override
  String get smartNotificationsSubtitle => 'パーソナライズされた通知コンテンツを作成する';

  @override
  String get completionMotivation => '完了モチベーション';

  @override
  String get completionMotivationSubtitle => '日次完了率に基づいてモチベーションを表示する';

  @override
  String get aiCategoryWork => '仕事';

  @override
  String get aiCategoryPersonal => '個人';

  @override
  String get aiCategoryStudy => '勉強';

  @override
  String get aiCategoryHealth => '健康';

  @override
  String get aiCategoryFitness => 'フィットネス';

  @override
  String get aiCategoryFinance => '金融';

  @override
  String get aiCategoryShopping => '買い物';

  @override
  String get aiCategoryFamily => '家族';

  @override
  String get aiCategorySocial => '社交';

  @override
  String get aiCategoryHobby => '趣味';

  @override
  String get aiCategoryTravel => '旅行';

  @override
  String get aiCategoryOther => 'その他';

  @override
  String get aiPriorityHigh => '高優先度';

  @override
  String get aiPriorityMedium => '中優先度';

  @override
  String get aiPriorityLow => '低優先度';

  @override
  String get aiPriorityUrgent => '緊急';

  @override
  String get aiPriorityImportant => '重要';

  @override
  String get aiPriorityNormal => '通常';

  @override
  String get selectTodoForPomodoro => 'ToDoを選択';

  @override
  String get pomodoroDescription => 'ポモドーロ集中セッションを開始するためにToDoアイテムを選択';

  @override
  String get noTodosForPomodoro => '利用可能なToDoがありません';

  @override
  String get createTodoForPomodoro => '最初にいくつかのToDoを作成してください';

  @override
  String get todaySessions => '今日のセッション';

  @override
  String get startPomodoro => 'ポモドーロ開始';

  @override
  String get aiDebugInfo => 'AI デバッグ情報';

  @override
  String get processingUnprocessedTodos => '未処理のToDoをAIで処理中';

  @override
  String get processAllTodosWithAI => 'すべてのToDoをAIで処理';

  @override
  String todayTimeFormat(Object time) {
    return '今日 $time';
  }

  @override
  String tomorrowTimeFormat(Object time) {
    return '明日 $time';
  }

  @override
  String get deleteTodoDialogTitle => '削除';

  @override
  String get deleteTodoDialogMessage => 'このToDoを削除してもよろしいですか？';

  @override
  String get deleteTodoDialogCancel => 'キャンセル';

  @override
  String get deleteTodoDialogDelete => '削除';

  @override
  String get customPersona => 'カスタムペルソナ';

  @override
  String get personaPrompt => 'ペルソナプロンプト';

  @override
  String get personaPromptHint => '例：ユーモアと絵文字を使う親切なアシスタント...';

  @override
  String get personaPromptDescription =>
      '通知用のAIの性格をカスタマイズします。これはToDoリマインダーと日次サマリーの両方に適用されます。';

  @override
  String get personaExample1 => 'ポジティブな強化で励ますモチベーショナルコーチ';

  @override
  String get personaExample2 => '軽いユーモアと絵文字を使うユーモラスなアシスタント';

  @override
  String get personaExample3 => '簡潔なアドバイスを与える専門的な生産性専門家';

  @override
  String get personaExample4 => '温かさと配慮で思い出させるサポートフレンド';

  @override
  String get aiDebugInfoTitle => 'AI デバッグ情報';

  @override
  String get aiDebugInfoSubtitle => 'AI機能の状態を確認';

  @override
  String get aiSettingsStatus => 'AI設定ステータス';

  @override
  String get aiFeatureToggles => 'AI機能トグル';

  @override
  String get aiTodoProviderConnection => 'Todoプロバイダー接続';

  @override
  String get aiMessages => 'AIメッセージ';

  @override
  String get aiApiRequestManager => 'APIリクエストマネージャー';

  @override
  String get aiCurrentRequestQueue => '現在のリクエストキュー';

  @override
  String get aiRecentRequests => '最近のリクエスト';

  @override
  String get aiPermissionRequestMessage =>
      'システム設定で「Easy Todo」の「アラームとリマインダー」権限を有効にしてください。';

  @override
  String get developerNameMeowLynxSea => '梦凌汐 (MeowLynxSea)';

  @override
  String get developerEmail => 'mew@meowdream.cn';

  @override
  String get developerGithub => 'github.com/MeowLynxSea';

  @override
  String get developerWebsite => 'www.meowdream.cn';

  @override
  String get backupFileShareSubject => 'Easy Todo バックアップファイル';

  @override
  String shareFailed(Object error) {
    return '共有に失敗しました: $error';
  }

  @override
  String get authenticateToAccessAppMessage => '指紋を使用してアプリにアクセスしてください';

  @override
  String get aiFeaturesEnabled => 'AI機能が有効';

  @override
  String get aiServiceValid => 'AIサービス有効';

  @override
  String get notConfigured => '未設定';

  @override
  String configured(Object count) {
    return '設定済み（$count文字）';
  }

  @override
  String get aiProviderConnected => 'AIプロバイダー接続済み';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get aiProcessedTodos => 'AI処理済みToDo';

  @override
  String get todosWithAICategory => 'AIカテゴリー付きToDo';

  @override
  String get todosWithAIPriority => 'AI優先度付きToDo';

  @override
  String get lastError => '最後のエラー';

  @override
  String get pendingRequests => '保留中のリクエスト';

  @override
  String get currentWindowRequests => '現在のウィンドウリクエスト';

  @override
  String get maxRequestsPerMinute => '最大リクエスト/分';

  @override
  String get status => 'ステータス';

  @override
  String get aiServiceNotAvailable => 'AIサービス利用不可';

  @override
  String get completionMessages => '完了メッセージ';

  @override
  String get exactAlarmPermission => '正確なアラーム権限';

  @override
  String get exactAlarmPermissionContent =>
      'ポモドーロとリマインダー機能が正確に機能するように、アプリは正確なアラーム権限が必要です。\n\nシステム設定で「Easy Todo」の「アラームとリマインダー」権限を有効にしてください。';

  @override
  String get setLater => '後で設定';

  @override
  String get goToSettings => '設定に移動';

  @override
  String get batteryOptimizationSettings => 'バッテリー最適化設定';

  @override
  String get batteryOptimizationContent =>
      'ポモドーロとリマインダー機能がバックグラウンドで正しく機能するように、このアプリのバッテリー最適化を無効にしてください。\n\nこれによりバッテリー消費が増加する可能性がありますが、タイマーとリマインダー機能が正確に機能することが保証されます。';

  @override
  String get breakTimeComplete => '休憩時間終了！';

  @override
  String get timeToGetBackToWork => '作業に戻る時間です！';

  @override
  String get aiServiceReturnedEmptyMessage => 'AIサービスが空のメッセージを返しました';

  @override
  String errorGeneratingMotivationalMessage(Object error) {
    return 'モチベーションメッセージの生成中にエラー: $error';
  }

  @override
  String get aiServiceNotAvailableCheckSettings =>
      'AIサービスが利用できません、AI設定を確認してください';

  @override
  String get filterByCategory => 'カテゴリーでフィルター';

  @override
  String get importance => '重要度';

  @override
  String get noCategoriesAvailable => '利用可能なカテゴリーがありません';

  @override
  String get aiWillCategorizeTasks => 'AIがタスクを自動的に分類します、後でもう一度お試しください';

  @override
  String get selectCategories => 'カテゴリーを選択';

  @override
  String get selectedCategories => '選択済み';

  @override
  String get categories => 'カテゴリー';

  @override
  String get apiFormat => 'API形式';

  @override
  String get apiFormatDescription =>
      'AIサービスプロバイダーを選択してください。異なるプロバイダーは異なるAPIエンドポイントと認証方法を必要とする場合があります。';

  @override
  String get openaiFormat => 'OpenAI';

  @override
  String get anthropicFormat => 'Anthropic';

  @override
  String aiPromptCategorization(Object description, Object title) {
    return 'このToDoタスクを次のカテゴリーのいずれかに分類してください：\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n\n      タスク：\"$title\"\n      説明：\"$description\"\n\n      カテゴリー名を小文字でのみ応答してください。';
  }

  @override
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  ) {
    return 'このToDoタスクの優先度を0-100で評価してください。以下を考慮：\n      - 緊急性：どのくらい早く必要ですか？（締切：$deadline）\n      - 影響：完了しない場合の結果は何ですか？\n      - 労力：どのくらいの時間/リソースが必要ですか？\n      - 個人的重要性：これがあなたにとってどれほど価値がありますか？\n\n      タスク：\"$title\"\n      説明：\"$description\"\n      締切あり：$hasDeadline\n      締切：$deadline\n\n      ガイドライン：\n      - 0-20：低優先度、延期可能\n      - 21-40：中優先度、すぐに行うべき\n      - 41-70：高優先度、完了が重要\n      - 71-100：重要優先度、緊急の完了が必要\n\n      0-100の数字でのみ応答してください。';
  }

  @override
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  ) {
    return 'この統計データに基づいてモチベーションメッセージを生成してください：\n      名前：\"$name\"\n      説明：\"$description\"\n      値：$value\n      単位：\"$unit\"\n      日付：$date\n\n      要件：\n      - データに応じた励ましの言葉にしてください\n      - 25文字以内にしてください\n      - 達成と進歩に焦点を当てる\n      - ポジティブで行動志向の言葉を使う\n      - 例：「今日も頑張った！🎯」や「続けよう！💪」\n      - メッセージのみを返信し、説明は含めないでください';
  }

  @override
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  ) {
    return 'このタスクのためのパーソナライズされた通知リマインダーを作成してください：\n      タスク：\"$title\"\n      説明：\"$description\"\n      カテゴリー：$category\n      優先度：$priority\n\n      要件：\n      - タイトルとメッセージの両方を作成してください\n      - タイトル：20文字未満、注目を引くもの\n      - メッセージ：50文字未満、モチベーションを上げ実行可能なもの\n      - エンゲージメントのために絵文字を適宜使用\n      - 優先度レベルに基づいた緊急性を含める\n      - 個人的で励ましになるようにする\n      - 指定された形式でタイトルとメッセージのみを返信し、説明は含めないでください\n\n      次の形式で応答してください：\n      TITLE: [タイトル]\n      MESSAGE: [メッセージ]';
  }

  @override
  String aiPromptCompletion(Object completed, Object percentage, Object total) {
    return '今日のToDo完了状況に基づいて励ましのメッセージを生成してください：\n      完了：$completed/$totalタスク\n      完了率：$percentage%\n\n      要件：\n      - ポジティブでモチベーションを上げるものにしてください\n      - 25文字以内にしてください\n      - 達成と進歩を祝う\n      - 励ましの言葉や絵文字を使用する\n      - 例：「素晴らしい仕事！🌟」や「進歩！👍」\n      - メッセージのみを返信し、説明は含めないでください';
  }

  @override
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  ) {
    return '未完了のToDoのための毎日のサマリー通知を作成してください。\n\n未完了タスク数：$pendingCount\nカテゴリー：$categories\n平均優先度：$avgPriority/100\n\nパーソナライズされたサマリーを作成してください：\n1. 注目を引くタイトル（最初の行）\n2. 未完了タスク数（$pendingCount）を必ず含む励ましのメッセージ\n3. メッセージ内容を50文字未満にしてください。モチベーションを上げ、実行可能にしてください。\n4. タイトルとメッセージのみを返信し、説明は含めないでください';
  }

  @override
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  ) {
    return '完了した$sessionTypeセッションのパーソナライズされた通知を作成してください。\n\nセッション詳細：\n- タスク：\"$taskTitle\"\n- セッションタイプ：$sessionType\n- 持続時間：$duration分\n- 完了：$isCompleted\n\n重要：日本語で返信してください。\n\nタイトルとメッセージを作成してください：\n1. タイトル：20文字未満、注目を集め、祝祭的なもの\n2. メッセージ：50文字未満、セッション完了に関連して励みになるもの\n3. フォーカスセッション（作業完了）：作業の達成を強調し、休憩の時間だと言及する\n4. 休憩セッション（休憩完了）：休憩の完了と集中作業に戻る時間だと言及する\n5. エンゲージメントのために適切に絵文字を使用する\n6. パーソナルで動機づけになるようにする\n7. 指定された形式でタイトルとメッセージのみを返信し、説明は含めないでください\n\n次の形式で返信してください：\nTITLE: [タイトル]\nMESSAGE: [メッセージ]';
  }

  @override
  String get cloudSyncAuthProcessingTitle => 'サインイン中';

  @override
  String get cloudSyncAuthProcessingSubtitle => 'ログインコールバックを処理しています…';

  @override
  String get cloudSyncChangePassphraseTitle => 'パスフレーズを変更';

  @override
  String get cloudSyncChangePassphraseSubtitle => 'DEK の再ラップのみ（履歴の再アップロードなし）';

  @override
  String get cloudSyncChangePassphraseAction => '変更';

  @override
  String get cloudSyncChangePassphraseDialogTitle => '同期パスフレーズを変更';

  @override
  String get cloudSyncChangePassphraseDialogHint =>
      'キー バンドルのみ更新します。他の端末では、新しいパスフレーズの入力が必要になる場合があります。';

  @override
  String get cloudSyncCurrentPassphrase => '現在のパスフレーズ';

  @override
  String get cloudSyncNewPassphrase => '新しいパスフレーズ';

  @override
  String get cloudSyncPassphraseChangedSnack => 'パスフレーズを更新しました';

  @override
  String get syncAiApiKeyTitle => 'API キーを同期（暗号化）';

  @override
  String get syncAiApiKeySubtitle => 'エンドツーエンド暗号化で端末間に API キーを共有します（任意）';

  @override
  String get syncAiApiKeyWarningTitle => 'API キーを同期しますか？';

  @override
  String get syncAiApiKeyWarningMessage =>
      'API キーは暗号文としてアップロードされ、同期パスフレーズを持つ端末で復号できます。リスクを理解している場合のみ有効にしてください。';

  @override
  String get cloudSyncAutoSyncIntervalTitle => '自動同期間隔';

  @override
  String get cloudSyncAutoSyncIntervalHint =>
      'ポーリングは端末ごとの設定です。ローカルに未送信の変更がある場合、outbox トリガーでより早く同期されることがあります。';

  @override
  String get cloudSyncAutoSyncIntervalSecondsLabel => '秒';

  @override
  String get cloudSyncAutoSyncIntervalMinHint => '最小 30 秒';

  @override
  String get cloudSyncAutoSyncIntervalSavedSnack => '自動同期間隔を保存しました';

  @override
  String cloudSyncAutoSyncIntervalSubtitle(Object interval) {
    return '現在：$interval';
  }

  @override
  String cloudSyncSecondsFormat(Object count) {
    return '$count秒';
  }

  @override
  String cloudSyncMinutesFormat(Object count) {
    return '$count分';
  }

  @override
  String cloudSyncMinutesSecondsFormat(Object minutes, Object seconds) {
    return '$minutes分 $seconds秒';
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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get preferences => '设置';

  @override
  String get appSettings => '应用设置';

  @override
  String get notifications => '通知';

  @override
  String get notificationsSubtitle => '管理通知偏好';

  @override
  String get theme => '主题';

  @override
  String get lightTheme => '亮色';

  @override
  String get darkTheme => '暗色';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get languageSettings => '语言设置允许您更改应用的显示语言。请从上方列表中选择您偏好的语言。';

  @override
  String get dataStorage => '数据和存储';

  @override
  String get backupRestore => '备份和恢复';

  @override
  String get backupSubtitle => '备份您的数据';

  @override
  String get storage => '存储';

  @override
  String get storageSubtitle => '管理存储空间';

  @override
  String get about => '关于';

  @override
  String get aboutEasyTodo => '关于 轻单';

  @override
  String get helpSupport => '帮助和支持';

  @override
  String get helpSubtitle => '获取应用帮助';

  @override
  String get processingCategory => '处理类别中...';

  @override
  String get processingPriority => '处理优先级中...';

  @override
  String get processingAI => 'AI处理中...';

  @override
  String get aiProcessingCompleted => 'AI处理完成';

  @override
  String get categorizingTask => '正在分类任务...';

  @override
  String get processingAIStatus => 'AI处理中...';

  @override
  String get dangerZone => '危险区域';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get clearDataSubtitle => '删除所有待办事项和设置';

  @override
  String get version => '版本';

  @override
  String get appDescription => '一个干净、优雅的待办事项应用程序，专为简单和生产力而设计。';

  @override
  String get developer => '开发者';

  @override
  String get developerInfo => '开发者信息';

  @override
  String get needHelp => '需要帮助？';

  @override
  String get helpDescription => '如果您遇到任何问题或有建议，请随时通过以上任何联系方式与我们联系。';

  @override
  String get close => '关闭';

  @override
  String get themeSettings => '主题设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get light => '亮色';

  @override
  String get dark => '暗色';

  @override
  String get system => '跟随系统';

  @override
  String get themeColors => '主题颜色';

  @override
  String get customTheme => '自定义主题';

  @override
  String get primaryColor => '主色调';

  @override
  String get secondaryColor => '次要色调';

  @override
  String get selectPrimaryColor => '选择应用的主色调';

  @override
  String get selectSecondaryColor => '选择应用的次要色调';

  @override
  String get selectColor => '选择颜色';

  @override
  String get hue => '色调';

  @override
  String get saturation => '饱和度';

  @override
  String get lightness => '亮度';

  @override
  String get applyCustomTheme => '应用自定义主题';

  @override
  String get customThemeApplied => '自定义主题应用成功';

  @override
  String get themeColorApplied => '主题颜色已应用';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get repeat => '重复';

  @override
  String get repeatTask => '重复任务';

  @override
  String get repeatType => '重复类型';

  @override
  String get daily => '每日';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get weekdays => '工作日';

  @override
  String get selectDays => '选择日期';

  @override
  String get selectDate => '选择日期';

  @override
  String get everyDay => '每天';

  @override
  String get everyWeek => '每周';

  @override
  String get everyMonth => '每月';

  @override
  String get monday => '周一';

  @override
  String get tuesday => '周二';

  @override
  String get wednesday => '周三';

  @override
  String get thursday => '周四';

  @override
  String get friday => '周五';

  @override
  String get saturday => '周六';

  @override
  String get sunday => '周日';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get noEndDate => '无结束日期';

  @override
  String get timeRange => '时间范围';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get noStartTimeSet => '未设置开始时间';

  @override
  String get noEndTimeSet => '未设置结束时间';

  @override
  String get invalidTimeRange => '结束时间必须晚于开始时间';

  @override
  String get repeatEnabled => '启用重复';

  @override
  String get repeatDescription => '自动创建重复任务';

  @override
  String get backfillMode => '补漏模式';

  @override
  String get backfillModeDescription => '为之前错过的日期自动创建重复任务';

  @override
  String get backfillDays => '向前补漏天数';

  @override
  String get backfillDaysDescription => '最大向前扫描天数（1-365，不含今天）';

  @override
  String get backfillAutoComplete => '补漏任务自动标记为已完成';

  @override
  String get backfillDaysRangeError => '补漏天数必须在 1 到 365 之间';

  @override
  String get backfillConflictTitle => '补漏范围冲突';

  @override
  String backfillConflictMessage(
    Object title,
    Object startDate,
    Object backfillStartDate,
  ) {
    return '「$title」的开始日期为 $startDate，但按补漏天数会向前补到 $backfillStartDate。本次强制刷新以哪个为最早可生成日期？';
  }

  @override
  String get useStartDate => '以开始日期为准';

  @override
  String get useBackfillDays => '以补漏天数为准';

  @override
  String get activeRepeatTasks => '活跃的重复任务';

  @override
  String get noRepeatTasks => '暂无重复任务';

  @override
  String get pauseRepeat => '暂停';

  @override
  String get resumeRepeat => '恢复';

  @override
  String get editRepeat => '编辑';

  @override
  String get deleteRepeat => '删除';

  @override
  String get repeatTaskConfirm => '删除重复任务';

  @override
  String get repeatTaskDeleteMessage => '这将删除从此模板生成的所有重复任务。此操作不可撤销。';

  @override
  String get manageRepeatTasks => '管理重复任务';

  @override
  String get comingSoon => '即将推出！';

  @override
  String get todos => '待办事项';

  @override
  String get schedule => '日程';

  @override
  String get clearDataWarning => '这将永久删除您的所有待办事项和统计数据。此操作无法撤销。';

  @override
  String get dataClearedSuccess => '所有数据已成功清除';

  @override
  String get clearDataFailed => '清除数据失败';

  @override
  String get history => '历史';

  @override
  String get stats => '统计';

  @override
  String get searchTodos => '搜索待办事项';

  @override
  String get addTodo => '添加待办';

  @override
  String get addTodoHint => '需要做什么？';

  @override
  String get todoTitle => '标题';

  @override
  String get todoDescription => '描述';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get complete => '完成';

  @override
  String get incomplete => '未完成';

  @override
  String get allTodos => '全部';

  @override
  String get activeTodos => '进行中';

  @override
  String get completedTodos => '已完成';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get thisWeek => '本周';

  @override
  String get thisMonth => '本月';

  @override
  String get older => '更早';

  @override
  String get totalTodos => '总待办事项';

  @override
  String get completedTodosCount => '已完成';

  @override
  String get activeTodosCount => '进行中';

  @override
  String get completionRate => '完成率';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get backupSuccess => '备份创建成功';

  @override
  String get backupFailed => '备份失败';

  @override
  String get restoreSuccess => '数据恢复成功';

  @override
  String restoreFailed(Object error) {
    return '恢复失败: $error';
  }

  @override
  String get webBackupHint => 'Web端：备份通过下载/上传完成。';

  @override
  String restoreWarning(Object fileName) {
    return '这将用来自\"$fileName\"的数据替换所有当前数据。此操作无法撤销。继续吗？';
  }

  @override
  String get totalStorage => '总存储';

  @override
  String get todosStorage => '待办事项';

  @override
  String get cacheStorage => '缓存';

  @override
  String get clearCache => '清除缓存';

  @override
  String get cacheCleared => '缓存清除成功';

  @override
  String get filterByStatus => '按状态筛选';

  @override
  String get sortBy => '排序方式';

  @override
  String get newestFirst => '最新优先';

  @override
  String get oldestFirst => '最早优先';

  @override
  String get alphabetical => '字母顺序';

  @override
  String get overview => '概览';

  @override
  String get weeklyProgress => '每周进度';

  @override
  String get monthlyTrends => '每月趋势';

  @override
  String get productivityOverview => '生产力概览';

  @override
  String get overallCompletionRate => '总体完成率';

  @override
  String get created => '创建时间';

  @override
  String get recentActivity => '最近活动';

  @override
  String get noRecentActivity => '暂无最近活动';

  @override
  String get todoDistribution => '待办事项分布';

  @override
  String get bestPerformance => '最佳表现';

  @override
  String get noCompletedTodosYet => '暂无已完成的待办事项';

  @override
  String get completionRateDescription => '的待办事项已完成';

  @override
  String get fingerprintLock => '指纹锁';

  @override
  String get fingerprintLockSubtitle => '使用指纹保护应用安全';

  @override
  String get fingerprintLockEnable => '启用指纹锁';

  @override
  String get fingerprintLockDisable => '禁用指纹锁';

  @override
  String get fingerprintLockEnabled => '指纹锁已启用';

  @override
  String get fingerprintLockDisabled => '指纹锁已禁用';

  @override
  String get fingerprintNotAvailable => '设备不支持指纹识别';

  @override
  String get fingerprintNotEnrolled => '未注册指纹';

  @override
  String get fingerprintAuthenticationFailed => '指纹验证失败';

  @override
  String get fingerprintAuthenticationSuccess => '指纹验证成功';

  @override
  String get active => '进行中';

  @override
  String get mon => '周一';

  @override
  String get tue => '周二';

  @override
  String get wed => '周三';

  @override
  String get thu => '周四';

  @override
  String get fri => '周五';

  @override
  String get sat => '周六';

  @override
  String get sun => '周日';

  @override
  String get week1 => '第1周';

  @override
  String get week2 => '第2周';

  @override
  String get week3 => '第3周';

  @override
  String get week4 => '第4周';

  @override
  String withCompletedTodos(Object count) {
    return '完成了 $count 个待办事项';
  }

  @override
  String get unableToLoadBackupStats => '无法加载备份统计信息';

  @override
  String get backupSummary => '备份摘要';

  @override
  String get itemsToBackup => '待备份项目';

  @override
  String get dataSize => '数据大小';

  @override
  String get backupFiles => '备份文件';

  @override
  String get backupSize => '备份大小';

  @override
  String get quickActions => '快速操作';

  @override
  String get backupRestoreDescription => '创建数据备份或从之前的备份中恢复。';

  @override
  String get createBackup => '创建备份';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get noBackupFilesFound => '未找到备份文件';

  @override
  String get createFirstBackup => '创建您的第一个备份以开始使用';

  @override
  String get refresh => '刷新';

  @override
  String get restoreFromFile => '从此文件恢复';

  @override
  String get deleteFile => '删除文件';

  @override
  String get aboutBackups => '关于备份';

  @override
  String get backupInfo1 => '• 备份包含您所有的待办事项和统计数据';

  @override
  String get backupInfo2 => '• 将备份文件存储在安全位置';

  @override
  String get backupInfo3 => '• 定期备份有助于防止数据丢失';

  @override
  String get backupInfo4 => '• 您可以从任何备份文件中恢复';

  @override
  String get backupCreatedSuccess => '备份创建成功';

  @override
  String get noBackupFilesAvailable => '没有可用的备份文件用于恢复';

  @override
  String get selectBackupFile => '选择备份文件';

  @override
  String get confirmRestore => '确认恢复';

  @override
  String dataRestoredSuccess(Object fileName) {
    return '数据已成功从\"$fileName\"恢复';
  }

  @override
  String get deleteBackupFile => '删除备份文件';

  @override
  String deleteBackupWarning(Object fileName) {
    return '您确定要删除\"$fileName\"吗？此操作无法撤销。';
  }

  @override
  String backupFileDeletedSuccess(Object fileName) {
    return '备份文件\"$fileName\"删除成功';
  }

  @override
  String get backupFileNotFound => '备份文件未找到';

  @override
  String invalidFilePath(Object fileName) {
    return '\"$fileName\"的文件路径无效';
  }

  @override
  String get failedToDeleteFile => '删除文件失败';

  @override
  String get files => '文件';

  @override
  String get storageManagement => '存储管理';

  @override
  String get storageOverview => '存储概览';

  @override
  String get storageAnalytics => '存储分析';

  @override
  String get noPendingRequests => '没有待处理的请求';

  @override
  String get request => '请求';

  @override
  String get unknown => '未知';

  @override
  String get waiting => '等待中';

  @override
  String get noRecentRequests => '没有最近的请求';

  @override
  String get requestCompleted => '请求已完成';

  @override
  String get noTodosToDisplay => '暂无待办事项显示';

  @override
  String get todoStatusDistribution => '待办状态分布';

  @override
  String get completed => '已完成';

  @override
  String get pending => '进行中';

  @override
  String get dataStorageUsage => '数据存储使用情况';

  @override
  String get total => '总计';

  @override
  String get storageCleanup => '存储清理';

  @override
  String get cleanupDescription => '通过删除不必要的数据来释放存储空间：';

  @override
  String get clearCompletedTodos => '清除已完成待办';

  @override
  String get clearOldStatistics => '清除旧统计数据';

  @override
  String get clearBackupFiles => '清除备份文件';

  @override
  String get cleanupCompleted => '清理完成';

  @override
  String todosDeleted(Object count) {
    return '删除了 $count 个待办';
  }

  @override
  String statisticsDeleted(Object count) {
    return '删除了 $count 个统计数据';
  }

  @override
  String backupFilesDeleted(Object count) {
    return '删除了 $count 个备份文件';
  }

  @override
  String get cleanupFailed => '清理失败';

  @override
  String get easyTodo => '轻单';

  @override
  String copiedToClipboard(Object url) {
    return '已复制到剪贴板: $url';
  }

  @override
  String cannotOpenLink(Object url) {
    return '无法打开链接，已复制到剪贴板: $url';
  }

  @override
  String get email => '邮箱';

  @override
  String get github => 'GitHub';

  @override
  String get website => '网站';

  @override
  String get noTodosMatchSearch => '没有匹配的待办事项';

  @override
  String get noCompletedTodos => '暂无已完成的待办事项';

  @override
  String get noActiveTodos => '暂无进行中的待办事项';

  @override
  String get noTodosYet => '暂无待办事项';

  @override
  String get deleteTodoConfirmation => '确定要删除这个待办事项吗？';

  @override
  String get createdLabel => '创建时间：';

  @override
  String get completedLabel => '完成时间：';

  @override
  String get filterByTime => '按时间筛选';

  @override
  String get sortByTime => '按时间排序';

  @override
  String get ascending => '升序';

  @override
  String get descending => '降序';

  @override
  String get threeDays => '近三天';

  @override
  String minutesAgoWithCount(Object count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgoWithCount(Object count) {
    return '$count 小时前';
  }

  @override
  String daysAgoWithCount(Object count) {
    return '$count 天前';
  }

  @override
  String get notificationSettings => '通知设置';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get dailySummary => '每日摘要';

  @override
  String get dailySummaryTime => '每日摘要时间';

  @override
  String get dailySummaryDescription => '接收待办事项的每日摘要';

  @override
  String get defaultReminderSettings => '默认提醒设置';

  @override
  String get enableDefaultReminders => '启用默认提醒';

  @override
  String get reminderTimeBefore => '提前提醒时间';

  @override
  String minutesBefore(Object count) {
    return '提前 $count 分钟';
  }

  @override
  String get notificationPermissions => '通知权限';

  @override
  String get grantPermissions => '授予权限';

  @override
  String get permissionsGranted => '权限已授予';

  @override
  String get permissionsDenied => '权限已拒绝';

  @override
  String get testNotification => '测试通知';

  @override
  String get sendTestNotification => '发送测试通知';

  @override
  String get notificationTestSent => '测试通知发送成功';

  @override
  String get reminderTime => '提醒时间';

  @override
  String get setReminder => '设置提醒';

  @override
  String reminderSet(Object time) {
    return '提醒已设置为 $time';
  }

  @override
  String get cancelReminder => '取消提醒';

  @override
  String get noReminderSet => '未设置提醒';

  @override
  String get enableReminder => '启用提醒';

  @override
  String get reminderOptions => '提醒选项';

  @override
  String get pomodoroTimer => '番茄钟';

  @override
  String get pomodoroSettings => '番茄钟设置';

  @override
  String get workDuration => '工作时长';

  @override
  String get breakDuration => '休息时长';

  @override
  String get longBreakDuration => '长休息时长';

  @override
  String get sessionsUntilLongBreak => '长休息间隔次数';

  @override
  String get minutes => '分钟';

  @override
  String get sessions => '次';

  @override
  String get settingsSaved => '设置保存成功';

  @override
  String get focusTime => '专注时间';

  @override
  String get clearOldPomodoroSessions => '清理旧番茄钟会话';

  @override
  String pomodoroSessionsDeleted(Object count) {
    return '删除了 $count 个番茄钟会话';
  }

  @override
  String get breakTime => '休息时间';

  @override
  String get start => '开始';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get stop => '停止';

  @override
  String get timeSpent => '已用时间';

  @override
  String get pomodoroStats => '番茄钟统计';

  @override
  String get sessionsCompleted => '完成会话';

  @override
  String get totalTime => '总时长';

  @override
  String get averageTime => '平均时长';

  @override
  String get focusSessions => '专注会话';

  @override
  String get pomodoroSessions => '番茄钟会话';

  @override
  String get totalFocusTime => '总专注时间';

  @override
  String get weeklyPomodoroStats => '周番茄钟统计';

  @override
  String get totalSessions => '总会话数';

  @override
  String get averageSessions => '平均会话数';

  @override
  String get monthlyPomodoroStats => '月番茄钟统计';

  @override
  String get averagePerWeek => '每周平均';

  @override
  String get pomodoroOverview => '番茄钟概览';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkUpdatesSubtitle => '搜索新版本';

  @override
  String get checkingForUpdates => '正在检查更新';

  @override
  String get pleaseWait => '请稍候，我们正在检查更新...';

  @override
  String get updateAvailable => '有新版本';

  @override
  String get requiredUpdate => '需要更新';

  @override
  String versionAvailable(Object version) {
    return '版本 $version 已可用！';
  }

  @override
  String get whatsNew => '更新内容：';

  @override
  String get noUpdatesAvailable => '没有可用更新';

  @override
  String get youHaveLatestVersion => '您已使用最新版本';

  @override
  String get updateNow => '立即更新';

  @override
  String get later => '稍后';

  @override
  String get downloadingUpdate => '正在下载更新';

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get downloadFrom => '正在从以下地址下载更新：';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get couldNotOpenDownloadUrl => '无法打开下载链接';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String get forceUpdateMessage => '有必需的更新可用。请更新以继续使用应用。';

  @override
  String get optionalUpdateMessage => '您可以现在或稍后更新';

  @override
  String get storagePermissionDenied => '存储权限被拒绝';

  @override
  String get cannotAccessStorage => '无法访问存储';

  @override
  String get updateDownloadSuccess => '更新下载成功';

  @override
  String get installUpdate => '安装更新';

  @override
  String get startingInstaller => '正在启动安装程序...';

  @override
  String get updateFileNotFound => '更新文件不存在，请重新下载';

  @override
  String get installPermissionRequired => '需要安装权限';

  @override
  String get installPermissionDescription =>
      '安装应用更新需要\"安装未知应用\"权限。请在设置中为轻单开启此权限。';

  @override
  String get needInstallPermission => '需要安装权限才能更新应用';

  @override
  String installFailed(Object error) {
    return '安装失败: $error';
  }

  @override
  String installLaunchFailed(Object error) {
    return '安装启动失败: $error';
  }

  @override
  String get storagePermissionTitle => '需要存储权限';

  @override
  String get storagePermissionDescription => '为了下载和安装应用更新，轻单 需要访问设备存储。';

  @override
  String get permissionNote => '点击\"允许\"将授予应用以下权限：';

  @override
  String get accessDeviceStorage => '• 访问设备存储';

  @override
  String get downloadFilesToDevice => '• 下载文件到设备';

  @override
  String get allow => '允许';

  @override
  String get openSettings => '打开设置';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get permissionDeniedMessage => '存储权限被永久拒绝。请在系统设置中手动开启权限，然后重试。';

  @override
  String get cannotOpenSettings => '无法打开设置页面';

  @override
  String get autoUpdate => '自动更新';

  @override
  String get autoUpdateSubtitle => '应用启动时自动检查更新';

  @override
  String get autoUpdateEnabled => '自动更新已启用';

  @override
  String get autoUpdateDisabled => '自动更新已禁用';

  @override
  String get exitApp => '退出应用';

  @override
  String get viewSettings => '视图设置';

  @override
  String get viewDisplay => '视图显示';

  @override
  String get viewDisplaySubtitle => '配置内容显示方式';

  @override
  String get todoViewSettings => '待办事项视图设置';

  @override
  String get historyViewSettings => '历史视图设置';

  @override
  String get viewMode => '视图模式';

  @override
  String get listView => '列表视图';

  @override
  String get stackingView => '堆叠视图';

  @override
  String get calendarView => '日历视图';

  @override
  String get openInNewPage => '在新页面中打开';

  @override
  String get openInNewPageSubtitle => '在新页面中打开视图而不是弹窗';

  @override
  String get historyViewMode => '历史视图模式';

  @override
  String get dayDetails => '日期详情';

  @override
  String get todoCount => '待办数量';

  @override
  String get completedCount => '已完成';

  @override
  String get totalCount => '总计';

  @override
  String get appLongDescription =>
      'Easy Todo 是一个干净、优雅且功能强大的待办事项列表应用程序，旨在帮助您高效地组织日常任务。凭借精美的UI设计、全面的统计跟踪、无缝的API集成和多语言支持，Easy Todo 使任务管理变得简单而愉快。功能包括日历视图、历史记录跟踪、备份与恢复、生物识别身份验证和可自定义主题，以匹配您的个人风格。';

  @override
  String get cannotDeleteRepeatTodo => '不可删除从重复任务生成的待办事项';

  @override
  String get appTitle => '轻单';

  @override
  String get filterAll => '全部';

  @override
  String get filterTodayTodos => '今日待办';

  @override
  String get filterCompleted => '已完成';

  @override
  String get filterThisWeek => '本周';

  @override
  String get resetButton => '重置';

  @override
  String get applyButton => '应用';

  @override
  String get repeatTaskWarning => '此待办事项是从重复任务自动生成的，删除后明天会重新生成。';

  @override
  String get learnMore => '了解';

  @override
  String get repeatTaskDialogTitle => '重复任务待办事项';

  @override
  String get repeatTaskExplanation =>
      '此待办事项是从重复任务模板自动创建的。删除它不会影响重复任务本身 - 明天会根据重复计划生成新的待办事项。如果您想停止生成这些待办事项，需要在重复任务管理部分编辑或删除重复任务模板。';

  @override
  String get iUnderstand => '我知道了';

  @override
  String get authenticateToContinue => '请验证身份以继续使用应用';

  @override
  String get retry => '重试';

  @override
  String get biometricReason => '请使用生物识别验证您的身份';

  @override
  String get biometricHint => '请使用生物识别';

  @override
  String get biometricNotRecognized => '生物识别未识别，请重试';

  @override
  String get biometricSuccess => '生物识别验证成功';

  @override
  String get biometricVerificationTitle => '生物识别验证';

  @override
  String addTodoError(Object error) {
    return '添加待办事项失败：$error';
  }

  @override
  String get titleRequired => '请输入标题';

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
    return '创建重复任务失败：$error';
  }

  @override
  String get repeatTaskTitleRequired => '请输入标题';

  @override
  String get importBackup => '导入备份';

  @override
  String get shareBackup => '分享备份';

  @override
  String get cannotAccessFile => '无法访问选中的文件';

  @override
  String get invalidBackupFormat => '无效的备份格式';

  @override
  String get importBackupTitle => '导入备份';

  @override
  String get import => '导入';

  @override
  String get backupShareSuccess => '备份文件分享成功';

  @override
  String get requiredUpdateAvailable => '有必需的更新可用。请更新以继续使用应用。';

  @override
  String updateCheckError(Object error) {
    return '检查更新时出错：$error';
  }

  @override
  String importingBackupFile(Object fileName) {
    return '即将导入备份文件 \"$fileName\"，这将覆盖当前的所有数据。确定继续吗？';
  }

  @override
  String hardcodedStringFound(Object fileName) {
    return '即将导入备份文件 \"$fileName\"，这将覆盖当前的所有数据。确定继续吗？';
  }

  @override
  String get testNotifications => '测试通知';

  @override
  String get testNotificationChannel => '测试通知通道';

  @override
  String get testNotificationContent => '这是一个测试通知，用于验证通知是否正常工作。';

  @override
  String get failedToSendTestNotification => '发送测试通知失败：';

  @override
  String get failedToCheckForUpdates => '检查更新失败';

  @override
  String get errorCheckingForUpdates => '检查更新时出错：';

  @override
  String get updateFileName => 'easy_todo_update.apk';

  @override
  String get unknownDate => '未知日期';

  @override
  String get restoreSuccessPrefix => '已恢复 ';

  @override
  String get restoreSuccessSuffix => ' 个待办事项';

  @override
  String get importSuccessPrefix => '备份文件导入成功，恢复了 ';

  @override
  String get importFailedPrefix => '导入失败：';

  @override
  String get cleanupFailedPrefix => '清理失败：';

  @override
  String get developerName => '梦凌汐 (MeowLynxSea)';

  @override
  String get createYourFirstRepeatTask => '创建您的第一个重复任务以开始使用';

  @override
  String get rate => '比率';

  @override
  String get openSource => '开源';

  @override
  String get repeatTodoTest => '重复待办测试';

  @override
  String get repeatTodos => '重复待办';

  @override
  String get addRepeatTodo => '添加重复待办';

  @override
  String get checkRepeatTodos => '检查重复待办';

  @override
  String get authenticateToAccessApp => '请使用指纹验证以访问应用';

  @override
  String get backupFileSubject => '轻单备份文件';

  @override
  String get shareFailedPrefix => '分享失败：';

  @override
  String get schedulingTodoReminder => '正在安排待办提醒 \"';

  @override
  String get todoReminderTimerScheduled => '待办提醒计时器安排成功';

  @override
  String get allRemindersRescheduled => '所有提醒已重新安排';

  @override
  String get allTimersCleared => '所有计时器已清除';

  @override
  String get allNotificationChannelsCreated => '所有通知渠道创建成功';

  @override
  String get utc => 'UTC';

  @override
  String get gmt => 'GMT';

  @override
  String get authenticateToEnableFingerprint => '请验证身份以启用指纹锁';

  @override
  String get authenticateToDisableFingerprint => '请验证身份以禁用指纹锁';

  @override
  String get authenticateToAccessWithFingerprint => '请使用指纹验证以访问应用';

  @override
  String get authenticateToAccessWithBiometric => '请使用生物识别验证您的身份以继续';

  @override
  String get authenticateToClearData => '请使用生物识别验证以清除所有数据';

  @override
  String get clearDataFailedPrefix => '清除数据失败：';

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
    return '每 $count 天';
  }

  @override
  String get dataStatistics => '数据统计';

  @override
  String get dataStatisticsDescription => '启用数据统计的重复任务数量';

  @override
  String get statisticsModes => '统计模式';

  @override
  String get statisticsModesDescription => '选择要应用的统计分析方法';

  @override
  String get dataUnit => '数据单位';

  @override
  String get dataUnitHint => '例如：kg, km, \$, %';

  @override
  String get statisticsModeAverage => '平均值';

  @override
  String get statisticsModeGrowth => '增长率';

  @override
  String get statisticsModeExtremum => '极值';

  @override
  String get statisticsModeTrend => '趋势';

  @override
  String get enterDataToComplete => '输入数据以完成';

  @override
  String get enterDataDescription => '此重复任务需要输入数据才能完成';

  @override
  String get dataValue => '数据值';

  @override
  String get dataValueHint => '请输入一个数值';

  @override
  String get dataValueRequired => '请输入数据值以完成此任务';

  @override
  String get invalidDataValue => '请输入有效的数字';

  @override
  String get dataStatisticsTab => '数据统计';

  @override
  String get selectRepeatTask => '选择重复任务';

  @override
  String get selectRepeatTaskHint => '选择一个重复任务查看其统计数据';

  @override
  String get timePeriod => '时间周期';

  @override
  String get timePeriodToday => '今天';

  @override
  String get timePeriodThisWeek => '本周';

  @override
  String get timePeriodThisMonth => '本月';

  @override
  String get timePeriodOverview => '概览';

  @override
  String get timePeriodCustom => '自定义范围';

  @override
  String get selectCustomRange => '选择日期范围';

  @override
  String get noRepeatTasksWithStats => '没有启用统计的重复任务';

  @override
  String get noDataAvailable => '所选时间段内暂无数据';

  @override
  String get dataProgressToday => '今日进度';

  @override
  String get averageValue => '平均值';

  @override
  String get totalValue => '总计';

  @override
  String get dataPoints => '数据点';

  @override
  String get growthRate => '增长率';

  @override
  String get trendAnalysis => '趋势分析';

  @override
  String get maximumValue => '最大值';

  @override
  String get minimumValue => '最小值';

  @override
  String get extremumAnalysis => '极值分析';

  @override
  String get statisticsSummary => '统计摘要';

  @override
  String get dataVisualization => '数据可视化';

  @override
  String get chartTitle => '数据趋势';

  @override
  String get lineChart => '折线图';

  @override
  String get barChart => '柱状图';

  @override
  String get showValueOnDrag => '在图表上拖动时显示数值';

  @override
  String get dragToShowValue => '拖动图表查看详细数值';

  @override
  String get analytics => '分析';

  @override
  String get dataEntry => '数据输入';

  @override
  String get statisticsEnabled => '统计已启用';

  @override
  String get dataCollection => '数据收集';

  @override
  String repeatTodoWithStats(Object count) {
    return '启用统计的重复任务：$count';
  }

  @override
  String dataEntries(Object count) {
    return '数据条目：$count';
  }

  @override
  String withDataValues(Object count) {
    return '有数值：$count';
  }

  @override
  String totalDataSize(Object size) {
    return '总数据大小：$size';
  }

  @override
  String get dataBackupSupported => '支持数据备份和恢复';

  @override
  String get repeatTasks => '重复任务';

  @override
  String get dataStatisticsEnabled => '数据统计已启用';

  @override
  String get statisticsData => '统计数据';

  @override
  String get dataStatisticsEnabledShort => '数据统计';

  @override
  String get dataWithValue => '有数值';

  @override
  String get noDataStatisticsEnabled => '未启用数据统计';

  @override
  String get enableDataStatisticsHint => '为重复任务启用数据统计以查看分析结果';

  @override
  String get selectTimePeriod => '选择时间周期';

  @override
  String get customRange => '自定义范围';

  @override
  String get selectRepeatTaskToViewData => '选择一个重复任务查看其数据统计';

  @override
  String get noStatisticsData => '暂无统计数据';

  @override
  String get completeSomeTodosToSeeData => '完成一些带数据的待办事项以查看统计';

  @override
  String get totalEntries => '总条目';

  @override
  String get average => '平均值';

  @override
  String get min => '最小值';

  @override
  String get max => '最大值';

  @override
  String get totalGrowth => '总增长';

  @override
  String get notEnoughDataForCharts => '数据不足，无法显示图表';

  @override
  String get averageTrend => '平均趋势';

  @override
  String get averageChartDescription => '显示随时间变化的平均值和趋势分析';

  @override
  String get trendDirection => '趋势方向';

  @override
  String get trendStrength => '趋势强度';

  @override
  String get growthAnalysis => '增长分析';

  @override
  String get range => '范围';

  @override
  String get stableTrendDescription => '稳定趋势，变化最小';

  @override
  String get weakTrendDescription => '弱趋势，有一定变化';

  @override
  String get moderateTrendDescription => '中等趋势，方向明确';

  @override
  String get strongTrendDescription => '强趋势，变化显著';

  @override
  String get invalidNumberFormat => '无效的数字格式';

  @override
  String get dataUnitRequired => '启用数据统计时需要填写数据单位';

  @override
  String get growth => '增长';

  @override
  String get extremum => '极值';

  @override
  String get trend => '趋势';

  @override
  String get dataInputRequired => '需要输入数据才能完成此任务';

  @override
  String get todayProgress => '今日进度';

  @override
  String get dataProgress => '数据进度';

  @override
  String get noDataForToday => '今日暂无数据';

  @override
  String get weeklyDataStats => '本周数据统计';

  @override
  String get noDataForThisWeek => '本周暂无数据';

  @override
  String get daysTracked => '跟踪天数';

  @override
  String get monthlyDataStats => '本月数据统计';

  @override
  String get noDataForThisMonth => '本月暂无数据';

  @override
  String get customDateRange => '自定义日期范围';

  @override
  String get allData => '全部数据';

  @override
  String get breakdownByTask => '按任务分解';

  @override
  String get clear => '清除';

  @override
  String get trendUp => '上升趋势';

  @override
  String get trendDown => '下降趋势';

  @override
  String get trendStable => '稳定趋势';

  @override
  String get needMoreDataToAnalyze => '需要收集更多数据以分析';

  @override
  String get taskCompleted => '任务已完成';

  @override
  String get taskWithdrawn => '任务已撤回';

  @override
  String get noDefaultSettings => '没有保存的设置，创建默认设置';

  @override
  String get authenticateForSensitiveOperation => '请使用生物识别验证您的身份以继续';

  @override
  String get insufficientData => '数据不足';

  @override
  String get stable => '平稳';

  @override
  String get strongUpward => '强劲上升';

  @override
  String get upward => '上升';

  @override
  String get strongDownward => '强劲下降';

  @override
  String get downward => '下降';

  @override
  String get repeatTasksRefreshedSuccessfully => '重复任务刷新成功';

  @override
  String get errorRefreshingRepeatTasks => '刷新重复任务时出错';

  @override
  String get forceRefresh => '强制刷新';

  @override
  String get errorLoadingRepeatTasks => '加载重复任务时出错';

  @override
  String get pleaseCheckStoragePermissions => '请检查您的存储权限并重试';

  @override
  String get todoReminders => '待办事项提醒';

  @override
  String get notificationsForIndividualTodoReminders => '个人待办事项提醒通知';

  @override
  String get notificationsForDailySummary => '待办事项每日摘要';

  @override
  String get pomodoroComplete => '番茄钟完成';

  @override
  String get notificationsForPomodoroSessions => '番茄钟会话完成通知';

  @override
  String get dailyTodoSummary => '每日待办摘要';

  @override
  String youHavePendingTodos(Object count, Object n, Object s) {
    return '您有 $count 个待办待完成事项';
  }

  @override
  String greatJobTimeForBreak(Object breakType) {
    return '做得好！是时候休息一下了';
  }

  @override
  String get shortBreak => '短';

  @override
  String get longBreak => '长';

  @override
  String get themeColorMysteriousPurple => '神秘紫';

  @override
  String get themeColorSkyBlue => '天空蓝';

  @override
  String get themeColorGemGreen => '宝石绿';

  @override
  String get themeColorLemonYellow => '柠檬黄';

  @override
  String get themeColorFlameRed => '火焰红';

  @override
  String get themeColorElegantPurple => '高雅紫';

  @override
  String get themeColorCherryPink => '樱花粉';

  @override
  String get themeColorForestCyan => '森林青';

  @override
  String get aiSettings => 'AI 设置';

  @override
  String get aiFeatures => 'AI 功能';

  @override
  String get aiEnabled => 'AI 功能已启用';

  @override
  String get aiDisabled => 'AI 功能已禁用';

  @override
  String get enableAIFeatures => '启用 AI 功能';

  @override
  String get enableAIFeaturesSubtitle => '使用人工智能增强您的待办事项体验';

  @override
  String get apiConfiguration => 'API 配置';

  @override
  String get apiEndpoint => 'API 端点';

  @override
  String get pleaseEnterApiEndpoint => '请输入 API 端点';

  @override
  String get invalidApiEndpoint => '请输入有效的 API 端点';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get pleaseEnterApiKey => '请输入 API 密钥';

  @override
  String get modelName => '模型名称';

  @override
  String get pleaseEnterModelName => '请输入模型名称';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get timeout => '超时时间 (毫秒)';

  @override
  String get pleaseEnterTimeout => '请输入超时时间';

  @override
  String get invalidTimeout => '请输入有效的超时时间（最少 1000 毫秒）';

  @override
  String get temperature => '温度';

  @override
  String get pleaseEnterTemperature => '请输入温度';

  @override
  String get invalidTemperature => '请输入有效的温度（0.0 - 2.0）';

  @override
  String get maxTokens => '最大令牌数';

  @override
  String get pleaseEnterMaxTokens => '请输入最大令牌数';

  @override
  String get invalidMaxTokens => '请输入有效的最大令牌数（最少 1）';

  @override
  String get rateLimit => '速率限制';

  @override
  String get rateLimitSubtitle => '每分钟最大请求数';

  @override
  String get pleaseEnterRateLimit => '请输入速率限制';

  @override
  String get invalidRateLimit => '速率限制必须在 1 到 100 之间';

  @override
  String get rateAndTokenLimits => '速率和令牌限制';

  @override
  String get testConnection => '测试连接';

  @override
  String get connectionSuccessful => '连接成功！';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get aiFeaturesToggle => 'AI 功能开关';

  @override
  String get autoCategorization => '自动分类';

  @override
  String get autoCategorizationSubtitle => '自动为您的任务分类';

  @override
  String get prioritySorting => '优先级排序';

  @override
  String get prioritySortingSubtitle => '评估任务重要性和优先级';

  @override
  String get motivationalMessages => '激励消息';

  @override
  String get motivationalMessagesSubtitle => '根据您的进度生成鼓励消息';

  @override
  String get smartNotifications => '智能通知';

  @override
  String get smartNotificationsSubtitle => '创建个性化通知内容';

  @override
  String get completionMotivation => '完成激励';

  @override
  String get completionMotivationSubtitle => '根据每日完成率显示激励内容';

  @override
  String get aiCategoryWork => '工作';

  @override
  String get aiCategoryPersonal => '个人';

  @override
  String get aiCategoryStudy => '学习';

  @override
  String get aiCategoryHealth => '健康';

  @override
  String get aiCategoryFitness => '健身';

  @override
  String get aiCategoryFinance => '财务';

  @override
  String get aiCategoryShopping => '购物';

  @override
  String get aiCategoryFamily => '家庭';

  @override
  String get aiCategorySocial => '社交';

  @override
  String get aiCategoryHobby => '爱好';

  @override
  String get aiCategoryTravel => '旅行';

  @override
  String get aiCategoryOther => '其他';

  @override
  String get aiPriorityHigh => '高优先级';

  @override
  String get aiPriorityMedium => '中优先级';

  @override
  String get aiPriorityLow => '低优先级';

  @override
  String get aiPriorityUrgent => '紧急';

  @override
  String get aiPriorityImportant => '重要';

  @override
  String get aiPriorityNormal => '普通';

  @override
  String get selectTodoForPomodoro => '选择待办事项';

  @override
  String get pomodoroDescription => '选择一个待办事项开始番茄钟专注时间';

  @override
  String get noTodosForPomodoro => '暂无可用的待办事项';

  @override
  String get createTodoForPomodoro => '请先创建一些待办事项';

  @override
  String get todaySessions => '今日会话';

  @override
  String get startPomodoro => '开始番茄钟';

  @override
  String get aiDebugInfo => 'AI 调试信息';

  @override
  String get processingUnprocessedTodos => '正在使用 AI 处理未处理的待办事项';

  @override
  String get processAllTodosWithAI => '使用 AI 处理所有待办事项';

  @override
  String todayTimeFormat(Object time) {
    return '今天 $time';
  }

  @override
  String tomorrowTimeFormat(Object time) {
    return '明天 $time';
  }

  @override
  String get deleteTodoDialogTitle => '删除';

  @override
  String get deleteTodoDialogMessage => '确定要删除这个待办事项吗？';

  @override
  String get deleteTodoDialogCancel => '取消';

  @override
  String get deleteTodoDialogDelete => '删除';

  @override
  String get customPersona => '自定义人设';

  @override
  String get personaPrompt => '人设提示词';

  @override
  String get personaPromptHint => '例如：你是一个风趣的助手，喜欢使用幽默和表情符号...';

  @override
  String get personaPromptDescription => '自定义 AI 的通知个性风格。这将应用于待办事项提醒和每日总结。';

  @override
  String get personaExample1 => '你是一个激励型教练，通过积极强化来鼓励用户';

  @override
  String get personaExample2 => '你是一个幽默的助手，使用轻松的幽默和表情符号';

  @override
  String get personaExample3 => '你是一个专业的生产力专家，给出简洁的建议';

  @override
  String get personaExample4 => '你是一个支持性的朋友，用温暖和关怀来提醒用户';

  @override
  String get aiDebugInfoTitle => 'AI 调试信息';

  @override
  String get aiDebugInfoSubtitle => '检查 AI 功能状态';

  @override
  String get aiSettingsStatus => 'AI 设置状态';

  @override
  String get aiFeatureToggles => 'AI 功能开关';

  @override
  String get aiTodoProviderConnection => '待办事项提供者连接';

  @override
  String get aiMessages => 'AI 消息';

  @override
  String get aiApiRequestManager => 'API 请求管理器';

  @override
  String get aiCurrentRequestQueue => '当前请求队列';

  @override
  String get aiRecentRequests => '最近请求';

  @override
  String get aiPermissionRequestMessage =>
      '请在系统设置中为\"Easy Todo\"开启\"闹钟和提醒\"权限。';

  @override
  String get developerNameMeowLynxSea => '梦凌汐 (MeowLynxSea)';

  @override
  String get developerEmail => 'mew@meowdream.cn';

  @override
  String get developerGithub => 'github.com/MeowLynxSea';

  @override
  String get developerWebsite => 'www.meowdream.cn';

  @override
  String get backupFileShareSubject => 'Easy Todo 备份文件';

  @override
  String shareFailed(Object error) {
    return '分享失败: $error';
  }

  @override
  String get authenticateToAccessAppMessage => '请使用指纹访问应用';

  @override
  String get aiFeaturesEnabled => 'AI 功能已启用';

  @override
  String get aiServiceValid => 'AI 服务有效';

  @override
  String get notConfigured => '未配置';

  @override
  String configured(Object count) {
    return '已配置 ($count 字符)';
  }

  @override
  String get aiProviderConnected => 'AI 提供者已连接';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get aiProcessedTodos => 'AI 处理的待办事项';

  @override
  String get todosWithAICategory => '有 AI 类别的待办事项';

  @override
  String get todosWithAIPriority => '有 AI 优先级的待办事项';

  @override
  String get lastError => '最后错误';

  @override
  String get pendingRequests => '待处理的请求';

  @override
  String get currentWindowRequests => '当前窗口请求';

  @override
  String get maxRequestsPerMinute => '最大请求/分钟';

  @override
  String get status => '状态';

  @override
  String get aiServiceNotAvailable => 'AI 服务不可用';

  @override
  String get completionMessages => '完成消息';

  @override
  String get exactAlarmPermission => '精确闹钟权限';

  @override
  String get exactAlarmPermissionContent =>
      '为了确保番茄钟和提醒功能准确运行，应用需要精确闹钟权限。\n\n请在系统设置中为\"Easy Todo\"开启\"闹钟和提醒\"权限。';

  @override
  String get setLater => '稍后设置';

  @override
  String get goToSettings => '去设置';

  @override
  String get batteryOptimizationSettings => '电池优化设置';

  @override
  String get batteryOptimizationContent =>
      '为了确保番茄钟和提醒功能在后台正常运行，请关闭本应用的电池优化。\n\n这可能会增加一些电池消耗，但能确保计时器和提醒功能准确工作。';

  @override
  String get breakTimeComplete => '休息时间结束！';

  @override
  String get timeToGetBackToWork => '该回去工作了！';

  @override
  String get aiServiceReturnedEmptyMessage => 'AI服务返回了空消息';

  @override
  String errorGeneratingMotivationalMessage(Object error) {
    return '生成激励消息时出错: $error';
  }

  @override
  String get aiServiceNotAvailableCheckSettings => 'AI服务不可用，请检查AI设置';

  @override
  String get filterByCategory => '按类别筛选';

  @override
  String get importance => '重要程度';

  @override
  String get noCategoriesAvailable => '暂无分类数据';

  @override
  String get aiWillCategorizeTasks => 'AI会自动为任务分类，请稍后再试';

  @override
  String get selectCategories => '选择分类';

  @override
  String get selectedCategories => '已选择';

  @override
  String get categories => '个分类';

  @override
  String get apiFormat => 'API 格式';

  @override
  String get apiFormatDescription =>
      '选择您的 AI 服务提供商。不同的提供商可能需要不同的 API 端点和身份验证方法。';

  @override
  String get openaiFormat => 'OpenAI';

  @override
  String get anthropicFormat => 'Anthropic';

  @override
  String aiPromptCategorization(Object description, Object title) {
    return '将这个待办任务分类到以下类别之一：\n      work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.\n\n      任务：\"$title\"\n      描述：\"$description\"\n\n      只用小写英文回复类别名称。';
  }

  @override
  String aiPromptPriority(
    Object deadline,
    Object description,
    Object hasDeadline,
    Object title,
  ) {
    return '评估这个待办任务的优先级（0-100），考虑：\n      - 紧急性：需要多快完成？（截止日期：$deadline）\n      - 影响：不完成会有什么后果？\n      - 努力程度：需要多少时间/资源？\n      - 个人重要性：这对你的价值如何？\n\n      任务：\"$title\"\n      描述：\"$description\"\n      有截止日期：$hasDeadline\n      截止日期：$deadline\n\n      指导原则：\n      - 0-20：低优先级，可以推迟\n      - 21-40：中等优先级，应该尽快做\n      - 41-70：高优先级，重要要完成\n      - 71-100：关键优先级，急需完成\n\n      只回复0-100的数字。';
  }

  @override
  String aiPromptMotivation(
    Object date,
    Object description,
    Object name,
    Object unit,
    Object value,
  ) {
    return '根据这个统计数据生成激励语句：\n      名称：\"$name\"\n      描述：\"$description\"\n      数值：$value\n      单位：\"$unit\"\n      日期：$date\n\n      要求：\n      - 使其具有鼓励性且与数据相关\n      - 保持25字符以内\n      - 专注于成就和进步\n      - 使用积极、行动导向的语言\n      - 示例：\"今天进步很大！🎯\" 或 \"继续加油！💪\"\n      - 只回复激励语句，不要包含任何说明';
  }

  @override
  String aiPromptNotification(
    Object category,
    Object description,
    Object priority,
    Object title,
  ) {
    return '为此任务创建个性化通知提醒：\n      任务：\"$title\"\n      描述：\"$description\"\n      类别：$category\n      优先级：$priority\n\n      要求：\n      - 创建标题和消息\n      - 标题：少于20个字符，吸引注意\n      - 消息：少于50个字符，具有激励性和可操作性\n      - 适当使用表情符号增加参与度\n      - 根据优先级包含紧急程度\n      - 使其个性化和鼓励性\n      - 严格按照以下格式回复，不要使用markdown或其他格式：\nTITLE: [你的标题]\nMESSAGE: [你的消息]\n      - 只返回这两行内容，不要包含任何说明文字';
  }

  @override
  String aiPromptCompletion(Object completed, Object percentage, Object total) {
    return '根据今日待办完成情况生成鼓励语句：\n      已完成：$completed/$total个任务\n      完成率：$percentage%\n\n      要求：\n      - 使其积极且具有激励性\n      - 保持25字符以内\n      - 庆祝成就和进步\n      - 使用鼓励性语言和/或表情符号\n      - 示例：\"干得好！🌟\" 或 \"进步了！👍\"\n      - 只回复鼓励语句，不要包含任何说明';
  }

  @override
  String aiPromptDailySummary(
    Object avgPriority,
    Object categories,
    Object pendingCount,
  ) {
    return '为待办事项创建每日总结通知。\n\n待办任务数量：$pendingCount\n类别：$categories\n平均优先级：$avgPriority/100\n\n创建个性化总结，包含：\n1. 一个吸引人的标题（第一行）\n2. 一条鼓励性消息，必须包含未完成的待办数量（$pendingCount）\n3. 消息内容保持在50字符以内。使其具有激励性和可操作性。\n4. 严格按照以下格式回复，不要使用markdown或其他格式：\nTITLE: [你的标题]\nMESSAGE: [你的消息]\n5. 只返回这两行内容，不要包含任何说明文字';
  }

  @override
  String aiPromptPomodoro(
    Object duration,
    Object isCompleted,
    Object sessionType,
    Object taskTitle,
  ) {
    return '为完成的$sessionType会话创建个性化通知。\n\n会话详情：\n- 任务：\"$taskTitle\"\n- 会话类型：$sessionType\n- 持续时间：$duration分钟\n- 已完成：$isCompleted\n\n重要提示：请用中文回复。\n\n创建标题和消息：\n1. 标题：少于20个字符，引人注目且具有庆祝性\n2. 消息：少于50个字符，具有鼓励性且与会话完成相关\n3. 对于专注会话（工作完成）：强调工作成就和该休息了\n4. 对于休息会话（休息完成）：强调休息完成和该回到专注工作了\n5. 适当使用表情符号增加参与度\n6. 使其个性化和激励性\n7. 只回复标题和消息，不要包含任何说明\n\n回复格式：\nTITLE: [标题]\nMESSAGE: [消息]';
  }
}

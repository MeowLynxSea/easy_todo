# Easy Todo

一款功能完整的待办事项应用：任务管理 + 重复任务 + 通知提醒 + 番茄钟 + 数据统计，并提供可选的 AI 增强能力（自动分类/优先级/智能通知等）。

## 功能一览

- 任务管理：新增/编辑/完成/删除，支持搜索与筛选
- 视图模式：待办（列表/堆叠），历史（列表/日历）
- 重复任务：按规则自动生成今日任务，可手动强制刷新
- 通知提醒：任务提醒、本地通知、时区处理；支持每日摘要通知
- 番茄钟：专注/休息计时，会话记录与完成通知
- 统计与图表：任务完成趋势与概览（`fl_chart`）
- 数据统计（可选）：为启用数据统计的重复任务记录数值并查看趋势
- 备份/恢复：本地数据导出与导入（JSON 文件）
- 个性化：主题（明/暗/跟随系统）、语言切换、多项偏好设置
- 安全：支持生物识别/设备口令解锁；敏感配置（如 AI Key）写入安全存储
- 应用更新（Android）：检查更新、下载 APK、可选强制更新流程

## 技术栈

- Flutter + Dart（本项目 `sdk: ^3.8.1`）
- 状态管理：Provider
- 本地存储：Hive（含迁移/容错处理）
- 网络：Dio
- 通知：flutter_local_notifications + timezone
- 生物识别：local_auth

## 快速开始

```bash
flutter pub get
flutter run
```

常用开发命令：

```bash
flutter analyze
flutter test
dart format .
```

## AI 功能配置（可选）

应用内进入「偏好设置 → AI 设置」配置：

- `API Endpoint`、`Model`、`Timeout/Temperature/Max tokens` 等
- `API Format` 支持 OpenAI 风格与 Ollama 风格
- 开启后可启用：自动分类、重要性排序、激励文案、智能通知/摘要

说明：不开启 AI 不影响基础待办/统计/通知等功能。

## 项目结构

- `lib/`：业务代码（`screens/`、`widgets/`、`providers/`、`services/`、`models/` 等）
- `assets/l10n/`：多语言 ARB（`flutter gen-l10n` 生成到 `lib/l10n/generated/`）
- `test/`：单元/Widget 测试

## License

GPL-3.0，详见 `LICENSE`。

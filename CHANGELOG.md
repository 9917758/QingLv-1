# 版本记录

## 1.2.0

### 架构优化

**提醒服务模块化**
- 新增 `ReminderService` 服务类，集中管理提醒计划的加载、校验、缓存、存储。
- `HomeModel` 和 `ReminderPlanPage` 共用同一服务，消除重复的 `ReminderPlan` interface、`DEFAULT_PLANS`、`parsePlansFromStorage`、`copyPlan` 等重复定义。
- 提醒计划数据加载增加内存缓存，30 秒轮询不再重复读取磁盘和 JSON.parse。
- 新增 `isValidPlan()` 校验函数，解析 JSON 时自动跳过损坏条目。

**「我的收藏」独立页面**
- 「我的收藏」从健康知识列表页的 tab 筛选栏移至「我的」tab 作为独立入口。
- 新增 `HealthFavoritesPage` 页面，支持收藏文章列表展示和空状态提示。
- 通过 entry 模块预注册路由解决 person↔health 模块循环依赖问题。

**模块常量集中管理**
- `PreferenceConstant` 新增 `REMINDER_PLANS`、`REMINDER_CHECKED_TODAY` 常量，替代各文件中的硬编码字符串。

**统一错误处理**
- 新增 `ErrorUtil` 工具类，提供 `handle()` 和 `log()` 方法，统一错误日志格式。

### 功能改进

**弹窗打卡**
- 提醒弹窗新增「打卡」+「知道了」双按钮，替代原来的单一「我知道了」。
- 点击「打卡」后按钮变为「✅ 已完成」并置灰，同时标记该计划今日已打卡。
- 打卡状态通过 `emitter` 实时同步到提醒计划页面，列表项显示绿色「已完成」标签。
- 提醒计划页面每次可见时自动同步打卡状态（`syncCheckedStatus`）。

**定时器异常保护**
- `HomePage` 的 `scheduleNextCheck` 回调增加 try-catch，确保单次异常不会中断整个定时链。

**emitter 回调引用稳定性**
- `HealthPage` 的 `onHealthDataChange` 从 `@Local` 改为 `private`，避免组件重建时引用变化导致 `emitter.off` 失效。

**Date 对象复用**
- `HealthModel` 的 `initDeviceData` 和 `initHealthData` 中复用 `now`/`nowMs` 变量，消除重复 `new Date()` 调用。

### 修改文件

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `features/health/src/main/ets/service/ReminderService.ets` | 新增 | 提醒计划服务（加载、缓存、校验、打卡状态同步） |
| `features/health/src/main/ets/views/HealthFavoritesPage.ets` | 新增 | 独立的「我的收藏」页面 |
| `commons/common/src/main/ets/util/ErrorUtil.ets` | 新增 | 统一错误处理工具 |
| `commons/common/src/main/ets/constant/PreferenceConstant.ts` | 修改 | 新增提醒存储 key 常量 |
| `commons/common/src/main/ets/constant/Constants.ets` | 修改 | 新增 `onReminderCheckIn` 事件 |
| `commons/common/src/main/ets/constant/RouterMap.ets` | 修改 | 新增 `HEALTH_FAVORITES_PAGE` 路由 |
| `commons/common/Index.ets` | 修改 | 导出 ErrorUtil |
| `features/health/Index.ets` | 修改 | 导出 ReminderService、ReminderPlanItem、HealthFavoritesPageBuilder |
| `features/health/src/main/ets/views/ReminderPlanPage.ets` | 修改 | 委托 ReminderService，监听打卡事件，显示「已完成」标签 |
| `features/health/src/main/ets/views/HealthKnowledgeListPage.ets` | 修改 | 移除「全部/我的收藏」tab 筛选栏 |
| `features/health/src/main/ets/views/HealthPage.ets` | 修改 | emitter 回调改为 private，新增 getCardModel 方法 |
| `features/health/src/main/ets/viewmodel/HealthModel.ets` | 修改 | 复用 Date 对象 |
| `products/entry/src/main/ets/pages/HomePage.ets` | 修改 | 弹窗双按钮打卡、定时器 try-catch、emitter 通知 |
| `products/entry/src/main/ets/viewmodel/HomeModel.ets` | 修改 | 委托 ReminderService，新增 markPlanChecked/findPlanIdByName |
| `products/entry/src/main/ets/pages/Index.ets` | 修改 | 预注册 HealthFavoritesPageBuilder 路由 |
| `features/person/src/main/ets/views/MinePage.ets` | 修改 | 菜单新增「我的收藏」入口 |

## 1.1.0

### 新增功能

**用药与饮水提醒管理**
- 新增提醒计划管理页面 `ReminderPlanPage`，支持 5 条默认提醒计划（饮水×3、用药×2）。
- 支持自定义提醒名称、类型（饮水/用药）、时间（±小时/±5分钟）、剂量/水量。
- 支持单条提醒的启用/禁用开关。
- 到时间后在首页顶部弹出提醒卡片弹窗，点击"我知道了"关闭。
- 弹窗区分饮水（青色主题）和用药（粉色主题）。

**每日健康科普与推送**
- 健康常识文章从 15 条扩充至 30 条，覆盖饮食（11篇）、运动（8篇）、睡眠（5篇）、心理（6篇）四大分类。
- 新增文章：肠道健康、补钙指南、控糖生活、合理用油、抗氧化饮食、跑步入门、游泳健身、力量训练入门、久坐的危害、失眠怎么办、枕头的学问、社交与健康、情绪管理、感恩练习、数字排毒。
- 首页新增"每日一句"健康知识卡片，每日自动推荐一篇文章，支持手动刷新（"换一换"）。
- 健康常识列表页新增"全部/我的收藏"筛选标签，显示文章数量。
- 文章详情页新增收藏功能（爱心图标切换，空心/实心）。
- 收藏数据基于 `PreferenceUtil` 本地持久化，跨页面同步。

**模拟数据优化**
- 心率模拟：基于时段的基线（早68、午73、晚70）±3随机波动。
- 血压模拟：收缩压 116-124，舒张压 77-83，整数无小数。
- 血糖模拟：整数运算避免浮点精度问题（如 5.4 不再出现 5.39999）。
- 步数模拟：基于时间的渐进增长（8:00-22:00 活跃窗口），不再随机跳变。
- 睡眠模拟：总分钟数正确拆分为小时+分钟（不再出现"6时104分"）。
- 所有 Mock 数据中的 2025 年日期更新为 2026 年。

### 兼容性修复（API 5 → API 6）

- 收藏按钮：改用 `Stack` + `Text('❤️')` 替代 `Image.fillColor`，解决 API 6 中 Image 触摸事件被拦截的问题。
- 提醒弹窗：采用 `onCheckComplete` 字符串编码传递匹配信息 + `@Local` 状态驱动 UI，替代 API 6 中失效的 `ComponentContent` + `promptAction` 系统弹窗方案。
- 定时器：使用 `setTimeout` 递归链替代 `setInterval`，在 ComponentV2 生命周期中管理。
- 时区修正：使用 `getUTCHours() + getTimezoneOffset()` 替代 `getHours()`，修正模拟器 UTC 时间偏差。
- JSON 序列化：`ReminderPlanItem` 改为普通类（移除 `@ObservedV2`/`@Trace`），避免 `JSON.stringify` 序列化损坏。
- ForEach Key：扩展为包含 `time + name + type + isEnabled` 全量字段，确保编辑后 UI 正确刷新。
- 编辑操作：使用逐字段深拷贝替代对象展开运算符（ArkTS 严格模式不允许 `{...obj}`）。
- 脏数据检测：`loadPlans()` 自动检测 `@ObservedV2` 序列化产生的损坏数据并清除重置。
- 收藏版本化：`FavoriteUtil` 添加版本号机制，自动清理旧版本残留的脏数据。

### 修改文件

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `features/health/src/main/ets/model/ReminderPlanModel.ets` | 新增 | 提醒计划数据模型 |
| `features/health/src/main/ets/mock/ReminderMockData.ets` | 新增 | 5 条默认提醒计划 |
| `features/health/src/main/ets/views/ReminderPlanPage.ets` | 新增 | 提醒计划管理页面 |
| `features/health/src/main/ets/util/FavoriteUtil.ets` | 新增 | 收藏工具类（本地持久化） |
| `features/health/src/main/ets/constants/constants.ets` | 修改 | 文章扩充至 30 条 |
| `features/health/src/main/ets/viewmodel/HealthKnowledgeSingleModel.ets` | 修改 | 新增 `id`、`tag`、`isFavorited` 字段 |
| `features/health/src/main/ets/comp/HealthKnowledgeRow.ets` | 修改 | 重写为"每日一句"卡片 |
| `features/health/src/main/ets/views/HealthKnowledgeListPage.ets` | 修改 | 新增收藏筛选功能 |
| `features/health/src/main/ets/views/HealthKnowledgeDetailPage.ets` | 修改 | 新增爱心收藏按钮 |
| `features/health/src/main/ets/views/HealthPage.ets` | 修改 | 新增提醒入口 |
| `features/health/Index.ets` | 修改 | 导出 FavoriteUtil |
| `products/entry/src/main/ets/pages/HomePage.ets` | 修改 | 提醒定时器 + 弹窗 UI |
| `products/entry/src/main/ets/viewmodel/HomeModel.ets` | 修改 | 提醒匹配逻辑 + 时间计算 |
| `products/entry/src/main/ets/pages/Index.ets` | 修改 | 启动时初始化收藏和提醒存储 |
| `products/entry/src/main/ets/viewmodel/HomeModel.ets` | 修改 | Mock 数据全面优化 |
| `commons/common/src/main/ets/constant/RouterMap.ets` | 修改 | 新增 REMINDER_PLAN_PAGE 路由 |
| `commons/common/src/main/ets/ui/MessageReminderDialog.ets` | 修改 | 返回值改为 boolean |

## 1.0.1

### 变更内容

- 多个三方组件锁定版本号。
- 修复一些已知问题单。
- 增加AI注释。

## 1.0.0

### 变更内容

- 本模板为健康管理类应用提供了完整的开发框架，包含健康数据监测、智能设备连接和个人信息管理三大核心模块。

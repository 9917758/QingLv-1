# 版本记录

## 1.3.1

### Bug 修复

**打卡状态跨应用重启丢失**
- 将打卡状态管理从 `HomeModel` 迁移至 `ReminderService`，作为唯一数据源。
- `ReminderService` 新增内存缓存层（`checkedTodayIds` + `checkedTodayDate`），优先读内存，首次从存储加载。
- 新增 `markPlanChecked()`、`isPlanCheckedToday()`、`resetCheckedToday()` 方法，统一打卡读写入口。
- `HomeModel.checkAndRemind()` 和 `HomePage.handleCheckIn()` 均委托 `ReminderService` 处理打卡，避免多处读写导致的状态不一致。

**饮水计划打卡未同步喝水杯数**
- `HomePage.handleCheckIn()` 中，当打卡的计划为饮水类型（type=0）时，自动调用 `WaterIntakeService.instance.drink()` 增加杯数。
- `HealthPage` 新增 `onReminderCheckIn` 事件监听，弹窗打卡后自动刷新喝水进度显示。

**喝水"+1"无上限**
- `WaterIntakeService.drink()` 新增每日上限 20 杯，达到后不再增加。
- `HealthPage` 的"+1"按钮达到上限后显示"✓"并置灰禁用。

**弹窗打卡后不自动关闭**
- 用户点击"打卡"后，弹窗延迟 1.2 秒自动关闭（让用户看到"✅ 已完成"反馈），无需再手动点"知道了"。

### ArkTS 编译修复

**PreferenceUtil API 修正**
- 三个服务（`HealthDataService`、`WaterIntakeService`、`HealthGoalService`）的 `PreferenceUtil` 调用从不存在的 `getPreference()` 改为正确的 `getInstance()` 同步 API。
- 所有 async/await 改为同步调用（`PreferenceUtil` 的 `put`/`get` 均为同步方法）。

**ArkTS 严格模式类型修复**
- 移除所有 `any`/`unknown` 类型，使用显式类型声明。
- `WeeklyReportModel`/`MonthlyReportModel` 中的图表数据点对象字面量改为显式 `ChartDataPoint` 类型声明。
- `HealthDataInputPage.saveCurrentAsRecord()` 的参数从对象字面量改为逐参数传递。

**ForEach Key 修复**
- `HealthPage` 中 ForEach key 生成器末尾多余的 `}` 字符已移除。

### 修改文件

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `features/health/src/main/ets/service/ReminderService.ets` | 修改 | 新增打卡状态管理（`markPlanChecked`/`getCheckedTodayIds`/`resetCheckedToday`） |
| `features/health/src/main/ets/service/HealthDataService.ets` | 修改 | PreferenceUtil API 修正，sync 替代 async |
| `features/health/src/main/ets/service/WaterIntakeService.ets` | 修改 | API 修正 + 喝水上限 20 杯 |
| `features/health/src/main/ets/service/HealthGoalService.ets` | 修改 | PreferenceUtil API 修正 |
| `features/health/src/main/ets/viewmodel/WeeklyReportModel.ets` | 修改 | ChartDataPoint 显式类型声明 |
| `features/health/src/main/ets/viewmodel/MonthlyReportModel.ets` | 修改 | ChartDataPoint 显式类型声明 |
| `features/health/src/main/ets/viewmodel/HealthHistoryModel.ets` | 修改 | loadHistory 改为同步 |
| `features/health/src/main/ets/views/HealthPage.ets` | 修改 | 喝水上限按钮状态 + 打卡事件监听刷新 |
| `features/health/src/main/ets/views/HealthHistoryPage.ets` | 修改 | aboutToAppear 改为同步 |
| `features/health/src/main/ets/views/HealthDataInputPage.ets` | 修改 | saveCurrentAsRecord 参数修复 |
| `products/entry/src/main/ets/viewmodel/HomeModel.ets` | 修改 | 打卡逻辑委托 ReminderService，移除本地状态管理 |
| `products/entry/src/main/ets/pages/HomePage.ets` | 修改 | 饮水打卡联动 + 弹窗自动关闭 |

## 1.3.0

### Bug 修复

**体重范围数据修正**
- 修复 `weightRange` 中 `'330.0'`/`'335.0'` 的拼写错误，更正为 `'230.0'`/`'235.0'`。
- 此 bug 会导致 230-235 斤区间的用户 BMI 选择器出现数值跳跃。

**健康知识文章去重**
- 文章 id='3'（原"轻断食"）与 id='1'（"健康饮食"）内容完全相同，现已替换为全新文章"轻食主义"。

**占位符文字清理**
- 删除账号弹窗中的 `'xxxx'` 占位文字更正为 `'清律'`。

**周报/月报日期修正**
- 周报日期选项从硬编码 2024 年改为基于当前日期动态生成最近 5 周。
- 月报日期选项从硬编码 2024 年改为基于当前日期动态生成最近 5 个月。

### 核心功能：健康数据历史系统

**HealthDataService 服务**
- 新增 `HealthDataService`，管理健康数据记录的持久化和查询。
- 支持按时间范围查询（`getRecordsByDateRange`）、获取最近 N 条（`getRecentRecords`）。
- 最多保留 500 条记录，超出自动裁剪。
- Mock 模式下自动生成 60 天的模拟历史数据，包含体重下降、血压改善等真实趋势。

**HealthDataRecord 类型**
- 新增 `HealthDataRecord` 接口，包含体重、BMI、体脂率、血糖、血压、心率、腰围、臀围等全量指标。
- 每次用户在健康数据录入页面修改任何指标，自动保存一条完整记录。

**历史数据接入报告系统**
- `WeeklyReportModel` 改为从历史数据动态聚合：按周筛选记录，计算体重/体脂趋势、血压/心率均值。
- `MonthlyReportModel` 改为从历史数据动态聚合：按月筛选记录，生成图表数据点。
- 选择不同日期/月份时，报告数据实时从历史记录重新计算。
- 无数据时优雅降级，使用原始 mock 数据。

**HealthHistoryModel 升级**
- `loadHistory()` 方法从 `HealthDataService` 加载数据，与 mock 数据合并去重。
- 按月份自动分组，支持多月份浏览。

### 新增功能

**💧 今日喝水进度**
- 新增 `WaterIntakeService` 服务，管理每日喝水打卡次数（基于日期 key 自动重置）。
- 健康页面新增喝水进度卡片：显示当前杯数/目标杯数、进度条、"+1"打卡按钮。
- 达成目标时显示 🎉 已达成提示。
- 默认每日目标 8 杯，支持自定义。
- 数据基于 Preferences 持久化，跨会话保留。

**🎯 健康目标设定**
- 新增 `HealthGoalService` 服务，管理目标体重设定和进度计算。
- 健康页面新增目标卡片（仅在设定目标体重后显示），显示"距目标还差 X 斤"或"🎉 已达成目标！"。

**🔍 健康知识搜索**
- 健康知识列表页新增搜索栏，支持按标题、副标题、标签关键词过滤。
- 搜索无结果时显示友好空状态提示（🔍 + "没有找到相关文章"）。

**📋 空状态优化**
- 健康历史记录页面：无数据时显示"还没有记录哦，去健康数据页面录入第一条数据吧"。
- 健康知识搜索：无匹配结果时显示"试试其他关键词吧"。
- 我的收藏页面已有空状态（保留原有设计）。

**📤 数据导出**
- 新增 `HealthDataExportUtil` 工具类，支持将健康数据导出为 JSON 文件。
- 使用系统文件选择器让用户选择保存位置。

### 单元测试

- 新增 `HealthGoalService.test.ets`：测试目标差距计算、进度百分比、目标描述生成等 9 个用例。
- 新增 `HealthDataRecord.test.ets`：测试 mock 数据生成、聚合计算（均值/极值/变化量）、日期过滤、BMI 计算、喝水进度等 12 个用例。
- 使用 `@ohos/hypium` 测试框架，可直接在 DevEco Studio 中运行。

### 修改文件

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `features/health/src/main/ets/service/HealthDataService.ets` | 新增 | 健康数据记录管理服务 |
| `features/health/src/main/ets/service/WaterIntakeService.ets` | 新增 | 喝水打卡服务 |
| `features/health/src/main/ets/service/HealthGoalService.ets` | 新增 | 健康目标管理服务 |
| `features/health/src/main/ets/types/HealthDataRecordTypes.ets` | 新增 | 健康数据记录类型定义 |
| `features/health/src/main/ets/mock/HealthDataRecordMockData.ets` | 新增 | 60 天 mock 历史数据生成 |
| `features/health/src/main/ets/util/HealthDataExportUtil.ets` | 新增 | 数据导出工具 |
| `features/health/src/main/test/HealthGoalService.test.ets` | 新增 | 目标服务单元测试 |
| `features/health/src/main/test/HealthDataRecord.test.ets` | 新增 | 数据记录逻辑单元测试 |
| `features/health/src/main/test/List.test.ets` | 新增 | 测试套件入口 |
| `features/health/src/main/ets/viewmodel/WeeklyReportModel.ets` | 重写 | 从历史数据动态聚合周报 |
| `features/health/src/main/ets/viewmodel/MonthlyReportModel.ets` | 重写 | 从历史数据动态聚合月报 |
| `features/health/src/main/ets/viewmodel/HealthHistoryModel.ets` | 重写 | 从 HealthDataService 加载并合并历史数据 |
| `features/health/src/main/ets/views/HealthPage.ets` | 修改 | 新增喝水进度卡片、健康目标卡片 |
| `features/health/src/main/ets/views/HealthKnowledgeListPage.ets` | 修改 | 新增搜索栏和空搜索结果提示 |
| `features/health/src/main/ets/views/HealthHistoryPage.ets` | 修改 | 接入真实数据加载、新增空状态 |
| `features/health/src/main/ets/views/HealthDataInputPage.ets` | 修改 | 每次输入自动保存历史记录 |
| `features/health/src/main/ets/constants/constants.ets` | 修改 | 修复体重范围数据、替换重复文章 |
| `features/health/Index.ets` | 修改 | 导出新增的三个服务和数据类型 |
| `commons/common/src/main/ets/dialog/OHDialogModel.ets` | 修改 | 占位符 'xxxx' → '清律' |

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

# Changelog

## v2.4.0 - 2026-06-18

### 新增

- **AI 助手 Markdown 渲染**: AI 回复中的 `**加粗**` 文本正确显示为粗体，支持标题、列表、引用等格式清理
- **ReAct Agent 工具调用**: 后端 AI 助手升级为 ReAct 架构，支持 10 个智能工具（营养分析、运动计划、趋势预测、健康风险评估等）
- **后端用户体重查询**: AI 助手现在能正确获取用户的体重信息（从 User 表读取）

### 修复

- **步数历史白屏**: 移除 `onPop: deletePage()` 回调，修复导航栈双重弹出导致的白屏崩溃
- **步数假数据日期错误**: Mock 数据改为动态生成，不再出现未来日期
- **血糖统计 minValue 错误**: 修正 BloodGlucoseMockData 中统计值与实际数据不匹配
- **周报/月报图表数据异常**: 图表数据限制在统计值声明的范围内
- **睡眠 Mock 日期不匹配**: 修正 SleepMockData 中 currentDate 与 monthTitle 不一致
- **血压月视图标签错误**: 修正 5月标签显示为 11/12月日期的问题
- **HealthPage 无条件调用 Mock**: `generateMockHistory()` 和 `generateMock()` 添加 `USE_MOCK_DATA` 守卫
- **CheckinStreakService 假数据**: 无持久化数据时不再无条件生成 Mock 打卡记录
- **routerModule 空值检查**: StepHistoryPage 和 StepCountPage 添加空值保护
- **后端 Agent 依赖冲突**: 移除 `langgraph.prebuilt`，改用 LangChain 原生 tool calling

---

## v2.3.0 - 2026-06-12

### 新增

- **数据备份与恢复**: 健康报告页新增 JSON 导出/导入功能，支持本地备份和恢复健康数据
- **健康日记**: 历史详情页新增日记功能，用户可为每天的健康数据写文字记录
- **搜索功能**: 健康历史页新增搜索栏，支持按日期或体重范围（如 `65` 或 `60-70`）过滤记录
- **个人中心 emitter 事件**: PersonInfoBirthdayPage 完成后通过 emitter 通知 InputPage 正确 pop

### 改动

- **API 拉取优化**: 所有 `loadFromApi(200)` 减少为 `loadFromApi(50)`，降低后端压力
- **HealthPage 并行请求**: `refreshFromApi` 从串行改为 `Promise.all` 并行，首页加载更快
- **HealthReportModel 数据补全**: API 数据不完整时自动用 UserInfo 本地计算 BMI/体脂

### 修复

- **PersonInfoInputPage 白屏**: 移除 `onPop: popPage()` 双重弹栈回调，改用 emitter 事件协调
- **AiAgentPage 崩溃**: `async aboutToAppear()` 添加 try-catch
- **HealthHistoryDetailPage 崩溃**: `.toFixed()` 作用在 undefined 上 → `@Local historyData` 用默认值初始化
- **FeedbackHistoryPage 未处理 rejection**: Promise 链添加 `.catch()`
- **导出提示无数据**: `handleExport` 在检查记录数前先调用 `loadFromApi` 加载数据
- **BMI 不计算**: API 返回 bmi=0 时自动用 UserInfo 身高体重本地计算
- **ThemeColors.primary 不存在**: 改为 `.accent`
- **emitter 导入路径错误**: 从 `@kit.ArkUI` 改为 `@kit.BasicServicesKit`
- **.gitignore 更新**: 新增 `.ohpm/`、`@ohos/`、`node_modules/` 等忽略规则，移除 883 个误提交的缓存文件

---

## v2.2.0 - 2026-06-10

### 新增

- **深色模式**: 新增 ThemeUtil 工具类，支持浅色/深色/跟随系统三种主题模式，设置页可切换
- **多语言基础设施**: 新增 I18nUtil 工具类，自动检测系统语言，为 Service 层提供多语言字符串
- **英文资源文件**: 所有 11 个模块创建 `en_US/element/string.json` 翻译文件
- **数据导出**: 健康报告页新增 CSV/JSON 导出功能（DataExportService）
- **数据趋势对比**: 周报/月报新增与上一周期的对比指标（体重、体脂、血压、心率变化标签）
- **身高体重持久化**: HealthDataInputPage 修改体重时自动同步到后端 API
- **启动时主题恢复**: EntryAbility.onCreate 加载保存的主题设置

### 改动

- **主题响应式**: 所有页面使用 `@Computed get themeColors()` 替代静态属性，主题切换即时生效
- **异常检测基于实际数据**: AnomalyHistoryService 从硬编码 mock 改为基于 HealthDataInputModel 的阈值检测
- **字符串资源化**: HealthPage、HealthReportPage、HealthHistoryPage、BackendLoginPage、ReminderPlanPage、BmiCalculatorPage、AnomalyHistoryPage、AchievementPage 等页面的硬编码中文替换为 `$r('app.string.xxx')`
- **健康报告数据同步**: HealthReportPage 打开时先 refreshHealthData 再 loadFromApi
- **ThemeUtil 单例引用修复**: 每次 applyMode 创建新 ThemeColors 对象，避免引用相等问题
- **ThemeColors 不再使用共享单例**: 修复切换同一主题两次可能不触发更新的问题

### 修复

- **主题切换无效**: `@Computed` 无法追踪 getter 中的 `@Trace` 属性 → 改为 `@Trace currentColors`
- **EntryAbility 覆盖主题**: 移除硬编码 `COLOR_MODE_LIGHT`，改为根据保存的主题设置
- **HealthCardRow 导航崩溃**: 移除 `onPop: deletePage()` 回调
- **AI 聊天历史加载**: `aboutToAppear` 改为 async，先 await loadSessions 再 initSession
- **体重单位不一致**: 前后端统一为公斤，移除所有 `斤` 和 `/2` 转换

---

## v2.1.0 - 2026-06-09

### 新增

- **体重目标 API**: 新增 `/api/health/goal/weight` 端点，支持云端同步体重目标
- **睡眠记录 API**: 新增 `/api/health/sleep` 端点，支持录入和查询睡眠数据
- **异常事件持久化**: 异常历史记录保存到 Preferences，按用户隔离，重启不丢失
- **数据库迁移脚本**: `init_v2.sql`（新表）、`init_v3.sql`（体重单位统一）
- **AI 上下文优化**: AI 对话现在包含用户个人信息、体重目标、饮水进度等上下文

### 改动

- **体重单位统一为公斤**: 移除所有 `斤` 相关的转换逻辑
- **后端 AI 分析**: 所有体重输出从 `斤` 改为 `公斤`

---

## v2.0.0 - 2026-06-08

### 新增
- **后端云同步**: 接入 FastAPI 后端，支持健康数据、饮水、提醒计划的云端同步
- **JWT 认证**: 新增后端登录/注册页面（BackendLoginPage），支持 Token 持久化
- **AI 健康顾问**: 新增 AiAgentPage，支持基于用户健康数据和收藏文章的多轮对话
- **会话管理**: AI 对话支持新建会话、切换历史会话、删除会话
- **服务器配置**: 设置页新增后端服务器地址配置项
- **健康知识 API**: 收藏操作自动同步到后端数据库
- **用户数据隔离**: 所有本地 Preferences 按用户 ID 隔离，切换账号数据互不影响

### 改动
- HealthDataService: 新增 `loadFromApi()` 异步加载，`saveRecord()` 自动同步后端
- WaterIntakeService: 新增 `loadFromApi()`，`drink()` 自动调后端 API
- ReminderService: 新增 `loadFromApi()`，打卡自动调后端 API
- HealthScoreService: 新增 `loadFromApi()` 从后端获取评分
- HealthSuggestionService: 新增 `loadFromApi()` 从后端获取 AI 建议
- HealthReportModel: 新增 `loadFromApi()` 从后端加载仪表盘数据
- HealthHistoryModel: 新增 `loadFromApi()` 从后端加载历史记录
- WeeklyReportModel / MonthlyReportModel: 新增 `loadFromApi()`
- FavoriteUtil: 收藏操作自动同步后端，按用户 ID 隔离本地存储
- HealthPage: 异步从后端刷新评分、建议、饮水数据
- SetupPage: 退出登录清除所有 Service 缓存，跳转后端登录页
- Index.ets: 启动流程改为检查 Token → 有 Token 进主页 / 无 Token 进登录页

### 修复
- 退出登录时清除所有 Service 内存缓存（9 个 Service），防止下一个用户读到旧数据
- 收藏数据按用户 ID 隔离，不再共享
- AI 回答中体重单位标注斤和公斤，避免混淆

---

## v1.6.0 - 2026-06-07

### 新增
- 健康评分系统（HealthScoreService）: 综合 BMI、血压、心率、血糖、运动计算 0-100 分
- 健康建议服务（HealthSuggestionService）: 根据健康数据动态生成个性化建议
- 连续打卡服务（CheckinStreakService）: 追踪每条提醒计划的连续打卡天数
- 成就徽章系统（AchievementService）: 8 种成就，追踪解锁进度
- 健康异常历史（AnomalyHistoryService）: 记录所有触发异常提醒的事件
- 睡眠质量评分（SleepQualityService）: 基于深睡/浅睡/REM 比例计算评分
- BMI 计算器页面
- 成就徽章页面
- 异常事件历史页面
- 健康首页集成评分、建议、快捷入口卡片

### 改动
- 健康首页布局重构: 从 lanes(2) + width('200%') 改为嵌套 List + lanes(2)
- 健康建议数据与主页数据同步

---

## v1.5.0 - 2026-06-06

### 新增
- 饮水打卡服务（WaterIntakeService）: 每日喝水次数记录与目标管理
- 健康目标管理（HealthGoalService）: 目标体重设定与进度追踪
- 提醒计划服务（ReminderService）: 饮水/用药提醒，支持打卡
- 用药与饮水提醒页面（ReminderPlanPage）
- 健康历史记录页面（HealthHistoryPage）: 按月分组展示
- 健康历史详情页面
- 周度报告页面（WeeklyReportPage）
- 月度报告页面（MonthlyReportPage）
- 健康数据导出功能（JSON 格式）
- 健康知识收藏功能（FavoriteUtil）

### 改动
- 首页弹窗提醒支持打卡操作
- 跨天自动重置打卡记录

---

## v1.4.0 - 2026-06-05

### 新增
- 健康数据录入页面（HealthDataInputPage）: 支持体重、BMI、体脂、血压、心率、血糖等指标
- 健康数据管理服务（HealthDataService）: 记录持久化、时间范围查询、聚合
- 健康报告页面（HealthReportPage）: 综合展示健康指标与评分
- 健康知识列表页面与详情页面
- 健康知识每日推荐

---

## v1.3.0 - 2026-06-04

### 新增
- 设备扫描与配对页面
- 设备信息展示
- 蓝牙设备连接流程

---

## v1.2.0 - 2026-06-03

### 新增
- 个人中心页面（EditPersonalCenterPage）
- 设置页面（SetupPage）: 清除缓存、版本检测、关于我们、退出登录
- 隐私设置页面
- 关于页面

---

## v1.1.0 - 2026-06-02

### 新增
- 健康首页（HealthPage）: 健康卡片、运动数据、健康知识展示
- 消息中心页面
- 应用入口与 Tab 导航

---

## v1.0.0 - 2026-06-01

### 新增
- 项目初始化
- 用户信息管理（UserInfo）
- 路由系统（OHRouter）
- 公共模块（common）: 工具类、常量、UI 组件
- 登录组件（aggregated_login）
- 隐私协议页面

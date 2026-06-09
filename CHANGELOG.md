# Changelog

## v2.1.0 - 2026-06-09

### 新增

- **体重目标 API**: 新增 `/api/health/goal/weight` 端点，支持云端同步体重目标
- **睡眠记录 API**: 新增 `/api/health/sleep` 端点，支持录入和查询睡眠数据
- **异常事件持久化**: 异常历史记录保存到 Preferences，按用户隔离，重启不丢失
- **数据库迁移脚本**: `init_v2.sql`（新表）、`init_v3.sql`（体重单位统一）

### 改动

- **体重单位统一为公斤**: 移除所有 `斤` 相关的转换逻辑（ReportAggregator、图表、目标、建议等）
- **异常检测基于实际数据**: AnomalyHistoryService 从硬编码 mock 改为基于 HealthDataInputModel 的规则检测
- **后端 AI 分析**: 所有体重输出从 `斤` 改为 `公斤`，移除 `/2` 转换
- **后端 mock 数据**: 体重不再 `*2`，与前端单位一致

### 修复

- **血压历史页面崩溃**: 移除 HealthCardRow 中 `onPop: deletePage()` 回调，防止导航栈损坏
- **AI 聊天历史加载**: `aboutToAppear` 中 `loadSessions()` 改为 `await`，修复异步时序问题
- **异常数据与主页不一致**: 异常服务现在读取实际健康数据，只在指标超阈值时生成事件

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

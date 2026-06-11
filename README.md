# 清律 - 智能健康管理 App（鸿蒙端）

> 基于 HarmonyOS ArkTS 开发的个人健康管理应用，支持健康数据追踪、AI 健康顾问、后端云同步、深色模式、多语言。

## 功能特性

### 健康数据管理
- 体重（公斤）、BMI、体脂率、血压、心率、血糖等指标录入与追踪
- 周度/月度健康报告，含趋势图表与上一周期对比
- 健康评分系统（0-100 分，多维度综合评估）
- 健康异常事件检测（基于实际数据：心率、血压、血糖、BMI 阈值判断）
- 健康数据 CSV/JSON 导出

### AI 健康顾问
- 基于用户健康数据的个性化 AI 问答
- 多轮对话，支持会话管理（新建/切换/删除）
- 结合收藏的健康知识文章给出建议
- 后端自动查询用户数据、体重目标、饮水进度作为上下文

### 健康知识
- 30 篇专业健康知识文章（饮食/运动/睡眠/心理）
- 文章收藏功能，按用户隔离
- 搜索与分类筛选

### 提醒与打卡
- 饮水/用药提醒计划管理
- 弹窗提醒 + 打卡功能
- 连续打卡天数统计与成就徽章

### 后端云同步
- JWT 认证的用户注册/登录
- 健康数据、饮水记录、提醒计划云端同步
- 服务器地址可配置（设置页）
- 离线优先：本地缓存 + 异步 API 刷新

### 深色模式
- 支持浅色/深色/跟随系统三种主题模式
- 设置页一键切换，即时生效
- 所有页面和组件自动适配

### 多语言
- 支持中文/英文，跟随系统语言自动切换
- 所有模块配有英文资源文件

## 项目结构

```
QingLv-1/
├── commons/
│   ├── common/                    # 公共模块
│   │   └── src/main/ets/
│   │       ├── util/
│   │       │   ├── HttpUtil.ets       # HTTP 请求封装
│   │       │   ├── NetworkConfig.ets  # 后端地址配置
│   │       │   ├── AuthToken.ets      # JWT Token 管理
│   │       │   ├── ApiTypes.ets       # API 响应类型定义
│   │       │   ├── ThemeUtil.ets      # 主题管理（浅色/深色/跟随系统）
│   │       │   ├── I18nUtil.ets       # 国际化工具（跟随系统语言）
│   │       │   └── FavoriteUtil.ets   # 收藏工具（按用户隔离）
│   │       └── ...
│   └── OHRouter/                  # 路由模块
├── features/
│   ├── health/                    # 健康模块
│   │   └── src/main/
│   │       ├── ets/
│   │       │   ├── service/           # 业务服务层
│   │       │   ├── viewmodel/         # 视图模型
│   │       │   ├── views/             # 页面
│   │       │   ├── comp/              # 组件
│   │       │   ├── types/             # 类型定义
│   │       │   └── mock/              # Mock 数据
│   │       └── resources/
│   │           ├── base/element/string.json   # 中文字符串
│   │           └── en_US/element/string.json  # 英文翻译
│   ├── person/                    # 个人中心模块
│   └── device/                    # 设备模块
├── components/                    # 业务组件
└── products/
    └── entry/                     # 应用入口
```

## 技术栈

- **平台**: HarmonyOS 5.0+ (ArkTS)
- **架构**: 多模块化（commons / features / components）
- **状态管理**: @ObservedV2 + @Trace + PersistenceV2
- **网络**: @ohos.net.http（封装于 HttpUtil）
- **路由**: 自研 OHRouter
- **后端**: FastAPI + MySQL（详见 backend 项目）

## 快速开始

### 1. 环境准备
- DevEco Studio 5.0+
- HarmonyOS SDK 5.0+

### 2. 后端配置
1. 启动 Python 后端（详见 backend README）
2. 在 App 设置页配置后端地址（默认 `http://192.168.237.1:8000`）

### 3. 运行
1. DevEco Studio 打开项目
2. 选择模拟器或真机
3. 点击 Run

## 数据隔离

所有本地数据按用户 ID 隔离，切换账号不会互相影响：

- 健康记录: `health_data_records_${userId}`
- 饮水数据: `water_intake_${userId}_YYYYMMDD`
- 提醒计划: `reminder_plans_${userId}`
- 打卡记录: `checkin_streak_${userId}`
- 收藏文章: `fav_${userId}`
- 健康目标: `health_goal_weight_${userId}`
- 异常历史: `health_anomaly_history_${userId}`

## 版本历史

详见 [CHANGELOG.md](./CHANGELOG.md)

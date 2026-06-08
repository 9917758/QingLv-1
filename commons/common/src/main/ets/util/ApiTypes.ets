/**
 * 后端 API 响应类型定义
 * 与 Python 后端的 Pydantic Schema 一一对应
 */

// ─── 认证 ───

export interface ApiUser {
  id: number;
  username: string;
  nick_name: string;
  gender: string;
  birthday: string | null;
  height: number;
  weight: number;
  created_at: string;
}

export interface ApiTokenResponse {
  access_token: string;
  token_type: string;
  user: ApiUser;
}

// ─── 健康记录 ───

export interface ApiHealthRecord {
  id: number;
  timestamp: string;
  weight: number;
  bmi: number;
  body_fat_percentage: number;
  fat_weight: number;
  blood_sugar: number;
  blood_pressure_systolic: number;
  blood_pressure_diastolic: number;
  heart_rate: number;
  waist_circumference: number;
  hip_circumference: number;
  step_count: number;
  sleep_hours: number;
}

export interface ApiRecordListResponse {
  total: number;
  records: ApiHealthRecord[];
}

// ─── 仪表盘 ───

export interface ApiDashboard {
  today_score: number;
  score_level: string;
  bmi: number;
  bmi_level: string;
  weight: number;
  body_fat_percentage: number;
  blood_pressure_systolic: number;
  blood_pressure_diastolic: number;
  heart_rate: number;
  blood_sugar: number;
  step_count: number;
  sleep_hours: number;
  water_cups: number;
  water_goal: number;
}

// ─── 趋势 ───

export interface ApiTrendPoint {
  date: string;
  value: number;
}

export interface ApiTrendResponse {
  metric: string;
  unit: string;
  points: ApiTrendPoint[];
}

// ─── 饮水 ───

export interface ApiWaterIntake {
  date: string;
  cup_count: number;
  daily_goal: number;
}

// ─── 提醒计划 ───

export interface ApiReminderPlan {
  id: number;
  plan_id: string;
  plan_type: number;
  name: string;
  time: string;
  dosage: string;
  is_enabled: boolean;
}

// ─── AI 分析 ───

export interface ApiAnalysisReport {
  overall_score: number;
  score_level: string;
  summary: string;
  highlights: string[];
  concerns: string[];
  suggestions: string[];
  weight_trend: string;
  bp_assessment: string;
  hr_assessment: string;
  bs_assessment: string;
}

export interface ApiChatResponse {
  role: string;
  content: string;
}

// ─── 健康知识 ───

export interface ApiKnowledgeArticle {
  id: number;
  title: string;
  sub_title: string;
  tag: string;
  content: string;
  is_favorited: boolean;
}

export interface ApiArticleListResponse {
  total: number;
  articles: ApiKnowledgeArticle[];
}

// ─── 健康 Agent ───

export interface ApiAgentMessage {
  role: string;
  content: string;
}

export interface ApiAgentRequest {
  message: string;
  history: ApiAgentMessage[];
}

export interface ApiAgentResponse {
  role: string;
  content: string;
}

// ─── AI 对话会话 ───

export interface ApiChatSession {
  id: number;
  title: string;
  created_at: string;
  updated_at: string;
}

export interface ApiChatSessionList {
  total: number;
  sessions: ApiChatSession[];
}

export interface ApiChatMessage {
  id: number;
  session_id: number;
  role: string;
  content: string;
  created_at: string;
}

export interface ApiChatMessageList {
  total: number;
  messages: ApiChatMessage[];
}

export interface ApiChatSendResponse {
  user_message: ApiChatMessage;
  ai_message: ApiChatMessage;
}

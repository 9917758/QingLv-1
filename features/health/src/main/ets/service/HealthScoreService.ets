/**
 * 健康评分服务
 * 综合 BMI、血压、心率、血糖、运动等指标计算 0-100 的健康评分
 * 支持本地计算 + 后端 API 评分同步
 */
import { HttpUtil, AuthToken } from 'common';
import type { ApiResponse, ApiDashboard } from 'common';
import { HealthDataInputModel } from '../viewmodel/HealthDataInputModel';

export interface ScoreHistory {
  date: string;
  score: number;
  bmiScore: number;
  bpScore: number;
  hrScore: number;
  bsScore: number;
  exerciseScore: number;
}

@ObservedV2
export class HealthScoreService {
  private static _instance: HealthScoreService;
  @Trace todayScore: number = 0;
  @Trace bmiScore: number = 0;
  @Trace bpScore: number = 0;
  @Trace hrScore: number = 0;
  @Trace bsScore: number = 0;
  @Trace exerciseScore: number = 0;
  @Trace scoreHistory: ScoreHistory[] = [];
  @Trace scoreLevel: string = '无数据';
  @Trace scoreColor: string = '#999999';

  public static get instance(): HealthScoreService {
    if (!HealthScoreService._instance) {
      HealthScoreService._instance = new HealthScoreService();
    }
    return HealthScoreService._instance;
  }

  /** 清除内存缓存（退出登录/切换用户时调用） */
  public clearCache(): void {
    this.todayScore = 0;
    this.bmiScore = 0;
    this.bpScore = 0;
    this.hrScore = 0;
    this.bsScore = 0;
    this.exerciseScore = 0;
    this.scoreHistory = [];
    this.scoreLevel = '无数据';
    this.scoreColor = '#999999';
  }

  /** 本地计算评分（兼容旧调用） */
  public calculateScore(inputVM: HealthDataInputModel, stepCount: number, sleepHours: number): number {
    this.bmiScore = this.calcBmiScore(inputVM.bmiValue);
    this.bpScore = this.calcBpScore(inputVM.bloodPressureSystolic, inputVM.bloodPressureDiastolic);
    this.hrScore = this.calcHrScore(inputVM.heartRate);
    this.bsScore = this.calcBsScore(inputVM.bloodSugar);
    this.exerciseScore = this.calcExerciseScore(stepCount, sleepHours);

    this.todayScore = Math.round(
      this.bmiScore * 0.25 + this.bpScore * 0.2 + this.hrScore * 0.15 +
      this.bsScore * 0.15 + this.exerciseScore * 0.25
    );
    this.updateLevelAndColor();
    this.saveTodayScore();
    return this.todayScore;
  }

  /** 从后端 API 获取评分（异步） */
  public async loadFromApi(): Promise<number> {
    if (!AuthToken.isLoggedIn()) {
      return this.todayScore;
    }
    const resp: ApiResponse<ApiDashboard> = await HttpUtil.get<ApiDashboard>('/api/health/dashboard');
    if (resp.data) {
      this.todayScore = resp.data.today_score;
      this.scoreLevel = resp.data.score_level;
      this.updateColorFromScore();
    }
    return this.todayScore;
  }

  public generateMockHistory(): void {
    const history: ScoreHistory[] = [];
    const now = new Date();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const dateStr = `${d.getMonth() + 1}/${d.getDate()}`;
      const bmi = 20 + Math.floor(Math.random() * 5);
      const bp = 17 + Math.floor(Math.random() * 3);
      const hr = 13 + Math.floor(Math.random() * 2);
      const bs = 13 + Math.floor(Math.random() * 2);
      const ex = 18 + Math.floor(Math.random() * 7);
      const total = Math.round(bmi * 0.25 + bp * 0.2 + hr * 0.15 + bs * 0.15 + ex * 0.25);
      history.push({
        date: dateStr,
        score: Math.min(100, Math.max(70, total)),
        bmiScore: bmi, bpScore: bp, hrScore: hr, bsScore: bs, exerciseScore: ex
      });
    }
    this.scoreHistory = history;
    if (history.length > 0) {
      const last = history[history.length - 1];
      this.todayScore = last.score;
      this.bmiScore = last.bmiScore;
      this.bpScore = last.bpScore;
      this.hrScore = last.hrScore;
      this.bsScore = last.bsScore;
      this.exerciseScore = last.exerciseScore;
      this.updateLevelAndColor();
    }
  }

  public getScoreLevel(): string {
    return this.scoreLevel;
  }

  public getScoreColor(): string {
    return this.scoreColor;
  }

  private updateLevelAndColor(): void {
    if (this.todayScore >= 90) { this.scoreLevel = '优秀'; this.scoreColor = '#4CAF50'; }
    else if (this.todayScore >= 80) { this.scoreLevel = '良好'; this.scoreColor = '#8BC34A'; }
    else if (this.todayScore >= 70) { this.scoreLevel = '一般'; this.scoreColor = '#FFC107'; }
    else if (this.todayScore >= 60) { this.scoreLevel = '偏差'; this.scoreColor = '#FF9800'; }
    else { this.scoreLevel = '需关注'; this.scoreColor = '#F44336'; }
  }

  private updateColorFromScore(): void {
    if (this.todayScore >= 90) this.scoreColor = '#4CAF50';
    else if (this.todayScore >= 80) this.scoreColor = '#8BC34A';
    else if (this.todayScore >= 70) this.scoreColor = '#FFC107';
    else if (this.todayScore >= 60) this.scoreColor = '#FF9800';
    else this.scoreColor = '#F44336';
  }

  private calcBmiScore(bmi: number): number {
    if (bmi <= 0) return 15;
    if (bmi >= 18.5 && bmi < 24) return 25;
    if (bmi >= 24 && bmi < 28) return 18;
    if (bmi < 18.5) return 15;
    return 10;
  }

  private calcBpScore(sys: number, dia: number): number {
    if (sys <= 0 || dia <= 0) return 12;
    if (sys < 130 && dia < 85) return 20;
    if (sys < 140 && dia < 90) return 16;
    return 10;
  }

  private calcHrScore(hr: number): number {
    if (hr <= 0) return 9;
    if (hr >= 60 && hr <= 80) return 15;
    if (hr >= 50 && hr <= 100) return 12;
    return 8;
  }

  private calcBsScore(bs: number): number {
    if (bs <= 0) return 9;
    if (bs >= 3.9 && bs <= 6.1) return 15;
    if (bs >= 3.9 && bs <= 7.8) return 12;
    return 8;
  }

  private calcExerciseScore(steps: number, sleepHours: number): number {
    let score = 0;
    if (steps >= 8000) score += 15;
    else if (steps >= 5000) score += 10;
    else score += 5;
    if (sleepHours >= 7 && sleepHours <= 9) score += 10;
    else if (sleepHours >= 6) score += 7;
    else score += 4;
    return score;
  }

  private saveTodayScore(): void {
    const today = new Date();
    const dateStr = `${today.getFullYear()}-${(today.getMonth() + 1).toString().padStart(2, '0')}-${today.getDate().toString().padStart(2, '0')}`;
    const entry: ScoreHistory = {
      date: dateStr, score: this.todayScore,
      bmiScore: this.bmiScore, bpScore: this.bpScore,
      hrScore: this.hrScore, bsScore: this.bsScore, exerciseScore: this.exerciseScore
    };
    const updated = this.scoreHistory.filter(h => h.date !== dateStr);
    updated.push(entry);
    this.scoreHistory = updated.slice(-7);
  }
}

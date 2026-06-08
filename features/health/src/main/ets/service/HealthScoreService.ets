/**
 * 健康评分服务
 * 综合 BMI、血压、心率、血糖、运动等指标计算 0-100 的健康评分
 */
import { GlobalContext, PreferenceUtil } from 'common';
import { HealthDataInputModel } from '../viewmodel/HealthDataInputModel';

const SCORE_HISTORY_KEY = 'health_score_history';

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

  public static get instance(): HealthScoreService {
    if (!HealthScoreService._instance) {
      HealthScoreService._instance = new HealthScoreService();
    }
    return HealthScoreService._instance;
  }

  /**
   * 计算今日健康评分
   */
  public calculateScore(inputVM: HealthDataInputModel, stepCount: number, sleepHours: number): number {
    this.bmiScore = this.calcBmiScore(inputVM.bmiValue);
    this.bpScore = this.calcBpScore(inputVM.bloodPressureSystolic, inputVM.bloodPressureDiastolic);
    this.hrScore = this.calcHrScore(inputVM.heartRate);
    this.bsScore = this.calcBsScore(inputVM.bloodSugar);
    this.exerciseScore = this.calcExerciseScore(stepCount, sleepHours);

    this.todayScore = Math.round(
      this.bmiScore * 0.25 +
      this.bpScore * 0.2 +
      this.hrScore * 0.15 +
      this.bsScore * 0.15 +
      this.exerciseScore * 0.25
    );

    this.saveTodayScore();
    return this.todayScore;
  }

  /**
   * Mock 模式下生成评分历史（最近 7 天）
   */
  public generateMockHistory(): void {
    const history: ScoreHistory[] = [];
    const now = new Date();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const dateStr = `${d.getMonth() + 1}/${d.getDate()}`;
      // 确保每项子评分不为 0
      const bmi = 20 + Math.floor(Math.random() * 5);
      const bp = 17 + Math.floor(Math.random() * 3);
      const hr = 13 + Math.floor(Math.random() * 2);
      const bs = 13 + Math.floor(Math.random() * 2);
      const ex = 18 + Math.floor(Math.random() * 7);
      const total = Math.round(bmi * 0.25 + bp * 0.2 + hr * 0.15 + bs * 0.15 + ex * 0.25);
      history.push({
        date: dateStr,
        score: Math.min(100, Math.max(70, total)),
        bmiScore: bmi,
        bpScore: bp,
        hrScore: hr,
        bsScore: bs,
        exerciseScore: ex
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
    }
  }

  /**
   * 获取评分等级文字
   */
  public getScoreLevel(): string {
    if (this.todayScore >= 90) return '优秀';
    if (this.todayScore >= 80) return '良好';
    if (this.todayScore >= 70) return '一般';
    if (this.todayScore >= 60) return '偏差';
    return '需关注';
  }

  /**
   * 获取评分等级颜色
   */
  public getScoreColor(): string {
    if (this.todayScore >= 90) return '#4CAF50';
    if (this.todayScore >= 80) return '#8BC34A';
    if (this.todayScore >= 70) return '#FFC107';
    if (this.todayScore >= 60) return '#FF9800';
    return '#F44336';
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
    const dateStr = `${today.getFullYear()}-${(today.getMonth()+1).toString().padStart(2,'0')}-${today.getDate().toString().padStart(2,'0')}`;
    const entry: ScoreHistory = {
      date: dateStr,
      score: this.todayScore,
      bmiScore: this.bmiScore,
      bpScore: this.bpScore,
      hrScore: this.hrScore,
      bsScore: this.bsScore,
      exerciseScore: this.exerciseScore
    };
    const updated = this.scoreHistory.filter(h => h.date !== dateStr);
    updated.push(entry);
    this.scoreHistory = updated.slice(-7);
  }
}

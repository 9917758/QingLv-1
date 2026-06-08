/**
 * 连续打卡天数服务
 * 追踪每条提醒计划的连续打卡天数和总打卡统计
 */
import { GlobalContext, PreferenceUtil } from 'common';

const STREAK_KEY = 'checkin_streak_data';

export interface PlanStreak {
  planId: string;
  planName: string;
  currentStreak: number;
  longestStreak: number;
  totalCheckins: number;
  lastCheckinDate: string;
}

export interface StreakRecord {
  date: string;
  planIds: string[];
}

@ObservedV2
export class CheckinStreakService {
  private static _instance: CheckinStreakService;
  @Trace streaks: PlanStreak[] = [];
  @Trace totalStreakDays: number = 0;

  public static get instance(): CheckinStreakService {
    if (!CheckinStreakService._instance) {
      CheckinStreakService._instance = new CheckinStreakService();
    }
    return CheckinStreakService._instance;
  }

  /**
   * 记录今日打卡（在 ReminderService.markPlanChecked 后调用）
   */
  public recordCheckin(planId: string, planName: string): void {
    const today = this.getTodayStr();
    const streak = this.getOrCreateStreak(planId, planName);

    if (streak.lastCheckinDate === today) {
      return; // 今天已记录
    }

    const yesterday = this.getYesterdayStr();
    if (streak.lastCheckinDate === yesterday) {
      streak.currentStreak++;
    } else if (streak.lastCheckinDate !== today) {
      streak.currentStreak = 1;
    }

    if (streak.currentStreak > streak.longestStreak) {
      streak.longestStreak = streak.currentStreak;
    }

    streak.totalCheckins++;
    streak.lastCheckinDate = today;
    this.saveStreaks();
    this.updateTotalStreakDays();
  }

  /**
   * 获取指定计划的连续打卡天数
   */
  public getStreak(planId: string): number {
    const streak = this.streaks.find(s => s.planId === planId);
    return streak ? streak.currentStreak : 0;
  }

  /**
   * 生成 Mock 打卡历史
   */
  public generateMockStreaks(): void {
    this.streaks = [
      { planId: 'mock_water_1', planName: '早晨喝水', currentStreak: 12, longestStreak: 15, totalCheckins: 28, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_water_2', planName: '下午喝水', currentStreak: 8, longestStreak: 12, totalCheckins: 25, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_med_1', planName: '降压药', currentStreak: 20, longestStreak: 20, totalCheckins: 30, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_water_3', planName: '睡前喝水', currentStreak: 5, longestStreak: 10, totalCheckins: 22, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_med_2', planName: '维生素', currentStreak: 15, longestStreak: 18, totalCheckins: 27, lastCheckinDate: this.getTodayStr() }
    ];
    this.updateTotalStreakDays();
  }

  /**
   * 计算某条计划的本月打卡完成率
   */
  public getMonthlyAdherence(planId: string): number {
    const streak = this.streaks.find(s => s.planId === planId);
    if (!streak) return 0;
    const now = new Date();
    const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    return Math.min(Math.round((streak.totalCheckins / daysInMonth) * 100), 100);
  }

  private getOrCreateStreak(planId: string, planName: string): PlanStreak {
    let streak = this.streaks.find(s => s.planId === planId);
    if (!streak) {
      streak = { planId, planName, currentStreak: 0, longestStreak: 0, totalCheckins: 0, lastCheckinDate: '' };
      this.streaks.push(streak);
    }
    return streak;
  }

  private updateTotalStreakDays(): void {
    this.totalStreakDays = this.streaks.reduce((sum, s) => sum + s.currentStreak, 0);
  }

  private getTodayStr(): string {
    const d = new Date();
    return `${d.getFullYear()}-${(d.getMonth()+1).toString().padStart(2,'0')}-${d.getDate().toString().padStart(2,'0')}`;
  }

  private getYesterdayStr(): string {
    const d = new Date();
    d.setDate(d.getDate() - 1);
    return `${d.getFullYear()}-${(d.getMonth()+1).toString().padStart(2,'0')}-${d.getDate().toString().padStart(2,'0')}`;
  }

  private saveStreaks(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(STREAK_KEY, JSON.stringify(this.streaks));
    } catch (err) {
      // ignore
    }
  }

  public loadStreaks(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const raw = pref.get(STREAK_KEY, '[]') as string;
      const parsed = JSON.parse(raw) as PlanStreak[];
      if (Array.isArray(parsed) && parsed.length > 0) {
        this.streaks = parsed;
        this.updateTotalStreakDays();
      } else {
        this.generateMockStreaks();
      }
    } catch {
      this.generateMockStreaks();
    }
  }
}

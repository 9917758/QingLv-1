/**
 * 连续打卡天数服务
 * 追踪每条提醒计划的连续打卡天数和总打卡统计
 * 本地存储按用户ID隔离
 */
import { GlobalContext, PreferenceUtil, UserInfo, USE_MOCK_DATA } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

export interface PlanStreak {
  planId: string;
  planName: string;
  currentStreak: number;
  longestStreak: number;
  totalCheckins: number;
  lastCheckinDate: string;
}

@ObservedV2
export class CheckinStreakService {
  private static _instance: CheckinStreakService;
  @Trace streaks: PlanStreak[] = [];
  @Trace totalStreakDays: number = 0;
  private _loadedUserId: string = '';

  public static get instance(): CheckinStreakService {
    if (!CheckinStreakService._instance) {
      CheckinStreakService._instance = new CheckinStreakService();
    }
    return CheckinStreakService._instance;
  }

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private getStreakKey(): string {
    return `checkin_streak_${CheckinStreakService.getUserId()}`;
  }

  /** 清除内存缓存 */
  public clearCache(): void {
    this.streaks = [];
    this.totalStreakDays = 0;
    this._loadedUserId = '';
  }

  /** 用户切换时自动清除缓存 */
  private checkUserSwitch(): void {
    const userId = CheckinStreakService.getUserId();
    if (this._loadedUserId.length > 0 && this._loadedUserId !== userId) {
      this.clearCache();
    }
    this._loadedUserId = userId;
  }

  public recordCheckin(planId: string, planName: string): void {
    const today = this.getTodayStr();
    const streak = this.getOrCreateStreak(planId, planName);
    if (streak.lastCheckinDate === today) return;
    const yesterday = this.getYesterdayStr();
    if (streak.lastCheckinDate === yesterday) {
      streak.currentStreak++;
    } else {
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

  public updateFromCheckin(planId: string, planName: string, streak: number): void {
    const existing = this.streaks.find(s => s.planId === planId);
    if (existing) {
      existing.currentStreak = streak;
      if (streak > existing.longestStreak) existing.longestStreak = streak;
      existing.totalCheckins++;
      existing.lastCheckinDate = this.getTodayStr();
    } else {
      this.streaks.push({
        planId, planName, currentStreak: streak,
        longestStreak: streak, totalCheckins: 1,
        lastCheckinDate: this.getTodayStr()
      });
    }
    this.updateTotalStreakDays();
  }

  public getStreak(planId: string): number {
    const streak = this.streaks.find(s => s.planId === planId);
    return streak ? streak.currentStreak : 0;
  }

  public generateMockStreaks(): void {
    this.streaks = [
      { planId: 'mock_water_1', planName: '早晨喝水', currentStreak: 12, longestStreak: 15, totalCheckins: 28, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_water_2', planName: '下午喝水', currentStreak: 8, longestStreak: 12, totalCheckins: 25, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_med_1', planName: '血压药', currentStreak: 20, longestStreak: 20, totalCheckins: 30, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_water_3', planName: '晚上喝水', currentStreak: 5, longestStreak: 10, totalCheckins: 22, lastCheckinDate: this.getTodayStr() },
      { planId: 'mock_med_2', planName: '维生素', currentStreak: 15, longestStreak: 18, totalCheckins: 27, lastCheckinDate: this.getTodayStr() }
    ];
    this.updateTotalStreakDays();
  }

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
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  }

  private getYesterdayStr(): string {
    const d = new Date();
    d.setDate(d.getDate() - 1);
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  }

  private saveStreaks(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this.getStreakKey(), JSON.stringify(this.streaks));
    } catch {
      // ignore
    }
  }

  public loadStreaks(): void {
    this.checkUserSwitch();
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const raw = pref.get(this.getStreakKey(), '[]') as string;
      const parsed = JSON.parse(raw) as PlanStreak[];
      if (Array.isArray(parsed) && parsed.length > 0) {
        this.streaks = parsed;
        this.updateTotalStreakDays();
      } else if (USE_MOCK_DATA) {
        this.generateMockStreaks();
      }
    } catch {
      if (USE_MOCK_DATA) {
        this.generateMockStreaks();
      }
    }
  }
}

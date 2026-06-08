/**
 * 喝水打卡服务
 * 管理每日喝水次数记录，支持打卡和查询
 */
import { GlobalContext, PreferenceUtil } from 'common';

const WATER_INTAKE_PREFIX = 'water_intake_';
const WATER_GOAL_KEY = 'water_intake_goal';
const DEFAULT_DAILY_GOAL = 8; // 默认每日目标杯数
const MAX_CUPS = 20; // 每日最大杯数上限

@ObservedV2
export class WaterIntakeService {
  private static _instance: WaterIntakeService;
  @Trace todayCount: number = 0;
  @Trace todayGoal: number = DEFAULT_DAILY_GOAL;
  private _todayKey: string = '';

  public static get instance(): WaterIntakeService {
    if (!WaterIntakeService._instance) {
      WaterIntakeService._instance = new WaterIntakeService();
    }
    return WaterIntakeService._instance;
  }

  /**
   * 获取今天的存储 key（格式：water_intake_20260607）
   */
  private getTodayKey(): string {
    const now = new Date();
    const key = `${WATER_INTAKE_PREFIX}${now.getFullYear()}${(now.getMonth() + 1).toString().padStart(2, '0')}${now.getDate().toString().padStart(2, '0')}`;
    return key;
  }

  /**
   * 加载今日喝水数据
   */
  public loadToday(): number {
    this._todayKey = this.getTodayKey();
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const val = pref.get(this._todayKey, '0') as string;
      this.todayCount = Number(val);
    } catch {
      this.todayCount = 0;
    }
    return this.todayCount;
  }

  /**
   * 喝水打卡（+1），上限 MAX_CUPS
   */
  public drink(): number {
    if (this.todayCount >= MAX_CUPS) {
      return this.todayCount;
    }
    this.todayCount++;
    this.persist();
    return this.todayCount;
  }

  /**
   * 设置今日喝水次数（用于手动调整）
   */
  public setCount(count: number): void {
    this.todayCount = Math.max(0, count);
    this.persist();
  }

  /**
   * 设置每日目标杯数
   */
  public setGoal(goal: number): void {
    this.todayGoal = Math.max(1, goal);
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(WATER_GOAL_KEY, String(this.todayGoal));
    } catch {
    }
  }

  /**
   * 加载每日目标
   */
  public loadGoal(): number {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const val = pref.get(WATER_GOAL_KEY, String(DEFAULT_DAILY_GOAL)) as string;
      this.todayGoal = Number(val);
    } catch {
      this.todayGoal = DEFAULT_DAILY_GOAL;
    }
    return this.todayGoal;
  }

  /**
   * 获取今日进度百分比
   */
  public getProgress(): number {
    if (this.todayGoal <= 0) return 0;
    return Math.min(Math.round((this.todayCount / this.todayGoal) * 100), 100);
  }

  /**
   * 是否达标
   */
  public isGoalReached(): boolean {
    return this.todayCount >= this.todayGoal;
  }

  /**
   * 持久化今日喝水次数
   */
  private persist(): void {
    if (!this._todayKey) {
      this._todayKey = this.getTodayKey();
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this._todayKey, String(this.todayCount));
    } catch (err) {
      console.error('WaterIntakeService persist failed');
    }
  }
}

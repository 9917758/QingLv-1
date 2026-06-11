/**
 * 喝水打卡服务
 * 管理每日喝水次数记录，支持打卡和查询
 * 支持两种模式：本地 Mock / 后端 API
 * 本地存储按用户ID隔离
 */
import { GlobalContext, PreferenceUtil, HttpUtil, AuthToken, UserInfo } from 'common';
import type { ApiResponse, ApiWaterIntake } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

const WATER_INTAKE_PREFIX = 'water_intake_';
const WATER_GOAL_KEY_PREFIX = 'water_intake_goal_';
const DEFAULT_DAILY_GOAL = 8;
const MAX_CUPS = 20;

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

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private getTodayKey(): string {
    const now = new Date();
    const uid = WaterIntakeService.getUserId();
    return `${WATER_INTAKE_PREFIX}${uid}_${now.getFullYear()}${(now.getMonth() + 1).toString().padStart(2, '0')}${now.getDate().toString().padStart(2, '0')}`;
  }

  private getGoalKey(): string {
    return `${WATER_GOAL_KEY_PREFIX}${WaterIntakeService.getUserId()}`;
  }

  /** 清除内存缓存 */
  public clearCache(): void {
    this.todayCount = 0;
    this.todayGoal = DEFAULT_DAILY_GOAL;
    this._todayKey = '';
  }

  /** 同步加载（兼容旧调用） */
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

  /** 从后端 API 加载今日饮水（异步） */
  public async loadFromApi(): Promise<number> {
    if (!AuthToken.isLoggedIn()) {
      this.loadToday();
      return this.todayCount;
    }
    const resp: ApiResponse<ApiWaterIntake> = await HttpUtil.get<ApiWaterIntake>('/api/health/water');
    if (resp.data) {
      this.todayCount = resp.data.cup_count;
      this.todayGoal = resp.data.daily_goal;
    }
    return this.todayCount;
  }

  /** 喝水打卡（+1） */
  public drink(): number {
    if (this.todayCount >= MAX_CUPS) return this.todayCount;
    this.todayCount++;
    if (AuthToken.isLoggedIn()) {
      HttpUtil.post<ApiWaterIntake>('/api/health/water/drink');
    }
    this.persistLocal();
    return this.todayCount;
  }

  public setCount(count: number): void {
    this.todayCount = Math.max(0, count);
    this.persistLocal();
  }

  public setGoal(goal: number): void {
    this.todayGoal = Math.max(1, goal);
    if (AuthToken.isLoggedIn()) {
      HttpUtil.put<ApiWaterIntake>(`/api/health/water/goal?goal=${this.todayGoal}`);
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this.getGoalKey(), String(this.todayGoal));
    } catch {
      // ignore
    }
  }

  public loadGoal(): number {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const val = pref.get(this.getGoalKey(), String(DEFAULT_DAILY_GOAL)) as string;
      this.todayGoal = Number(val);
    } catch {
      this.todayGoal = DEFAULT_DAILY_GOAL;
    }
    return this.todayGoal;
  }

  public getProgress(): number {
    if (this.todayGoal <= 0) return 0;
    return Math.min(Math.round((this.todayCount / this.todayGoal) * 100), 100);
  }

  public isGoalReached(): boolean {
    return this.todayCount >= this.todayGoal;
  }

  private persistLocal(): void {
    if (!this._todayKey) this._todayKey = this.getTodayKey();
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this._todayKey, String(this.todayCount));
    } catch {
      // ignore
    }
  }
}

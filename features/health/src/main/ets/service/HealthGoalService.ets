/**
 * 健康目标管理服务
 * 管理用户设定的健康目标（目标体重等）
 * 本地存储按用户ID隔离
 */
import { GlobalContext, PreferenceUtil, UserInfo } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

const GOAL_WEIGHT_KEY_PREFIX = 'health_goal_weight_';

@ObservedV2
export class HealthGoalService {
  private static _instance: HealthGoalService;
  @Trace goalWeight: number = 0;
  private _loadedUserId: string = '';

  public static get instance(): HealthGoalService {
    if (!HealthGoalService._instance) {
      HealthGoalService._instance = new HealthGoalService();
    }
    return HealthGoalService._instance;
  }

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private getGoalKey(): string {
    return `${GOAL_WEIGHT_KEY_PREFIX}${HealthGoalService.getUserId()}`;
  }

  /** 清除内存缓存 */
  public clearCache(): void {
    this.goalWeight = 0;
    this._loadedUserId = '';
  }

  /** 用户切换时自动清除缓存 */
  private checkUserSwitch(): void {
    const userId = HealthGoalService.getUserId();
    if (this._loadedUserId.length > 0 && this._loadedUserId !== userId) {
      this.clearCache();
    }
    this._loadedUserId = userId;
  }

  public loadGoal(): number {
    this.checkUserSwitch();
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const val = pref.get(this.getGoalKey(), '0') as string;
      this.goalWeight = Number(val);
    } catch {
      this.goalWeight = 0;
    }
    return this.goalWeight;
  }

  public setGoalWeight(weight: number): void {
    this.goalWeight = weight;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this.getGoalKey(), String(weight));
    } catch {
      // ignore
    }
  }

  public getWeightDiff(currentWeight: number): number {
    if (this.goalWeight <= 0) return 0;
    return Math.round((currentWeight - this.goalWeight) * 10) / 10;
  }

  public getGoalDescription(currentWeight: number): string {
    if (this.goalWeight <= 0) return '';
    const diff = this.getWeightDiff(currentWeight);
    if (diff > 0) return `距目标还差 ${diff.toFixed(1)} 斤`;
    else if (diff < 0) return `已超过目标 ${Math.abs(diff).toFixed(1)} 斤`;
    else return '🎉 已达成目标！';
  }

  public getProgress(startWeight: number, currentWeight: number): number {
    if (this.goalWeight <= 0 || startWeight <= this.goalWeight) return 0;
    const totalToLose = startWeight - this.goalWeight;
    const lost = startWeight - currentWeight;
    return Math.min(Math.max(Math.round((lost / totalToLose) * 100), 0), 100);
  }
}

/**
 * 健康目标管理服务
 * 管理用户设定的健康目标（目标体重等）
 */
import { GlobalContext, PreferenceUtil } from 'common';

const GOAL_WEIGHT_KEY = 'health_goal_weight';

@ObservedV2
export class HealthGoalService {
  private static _instance: HealthGoalService;
  @Trace goalWeight: number = 0; // 目标体重（斤），0表示未设定

  public static get instance(): HealthGoalService {
    if (!HealthGoalService._instance) {
      HealthGoalService._instance = new HealthGoalService();
    }
    return HealthGoalService._instance;
  }

  /**
   * 加载目标体重
   */
  public loadGoal(): number {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const val = pref.get(GOAL_WEIGHT_KEY, '0') as string;
      this.goalWeight = Number(val);
    } catch {
      this.goalWeight = 0;
    }
    return this.goalWeight;
  }

  /**
   * 设置目标体重
   */
  public setGoalWeight(weight: number): void {
    this.goalWeight = weight;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(GOAL_WEIGHT_KEY, String(weight));
    } catch {
    }
  }

  /**
   * 计算当前体重与目标的差距（斤）
   * 正值表示还需减重，负值表示已超过目标
   */
  public getWeightDiff(currentWeight: number): number {
    if (this.goalWeight <= 0) return 0;
    return Math.round((currentWeight - this.goalWeight) * 10) / 10;
  }

  /**
   * 获取目标进度描述
   */
  public getGoalDescription(currentWeight: number): string {
    if (this.goalWeight <= 0) return '';
    const diff = this.getWeightDiff(currentWeight);
    if (diff > 0) {
      return `距目标还差 ${diff.toFixed(1)} 斤`;
    } else if (diff < 0) {
      return `已超过目标 ${Math.abs(diff).toFixed(1)} 斤`;
    } else {
      return '🎉 已达成目标！';
    }
  }

  /**
   * 获取进度百分比（0-100）
   * 假设起始体重比目标重 20 斤为 0%，达到目标为 100%
   */
  public getProgress(startWeight: number, currentWeight: number): number {
    if (this.goalWeight <= 0 || startWeight <= this.goalWeight) return 0;
    const totalToLose = startWeight - this.goalWeight;
    const lost = startWeight - currentWeight;
    return Math.min(Math.max(Math.round((lost / totalToLose) * 100), 0), 100);
  }
}

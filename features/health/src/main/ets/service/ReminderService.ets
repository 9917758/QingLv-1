import { GlobalContext, PreferenceConstant, PreferenceUtil, TCLogger, TimeUtil } from 'common';
import { ReminderPlanItem } from '../model/ReminderPlanModel';
import { DEFAULT_REMINDER_PLANS } from '../mock/ReminderMockData';

const TAG = 'ReminderService';

/**
 * 提醒计划服务
 * 集中管理提醒计划的加载、校验、缓存、存储，供 HomePage 和 ReminderPlanPage 共用
 * （#2 模块职责内聚、#4 内存缓存、#7 JSON 校验）
 */
export class ReminderService {
  private static cachedPlans: ReminderPlanItem[] | null = null;
  // 今日已打卡计划ID缓存（内存级，同步持久化到 Preferences）
  private static checkedTodayIds: Set<string> = new Set();
  private static checkedTodayDate: string = '';

  /**
   * 校验解析后的对象是否为合法的 ReminderPlanItem（#7）
   */
  static isValidPlan(obj: Record<string, Object>): boolean {
    if (obj['id'] === undefined || obj['id'] === null || typeof obj['id'] !== 'string') {
      return false;
    }
    if (obj['name'] === undefined || obj['name'] === null || typeof obj['name'] !== 'string') {
      return false;
    }
    if (obj['time'] === undefined || obj['time'] === null || typeof obj['time'] !== 'string') {
      return false;
    }
    if (obj['type'] === undefined || obj['type'] === null || typeof obj['type'] !== 'number') {
      return false;
    }
    return true;
  }

  /**
   * 从存储解析计划列表（模块级函数，避免 any）
   */
  private static parsePlans(data: string): ReminderPlanItem[] {
    const raw: Object[] = JSON.parse(data) as Object[];
    const result: ReminderPlanItem[] = [];
    for (let i = 0; i < raw.length; i++) {
      const item: Record<string, Object> = raw[i] as Record<string, Object>;
      if (!ReminderService.isValidPlan(item)) {
        continue; // 跳过损坏条目
      }
      const plan = new ReminderPlanItem();
      plan.id = (item['id'] as string) || '';
      plan.type = (item['type'] as number) || 0;
      plan.name = (item['name'] as string) || '';
      plan.time = (item['time'] as string) || '';
      plan.dosage = (item['dosage'] as string) || '';
      plan.isEnabled = (item['isEnabled'] as boolean) ?? true;
      plan.isCheckedToday = (item['isCheckedToday'] as boolean) ?? false;
      result.push(plan);
    }
    return result;
  }

  /**
   * 深拷贝单条计划（ArkTS 不允许对象 spread）
   */
  static copyPlan(src: ReminderPlanItem): ReminderPlanItem {
    const dst = new ReminderPlanItem();
    dst.id = src.id;
    dst.type = src.type;
    dst.name = src.name;
    dst.time = src.time;
    dst.dosage = src.dosage;
    dst.isEnabled = src.isEnabled;
    dst.isCheckedToday = src.isCheckedToday;
    return dst;
  }

  /**
   * 获取默认计划的深拷贝列表
   */
  static getDefaultPlans(): ReminderPlanItem[] {
    const defaults: ReminderPlanItem[] = [];
    for (let i = 0; i < DEFAULT_REMINDER_PLANS.length; i++) {
      defaults.push(ReminderService.copyPlan(DEFAULT_REMINDER_PLANS[i]));
    }
    return defaults;
  }

  /**
   * 加载提醒计划（带内存缓存，#4）
   * 30 秒轮询一次时直接返回缓存，避免重复磁盘读取+JSON.parse
   */
  static loadPlans(): ReminderPlanItem[] {
    if (ReminderService.cachedPlans !== null) {
      return ReminderService.cachedPlans;
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const data = pref.get(PreferenceConstant.REMINDER_PLANS, '') as string;
      if (data && data.length > 0) {
        const parsed: ReminderPlanItem[] = ReminderService.parsePlans(data);
        if (parsed.length > 0 && parsed[0].name !== 'undefined') {
          ReminderService.cachedPlans = parsed;
          return parsed;
        }
        // 数据损坏，清除
        pref.delete(PreferenceConstant.REMINDER_PLANS);
      }
    } catch (e) {
      const err = e instanceof Error ? e : new Error(String(e));
      TCLogger.error(TAG, `loadPlans error: ${err.message}`);
    }
    const defaults = ReminderService.getDefaultPlans();
    ReminderService.cachedPlans = defaults;
    return defaults;
  }

  /**
   * 保存计划到存储并更新缓存
   */
  static savePlans(plans: ReminderPlanItem[]): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(PreferenceConstant.REMINDER_PLANS, JSON.stringify(plans));
      ReminderService.cachedPlans = plans;
    } catch (e) {
      const err = e instanceof Error ? e : new Error(String(e));
      TCLogger.error(TAG, `savePlans error: ${err.message}`);
    }
  }

  /**
   * 使缓存失效（ReminderPlanPage 修改计划后调用，#4）
   */
  static invalidateCache(): void {
    ReminderService.cachedPlans = null;
  }

  /**
   * 获取今天已打卡的计划 ID 集合（内存缓存 + 存储双层）
   */
  static getCheckedTodayIds(): Set<string> {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    // 跨天清空
    if (ReminderService.checkedTodayDate !== today) {
      ReminderService.checkedTodayIds = new Set();
      ReminderService.checkedTodayDate = today;
    }
    // 内存已有数据直接返回
    if (ReminderService.checkedTodayIds.size > 0) {
      return ReminderService.checkedTodayIds;
    }
    // 从存储加载
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const stored = pref.get(PreferenceConstant.REMINDER_CHECKED_TODAY, '{}') as string;
      const data: Record<string, Object> = JSON.parse(stored) as Record<string, Object>;
      if (data['date'] === today) {
        const ids = data['ids'];
        if (ids !== undefined && ids !== null) {
          const arr = ids as string[];
          for (let i = 0; i < arr.length; i++) {
            ReminderService.checkedTodayIds.add(arr[i]);
          }
        }
      }
    } catch {
      TCLogger.error(TAG, 'getCheckedTodayIds error');
    }
    return ReminderService.checkedTodayIds;
  }

  /**
   * 标记指定计划今日已打卡（内存 + 持久化）
   */
  static markPlanChecked(planId: string): void {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    ReminderService.getCheckedTodayIds(); // 确保已加载
    if (ReminderService.checkedTodayIds.has(planId)) {
      return; // 已打过
    }
    ReminderService.checkedTodayIds.add(planId);
    ReminderService.checkedTodayDate = today;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(PreferenceConstant.REMINDER_CHECKED_TODAY,
        JSON.stringify({ date: today, ids: Array.from(ReminderService.checkedTodayIds) }));
    } catch {
      TCLogger.error(TAG, 'markPlanChecked error');
    }
  }

  /**
   * 检查指定计划今日是否已打卡
   */
  static isPlanCheckedToday(planId: string): boolean {
    return ReminderService.getCheckedTodayIds().has(planId);
  }

  /**
   * 跨天重置打卡记录（清空内存缓存和存储）
   */
  static resetCheckedToday(): void {
    ReminderService.checkedTodayIds = new Set();
    ReminderService.checkedTodayDate = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(PreferenceConstant.REMINDER_CHECKED_TODAY,
        JSON.stringify({ date: ReminderService.checkedTodayDate, ids: [] }));
    } catch {
      TCLogger.error(TAG, 'resetCheckedToday error');
    }
    ReminderService.invalidateCache();
  }

  /**
   * 将今日打卡状态同步到计划列表的 isCheckedToday 字段
   * 返回同步后的新数组（深拷贝），可直接赋值给 @Local plans
   */
  static syncCheckedStatus(plans: ReminderPlanItem[]): ReminderPlanItem[] {
    const checkedIds = ReminderService.getCheckedTodayIds();
    const result: ReminderPlanItem[] = [];
    for (let i = 0; i < plans.length; i++) {
      const copied = ReminderService.copyPlan(plans[i]);
      copied.isCheckedToday = checkedIds.has(copied.id);
      result.push(copied);
    }
    return result;
  }

  /**
   * 清除缓存和存储（重置场景用）
   */
  static clearAll(): void {
    ReminderService.cachedPlans = null;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.delete(PreferenceConstant.REMINDER_PLANS);
    } catch (e) {
      TCLogger.error(TAG, `clearAll error: ${JSON.stringify(e)}`);
    }
  }
}

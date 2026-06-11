/**
 * 提醒计划服务
 * 集中管理提醒计划的加载、校验、缓存、存储，供 HomePage 和 ReminderPlanPage 共用
 * 支持两种模式：本地 Mock / 后端 API
 * 本地存储按用户ID隔离
 */
import { GlobalContext, PreferenceUtil, HttpUtil, AuthToken, TCLogger, TimeUtil, UserInfo } from 'common';
import type { ApiResponse, ApiReminderPlan } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';
import { ReminderPlanItem } from '../model/ReminderPlanModel';
import { DEFAULT_REMINDER_PLANS } from '../mock/ReminderMockData';

const TAG = 'ReminderService';

interface PlanSavePayload {
  plan_id: string;
  plan_type: number;
  name: string;
  time: string;
  dosage: string;
  is_enabled: boolean;
}

export class ReminderService {
  private static cachedPlans: ReminderPlanItem[] | null = null;
  private static checkedTodayIds: Set<string> = new Set();
  private static checkedTodayDate: string = '';
  private static cachedUserId: string = '';

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private static getPlansKey(): string {
    return `reminder_plans_${ReminderService.getUserId()}`;
  }

  private static getCheckedKey(): string {
    return `reminder_checked_${ReminderService.getUserId()}`;
  }

  static isValidPlan(obj: Record<string, Object>): boolean {
    if (obj['id'] === undefined || obj['id'] === null || typeof obj['id'] !== 'string') return false;
    if (obj['name'] === undefined || obj['name'] === null || typeof obj['name'] !== 'string') return false;
    if (obj['time'] === undefined || obj['time'] === null || typeof obj['time'] !== 'string') return false;
    if (obj['type'] === undefined || obj['type'] === null || typeof obj['type'] !== 'number') return false;
    return true;
  }

  private static parsePlans(data: string): ReminderPlanItem[] {
    const raw: Object[] = JSON.parse(data) as Object[];
    const result: ReminderPlanItem[] = [];
    for (let i = 0; i < raw.length; i++) {
      const item: Record<string, Object> = raw[i] as Record<string, Object>;
      if (!ReminderService.isValidPlan(item)) continue;
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

  static copyPlan(src: ReminderPlanItem): ReminderPlanItem {
    const dst = new ReminderPlanItem();
    dst.id = src.id; dst.type = src.type; dst.name = src.name;
    dst.time = src.time; dst.dosage = src.dosage;
    dst.isEnabled = src.isEnabled; dst.isCheckedToday = src.isCheckedToday;
    return dst;
  }

  static getDefaultPlans(): ReminderPlanItem[] {
    const defaults: ReminderPlanItem[] = [];
    for (let i = 0; i < DEFAULT_REMINDER_PLANS.length; i++) {
      defaults.push(ReminderService.copyPlan(DEFAULT_REMINDER_PLANS[i]));
    }
    return defaults;
  }

  /** 用户切换时自动清除缓存 */
  private static checkUserSwitch(): void {
    const userId = ReminderService.getUserId();
    if (ReminderService.cachedUserId.length > 0 && ReminderService.cachedUserId !== userId) {
      ReminderService.invalidateCache();
      ReminderService.checkedTodayIds = new Set();
      ReminderService.checkedTodayDate = '';
    }
    ReminderService.cachedUserId = userId;
  }

  /** 同步加载 */
  static loadPlans(): ReminderPlanItem[] {
    ReminderService.checkUserSwitch();
    if (ReminderService.cachedPlans !== null) {
      return ReminderService.cachedPlans;
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const data = pref.get(ReminderService.getPlansKey(), '') as string;
      if (data && data.length > 0) {
        const parsed: ReminderPlanItem[] = ReminderService.parsePlans(data);
        if (parsed.length > 0 && parsed[0].name !== 'undefined') {
          ReminderService.cachedPlans = parsed;
          return parsed;
        }
        pref.delete(ReminderService.getPlansKey());
      }
    } catch (e) {
      const err = e instanceof Error ? e : new Error(String(e));
      TCLogger.error(TAG, `loadPlans error: ${err.message}`);
    }
    const defaults = ReminderService.getDefaultPlans();
    ReminderService.cachedPlans = defaults;
    return defaults;
  }

  /** 从后端 API 加载计划 */
  static async loadFromApi(): Promise<ReminderPlanItem[]> {
    if (!AuthToken.isLoggedIn()) return ReminderService.loadPlans();
    const resp: ApiResponse<ApiReminderPlan[]> = await HttpUtil.get<ApiReminderPlan[]>('/api/health/plans');
    if (resp.data && resp.data.length > 0) {
      const plans: ReminderPlanItem[] = [];
      for (let i = 0; i < resp.data.length; i++) {
        const r = resp.data[i];
        const plan = new ReminderPlanItem();
        plan.id = r.plan_id; plan.type = r.plan_type; plan.name = r.name;
        plan.time = r.time; plan.dosage = r.dosage; plan.isEnabled = r.is_enabled;
        plan.isCheckedToday = ReminderService.isPlanCheckedToday(r.plan_id);
        plans.push(plan);
      }
      ReminderService.cachedPlans = plans;
    }
    return ReminderService.cachedPlans || ReminderService.loadPlans();
  }

  /** 保存计划 */
  static savePlans(plans: ReminderPlanItem[]): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(ReminderService.getPlansKey(), JSON.stringify(plans));
      ReminderService.cachedPlans = plans;
    } catch (e) {
      const err = e instanceof Error ? e : new Error(String(e));
      TCLogger.error(TAG, `savePlans error: ${err.message}`);
    }
    if (AuthToken.isLoggedIn()) {
      for (let i = 0; i < plans.length; i++) {
        const p = plans[i];
        const payload: PlanSavePayload = {
          plan_id: p.id, plan_type: p.type, name: p.name,
          time: p.time, dosage: p.dosage, is_enabled: p.isEnabled
        };
        HttpUtil.post<ApiReminderPlan>('/api/health/plans', payload);
      }
    }
  }

  static invalidateCache(): void {
    ReminderService.cachedPlans = null;
  }

  static getCheckedTodayIds(): Set<string> {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    if (ReminderService.checkedTodayDate !== today) {
      ReminderService.checkedTodayIds = new Set();
      ReminderService.checkedTodayDate = today;
    }
    if (ReminderService.checkedTodayIds.size > 0) return ReminderService.checkedTodayIds;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const stored = pref.get(ReminderService.getCheckedKey(), '{}') as string;
      const data: Record<string, Object> = JSON.parse(stored) as Record<string, Object>;
      if (data['date'] === today) {
        const ids = data['ids'];
        if (ids !== undefined && ids !== null) {
          const arr = ids as string[];
          for (let i = 0; i < arr.length; i++) ReminderService.checkedTodayIds.add(arr[i]);
        }
      }
    } catch {
      TCLogger.error(TAG, 'getCheckedTodayIds error');
    }
    return ReminderService.checkedTodayIds;
  }

  static markPlanChecked(planId: string): void {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    ReminderService.getCheckedTodayIds();
    if (ReminderService.checkedTodayIds.has(planId)) return;
    ReminderService.checkedTodayIds.add(planId);
    ReminderService.checkedTodayDate = today;
    if (AuthToken.isLoggedIn()) {
      HttpUtil.post<object>(`/api/health/checkin/${planId}`);
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(ReminderService.getCheckedKey(),
        JSON.stringify({ date: today, ids: Array.from(ReminderService.checkedTodayIds) }));
    } catch {
      TCLogger.error(TAG, 'markPlanChecked error');
    }
  }

  static isPlanCheckedToday(planId: string): boolean {
    return ReminderService.getCheckedTodayIds().has(planId);
  }

  static resetCheckedToday(): void {
    ReminderService.checkedTodayIds = new Set();
    ReminderService.checkedTodayDate = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(ReminderService.getCheckedKey(),
        JSON.stringify({ date: ReminderService.checkedTodayDate, ids: [] }));
    } catch {
      TCLogger.error(TAG, 'resetCheckedToday error');
    }
    ReminderService.invalidateCache();
  }

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

  static clearAll(): void {
    ReminderService.cachedPlans = null;
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.delete(ReminderService.getPlansKey());
    } catch (e) {
      TCLogger.error(TAG, `clearAll error: ${JSON.stringify(e)}`);
    }
  }
}

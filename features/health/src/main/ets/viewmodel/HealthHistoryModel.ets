/**
 * 健康历史记录 Model
 */
import { HealthHistoryItem, MonthGroup } from '../types/HealthHistoryTypes';
import { HEALTH_HISTORY_GROUPS } from '../mock/HealthHistoryMockData';
import { HealthDataService } from '../service/HealthDataService';
import { GlobalContext, USE_MOCK_DATA, UserInfo } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

@ObservedV2
export class HealthHistoryModel {
  private static _instance: HealthHistoryModel;

  @Trace historyGroups: MonthGroup[] = [];
  @Trace selectedMonth: string = '';
  @Trace showMonthPicker: boolean = false;

  public static get instance() {
    if (!HealthHistoryModel._instance) {
      HealthHistoryModel._instance = new HealthHistoryModel();
    }
    return HealthHistoryModel._instance;
  }

  /**
   * 加载历史数据
   */
  public loadHistory(): void {
    if (USE_MOCK_DATA) {
      // Mock 模式：合并 mock 数据和用户录入的数据
      const records = HealthDataService.instance.loadRecords();
      const fromRecords = this.convertRecordsToGroups(records);
      // 合并 mock 数据和记录数据，去重
      const allGroups = this.mergeGroups(HEALTH_HISTORY_GROUPS, fromRecords);
      this.historyGroups = allGroups;
    } else {
      const records = HealthDataService.instance.loadRecords();
      this.historyGroups = this.convertRecordsToGroups(records);
    }

    // 设置默认选中月份
    if (this.historyGroups.length > 0 && !this.selectedMonth) {
      this.selectedMonth = this.historyGroups[0].month;
    }
  }

  /**
   * 从用户信息中获取身高
   */
  private getUserHeight(): number {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.height : 172;
  }

  /**
   * 从用户生日计算年龄
   */
  private getUserAge(): number {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    if (userInfo && userInfo.birthday) {
      const birthday = new Date(userInfo.birthday).getTime();
      const age = (Date.now() - birthday) / (3600 * 24 * 365.25 * 1000);
      return Math.round(age);
    }
    return 28;
  }

  /**
   * 将 HealthDataRecord 转换为按月分组的历史记录
   */
  private convertRecordsToGroups(records: import('../types/HealthDataRecordTypes').HealthDataRecord[]): MonthGroup[] {
    const groupMap = new Map<string, HealthHistoryItem[]>();
    const userHeight = this.getUserHeight();
    const userAge = this.getUserAge();

    for (const r of records) {
      const d = new Date(r.timestamp);
      const monthKey = `${d.getFullYear()}年${d.getMonth() + 1}月`;
      const dateStr = `${d.getMonth() + 1}月${d.getDate()}日`;
      const fullDateStr = `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`;

      const item: HealthHistoryItem = {
        id: r.id,
        date: dateStr,
        weight: r.weight,
        fullDate: fullDateStr,
        height: userHeight,
        age: userAge,
        bmi: r.bmi,
        bodyFat: r.bodyFatPercentage,
        fatMass: r.fatWeight,
        heartRate: r.heartRate,
        bloodPressureSystolic: r.bloodPressureSystolic,
        bloodPressureDiastolic: r.bloodPressureDiastolic,
        bloodGlucose: r.bloodSugar
      };

      if (!groupMap.has(monthKey)) {
        groupMap.set(monthKey, []);
      }
      groupMap.get(monthKey)!.push(item);
    }

    // 按月份倒序排列
    const groups: MonthGroup[] = [];
    const sortedKeys = Array.from(groupMap.keys()).sort().reverse();
    for (const key of sortedKeys) {
      groups.push({ month: key, items: groupMap.get(key)! });
    }
    return groups;
  }

  /**
   * 合并两个月份分组（避免重复记录）
   */
  private mergeGroups(a: MonthGroup[], b: MonthGroup[]): MonthGroup[] {
    const merged = new Map<string, HealthHistoryItem[]>();

    for (const group of a) {
      merged.set(group.month, [...group.items]);
    }
    for (const group of b) {
      const existing = merged.get(group.month) || [];
      const existingIds = new Set(existing.map(i => i.id));
      for (const item of group.items) {
        if (!existingIds.has(item.id)) {
          existing.push(item);
        }
      }
      merged.set(group.month, existing);
    }

    const result: MonthGroup[] = [];
    const sortedKeys = Array.from(merged.keys()).sort().reverse();
    for (const key of sortedKeys) {
      result.push({ month: key, items: merged.get(key)! });
    }
    return result;
  }

  /**
   * 获取可选月份列表
   */
  public getMonthOptions(): string[] {
    return this.historyGroups.map(group => group.month);
  }

  /**
   * 获取当前选中月份的数据
   */
  public getCurrentMonthData(): HealthHistoryItem[] {
    const group = this.historyGroups.find(g => g.month === this.selectedMonth);
    return group ? group.items : [];
  }

  /**
   * 切换月份选择器
   */
  public toggleMonthPicker(): void {
    this.showMonthPicker = !this.showMonthPicker;
  }

  /**
   * 选择月份
   */
  public selectMonth(month: string): void {
    this.selectedMonth = month;
    this.showMonthPicker = false;
  }
}

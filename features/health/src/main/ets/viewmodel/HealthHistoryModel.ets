/**
 * 健康历史记录 Model
 */
import { HealthHistoryItem, MonthGroup } from '../types/HealthHistoryTypes';
import { HEALTH_HISTORY_GROUPS } from '../mock/HealthHistoryMockData';
import { HealthDataService } from '../service/HealthDataService';
import { GlobalContext, I18nUtil, USE_MOCK_DATA, UserInfo } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

@ObservedV2
export class HealthHistoryModel {
  private static _instance: HealthHistoryModel;

  @Trace historyGroups: MonthGroup[] = [];
  @Trace selectedMonth: string = '';
  @Trace showMonthPicker: boolean = false;
  @Trace searchKeyword: string = '';
  @Trace isSearching: boolean = false;

  public static get instance() {
    if (!HealthHistoryModel._instance) {
      HealthHistoryModel._instance = new HealthHistoryModel();
    }
    return HealthHistoryModel._instance;
  }

  /**
   * 加载历史数据（同步，兼容旧调用）
   */
  public loadHistory(): void {
    if (USE_MOCK_DATA) {
      const records = HealthDataService.instance.loadRecords();
      const fromRecords = this.convertRecordsToGroups(records);
      const allGroups = this.mergeGroups(HEALTH_HISTORY_GROUPS, fromRecords);
      this.historyGroups = allGroups;
    } else {
      const records = HealthDataService.instance.loadRecords();
      this.historyGroups = this.convertRecordsToGroups(records);
    }
    if (this.historyGroups.length > 0 && !this.selectedMonth) {
      this.selectedMonth = this.historyGroups[0].month;
    }
  }

  /**
   * 从后端 API 加载历史数据（异步）
   */
  public async loadFromApi(): Promise<void> {
    const records = await HealthDataService.instance.loadFromApi(50);
    const fromRecords = this.convertRecordsToGroups(records);
    if (USE_MOCK_DATA) {
      this.historyGroups = this.mergeGroups(HEALTH_HISTORY_GROUPS, fromRecords);
    } else {
      this.historyGroups = fromRecords;
    }
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
      const monthKey = I18nUtil.formatYearMonth(d.getFullYear(), d.getMonth() + 1);
      const dateStr = I18nUtil.formatDate(d.getMonth() + 1, d.getDate());
      const fullDateStr = I18nUtil.formatFullDate(d.getFullYear(), d.getMonth() + 1, d.getDate());

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

  /**
   * 搜索/过滤历史记录
   */
  public search(keyword: string): void {
    this.searchKeyword = keyword.trim();
    this.isSearching = this.searchKeyword.length > 0;
  }

  /**
   * 清除搜索
   */
  public clearSearch(): void {
    this.searchKeyword = '';
    this.isSearching = false;
  }

  /**
   * 获取过滤后的当前月份数据
   */
  public getFilteredMonthData(): HealthHistoryItem[] {
    const data = this.getCurrentMonthData();
    if (!this.isSearching || this.searchKeyword.length === 0) {
      return data;
    }
    const keyword = this.searchKeyword;
    // 按日期或体重范围搜索
    return data.filter((item: HealthHistoryItem) => {
      // 日期匹配
      if (item.date.includes(keyword) || item.fullDate.includes(keyword)) {
        return true;
      }
      // 体重匹配（支持 "60" 或 "60-70" 范围格式）
      if (keyword.includes('-')) {
        const parts = keyword.split('-');
        const min = parseFloat(parts[0]);
        const max = parseFloat(parts[1]);
        if (!isNaN(min) && !isNaN(max) && item.weight > 0) {
          return item.weight >= min && item.weight <= max;
        }
      }
      const num = parseFloat(keyword);
      if (!isNaN(num) && item.weight > 0) {
        return Math.abs(item.weight - num) < 0.5;
      }
      return false;
    });
  }
}

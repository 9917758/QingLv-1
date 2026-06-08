/**
 * 健康数据管理服务
 * 负责健康数据记录的持久化、查询和聚合
 */
import { HealthDataRecord } from '../types/HealthDataRecordTypes';
import { GlobalContext, PreferenceUtil, USE_MOCK_DATA } from 'common';
import { getMockHealthRecords } from '../mock/HealthDataRecordMockData';

const HEALTH_RECORDS_KEY = 'health_data_records';
const MAX_RECORDS = 500; // 最多保留500条记录

@ObservedV2
export class HealthDataService {
  private static _instance: HealthDataService;
  private _records: HealthDataRecord[] = [];
  private _loaded: boolean = false;

  public static get instance(): HealthDataService {
    if (!HealthDataService._instance) {
      HealthDataService._instance = new HealthDataService();
    }
    return HealthDataService._instance;
  }

  /**
   * 加载所有历史记录
   */
  public loadRecords(): HealthDataRecord[] {
    if (this._loaded) {
      return this._records;
    }

    if (USE_MOCK_DATA) {
      this._records = getMockHealthRecords();
      this._loaded = true;
      return this._records;
    }

    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const raw = pref.get(HEALTH_RECORDS_KEY, '[]') as string;
      this._records = JSON.parse(raw) as HealthDataRecord[];
    } catch {
      this._records = [];
    }
    this._loaded = true;
    return this._records;
  }

  /**
   * 保存一条新记录
   */
  public saveRecord(record: HealthDataRecord): void {
    this._records.unshift(record); // 新记录在前
    // 超过上限时裁剪
    if (this._records.length > MAX_RECORDS) {
      this._records = this._records.slice(0, MAX_RECORDS);
    }
    this.persist();
  }

  /**
   * 从用户输入的健康指标值创建并保存一条记录
   */
  public saveFromInput(weight: number, bmiValue: number, bodyFatPercentage: number,
    fatWeight: number, bloodSugar: number, bloodPressureSystolic: number,
    bloodPressureDiastolic: number, heartRate: number,
    waistCircumference: number, hipCircumference: number): void {
    const record: HealthDataRecord = {
      id: `rec_${Date.now()}`,
      timestamp: Date.now(),
      weight: weight,
      bmi: bmiValue,
      bodyFatPercentage: bodyFatPercentage,
      fatWeight: fatWeight,
      bloodSugar: bloodSugar,
      bloodPressureSystolic: bloodPressureSystolic,
      bloodPressureDiastolic: bloodPressureDiastolic,
      heartRate: heartRate,
      waistCircumference: waistCircumference,
      hipCircumference: hipCircumference
    };
    this.saveRecord(record);
  }

  /**
   * 获取指定时间范围内的记录
   */
  public getRecordsByDateRange(startMs: number, endMs: number): HealthDataRecord[] {
    // 包含 endMs 当天的全部数据（到当天 23:59:59）
    const endOfDay = endMs + 24 * 60 * 60 * 1000 - 1;
    return this._records.filter(r => r.timestamp >= startMs && r.timestamp <= endOfDay);
  }

  /**
   * 获取最近 N 条记录
   */
  public getRecentRecords(count: number): HealthDataRecord[] {
    return this._records.slice(0, count);
  }

  /**
   * 获取所有记录（只读副本）
   */
  public getAllRecords(): HealthDataRecord[] {
    return this._records.slice();
  }

  /**
   * 获取记录总数
   */
  public getRecordCount(): number {
    return this._records.length;
  }

  /**
   * 持久化到 Preferences
   */
  private persist(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(HEALTH_RECORDS_KEY, JSON.stringify(this._records));
    } catch (err) {
      console.error('HealthDataService persist failed');
    }
  }
}

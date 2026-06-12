/**
 * 健康数据管理服务
 * 负责健康数据记录的持久化、查询和聚合
 * 支持两种模式：本地 Mock / 后端 API
 * 本地存储按用户ID隔离
 */
import { HealthDataRecord } from '../types/HealthDataRecordTypes';
import { GlobalContext, HttpUtil, AuthToken, PreferenceUtil, UserInfo, USE_MOCK_DATA } from 'common';
import type { ApiResponse, ApiRecordListResponse, ApiHealthRecord } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';
import { getMockHealthRecords } from '../mock/HealthDataRecordMockData';

const MAX_RECORDS = 500;

interface HealthRecordPayload {
  weight: number;
  bmi: number;
  body_fat_percentage: number;
  fat_weight: number;
  blood_sugar: number;
  blood_pressure_systolic: number;
  blood_pressure_diastolic: number;
  heart_rate: number;
  waist_circumference: number;
  hip_circumference: number;
  step_count: number;
  sleep_hours: number;
}

@ObservedV2
export class HealthDataService {
  private static _instance: HealthDataService;
  @Trace _records: HealthDataRecord[] = [];
  private _loaded: boolean = false;
  private _loadedUserId: string = '';

  public static get instance(): HealthDataService {
    if (!HealthDataService._instance) {
      HealthDataService._instance = new HealthDataService();
    }
    return HealthDataService._instance;
  }

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private getRecordsKey(): string {
    return `health_data_records_${HealthDataService.getUserId()}`;
  }

  /** 清除内存缓存（退出登录/切换用户时调用） */
  public clearCache(): void {
    this._records = [];
    this._loaded = false;
    this._loadedUserId = '';
  }

  /** 同步加载（兼容旧调用） */
  public loadRecords(): HealthDataRecord[] {
    const userId = HealthDataService.getUserId();
    if (this._loadedUserId.length > 0 && this._loadedUserId !== userId) {
      this.clearCache();
    }
    if (this._loaded) {
      return this._records;
    }
    if (USE_MOCK_DATA) {
      this._records = getMockHealthRecords();
      this._loaded = true;
      this._loadedUserId = userId;
      return this._records;
    }
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const raw = pref.get(this.getRecordsKey(), '[]') as string;
      this._records = JSON.parse(raw) as HealthDataRecord[];
    } catch {
      this._records = [];
    }
    this._loaded = true;
    this._loadedUserId = userId;
    return this._records;
  }

  /** 从后端 API 加载记录（异步） */
  public async loadFromApi(limit: number = 100): Promise<HealthDataRecord[]> {
    if (!AuthToken.isLoggedIn()) {
      this.loadRecords();
      return this._records;
    }
    const resp: ApiResponse<ApiRecordListResponse> = await HttpUtil.get<ApiRecordListResponse>(`/api/health/records?limit=${limit}`);
    if (resp.data) {
      this._records = resp.data.records.map((r: ApiHealthRecord) => this.fromApiRecord(r));
      this._loaded = true;
      this._loadedUserId = HealthDataService.getUserId();
    }
    return this._records;
  }

  /** 保存一条新记录（同步本地 + 异步 API） */
  public async saveRecord(record: HealthDataRecord): Promise<void> {
    this._records.unshift(record);
    if (this._records.length > MAX_RECORDS) {
      this._records = this._records.slice(0, MAX_RECORDS);
    }
    if (AuthToken.isLoggedIn()) {
      const resp = await HttpUtil.post<object>('/api/health/records', this.toApiPayload(record));
      if (resp.error.length > 0) {
        console.error(`[HealthDataService] sync failed: ${resp.error}`);
      }
    }
    this.persistLocal();
  }

  public saveFromInput(weight: number, bmiValue: number, bodyFatPercentage: number,
    fatWeight: number, bloodSugar: number, bloodPressureSystolic: number,
    bloodPressureDiastolic: number, heartRate: number,
    waistCircumference: number, hipCircumference: number,
    stepCount: number = 0, sleepHours: number = 0): void {
    const record: HealthDataRecord = {
      id: `rec_${Date.now()}`, timestamp: Date.now(),
      weight, bmi: bmiValue, bodyFatPercentage, fatWeight,
      bloodSugar, bloodPressureSystolic, bloodPressureDiastolic,
      heartRate, waistCircumference, hipCircumference,
      stepCount, sleepHours
    };
    this.saveRecord(record);
  }

  public getRecordsByDateRange(startMs: number, endMs: number): HealthDataRecord[] {
    const endOfDay = endMs + 24 * 60 * 60 * 1000 - 1;
    return this._records.filter(r => r.timestamp >= startMs && r.timestamp <= endOfDay);
  }

  public getRecentRecords(count: number): HealthDataRecord[] {
    return this._records.slice(0, count);
  }

  public getAllRecords(): HealthDataRecord[] {
    return this._records.slice();
  }

  public getRecordCount(): number {
    return this._records.length;
  }

  /** 批量导入记录到本地（不触发 API 同步，跳过重复日期） */
  public bulkImportLocal(records: HealthDataRecord[]): number {
    const existingDates = new Set(this._records.map((r: HealthDataRecord) => {
      const d = new Date(r.timestamp);
      return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
    }));

    let count = 0;
    for (const record of records) {
      const d = new Date(record.timestamp);
      const dateStr = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
      if (!existingDates.has(dateStr)) {
        this._records.unshift(record);
        existingDates.add(dateStr);
        count++;
      }
    }

    if (count > 0) {
      this._records.sort((a: HealthDataRecord, b: HealthDataRecord) => b.timestamp - a.timestamp);
      if (this._records.length > MAX_RECORDS) {
        this._records = this._records.slice(0, MAX_RECORDS);
      }
      this.persistLocal();
    }
    return count;
  }

  private persistLocal(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this.getRecordsKey(), JSON.stringify(this._records));
    } catch {
      // ignore
    }
  }

  private fromApiRecord(r: ApiHealthRecord): HealthDataRecord {
    return {
      id: `api_${r.id}`, timestamp: new Date(r.timestamp).getTime(),
      weight: r.weight, bmi: r.bmi, bodyFatPercentage: r.body_fat_percentage,
      fatWeight: r.fat_weight, bloodSugar: r.blood_sugar,
      bloodPressureSystolic: r.blood_pressure_systolic,
      bloodPressureDiastolic: r.blood_pressure_diastolic,
      heartRate: r.heart_rate, waistCircumference: r.waist_circumference,
      hipCircumference: r.hip_circumference,
      stepCount: r.step_count || 0, sleepHours: r.sleep_hours || 0
    };
  }

  private toApiPayload(record: HealthDataRecord): HealthRecordPayload {
    return {
      weight: record.weight, bmi: record.bmi,
      body_fat_percentage: record.bodyFatPercentage, fat_weight: record.fatWeight,
      blood_sugar: record.bloodSugar,
      blood_pressure_systolic: record.bloodPressureSystolic,
      blood_pressure_diastolic: record.bloodPressureDiastolic,
      heart_rate: record.heartRate,
      waist_circumference: record.waistCircumference,
      hip_circumference: record.hipCircumference,
      step_count: record.stepCount || 0,
      sleep_hours: record.sleepHours || 0
    };
  }
}

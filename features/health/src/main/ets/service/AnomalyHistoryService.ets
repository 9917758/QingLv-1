/**
 * 健康异常事件服务
 * 基于实际健康数据检测异常，记录异常历史
 * 本地存储按用户ID隔离
 */
import { GlobalContext, PreferenceUtil, UserInfo } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';
import { HealthDataInputModel } from '../viewmodel/HealthDataInputModel';

// 单条异常事件
export interface AnomalyEvent {
  id: string;
  type: string;          // 'heartrate' | 'bloodpressure' | 'bloodsugar' | 'bmi'
  icon: string;
  title: string;
  detail: string;
  value: string;
  severity: string;      // 'warning' | 'danger' | 'info'
  timestamp: number;
  dateStr: string;
  timeStr: string;
}

const ANOMALY_HISTORY_KEY_PREFIX = 'health_anomaly_history_';

@ObservedV2
export class AnomalyHistoryService {
  private static _instance: AnomalyHistoryService;
  @Trace events: AnomalyEvent[] = [];
  @Trace totalCount: number = 0;
  private _loadedUserId: string = '';

  public static get instance(): AnomalyHistoryService {
    if (!AnomalyHistoryService._instance) {
      AnomalyHistoryService._instance = new AnomalyHistoryService();
    }
    return AnomalyHistoryService._instance;
  }

  private static getUserId(): string {
    const userInfo = PersistenceV2.connect(UserInfo, () => new UserInfo());
    return userInfo ? userInfo.id : 'anonymous';
  }

  private getHistoryKey(): string {
    return `${ANOMALY_HISTORY_KEY_PREFIX}${AnomalyHistoryService.getUserId()}`;
  }

  /** 清除内存缓存 */
  public clearCache(): void {
    this.events = [];
    this.totalCount = 0;
    this._loadedUserId = '';
  }

  /** 用户切换时自动清除缓存 */
  private checkUserSwitch(): void {
    const userId = AnomalyHistoryService.getUserId();
    if (this._loadedUserId.length > 0 && this._loadedUserId !== userId) {
      this.clearCache();
    }
    this._loadedUserId = userId;
  }

  /** 加载历史异常记录 */
  public loadHistory(): void {
    this.checkUserSwitch();
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const raw = pref.get(this.getHistoryKey(), '[]') as string;
      this.events = JSON.parse(raw) as AnomalyEvent[];
      this.totalCount = this.events.length;
    } catch {
      this.events = [];
      this.totalCount = 0;
    }
  }

  /** 基于实际健康数据检测异常并记录 */
  public generate(inputVM: HealthDataInputModel): void {
    this.loadHistory();
    const now = new Date();
    const today = now.toDateString();
    const newEvents: AnomalyEvent[] = [];

    // 检查今日是否已记录过同类异常（避免重复）
    const todayEvents = this.events.filter(e =>
      new Date(e.timestamp).toDateString() === today
    );
    const todayTypes = new Set(todayEvents.map(e => e.type));

    // 心率异常检测
    if (inputVM.heartRate > 0 && !todayTypes.has('heartrate')) {
      if (inputVM.heartRate > 100) {
        newEvents.push(this.createEvent(
          'heartrate', '💓', '心率偏高',
          `当前心率 ${inputVM.heartRate} 次/分，超过正常范围（60-100）`,
          `${inputVM.heartRate}次/分`,
          inputVM.heartRate > 120 ? 'danger' : 'warning'
        ));
      } else if (inputVM.heartRate < 50) {
        newEvents.push(this.createEvent(
          'heartrate', '💓', '心率偏低',
          `当前心率 ${inputVM.heartRate} 次/分，低于正常范围（60-100）`,
          `${inputVM.heartRate}次/分`,
          'warning'
        ));
      }
    }

    // 血压异常检测
    if (inputVM.bloodPressureSystolic > 0 && !todayTypes.has('bloodpressure')) {
      const sys = inputVM.bloodPressureSystolic;
      const dia = inputVM.bloodPressureDiastolic;
      if (sys >= 140 || dia >= 90) {
        newEvents.push(this.createEvent(
          'bloodpressure', '❤️', '血压偏高',
          `当前血压 ${sys}/${dia} mmHg，建议关注饮食和运动`,
          `${sys}/${dia}mmHg`,
          sys >= 160 || dia >= 100 ? 'danger' : 'warning'
        ));
      } else if (sys < 90 || dia < 60) {
        newEvents.push(this.createEvent(
          'bloodpressure', '❤️', '血压偏低',
          `当前血压 ${sys}/${dia} mmHg，注意休息和营养`,
          `${sys}/${dia}mmHg`,
          'warning'
        ));
      }
    }

    // 血糖异常检测
    if (inputVM.bloodSugar > 0 && !todayTypes.has('bloodsugar')) {
      if (inputVM.bloodSugar > 7.0) {
        newEvents.push(this.createEvent(
          'bloodsugar', '🩸', '血糖偏高',
          `当前血糖 ${inputVM.bloodSugar} mmol/L，建议控制饮食`,
          `${inputVM.bloodSugar}mmol/L`,
          inputVM.bloodSugar > 11.1 ? 'danger' : 'warning'
        ));
      } else if (inputVM.bloodSugar < 3.9) {
        newEvents.push(this.createEvent(
          'bloodsugar', '🩸', '血糖偏低',
          `当前血糖 ${inputVM.bloodSugar} mmol/L，注意补充糖分`,
          `${inputVM.bloodSugar}mmol/L`,
          'warning'
        ));
      }
    }

    // BMI 异常检测
    if (inputVM.bmiValue > 0 && !todayTypes.has('bmi')) {
      if (inputVM.bmiValue >= 28) {
        newEvents.push(this.createEvent(
          'bmi', '⚖️', '肥胖',
          `BMI 为 ${inputVM.bmiValue}，建议增加运动量`,
          `${inputVM.bmiValue}`,
          'danger'
        ));
      } else if (inputVM.bmiValue >= 24) {
        newEvents.push(this.createEvent(
          'bmi', '⚖️', '超重',
          `BMI 为 ${inputVM.bmiValue}，建议适当运动`,
          `${inputVM.bmiValue}`,
          'warning'
        ));
      } else if (inputVM.bmiValue < 18.5) {
        newEvents.push(this.createEvent(
          'bmi', '⚖️', '偏瘦',
          `BMI 为 ${inputVM.bmiValue}，建议加强营养`,
          `${inputVM.bmiValue}`,
          'warning'
        ));
      }
    }

    // 合并新事件并持久化
    if (newEvents.length > 0) {
      this.events = [...newEvents, ...this.events].slice(0, 100);
      this.totalCount = this.events.length;
      this.persistHistory();
    }
  }

  /** 创建异常事件对象 */
  private createEvent(
    type: string, icon: string, title: string,
    detail: string, value: string, severity: string
  ): AnomalyEvent {
    const now = new Date();
    return {
      id: `anomaly_${now.getTime()}_${type}`,
      type, icon, title, detail, value, severity,
      timestamp: now.getTime(),
      dateStr: `${now.getMonth() + 1}月${now.getDate()}日`,
      timeStr: `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
    };
  }

  /** 记录单条异常事件（供外部调用） */
  public record(type: string, icon: string, title: string, detail: string, value: string, severity: string): void {
    this.loadHistory();
    const event = this.createEvent(type, icon, title, detail, value, severity);
    this.events = [event, ...this.events].slice(0, 100);
    this.totalCount = this.events.length;
    this.persistHistory();
  }

  /** 获取指定类型的事件数量 */
  public getCountByType(type: string): number {
    return this.events.filter(e => e.type === type).length;
  }

  /** 获取本周异常事件数 */
  public getThisWeekCount(): number {
    const now = new Date();
    const weekAgo = now.getTime() - 7 * 24 * 60 * 60 * 1000;
    return this.events.filter(e => e.timestamp >= weekAgo).length;
  }

  /** 持久化异常历史 */
  private persistHistory(): void {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(this.getHistoryKey(), JSON.stringify(this.events));
    } catch {
      // ignore
    }
  }
}

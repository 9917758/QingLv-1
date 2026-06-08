/**
 * 健康异常事件历史服务
 * 记录所有触发异常提醒的事件，形成健康事件时间线
 */

export interface AnomalyEvent {
  id: string;
  type: string;
  icon: string;
  title: string;
  detail: string;
  value: string;
  severity: string;
  timestamp: number;
  dateStr: string;
  timeStr: string;
}

@ObservedV2
export class AnomalyHistoryService {
  private static _instance: AnomalyHistoryService;
  @Trace events: AnomalyEvent[] = [];

  public static get instance(): AnomalyHistoryService {
    if (!AnomalyHistoryService._instance) {
      AnomalyHistoryService._instance = new AnomalyHistoryService();
    }
    return AnomalyHistoryService._instance;
  }

  /**
   * 记录异常事件
   */
  public record(type: string, icon: string, title: string, detail: string, value: string, severity: string): void {
    const now = new Date();
    const event: AnomalyEvent = {
      id: `anomaly_${now.getTime()}`,
      type,
      icon,
      title,
      detail,
      value,
      severity,
      timestamp: now.getTime(),
      dateStr: `${now.getMonth()+1}月${now.getDate()}日`,
      timeStr: `${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}`
    };
    this.events.unshift(event);
    if (this.events.length > 50) {
      this.events = this.events.slice(0, 50);
    }
  }

  /**
   * 生成 Mock 异常历史数据
   */
  public generateMock(): void {
    const now = new Date();
    this.events = [];
    const mockEvents: AnomalyEvent[] = [];

    for (let i = 0; i < 15; i++) {
      const d = new Date(now);
      d.setDate(d.getDate() - Math.floor(i / 2));
      d.setHours(8 + Math.floor(Math.random() * 12), Math.floor(Math.random() * 60));
      const types = ['heartrate', 'bloodpressure', 'bloodsugar', 'bmi'];
      const type = types[i % 4];
      let event: AnomalyEvent;

      if (type === 'heartrate') {
        const hr = 100 + Math.floor(Math.random() * 20);
        event = {
          id: `mock_anomaly_${i}`, type, icon: '💓',
          title: '心率偏高', detail: `静息心率 ${hr} 次/分，超过正常范围（60-100次/分）`,
          value: `${hr}次/分`, severity: hr > 110 ? 'warning' : 'info',
          timestamp: d.getTime(),
          dateStr: `${d.getMonth()+1}月${d.getDate()}日`,
          timeStr: `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`
        };
      } else if (type === 'bloodpressure') {
        const sys = 140 + Math.floor(Math.random() * 20);
        event = {
          id: `mock_anomaly_${i}`, type, icon: '❤️',
          title: '血压偏高', detail: `收缩压 ${sys} mmHg，超过正常范围（<140mmHg）`,
          value: `${sys}/90`, severity: sys > 150 ? 'warning' : 'info',
          timestamp: d.getTime(),
          dateStr: `${d.getMonth()+1}月${d.getDate()}日`,
          timeStr: `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`
        };
      } else if (type === 'bloodsugar') {
        const bs = (7.0 + Math.random() * 2).toFixed(1);
        event = {
          id: `mock_anomaly_${i}`, type, icon: '🩸',
          title: '血糖偏高', detail: `血糖 ${bs} mmol/L，超过正常范围（3.9-7.8mmol/L）`,
          value: `${bs}mmol/L`, severity: Number(bs) > 8.0 ? 'warning' : 'info',
          timestamp: d.getTime(),
          dateStr: `${d.getMonth()+1}月${d.getDate()}日`,
          timeStr: `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`
        };
      } else {
        const bmi = (25 + Math.random() * 3).toFixed(1);
        event = {
          id: `mock_anomaly_${i}`, type, icon: '⚖️',
          title: 'BMI 偏高', detail: `BMI ${bmi}，属于偏胖范围（25-30）`,
          value: `${bmi}`, severity: 'info',
          timestamp: d.getTime(),
          dateStr: `${d.getMonth()+1}月${d.getDate()}日`,
          timeStr: `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`
        };
      }
      mockEvents.push(event);
    }

    this.events = mockEvents.sort((a, b) => b.timestamp - a.timestamp);
  }

  /**
   * 获取指定类型的事件数量
   */
  public getCountByType(type: string): number {
    return this.events.filter(e => e.type === type).length;
  }

  /**
   * 获取本周事件数量
   */
  public getThisWeekCount(): number {
    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    weekStart.setHours(0, 0, 0, 0);
    return this.events.filter(e => e.timestamp >= weekStart.getTime()).length;
  }
}

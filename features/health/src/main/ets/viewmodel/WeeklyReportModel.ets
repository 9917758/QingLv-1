/**
 * 周度报告 Model
 */
import { WeeklyReportData, ChartDataPoint } from '../types/WeeklyReportTypes';
import { WEEKLY_REPORT_DATA } from '../mock/WeeklyReportMockData';
import { HealthDataService } from '../service/HealthDataService';

@ObservedV2
export class WeeklyReportModel {
  private static _instance: WeeklyReportModel;

  @Trace reportData: WeeklyReportData = WEEKLY_REPORT_DATA;
  @Trace selectedDateIndex: number = 0;

  // 日期选项列表（基于当前日期动态生成最近5周）
  dateOptions: string[] = WeeklyReportModel.generateWeekOptions();

  public static get instance() {
    if (!WeeklyReportModel._instance) {
      WeeklyReportModel._instance = new WeeklyReportModel();
    }
    return WeeklyReportModel._instance;
  }

  /**
   * 动态生成最近5周的日期选项
   */
  private static generateWeekOptions(): string[] {
    const options: string[] = [];
    const now = new Date();
    for (let w = 0; w < 5; w++) {
      const endDate = new Date(now);
      endDate.setDate(endDate.getDate() - w * 7);
      const startDate = new Date(endDate);
      startDate.setDate(startDate.getDate() - 6);
      const startMonth = startDate.getMonth() + 1;
      const startDay = startDate.getDate();
      const endMonth = endDate.getMonth() + 1;
      const endDay = endDate.getDate();
      const startStr = `${startDate.getFullYear()}年${startMonth}月${startDay}日`;
      const endStr = startMonth === endMonth ?
        `${endMonth}月${endDay}日` :
        `${endMonth}月${endDay}日`;
      options.push(`${startStr} - ${endStr}`);
    }
    return options;
  }

  /**
   * 选择日期并从历史数据生成报告
   */
  public selectDate(index: number): void {
    this.selectedDateIndex = index;
    this.reportData = this.buildReportFromHistory(index);
  }

  /**
   * 从健康数据历史记录中聚合周度报告
   */
  private buildReportFromHistory(weekIndex: number): WeeklyReportData {
    const now = new Date();
    const endDate = new Date(now);
    endDate.setDate(endDate.getDate() - weekIndex * 7);
    const startDate = new Date(endDate);
    startDate.setDate(startDate.getDate() - 6);

    const records = HealthDataService.instance.getRecordsByDateRange(startDate.getTime(), endDate.getTime());

    if (records.length === 0) {
      const data: WeeklyReportData = {
        startDate: `${startDate.getFullYear()}年${startDate.getMonth() + 1}月${startDate.getDate()}日`,
        endDate: `${endDate.getMonth() + 1}月${endDate.getDate()}日`,
        dateRange: this.dateOptions[weekIndex],
        weightTrend: WEEKLY_REPORT_DATA.weightTrend,
        bodyFatTrend: WEEKLY_REPORT_DATA.bodyFatTrend,
        bloodPressure: WEEKLY_REPORT_DATA.bloodPressure,
        heartRate: WEEKLY_REPORT_DATA.heartRate
      };
      return data;
    }

    // 聚合数据
    const weights = records.map(r => r.weight / 2); // 斤转kg
    const bodyFats = records.map(r => r.bodyFatPercentage);
    const systolics = records.map(r => r.bloodPressureSystolic);
    const diastolics = records.map(r => r.bloodPressureDiastolic);
    const heartRates = records.map(r => r.heartRate);

    const weightChange = weights.length >= 2 ?
      Math.round((weights[weights.length - 1] - weights[0]) * 10) / 10 : 0;
    const bodyFatChange = bodyFats.length >= 2 ?
      Math.round((bodyFats[bodyFats.length - 1] - bodyFats[0]) * 10) / 10 : 0;

    const weightChartData: ChartDataPoint[] = records.map(r => {
      const d = new Date(r.timestamp);
      const point: ChartDataPoint = { date: `${d.getMonth() + 1}/${d.getDate()}`, value: Math.round(r.weight / 2) };
      return point;
    });
    const bodyFatChartData: ChartDataPoint[] = records.map(r => {
      const d = new Date(r.timestamp);
      const point: ChartDataPoint = { date: `${d.getMonth() + 1}/${d.getDate()}`, value: r.bodyFatPercentage };
      return point;
    });

    const startStr = `${startDate.getFullYear()}年${startDate.getMonth() + 1}月${startDate.getDate()}日`;
    const endStr = `${endDate.getMonth() + 1}月${endDate.getDate()}日`;

    const data: WeeklyReportData = {
      startDate: startStr,
      endDate: endStr,
      dateRange: this.dateOptions[weekIndex],
      weightTrend: {
        maxWeight: Math.round(Math.max(...weights)),
        minWeight: Math.round(Math.min(...weights)),
        change: weightChange,
        chartData: weightChartData
      },
      bodyFatTrend: {
        maxBodyFat: Math.round(Math.max(...bodyFats) * 10) / 10,
        minBodyFat: Math.round(Math.min(...bodyFats) * 10) / 10,
        change: bodyFatChange,
        chartData: bodyFatChartData
      },
      bloodPressure: {
        systolic: Math.round(systolics.reduce((a, b) => a + b, 0) / systolics.length),
        diastolic: Math.round(diastolics.reduce((a, b) => a + b, 0) / diastolics.length),
        pulse: 0
      },
      heartRate: {
        maxHeartRate: Math.max(...heartRates),
        minHeartRate: Math.min(...heartRates),
        restingHeartRate: Math.round(heartRates.reduce((a, b) => a + b, 0) / heartRates.length),
        averageHeartRate: Math.round(heartRates.reduce((a, b) => a + b, 0) / heartRates.length)
      }
    };
    return data;
  }

  /**
   * 生成报告（从历史数据重新聚合）
   */
  public generateReport(): void {
    this.reportData = this.buildReportFromHistory(this.selectedDateIndex);
  }

  /**
   * 获取体重变化文字
   */
  public getWeightChangeText(): string {
    const change = this.reportData.weightTrend.change;
    if (change > 0) {
      return `+${change.toFixed(1)}`;
    } else if (change < 0) {
      return change.toFixed(1);
    }
    return '0';
  }

  /**
   * 获取体脂率变化文字
   */
  public getBodyFatChangeText(): string {
    const change = this.reportData.bodyFatTrend.change;
    if (change > 0) {
      return `+${change.toFixed(1)}`;
    } else if (change < 0) {
      return change.toFixed(1);
    }
    return '0';
  }
}

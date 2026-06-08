/**
 * 月度报告 Model
 */
import { MonthlyReportData, ChartDataPoint } from '../types/MonthlyReportTypes';
import { MONTHLY_REPORT_DATA } from '../mock/MonthlyReportMockData';
import { HealthDataService } from '../service/HealthDataService';

@ObservedV2
export class MonthlyReportModel {
  private static _instance: MonthlyReportModel;
  @Trace reportData: MonthlyReportData = MONTHLY_REPORT_DATA;
  @Trace selectedDateIndex: number = 0;
  // 月份选项列表（基于当前日期动态生成最近5个月）
  dateOptions: string[] = MonthlyReportModel.generateMonthOptions();

  public static get instance() {
    if (!MonthlyReportModel._instance) {
      MonthlyReportModel._instance = new MonthlyReportModel();
    }
    return MonthlyReportModel._instance;
  }

  /**
   * 动态生成最近5个月的选项
   */
  private static generateMonthOptions(): string[] {
    const options: string[] = [];
    const now = new Date();
    for (let m = 0; m < 5; m++) {
      const date = new Date(now.getFullYear(), now.getMonth() - m, 1);
      options.push(`${date.getFullYear()}年${date.getMonth() + 1}月`);
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
   * 从健康数据历史记录中聚合月度报告
   */
  private buildReportFromHistory(monthIndex: number): MonthlyReportData {
    const now = new Date();
    const targetYear = now.getFullYear();
    const targetMonth = now.getMonth() - monthIndex;
    const startDate = new Date(targetYear, targetMonth, 1);
    const endDate = new Date(targetYear, targetMonth + 1, 0); // 月末

    const records = HealthDataService.instance.getRecordsByDateRange(startDate.getTime(), endDate.getTime());

    const monthStr = `${startDate.getFullYear()}年${startDate.getMonth() + 1}月`;

    if (records.length === 0) {
      const data: MonthlyReportData = {
        startDate: `${startDate.getFullYear()}年${startDate.getMonth() + 1}月1日`,
        endDate: `${startDate.getMonth() + 1}月${endDate.getDate()}日`,
        dateRange: monthStr,
        weightTrend: MONTHLY_REPORT_DATA.weightTrend,
        bodyFatTrend: MONTHLY_REPORT_DATA.bodyFatTrend,
        bloodPressure: MONTHLY_REPORT_DATA.bloodPressure,
        heartRate: MONTHLY_REPORT_DATA.heartRate
      };
      return data;
    }

    const weights = records.map(r => r.weight / 2);
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

    const data: MonthlyReportData = {
      startDate: `${startDate.getFullYear()}年${startDate.getMonth() + 1}月1日`,
      endDate: `${startDate.getMonth() + 1}月${endDate.getDate()}日`,
      dateRange: monthStr,
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
   * 生成报告
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

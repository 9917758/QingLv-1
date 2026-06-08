/**
 * 月度报告 Model
 */
import { MonthlyReportData } from '../types/MonthlyReportTypes';
import { MONTHLY_REPORT_DATA } from '../mock/MonthlyReportMockData';
import { HealthDataService } from '../service/HealthDataService';
import { aggregateRecords, getChangeText } from '../util/ReportAggregator';

@ObservedV2
export class MonthlyReportModel {
  private static _instance: MonthlyReportModel;
  @Trace reportData: MonthlyReportData = MONTHLY_REPORT_DATA;
  @Trace selectedDateIndex: number = 0;
  dateOptions: string[] = MonthlyReportModel.generateMonthOptions();

  public static get instance() {
    if (!MonthlyReportModel._instance) {
      MonthlyReportModel._instance = new MonthlyReportModel();
    }
    return MonthlyReportModel._instance;
  }

  private static generateMonthOptions(): string[] {
    const options: string[] = [];
    const now = new Date();
    for (let m = 0; m < 5; m++) {
      const date = new Date(now.getFullYear(), now.getMonth() - m, 1);
      options.push(`${date.getFullYear()}年${date.getMonth() + 1}月`);
    }
    return options;
  }

  public selectDate(index: number): void {
    this.selectedDateIndex = index;
    this.reportData = this.buildReportFromHistory(index);
  }

  private buildReportFromHistory(monthIndex: number): MonthlyReportData {
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth() - monthIndex, 1);
    const endDate = new Date(now.getFullYear(), now.getMonth() - monthIndex + 1, 0);

    const records = HealthDataService.instance.getRecordsByDateRange(startDate.getTime(), endDate.getTime());
    const monthStr = `${startDate.getFullYear()}年${startDate.getMonth() + 1}月`;
    const startStr = `${startDate.getFullYear()}年${startDate.getMonth() + 1}月1日`;
    const endStr = `${startDate.getMonth() + 1}月${endDate.getDate()}日`;

    if (records.length === 0) {
      return {
        startDate: startStr, endDate: endStr, dateRange: monthStr,
        weightTrend: MONTHLY_REPORT_DATA.weightTrend,
        bodyFatTrend: MONTHLY_REPORT_DATA.bodyFatTrend,
        bloodPressure: MONTHLY_REPORT_DATA.bloodPressure,
        heartRate: MONTHLY_REPORT_DATA.heartRate
      };
    }

    const agg = aggregateRecords(records);
    return {
      startDate: startStr, endDate: endStr, dateRange: monthStr,
      weightTrend: { maxWeight: agg.maxWeight, minWeight: agg.minWeight, change: agg.weightChange, chartData: agg.weightChartData },
      bodyFatTrend: { maxBodyFat: agg.maxBodyFat, minBodyFat: agg.minBodyFat, change: agg.bodyFatChange, chartData: agg.bodyFatChartData },
      bloodPressure: { systolic: agg.avgSystolic, diastolic: agg.avgDiastolic, pulse: 0 },
      heartRate: { maxHeartRate: agg.maxHeartRate, minHeartRate: agg.minHeartRate, restingHeartRate: agg.avgHeartRate, averageHeartRate: agg.avgHeartRate }
    };
  }

  public generateReport(): void {
    this.reportData = this.buildReportFromHistory(this.selectedDateIndex);
  }

  public getWeightChangeText(): string {
    return getChangeText(this.reportData.weightTrend.change);
  }

  public getBodyFatChangeText(): string {
    return getChangeText(this.reportData.bodyFatTrend.change);
  }
}

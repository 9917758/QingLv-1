/**
 * 周度报告 Model
 */
import { WeeklyReportData } from '../types/WeeklyReportTypes';
import { WEEKLY_REPORT_DATA } from '../mock/WeeklyReportMockData';
import { HealthDataService } from '../service/HealthDataService';
import { aggregateRecords, getChangeText } from '../util/ReportAggregator';

@ObservedV2
export class WeeklyReportModel {
  private static _instance: WeeklyReportModel;

  @Trace reportData: WeeklyReportData = WEEKLY_REPORT_DATA;
  @Trace selectedDateIndex: number = 0;

  dateOptions: string[] = WeeklyReportModel.generateWeekOptions();

  public static get instance() {
    if (!WeeklyReportModel._instance) {
      WeeklyReportModel._instance = new WeeklyReportModel();
    }
    return WeeklyReportModel._instance;
  }

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
        `${endDay}日` :
        `${endMonth}月${endDay}日`;
      options.push(`${startStr} - ${endStr}`);
    }
    return options;
  }

  public selectDate(index: number): void {
    this.selectedDateIndex = index;
    this.reportData = this.buildReportFromHistory(index);
  }

  private buildReportFromHistory(weekIndex: number): WeeklyReportData {
    const now = new Date();
    const endDate = new Date(now);
    endDate.setDate(endDate.getDate() - weekIndex * 7);
    const startDate = new Date(endDate);
    startDate.setDate(startDate.getDate() - 6);

    const records = HealthDataService.instance.getRecordsByDateRange(startDate.getTime(), endDate.getTime());
    const startStr = `${startDate.getFullYear()}年${startDate.getMonth() + 1}月${startDate.getDate()}日`;
    const endStr = `${endDate.getMonth() + 1}月${endDate.getDate()}日`;

    if (records.length === 0) {
      return {
        startDate: startStr, endDate: endStr, dateRange: this.dateOptions[weekIndex],
        weightTrend: WEEKLY_REPORT_DATA.weightTrend,
        bodyFatTrend: WEEKLY_REPORT_DATA.bodyFatTrend,
        bloodPressure: WEEKLY_REPORT_DATA.bloodPressure,
        heartRate: WEEKLY_REPORT_DATA.heartRate
      };
    }

    const agg = aggregateRecords(records);
    return {
      startDate: startStr, endDate: endStr, dateRange: this.dateOptions[weekIndex],
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

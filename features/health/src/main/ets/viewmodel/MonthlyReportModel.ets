/**
 * 月度报告 Model
 */
import { MonthlyReportData } from '../types/MonthlyReportTypes';
import { MONTHLY_REPORT_DATA } from '../mock/MonthlyReportMockData';
import { HealthDataService } from '../service/HealthDataService';
import { aggregateRecords, getChangeText, comparePeriods, formatDelta } from '../util/ReportAggregator';
import type { PeriodComparison } from '../types/MonthlyReportTypes';
import { I18nUtil } from 'common';

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
      options.push(I18nUtil.formatYearMonth(date.getFullYear(), date.getMonth() + 1));
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
    const monthStr = I18nUtil.formatYearMonth(startDate.getFullYear(), startDate.getMonth() + 1);
    const startStr = I18nUtil.formatFullDate(startDate.getFullYear(), startDate.getMonth() + 1, 1);
    const endStr = I18nUtil.formatDate(startDate.getMonth() + 1, endDate.getDate());

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

    // 计算上一月对比
    let comparison: PeriodComparison | undefined;
    const prevStartDate = new Date(now.getFullYear(), now.getMonth() - monthIndex - 1, 1);
    const prevEndDate = new Date(now.getFullYear(), now.getMonth() - monthIndex, 0);
    const prevRecords = HealthDataService.instance.getRecordsByDateRange(prevStartDate.getTime(), prevEndDate.getTime());
    if (prevRecords.length > 0) {
      const prevAgg = aggregateRecords(prevRecords);
      const deltas = comparePeriods(agg, prevAgg);
      comparison = {
        weightDelta: deltas.weightDelta,
        bodyFatDelta: deltas.bodyFatDelta,
        systolicDelta: deltas.systolicDelta,
        diastolicDelta: deltas.diastolicDelta,
        heartRateDelta: deltas.heartRateDelta,
        previousLabel: I18nUtil.t('report.previous_month')
      };
    }

    return {
      startDate: startStr, endDate: endStr, dateRange: monthStr,
      weightTrend: { maxWeight: agg.maxWeight, minWeight: agg.minWeight, change: agg.weightChange, chartData: agg.weightChartData },
      bodyFatTrend: { maxBodyFat: agg.maxBodyFat, minBodyFat: agg.minBodyFat, change: agg.bodyFatChange, chartData: agg.bodyFatChartData },
      bloodPressure: { systolic: agg.avgSystolic, diastolic: agg.avgDiastolic, pulse: 0 },
      heartRate: { maxHeartRate: agg.maxHeartRate, minHeartRate: agg.minHeartRate, restingHeartRate: agg.avgHeartRate, averageHeartRate: agg.avgHeartRate },
      comparison
    };
  }

  public generateReport(): void {
    this.reportData = this.buildReportFromHistory(this.selectedDateIndex);
  }

  /** 从后端 API 加载数据后重新生成报告 */
  public async loadFromApi(): Promise<void> {
    await HealthDataService.instance.loadFromApi(200);
    this.generateReport();
  }

  public getWeightChangeText(): string {
    return getChangeText(this.reportData.weightTrend.change);
  }

  public getBodyFatChangeText(): string {
    return getChangeText(this.reportData.bodyFatTrend.change);
  }

  public getComparisonWeightText(): string {
    if (!this.reportData.comparison) return '';
    return formatDelta(this.reportData.comparison.weightDelta, '公斤');
  }

  public getComparisonBodyFatText(): string {
    if (!this.reportData.comparison) return '';
    return formatDelta(this.reportData.comparison.bodyFatDelta, '%');
  }
}

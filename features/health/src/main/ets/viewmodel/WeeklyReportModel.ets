/**
 * 周度报告 Model
 */
import { WeeklyReportData } from '../types/WeeklyReportTypes';
import { WEEKLY_REPORT_DATA } from '../mock/WeeklyReportMockData';
import { HealthDataService } from '../service/HealthDataService';
import { aggregateRecords, getChangeText, comparePeriods, formatDelta } from '../util/ReportAggregator';
import type { PeriodComparison } from '../types/WeeklyReportTypes';
import { I18nUtil } from 'common';

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
      const startStr = I18nUtil.formatFullDate(startDate.getFullYear(), startMonth, startDay);
      const endStr = startMonth === endMonth ?
        `${endDay}${I18nUtil.t('date.day_suffix')}` :
        I18nUtil.formatDate(endMonth, endDay);
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
    const startStr = I18nUtil.formatFullDate(startDate.getFullYear(), startDate.getMonth() + 1, startDate.getDate());
    const endStr = I18nUtil.formatDate(endDate.getMonth() + 1, endDate.getDate());

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

    // 计算上一周期对比
    let comparison: PeriodComparison | undefined;
    const prevEnd = new Date(startDate);
    prevEnd.setDate(prevEnd.getDate() - 1);
    const prevStart = new Date(prevEnd);
    prevStart.setDate(prevStart.getDate() - 6);
    const prevRecords = HealthDataService.instance.getRecordsByDateRange(prevStart.getTime(), prevEnd.getTime());
    if (prevRecords.length > 0) {
      const prevAgg = aggregateRecords(prevRecords);
      const deltas = comparePeriods(agg, prevAgg);
      comparison = {
        weightDelta: deltas.weightDelta,
        bodyFatDelta: deltas.bodyFatDelta,
        systolicDelta: deltas.systolicDelta,
        diastolicDelta: deltas.diastolicDelta,
        heartRateDelta: deltas.heartRateDelta,
        previousLabel: I18nUtil.t('report.previous_week')
      };
    }

    return {
      startDate: startStr, endDate: endStr, dateRange: this.dateOptions[weekIndex],
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
    await HealthDataService.instance.loadFromApi(100);
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

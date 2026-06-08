/**
 * 报告数据聚合工具
 * 周报和月报共用的聚合逻辑，避免重复代码
 */
import { HealthDataRecord } from '../types/HealthDataRecordTypes';
import { ChartDataPoint } from '../types/WeeklyReportTypes';

/** 聚合结果（周报/月报共用结构） */
export interface AggregatedReport {
  maxWeight: number;
  minWeight: number;
  weightChange: number;
  weightChartData: ChartDataPoint[];
  maxBodyFat: number;
  minBodyFat: number;
  bodyFatChange: number;
  bodyFatChartData: ChartDataPoint[];
  avgSystolic: number;
  avgDiastolic: number;
  maxHeartRate: number;
  minHeartRate: number;
  avgHeartRate: number;
}

/**
 * 从健康记录中聚合报告数据
 */
export function aggregateRecords(records: HealthDataRecord[]): AggregatedReport {
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

  return {
    maxWeight: Math.round(Math.max(...weights)),
    minWeight: Math.round(Math.min(...weights)),
    weightChange,
    weightChartData,
    maxBodyFat: Math.round(Math.max(...bodyFats) * 10) / 10,
    minBodyFat: Math.round(Math.min(...bodyFats) * 10) / 10,
    bodyFatChange,
    bodyFatChartData,
    avgSystolic: Math.round(systolics.reduce((a, b) => a + b, 0) / systolics.length),
    avgDiastolic: Math.round(diastolics.reduce((a, b) => a + b, 0) / diastolics.length),
    maxHeartRate: Math.max(...heartRates),
    minHeartRate: Math.min(...heartRates),
    avgHeartRate: Math.round(heartRates.reduce((a, b) => a + b, 0) / heartRates.length)
  };
}

/**
 * 获取变化量文字（共用）
 */
export function getChangeText(change: number): string {
  if (change > 0) {
    return `+${change.toFixed(1)}`;
  } else if (change < 0) {
    return change.toFixed(1);
  }
  return '0';
}

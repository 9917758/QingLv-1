/**
 * 健康数据记录 Mock 数据
 * 生成近30天的模拟历史记录
 */
import { HealthDataRecord } from '../types/HealthDataRecordTypes';

/**
 * 生成近 N 天的 mock 健康数据记录
 * 基于基准值 + 日间波动 + 趋势变化，模拟真实的体重下降、血压改善等趋势
 */
export function generateMockHealthRecords(days: number): HealthDataRecord[] {
  const records: HealthDataRecord[] = [];
  const now = new Date();

  // 基准值（模拟一个正在减重、血压偏高的用户）
  const baseWeight = 60; // 公斤
  const baseSystolic = 132;
  const baseDiastolic = 88;
  const baseHeartRate = 76;
  const baseBloodSugar = 5.4;
  const baseWaist = 82;
  const baseHip = 96;
  const height = 167; // cm
  const age = 28;

  for (let i = 0; i < days; i++) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    const timestamp = date.getTime();

    // 日间随机波动（±2%左右）
    const jitter = () => (Math.random() - 0.5) * 0.04;

    // 趋势：体重缓慢下降（每天约 -0.05 斤），血压逐渐改善
    const trendFactor = i / days; // 0（今天）→ ~1（N天前）

    const weight = Math.round((baseWeight + trendFactor * 2.5 + baseWeight * jitter()) * 10) / 10;
    const bmi = Math.round((weight / ((height / 100) * (height / 100))) * 10) / 10;
    const bodyFat = Math.round((1.2 * bmi + 0.23 * age - 5.4 + (Math.random() - 0.5) * 1.5) * 10) / 10;
    const fatWeight = Math.round((weight * bodyFat / 100) * 10) / 10;

    const systolic = Math.round(baseSystolic + trendFactor * 6 + (Math.random() - 0.5) * 8);
    const diastolic = Math.round(baseDiastolic + trendFactor * 4 + (Math.random() - 0.5) * 6);
    const heartRate = Math.round(baseHeartRate + trendFactor * 3 + (Math.random() - 0.5) * 10);
    const bloodSugar = Math.round((baseBloodSugar + trendFactor * 0.3 + (Math.random() - 0.5) * 0.6) * 10) / 10;
    const waist = Math.round((baseWaist + trendFactor * 1.5 + (Math.random() - 0.5) * 2) * 10) / 10;
    const hip = Math.round((baseHip + trendFactor * 1 + (Math.random() - 0.5) * 2) * 10) / 10;

    const record: HealthDataRecord = {
      id: `mock_${i}`,
      timestamp: timestamp,
      weight: weight,
      bmi: bmi,
      bodyFatPercentage: bodyFat,
      fatWeight: fatWeight,
      bloodSugar: bloodSugar,
      bloodPressureSystolic: systolic,
      bloodPressureDiastolic: diastolic,
      heartRate: heartRate,
      waistCircumference: waist,
      hipCircumference: hip,
      stepCount: Math.floor(3000 + Math.random() * 9000),
      sleepHours: Math.round((6.5 + Math.random() * 2.5) * 10) / 10
    };
    records.push(record);
  }

  return records;
}

/**
 * 预生成的 30 天 mock 记录（惰性初始化，避免每次 import 都计算）
 */
let _cachedMockRecords: HealthDataRecord[] | null = null;

export function getMockHealthRecords(): HealthDataRecord[] {
  if (_cachedMockRecords === null) {
    _cachedMockRecords = generateMockHealthRecords(60);
  }
  return _cachedMockRecords;
}

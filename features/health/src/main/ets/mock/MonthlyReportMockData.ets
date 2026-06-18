/**
 * 月度报告模拟数据
 */
import { MonthlyReportData } from '../types/MonthlyReportTypes';

export const MONTHLY_REPORT_DATA: MonthlyReportData = {
  startDate: '2026年4月1日',
  endDate: '4月30日',
  dateRange: '2026年4月',

  weightTrend: {
    maxWeight: 122,
    minWeight: 120,
    change: -0.2,
    chartData: [
      { date: '4/4', value: 121.8 },
      { date: '4/12', value: 121.5 },
      { date: '4/19', value: 121.0 },
      { date: '4/26', value: 120.5 },
      { date: '5/2', value: 120.0 }
    ]
  },

  bodyFatTrend: {
    maxBodyFat: 32.1,
    minBodyFat: 28.1,
    change: -4.0,
    chartData: [
      { date: '4/4', value: 31.8 },
      { date: '4/12', value: 31.0 },
      { date: '4/19', value: 30.2 },
      { date: '4/26', value: 29.5 },
      { date: '5/2', value: 28.5 }
    ]
  },

  bloodPressure: {
    diastolic: 88,
    systolic: 128,
    pulse: 0 // 暂无数据
  },

  heartRate: {
    restingHeartRate: 76,
    averageHeartRate: 82,
    maxHeartRate: 96,
    minHeartRate: 68
  }
};


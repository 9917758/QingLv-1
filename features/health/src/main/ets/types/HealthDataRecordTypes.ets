/**
 * 健康数据记录类型定义
 * 用于存储用户每次录入的健康数据历史
 */

/**
 * 单条健康数据记录
 */
export interface HealthDataRecord {
  id: string;                      // 记录ID
  timestamp: number;               // 记录时间戳
  weight: number;                  // 体重（斤）
  bmi: number;                     // BMI
  bodyFatPercentage: number;       // 体脂率
  fatWeight: number;               // 脂肪重量
  bloodSugar: number;              // 血糖
  bloodPressureSystolic: number;   // 收缩压
  bloodPressureDiastolic: number;  // 舒张压
  heartRate: number;               // 心率
  waistCircumference: number;      // 腰围
  hipCircumference: number;        // 臀围
}

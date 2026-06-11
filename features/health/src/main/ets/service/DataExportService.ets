/**
 * 健康数据导出服务
 * 支持导出为 CSV 和 JSON 格式
 */
import { HealthDataService } from './HealthDataService';
import { HealthDataRecord } from '../types/HealthDataRecordTypes';
import { fileIo } from '@kit.CoreFileKit';
import { Context } from '@kit.AbilityKit';
import { GlobalContext } from 'common';

/** JSON 导出记录结构 */
interface ExportRecord {
  date: string;
  weight: number;
  bmi: number;
  bodyFatPercentage: number;
  fatWeight: number;
  bloodSugar: number;
  bloodPressureSystolic: number;
  bloodPressureDiastolic: number;
  heartRate: number;
  waistCircumference: number;
  hipCircumference: number;
  stepCount: number;
  sleepHours: number;
}

export class DataExportService {
  /**
   * 导出为 CSV 字符串
   */
  public static toCsv(records: HealthDataRecord[]): string {
    const header = '日期,体重(公斤),BMI,体脂率(%),脂肪重量,血糖(mmol/L),收缩压(mmHg),舒张压(mmHg),心率(次/分),腰围(cm),臀围(cm),步数,睡眠时长(h)';
    const rows: string[] = records.map((r: HealthDataRecord) => {
      const d = new Date(r.timestamp);
      const dateStr = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
      return [
        dateStr, r.weight, r.bmi, r.bodyFatPercentage, r.fatWeight,
        r.bloodSugar, r.bloodPressureSystolic, r.bloodPressureDiastolic,
        r.heartRate, r.waistCircumference, r.hipCircumference,
        r.stepCount, r.sleepHours
      ].join(',');
    });
    return [header, ...rows].join('\n');
  }

  /**
   * 导出为 JSON 字符串
   */
  public static toJson(records: HealthDataRecord[]): string {
    const data: ExportRecord[] = records.map((r: HealthDataRecord) => {
      const item: ExportRecord = {
        date: new Date(r.timestamp).toISOString().split('T')[0],
        weight: r.weight,
        bmi: r.bmi,
        bodyFatPercentage: r.bodyFatPercentage,
        fatWeight: r.fatWeight,
        bloodSugar: r.bloodSugar,
        bloodPressureSystolic: r.bloodPressureSystolic,
        bloodPressureDiastolic: r.bloodPressureDiastolic,
        heartRate: r.heartRate,
        waistCircumference: r.waistCircumference,
        hipCircumference: r.hipCircumference,
        stepCount: r.stepCount,
        sleepHours: r.sleepHours,
      };
      return item;
    });
    return JSON.stringify(data, null, 2);
  }

  /**
   * 导出到文件并返回文件路径
   * @param format 导出格式
   * @returns 文件路径
   */
  public static async exportToFile(format: 'csv' | 'json'): Promise<string> {
    const records = HealthDataService.instance.getAllRecords();
    if (records.length === 0) {
      throw new Error('没有可导出的数据');
    }

    const content: string = format === 'csv' ? DataExportService.toCsv(records) : DataExportService.toJson(records);
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const fileName = `health_data_${timestamp}.${format}`;

    // 获取应用缓存目录
    const ctx: Context = GlobalContext.getUIAbilityContext();
    const cacheDir: string = ctx.cacheDir;
    const filePath = `${cacheDir}/${fileName}`;

    // 写入文件
    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.writeSync(file.fd, content);
    fileIo.closeSync(file);

    return filePath;
  }

  /**
   * 获取记录总数
   */
  public static getRecordCount(): number {
    return HealthDataService.instance.getRecordCount();
  }
}

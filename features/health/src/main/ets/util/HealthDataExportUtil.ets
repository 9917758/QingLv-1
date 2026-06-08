/**
 * 健康数据导出工具
 * 将健康数据记录导出为 JSON 文件
 */
import { HealthDataService } from '../service/HealthDataService';
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class HealthDataExportUtil {
  /**
   * 导出所有健康数据为 JSON 文件
   */
  static async exportToJson(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const records = HealthDataService.instance.getAllRecords();
      if (records.length === 0) {
        return false;
      }

      const exportData = {
        appName: '清律',
        exportTime: new Date().toISOString(),
        recordCount: records.length,
        records: records
      };

      const jsonStr = JSON.stringify(exportData, null, 2);

      // 使用文件选择器让用户选择保存位置
      const documentPicker = new picker.DocumentViewPicker(context);
      const uris = await documentPicker.save({
        newFileNames: [`health_data_${formatDate(new Date())}.json`]
      });

      if (uris && uris.length > 0) {
        const uri = uris[0];
        const file = await context.openFile(uri, 'wt');
        if (file) {
          file.writeSync(jsonStr);
          file.close();
          return true;
        }
      }
      return false;
    } catch (err) {
      const error = err as BusinessError;
      console.error('Export failed:', error.message);
      return false;
    }
  }
}

function formatDate(date: Date): string {
  const y = date.getFullYear();
  const m = (date.getMonth() + 1).toString().padStart(2, '0');
  const d = date.getDate().toString().padStart(2, '0');
  return `${y}${m}${d}`;
}

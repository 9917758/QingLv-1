export class ReminderPlanItem {
  id: string = '';
  type: number = 0; // 0=饮水, 1=用药
  name: string = ''; // 名称（如"降压药"、"上午喝水"）
  time: string = ''; // 提醒时间 HH:mm（如"10:00"）
  dosage: string = ''; // 剂量说明（用药）或水量（饮水）
  isEnabled: boolean = true; // 是否启用
  isCheckedToday: boolean = false; // 今日是否已打卡
}

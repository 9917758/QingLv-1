import { ReminderPlanItem } from '../model/ReminderPlanModel';

/**
 * 创建默认提醒计划实例（不使用对象字面量，避免 ArkTS 严格模式报错）
 */
function createPlan(id: string, type: number, name: string, time: string, dosage: string): ReminderPlanItem {
  const plan = new ReminderPlanItem();
  plan.id = id;
  plan.type = type;
  plan.name = name;
  plan.time = time;
  plan.dosage = dosage;
  plan.isEnabled = true;
  plan.isCheckedToday = false;
  return plan;
}

/**
 * 用药与饮水提醒 Mock 数据
 * 首次使用时注入，后续用户自定义的计划由 PreferenceUtil 持久化
 */
export const DEFAULT_REMINDER_PLANS: ReminderPlanItem[] = [
  createPlan('1', 0, '上午喝水', '10:00', '250ml（约一杯）'),
  createPlan('2', 0, '下午喝水', '15:00', '250ml（约一杯）'),
  createPlan('3', 1, '降压药', '19:00', '1片，饭后30分钟服用'),
  createPlan('4', 1, '维生素片', '08:30', '1片，随餐服用'),
  createPlan('5', 0, '晚间补水', '21:00', '200ml（半杯）')
];

/**
 * 国际化工具
 * 为 Service/ViewModel 层提供多语言字符串（$r 只能在 UI 组件中使用）
 * UI 层应直接使用 $r('app.string.xxx')
 * 语言跟随系统 locale，与 $r() 保持一致
 */
import { i18n } from '@kit.LocalizationKit';

/** 中文字符串映射 */
const ZH: Record<string, string> = {
  // 健康评分
  'score.excellent': '优秀',
  'score.good': '良好',
  'score.average': '一般',
  'score.poor': '偏差',
  'score.attention': '需关注',
  'score.no_data': '无数据',

  // 睡眠质量
  'sleep.excellent': '优秀',
  'sleep.good': '良好',
  'sleep.average': '一般',
  'sleep.poor': '较差',

  // 异常事件
  'anomaly.heartrate_high': '心率偏快',
  'anomaly.heartrate_low': '心率偏慢',
  'anomaly.bp_high': '血压偏高',
  'anomaly.bp_low': '血压偏低',
  'anomaly.bs_high': '血糖偏高',
  'anomaly.bs_low': '血糖偏低',
  'anomaly.bmi_obese': 'BMI 肥胖',
  'anomaly.bmi_overweight': 'BMI 偏胖',
  'anomaly.bmi_underweight': 'BMI 偏瘦',

  // 健康建议
  'suggestion.weight_manage': '体重管理',
  'suggestion.nutrition': '营养补充',
  'suggestion.bp_attention': '血压关注',
  'suggestion.hr_fast': '心率偏快',
  'suggestion.bs_high': '血糖偏高',
  'suggestion.exercise_lack': '运动不足',
  'suggestion.exercise_good': '运动达标',
  'suggestion.water_lack': '饮水不足',
  'suggestion.status_good': '状态良好',
  'suggestion.bmi_obese': 'BMI {0}（肥胖），建议控制每日热量摄入，增加有氧运动，每周减重0.5-1斤为宜。',
  'suggestion.bmi_overweight': 'BMI {0}（偏胖），建议减少高热量食物，每天保持30分钟以上运动。',
  'suggestion.bmi_underweight': 'BMI {0}（偏瘦），建议适当增加优质蛋白和碳水化合物摄入。',
  'suggestion.bp_high': '血压 {0} mmHg 偏高，建议低盐饮食、规律作息，必要时就医。',
  'suggestion.heartrate_high': '心率偏快',
  'suggestion.heartrate_high_detail': '静息心率 {0} 次/分偏高，建议避免咖啡因，保持充足睡眠。',
  'suggestion.heartrate_low': '心率偏慢',
  'suggestion.heartrate_low_detail': '心率 {0} 次/分偏低，如无不适属正常，如有头晕请及时就医。',
  'suggestion.bs_high_detail': '血糖 {0} mmol/L 偏高，建议控制碳水摄入，餐后适当运动。',
  'suggestion.exercise_low': '运动不足',
  'suggestion.exercise_low_detail': '今日步数 {0}，建议增加步行，目标 8000 步以上。',
  'suggestion.exercise_good_detail': '今日步数 {0}，运动量充足，继续保持！',
  'suggestion.water_low': '饮水不足',
  'suggestion.water_low_detail': '今日仅喝 {0} 杯水，目标 {1} 杯，记得多喝水。',
  'suggestion.status_good_detail': '各项指标正常，继续保持良好的生活习惯！每日保持运动和充足饮水。',
  'suggestion.need_attention': '需关注',

  // 目标
  'goal.distance': '距目标还差',
  'goal.exceeded': '已超过目标',
  'goal.reached': '🎉 已达成目标！',

  // 单位
  'unit.kg': '公斤',
  'unit.times_per_min': '次/分',
  'unit.mmhg': 'mmHg',
  'unit.mmol': 'mmol/L',
  'unit.cups': '杯',
  'unit.steps': '步',
  'unit.hours': '时',
  'unit.minutes': '分',

  // 日期格式
  'date.year_suffix': '年',
  'date.month_suffix': '月',
  'date.day_suffix': '日',

  // 报告
  'report.previous_week': '上周',
  'report.previous_month': '上月',

  // 通用
  'common.cancel': '取消',
  'common.confirm': '确认',
  'common.save': '保存',
  'common.delete': '删除',
  'common.edit': '编辑',
  'common.loading': '加载中...',
  'common.no_data': '暂无数据',

  // BMI 等级
  'health.bmi_type_underweight': '偏瘦',
  'health.bmi_type_normal': '正常',
  'health.bmi_type_overweight': '偏胖',
  'health.bmi_type_obesity': '肥胖',

  // BMI 建议
  'health.bmi_advice_underweight': '您的体重偏轻，建议适当增加营养摄入，加强运动锻炼。',
  'health.bmi_advice_normal': '您的体重在正常范围内，请继续保持健康的生活方式。',
  'health.bmi_advice_overweight': '您的体重偏高，建议控制饮食，增加有氧运动。',
  'health.bmi_advice_obesity': '您的体重超标，建议制定减重计划，必要时咨询专业医生。',
  'health.bmi_advice_default': '请保持健康的生活方式。',

  // 用药提醒
  'reminder.water_morning': '早晨喝水',
  'reminder.water_afternoon': '下午喝水',
  'reminder.water_sleep': '睡前喝水',
  'reminder.medicine_bp': '降压药',
  'reminder.medicine_vitamin': '维生素',
};

/** 英文字符串映射 */
const EN: Record<string, string> = {
  'score.excellent': 'Excellent',
  'score.good': 'Good',
  'score.average': 'Average',
  'score.poor': 'Poor',
  'score.attention': 'Needs Attention',
  'score.no_data': 'No Data',

  'sleep.excellent': 'Excellent',
  'sleep.good': 'Good',
  'sleep.average': 'Average',
  'sleep.poor': 'Poor',

  'anomaly.heartrate_high': 'High Heart Rate',
  'anomaly.heartrate_low': 'Low Heart Rate',
  'anomaly.bp_high': 'High Blood Pressure',
  'anomaly.bp_low': 'Low Blood Pressure',
  'anomaly.bs_high': 'High Blood Sugar',
  'anomaly.bs_low': 'Low Blood Sugar',
  'anomaly.bmi_obese': 'BMI Obese',
  'anomaly.bmi_overweight': 'BMI Overweight',
  'anomaly.bmi_underweight': 'BMI Underweight',

  'suggestion.weight_manage': 'Weight Management',
  'suggestion.nutrition': 'Nutrition',
  'suggestion.bp_attention': 'Blood Pressure',
  'suggestion.hr_fast': 'Fast Heart Rate',
  'suggestion.bs_high': 'High Blood Sugar',
  'suggestion.exercise_lack': 'Lack of Exercise',
  'suggestion.exercise_good': 'Exercise Goal Met',
  'suggestion.water_lack': 'Low Water Intake',
  'suggestion.status_good': 'Status Good',
  'suggestion.bmi_obese': 'BMI {0} (Obese), suggest controlling daily calorie intake and increasing aerobic exercise, aim for 0.5-1 kg/week loss.',
  'suggestion.bmi_overweight': 'BMI {0} (Overweight), suggest reducing high-calorie foods and maintaining 30+ minutes of daily exercise.',
  'suggestion.bmi_underweight': 'BMI {0} (Underweight), suggest increasing quality protein and carbohydrate intake.',
  'suggestion.bp_high': 'BP {0} mmHg is elevated, suggest low-sodium diet and regular sleep, consult doctor if needed.',
  'suggestion.heartrate_high': 'Fast Heart Rate',
  'suggestion.heartrate_high_detail': 'Resting heart rate {0} bpm is elevated, suggest avoiding caffeine and ensuring adequate sleep.',
  'suggestion.heartrate_low': 'Slow Heart Rate',
  'suggestion.heartrate_low_detail': 'Heart rate {0} bpm is low, normal if asymptomatic, consult doctor if dizziness occurs.',
  'suggestion.bs_high_detail': 'Blood sugar {0} mmol/L is elevated, suggest controlling carb intake and exercising after meals.',
  'suggestion.exercise_low': 'Low Exercise',
  'suggestion.exercise_low_detail': 'Today steps: {0}, suggest increasing walking, target 8000+ steps.',
  'suggestion.exercise_good_detail': 'Today steps: {0}, great exercise level, keep it up!',
  'suggestion.water_low': 'Low Water Intake',
  'suggestion.water_low_detail': 'Only {0} cups today, goal is {1} cups, remember to hydrate.',
  'suggestion.status_good_detail': 'All indicators normal, maintain healthy habits! Keep exercising and stay hydrated.',
  'suggestion.need_attention': 'Needs Attention',

  'goal.distance': 'Remaining to goal:',
  'goal.exceeded': 'Exceeded goal by:',
  'goal.reached': '🎉 Goal reached!',

  'unit.kg': 'kg',
  'unit.times_per_min': 'bpm',
  'unit.mmhg': 'mmHg',
  'unit.mmol': 'mmol/L',
  'unit.cups': 'cups',
  'unit.steps': 'steps',
  'unit.hours': 'h',
  'unit.minutes': 'min',

  'date.year_suffix': '/',
  'date.month_suffix': '/',
  'date.day_suffix': '',

  'report.previous_week': 'Last Week',
  'report.previous_month': 'Last Month',

  'health.bmi_type_underweight': 'Underweight',
  'health.bmi_type_normal': 'Normal',
  'health.bmi_type_overweight': 'Overweight',
  'health.bmi_type_obesity': 'Obesity',

  'health.bmi_advice_underweight': 'Your weight is underweight. Consider increasing nutrition intake and exercise.',
  'health.bmi_advice_normal': 'Your weight is normal. Keep up the healthy lifestyle.',
  'health.bmi_advice_overweight': 'Your weight is overweight. Consider controlling diet and increasing aerobic exercise.',
  'health.bmi_advice_obesity': 'Your weight is obese. Consider a weight loss plan and consult a doctor if needed.',
  'health.bmi_advice_default': 'Please maintain a healthy lifestyle.',

  'common.cancel': 'Cancel',
  'common.confirm': 'Confirm',
  'common.save': 'Save',
  'common.delete': 'Delete',
  'common.edit': 'Edit',
  'common.loading': 'Loading...',
  'common.no_data': 'No Data',

  'reminder.water_morning': 'Morning Water',
  'reminder.water_afternoon': 'Afternoon Water',
  'reminder.water_sleep': 'Bedtime Water',
  'reminder.medicine_bp': 'Blood Pressure Med',
  'reminder.medicine_vitamin': 'Vitamin',
};

@ObservedV2
export class I18nUtil {
  @Trace private static _lang: string = 'zh';

  /**
   * 初始化：跟随系统语言
   * $r() 跟随系统 locale，I18nUtil 也必须跟随，否则两边不一致
   */
  public static init(): void {
    try {
      const sysLang = i18n.System.getSystemLanguage();
      I18nUtil._lang = sysLang.startsWith('en') ? 'en' : 'zh';
    } catch {
      I18nUtil._lang = 'zh';
    }
  }

  /** 获取当前语言 */
  public static get lang(): string {
    return I18nUtil._lang;
  }

  /**
   * 获取翻译字符串
   * @param key 字符串 key（如 'score.excellent'）
   * @returns 对应语言的字符串，找不到则返回 key 本身
   */
  public static t(key: string): string {
    if (I18nUtil._lang === 'en') {
      return EN[key] || ZH[key] || key;
    }
    return ZH[key] || key;
  }

  /**
   * 格式化日期（根据语言返回不同格式）
   */
  public static formatDate(month: number, day: number): string {
    if (I18nUtil._lang === 'en') {
      return `${month}/${day}`;
    }
    return `${month}月${day}日`;
  }

  /**
   * 格式化年月（如 "2026年6月" 或 "2026/6"）
   */
  public static formatYearMonth(year: number, month: number): string {
    if (I18nUtil._lang === 'en') {
      return `${year}/${month}`;
    }
    return `${year}年${month}月`;
  }

  /**
   * 格式化完整日期（如 "2026年6月10日" 或 "2026/6/10"）
   */
  public static formatFullDate(year: number, month: number, day: number): string {
    if (I18nUtil._lang === 'en') {
      return `${year}/${month}/${day}`;
    }
    return `${year}年${month}月${day}日`;
  }
}

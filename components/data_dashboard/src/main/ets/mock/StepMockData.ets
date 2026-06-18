/**
 * 步数页面 Mock 数据
 * 根据当前日期动态生成，避免出现未来日期
 */
import { TimeRange, StepRangeOption, MonthGroup, StepHistoryItem, StepHistoryStatistics } from '../types/StepTypes';

/**
 * 格式化日期为两位数
 */
function padDate(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

/**
 * 获取指定日期是周几（中文）
 */
function getWeekDay(date: Date): string {
  const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  return days[date.getDay()];
}

/**
 * 生成指定范围内的随机步数
 */
function randomSteps(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 生成本周的 Mock 数据（基于当前日期）
 */
function generateWeekOptions(): StepRangeOption[] {
  const now = new Date();
  const options: StepRangeOption[] = [];

  // 生成最近3周的数据
  for (let weekOffset = 0; weekOffset < 3; weekOffset++) {
    const endDate = new Date(now);
    endDate.setDate(now.getDate() - weekOffset * 7);
    const startDate = new Date(endDate);
    startDate.setDate(endDate.getDate() - 6);

    const startStr = `${padDate(startDate.getMonth() + 1)}月${padDate(startDate.getDate())}日`;
    const endStr = `${padDate(endDate.getMonth() + 1)}月${padDate(endDate.getDate())}日`;
    const yearStr = `${endDate.getFullYear()}年`;

    // 生成7天的步数数据
    const steps: number[] = [];
    const labels: string[] = [];
    let totalSteps = 0;

    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      const daySteps = randomSteps(1500, 8000);
      steps.push(daySteps);
      totalSteps += daySteps;
      labels.push(`${padDate(date.getMonth() + 1)}月${padDate(date.getDate())}日`);
    }

    // 选中中间一天作为当前显示
    const midIndex = 3;
    const midDate = new Date(startDate);
    midDate.setDate(startDate.getDate() + midIndex);

    options.push({
      label: `${yearStr}${startStr} - ${endStr}`,
      period: `${padDate(midDate.getMonth() + 1)}月${padDate(midDate.getDate())}日(${getWeekDay(midDate)})`,
      currentSteps: steps[midIndex],
      steps: steps,
      labels: labels,
      statistics: {
        total: totalSteps,
        average: Math.floor(totalSteps / 7),
        calories: Math.floor(totalSteps * 0.04),
        distance: Math.round((totalSteps * 0.0007) * 100) / 100
      }
    });
  }

  return options;
}

/**
 * 生成本月和前2个月的 Mock 数据
 */
function generateMonthOptions(): StepRangeOption[] {
  const now = new Date();
  const options: StepRangeOption[] = [];

  for (let monthOffset = 0; monthOffset < 3; monthOffset++) {
    const targetDate = new Date(now.getFullYear(), now.getMonth() - monthOffset, 1);
    const year = targetDate.getFullYear();
    const month = targetDate.getMonth() + 1;
    const daysInMonth = new Date(year, month, 0).getDate();

    // 生成该月每天的步数
    const steps: number[] = [];
    const labels: string[] = [];
    let totalSteps = 0;

    for (let day = 1; day <= daysInMonth; day++) {
      const daySteps = randomSteps(2000, 9000);
      steps.push(daySteps);
      totalSteps += daySteps;
      // 只在特定日期显示标签
      if (day === 1 || day === 5 || day === 10 || day === 15 || day === 20 || day === 25 || day === daysInMonth) {
        labels.push(`${month}/${day}`);
      } else {
        labels.push('');
      }
    }

    // 选中月中某天作为当前显示
    const midDay = Math.min(15, daysInMonth);

    options.push({
      label: `${year}年${padDate(month)}月`,
      period: `${padDate(month)}月${padDate(midDay)}日`,
      currentSteps: steps[midDay - 1],
      steps: steps,
      labels: labels,
      statistics: {
        total: totalSteps,
        average: Math.floor(totalSteps / daysInMonth),
        calories: Math.floor(totalSteps * 0.04),
        distance: Math.round((totalSteps * 0.0007) * 100) / 100
      }
    });
  }

  return options;
}

/**
 * 生成最近3个月的 Mock 数据
 */
function generateThreeMonthsOptions(): StepRangeOption[] {
  const now = new Date();
  const options: StepRangeOption[] = [];

  for (let offset = 0; offset < 3; offset++) {
    const endDate = new Date(now.getFullYear(), now.getMonth() - offset, 1);
    const startDate = new Date(endDate.getFullYear(), endDate.getMonth() - 2, 1);

    const startMonth = startDate.getMonth() + 1;
    const endMonth = endDate.getMonth() + 1;

    // 生成12周的数据（3个月约12周）
    const steps: number[] = [];
    const labels: string[] = [];
    let totalSteps = 0;

    for (let i = 0; i < 12; i++) {
      const weekSteps = randomSteps(15000, 55000);
      steps.push(weekSteps);
      totalSteps += weekSteps;

      // 每月第一周显示月份标签
      if (i % 4 === 0) {
        const monthIndex = Math.floor(i / 4);
        const month = startMonth + monthIndex;
        labels.push(`${month > 12 ? month - 12 : month}月`);
      } else {
        labels.push('');
      }
    }

    options.push({
      label: `${startDate.getFullYear()}年${padDate(startMonth)}月 - ${padDate(endMonth)}月`,
      period: '近三个月',
      currentSteps: steps[steps.length - 1],
      steps: steps,
      labels: labels,
      statistics: {
        total: totalSteps,
        average: Math.floor(totalSteps / 12),
        calories: Math.floor(totalSteps * 0.04),
        distance: Math.round((totalSteps * 0.0007) * 100) / 100
      }
    });
  }

  return options;
}

/**
 * 步数范围选项数据（动态生成）
 */
export const STEP_RANGE_OPTIONS: Record<TimeRange, StepRangeOption[]> = {
  [TimeRange.WEEK]: generateWeekOptions(),
  [TimeRange.MONTH]: generateMonthOptions(),
  [TimeRange.THREE_MONTHS]: generateThreeMonthsOptions()
};

/**
 * 生成步数历史记录数据
 */
function generateStepHistoryMonths(): MonthGroup[] {
  const now = new Date();
  const months: MonthGroup[] = [];

  // 生成最近3个月的历史记录
  for (let monthOffset = 0; monthOffset < 3; monthOffset++) {
    const targetDate = new Date(now.getFullYear(), now.getMonth() - monthOffset, 1);
    const year = targetDate.getFullYear();
    const month = targetDate.getMonth() + 1;
    const daysInMonth = new Date(year, month, 0).getDate();

    const records: StepHistoryItem[] = [];
    // 每月生成6-8条记录
    const recordCount = 6 + Math.floor(Math.random() * 3);

    for (let i = 0; i < recordCount; i++) {
      const day = Math.max(1, Math.min(daysInMonth, Math.floor(Math.random() * daysInMonth) + 1));
      const hour = 17 + Math.floor(Math.random() * 4); // 17-20点
      const minute = Math.floor(Math.random() * 60);
      const steps = randomSteps(6000, 15000);
      const durationMinutes = 20 + Math.floor(Math.random() * 20);

      const item: StepHistoryItem = {
        steps: steps,
        duration: `00:${padDate(durationMinutes)}:00`,
        distance: Math.round((steps * 0.0007) * 100) / 100,
        dateTime: `${padDate(month)}/${padDate(day)} ${padDate(hour)}:${padDate(minute)}`
      };
      records.push(item);
    }

    // 按日期排序（降序）
    records.sort((a: StepHistoryItem, b: StepHistoryItem) => {
      const dateA: number = parseInt(a.dateTime.replace(/[\/\s:]/g, ''));
      const dateB: number = parseInt(b.dateTime.replace(/[\/\s:]/g, ''));
      return dateB - dateA;
    });

    months.push({
      monthTitle: `${year}年${padDate(month)}月`,
      records: records
    });
  }

  return months;
}

/**
 * 步数历史记录数据（动态生成）
 */
export const STEP_HISTORY_MONTHS: MonthGroup[] = generateStepHistoryMonths();

/**
 * 步数历史统计数据（动态生成）
 */
export const STEP_HISTORY_STATISTICS: StepHistoryStatistics = {
  totalDuration: 7.5,
  totalCount: 8,
  totalCalories: 2863
};

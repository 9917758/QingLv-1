/**
 * 步数页面 Mock 数据
 */
import { TimeRange, StepRangeOption, MonthGroup, StepHistoryStatistics } from '../types/StepTypes';

/**
 * 步数范围选项数据
 */
export const STEP_RANGE_OPTIONS: Record<TimeRange, StepRangeOption[]> = {
  [TimeRange.WEEK]: [
    {
      label: '2026年06月24日 - 06月30日',
      period: '06月24日(周日)',
      currentSteps: 1800,
      steps: [1800, 6000, 2700, 900, 7500, 2500, 4600],
      labels: ['06月24日', '06月25日', '06月26日', '06月27日', '06月28日', '06月29日', '06月30日'],
      statistics: {
        total: 8000,
        average: 1398,
        calories: 230,
        distance: 0.98
      }
    },
    {
      label: '2026年06月17日 - 06月23日',
      period: '06月20日(周四)',
      currentSteps: 5120,
      steps: [2200, 5500, 3400, 1600, 6800, 3100, 5200],
      labels: [],
      statistics: {
        total: 9100,
        average: 1300,
        calories: 250,
        distance: 1.10
      }
    },
    {
      label: '2026年06月10日 - 06月16日',
      period: '06月13日(周五)',
      currentSteps: 4980,
      steps: [2000, 4800, 3600, 1400, 6200, 2800, 5000],
      labels: [],
      statistics: {
        total: 8600,
        average: 1228,
        calories: 240,
        distance: 1.02
      }
    }
  ],
  [TimeRange.MONTH]: [
    {
      label: '2026年4月',
      period: '06月19日',
      currentSteps: 1200,
      steps: [4800, 6200, 3600, 5900, 7100, 4750, 3400, 8300, 5950, 6050, 4700, 8400, 4800, 3600, 7200, 5900, 7100,
        4650, 7250, 6000, 4850, 7150, 4700, 5950, 8300, 4800, 6050, 7200, 5900, 7100],
      labels: ['6/1', '', '', '', '6/5', '', '', '', '', '6/10', '', '', '', '', '6/15', '', '', '', '', '6/20', '', '',
        '', '', '6/25', '', '', '', '', '6/30'],
      statistics: {
        total: 180000,
        average: 6000,
        calories: 2400,
        distance: 12.60
      }
    },
    {
      label: '2026年3月',
      period: '05月15日',
      currentSteps: 1420,
      steps: [1100, 600, 900, 500, 700, 800, 1400, 500, 600, 300, 800, 900, 600],
      labels: ['5/2', '', '', '5/10', '', '', '', '5/17', '', '', '5/24', '', '', '5/31'],
      statistics: {
        total: 31500,
        average: 1050,
        calories: 450,
        distance: 2.60
      }
    },
    {
      label: '2026年2月',
      period: '04月12日',
      currentSteps: 1630,
      steps: [1200, 800, 700, 600, 900, 700, 1300, 700, 500, 400, 1000, 800, 700],
      labels: ['4/1', '', '', '4/9', '', '', '', '4/16', '', '', '4/23', '', '', '4/28'],
      statistics: {
        total: 33200,
        average: 1070,
        calories: 470,
        distance: 2.80
      }
    }
  ],
  [TimeRange.THREE_MONTHS]: [
    {
      label: '2026年2月 - 06月',
      period: '3月12日～3月18日',
      currentSteps: 6130,
      // 12个柱子代表3个月，每月4周：2月(4周) + 3月(4周) + 4月(4周)
      steps: [6300, 4700, 5800, 4400, 5500, 4400, 7200, 4600, 5700, 4400, 5900, 4700],
      labels: ['2月', '', '', '', '3月', '', '', '', '4月', '', '', ''],
      statistics: {
        total: 450000,
        average: 6500,
        calories: 3150,
        distance: 31.50
      }
    },
    {
      label: '2026年5月 - 7月',
      period: '近三个月',
      currentSteps: 1380,
      steps: [1100, 600, 900, 500, 700, 800, 1400, 500, 600, 300, 800, 900],
      labels: ['5月', '', '', '', '6月', '', '', '', '7月', '', '', ''],
      statistics: {
        total: 94000,
        average: 1560,
        calories: 650,
        distance: 4.40
      }
    },
    {
      label: '2026年8月 - 10月',
      period: '近三个月',
      currentSteps: 1520,
      steps: [1200, 800, 700, 600, 900, 700, 1300, 700, 500, 400, 1000, 800],
      labels: ['8月', '', '', '', '9月', '', '', '', '10月', '', '', ''],
      statistics: {
        total: 98000,
        average: 1620,
        calories: 670,
        distance: 4.70
      }
    }
  ]
};

/**
 * 步数历史记录数据
 */
export const STEP_HISTORY_MONTHS: MonthGroup[] = [
  {
    monthTitle: '2026年4月',
    records: [
      {
        steps: 12130,
        duration: '00:30:00',
        distance: 5.68,
        dateTime: '06/28 19:00'
      },
      {
        steps: 10850,
        duration: '00:28:00',
        distance: 5.12,
        dateTime: '06/25 18:30'
      },
      {
        steps: 11500,
        duration: '00:29:00',
        distance: 5.40,
        dateTime: '06/22 20:15'
      },
      {
        steps: 9800,
        duration: '00:25:00',
        distance: 4.60,
        dateTime: '06/18 19:45'
      },
      {
        steps: 13200,
        duration: '00:33:00',
        distance: 6.20,
        dateTime: '06/15 18:20'
      },
      {
        steps: 10200,
        duration: '00:26:00',
        distance: 4.80,
        dateTime: '06/12 19:30'
      },
      {
        steps: 11800,
        duration: '00:30:00',
        distance: 5.50,
        dateTime: '06/08 18:50'
      },
      {
        steps: 9500,
        duration: '00:24:00',
        distance: 4.45,
        dateTime: '06/05 20:00'
      }
    ]
  },
  {
    monthTitle: '2026年3月',
    records: [
      {
        steps: 11020,
        duration: '00:28:00',
        distance: 5.12,
        dateTime: '05/30 18:30'
      },
      {
        steps: 12500,
        duration: '00:31:00',
        distance: 5.85,
        dateTime: '05/27 19:00'
      },
      {
        steps: 9800,
        duration: '00:25:00',
        distance: 4.60,
        dateTime: '05/24 20:00'
      },
      {
        steps: 10600,
        duration: '00:27:00',
        distance: 4.95,
        dateTime: '05/21 18:15'
      },
      {
        steps: 12360,
        duration: '00:32:00',
        distance: 5.90,
        dateTime: '05/18 19:20'
      },
      {
        steps: 11200,
        duration: '00:29:00',
        distance: 5.25,
        dateTime: '05/15 18:45'
      },
      {
        steps: 10800,
        duration: '00:28:00',
        distance: 5.05,
        dateTime: '05/12 20:10'
      },
      {
        steps: 9600,
        duration: '00:24:00',
        distance: 4.50,
        dateTime: '05/09 19:30'
      },
      {
        steps: 11500,
        duration: '00:29:00',
        distance: 5.40,
        dateTime: '05/06 18:20'
      },
      {
        steps: 10400,
        duration: '00:26:00',
        distance: 4.85,
        dateTime: '05/03 19:50'
      }
    ]
  },
  {
    monthTitle: '2026年2月',
    records: [
      {
        steps: 10560,
        duration: '00:27:00',
        distance: 4.95,
        dateTime: '04/28 18:10'
      },
      {
        steps: 11800,
        duration: '00:30:00',
        distance: 5.50,
        dateTime: '04/25 19:00'
      },
      {
        steps: 8900,
        duration: '00:23:00',
        distance: 4.10,
        dateTime: '04/22 19:45'
      },
      {
        steps: 12200,
        duration: '00:31:00',
        distance: 5.70,
        dateTime: '04/19 18:30'
      },
      {
        steps: 9500,
        duration: '00:24:00',
        distance: 4.45,
        dateTime: '04/16 20:00'
      },
      {
        steps: 11240,
        duration: '00:29:00',
        distance: 5.30,
        dateTime: '04/13 19:20'
      },
      {
        steps: 10300,
        duration: '00:26:00',
        distance: 4.82,
        dateTime: '04/10 18:40'
      },
      {
        steps: 12000,
        duration: '00:30:00',
        distance: 5.60,
        dateTime: '04/07 19:15'
      },
      {
        steps: 9800,
        duration: '00:25:00',
        distance: 4.60,
        dateTime: '04/04 18:50'
      },
      {
        steps: 11600,
        duration: '00:29:00',
        distance: 5.45,
        dateTime: '04/01 19:30'
      }
    ]
  }
];

/**
 * 步数历史统计数据
 */
export const STEP_HISTORY_STATISTICS: StepHistoryStatistics = {
  totalDuration: 7.5,
  totalCount: 8,
  totalCalories: 2863
};


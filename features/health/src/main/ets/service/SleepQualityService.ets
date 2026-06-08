/**
 * 睡眠质量评分服务
 * 基于深睡/浅睡/REM/清醒比例计算 0-100 睡眠质量评分
 */

export interface SleepQualityResult {
  score: number;
  deepRatio: number;
  lightRatio: number;
  remRatio: number;
  awakeRatio: number;
  totalHours: number;
  level: string;
  levelColor: string;
  advice: string;
}

@ObservedV2
export class SleepQualityService {
  private static _instance: SleepQualityService;
  @Trace todayResult: SleepQualityResult | null = null;
  @Trace weekScores: number[] = [];

  public static get instance(): SleepQualityService {
    if (!SleepQualityService._instance) {
      SleepQualityService._instance = new SleepQualityService();
    }
    return SleepQualityService._instance;
  }

  /**
   * 从睡眠数据计算质量评分
   * @param deepHours 深睡小时
   * @param deepMinutes 深睡分钟
   * @param lightHours 浅睡小时
   * @param lightMinutes 浅睡分钟
   * @param remMinutes REM分钟
   * @param awakeMinutes 清醒分钟
   */
  public calculate(deepHours: number, deepMinutes: number,
    lightHours: number, lightMinutes: number,
    remMinutes: number, awakeMinutes: number): SleepQualityResult {
    const deepTotal = deepHours * 60 + deepMinutes;
    const lightTotal = lightHours * 60 + lightMinutes;
    const total = deepTotal + lightTotal + remMinutes + awakeMinutes;

    if (total <= 0) {
      return this.getDefaultResult();
    }

    const deepRatio = deepTotal / total;
    const lightRatio = lightTotal / total;
    const remRatio = remMinutes / total;
    const awakeRatio = awakeMinutes / total;
    const totalHours = total / 60;

    // 评分算法
    let score = 0;

    // 深睡比例（理想 20-25%）：占比越高越好，最高 30 分
    if (deepRatio >= 0.20 && deepRatio <= 0.25) {
      score += 30;
    } else if (deepRatio >= 0.15) {
      score += 25;
    } else if (deepRatio >= 0.10) {
      score += 20;
    } else {
      score += 10;
    }

    // REM 比例（理想 20-25%）：最高 25 分
    if (remRatio >= 0.20 && remRatio <= 0.25) {
      score += 25;
    } else if (remRatio >= 0.15) {
      score += 20;
    } else if (remRatio >= 0.10) {
      score += 15;
    } else {
      score += 8;
    }

    // 清醒比例（越低越好）：最高 20 分
    if (awakeRatio <= 0.05) {
      score += 20;
    } else if (awakeRatio <= 0.10) {
      score += 15;
    } else if (awakeRatio <= 0.15) {
      score += 10;
    } else {
      score += 5;
    }

    // 总时长（理想 7-9 小时）：最高 25 分
    if (totalHours >= 7 && totalHours <= 9) {
      score += 25;
    } else if (totalHours >= 6) {
      score += 18;
    } else if (totalHours >= 5) {
      score += 12;
    } else {
      score += 5;
    }

    const level = score >= 85 ? '优秀' : score >= 70 ? '良好' : score >= 55 ? '一般' : '较差';
    const levelColor = score >= 85 ? '#4CAF50' : score >= 70 ? '#8BC34A' : score >= 55 ? '#FFC107' : '#F44336';
    const advice = this.getAdvice(score, deepRatio, awakeRatio, totalHours);

    this.todayResult = {
      score,
      deepRatio: Math.round(deepRatio * 100),
      lightRatio: Math.round(lightRatio * 100),
      remRatio: Math.round(remRatio * 100),
      awakeRatio: Math.round(awakeRatio * 100),
      totalHours: Math.round(totalHours * 10) / 10,
      level,
      levelColor,
      advice
    };

    return this.todayResult;
  }

  /**
   * 生成 Mock 睡眠质量数据
   */
  public generateMock(): void {
    // 模拟 7 天的睡眠评分
    this.weekScores = [78, 82, 65, 88, 75, 90, 85];
    // 今天的结果
    this.todayResult = {
      score: 85,
      deepRatio: 22,
      lightRatio: 45,
      remRatio: 23,
      awakeRatio: 10,
      totalHours: 7.5,
      level: '良好',
      levelColor: '#8BC34A',
      advice: '深睡比例良好，建议保持规律作息时间。'
    };
  }

  private getAdvice(score: number, deepRatio: number, awakeRatio: number, totalHours: number): string {
    if (deepRatio < 0.15) {
      return '深睡比例偏低，建议睡前避免使用电子设备，保持卧室温度适宜。';
    }
    if (awakeRatio > 0.10) {
      return '夜间清醒次数较多，建议减少晚间饮水，避免咖啡因。';
    }
    if (totalHours < 7) {
      return '睡眠时间不足，建议提前入睡，保证 7-8 小时睡眠。';
    }
    if (score >= 85) {
      return '睡眠质量优秀，继续保持规律的作息习惯！';
    }
    return '睡眠质量良好，建议保持固定的入睡和起床时间。';
  }

  private getDefaultResult(): SleepQualityResult {
    return {
      score: 0, deepRatio: 0, lightRatio: 0, remRatio: 0, awakeRatio: 0,
      totalHours: 0, level: '无数据', levelColor: '#999', advice: '暂无睡眠数据'
    };
  }
}

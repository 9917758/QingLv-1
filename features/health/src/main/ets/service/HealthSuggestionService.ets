/**
 * 健康建议服务
 * 根据当前健康数据动态生成个性化建议
 * 支持本地规则 + 后端 API AI 分析
 */
import { HttpUtil, AuthToken } from 'common';
import type { ApiResponse, ApiAnalysisReport } from 'common';
import { HealthDataInputModel } from '../viewmodel/HealthDataInputModel';

export interface HealthSuggestion {
  icon: string;
  title: string;
  content: string;
  color: string;
  priority: number;
}

@ObservedV2
export class HealthSuggestionService {
  private static _instance: HealthSuggestionService;
  @Trace suggestions: HealthSuggestion[] = [];

  public static get instance(): HealthSuggestionService {
    if (!HealthSuggestionService._instance) {
      HealthSuggestionService._instance = new HealthSuggestionService();
    }
    return HealthSuggestionService._instance;
  }

  /** 本地规则生成建议（兼容旧调用） */
  public generate(inputVM: HealthDataInputModel, stepCount: number, waterCount: number, waterGoal: number): void {
    const list: HealthSuggestion[] = [];

    if (inputVM.bmiValue >= 28) {
      list.push({ icon: '⚖️', title: '体重管理', content: `BMI ${inputVM.bmiValue}（肥胖），建议控制每日热量摄入，增加有氧运动，每周减重 0.5-1 公斤为宜。`, color: '#F44336', priority: 10 });
    } else if (inputVM.bmiValue >= 24) {
      list.push({ icon: '⚖️', title: '体重管理', content: `BMI ${inputVM.bmiValue}（偏胖），建议减少高热量食物，每天保持 30 分钟以上运动。`, color: '#FF9800', priority: 8 });
    } else if (inputVM.bmiValue > 0 && inputVM.bmiValue < 18.5) {
      list.push({ icon: '⚖️', title: '营养补充', content: `BMI ${inputVM.bmiValue}（偏瘦），建议适当增加优质蛋白和碳水化合物摄入。`, color: '#2196F3', priority: 8 });
    }

    if (inputVM.bloodPressureSystolic >= 140 || inputVM.bloodPressureDiastolic >= 90) {
      list.push({ icon: '❤️', title: '血压关注', content: `血压 ${inputVM.bloodPressureSystolic}/${inputVM.bloodPressureDiastolic} mmHg 偏高，建议低盐饮食、规律作息，必要时就医。`, color: '#F44336', priority: 9 });
    }

    if (inputVM.heartRate > 100) {
      list.push({ icon: '💓', title: '心率偏快', content: `静息心率 ${inputVM.heartRate} 次/分偏高，建议避免咖啡因，保持充足睡眠。`, color: '#FF9800', priority: 7 });
    } else if (inputVM.heartRate > 0 && inputVM.heartRate < 50) {
      list.push({ icon: '💓', title: '心率偏慢', content: `心率 ${inputVM.heartRate} 次/分偏低，如无不适属正常，如有头晕请及时就医。`, color: '#2196F3', priority: 6 });
    }

    if (inputVM.bloodSugar > 7.0) {
      list.push({ icon: '🩸', title: '血糖偏高', content: `血糖 ${inputVM.bloodSugar} mmol/L 偏高，建议控制碳水摄入，餐后适当运动。`, color: '#F44336', priority: 9 });
    }

    if (stepCount < 5000) {
      list.push({ icon: '🚶', title: '运动不足', content: `今日步数 ${stepCount}，建议增加步行，目标 8000 步以上。`, color: '#FF9800', priority: 6 });
    } else if (stepCount >= 10000) {
      list.push({ icon: '🎉', title: '运动达标', content: `今日步数 ${stepCount}，运动量充足，继续保持！`, color: '#4CAF50', priority: 3 });
    }

    if (waterCount < waterGoal * 0.5) {
      list.push({ icon: '💧', title: '饮水不足', content: `今日仅喝 ${waterCount} 杯水，目标 ${waterGoal} 杯，记得多喝水。`, color: '#2196F3', priority: 5 });
    }

    if (list.length === 0) {
      list.push({ icon: '✅', title: '状态良好', content: '各项指标正常，继续保持良好的生活习惯！每日保持运动和充足饮水。', color: '#4CAF50', priority: 1 });
    }

    this.suggestions = list.sort((a, b) => b.priority - a.priority);
  }

  /** 从后端 API 获取 AI 建议（异步） */
  public async loadFromApi(): Promise<void> {
    if (!AuthToken.isLoggedIn()) return;
    const resp: ApiResponse<ApiAnalysisReport> = await HttpUtil.get<ApiAnalysisReport>('/api/analysis/report');
    if (resp.data) {
      const report = resp.data;
      const list: HealthSuggestion[] = [];

      // concerns → 高优先级建议
      for (let i = 0; i < report.concerns.length; i++) {
        list.push({
          icon: '⚠️', title: '需关注',
          content: report.concerns[i],
          color: '#FF9800', priority: 9 - i
        });
      }
      // suggestions → 建议
      for (let i = 0; i < report.suggestions.length; i++) {
        list.push({
          icon: '💡', title: '健康建议',
          content: report.suggestions[i],
          color: '#2196F3', priority: 6 - i
        });
      }
      // highlights → 亮点
      for (let i = 0; i < report.highlights.length; i++) {
        list.push({
          icon: '✅', title: '做得好',
          content: report.highlights[i],
          color: '#4CAF50', priority: 2
        });
      }

      if (list.length > 0) {
        this.suggestions = list.sort((a, b) => b.priority - a.priority);
      }
    }
  }

  /** Mock 建议数据 */
  public generateMock(): void {
    this.suggestions = [
      { icon: '🚶', title: '运动建议', content: '今日步数 6800，距离目标还差 1200 步，晚饭后散步 20 分钟即可达标。', color: '#FF9800', priority: 6 },
      { icon: '💧', title: '饮水提醒', content: '今日已喝 5 杯水，距离目标还差 3 杯，记得补充水分。', color: '#2196F3', priority: 5 },
      { icon: '✅', title: '血压正常', content: '今日血压 122/80 mmHg，在正常范围内，继续保持低盐饮食。', color: '#4CAF50', priority: 3 },
      { icon: '💤', title: '睡眠建议', content: '昨晚睡眠 7.5 小时，质量良好。建议今晚 23:00 前入睡。', color: '#9C27B0', priority: 4 }
    ];
  }
}

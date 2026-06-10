/**
 * 成就徽章服务
 * 追踪用户达成的各项健康目标
 */

export interface Achievement {
  id: string;
  icon: string;
  title: string;
  description: string;
  isUnlocked: boolean;
  unlockedDate: string;
  progress: number;
  target: number;
}

@ObservedV2
export class AchievementService {
  private static _instance: AchievementService;
  @Trace achievements: Achievement[] = [];

  public static get instance(): AchievementService {
    if (!AchievementService._instance) {
      AchievementService._instance = new AchievementService();
    }
    return AchievementService._instance;
  }

  /** 清除内存缓存 */
  public clearCache(): void {
    this.achievements = [];
  }

  /**
   * 初始化所有成就定义
   */
  public init(): void {
    this.achievements = [
      { id: 'streak_7', icon: '🔥', title: '坚持不懈', description: '连续打卡 7 天', isUnlocked: false, unlockedDate: '', progress: 0, target: 7 },
      { id: 'streak_30', icon: '🏆', title: '月度达人', description: '连续打卡 30 天', isUnlocked: false, unlockedDate: '', progress: 0, target: 30 },
      { id: 'water_master', icon: '💧', title: '水分充足', description: '连续 7 天达成饮水目标', isUnlocked: false, unlockedDate: '', progress: 0, target: 7 },
      { id: 'all_metrics', icon: '📊', title: '数据达人', description: '录入全部 6 项健康指标', isUnlocked: false, unlockedDate: '', progress: 0, target: 6 },
      { id: 'weight_goal', icon: '🎯', title: '目标达成', description: '达到设定的目标体重', isUnlocked: false, unlockedDate: '', progress: 0, target: 1 },
      { id: 'steps_10k', icon: '👟', title: '万步达人', description: '单日步数达到 10000 步', isUnlocked: false, unlockedDate: '', progress: 0, target: 10000 },
      { id: 'knowledge_10', icon: '📚', title: '知识渊博', description: '阅读 10 篇健康知识文章', isUnlocked: false, unlockedDate: '', progress: 0, target: 10 },
      { id: 'report_viewer', icon: '📈', title: '数据分析师', description: '查看周报和月报', isUnlocked: false, unlockedDate: '', progress: 0, target: 2 }
    ];
  }

  /**
   * 更新成就进度
   */
  public updateProgress(id: string, progress: number): void {
    const achievement = this.achievements.find(a => a.id === id);
    if (!achievement) return;
    achievement.progress = Math.min(progress, achievement.target);
    if (achievement.progress >= achievement.target && !achievement.isUnlocked) {
      achievement.isUnlocked = true;
      const d = new Date();
      achievement.unlockedDate = `${d.getMonth()+1}/${d.getDate()}`;
    }
  }

  /**
   * 解锁成就
   */
  public unlock(id: string): void {
    const achievement = this.achievements.find(a => a.id === id);
    if (achievement && !achievement.isUnlocked) {
      achievement.isUnlocked = true;
      achievement.progress = achievement.target;
      const d = new Date();
      achievement.unlockedDate = `${d.getMonth()+1}/${d.getDate()}`;
    }
  }

  /**
   * 获取已解锁数量
   */
  public getUnlockedCount(): number {
    return this.achievements.filter(a => a.isUnlocked).length;
  }

  /**
   * Mock 模式下解锁部分成就
   */
  public generateMock(): void {
    this.init();
    // 新用户无任何解锁，仅展示成就定义
  }
}

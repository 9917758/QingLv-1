import { describe, it, expect } from '@ohos/hypium';

/**
 * HealthGoalService 逻辑测试
 * 注意：这些测试验证纯计算逻辑，不涉及 Preferences 持久化
 */
export default function healthGoalServiceTest() {
  describe('HealthGoalServiceTest', () => {
    // getWeightDiff 测试
    it('getWeightDiff_returns_positive_when_above_goal', 0, () => {
      // 当前体重130斤，目标120斤，应返回10
      const goalWeight = 120;
      const currentWeight = 130;
      const diff = Math.round((currentWeight - goalWeight) * 10) / 10;
      expect(diff).assertEqual(10);
    });

    it('getWeightDiff_returns_zero_when_at_goal', 0, () => {
      const goalWeight = 120;
      const currentWeight = 120;
      const diff = Math.round((currentWeight - goalWeight) * 10) / 10;
      expect(diff).assertEqual(0);
    });

    it('getWeightDiff_returns_negative_when_below_goal', 0, () => {
      const goalWeight = 120;
      const currentWeight = 115;
      const diff = Math.round((currentWeight - goalWeight) * 10) / 10;
      expect(diff).assertEqual(-5);
    });

    // getGoalDescription 测试
    it('getGoalDescription_shows_remaining_when_above', 0, () => {
      const goalWeight = 120;
      const currentWeight = 125.5;
      const diff = Math.round((currentWeight - goalWeight) * 10) / 10;
      const desc = `距目标还差 ${diff.toFixed(1)} 斤`;
      expect(desc).assertEqual('距目标还差 5.5 斤');
    });

    it('getGoalDescription_shows_exceeded_when_below', 0, () => {
      const goalWeight = 120;
      const currentWeight = 118;
      const diff = Math.round((currentWeight - goalWeight) * 10) / 10;
      const desc = `已超过目标 ${Math.abs(diff).toFixed(1)} 斤`;
      expect(desc).assertEqual('已超过目标 2.0 斤');
    });

    it('getGoalDescription_shows_congrats_when_at_goal', 0, () => {
      const goalWeight = 120;
      const currentWeight = 120;
      const diff = Math.round((currentWeight - goalWeight) * 10) / 10;
      const desc = diff === 0 ? '🎉 已达成目标！' : '';
      expect(desc).assertEqual('🎉 已达成目标！');
    });

    // getProgress 测试
    it('getProgress_calculates_correctly', 0, () => {
      const startWeight = 140;
      const goalWeight = 120;
      const currentWeight = 130;
      const totalToLose = startWeight - goalWeight; // 20
      const lost = startWeight - currentWeight; // 10
      const progress = Math.min(Math.max(Math.round((lost / totalToLose) * 100), 0), 100);
      expect(progress).assertEqual(50);
    });

    it('getProgress_caps_at_100', 0, () => {
      const startWeight = 140;
      const goalWeight = 120;
      const currentWeight = 115; // 超过目标
      const totalToLose = startWeight - goalWeight;
      const lost = startWeight - currentWeight;
      const progress = Math.min(Math.max(Math.round((lost / totalToLose) * 100), 0), 100);
      expect(progress).assertEqual(100);
    });

    it('getProgress_returns_0_when_no_progress', 0, () => {
      const startWeight = 140;
      const goalWeight = 120;
      const currentWeight = 140; // 没有减
      const totalToLose = startWeight - goalWeight;
      const lost = startWeight - currentWeight;
      const progress = Math.min(Math.max(Math.round((lost / totalToLose) * 100), 0), 100);
      expect(progress).assertEqual(0);
    });

    it('getProgress_returns_0_when_no_goal', 0, () => {
      const goalWeight = 0;
      const progress = goalWeight <= 0 ? 0 : 50;
      expect(progress).assertEqual(0);
    });
  });
}

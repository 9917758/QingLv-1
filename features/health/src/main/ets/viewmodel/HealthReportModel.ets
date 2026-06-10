/**
 * 健康报告 Model
 */
import { HealthReportData, HealthMetricItem, ReportMenuItem, BMILevel } from '../types/HealthReportTypes';
import { HealthDataInputModel } from './HealthDataInputModel';
import { I18nUtil, TimeUtil, UserInfo, HttpUtil, AuthToken } from 'common';
import type { ApiResponse, ApiDashboard } from 'common';
import { PersistenceV2 } from '@kit.ArkUI';

@ObservedV2
export class HealthReportModel {
  private static _instance: HealthReportModel;
  @Trace reportData: HealthReportData = {} as HealthReportData;
  @Trace showReportMenu: boolean = false;
  private healthDataInputModel: HealthDataInputModel | null = null;
  private userInfo: UserInfo | null = null;

  public static get instance(): HealthReportModel {
    if (!HealthReportModel._instance) {
      HealthReportModel._instance = new HealthReportModel();
      // 获取 HealthDataInputModel 和 UserInfo 实例
      HealthReportModel._instance.healthDataInputModel =
        PersistenceV2.connect(HealthDataInputModel, () => new HealthDataInputModel())!;
      HealthReportModel._instance.userInfo =
        PersistenceV2.connect(UserInfo, () => new UserInfo())!;
      HealthReportModel._instance.loadHealthData();
    }
    return HealthReportModel._instance;
  }

  /**
   * 从 HealthDataInputModel 和 UserInfo 加载实际数据
   */
  private loadHealthData(): void {
    // 检查实例是否已初始化
    if (!this.healthDataInputModel || !this.userInfo) {
      return;
    }

    // 获取身高和体重（都从 UserInfo 中读取）
    const height: number = this.userInfo.height;
    const weight: number = this.userInfo.weight;
    const birthday: string = this.userInfo.birthday;
    const sex: string = this.userInfo.gender || '男'; // gender 字段为 '男' 或 '女'

    // 计算年龄
    const age: number = this.calculateAge(birthday);

    // 计算 BMI
    const bmi: number = height > 0 && weight > 0 ?
      this.healthDataInputModel.bmiCalculator(height, weight) : 0;

    // 计算体脂率
    const bodyFat: number = height > 0 && weight > 0 && birthday ?
      this.healthDataInputModel.getBodyFatPercentage(birthday, bmi, sex) : 0;

    // 计算脂肪重量
    const fatMass: number = weight > 0 && bodyFat > 0 ? (weight * bodyFat / 100) : 0;

    // 确定 BMI 等级
    const bmiLevel: BMILevel = this.getBMILevelFromValue(bmi);

    // 计算健康评分 (简化版)
    const score: number = this.calculateHealthScore(bmi, bodyFat, this.healthDataInputModel.heartRate,
      this.healthDataInputModel.bloodPressureSystolic, this.healthDataInputModel.bloodPressureDiastolic);

    // 真实时间
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = (now.getMonth() + 1).toString().padStart(2, '0');
    const dd = now.getDate().toString().padStart(2, '0');
    const HH = now.getHours().toString().padStart(2, '0');
    const MM = now.getMinutes().toString().padStart(2, '0');
    const reportDateStr = `${yyyy}/${mm}/${dd} ${HH}:${MM}`;

    // 生成报告数据
    this.reportData = {
      userName: this.userInfo.nickName || '用户',
      score: score,
      percentile: this.calculatePercentile(score),
      reportDate: reportDateStr,
      weight: weight,
      height: height,
      age: age,
      bmi: bmi,
      bmiLevel: bmiLevel,
      bodyFat: bodyFat,
      fatMass: Math.round(fatMass * 10) / 10,
      heartRate: this.healthDataInputModel.heartRate,
      bloodPressureSystolic: this.healthDataInputModel.bloodPressureSystolic,
      bloodPressureDiastolic: this.healthDataInputModel.bloodPressureDiastolic,
      bloodGlucose: this.healthDataInputModel.bloodSugar,
      bmiTarget: this.calculateBMITarget(bmi),
      bmiAdvice: this.generateBMIAdvice(bmiLevel)
    } as HealthReportData;
  }

  /**
   * 计算年龄
   */
  private calculateAge(birthday: string): number {
    if (!birthday) {
      return 0;
    }
    try {
      const birthDate = TimeUtil.parseDate(birthday, TimeUtil.PATTERN_DATE_HYPHEN);
      const currentTime = new Date().getTime();
      const age = (currentTime - birthDate) / (365 * 24 * 60 * 60 * 1000);
      return Math.floor(age);
    } catch (e) {
      return 0;
    }
  }

  /**
   * 根据 BMI 值确定等级
   */
  private getBMILevelFromValue(bmi: number): BMILevel {
    if (bmi < 18.5) {
      return BMILevel.LOW;
    } else if (bmi >= 18.5 && bmi < 25) {
      return BMILevel.NORMAL;
    } else if (bmi >= 25 && bmi < 30) {
      return BMILevel.HIGH;
    } else {
      return BMILevel.OBESE;
    }
  }

  /**
   * 计算健康评分（简化版）
   */
  private calculateHealthScore(bmi: number, bodyFat: number, heartRate: number, systolic: number,
    diastolic: number): number {
    if (bmi === 0) {
      return 0;
    }

    let score = 100;

    // BMI 扣分
    if (bmi < 18.5 || bmi >= 30) {
      score -= 20;
    } else if (bmi >= 25 && bmi < 30) {
      score -= 10;
    }

    // 体脂率扣分
    if (bodyFat > 30) {
      score -= 15;
    } else if (bodyFat > 25) {
      score -= 10;
    }

    // 心率扣分
    if (heartRate > 0 && (heartRate < 60 || heartRate > 100)) {
      score -= 10;
    }

    // 血压扣分
    if (systolic > 0 && (systolic < 90 || systolic > 140)) {
      score -= 10;
    }
    if (diastolic > 0 && (diastolic < 60 || diastolic > 90)) {
      score -= 5;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 计算百分位
   */
  private calculatePercentile(score: number): number {
    // 简化算法：分数越高，百分位越高
    return Math.min(99, Math.floor(score * 0.9));
  }

  /**
   * 计算 BMI 目标值
   */
  private calculateBMITarget(currentBMI: number): number {
    if (currentBMI < 18.5) {
      return 20.0;
    } else if (currentBMI >= 25) {
      return 23.0;
    } else {
      return currentBMI;
    }
  }

  /**
   * 生成 BMI 建议
   */
  private generateBMIAdvice(bmiLevel: BMILevel): string {
    switch (bmiLevel) {
      case BMILevel.LOW:
        return I18nUtil.t('health.bmi_advice_underweight');
      case BMILevel.NORMAL:
        return I18nUtil.t('health.bmi_advice_normal');
      case BMILevel.HIGH:
        return I18nUtil.t('health.bmi_advice_overweight');
      case BMILevel.OBESE:
        return I18nUtil.t('health.bmi_advice_obesity');
      default:
        return I18nUtil.t('health.bmi_advice_default');
    }
  }

  /**
   * 刷新健康数据
   */
  public refreshHealthData(): void {
    this.loadHealthData();
  }

  /**
   * 获取健康指标列表
   */
  public getHealthMetrics(): HealthMetricItem[] {
    const metrics: HealthMetricItem[] = [
      {
        icon: $r('app.media.health_bmi'),
        label: 'BMI',
        value: this.reportData.bmi.toFixed(1),
        unit: '',
        backgroundColor: '#FFF5F5F5'
      } as HealthMetricItem,
      {
        icon: $r('app.media.health_bmi_fatPercentage'),
        label: $r('app.string.health_body_fat_rate'),
        value: this.reportData.bodyFat.toFixed(1),
        unit: '%',
        backgroundColor: '#FFF5F5F5'
      } as HealthMetricItem,
      {
        icon: $r('app.media.health_bmi_fatWeight'),
        label: $r('app.string.health_fat_weight'),
        value: this.reportData.fatMass.toFixed(1),
        unit: '',
        backgroundColor: '#FFF5F5F5'
      } as HealthMetricItem,
      {
        icon: $r('app.media.health_bmi_heart'),
        label: $r('app.string.health_heartrate'),
        value: this.reportData.heartRate.toString(),
        unit: '次/分',
        backgroundColor: '#FFF5F5F5'
      } as HealthMetricItem,
      {
        icon: $r('app.media.health_bmi_bloodpressure'),
        label: $r('app.string.health_bloodpressure'),
        value: `${this.reportData.bloodPressureSystolic}/${this.reportData.bloodPressureDiastolic}`,
        unit: 'mmHg',
        backgroundColor: '#FFF5F5F5'
      } as HealthMetricItem,
      {
        icon: $r('app.media.health_bmi_bloodglucose'),
        label: $r('app.string.health_blood_sugar'),
        value: this.reportData.bloodGlucose.toFixed(1),
        unit: 'mmol/L',
        backgroundColor: '#FFF5F5F5'
      } as HealthMetricItem
    ];
    return metrics;
  }

  /**
   * 获取报告类型菜单
   */
  public getReportMenuItems(): ReportMenuItem[] {
    const menuItems: ReportMenuItem[] = [
      { label: $r('app.string.health_history_title'), value: 'history' } as ReportMenuItem,
      { label: $r('app.string.health_weekly_report'), value: 'weekly' } as ReportMenuItem,
      { label: $r('app.string.health_monthly_report'), value: 'monthly' } as ReportMenuItem,
      { label: $r('app.string.health_export_csv'), value: 'export_csv' } as ReportMenuItem,
      { label: $r('app.string.health_export_json'), value: 'export_json' } as ReportMenuItem
    ];
    return menuItems;
  }

  /**
   * 获取BMI等级文本
   */
  public getBMILevelText(): string {
    switch (this.reportData.bmiLevel) {
      case BMILevel.LOW:
        return I18nUtil.t('health.bmi_type_underweight');
      case BMILevel.NORMAL:
        return I18nUtil.t('health.bmi_type_normal');
      case BMILevel.HIGH:
        return I18nUtil.t('health.bmi_type_overweight');
      case BMILevel.OBESE:
        return I18nUtil.t('health.bmi_type_obesity');
      default:
        return I18nUtil.t('health.bmi_type_normal');
    }
  }

  /**
   * 获取BMI等级颜色
   */
  public getBMILevelColor(): ResourceColor {
    switch (this.reportData.bmiLevel) {
      case BMILevel.LOW:
        return '#FFA800';
      case BMILevel.NORMAL:
        return '#00d2b9';
      case BMILevel.HIGH:
        return '#FF6B00';
      case BMILevel.OBESE:
        return '#F44336';
      default:
        return '#00d2b9';
    }
  }

  /**
   * 从后端 API 加载仪表盘数据（异步）
   */
  public async loadFromApi(): Promise<void> {
    if (!AuthToken.isLoggedIn()) return;
    const resp: ApiResponse<ApiDashboard> = await HttpUtil.get<ApiDashboard>('/api/health/dashboard');
    if (resp.data) {
      const d = resp.data;
      const now = new Date();
      const reportDateStr = `${now.getFullYear()}/${(now.getMonth() + 1).toString().padStart(2, '0')}/${now.getDate().toString().padStart(2, '0')} ${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

      this.reportData = {
        userName: this.userInfo?.nickName || '用户',
        score: d.today_score,
        percentile: this.calculatePercentile(d.today_score),
        reportDate: reportDateStr,
        weight: d.weight,
        height: this.userInfo?.height || 0,
        age: this.userInfo?.birthday ? this.calculateAge(this.userInfo.birthday) : 0,
        bmi: d.bmi,
        bmiLevel: this.getBMILevelFromValue(d.bmi),
        bodyFat: d.body_fat_percentage,
        fatMass: Math.round(d.weight * d.body_fat_percentage / 100 * 10) / 10,
        heartRate: d.heart_rate,
        bloodPressureSystolic: d.blood_pressure_systolic,
        bloodPressureDiastolic: d.blood_pressure_diastolic,
        bloodGlucose: d.blood_sugar,
        bmiTarget: this.calculateBMITarget(d.bmi),
        bmiAdvice: this.generateBMIAdvice(this.getBMILevelFromValue(d.bmi))
      } as HealthReportData;
    }
  }

  /**
   * 切换报告菜单显示
   */
  public toggleReportMenu(): void {
    this.showReportMenu = !this.showReportMenu;
  }

  /**
   * 关闭报告菜单
   */
  public closeReportMenu(): void {
    this.showReportMenu = false;
  }

  /**
   * 检查是否有健康数据
   * 判断标准：体重和身高不为0（这两个是计算BMI的必要条件）
   */
  public hasHealthData(): boolean {
    return this.reportData.weight > 0 && this.reportData.height > 0;
  }
}


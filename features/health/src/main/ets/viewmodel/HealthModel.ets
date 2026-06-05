import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { BaseViewModel, BreakpointModel, TimeUtil, USE_MOCK_DATA } from 'common';
import { healthCard } from '../constants/constants';
import { BreakpointNameEnum } from 'common/src/main/ets/constant/GridRowColSetting';
import { HealthCardModel } from './HealthCardModel';
import { HealthDataInputModel } from './HealthDataInputModel';
import { PairedDeviceMacList } from 'device';

@ObservedV2
export class HealthModel extends BaseViewModel {
  @Trace activityHeat = 260; // 活动热量
  @Trace exerciseDuration = 20; // 锻炼时长
  @Trace travelDistance = 2.5; // 运动距离
  standardActivityHeat = 500; // 标准活动热量
  standardExerciseDuration = 60; // 标准锻炼时长
  standardTravelDistance = 5; // 标准运动距离
  @Trace stepCount = 2739; //今日步数
  @Trace isReportData = false; // 健康报告是否有数据
  @Trace breakPointModel: BreakpointModel =
    AppStorageV2.connect(BreakpointModel, () => new BreakpointModel())!;
  @Trace cardList = healthCard;
  @Trace dataVM = new HealthCardModel();
  @Trace reportVM = new HealthCardModel();
  @Trace sleepVM = new HealthCardModel();
  @Trace bloodPreVM = new HealthCardModel();
  @Trace heartRateVM = new HealthCardModel();
  @Trace bloodSugarVM = new HealthCardModel();
  @Trace inputVM: HealthDataInputModel =
    PersistenceV2.connect(HealthDataInputModel, () => new HealthDataInputModel())!;
  @Trace macList: PairedDeviceMacList =
    PersistenceV2.connect(PairedDeviceMacList, () => new PairedDeviceMacList())!;
  private static _instance: HealthModel;

  public static get instance() {
    if (!HealthModel._instance) {
      HealthModel._instance = new HealthModel();
      // Mock 模式下为 inputVM 注入虚拟数据（与 mock 数据文件保持一致）
      if (USE_MOCK_DATA) {
        HealthModel._instance.initMockInputData();
      }
      HealthModel._instance.initHealthData();
      HealthModel._instance.initDeviceData();
    }
    return HealthModel._instance;
  }

  /**
   * Mock 模式下注入虚拟健康数据
   * 每次进入应用均重新生成，模拟设备"刚刚完成新一轮测量"
   * 加入 ±5-10% 随机抖动，模拟真实数据采集的自然波动
   */
  private initMockInputData() {
    const now = new Date();
    const timeStr = `今天 ${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    // 心率：基于时间段的基线 + 微小浮动，模拟静息心率的自然变化
    // 清晨(6-12点)静息心率偏低 65-72，下午(12-18点)略高 70-78，晚间回落 67-75
    const hour = now.getHours();
    const hrBase = (hour >= 6 && hour < 12) ? 68 : (hour >= 12 && hour < 18) ? 73 : 70;
    this.inputVM.heartRate = hrBase + Math.floor(Math.random() * 7);
    this.inputVM.heartRateTime = timeStr;

    // 血压：以正常值 120/80 为基准 ±6 浮动
    this.inputVM.bloodPressureSystolic = 116 + Math.floor(Math.random() * 9);
    this.inputVM.bloodPressureDiastolic = 77 + Math.floor(Math.random() * 7);
    this.inputVM.bloodPressureTime = timeStr;

    // 血糖：空腹正常范围 4.8-6.2，用整数运算避免浮点精度问题
    const sugarTenths = 48 + Math.floor(Math.random() * 15); // 48~62 → 4.8~6.2
    this.inputVM.bloodSugar = Number((sugarTenths / 10).toFixed(1));
    this.inputVM.bloodSugarTime = timeStr;
  }

  initDeviceData() {
    const now = new Date();
    this.dataVM.img = $r('app.media.health_data_icon');
    this.dataVM.title = '健康数据';
    this.dataVM.type = 1;
    this.dataVM.icon = '';
    this.dataVM.timeStatus = TimeUtil.formatDate(new Date().getTime(), TimeUtil.PATTERN_DATE_TIME_CN_MONTH);

    this.reportVM.img = $r('app.media.health_report_icon');
    this.reportVM.title = '健康报告';
    this.reportVM.type = 2;
    this.reportVM.icon = '';
    this.reportVM.timeStatus = TimeUtil.formatDate(new Date().getTime(), TimeUtil.PATTERN_DATE_CN_WITHOUT_YEAR);


    this.sleepVM.img = $r('app.media.health_sleep_icon');
    this.sleepVM.title = '睡眠';
    this.sleepVM.type = 3;
    this.sleepVM.icon = $r('app.media.sleep_icon');

    if (USE_MOCK_DATA || this.macList.pairedList.length > 0) {
      this.dataVM.value = '良好';
      this.dataVM.desc = '今天身体状态';

      if (this.userInfo.weight > 0 && this.userInfo.height > 0) {
        this.reportVM.value = '良好';
        this.reportVM.desc = '今天身体状态';
      } else {
        this.reportVM.desc = '暂无数据';
      }

      this.sleepVM.value = '';
      // 睡眠数据：基于日期生成，一天内稳定，不同天之间有微小差异
      // 模拟每晚 6.5~8.5 小时的睡眠时长
      const totalSleepMinutes = 390 + (now.getDate() * 13 + now.getMonth() * 7) % 120;
      const sleepH = Math.floor(totalSleepMinutes / 60);
      const sleepM = totalSleepMinutes % 60;
      this.sleepVM.desc = `${sleepH}时${sleepM}分`;
      this.sleepVM.timeStatus = '目标 8小时 ｜良好';

      // 运动数据：基于当天时间累积增长（模拟真实全天活动规律）
      // 假设用户 8:00 起床开始活动，22:00 结束，目标日步数 ~8000
      const minutesSinceMidnight = now.getHours() * 60 + now.getMinutes();
      const activeMinutes = Math.max(0, minutesSinceMidnight - 8 * 60); // 8点后开始累积
      const dayProgress = Math.min(activeMinutes / (14 * 60), 1.0); // 8:00-22:00 14小时活跃窗口
      this.stepCount = Math.floor(500 + dayProgress * 7500);
      this.activityHeat = Math.floor(30 + dayProgress * 280);
      this.exerciseDuration = Math.floor(2 + dayProgress * 45);
      this.travelDistance = Math.round((0.3 + dayProgress * 3.7) * 10) / 10;

    } else {
      this.dataVM.value = '';
      this.dataVM.desc = '暂无数据';
      this.reportVM.value = '';
      this.reportVM.desc = '暂无数据';
      this.sleepVM.value = '';
      this.sleepVM.desc = '暂无数据';
      this.sleepVM.timeStatus = TimeUtil.formatDate(new Date().getTime(), TimeUtil.PATTERN_DATE_CN_WITHOUT_YEAR);

      this.activityHeat = 0;
      this.exerciseDuration = 0;
      this.travelDistance = 0;
      this.stepCount = 0;
    }
  }

  initHealthData() {
    this.bloodPreVM.img = $r('app.media.health_blood_pre_icon');
    this.bloodPreVM.title = '血压';
    this.bloodPreVM.type = 4;
    this.bloodPreVM.icon = $r('app.media.blood_pre_icon');

    this.heartRateVM.img = $r('app.media.health_heart_rate_icon');
    this.heartRateVM.title = '心率';
    this.heartRateVM.type = 5;
    this.heartRateVM.icon = $r('app.media.heart_rate_icon');

    this.bloodSugarVM.img = $r('app.media.health_blood_sugar_icon');
    this.bloodSugarVM.title = '血糖';
    this.bloodSugarVM.type = 6;
    this.bloodSugarVM.icon = $r('app.media.blood_sugar_icon');

    if (USE_MOCK_DATA || this.macList.pairedList.length > 0) {
      this.bloodPreVM.value = this.inputVM.bloodPressureSystolic > 0 ?
      this.inputVM.bloodPressureSystolic.toString() : '--';
      this.bloodPreVM.diastolicValue = this.inputVM.bloodPressureDiastolic > 0 ?
      this.inputVM.bloodPressureDiastolic.toString() : '--';
      this.bloodPreVM.desc = 'mmHg';
      this.bloodPreVM.timeStatus = this.inputVM.bloodPressureTime;

      this.heartRateVM.value = this.inputVM.heartRate > 0 ? this.inputVM.heartRate.toString() : '--'
      this.heartRateVM.desc = '次/分';
      this.heartRateVM.timeStatus = this.inputVM.heartRateTime;

      this.bloodSugarVM.value = this.inputVM.bloodSugar > 0 ? this.inputVM.bloodSugar.toString() : '--';
      this.bloodSugarVM.desc = 'mmol/L';
      this.bloodSugarVM.timeStatus = this.inputVM.bloodSugarTime;
    } else {
      this.bloodPreVM.value = '';
      this.bloodPreVM.desc = '暂无数据';
      this.bloodPreVM.timeStatus = TimeUtil.formatDate(new Date().getTime(), TimeUtil.PATTERN_DATE_CN_WITHOUT_YEAR);
      this.heartRateVM.value = '';
      this.heartRateVM.desc = '暂无数据';
      this.heartRateVM.timeStatus = TimeUtil.formatDate(new Date().getTime(), TimeUtil.PATTERN_DATE_CN_WITHOUT_YEAR);
      this.bloodSugarVM.value = '';
      this.bloodSugarVM.desc = '暂无数据';
      this.bloodSugarVM.timeStatus = TimeUtil.formatDate(new Date().getTime(), TimeUtil.PATTERN_DATE_CN_WITHOUT_YEAR);
    }
  }

  @Computed
  get getFoldShow(): boolean {
    if (this.breakPointModel.currentBreakpoint === BreakpointNameEnum.SM) {
      return false;
    } else {
      return true;
    }
  }
}
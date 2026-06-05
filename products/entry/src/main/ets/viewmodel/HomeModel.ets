import { PersistenceV2 } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { Constants, GlobalContext, OHDialog, OHDialogModel, PreferenceUtil, TimeUtil, USE_MOCK_DATA } from 'common';
import { PairedDeviceMacList } from 'device';
import { SkipStepModel } from 'person';
import { TAB_CONFIG } from '../constants/constants';
import { TabSingleItem } from './TabSingleItem';

const REMINDER_STORAGE_KEY = 'reminder_plans';
const REMINDER_CHECKED_KEY = 'reminder_checked_today';

interface ReminderPlan {
  id: string;
  type: number; // 0=饮水, 1=用药
  name: string;
  time: string; // HH:mm
  dosage: string;
  isEnabled: boolean;
  isCheckedToday: boolean;
}

@Builder
function homeModelDialogBuilder(vm: OHDialogModel) {
  Text(vm.subtitle)
    .fontSize($r('sys.float.Body_M'))
    .fontColor(Color.Black)
    .lineHeight($r('app.float.vp_22'))
    .maxLines(-1)

  Blank().height($r('app.float.vp_26'))
}

@ObservedV2
export class HomeModel {
  @Trace curIndex: number = 0;
  public controller: TabsController = new TabsController();
  public tabList: TabSingleItem[] = TAB_CONFIG;
  private static _instance: HomeModel;
  @Trace macList: PairedDeviceMacList = PersistenceV2.connect(PairedDeviceMacList, () => new PairedDeviceMacList())!;
  private lastCheckedDate: string = '';
  // 诊断+匹配回调：status 参数头部可编码 MATCH 信息，由 HomePage 解析
  onCheckComplete: ((status: string) => void) | null = null;
  private onGotoDeviceTabChange: () => void = () => {
    this.curIndex = 1;
  }

  public static get instance() {
    if (!HomeModel._instance) {
      HomeModel._instance = new HomeModel();
      emitter.on(Constants.onGotoDeviceTabChange, HomeModel._instance.onGotoDeviceTabChange);
    }
    return HomeModel._instance;
  }

  addDeviceDialog() {
    if (USE_MOCK_DATA) {
      return;
    }
    if (this.macList.pairedList.length === 0) {
      let dialogVM = new SkipStepModel();
      dialogVM.title = '设备连接';
      dialogVM.subtitle = '连接后数据会同步APP显示';
      dialogVM.onValueConfirmClick = () => {
        this.curIndex = 1;
      }
      dialogVM.childBuilder = homeModelDialogBuilder
      OHDialog.ShowPopup(dialogVM)
    }
  }

  /** 默认提醒计划（与 ReminderMockData 保持一致，首次/数据损坏时兜底） */
  private static readonly DEFAULT_PLANS: ReminderPlan[] = [
    { id: '1', type: 0, name: '上午喝水', time: '10:00', dosage: '250ml（约一杯）', isEnabled: true, isCheckedToday: false },
    { id: '2', type: 0, name: '下午喝水', time: '15:00', dosage: '250ml（约一杯）', isEnabled: true, isCheckedToday: false },
    { id: '3', type: 1, name: '降压药', time: '19:00', dosage: '1片，饭后30分钟服用', isEnabled: true, isCheckedToday: false },
    { id: '4', type: 1, name: '维生素片', time: '08:30', dosage: '1片，随餐服用', isEnabled: true, isCheckedToday: false },
    { id: '5', type: 0, name: '晚间补水', time: '21:00', dosage: '200ml（半杯）', isEnabled: true, isCheckedToday: false }
  ];

  /** 加载用户自定义提醒计划 */
  private loadPlans(): ReminderPlan[] {
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const data = pref.get(REMINDER_STORAGE_KEY, '') as string;
      if (data) {
        const parsed: ReminderPlan[] = JSON.parse(data) as ReminderPlan[];
        // 检测损坏数据（之前 @ObservedV2 序列化产生的）
        if (parsed.length > 0 && (!parsed[0].name || parsed[0].name === 'undefined')) {
          pref.delete(REMINDER_STORAGE_KEY);
          return HomeModel.DEFAULT_PLANS;
        }
        return parsed;
      }
    } catch {
      // ignore
    }
    // 存储为空：返回默认计划，确保定时器有数据可匹配
    return HomeModel.DEFAULT_PLANS;
  }

  /** 获取今天已打卡的计划ID集合 */
  private getCheckedToday(): Set<string> {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const stored = pref.get(REMINDER_CHECKED_KEY, '{}') as string;
      const data: Record<string, Object> = JSON.parse(stored) as Record<string, Object>;
      if (data['date'] === today) {
        return new Set((data['ids'] as string[]) ?? []);
      }
    } catch {
      // ignore
    }
    return new Set();
  }

  /** 标记今天已打卡 */
  private markChecked(planId: string): void {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    const checked = this.getCheckedToday();
    checked.add(planId);
    const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
    pref.put(REMINDER_CHECKED_KEY, JSON.stringify({ date: today, ids: Array.from(checked) }));
  }

  /** 初始检查（首页加载时触发一次），定时轮询由 HomePage 的 ComponentV2 生命周期管理 */
  addHealthRemind() {
    this.checkAndRemind();
  }

  /** 诊断：返回当前加载的计划列表，供 HomePage 诊断横幅使用 */
  public getLoadedPlans(): ReminderPlan[] {
    return this.loadPlans();
  }

  /** 检查所有计划并在匹配时弹窗（public — 由 HomePage 定时调用以确保 UIContext 有效） */
  public checkAndRemind(): void {
    const now = new Date();
    const currentDate = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);

    // 跨天重置打卡记录
    if (this.lastCheckedDate && this.lastCheckedDate !== currentDate) {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(REMINDER_CHECKED_KEY, JSON.stringify({ date: currentDate, ids: [] }));
    }
    this.lastCheckedDate = currentDate;

    // 使用 UTC 方法+时区偏移计算本地时间（模拟器 getHours() 可能返回 UTC）
    const tzOffset: number = now.getTimezoneOffset();
    const nowMinutes: number = (now.getUTCHours() * 60 + now.getUTCMinutes()) - tzOffset;
    const plans = this.loadPlans();
    const checkedToday = this.getCheckedToday();
    let matchedPlanName: string = '';
    let matchedPlanTime: string = '';
    let matchedPlanType: number = -1;
    let diagResult: string = '';

    for (let i = 0; i < plans.length; i++) {
      const plan: ReminderPlan = plans[i];
      if (!plan.isEnabled) {
        diagResult += `${plan.name}[off] `;
        continue;
      }
      const alreadyChecked: boolean = checkedToday.has(plan.id);
      if (alreadyChecked) {
        diagResult += `${plan.name}[done] `;
        continue;
      }
      const parts: string[] = plan.time.split(':');
      if (parts.length !== 2) {
        continue;
      }
      const planMinutes: number = parseInt(parts[0]) * 60 + parseInt(parts[1]);
      const diff: number = Math.abs(nowMinutes - planMinutes);
      if (diff <= 7) {
        matchedPlanName = plan.name;
        matchedPlanTime = plan.time;
        matchedPlanType = plan.type;
        this.markChecked(plan.id);
        diagResult += `${plan.name}[HIT d=${diff}] `;
      } else {
        diagResult += `${plan.name}[d=${diff}] `;
      }
    }

    if (this.onCheckComplete) {
      const localHour: number = Math.floor(nowMinutes / 60) % 24;
      const localMin: number = nowMinutes % 60;
      const timeStr: string = `${localHour.toString().padStart(2, '0')}:${localMin.toString().padStart(2, '0')}`;
      // 格式: "m=1;name=X;time=X;type=N;|HH:MM|诊断"
      let status: string = '';
      if (matchedPlanName.length > 0) {
        status = `m=1;name=${matchedPlanName};time=${matchedPlanTime};type=${matchedPlanType};|${timeStr}|${diagResult}`;
      } else {
        status = `m=0;|${timeStr}|${diagResult}`;
      }
      this.onCheckComplete(status);
    }
  }
}
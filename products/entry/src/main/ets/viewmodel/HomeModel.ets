import { PersistenceV2 } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { Constants, GlobalContext, OHDialog, OHDialogModel, PreferenceConstant, PreferenceUtil, TimeUtil, USE_MOCK_DATA } from 'common';
import { PairedDeviceMacList } from 'device';
import { SkipStepModel } from 'person';
import { ReminderPlanItem, ReminderService } from 'health';
import { TAB_CONFIG } from '../constants/constants';
import { TabSingleItem } from './TabSingleItem';

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

  /** 加载用户自定义提醒计划（委托 ReminderService，带缓存） */
  private loadPlans(): ReminderPlanItem[] {
    return ReminderService.loadPlans();
  }

  /** 获取今天已打卡的计划ID集合 */
  private getCheckedToday(): Set<string> {
    const today = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);
    try {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      const stored = pref.get(PreferenceConstant.REMINDER_CHECKED_TODAY, '{}') as string;
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
    pref.put(PreferenceConstant.REMINDER_CHECKED_TODAY, JSON.stringify({ date: today, ids: Array.from(checked) }));
  }

  /** 公开方法：供弹窗"已完成"按钮调用，标记指定计划已打卡（#10） */
  public markPlanChecked(planId: string): void {
    this.markChecked(planId);
  }

  /** 公开方法：根据计划名称查找计划ID（供弹窗打卡用） */
  public findPlanIdByName(planName: string): string {
    const plans = this.loadPlans();
    for (let i = 0; i < plans.length; i++) {
      if (plans[i].name === planName) {
        return plans[i].id;
      }
    }
    return '';
  }

  /** 初始检查（首页加载时触发一次），定时轮询由 HomePage 的 ComponentV2 生命周期管理 */
  addHealthRemind() {
    this.checkAndRemind();
  }

  /** 检查所有计划并在匹配时弹窗（public — 由 HomePage 定时调用以确保 UIContext 有效） */
  public checkAndRemind(): void {
    const now = new Date();
    const currentDate = TimeUtil.getCurTime(TimeUtil.PATTERN_DATE_HYPHEN);

    // 跨天重置打卡记录
    if (this.lastCheckedDate && this.lastCheckedDate !== currentDate) {
      const pref = PreferenceUtil.getInstance(GlobalContext.getUIAbilityContext());
      pref.put(PreferenceConstant.REMINDER_CHECKED_TODAY, JSON.stringify({ date: currentDate, ids: [] }));
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

    for (let i = 0; i < plans.length; i++) {
      const plan: ReminderPlanItem = plans[i];
      if (!plan.isEnabled) {
        continue;
      }
      const alreadyChecked: boolean = checkedToday.has(plan.id);
      if (alreadyChecked) {
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
      }
    }

    if (this.onCheckComplete) {
      const localHour: number = Math.floor(nowMinutes / 60) % 24;
      const localMin: number = nowMinutes % 60;
      const timeStr: string = `${localHour.toString().padStart(2, '0')}:${localMin.toString().padStart(2, '0')}`;
      let status: string = '';
      if (matchedPlanName.length > 0) {
        status = `m=1;name=${matchedPlanName};time=${matchedPlanTime};type=${matchedPlanType};|${timeStr}`;
      } else {
        status = `m=0;|${timeStr}`;
      }
      this.onCheckComplete(status);
    }
  }
}

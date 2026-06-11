import { common } from '@kit.AbilityKit';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { TCLogger, BarVM, Constants } from 'common';
import { HomeModel } from '../viewmodel/HomeModel';
import { TabSingleItem } from '../viewmodel/TabSingleItem';
import { WaterIntakeService } from 'health';

@Builder
export function HomePageBuilder() {
  HomePage()
}

const TAG = 'HomePage';
const CHECK_INTERVAL = 30000; // 30秒检查一次

@ComponentV2
export struct HomePage {
  vm: HomeModel = HomeModel.instance;
  private timerId: number = -1;
  @Local reminderVisible: boolean = false;
  @Local reminderTitle: string = '';
  @Local reminderBody: string = '';
  @Local reminderIconType: number = 0; // 0=water, 1=med
  @Local tickCount: number = 0;
  @Local checkedIn: boolean = false; // #10 本次弹窗是否已打卡

  @Builder
  tabBuilder(tabItem: TabSingleItem) {
    Column() {
      Image(this.vm.curIndex === tabItem.index ? tabItem.iconActive : tabItem.icon)
        .width($r('app.float.vp_24'))
        .height($r('app.float.vp_24'))
        .objectFit(ImageFit.Contain)
      Text(tabItem.label)
        .margin({ top: $r('app.float.vp_4') })
        .fontSize($r('sys.float.Caption_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.vm.curIndex === tabItem.index ? tabItem.fontColorActive : tabItem.fontColor)
    }
    .justifyContent(FlexAlign.Center)
    .height($r('app.float.vp_52'))
    .width('100%')
  }

  aboutToAppear(): void {
    this.vm.addDeviceDialog();
    this.vm.onCheckComplete = (status: string) => {
      const parts: string[] = status.split('|');
      const meta: string = parts[0] || '';
      if (meta.startsWith('m=1;')) {
        const fields: string[] = meta.split(';');
        for (let j = 0; j < fields.length; j++) {
          const kv: string[] = fields[j].split('=');
          if (kv.length >= 2) {
            if (kv[0] === 'name') { this.reminderTitle = kv[1]; }
            if (kv[0] === 'time') { this.reminderBody = kv[1]; }
            if (kv[0] === 'type') { this.reminderIconType = parseInt(kv[1]); }
          }
        }
        this.checkedIn = false; // 新弹窗重置打卡状态
        this.reminderVisible = true;
      }
    };
    this.vm.addHealthRemind();
    this.scheduleNextCheck();
  }

  private scheduleNextCheck(): void {
    this.timerId = setTimeout(() => {
      // #8 定时器异常保护：确保异常不会中断定时链
      try {
        this.tickCount++;
        this.vm.checkAndRemind();
      } catch (e) {
        const err = e instanceof Error ? e : new Error(String(e));
        TCLogger.error(TAG, `checkAndRemind error: ${err.message}`);
      }
      this.scheduleNextCheck();
    }, CHECK_INTERVAL);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  /** #10 弹窗打卡 */
  private handleCheckIn(): void {
    if (this.checkedIn) {
      return; // 防止重复打卡
    }
    const planId = this.vm.findPlanIdByName(this.reminderTitle);
    if (planId.length > 0) {
      this.vm.markPlanChecked(planId);
      // 饮水计划打卡时，同步增加喝水杯数
      if (this.reminderIconType === 0) {
        WaterIntakeService.instance.drink();
      }
    }
    this.checkedIn = true;
    // 通知 ReminderPlanPage 刷新打卡状态
    emitter.emit(Constants.onReminderCheckIn);
    // 1.2秒后自动关闭弹窗，让用户看到"已完成"反馈
    setTimeout(() => {
      this.reminderVisible = false;
    }, 1200);
  }

  /** 关闭弹窗 */
  private dismissReminder(): void {
    this.reminderVisible = false;
  }

  // 页面内容渲染
  @Builder
  render() {
    Stack() {
      Tabs({
        barPosition: BarPosition.End,
        index: $$this.vm.curIndex,
        controller: this.vm.controller
      }) {
        ForEach(this.vm.tabList, (item: TabSingleItem) => {
          TabContent() {
            item.component.builder('');
          }
          .tabBar(this.tabBuilder(item))
        }, (item: TabSingleItem, index) => JSON.stringify(item) + '_' + index)
      }
      .clip(true)
      .width('100%')
      .backgroundColor($r('app.color.background_color_page'))
      .barHeight($r('app.float.vp_50'))
      .barMode(BarMode.Fixed)
      .padding({
        bottom: BarVM.instance.aiBarH
      })
      .animationDuration(0)
      .scrollable(false)

      // 遮罩层 + 弹窗卡片
      Column() {
        Column() {
          // 顶部彩色条
          Row()
            .width('100%')
            .height(4)
            .backgroundColor(this.reminderIconType === 0 ? '#4ECDC4' : '#FF6B6B')
            .borderRadius({ topLeft: 16, topRight: 16 })

          Blank().height(20)

          // 图标
          Stack() {
            Circle()
              .width(64)
              .height(64)
              .fill(this.reminderIconType === 0 ? '#E8F8F5' : '#FFF0F0')
            Text(this.reminderIconType === 0 ? '💧' : '💊')
              .fontSize(32)
          }

          Blank().height(14)

          // 标题
          Text(this.reminderTitle)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank().height(6)

          // 时间
          Text(`提醒时间：${this.reminderBody}`)
            .fontSize(14)
            .fontColor('#888888')

          Blank().height(20)

          // #10 打卡 + 知道了 双按钮
          Row({ space: 12 }) {
            Button(this.checkedIn ? '✅ 已完成' : '打卡')
              .height(44)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(this.checkedIn ? '#AAAAAA' : '#4ECDC4')
              .borderRadius(22)
              .layoutWeight(1)
              .enabled(!this.checkedIn)
              .onClick(() => this.handleCheckIn())

            Button('知道了')
              .height(44)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.reminderIconType === 0 ? '#4ECDC4' : '#FF6B6B')
              .backgroundColor($r('sys.color.comp_background_list_card'))
              .borderRadius(22)
              .borderWidth(1)
              .borderColor(this.reminderIconType === 0 ? '#4ECDC4' : '#FF6B6B')
              .layoutWeight(1)
              .onClick(() => this.dismissReminder())
          }
          .width('80%')

          Blank().height(8)
        }
        .width('80%')
        .padding({ bottom: 20 })
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .shadow({ radius: 24, color: '#33000000', offsetX: 0, offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0,0,0,0.35)')
      .visibility(this.reminderVisible ? Visibility.Visible : Visibility.None)
      .onClick(() => this.dismissReminder())
    }
    .width('100%')
    .height('100%')
  }

  build() {
    NavDestination() {
      this.render();
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true)
    .onBackPressed(() => {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.terminateSelf((err: BusinessError) => {
        if (err !== undefined) {
          TCLogger.error(TAG, 'terminate self failed. error:' + JSON.stringify(err));
        } else {
          TCLogger.info(TAG, 'terminate self success');
        }
      });
      return true
    })
  }
}

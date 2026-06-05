import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TCLogger, BarVM } from 'common';
import { HomeModel } from '../viewmodel/HomeModel';
import { TabSingleItem } from '../viewmodel/TabSingleItem';

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
        this.reminderVisible = true;
      }
    };
    this.vm.addHealthRemind();
    this.scheduleNextCheck();
  }

  private scheduleNextCheck(): void {
    this.timerId = setTimeout(() => {
      this.tickCount++;
      this.vm.checkAndRemind();
      this.scheduleNextCheck();
    }, CHECK_INTERVAL);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
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

          // 确认按钮
          Button('我知道了')
            .width('80%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor(this.reminderIconType === 0 ? '#4ECDC4' : '#FF6B6B')
            .borderRadius(22)
            .onClick(() => this.reminderVisible = false)

          Blank().height(8)
        }
        .width('80%')
        .padding({ bottom: 20 })
        .backgroundColor(Color.White)
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
      .onClick(() => this.reminderVisible = false)
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

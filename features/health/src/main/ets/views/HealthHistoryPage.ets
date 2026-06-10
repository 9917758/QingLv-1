/**
 * 健康历史记录页面
 */
import { phoneRouterControl } from 'oh_router';
import { HealthHistoryModel } from '../viewmodel/HealthHistoryModel';
import { HealthHistoryItem } from '../types/HealthHistoryTypes';
import { RouterMap, UnitConverter, BarVM, ThemeUtil } from 'common';
import type { ThemeColors } from 'common';
import { HealthHistoryDetailPageBuilder } from './HealthHistoryDetailPage';

@Builder
export function HealthHistoryPageBuilder() {
  HealthHistoryPage()
}

@ComponentV2
export struct HealthHistoryPage {
  private vm: HealthHistoryModel = HealthHistoryModel.instance;
  @Computed get themeColors(): ThemeColors {
    return ThemeUtil.instance.currentColors;
  }

  async aboutToAppear(): Promise<void> {
    this.vm.loadHistory();
    try {
      await this.vm.loadFromApi();
    } catch (err) {
      console.error(`HealthHistoryPage loadFromApi error: ${JSON.stringify(err)}`);
    }
  }

  handleBack = (): void => {
    phoneRouterControl.popPage();
  }
  handleMonthClick = (): void => {
    this.vm.toggleMonthPicker();
  }
  handleItemClick = (item: HealthHistoryItem): void => {
    phoneRouterControl.jumpPage({
      pageName: RouterMap.HEALTH_HISTORY_DETAIL_PAGE,
      builder: wrapBuilder(HealthHistoryDetailPageBuilder),
      param: item
    })
  }

  private getMonthMenuItems() {
    interface MenuItemType {
      value: string;
      action: () => void;
    }

    const items: MenuItemType[] = this.vm.getMonthOptions().map(month => {
      const menuItem: MenuItemType = {
        value: month,
        action: () => this.vm.selectMonth(month)
      };
      return menuItem;
    });
    return items;
  }

  build() {
    NavDestination() {
      Column() {
        // 自定义标题栏
        Row() {
          Image($r('app.media.ic_backward2'))
            .width(40)
            .aspectRatio(1)
            .margin({ left: 16, top: 32, right: 8 })
            .onClick(this.handleBack)

          Text($r('app.string.health_history_title'))
            .size({ height: 27 })
            .margin({ top: 32 })
            .fontSize($r('sys.float.Title_S'))
            .fontWeight(700)
            .fontColor(this.themeColors.textPrimary)

          Blank().layoutWeight(1)
        }
        .height(UnitConverter.px2vp(BarVM.instance.statusBarHeight.value) + 48)
        .width('100%')
        .margin({ top: 16, bottom: 8 })

        // 月份选择器
        Row() {
          Text(this.vm.selectedMonth)
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeColors.textPrimary)
            .fontFamily('HarmonyOS Sans SC')
            .layoutWeight(1)

          Image($r('sys.media.ohos_ic_public_arrow_down'))
            .width(16)
            .height(16)
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 8,
          bottom: 8
        })
        .onClick(this.handleMonthClick)
        .bindMenu(this.vm.showMonthPicker, this.getMonthMenuItems(), {
          placement: Placement.BottomRight
        })

        // 列表卡片容器 - 整体白色卡片
        Column() {
          if (this.vm.getCurrentMonthData().length === 0) {
            // 空状态提示
            Column({ space: 8 }) {
              Text('📋')
                .fontSize(48)
              Text($r('app.string.health_no_records_yet'))
                .fontColor(this.themeColors.textTertiary)
                .fontSize(16)
              Text($r('app.string.health_go_input_data_hint'))
                .fontColor(this.themeColors.textTertiary)
                .fontSize(14)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
          List({ space: 0 }) {
            ForEach(this.vm.getCurrentMonthData(), (item: HealthHistoryItem, index: number) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(`体重${item.weight}`)
                      .fontSize($r('sys.float.Body_L'))
                      .fontColor(this.themeColors.textPrimary)
                      .fontFamily('HarmonyOS Sans SC')
                      .layoutWeight(1)

                    Text(item.date)
                      .fontSize($r('sys.float.Body_M'))
                      .fontColor(this.themeColors.textSecondary)
                      .fontFamily('HarmonyOS Sans SC')
                      .margin({ right: 8 })

                    Image($r('sys.media.ohos_ic_public_arrow_right'))
                      .width(16)
                      .height(16)
                      .fillColor(this.themeColors.textTertiary)
                  }
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 18,
                    bottom: 18
                  })

                  // 下划线（最后一项不显示）
                  if (index < this.vm.getCurrentMonthData().length - 1) {
                    Divider()
                      .strokeWidth('1px')
                      .color(this.themeColors.divider)
                      .margin({ left: 16, right: 16 })
                  }
                }
                .width('100%')
                .onClick(() => this.handleItemClick(item))
              }
            })
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeColors.backgroundCard)
          .borderRadius($r('sys.float.corner_radius_level7'))
          .clip(true)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: 16,
          right: 16,
          top: 8,
          bottom: 16
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeColors.backgroundSecondary)
    }
    .hideTitleBar(true)
  }
}


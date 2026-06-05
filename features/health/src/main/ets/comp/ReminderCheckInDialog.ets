import { ReminderPlanItem } from '../model/ReminderPlanModel';

/**
 * 用药/饮水提醒打卡弹窗
 * 到点弹出，用户可点击"已服药"/"已喝水"完成打卡，或点击"稍后提醒"关闭
 */
@ComponentV2
export struct ReminderCheckInDialog {
  @Param @Require plan: ReminderPlanItem;
  @Param onCheckIn: () => void = () => {};
  @Param onDismiss: () => void = () => {};

  build() {
    Column({ space: 16 }) {
      // 弹窗标题
      Row({ space: 8 }) {
        Image(this.plan.type === 0
          ? $r('app.media.health_water_clock_icon')
          : $r('app.media.health_medication_reminder_icon'))
          .width(32)
          .height(32)
        Text(this.plan.type === 0 ? '喝水提醒' : '用药提醒')
          .fontSize($r('sys.float.Subtitle_L'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 提醒内容
      Column({ space: 8 }) {
        Text(this.plan.name)
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        if (this.plan.dosage) {
          Text(this.plan.dosage)
            .fontSize($r('sys.float.Body_S'))
            .fontColor($r('sys.color.font_secondary'))
        }
        Text(`提醒时间：${this.plan.time}`)
          .fontSize($r('sys.float.Body_S'))
          .fontColor($r('sys.color.font_tertiary'))
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      // 操作按钮
      Row({ space: 12 }) {
        Button('稍后提醒')
          .fontSize($r('sys.float.Body_M'))
          .height(40)
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_gray'))
          .fontColor($r('sys.color.font_secondary'))
          .borderRadius($r('sys.float.corner_radius_level6'))
          .onClick(() => this.onDismiss())

        Button(this.plan.type === 0 ? '已喝水 ✓' : '已服药 ✓')
          .fontSize($r('sys.float.Body_M'))
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#117CFF')
          .fontColor(Color.White)
          .borderRadius($r('sys.float.corner_radius_level6'))
          .onClick(() => this.onCheckIn())
      }
      .width('100%')
    }
    .padding(20)
    .width('100%')
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }
}

import { BarVM, CommonHeader, Constants } from 'common';
import { emitter } from '@kit.BasicServicesKit';
import { phoneRouterControl } from 'oh_router';
import { ReminderPlanItem } from '../model/ReminderPlanModel';
import { ReminderService } from '../service/ReminderService';

@Builder
export function ReminderPlanPageBuilder() {
  ReminderPlanPage()
}

@ComponentV2
export struct ReminderPlanPage {
  @Local plans: ReminderPlanItem[] = [];
  @Local showEditDialog: boolean = false;
  @Local editingPlan: ReminderPlanItem = new ReminderPlanItem();
  @Local editingIndex: number = -1;
  @Local editName: string = '';
  @Local editType: number = 0;
  @Local editHour: string = '08';
  @Local editMinute: string = '00';
  @Local editDosage: string = '';
  @Local plansVersion: number = 0; // 每次编辑后递增，强制 ForEach 刷新
  @Local onReturnClick: () => void = () => {
    phoneRouterControl.popPage()
  }
  private onReminderCheckIn: () => void = () => {
    this.loadPlans();
  }

  aboutToAppear(): void {
    this.loadPlans();
    emitter.on(Constants.onReminderCheckIn, this.onReminderCheckIn);
  }

  aboutToDisappear(): void {
    emitter.off(Constants.onReminderCheckIn.eventId, this.onReminderCheckIn);
  }

  loadPlans(): void {
    // 委托 ReminderService 加载（含缓存和校验，#2 #4 #7）
    const loaded: ReminderPlanItem[] = ReminderService.loadPlans();
    if (loaded.length > 0) {
      // 同步今日打卡状态（弹窗打卡后 isCheckedToday 需要与存储一致）
      this.plans = ReminderService.syncCheckedStatus(loaded);
      this.plansVersion++;
    } else {
      this.plans = ReminderService.getDefaultPlans();
      this.savePlans();
    }
  }

  savePlans(): void {
    // #2 委托 ReminderService 保存并更新缓存
    ReminderService.savePlans(this.plans);
  }

  togglePlan(index: number): void {
    const updated: ReminderPlanItem[] = [];
    for (let i = 0; i < this.plans.length; i++) {
      const cloned: ReminderPlanItem = ReminderService.copyPlan(this.plans[i]);
      if (i === index) {
        cloned.isEnabled = !cloned.isEnabled;
      }
      updated.push(cloned);
    }
    this.plans = updated;
    this.plansVersion++;
    this.savePlans();
  }

  openEditDialog(plan: ReminderPlanItem, index: number): void {
    this.editingPlan = plan;
    this.editingIndex = index;
    this.editName = plan.name;
    this.editType = plan.type;
    const parts: string[] = plan.time.split(':');
    this.editHour = parts[0] || '08';
    this.editMinute = parts[1] || '00';
    this.editDosage = plan.dosage;
    this.showEditDialog = true;
  }

  saveEdit(): void {
    const timeStr: string = `${this.editHour}:${this.editMinute}`;
    if (this.editingIndex >= 0 && this.editingIndex < this.plans.length) {
      const updated: ReminderPlanItem[] = [];
      for (let i = 0; i < this.plans.length; i++) {
        const cloned: ReminderPlanItem = ReminderService.copyPlan(this.plans[i]);
        if (i === this.editingIndex) {
          cloned.name = this.editName;
          cloned.type = this.editType;
          cloned.time = timeStr;
          cloned.dosage = this.editDosage;
        }
        updated.push(cloned);
      }
      this.plans = updated;
      this.plansVersion++;
      this.savePlans();
    }
    this.showEditDialog = false;
  }

  getTypeIcon(type: number): ResourceStr {
    return type === 0 ? $r('app.media.health_water_clock_icon') : $r('app.media.health_medication_reminder_icon');
  }

  getTypeLabel(type: number): string {
    return type === 0 ? '饮水' : '用药';
  }

  getTypeColor(type: number): string {
    return type === 0 ? '#4ECDC4' : '#FF6B6B';
  }

  build() {
    NavDestination() {
      Stack() {
        this.render()
        if (this.showEditDialog) {
          this.renderEditDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onAppear(() => {
      // 每次页面可见时重新同步打卡状态（弹窗打卡后返回时刷新）
      this.loadPlans();
    })
    .onBackPressed(() => {
      phoneRouterControl.popPage()
      return true
    })
  }

  @Builder
  render() {
    Column() {
      CommonHeader({
        title: '用药与饮水提醒',
        onReturnClick: this.onReturnClick,
        leftImageRes: $r('app.media.ic_backward2')
      })

      Text('点击计划可修改时间和详情，到点自动弹窗提醒')
        .fontSize($r('sys.float.Caption_S'))
        .fontColor($r('sys.color.font_tertiary'))
        .padding({ left: 16, right: 16, top: 8, bottom: 4 })
        .width('100%')

      // plansVersion 绑定：任何值变化触发此处的 UI 树重构
      Text(`v${this.plansVersion}`).fontSize(0).width(0).height(0)
      List({ space: 8 }) {
        ForEach(this.plans, (plan: ReminderPlanItem, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Image(this.getTypeIcon(plan.type))
                  .width(28)
                  .height(28)
              }
              .width(44)
              .height(44)
              .borderRadius($r('sys.float.corner_radius_level6'))
              .backgroundColor(this.getTypeColor(plan.type) + '20')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              Blank().width(12)

              Column({ space: 2 }) {
                Row({ space: 6 }) {
                  Text(plan.name)
                    .fontSize($r('sys.float.Body_L'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                  Text(this.getTypeLabel(plan.type))
                    .fontSize(10)
                    .fontColor(Color.White)
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .backgroundColor(this.getTypeColor(plan.type))
                    .borderRadius($r('sys.float.corner_radius_level2'))
                  if (plan.isCheckedToday) {
                    Text('已完成')
                      .fontSize(10)
                      .fontColor(Color.White)
                      .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      .backgroundColor('#4CAF50')
                      .borderRadius($r('sys.float.corner_radius_level2'))
                  }
                }
                Text(`${plan.time}  ${plan.dosage}`)
                  .fontSize($r('sys.float.Body_S'))
                  .fontColor($r('sys.color.font_secondary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: plan.isEnabled })
                .onChange(() => this.togglePlan(index))
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('sys.color.background_primary'))
            .borderRadius($r('sys.float.corner_radius_level7'))
            .onClick(() => this.openEditDialog(plan, index))
          }
        }, (item: ReminderPlanItem) => `${item.id}_${item.time}_${item.name}_${item.type}_${item.isEnabled}_${item.isCheckedToday}`)

        ListItem().height(px2vp(BarVM.instance.aiBarH))
      }
      .height('100%')
      .width('100%')
      .padding({ left: 16, right: 16, top: 4 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#FFF1F3F5')
  }

  @Builder
  renderEditDialog() {
    Column() {
      Column({ space: 12 }) {
        Text('编辑提醒计划')
          .fontSize($r('sys.float.Subtitle_L'))
          .fontWeight(FontWeight.Medium)
          .width('100%')

        // 名称
        Row() {
          Text('名称')
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .width(60)
          TextInput({ text: this.editName, placeholder: '如：降压药、上午喝水' })
            .onChange((value: string) => this.editName = value)
            .layoutWeight(1)
            .height(36)
            .fontSize($r('sys.float.Body_M'))
        }

        // 类型
        Row() {
          Text('类型')
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .width(60)
          Row({ space: 16 }) {
            Row({ space: 4 }) {
              Radio({ value: 'water', group: 'planType' })
                .checked(this.editType === 0)
                .onChange(() => this.editType = 0)
                .width(18).height(18)
              Text('饮水').fontSize($r('sys.float.Body_M'))
            }
            Row({ space: 4 }) {
              Radio({ value: 'med', group: 'planType' })
                .checked(this.editType === 1)
                .onChange(() => this.editType = 1)
                .width(18).height(18)
              Text('用药').fontSize($r('sys.float.Body_M'))
            }
          }
        }

        // 时间
        Row() {
          Text('时间')
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .width(60)
          Row({ space: 4 }) {
            Button(`${this.editHour}`)
              .fontSize($r('sys.float.Body_M'))
              .height(32)
              .width(50)
              .backgroundColor($r('sys.color.comp_background_emphasize'))
              .onClick(() => {
                let h: number = parseInt(this.editHour) + 1;
                if (h > 23) { h = 0; }
                this.editHour = h.toString().padStart(2, '0');
              })
            Text(':')
              .fontSize($r('sys.float.Subtitle_L'))
              .fontWeight(FontWeight.Bold)
            Button(`${this.editMinute}`)
              .fontSize($r('sys.float.Body_M'))
              .height(32)
              .width(50)
              .backgroundColor($r('sys.color.comp_background_emphasize'))
              .onClick(() => {
                let m: number = parseInt(this.editMinute) + 5;
                if (m > 55) { m = 0; }
                this.editMinute = m.toString().padStart(2, '0');
              })
          }
        }

        // 剂量/水量
        Row() {
          Text('剂量/水量')
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .width(60)
          TextInput({ text: this.editDosage, placeholder: '如：1片、250ml' })
            .onChange((value: string) => this.editDosage = value)
            .layoutWeight(1)
            .height(36)
            .fontSize($r('sys.float.Body_M'))
        }

        // 按钮
        Row({ space: 12 }) {
          Button('取消')
            .fontSize($r('sys.float.Body_M'))
            .height(40)
            .layoutWeight(1)
            .backgroundColor($r('sys.color.comp_background_gray'))
            .fontColor($r('sys.color.font_secondary'))
            .borderRadius($r('sys.float.corner_radius_level6'))
            .onClick(() => this.showEditDialog = false)

          Button('保存')
            .fontSize($r('sys.float.Body_M'))
            .height(40)
            .layoutWeight(1)
            .backgroundColor('#117CFF')
            .fontColor(Color.White)
            .borderRadius($r('sys.float.corner_radius_level6'))
            .onClick(() => this.saveEdit())
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .padding(20)
      .width('90%')
      .backgroundColor($r('sys.color.background_primary'))
      .borderRadius($r('sys.float.corner_radius_level8'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .onClick(() => this.showEditDialog = false)
  }
}

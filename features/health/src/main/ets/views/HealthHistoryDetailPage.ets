//健康历史详情页面
import { phoneRouterControl } from 'oh_router';
import { TValueType, UnitConverter, BarVM, ThemeUtil, GlobalContext } from 'common';
import type { ThemeColors } from 'common';
import { HealthHistoryItem } from '../types/HealthHistoryTypes';
import { HealthDiaryService } from '../service/HealthDiaryService';
import { promptAction } from '@kit.ArkUI';

@Builder
export function HealthHistoryDetailPageBuilder(value: TValueType) {
  HealthHistoryDetailPage({
    value: value
  })
}

//健康历史详情页面
@ComponentV2
export struct HealthHistoryDetailPage {
  @Param @Require value: TValueType;
  @Computed get themeColors(): ThemeColors {
    return ThemeUtil.instance.currentColors;
  }
  @Local diaryContent: string = '';
  @Local isEditingDiary: boolean = false;

  @Local historyData: HealthHistoryItem = {
    id: '1',
    date: '9月12日',
    weight: 112.4,
    fullDate: '2026年5月28日',
    height: 167,
    age: 28,
    bmi: 23.2,
    bodyFat: 32.1,
    fatMass: 39.3,
    heartRate: 85,
    bloodPressureSystolic: 128,
    bloodPressureDiastolic: 88,
    bloodGlucose: 5.0
  };

  aboutToAppear(): void {
    this.historyData = this.value as HealthHistoryItem;
    // 加载该日期的日记
    const d = new Date(this.historyData.fullDate);
    if (!isNaN(d.getTime())) {
      const dateStr = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
      const entry = HealthDiaryService.instance.getEntry(dateStr);
      this.diaryContent = entry ? entry.content : '';
    }
  }

  private getDateStr(): string {
    const d = new Date(this.historyData.fullDate);
    if (isNaN(d.getTime())) return '';
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  }

  private saveDiary(): void {
    const dateStr = this.getDateStr();
    if (dateStr && this.diaryContent.trim().length > 0) {
      HealthDiaryService.instance.saveEntry(dateStr, this.diaryContent.trim());
      promptAction.showToast({ message: '日记已保存' });
    }
    this.isEditingDiary = false;
  }

  handleBack = (): void => {
    phoneRouterControl.popPage();
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.ic_backward2'))
            .width(40)
            .aspectRatio(1)
            .margin({ left: 16, top: 32, right: 8 })
            .onClick(this.handleBack)

          Text(this.historyData.fullDate)
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

        Column({ space: 12 }) {
          Row({ space: 0 }) {
            Column({ space: 6 }) {
              Text(this.historyData.weight.toFixed(1))
                .fontSize($r('sys.float.Title_M'))
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
                .fontFamily('HarmonyOS Sans SC')
              Text($r('app.string.health_weight_kg_label'))
                .fontSize($r('sys.float.Body_S'))
                .fontColor(this.themeColors.textSecondary)
                .fontFamily('HarmonyOS Sans SC')
            }
            .layoutWeight(1)

            Divider()
              .vertical(true)
              .height(42)
              .color(this.themeColors.divider)
              .strokeWidth('1px')

            Column({ space: 6 }) {
              Text(this.historyData.height.toString())
                .fontSize($r('sys.float.Title_M'))
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
                .fontFamily('HarmonyOS Sans SC')
              Text($r('app.string.health_height_cm_label'))
                .fontSize($r('sys.float.Body_S'))
                .fontColor(this.themeColors.textSecondary)
                .fontFamily('HarmonyOS Sans SC')
            }
            .layoutWeight(1)

            Divider()
              .vertical(true)
              .height(42)
              .color(this.themeColors.divider)
              .strokeWidth('1px')

            Column({ space: 6 }) {
              Text(this.historyData.age.toString())
                .fontSize($r('sys.float.Title_M'))
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
                .fontFamily('HarmonyOS Sans SC')
              Text($r('app.string.health_age_label'))
                .fontSize($r('sys.float.Body_S'))
                .fontColor(this.themeColors.textSecondary)
                .fontFamily('HarmonyOS Sans SC')
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24,
            top: 24,
            bottom: 24
          })
          .backgroundColor(this.themeColors.backgroundCard)
          .borderRadius($r('sys.float.corner_radius_level7'))
          .clip(true)

          Column({ space: 0 }) {
            this.renderDataRow('BMI', this.historyData.bmi.toFixed(1), false)
            this.renderDataRow($r('app.string.health_body_fat_rate'), `${this.historyData.bodyFat.toFixed(1)}%`, false)
            this.renderDataRow($r('app.string.health_fat_weight'), this.historyData.fatMass.toFixed(1), false)
          }
          .width('100%')
          .backgroundColor(this.themeColors.backgroundCard)
          .borderRadius($r('sys.float.corner_radius_level7'))
          .clip(true)

          Column({ space: 0 }) {
            this.renderDataRow($r('app.string.health_heartrate'), `${this.historyData.heartRate}次/分`, false)
            this.renderDataRow($r('app.string.health_bloodpressure'),
              `${this.historyData.bloodPressureSystolic}/${this.historyData.bloodPressureDiastolic}mmHg`, false)
            this.renderDataRow($r('app.string.health_blood_glucose'), `${this.historyData.bloodGlucose.toFixed(1)}mmol/L`, false)
          }
          .width('100%')
          .backgroundColor(this.themeColors.backgroundCard)
          .borderRadius($r('sys.float.corner_radius_level7'))
          .clip(true)

          // 日记卡片
          Column() {
            Row() {
              Text('📝 健康日记')
                .fontSize($r('sys.float.Body_L'))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textPrimary)
              Blank()
              if (!this.isEditingDiary) {
                Text(this.diaryContent.length > 0 ? '编辑' : '写日记')
                  .fontSize(14)
                  .fontColor(this.themeColors.accent)
                  .onClick(() => {
                    this.isEditingDiary = true;
                  })
              }
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 20 })

            if (this.isEditingDiary) {
              TextInput({ placeholder: '记录今天的感受...', text: this.diaryContent })
                .width('100%')
                .height(100)
                .margin({ left: 16, right: 16, top: 8 })
                .fontSize(14)
                .backgroundColor(this.themeColors.backgroundSecondary)
                .borderRadius(8)
                .onChange((value: string) => {
                  this.diaryContent = value;
                })
              Row() {
                Button('保存')
                  .type(ButtonType.Capsule)
                  .fontSize(14)
                  .height(32)
                  .backgroundColor(this.themeColors.accent)
                  .onClick(() => {
                    this.saveDiary();
                  })
                Button('取消')
                  .type(ButtonType.Capsule)
                  .fontSize(14)
                  .height(32)
                  .backgroundColor(this.themeColors.backgroundSecondary)
                  .fontColor(this.themeColors.textSecondary)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.isEditingDiary = false;
                  })
              }
              .width('100%')
              .padding({ left: 24, right: 24, top: 8, bottom: 16 })
              .justifyContent(FlexAlign.End)
            } else if (this.diaryContent.length > 0) {
              Text(this.diaryContent)
                .fontSize(14)
                .fontColor(this.themeColors.textSecondary)
                .width('100%')
                .padding({ left: 24, right: 24, top: 8, bottom: 20 })
            } else {
              Text('点击"写日记"记录今天的感受')
                .fontSize(14)
                .fontColor(this.themeColors.textTertiary)
                .width('100%')
                .padding({ left: 24, right: 24, top: 8, bottom: 20 })
            }
          }
          .width('100%')
          .backgroundColor(this.themeColors.backgroundCard)
          .borderRadius($r('sys.float.corner_radius_level7'))
          .clip(true)
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

  @Builder
  private renderDataRow(label: ResourceStr, value: string, showDivider: boolean) {
    Column() {
      Row() {
        Text(label)
          .fontSize($r('sys.float.Body_L'))
          .fontColor(this.themeColors.textPrimary)
          .fontFamily('HarmonyOS Sans SC')
          .layoutWeight(1)

        Text(value)
          .fontSize($r('sys.float.Body_L'))
          .fontColor(this.themeColors.textPrimary)
          .fontFamily('HarmonyOS Sans SC')
      }
      .width('100%')
      .padding({
        left: 24,
        right: 24,
        top: 20,
        bottom: 20
      })

      if (showDivider) {
        Divider()
          .color(this.themeColors.divider)
          .strokeWidth('1px')
      }
    }
  }
}


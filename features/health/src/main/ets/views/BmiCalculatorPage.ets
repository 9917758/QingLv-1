/**
 * BMI 计算器页面
 */
import { CommonHeader } from 'common';
import { phoneRouterControl } from 'oh_router';

@Builder
export function BmiCalculatorPageBuilder() {
  BmiCalculatorPage()
}

@ComponentV2
export struct BmiCalculatorPage {
  @Local selectedHeight: number = 170;
  @Local selectedWeight: number = 65;
  @Local bmiValue: number = 0;
  @Local bmiCategory: string = '';
  @Local healthyRange: string = '';
  @Local showResult: boolean = false;
  @Local onReturnClick: () => void = () => {
    phoneRouterControl.popPage()
  }

  private heightRange: string[] = [];
  private weightRange: string[] = [];

  aboutToAppear(): void {
    const heights: string[] = [];
    for (let i = 140; i <= 200; i++) {
      heights.push(`${i}`);
    }
    this.heightRange = heights;

    const weights: string[] = [];
    for (let i = 30; i <= 150; i++) {
      weights.push(`${i}`);
    }
    this.weightRange = weights;
  }

  calculateBmi(): void {
    const heightM: number = this.selectedHeight / 100;
    const bmi: number = this.selectedWeight / (heightM * heightM);
    this.bmiValue = Math.round(bmi * 10) / 10;

    if (bmi < 18.5) {
      this.bmiCategory = '偏瘦';
    } else if (bmi < 24) {
      this.bmiCategory = '正常';
    } else if (bmi < 28) {
      this.bmiCategory = '偏胖';
    } else {
      this.bmiCategory = '肥胖';
    }

    const minWeight: number = Math.round(18.5 * heightM * heightM);
    const maxWeight: number = Math.round(24 * heightM * heightM);
    this.healthyRange = `${minWeight}kg ~ ${maxWeight}kg`;
    this.showResult = true;
  }

  getCategoryColor(): ResourceColor {
    if (this.bmiCategory === '偏瘦') {
      return '#4ECDC4';
    } else if (this.bmiCategory === '正常') {
      return '#4CAF50';
    } else if (this.bmiCategory === '偏胖') {
      return '#FF9800';
    } else {
      return '#F44336';
    }
  }

  getBarPercent(): number {
    // Map BMI 15-35 to 0-100%
    const clamped: number = Math.max(15, Math.min(35, this.bmiValue));
    return ((clamped - 15) / 20) * 100;
  }

  @Builder
  renderResult() {
    Column({ space: 12 }) {
      Text(`${this.bmiValue}`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getCategoryColor())

      Text(this.bmiCategory)
        .fontSize($r('sys.float.Subtitle_L'))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getCategoryColor())
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        .backgroundColor('#FFF5F5F5')
        .borderRadius($r('sys.float.corner_radius_level4'))

      Text('健康体重范围')
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ top: 8 })

      Text(this.healthyRange)
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      // 可视化条形指示器
      Column({ space: 4 }) {
        Row() {
          Text('偏瘦')
            .fontSize(10)
            .fontColor('#4ECDC4')
          Blank()
          Text('正常')
            .fontSize(10)
            .fontColor('#4CAF50')
          Blank()
          Text('偏胖')
            .fontSize(10)
            .fontColor('#FF9800')
          Blank()
          Text('肥胖')
            .fontSize(10)
            .fontColor('#F44336')
        }
        .width('100%')

        Stack({ alignContent: Alignment.Start }) {
          Row() {
            Row()
              .width('25%')
              .height(8)
              .backgroundColor('#4ECDC4')
            Row()
              .width('25%')
              .height(8)
              .backgroundColor('#4CAF50')
            Row()
              .width('25%')
              .height(8)
              .backgroundColor('#FF9800')
            Row()
              .width('25%')
              .height(8)
              .backgroundColor('#F44336')
          }
          .width('100%')
          .height(8)
          .borderRadius(4)
          .clip(true)

          // 指针
          Column()
            .width(3)
            .height(16)
            .backgroundColor(Color.White)
            .borderRadius(1.5)
            .shadow({ radius: 2, color: '#33000000' })
            .offset({ x: `${this.getBarPercent()}%`, y: -4 })
        }
        .width('100%')
        .height(16)
        .margin({ top: 8 })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .backgroundColor(Color.White)
    .borderRadius($r('sys.float.corner_radius_level7'))
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        CommonHeader({
          title: 'BMI 计算器',
          onReturnClick: this.onReturnClick,
          leftImageRes: $r('app.media.ic_backward2')
        })

        Scroll() {
          Column({ space: 16 }) {
            // 身高选择卡片
            Column({ space: 8 }) {
              Text('身高 (cm)')
                .fontSize($r('sys.float.Body_L'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
                .width('100%')

              TextPicker({ range: this.heightRange, selected: this.selectedHeight - 140 })
                .onChange((value: string | string[], index: number | number[]) => {
                  if (typeof value === 'string') {
                    this.selectedHeight = parseInt(value);
                  }
                })
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius($r('sys.float.corner_radius_level7'))

            // 体重选择卡片
            Column({ space: 8 }) {
              Text('体重 (kg)')
                .fontSize($r('sys.float.Body_L'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
                .width('100%')

              TextPicker({ range: this.weightRange, selected: this.selectedWeight - 30 })
                .onChange((value: string | string[], index: number | number[]) => {
                  if (typeof value === 'string') {
                    this.selectedWeight = parseInt(value);
                  }
                })
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius($r('sys.float.corner_radius_level7'))

            // 计算按钮
            Button('计算 BMI')
              .width('100%')
              .height(48)
              .fontSize($r('sys.float.Body_L'))
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#117CFF')
              .fontColor(Color.White)
              .borderRadius($r('sys.float.corner_radius_level6'))
              .onClick(() => this.calculateBmi())

            // 结果展示
            if (this.showResult) {
              this.renderResult()
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 32 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .backgroundColor('#FFF1F3F5')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      phoneRouterControl.popPage()
      return true
    })
  }
}

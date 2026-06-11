// 强类型接口：约束模拟数据
interface HealthInfo {
  weight: number;
  bmi: number;
  water: number;
  score: number;
}

@Entry
@Component
struct HealthCard {
  // 写死模拟数据（保持原有业务数据不变）
  @State healthData: HealthInfo = {
    weight: 68,
    bmi: 22.5,
    water: 8,
    score: 90
  };

  build() {
    // 根布局：Stack 实现背景图+遮罩+内容，最外层绑定点击事件
    Stack() {
      // 第一层：全屏背景图
      Column()
        .width("100%")
        .height("100%")
        .backgroundImage($r("app.media.health_icon"))
        .backgroundImageSize(ImageSize.Cover)

      // 第二层：半透明白色遮罩（保证文字清晰）
      Column()
        .width("100%")
        .height("100%")
        .backgroundColor(Color.White)
        .opacity(0.7)

      // 第三层：文字与数据内容
      Column({ space: 6 }) {
        Text("清律健康速览")
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width("100%")
          .textAlign(TextAlign.Center)

        Flex({ justifyContent: FlexAlign.SpaceAround, wrap: FlexWrap.Wrap }) {
          Column() {
            Text("体重")
              .fontSize(12)
              .fontColor(Color.Grey)
            Text(`${this.healthData.weight} kg`)
              .fontSize(14)
          }
          Column() {
            Text("BMI")
              .fontSize(12)
              .fontColor(Color.Grey)
            Text(`${this.healthData.bmi}`)
              .fontSize(14)
          }
          Column() {
            Text("今日饮水")
              .fontSize(12)
              .fontColor(Color.Grey)
            Text(`${this.healthData.water} 杯`)
              .fontSize(14)
          }
          Column() {
            Text("健康评分")
              .fontSize(12)
              .fontColor(Color.Grey)
            Text(`${this.healthData.score}`)
              .fontSize(14)
              .fontColor(Color.Green)
          }
        }
      }
      .width("100%")
      .height("100%")
      .padding(10)
    }
    .width("100%")
    .height("100%")
    // ========== 核心：卡片全局点击事件（官方标准跳转） ==========
    .onClick(() => {
      // 调用鸿蒙卡片专属接口：router 事件 = 拉起当前App主Ability
      postCardAction(this, {
        action: "router",
        abilityName: "EntryAbility" // 和 module.json5 主入口名称严格一致
      });
    })
  }
}
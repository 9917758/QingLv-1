/**
 * 时间范围切换按钮（共享组件）
 * 用于数据看板页面的"近七天/近一个月/近三个月"切换
 */
@ComponentV2
export struct TimeRangeButton {
  @Param label: string = '';
  @Param isSelected: boolean = false;
  @Param onTap: () => void = () => {
  };

  build() {
    Row() {
      Text(this.label)
        .fontSize($r('sys.float.Body_M'))
        .fontColor(this.isSelected ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .height(40)
    .layoutWeight(1)
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor(this.isSelected ? '#2B69FF' : Color.Transparent)
    .onClick(this.onTap)
  }
}

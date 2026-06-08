/**
 * 健康异常事件历史页面
 * 展示健康异常事件时间线
 */
import { BarVM, CommonHeader } from 'common';
import { phoneRouterControl } from 'oh_router';
import { AnomalyHistoryService, AnomalyEvent } from '../service/AnomalyHistoryService';

interface DateGroup {
  dateStr: string;
  events: AnomalyEvent[];
}

@Builder
export function AnomalyHistoryPageBuilder() {
  AnomalyHistoryPage()
}

@ComponentV2
export struct AnomalyHistoryPage {
  private service: AnomalyHistoryService = AnomalyHistoryService.instance;
  @Local weekCount: number = 0;

  aboutToAppear(): void {
    this.weekCount = this.service.getThisWeekCount();
  }

  private getDateGroups(): DateGroup[] {
    const groups: DateGroup[] = [];
    const groupMap: Map<string, AnomalyEvent[]> = new Map();

    for (const event of this.service.events) {
      const existing: AnomalyEvent[] | undefined = groupMap.get(event.dateStr);
      if (existing !== undefined) {
        existing.push(event);
      } else {
        groupMap.set(event.dateStr, [event]);
      }
    }

    groupMap.forEach((events: AnomalyEvent[], dateStr: string) => {
      const group: DateGroup = { dateStr, events };
      groups.push(group);
    });

    return groups;
  }

  private getSeverityColor(severity: string): string {
    if (severity === 'warning') {
      return '#FF9500';
    }
    return '#117CFF';
  }

  private getSeverityLabel(severity: string): string {
    if (severity === 'warning') {
      return '警告';
    }
    return '提示';
  }

  @Builder
  render() {
    Column() {
      CommonHeader({
        title: '健康事件',
        onReturnClick: () => {
          phoneRouterControl.popPage();
        },
        leftImageRes: $r('app.media.ic_backward2')
      })

      if (this.service.events.length === 0) {
        // 空状态
        Column() {
          Text('📋')
            .fontSize(48)
          Blank().height(12)
          Text('暂无异常记录，继续保持！')
            .fontColor($r('sys.color.font_tertiary'))
            .fontSize($r('sys.float.Body_M'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 0 }) {
          // 本周汇总
          ListItem() {
            Text(`本周 ${this.weekCount} 条异常事件`)
              .fontSize($r('sys.float.Body_L'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .padding({ left: 4, top: 12, bottom: 12 })
          }

          ForEach(this.getDateGroups(), (group: DateGroup) => {
            // 日期分组头
            ListItem() {
              Text(group.dateStr)
                .fontSize($r('sys.float.Caption_L'))
                .fontColor($r('sys.color.font_secondary'))
                .padding({ left: 4, top: 12, bottom: 8 })
            }

            // 该日期下的事件卡片
            ForEach(group.events, (event: AnomalyEvent, index: number) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(event.icon)
                      .fontSize(20)
                      .width(32)
                      .height(32)
                      .textAlign(TextAlign.Center)

                    Column({ space: 2 }) {
                      Row({ space: 6 }) {
                        Text(event.title)
                          .fontSize($r('sys.float.Body_L'))
                          .fontWeight(FontWeight.Medium)
                          .fontColor($r('sys.color.font_primary'))
                        Text(this.getSeverityLabel(event.severity))
                          .fontSize(10)
                          .fontColor(Color.White)
                          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                          .backgroundColor(this.getSeverityColor(event.severity))
                          .borderRadius($r('sys.float.corner_radius_level2'))
                      }
                      .alignItems(VerticalAlign.Center)

                      Text(event.detail)
                        .fontSize($r('sys.float.Body_S'))
                        .fontColor($r('sys.color.font_secondary'))
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 2 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Column({ space: 4 }) {
                      Text(event.value)
                        .fontSize($r('sys.float.Body_M'))
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.getSeverityColor(event.severity))
                        .textAlign(TextAlign.End)
                      Text(event.timeStr)
                        .fontSize($r('sys.float.Caption_S'))
                        .fontColor($r('sys.color.font_tertiary'))
                        .textAlign(TextAlign.End)
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')
                  .padding(14)
                  .alignItems(VerticalAlign.Top)

                  // 分割线（同组内最后一项不显示）
                  if (index < group.events.length - 1) {
                    Divider()
                      .strokeWidth('1px')
                      .color($r('sys.color.comp_divider'))
                      .margin({ left: 60, right: 16 })
                  }
                }
                .width('100%')
                .backgroundColor(Color.White)
              }
            }, (event: AnomalyEvent) => `${event.id}`)

            // 日期组之间的间距
            ListItem() {
              Divider()
                .strokeWidth('8px')
                .color('#FFF1F3F5')
            }
          }, (group: DateGroup) => `group_${group.dateStr}`)

          ListItem().height(px2vp(BarVM.instance.aiBarH))
        }
        .height('100%')
        .width('100%')
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#FFF1F3F5')
  }

  build() {
    NavDestination() {
      this.render()
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      phoneRouterControl.popPage()
      return true
    })
  }
}

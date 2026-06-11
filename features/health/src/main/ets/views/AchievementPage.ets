/**
 * 成就徽章页面
 */
import { CommonHeader } from 'common';
import { phoneRouterControl } from 'oh_router';
import { AchievementService, Achievement } from '../service/AchievementService';

@Builder
export function AchievementPageBuilder() {
  AchievementPage()
}

@ComponentV2
export struct AchievementPage {
  private vm: AchievementService = AchievementService.instance;
  @Local onReturnClick: () => void = () => {
    phoneRouterControl.popPage()
  }

  aboutToAppear(): void {
    this.vm.generateMock();
  }

  getUnlockedCount(): number {
    return this.vm.getUnlockedCount();
  }

  getTotalCount(): number {
    return this.vm.achievements.length;
  }

  @Builder
  renderAchievementCard(achievement: Achievement) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(achievement.icon)
          .fontSize(32)

        Column({ space: 2 }) {
          Text(achievement.title)
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .fontColor(achievement.isUnlocked ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))

          Text(achievement.description)
            .fontSize($r('sys.float.Caption_S'))
            .fontColor($r('sys.color.font_tertiary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 进度条
      Column({ space: 4 }) {
        Row() {
          Text(`${achievement.progress}/${achievement.target}`)
            .fontSize(11)
            .fontColor($r('sys.color.font_tertiary'))
          Blank()
          Text(achievement.isUnlocked ? achievement.unlockedDate : $r('app.string.achievement_locked'))
            .fontSize(11)
            .fontColor(achievement.isUnlocked ? '#4CAF50' : $r('sys.color.font_tertiary'))
        }
        .width('100%')

        Progress({ value: achievement.progress, total: achievement.target, type: ProgressType.Linear })
          .width('100%')
          .height(6)
          .color(achievement.isUnlocked ? '#4CAF50' : '#CCCCCC')
          .backgroundColor($r('sys.color.comp_background_list_card'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(achievement.isUnlocked ? '#F0FFF4' : $r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level7'))
  }

  build() {
    NavDestination() {
      Column() {
        CommonHeader({
          title: '成就徽章',
          onReturnClick: this.onReturnClick,
          leftImageRes: $r('app.media.ic_backward2')
        })

        Text(`已解锁 ${this.getUnlockedCount()}/${this.getTotalCount()} 个成就`)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))
          .padding({ left: 16, right: 16, bottom: 8 })
          .width('100%')

        Grid() {
          ForEach(this.vm.achievements, (achievement: Achievement) => {
            GridItem() {
              this.renderAchievementCard(achievement)
            }
          }, (item: Achievement, index: number) => `${item.id}_${index}`)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .backgroundColor($r('sys.color.comp_background_list_card'))
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      phoneRouterControl.popPage()
      return true
    })
  }
}
